class_name FacadeComposer
extends RefCounted

## Reads a v2 facade plan JSON and builds a complete 3D facade from parts.
## Uses FacadePartLibrary for element creation and FacadePartMaterials for surfaces.
##
## Usage:
##   var facade := FacadeComposer.build_from_file("res://commons/facade_parts/presets/classical.json")
##   add_child(facade)
##
##   var facade2 := FacadeComposer.build_from_dict(my_dict)
##   add_child(facade2)

const _FPL := preload("res://commons/facade_parts/facade_part_library.gd")
const _FPM := preload("res://commons/facade_parts/facade_materials.gd")

const WALL_DEPTH := 0.25

## Default zone height multipliers.
const DEFAULT_ZONE_MULTIPLIERS := {
	"Cornice": 0.5,
	"Upper": 1.0,
	"Piano Nobile": 1.4,
	"Base": 0.9,
	"Plinth": 0.45,
}


## Build from a JSON file path. Returns the assembled Node3D.
static func build_from_file(json_path: String) -> Node3D:
	var data := _load_json(json_path)
	if data.is_empty():
		push_error("FacadeComposer: Failed to load plan from '%s'" % json_path)
		return _empty("EmptyFacade")
	return build_from_dict(data)


## Build from a Dictionary (already parsed JSON). Returns Node3D.
static func build_from_dict(data: Dictionary) -> Node3D:
	var version: int = data.get("version", 0) as int
	if version != 2:
		push_warning("FacadeComposer: Unexpected version %d (expected 2)" % version)

	var facade_data: Dictionary = data.get("facade", {})
	var zones_data: Array = data.get("zones", [])
	var placements_data: Array = data.get("placements", [])
	var materials_data: Dictionary = data.get("materials", {})

	# ── Extract facade dimensions ──
	var bays: int = facade_data.get("bays", 5) as int
	var stories: int = facade_data.get("stories", 4) as int
	var total_width: float = facade_data.get("total_width", 15.0) as float
	var total_height: float = facade_data.get("total_height", 12.0) as float
	var wall_depth: float = facade_data.get("wall_depth", WALL_DEPTH) as float
	var symmetry: String = str(facade_data.get("symmetry", "none"))
	var wall_color: String = str(materials_data.get("wall", "#d4c5a9"))

	var root := Node3D.new()
	root.name = "FacadeComposed"

	# ── Build zone map and compute row heights ──
	var zone_for_row := {}  # row -> zone name
	var zone_multipliers := {}  # row -> height multiplier
	var zone_materials := {}  # zone_name -> {color, type}

	for entry in zones_data:
		if not entry is Dictionary:
			continue
		var row: int = entry.get("row", -1) as int
		var zname: String = str(entry.get("name", ""))
		if row >= 0 and zname != "":
			zone_for_row[row] = zname
		if row >= 0 and entry.has("height_multiplier"):
			zone_multipliers[row] = float(entry["height_multiplier"])

	# Parse zone materials
	var zone_mat_data: Dictionary = materials_data.get("zones", {})
	for zname in zone_mat_data:
		if zone_mat_data[zname] is Dictionary:
			zone_materials[zname] = zone_mat_data[zname]

	# Compute row heights
	var row_heights: Array[float] = []
	var raw_total := 0.0

	for r in range(stories):
		var zname: String = zone_for_row.get(r, "")
		var mult: float = zone_multipliers.get(r, DEFAULT_ZONE_MULTIPLIERS.get(zname, 1.0))
		row_heights.append(mult)
		raw_total += mult

	# Normalize
	if raw_total > 0:
		for i in range(row_heights.size()):
			row_heights[i] = (row_heights[i] / raw_total) * total_height

	# ── Cumulative Y offsets ──
	# Row 0 is at the TOP, row (stories-1) at the BOTTOM.
	var row_y_bottoms: Array[float] = []
	row_y_bottoms.resize(stories)
	var cum_y := 0.0
	for r in range(stories - 1, -1, -1):
		row_y_bottoms[r] = cum_y
		cum_y += row_heights[r]

	var cell_width := total_width / float(bays)

	# ── Base wall ──
	var wall := _create_base_wall(total_width, total_height, wall_depth, wall_color)
	root.add_child(wall)

	# ── Bounds marker for camera framing (capture script uses MeshInstance3D AABB) ──
	var bounds_mesh := BoxMesh.new()
	bounds_mesh.size = Vector3(total_width, total_height, wall_depth)
	var bounds_marker := MeshInstance3D.new()
	bounds_marker.name = "BoundsMarker"
	bounds_marker.mesh = bounds_mesh
	bounds_marker.position = Vector3(total_width * 0.5, total_height * 0.5, 0.0)
	bounds_marker.transparency = 1.0  # Fully invisible
	root.add_child(bounds_marker)

	# ── Zone background overlays ──
	var zone_container := Node3D.new()
	zone_container.name = "Zones"
	root.add_child(zone_container)

	for zone_entry in zones_data:
		if not zone_entry is Dictionary:
			continue
		var row: int = zone_entry.get("row", 0) as int
		if row < 0 or row >= stories:
			continue
		var zname: String = str(zone_entry.get("name", ""))
		var zone_mat_info: Dictionary = zone_materials.get(zname, {})
		var zone_color_hex: String = str(zone_mat_info.get("color", ""))
		var zone_type: String = str(zone_mat_info.get("type", "stone"))

		if zone_color_hex != "" and zone_color_hex.begins_with("#"):
			var zone_bg := CSGBox3D.new()
			zone_bg.name = "ZoneBg_%s_%d" % [zname, row]
			zone_bg.size = Vector3(total_width, row_heights[row], 0.01)
			zone_bg.position = Vector3(
				total_width * 0.5,
				row_y_bottoms[row] + row_heights[row] * 0.5,
				wall_depth * 0.5 + 0.006
			)
			zone_bg.material = _FPM.from_zone(zone_type, zone_color_hex)
			zone_container.add_child(zone_bg)

	# ── Element placements ──
	var elements_container := Node3D.new()
	elements_container.name = "Elements"
	root.add_child(elements_container)

	for placement in placements_data:
		if not placement is Dictionary:
			continue

		var col: int = placement.get("col", 0) as int
		var row: int = placement.get("row", 0) as int
		var part_name: String = str(placement.get("part", ""))
		var col_span: int = placement.get("col_span", 1) as int
		var row_span: int = placement.get("row_span", 1) as int

		if col < 0 or col >= bays or row < 0 or row >= stories:
			continue
		if part_name == "" or part_name == "plain_wall":
			continue

		# Calculate effective dimensions from spans
		var ew := cell_width * float(col_span)
		var eh: float = 0.0
		for ri in range(row, mini(row + row_span, stories)):
			eh += row_heights[ri] if ri < row_heights.size() else (total_height / float(stories))

		# Build element params
		var elem_params: Dictionary = {}
		if placement.has("params") and placement["params"] is Dictionary:
			elem_params = placement["params"].duplicate()
		elem_params["wall_depth"] = wall_depth

		# Generate the part via FacadePartLibrary
		var part_node := _FPL.create(part_name, ew, eh, elem_params)

		# Position: cell left X, cell bottom Y, slightly in front of wall
		var cell_x := float(col) * cell_width
		var cell_y := row_y_bottoms[row]
		part_node.position = Vector3(cell_x, cell_y, wall_depth * 0.5)
		part_node.name = "%s_c%d_r%d" % [part_name, col, row]
		elements_container.add_child(part_node)

	# ── Apply bilateral symmetry if requested ──
	if symmetry == "bilateral":
		_apply_bilateral_symmetry(elements_container, total_width, bays, cell_width,
			row_y_bottoms, row_heights, stories, wall_depth, placements_data)

	print("FacadeComposer: Built facade with %d placements (%d bays x %d stories)" % [
		placements_data.size(), bays, stories
	])

	return root


# ─── INTERNAL HELPERS ─────────────────────────────────────────────────────

## Apply bilateral symmetry: mirror placements from left half to right half.
static func _apply_bilateral_symmetry(container: Node3D, total_width: float,
		bays: int, cell_width: float, row_y_bottoms: Array[float],
		row_heights: Array[float], stories: int, wall_depth: float,
		placements_data: Array) -> void:
	var half := bays / 2

	for placement in placements_data:
		if not placement is Dictionary:
			continue
		var col: int = placement.get("col", 0) as int
		var row: int = placement.get("row", 0) as int
		var part_name: String = str(placement.get("part", ""))

		# Only mirror columns in the left half (0 to half-1)
		if col >= half:
			continue
		if part_name == "" or part_name == "plain_wall":
			continue

		var mirror_col := bays - 1 - col
		# Check if mirror position already has a placement
		var already_placed := false
		for existing in placements_data:
			if existing is Dictionary:
				if existing.get("col", -1) as int == mirror_col and existing.get("row", -1) as int == row:
					already_placed = true
					break
		if already_placed:
			continue

		var col_span: int = placement.get("col_span", 1) as int
		var row_span: int = placement.get("row_span", 1) as int
		var ew := cell_width * float(col_span)
		var eh: float = 0.0
		for ri in range(row, mini(row + row_span, stories)):
			eh += row_heights[ri] if ri < row_heights.size() else 1.0

		var elem_params: Dictionary = {}
		if placement.has("params") and placement["params"] is Dictionary:
			elem_params = placement["params"].duplicate()
		elem_params["wall_depth"] = wall_depth

		var part_node := _FPL.create(part_name, ew, eh, elem_params)
		var cell_x := float(mirror_col) * cell_width
		var cell_y := row_y_bottoms[row]
		part_node.position = Vector3(cell_x, cell_y, wall_depth * 0.5)
		part_node.name = "%s_c%d_r%d_mirror" % [part_name, mirror_col, row]
		container.add_child(part_node)


## Load and parse a JSON file.
static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("FacadeComposer: File not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("FacadeComposer: Cannot open file: %s" % path)
		return {}

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("FacadeComposer: JSON parse error at line %d: %s" % [
			json.get_error_line(), json.get_error_message()
		])
		return {}

	if json.data is Dictionary:
		return json.data
	return {}


## Create the base wall as a CSGBox3D.
static func _create_base_wall(width: float, height: float, depth: float, color_hex: String) -> CSGBox3D:
	var wall := CSGBox3D.new()
	wall.name = "BaseWall"
	wall.size = Vector3(width, height, depth)
	wall.position = Vector3(width * 0.5, height * 0.5, 0.0)

	var color := Color(0.83, 0.77, 0.66)
	if color_hex.begins_with("#"):
		color = Color.html(color_hex)

	wall.material = _FPM.stone(color)
	return wall


## Return an empty placeholder Node3D.
static func _empty(node_name: String) -> Node3D:
	var n := Node3D.new()
	n.name = node_name
	return n
