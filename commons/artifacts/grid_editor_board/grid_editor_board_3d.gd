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

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
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
		# Accept web grid editor format: {placements: [{element, position: [x,y]}], grid_size: [w,h]}
		_clear_board()
		if config_data.has("grid_size"):
			var gs: Array = config_data["grid_size"]
			if gs.size() >= 2:
				_init_occupancy(int(gs[0]), int(gs[1]))
		var placements: Array = config_data["placements"]
		for p in placements:
			var pos: Array = p.get("position", [0, 0])
			_place_element(str(p["element"]), int(pos[0]), int(pos[1]))
		_update_status()
		print("[GridEditorBoard3D] Loaded web layout — %d elements" % _placements.size())

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
	cam.position = Vector3(0.0, 0.65, 1.8)
	cam.look_at(Vector3(0.0, 0.65, 0.0), Vector3.UP)

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
	if el.is_empty():
		push_warning("[GridEditorBoard3D] Unknown element: %s" % el_id)
		return

	var ew: int = int(el["w"])
	var eh: int = int(el["h"])

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

	# Build 3D element via factory
	var node: Node3D = Factory.build_element_3d(el_id, cell_size)
	if node == null:
		# Fallback: coloured quad (same as shadow board)
		node = _build_fallback_quad(el_id, ew, eh)

	node.name = inst_id
	node.position = _grid_cell_to_local_center(gx, gy, ew, eh)
	_placement_container.add_child(node)

	# Track for animation
	var el_type: String = Factory.get_element_type(el_id)
	if el_type == "animated":
		_animated_elements.append({"node": node, "element": el_id})

	_placements[inst_id] = {
		"element": el_id,
		"gx": gx,
		"gy": gy,
		"node": node,
	}

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
