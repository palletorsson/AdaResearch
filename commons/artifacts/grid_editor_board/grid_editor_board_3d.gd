# grid_editor_board_3d.gd
# 3D interactive version of the grid editor board. Same layout data as the
# shadow board (grid_editor_board.gd) but replaces flat coloured rectangles
# with real 3D elements — CRT monitors with phosphor flicker, VU meters
# with bouncing needles, interactive push buttons, slider faders, rotary
# knobs, toggle switches, speakers, and blinking LEDs.
#
# Driven by ControlBoardSubset presets and ControlBoardElementFactory builders.
extends Node3D
class_name GridEditorBoard3D

var PUSH_BUTTON: PackedScene
const CBS = preload("res://commons/artifacts/grid_editor_board/control_board_subset.gd")
const Factory = preload("res://commons/artifacts/grid_editor_board/control_board_element_factory.gd")

# ── Colours ────────────────────────────────────────────────────────────
const COL_PANEL     := Color(0.08, 0.08, 0.10)
const COL_BEZEL     := Color(0.12, 0.12, 0.14)
const COL_GRID_BG   := Color(0.04, 0.04, 0.06)
const COL_GRID_LINE := Color(0.18, 0.18, 0.22, 0.5)
const COL_SCREEN_FG := Color(0.15, 0.85, 0.15)

# ── Config ─────────────────────────────────────────────────────────────
@export var panel_width: float = 2.8
@export var panel_height: float = 1.4
@export var cell_size: float = 0.06
@export var grid_margin_left: float = 0.08
@export var default_grid_w: int = 24
@export var default_grid_h: int = 14

# ── State ──────────────────────────────────────────────────────────────
var _grid_w: int = 24
var _grid_h: int = 14
var _occupancy: Array = []
var _placements: Dictionary = {}
var _next_id: int = 0
var _current_preset_name: String = ""
var _time: float = 0.0
var _inline_elements: Dictionary = {}  # element_id -> {w, h, color} from config JSON

# Animation tracking
var _animated_elements: Array[Dictionary] = []  # {node, element}

# ── Refs ───────────────────────────────────────────────────────────────
var _grid_container: Node3D
var _placement_container: Node3D
var _status_label: Label3D
var _count_label: Label3D
var _grid_left: float
var _grid_bottom: float

# ═══════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════

func _ready() -> void:
	PUSH_BUTTON = load("res://commons/interactables/push_button.tscn")
	_init_occupancy(default_grid_w, default_grid_h)
	_build_back_panel()
	_build_grid()
	_build_status_label()
	_build_capture_camera()
	_load_preset(CBS.PRESET_MISSION_CONTROL)
	print("[GridEditorBoard3D] Built — %dx%d grid, cell %.3fm, %d elements" % [
		_grid_w, _grid_h, cell_size, _placements.size()])

func _process(delta: float) -> void:
	_time += delta
	_animate_all()

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("preset"):
		var preset_id: String = str(config_data["preset"])
		for p in CBS.get_presets():
			if p["id"] == preset_id:
				_load_preset(p)
				break
	elif config_data.has("placements"):
		# Accept web grid editor format: {placements: [{element, position: [x,y]}], grid_size: [w,h], elements: {id: {w,h,color}}}
		# Store inline element definitions for subsets CBS doesn't know
		if config_data.has("elements"):
			_inline_elements = config_data["elements"]
		# Rebuild board to match grid size
		var new_w: int = default_grid_w
		var new_h: int = default_grid_h
		if config_data.has("grid_size"):
			var gs: Array = config_data["grid_size"]
			if gs.size() >= 2:
				new_w = int(gs[0])
				new_h = int(gs[1])
		_rebuild_for_grid(new_w, new_h)
		var placements: Array = config_data["placements"]
		for p in placements:
			var pos: Array = p.get("position", [0, 0])
			_place_element(str(p["element"]), roundi(pos[0]), roundi(pos[1]))
		_update_status()
		print("[GridEditorBoard3D] Loaded web layout — %d elements (%d inline defs) on %dx%d" % [_placements.size(), _inline_elements.size(), new_w, new_h])

# ═══════════════════════════════════════════════════════════════════════
# DATA
# ═══════════════════════════════════════════════════════════════════════

func _init_occupancy(w: int, h: int) -> void:
	_grid_w = w
	_grid_h = h
	_occupancy.clear()
	for y in _grid_h:
		var row: Array = []
		for x in _grid_w:
			row.append("")
		_occupancy.append(row)

func _clear_board() -> void:
	for id in _placements:
		var p: Dictionary = _placements[id]
		if is_instance_valid(p["node"]):
			p["node"].queue_free()
	_placements.clear()
	_animated_elements.clear()
	_init_occupancy(_grid_w, _grid_h)
	_next_id = 0

# ═══════════════════════════════════════════════════════════════════════
# BUILDERS
# ═══════════════════════════════════════════════════════════════════════

func _rebuild_for_grid(w: int, h: int) -> void:
	# Remove all visual children and rebuild for the new grid size
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_placements.clear()
	_animated_elements.clear()
	_grid_container = null
	_placement_container = null
	_status_label = null
	_count_label = null
	_next_id = 0
	# Resize panel to fit the grid with margin
	var margin := grid_margin_left * 2
	panel_width = maxf(w * cell_size + margin, 0.5)
	panel_height = maxf(h * cell_size + margin, 0.3)
	_init_occupancy(w, h)
	_build_back_panel()
	_build_grid()
	_build_status_label()
	_build_capture_camera()

func _build_back_panel() -> void:
	var plate := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(panel_width, panel_height, 0.04)
	plate.mesh = mesh
	plate.material_override = _mat(COL_PANEL, 0.3, 0.7)
	plate.position = Vector3(0, panel_height * 0.5, -0.02)
	add_child(plate)

	for side in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(0.025, panel_height, 0.06)
		rail.mesh = rm
		rail.material_override = _mat(COL_BEZEL, 0.5, 0.5)
		rail.position = Vector3(side * panel_width * 0.5, panel_height * 0.5, -0.02)
		add_child(rail)

func _build_grid() -> void:
	_grid_container = Node3D.new()
	_grid_container.name = "GridContainer"
	add_child(_grid_container)

	_placement_container = Node3D.new()
	_placement_container.name = "Placements"
	add_child(_placement_container)

	var grid_w_m: float = _grid_w * cell_size
	var grid_h_m: float = _grid_h * cell_size

	_grid_left = -panel_width * 0.5 + grid_margin_left
	_grid_bottom = (panel_height - grid_h_m) * 0.5 - 0.03

	var cx := _grid_left + grid_w_m * 0.5
	var cy := _grid_bottom + grid_h_m * 0.5

	# Grid background
	var bg := MeshInstance3D.new()
	var bgm := QuadMesh.new()
	bgm.size = Vector2(grid_w_m, grid_h_m)
	bg.mesh = bgm
	bg.material_override = _mat(COL_GRID_BG, 0.0, 0.9)
	bg.position = Vector3(cx, cy, 0.002)
	_grid_container.add_child(bg)

	# Grid lines
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = COL_GRID_LINE
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for i in _grid_w + 1:
		var vl := MeshInstance3D.new()
		var vm := BoxMesh.new()
		vm.size = Vector3(0.0008, grid_h_m, 0.001)
		vl.mesh = vm
		vl.material_override = line_mat
		vl.position = Vector3(_grid_left + i * cell_size, cy, 0.004)
		_grid_container.add_child(vl)

	for j in _grid_h + 1:
		var hl := MeshInstance3D.new()
		var hm := BoxMesh.new()
		hm.size = Vector3(grid_w_m, 0.0008, 0.001)
		hl.mesh = hm
		hl.material_override = line_mat
		hl.position = Vector3(cx, _grid_bottom + j * cell_size, 0.004)
		_grid_container.add_child(hl)

	# Grid frame
	var frame_mat := _mat(COL_BEZEL, 0.5, 0.5)
	var fw := 0.005
	for data in [
		[Vector3(grid_w_m + fw * 2, fw, 0.008), Vector3(cx, cy + grid_h_m * 0.5 + fw * 0.5, 0.003)],
		[Vector3(grid_w_m + fw * 2, fw, 0.008), Vector3(cx, cy - grid_h_m * 0.5 - fw * 0.5, 0.003)],
		[Vector3(fw, grid_h_m, 0.008), Vector3(cx - grid_w_m * 0.5 - fw * 0.5, cy, 0.003)],
		[Vector3(fw, grid_h_m, 0.008), Vector3(cx + grid_w_m * 0.5 + fw * 0.5, cy, 0.003)],
	]:
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = data[0]
		bar.mesh = bm
		bar.material_override = frame_mat
		bar.position = data[1]
		_grid_container.add_child(bar)

	# Title
	var title := Label3D.new()
	title.text = "3D CONTROL BOARD"
	title.pixel_size = 0.0008
	title.font_size = 14
	title.modulate = Color(0.7, 0.7, 0.7)
	title.position = Vector3(_grid_left, panel_height - 0.025, 0.01)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(title)

func _build_status_label() -> void:
	_status_label = Label3D.new()
	_status_label.text = "READY"
	_status_label.pixel_size = 0.0006
	_status_label.font_size = 8
	_status_label.modulate = Color(0.3, 0.7, 0.3)
	_status_label.position = Vector3(_grid_left + 0.02, 0.04, 0.01)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_status_label)

	_count_label = Label3D.new()
	_count_label.text = "0 elements"
	_count_label.pixel_size = 0.0005
	_count_label.font_size = 7
	_count_label.modulate = Color(0.5, 0.5, 0.5)
	_count_label.position = Vector3(_grid_left + 0.02, 0.02, 0.01)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_count_label)

func _build_capture_camera() -> void:
	var cam := Camera3D.new()
	cam.name = "CaptureCamera"
	cam.fov = 60.0
	add_child(cam)
	# Dynamic framing based on actual panel size
	var half_w := panel_width * 0.5
	var half_h := panel_height * 0.5
	var aspect := 1.333  # 4:3 capture
	var fov_rad := deg_to_rad(cam.fov)
	var dist_h := half_h / tan(fov_rad * 0.5)
	var dist_w := half_w / (tan(fov_rad * 0.5) * aspect)
	var dist := maxf(dist_h, dist_w) * 1.15  # 15% padding
	var center_y := panel_height * 0.5
	cam.position = Vector3(0.0, center_y, dist)
	cam.look_at(Vector3(0.0, center_y, 0.0), Vector3.UP)

# ═══════════════════════════════════════════════════════════════════════
# PRESET LOADING
# ═══════════════════════════════════════════════════════════════════════

func _load_preset(preset: Dictionary) -> void:
	_clear_board()
	_current_preset_name = preset.get("name", "")

	var pw: int = int(preset.get("grid_w", default_grid_w))
	var ph: int = int(preset.get("grid_h", default_grid_h))
	if pw != _grid_w or ph != _grid_h:
		_init_occupancy(pw, ph)

	var placements: Array = preset.get("placements", [])
	for p in placements:
		_place_element(str(p["element"]), int(p["x"]), int(p["y"]))

	_update_status()
	print("[GridEditorBoard3D] Loaded '%s' — %d elements (%d animated)" % [
		_current_preset_name, _placements.size(), _animated_elements.size()])

# ═══════════════════════════════════════════════════════════════════════
# PLACEMENT
# ═══════════════════════════════════════════════════════════════════════

func _place_element(el_id: String, gx: int, gy: int) -> void:
	var el: Dictionary = CBS.get_element(el_id)
	var is_inline := false
	if el.is_empty() and _inline_elements.has(el_id):
		# Use inline element definition from config JSON
		el = _inline_elements[el_id]
		is_inline = true
	if el.is_empty():
		push_warning("[GridEditorBoard3D] Unknown element: %s" % el_id)
		return

	var ew: int = int(el.get("w", 1))
	var eh: int = int(el.get("h", 1))

	if gx < 0 or gy < 0 or gx + ew > _grid_w or gy + eh > _grid_h:
		return

	for dy in eh:
		for dx in ew:
			if _occupancy[gy + dy][gx + dx] != "":
				return

	var inst_id: String = "p_%d" % _next_id
	_next_id += 1

	for dy in eh:
		for dx in ew:
			_occupancy[gy + dy][gx + dx] = inst_id

	var node: Node3D = null
	if is_inline:
		# Inline element — build colored quad with color from config
		var color_hex: String = str(el.get("color", "#666666"))
		node = _build_inline_element(el_id, ew, eh, color_hex)
	else:
		# Build 3D element via factory
		node = Factory.build_element_3d(el_id, cell_size)
		if node == null:
			# Fallback: coloured quad (same as shadow board)
			node = _build_fallback_quad(el_id, ew, eh)

	node.name = inst_id
	node.position = _grid_cell_to_local_center(gx, gy, ew, eh)
	_placement_container.add_child(node)

	# Track for animation
	if not is_inline:
		var el_type: String = Factory.get_element_type(el_id)
		if el_type == "animated":
			_animated_elements.append({"node": node, "element": el_id})

	_placements[inst_id] = {
		"element": el_id,
		"gx": gx,
		"gy": gy,
		"node": node,
	}

func _build_inline_element(el_id: String, w: int, h: int, color_hex: String) -> Node3D:
	var col := Color(color_hex)
	var sx: float = w * cell_size - 0.004
	var sy: float = h * cell_size - 0.004
	var depth: float = cell_size * 0.4

	# --- Glass Rack ---
	if el_id in ["flask", "beaker"]:
		return _inline_flask(sx, sy, col)
	if el_id in ["straight", "straight_long", "straight_h", "wobbly"]:
		return _inline_tube(sx, sy, col, el_id == "straight_h")
	if el_id.begins_with("corner") or el_id in ["sbend", "ubend", "reducer"]:
		return _inline_bend(sx, sy, col)
	if el_id in ["tee", "ypipe", "cross"]:
		return _inline_junction(sx, sy, col)
	if el_id in ["spiral", "condenser"]:
		return _inline_condenser(sx, sy, col)
	if el_id in ["cap", "drip"]:
		return _inline_terminal(sx, sy, col)

	# --- Chemical Models ---
	if el_id.begins_with("atom_"):
		return _inline_atom(sx, sy, el_id, col)
	if el_id == "bond_single" or el_id == "lone_pair":
		return _inline_bond(sx, sy, col)

	# --- Big Pipes ---
	if el_id in ["t_junction", "end_cap", "up", "down"] or (el_id == "straight" and w >= 1) or el_id.begins_with("corner_"):
		return _inline_pipe(sx, sy, col, el_id)

	# --- Sticky Notes ---
	if el_id.begins_with("note_") or el_id in ["index_card", "photo_frame"]:
		return _inline_sticky(sx, sy, col, el_id)
	if el_id in ["push_pin", "star_marker"]:
		return _inline_pin(sx, sy, col)
	if el_id.begins_with("arrow_"):
		return _inline_arrow(sx, sy, col, el_id)
	if el_id in ["header_strip", "label_tag"]:
		return _inline_label_strip(sx, sy, col)

	# --- Periodic Table ---
	if el_id.begins_with("el_"):
		return _inline_periodic_cell(sx, sy, el_id, col)

	# --- Audio Rack ---
	if el_id.begins_with("src_"):
		return _inline_audio_source(sx, sy, col)
	if el_id.begins_with("sl_") or el_id.begins_with("knob_"):
		return _inline_knob(sx, sy, col)
	if el_id.begins_with("btn_"):
		return _inline_button(sx, sy, col)
	if el_id.begins_with("disp_") or el_id == "meter_vu":
		return _inline_display(sx, sy, col)

	# --- Facade Elements ---
	if el_id.begins_with("column_") or el_id.begins_with("pilaster"):
		return _inline_column(sx, sy, col)
	if el_id.begins_with("window_") or el_id.begins_with("door_") or el_id == "arcade_arch":
		return _inline_opening(sx, sy, col)
	if el_id.begins_with("cornice_") or el_id.begins_with("string_") or el_id.begins_with("fascia_"):
		return _inline_band(sx, sy, col)
	if el_id.begins_with("pediment_") or el_id == "art_deco_crown":
		return _inline_pediment(sx, sy, col)
	if el_id.begins_with("zone_") or el_id.begins_with("rustication") or el_id == "wall_plain" or el_id == "balustrade":
		return _inline_wall_block(sx, sy, col)

	# --- Lab Items ---
	if el_id in ["microscope", "oscilloscope", "atmosphericmonitoring", "seismograph"]:
		return _inline_lab_device(sx, sy, col)
	if el_id in ["multimeter", "electronicscales", "terminal", "datatablet"]:
		return _inline_lab_box(sx, sy, col)
	if el_id in ["chemicalapparatus", "samplevialrack", "petri_dish_worms", "pipettedispenser"]:
		return _inline_flask(sx, sy, col)
	if el_id in ["dna_specimen", "additive_wave_demo"]:
		return _inline_display(sx, sy, col)

	# Fallback: colored box with depth
	return _inline_box_fallback(sx, sy, depth, col, el_id)

# ── Inline 3D builders ──────────────────────────────────────────────

func _inline_flask(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	# Cylindrical body
	var body := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = sx * 0.2
	cm.bottom_radius = sx * 0.45
	cm.height = sy * 0.7
	body.mesh = cm
	body.rotation_degrees.x = 90
	body.material_override = _mat_glass(col)
	node.add_child(body)
	# Neck
	var neck := MeshInstance3D.new()
	var nm := CylinderMesh.new()
	nm.top_radius = sx * 0.1
	nm.bottom_radius = sx * 0.2
	nm.height = sy * 0.35
	neck.mesh = nm
	neck.rotation_degrees.x = 90
	neck.position.y = sy * 0.35
	neck.material_override = _mat_glass(col)
	node.add_child(neck)
	return node

func _inline_tube(sx: float, sy: float, col: Color, horizontal: bool) -> Node3D:
	var node := Node3D.new()
	var tube := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	var length := sx if horizontal else sy
	cm.top_radius = cell_size * 0.15
	cm.bottom_radius = cell_size * 0.15
	cm.height = length * 0.9
	tube.mesh = cm
	if horizontal:
		tube.rotation_degrees.z = 90
	else:
		tube.rotation_degrees.x = 90
	tube.material_override = _mat_glass(col)
	node.add_child(tube)
	return node

func _inline_bend(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	var bend := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = cell_size * 0.12
	tm.outer_radius = cell_size * 0.35
	bend.mesh = tm
	bend.material_override = _mat_glass(col)
	node.add_child(bend)
	return node

func _inline_junction(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	var sp := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = cell_size * 0.25
	sm.height = cell_size * 0.5
	sp.mesh = sm
	sp.material_override = _mat_glass(col)
	node.add_child(sp)
	# Small tubes radiating
	for angle in [0, 90, 180]:
		var t := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = cell_size * 0.08
		cm.bottom_radius = cell_size * 0.08
		cm.height = cell_size * 0.3
		t.mesh = cm
		t.rotation_degrees.z = float(angle)
		t.material_override = _mat_glass(col)
		node.add_child(t)
	return node

func _inline_condenser(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	# Outer jacket
	var outer := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = sx * 0.3
	cm.bottom_radius = sx * 0.3
	cm.height = sy * 0.8
	outer.mesh = cm
	outer.rotation_degrees.x = 90
	outer.material_override = _mat_glass(col, 0.5)
	node.add_child(outer)
	# Inner coil (smaller cylinder)
	var inner := MeshInstance3D.new()
	var im := CylinderMesh.new()
	im.top_radius = sx * 0.1
	im.bottom_radius = sx * 0.1
	im.height = sy * 0.85
	inner.mesh = im
	inner.rotation_degrees.x = 90
	inner.material_override = _mat_glass(col.lightened(0.3))
	node.add_child(inner)
	return node

func _inline_terminal(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	var sp := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = minf(sx, sy) * 0.35
	sm.height = minf(sx, sy) * 0.7
	sp.mesh = sm
	sp.material_override = _mat_glass(col)
	node.add_child(sp)
	return node

func _inline_atom(sx: float, sy: float, el_id: String, col: Color) -> Node3D:
	# CPK coloring for atoms
	var cpk_colors := {
		"atom_H": Color(1.0, 1.0, 1.0), "atom_C": Color(0.2, 0.2, 0.2),
		"atom_N": Color(0.2, 0.3, 1.0), "atom_O": Color(1.0, 0.15, 0.15),
		"atom_F": Color(0.6, 1.0, 0.6), "atom_Cl": Color(0.1, 0.9, 0.1),
		"atom_S": Color(1.0, 0.85, 0.2), "atom_P": Color(1.0, 0.5, 0.0),
		"atom_Na": Color(0.7, 0.3, 1.0), "atom_Ca": Color(0.3, 1.0, 0.3),
		"atom_Fe": Color(0.9, 0.5, 0.15), "atom_Cu": Color(0.8, 0.5, 0.2),
		"atom_Zn": Color(0.5, 0.5, 0.7),
	}
	var atom_col: Color = cpk_colors.get(el_id, col)
	var node := Node3D.new()
	var sp := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = minf(sx, sy) * 0.45
	sm.height = minf(sx, sy) * 0.9
	sp.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = atom_col
	mat.metallic = 0.2
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = atom_col
	mat.emission_energy_multiplier = 0.2
	sp.material_override = mat
	node.add_child(sp)
	# Label
	var lbl := Label3D.new()
	lbl.text = el_id.replace("atom_", "")
	lbl.pixel_size = 0.0006
	lbl.font_size = 8
	lbl.modulate = Color(0.0, 0.0, 0.0) if atom_col.get_luminance() > 0.5 else Color(1, 1, 1)
	lbl.position.z = minf(sx, sy) * 0.46
	node.add_child(lbl)
	return node

func _inline_bond(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	var stick := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = cell_size * 0.06
	cm.bottom_radius = cell_size * 0.06
	cm.height = maxf(sx, sy) * 0.9
	stick.mesh = cm
	if sx > sy:
		stick.rotation_degrees.z = 90
	else:
		stick.rotation_degrees.x = 90
	stick.material_override = _mat(Color(0.6, 0.6, 0.6), 0.3, 0.5)
	node.add_child(stick)
	return node

func _inline_pipe(sx: float, sy: float, col: Color, el_id: String) -> Node3D:
	var node := Node3D.new()
	var pipe := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = minf(sx, sy) * 0.35
	cm.bottom_radius = minf(sx, sy) * 0.35
	cm.height = maxf(sx, sy) * 0.85
	pipe.mesh = cm
	if sx > sy:
		pipe.rotation_degrees.z = 90
	pipe.material_override = _mat(col.darkened(0.1), 0.7, 0.3)
	node.add_child(pipe)
	if el_id == "t_junction" or el_id == "cross":
		var branch := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = minf(sx, sy) * 0.3
		bm.bottom_radius = minf(sx, sy) * 0.3
		bm.height = minf(sx, sy) * 0.6
		branch.mesh = bm
		branch.rotation_degrees.z = 90
		branch.material_override = _mat(col.darkened(0.1), 0.7, 0.3)
		node.add_child(branch)
	return node

func _inline_sticky(sx: float, sy: float, col: Color, el_id: String) -> Node3D:
	var node := Node3D.new()
	var note := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sx * 0.9, sy * 0.9, cell_size * 0.05)
	note.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.5
	mat.roughness = 0.8
	note.material_override = mat
	# Slight tilt for 3D feel
	node.rotation_degrees.x = randf_range(-3, 3)
	node.rotation_degrees.y = randf_range(-5, 5)
	node.add_child(note)
	return node

func _inline_pin(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = minf(sx, sy) * 0.3
	sm.height = minf(sx, sy) * 0.6
	head.mesh = sm
	head.material_override = _mat(col, 0.5, 0.3)
	head.position.z = cell_size * 0.1
	node.add_child(head)
	return node

func _inline_arrow(sx: float, sy: float, col: Color, el_id: String) -> Node3D:
	var node := Node3D.new()
	var shaft := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sx * 0.6, sy * 0.15, cell_size * 0.04)
	shaft.mesh = bm
	shaft.material_override = _mat(col, 0.0, 0.8)
	node.add_child(shaft)
	return node

func _inline_label_strip(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	var strip := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sx * 0.9, sy * 0.5, cell_size * 0.03)
	strip.mesh = bm
	strip.material_override = _mat(col.darkened(0.2), 0.0, 0.7)
	node.add_child(strip)
	return node

func _inline_periodic_cell(sx: float, sy: float, el_id: String, col: Color) -> Node3D:
	var node := Node3D.new()
	var cell := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sx * 0.88, sy * 0.88, cell_size * 0.12)
	cell.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col.darkened(0.15)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.6
	mat.roughness = 0.5
	cell.material_override = mat
	node.add_child(cell)
	var lbl := Label3D.new()
	lbl.text = el_id.replace("el_", "")
	lbl.pixel_size = 0.0008
	lbl.font_size = 10
	lbl.modulate = Color(1, 1, 1)
	lbl.position.z = cell_size * 0.07
	node.add_child(lbl)
	return node

func _inline_audio_source(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	# Speaker-like shape
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sx * 0.85, sy * 0.85, cell_size * 0.2)
	body.mesh = bm
	body.material_override = _mat(col.darkened(0.3), 0.3, 0.6)
	node.add_child(body)
	var cone := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = minf(sx, sy) * 0.15
	cm.bottom_radius = minf(sx, sy) * 0.35
	cm.height = cell_size * 0.15
	cone.mesh = cm
	cone.rotation_degrees.x = 90
	cone.position.z = cell_size * 0.12
	cone.material_override = _mat(col, 0.1, 0.7)
	node.add_child(cone)
	return node

func _inline_knob(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	var knob := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = minf(sx, sy) * 0.35
	cm.bottom_radius = minf(sx, sy) * 0.4
	cm.height = cell_size * 0.2
	knob.mesh = cm
	knob.rotation_degrees.x = 90
	knob.position.z = cell_size * 0.1
	knob.material_override = _mat(col.darkened(0.2), 0.6, 0.3)
	node.add_child(knob)
	# Pointer
	var ptr := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(cell_size * 0.03, minf(sx, sy) * 0.3, cell_size * 0.02)
	ptr.mesh = pm
	ptr.position.z = cell_size * 0.21
	ptr.material_override = _mat(Color.WHITE, 0.0, 0.5)
	ptr.rotation_degrees.z = randf_range(-140, 140)
	node.add_child(ptr)
	return node

func _inline_button(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	var btn := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = minf(sx, sy) * 0.35
	cm.bottom_radius = minf(sx, sy) * 0.35
	cm.height = cell_size * 0.15
	btn.mesh = cm
	btn.rotation_degrees.x = 90
	btn.position.z = cell_size * 0.08
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.8
	mat.roughness = 0.4
	btn.material_override = mat
	node.add_child(btn)
	return node

func _inline_display(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	# Bezel
	var bezel := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sx * 0.9, sy * 0.9, cell_size * 0.15)
	bezel.mesh = bm
	bezel.material_override = _mat(Color(0.1, 0.1, 0.12), 0.3, 0.6)
	node.add_child(bezel)
	# Screen
	var screen := MeshInstance3D.new()
	var sm := QuadMesh.new()
	sm.size = Vector2(sx * 0.75, sy * 0.75)
	screen.mesh = sm
	screen.position.z = cell_size * 0.08
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col.darkened(0.5)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen.material_override = mat
	node.add_child(screen)
	return node

func _inline_column(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	var shaft := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = sx * 0.3
	cm.bottom_radius = sx * 0.35
	cm.height = sy * 0.75
	shaft.mesh = cm
	shaft.rotation_degrees.x = 90
	shaft.material_override = _mat(col, 0.2, 0.6)
	node.add_child(shaft)
	# Capital
	var cap := MeshInstance3D.new()
	var capm := BoxMesh.new()
	capm.size = Vector3(sx * 0.8, sy * 0.12, cell_size * 0.15)
	cap.mesh = capm
	cap.position.y = sy * 0.42
	cap.material_override = _mat(col.lightened(0.1), 0.2, 0.5)
	node.add_child(cap)
	# Base
	var base := MeshInstance3D.new()
	var basem := BoxMesh.new()
	basem.size = Vector3(sx * 0.8, sy * 0.08, cell_size * 0.15)
	base.mesh = basem
	base.position.y = -sy * 0.42
	base.material_override = _mat(col.lightened(0.1), 0.2, 0.5)
	node.add_child(base)
	return node

func _inline_opening(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	# Frame
	var frame := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sx * 0.9, sy * 0.9, cell_size * 0.1)
	frame.mesh = bm
	frame.material_override = _mat(col.darkened(0.2), 0.2, 0.6)
	node.add_child(frame)
	# Dark interior
	var glass := MeshInstance3D.new()
	var gm := QuadMesh.new()
	gm.size = Vector2(sx * 0.65, sy * 0.7)
	glass.mesh = gm
	glass.position.z = cell_size * 0.06
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.2, 0.35, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.material_override = mat
	node.add_child(glass)
	return node

func _inline_band(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	var band := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sx * 0.95, sy * 0.6, cell_size * 0.12)
	band.mesh = bm
	band.material_override = _mat(col, 0.2, 0.6)
	node.add_child(band)
	return node

func _inline_pediment(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	# Triangular shape approximated with box + prism
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sx * 0.9, sy * 0.4, cell_size * 0.1)
	base.mesh = bm
	base.position.y = -sy * 0.2
	base.material_override = _mat(col, 0.2, 0.6)
	node.add_child(base)
	var peak := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(sx * 0.85, sy * 0.5, cell_size * 0.1)
	peak.mesh = pm
	peak.position.y = sy * 0.1
	peak.material_override = _mat(col, 0.2, 0.6)
	node.add_child(peak)
	return node

func _inline_wall_block(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	var block := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sx * 0.92, sy * 0.92, cell_size * 0.08)
	block.mesh = bm
	block.material_override = _mat(col.darkened(0.15), 0.1, 0.8)
	node.add_child(block)
	return node

func _inline_lab_device(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	# Body
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sx * 0.8, sy * 0.5, cell_size * 0.3)
	body.mesh = bm
	body.position.y = -sy * 0.15
	body.material_override = _mat(col.darkened(0.2), 0.3, 0.6)
	node.add_child(body)
	# Eyepiece / display
	var top := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = sx * 0.1
	cm.bottom_radius = sx * 0.15
	cm.height = sy * 0.35
	top.mesh = cm
	top.rotation_degrees.x = 90
	top.position.y = sy * 0.2
	top.position.z = cell_size * 0.1
	top.material_override = _mat(col, 0.5, 0.4)
	node.add_child(top)
	return node

func _inline_lab_box(sx: float, sy: float, col: Color) -> Node3D:
	var node := Node3D.new()
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sx * 0.85, sy * 0.85, cell_size * 0.25)
	box.mesh = bm
	box.material_override = _mat(col.darkened(0.1), 0.3, 0.5)
	node.add_child(box)
	# Screen face
	var face := MeshInstance3D.new()
	var fm := QuadMesh.new()
	fm.size = Vector2(sx * 0.6, sy * 0.5)
	face.mesh = fm
	face.position.z = cell_size * 0.13
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.15, 0.1)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.5
	face.material_override = mat
	node.add_child(face)
	return node

func _inline_box_fallback(sx: float, sy: float, depth: float, col: Color, el_id: String) -> Node3D:
	var node := Node3D.new()
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(sx * 0.85, sy * 0.85, depth)
	box.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col.darkened(0.2)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.3
	box.material_override = mat
	node.add_child(box)
	return node

func _mat_glass(col: Color, alpha: float = 0.7) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(col.r, col.g, col.b, alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.1
	mat.roughness = 0.15
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.3
	return mat

func _build_fallback_quad(el_id: String, w: int, h: int) -> Node3D:
	var node := Node3D.new()
	var el: Dictionary = CBS.get_element(el_id)
	var cat_color: Color = CBS.get_category_color(el.get("category", ""))
	var rect := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(w * cell_size - 0.006, h * cell_size - 0.006)
	rect.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cat_color.darkened(0.2)
	mat.emission_enabled = true
	mat.emission = cat_color
	mat.emission_energy_multiplier = 0.3
	rect.material_override = mat
	node.add_child(rect)
	var lbl := Label3D.new()
	lbl.text = el.get("name", el_id)
	lbl.pixel_size = 0.0004
	lbl.font_size = 5
	lbl.modulate = Color(0.9, 0.9, 0.9)
	lbl.position.z = 0.001
	node.add_child(lbl)
	return node

func _grid_cell_to_local_center(gx: int, gy: int, w: int, h: int) -> Vector3:
	var x: float = _grid_left + (gx + w * 0.5) * cell_size
	var y: float = _grid_bottom + (_grid_h - gy - h * 0.5) * cell_size
	return Vector3(x, y, 0.006)

func _update_status() -> void:
	if is_instance_valid(_status_label):
		_status_label.text = _current_preset_name if _current_preset_name != "" else "READY"
		_status_label.modulate = Color(0.3, 0.7, 0.3)
	if is_instance_valid(_count_label):
		_count_label.text = "%d elements" % _placements.size()

# ═══════════════════════════════════════════════════════════════════════
# ANIMATION
# ═══════════════════════════════════════════════════════════════════════

func _animate_all() -> void:
	for entry in _animated_elements:
		if not is_instance_valid(entry["node"]):
			continue
		var node: Node3D = entry["node"]
		match entry["element"]:
			"crt_large", "crt_small", "waveform_display":
				_animate_crt(node)
			"radar_display":
				_animate_radar(node)
			"status_panel":
				_animate_crt(node)  # Same flicker
			"vu_meter", "gauge_round":
				_animate_needle(node)
			"led_bar_v":
				_animate_led_bar(node)
			"led_green", "led_red", "led_amber":
				_animate_led(node)
			"warning_light":
				_animate_warning(node)

func _animate_crt(node: Node3D) -> void:
	var screen := node.get_node_or_null("Screen") as MeshInstance3D
	if not screen:
		return
	var mat: StandardMaterial3D = screen.material_override
	if mat:
		var flicker: float = 0.7 + sin(_time * 30.0) * 0.05 + sin(_time * 7.3) * 0.1
		mat.emission_energy_multiplier = 0.6 + sin(_time * 2.1) * 0.2
		# Slightly vary the emission color brightness
		var base: Color = mat.emission / maxf(mat.emission.r + mat.emission.g + mat.emission.b, 0.01)
		mat.emission = base * flicker * 0.4

func _animate_radar(node: Node3D) -> void:
	_animate_crt(node)
	var sweep := node.get_node_or_null("SweepLine") as MeshInstance3D
	if sweep:
		sweep.rotation_degrees.z = fmod(_time * 60.0, 360.0)

func _animate_needle(node: Node3D) -> void:
	var needle := node.get_node_or_null("Needle") as MeshInstance3D
	if needle:
		var signal_val: float = abs(sin(_time * 2.5)) * 0.6 + sin(_time * 13.0) * 0.15
		signal_val = clampf(signal_val, 0.0, 1.0)
		needle.rotation_degrees.z = lerp(-35.0, 35.0, signal_val)

func _animate_led_bar(node: Node3D) -> void:
	var level: float = (sin(_time * 1.8) * 0.5 + 0.5) * 8.0
	for i in 8:
		var led := node.get_node_or_null("LED_%d" % i) as MeshInstance3D
		if not led:
			continue
		var mat: StandardMaterial3D = led.material_override
		if mat:
			mat.emission_energy_multiplier = 2.0 if i < int(level) else 0.3

func _animate_led(node: Node3D) -> void:
	var bulb := node.get_node_or_null("Bulb") as MeshInstance3D
	if not bulb:
		return
	var mat: StandardMaterial3D = bulb.material_override
	if mat:
		# Slow blink with some randomness via node hash
		var phase: float = float(node.get_instance_id() % 1000) * 0.001
		var on: bool = fmod(_time + phase * 3.7, 2.0) > 0.3
		mat.emission_energy_multiplier = 2.0 if on else 0.3

func _animate_warning(node: Node3D) -> void:
	var bulb := node.get_node_or_null("Bulb") as MeshInstance3D
	if not bulb:
		return
	var mat: StandardMaterial3D = bulb.material_override
	if mat:
		# Slow pulsing
		mat.emission_energy_multiplier = 1.5 + sin(_time * 4.0) * 1.5

# ═══════════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════════

func _mat(color: Color, metallic: float = 0.0, roughness: float = 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m
