# GridWallSegmentsComponent.gd
# INTERIOR wall segments from an optional `layers.walls` grid — the Two Point
# Museum move: partition a floor plate into wings with thin walls and doorways.
#
# Encoding (per cell, string): edge letters n/e/s/w = solid wall on that edge;
# UPPERCASE N/E/S/W = a doorway in that edge's wall. Empty/" " = nothing.
#   "e"  wall on the east edge
#   "nE" wall north + doorway east
# Shared edges are deduped (cell's "n" == northern neighbor's "s"); declare
# either side. Config via settings.wall_segments {height, thickness, color,
# door_width, door_height}. Purely additive: maps without a walls layer are
# untouched.

extends Node
class_name GridWallSegmentsComponent

# MARRIAGE 3: when the map carries compiled wall runs (settings.wall_runs,
# tools/wall_runs.py) and the labwall style, walls are built from the SAME
# variant library the Three.js viewer renders (WallVariantLibrary via glTF)
# — one wall, two renderers. Collision stays engine-built; maps without
# wall_runs render exactly as before.
const WallLibScript := preload("res://commons/grid/WallVariantLibrary.gd")

var grid_system: Node3D
var data_component: GridDataComponent
var _wall_runs: Dictionary = {}
var _lib = null
var _variant_at: Dictionary = {}
var _current_variant: String = ""

var cube_size: float = 1.0
var gutter: float = 0.0
var wall_height: float = 3.2
var wall_thickness: float = 0.16
var door_width: float = 1.2
var door_height: float = 2.3
var wall_color: Color = Color(0.86, 0.82, 0.72)

var _container: Node3D
var _built_edges: Dictionary = {}
var _mat: StandardMaterial3D

# "labwall" style (additive, config settings.wall_segments.style): the
# Half-Life industrial composition — dark kick plate, concrete panel, groove,
# emissive amber accent line, dark top trim, and a small hover gap under the
# wall so it casts a shadow line (the cheap accent). Maps without the style
# key render exactly as before.
var _style: String = ""
var _mat_panel: StandardMaterial3D
var _mat_dark: StandardMaterial3D
var _mat_accent: StandardMaterial3D
# light palettes (config.palettes): zone rects in cell coords, each with an
# `accent` [r,g,b] — the emissive line changes register per zone (mission
# act-halls: amber arrival, cyan work, red depth). No palettes = one amber.
var _zone_accents: Array = []   # [{x0,y0,x1,y1, mat}]
const HOVER := 0.06
const KICK_H := 0.28
const ACCENT_H := 0.08
const TRIM_H := 0.55

signal wall_segments_complete(segment_count: int)

func initialize(grid_sys: Node3D, data_comp: GridDataComponent, settings: Dictionary = {}) -> void:
	grid_system = grid_sys
	data_component = data_comp
	cube_size = settings.get("cube_size", cube_size)
	gutter = settings.get("gutter", gutter)
	var wr = settings.get("wall_runs", {})
	_wall_runs = wr if wr is Dictionary else {}

func generate_segments(walls_layer: Array, structure_layer: Array, config: Dictionary = {}) -> void:
	if walls_layer.is_empty():
		return
	wall_height = float(config.get("height", wall_height))
	wall_thickness = float(config.get("thickness", wall_thickness))
	door_width = float(config.get("door_width", door_width))
	door_height = float(config.get("door_height", door_height))
	var c = config.get("color")
	if c is Array and c.size() >= 3:
		wall_color = Color(c[0], c[1], c[2])

	clear_segments()
	_container = Node3D.new()
	_container.name = "WallSegments"
	grid_system.add_child(_container)

	_mat = StandardMaterial3D.new()
	_mat.albedo_color = wall_color
	_mat.roughness = 0.85

	_style = str(config.get("style", ""))
	if _style == "labwall":
		_mat_panel = StandardMaterial3D.new()
		_mat_panel.albedo_color = wall_color if c is Array else Color(0.52, 0.54, 0.55)
		_mat_panel.roughness = 0.9
		_mat_dark = StandardMaterial3D.new()
		_mat_dark.albedo_color = Color(0.12, 0.13, 0.14)
		_mat_dark.roughness = 0.6
		_mat_dark.metallic = 0.35
		_mat_accent = StandardMaterial3D.new()
		_mat_accent.albedo_color = Color(1.0, 0.62, 0.18)
		_mat_accent.emission_enabled = true
		_mat_accent.emission = Color(1.0, 0.55, 0.15)
		_mat_accent.emission_energy_multiplier = 1.6
		_zone_accents.clear()
		for p in config.get("palettes", []):
			if not (p is Dictionary and p.has("rect") and p.has("accent")):
				continue
			var rect: Array = p["rect"]
			var acc: Array = p["accent"]
			if rect.size() < 4 or acc.size() < 3:
				continue
			var m := StandardMaterial3D.new()
			var col2 := Color(acc[0], acc[1], acc[2])
			m.albedo_color = col2
			m.emission_enabled = true
			m.emission = col2
			m.emission_energy_multiplier = 1.6
			_zone_accents.append({"x0": int(rect[0]), "y0": int(rect[1]),
					"x1": int(rect[2]), "y1": int(rect[3]), "mat": m})
	# MARRIAGE 3: compiled wall runs + labwall -> build from the ONE library
	_variant_at.clear()
	_lib = null
	if _style == "labwall" and _wall_runs.get("runs", []).size() > 0:
		_lib = WallLibScript.new()
		for run in _wall_runs["runs"]:
			var mods: Array = run.get("modules", [])
			for i in mods.size():
				var ex: int = int(run["x"]) + (i if run["axis"] == "h" else 0)
				var ez: int = int(run["z"]) + (0 if run["axis"] == "h" else i)
				_variant_at["%s:%d:%d" % [run["axis"], ex, ez]] = mods[i].get("v", "plain")

	var total := cube_size + gutter
	var count := 0
	for row in walls_layer.size():
		var cells = walls_layer[row]
		for col in cells.size():
			var code := str(cells[col]).strip_edges()
			if code.is_empty():
				continue
			for ch in code:
				var lower := String(ch).to_lower()
				if not lower in ["n", "e", "s", "w"]:
					continue
				var is_door := String(ch) != lower
				var key := _edge_key(col, row, lower)
				if _built_edges.has(key):
					continue
				_built_edges[key] = true
				_build_edge(col, row, lower, is_door, structure_layer, total)
				count += 1
	# corner posts from the compiled runs (visual only; wall collisions overlap here)
	if _lib != null:
		for cn in _wall_runs.get("corners", []):
			var total2 := cube_size + gutter
			var h_int: int = int(cn.get("y", 1))
			var cy: float = GridCommon.surface_world_y(h_int, total2, cube_size * 0.5)
			var node: Node3D = _lib.build("corner",
					_accent_for(int(cn.get("x", 0)), int(cn.get("z", 0))))
			node.position = Vector3(float(cn["x"]) * total2, cy, float(cn["z"]) * total2)
			_container.add_child(node)
	print("GridWallSegmentsComponent: built %d wall segments (%d with doors, variants: %s)"
			% [count, _door_count, "on" if _lib != null else "off"])
	wall_segments_complete.emit(count)

var _door_count := 0

# Normalize a cell edge to a unique key: north/south edges are horizontal
# edges keyed by the row ABOVE them; east/west are vertical edges keyed by
# the column to their WEST.
func _edge_key(col: int, row: int, edge: String) -> String:
	match edge:
		"n": return "h:%d:%d" % [col, row]
		"s": return "h:%d:%d" % [col, row + 1]
		"w": return "v:%d:%d" % [col, row]
		"e": return "v:%d:%d" % [col + 1, row]
	return "?"

func _cell_floor_y(col: int, row: int, structure_layer: Array, total: float) -> float:
	if row < structure_layer.size():
		var cells = structure_layer[row]
		if col < cells.size():
			var h := int(str(cells[col]).strip_edges().to_float())
			return GridCommon.surface_world_y(h, total, cube_size * 0.5)
	return 0.0

var _current_accent: StandardMaterial3D = null

func _accent_for(col: int, row: int) -> StandardMaterial3D:
	for z in _zone_accents:
		if col >= z["x0"] and col <= z["x1"] and row >= z["y0"] and row <= z["y1"]:
			return z["mat"]
	return _mat_accent

func _build_edge(col: int, row: int, edge: String, is_door: bool,
		structure_layer: Array, total: float) -> void:
	if _style == "labwall":
		_current_accent = _accent_for(col, row)
	_current_variant = ""
	if _lib != null:
		_current_variant = _variant_at.get(_edge_key(col, row, edge), "")
	var center: Vector3 = GridCommon.grid_to_world_position(Vector3i(col, 0, row), cube_size, gutter)
	var base_y := _cell_floor_y(col, row, structure_layer, total)
	var half := total * 0.5
	var along_x := edge in ["n", "s"]
	var offset := Vector3.ZERO
	match edge:
		"n": offset = Vector3(0, 0, -half)
		"s": offset = Vector3(0, 0, half)
		"w": offset = Vector3(-half, 0, 0)
		"e": offset = Vector3(half, 0, 0)
	var mid := center + offset
	var seg_len := total + wall_thickness   # slight overlap closes corners

	# variant mode: the library node is the visual, engine boxes stay collision
	var use_variant: bool = _lib != null and _current_variant != ""

	if not is_door:
		if use_variant:
			_wall_box(mid, base_y, seg_len, wall_height, along_x, false)
			_place_variant(_current_variant, mid, base_y, along_x)
		else:
			_wall_box(mid, base_y, seg_len, wall_height, along_x)
		return

	_door_count += 1
	# doorway: lintel above the opening; jambs only when the opening is
	# narrower than the edge (door_width >= edge -> full clear opening)
	var door_visual: bool = not (_lib != null)
	var opening: float = minf(door_width, seg_len)
	var jamb_len: float = (seg_len - opening) * 0.5
	if jamb_len > 0.08:
		var jamb_off: float = (opening + jamb_len) * 0.5
		var side := Vector3(jamb_off, 0, 0) if along_x else Vector3(0, 0, jamb_off)
		_wall_box(mid + side, base_y, jamb_len, wall_height, along_x, door_visual)
		_wall_box(mid - side, base_y, jamb_len, wall_height, along_x, door_visual)
	var lintel_h: float = maxf(0.05, wall_height - door_height)
	_wall_box(mid, base_y + door_height, seg_len, lintel_h, along_x, door_visual)
	if not door_visual:
		_place_variant("doorframe", mid, base_y, along_x)

func _place_variant(vname: String, mid: Vector3, base_y: float, along_x: bool) -> void:
	var acc: StandardMaterial3D = _current_accent if _current_accent != null else _mat_accent
	var node: Node3D = _lib.build(vname, acc)
	node.scale = Vector3(1.04, wall_height / 3.2, 1.0)
	if not along_x:
		node.rotation.y = PI / 2
	node.position = Vector3(mid.x, base_y, mid.z)
	_container.add_child(node)

func _wall_box(mid: Vector3, base_y: float, length: float, height: float,
		along_x: bool, visual: bool = true) -> void:
	var size := Vector3(length, height, wall_thickness) if along_x \
		else Vector3(wall_thickness, height, length)
	var body := StaticBody3D.new()
	body.position = Vector3(mid.x, base_y + height * 0.5, mid.z)
	if visual:
		if _style == "labwall":
			_dress_labwall(body, length, height, along_x)
		else:
			body.add_child(_box_mesh(size, _mat, Vector3.ZERO))
	var col_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col_shape.shape = shape
	body.add_child(col_shape)
	_container.add_child(body)

func _box_mesh(size: Vector3, mat: StandardMaterial3D, offset: Vector3) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = mat
	mesh.position = offset
	return mesh

# The labwall composition, built inside the body's local space (origin at the
# wall's volumetric centre). Short pieces (lintels) stay a plain dark slab.
func _dress_labwall(body: StaticBody3D, length: float, height: float, along_x: bool) -> void:
	var t := wall_thickness
	var y0 := -height * 0.5                      # local floor line
	if height < 1.6:
		body.add_child(_box_mesh(_seg_size(length, height, t, along_x), _mat_dark, Vector3.ZERO))
		return
	# hover gap: visuals start above the floor line; collision stays full
	var kick_y := y0 + HOVER + KICK_H * 0.5
	body.add_child(_box_mesh(_seg_size(length, KICK_H, t * 1.35, along_x), _mat_dark,
			Vector3(0, kick_y, 0)))
	var trim_y := height * 0.5 - TRIM_H * 0.5
	var accent_y := height * 0.5 - TRIM_H - ACCENT_H * 0.5
	var panel_bottom := y0 + HOVER + KICK_H
	var panel_top := accent_y - ACCENT_H * 0.5
	var panel_h := panel_top - panel_bottom
	body.add_child(_box_mesh(_seg_size(length, panel_h, t, along_x), _mat_panel,
			Vector3(0, panel_bottom + panel_h * 0.5, 0)))
	# groove: a dark proud line a third of the way up the panel
	var groove_y := panel_bottom + panel_h * 0.38
	body.add_child(_box_mesh(_seg_size(length, 0.09, t * 1.06, along_x), _mat_dark,
			Vector3(0, groove_y, 0)))
	# the accent line — amber by default, zone-colored under light palettes
	var acc_mat := _current_accent if _current_accent != null else _mat_accent
	body.add_child(_box_mesh(_seg_size(length, ACCENT_H, t * 1.18, along_x), acc_mat,
			Vector3(0, accent_y, 0)))
	body.add_child(_box_mesh(_seg_size(length, TRIM_H, t * 1.25, along_x), _mat_dark,
			Vector3(0, trim_y, 0)))

func _seg_size(l: float, h: float, th: float, along_x: bool) -> Vector3:
	return Vector3(l, h, th) if along_x else Vector3(th, h, l)

func clear_segments() -> void:
	if _container and is_instance_valid(_container):
		_container.queue_free()
	_container = null
	_built_edges.clear()
	_door_count = 0
