extends Node3D

const RackPassiveElementsScript = preload("res://commons/interactables/RackPassiveElements.gd")

## Interactable Demo — one row of every control type with labels.
## For inspecting, testing, and improving each VR control element.
## Run this scene directly or place as artifact in a map.

## Control definitions — scenes loaded at runtime (not preload) to avoid
## RigidBody3D script compilation errors with interactable_handle.gd
const DEFAULT_CONTROLS := [
	{ "scene": "res://commons/interactables/push_button.tscn", "label": "BUTTON", "y": 0.0 },
	{ "scene": "res://commons/interactables/push_button_front.tscn", "label": "BUTTON\nFRONT", "y": 0.0, "rot_y": 180.0 },
	{ "scene": "res://commons/interactables/dial_smooth.tscn", "label": "KNOB", "y": 0.0 },
	{ "scene": "res://commons/interactables/slider_smooth.tscn", "label": "SLIDER V", "y": 0.0 },
	{ "scene": "res://commons/interactables/slider_horizontal.tscn", "label": "SLIDER H", "y": 0.0 },
	{ "scene": "res://commons/interactables/slider_snap.tscn", "label": "SNAP", "y": 0.0 },
	{ "scene": "res://commons/interactables/slider_zero.tscn", "label": "ZERO", "y": 0.0 },
	{ "scene": "res://commons/interactables/lever_smooth.tscn", "label": "LEVER", "y": 0.0 },
	{ "scene": "res://commons/interactables/wheel_smooth.tscn", "label": "WHEEL", "y": 0.0 },
	{ "scene": "res://commons/interactables/joystick_smooth.tscn", "label": "JOYSTICK", "y": -0.05 },
	{ "scene": "res://commons/interactables/slider_plane.tscn", "label": "XY PAD", "y": -0.05 },
]

## Additional button types (procedural, added to Row 1 overflow)
const DEFAULT_EXTRA_BUTTONS := [
	{ "type": "rect_sm", "label": "RECT SM" },
	{ "type": "rect_wide", "label": "RECT WIDE" },
	{ "type": "rect_tall", "label": "RECT TALL" },
	{ "type": "toggle", "label": "TOGGLE" },
]

## Row 4: New prototype modules — procedural versions of the interface_prototypes preset
const DEFAULT_NEW_MODULES := [
	{ "type": "touch_grid", "label": "TOUCH\nGRID", "width": 1 },
	{ "type": "rotary_selector", "label": "ROTARY\nSELECTOR", "width": 1 },
	{ "type": "needle_meter", "label": "NEEDLE\nMETER", "width": 1 },
	{ "type": "patch_matrix", "label": "PATCH\nMATRIX", "width": 1 },
	{ "type": "text_static_1", "label": "TEXT 1", "width": 1 },
	{ "type": "text_static_2", "label": "TEXT 2", "width": 2 },
	{ "type": "text_static_3", "label": "TEXT 3", "width": 3 },
	{ "type": "text_scroll_1", "label": "SCROLL 1", "width": 1 },
	{ "type": "text_scroll_2", "label": "SCROLL 2", "width": 2 },
	{ "type": "text_scroll_3", "label": "SCROLL 3", "width": 3 },
]

const DEFAULT_SPACING := 0.30  # meters between each control
const DEFAULT_CONTROL_Z := 0.02  # forward from back panel
const DEFAULT_LABEL_Y_OFFSET := -0.18  # below control center
const DEFAULT_ROW_Y := 1.1  # height of row center
const COMPOUND_FRAME_HEIGHT := 0.28
const COMPOUND_INNER_MARGIN := 0.015
const FRAME_BAR_THICKNESS := 0.008
const FRAME_BAR_DEPTH := 0.004
const FRAME_Z_OFFSET := -0.004
const CONTENT_FRAME_MARGIN_X := 0.012
const CONTENT_FRAME_MARGIN_Y := 0.012
const VERTICAL_SLIDER_SIZE := Vector2(0.08, 0.22)
const HORIZONTAL_SLIDER_SIZE := Vector2(0.22, 0.08)
const VERTICAL_SLIDER_GAP := 0.04
const HORIZONTAL_SLIDER_GAP := 0.008
const SLIDER_VERTICAL_SCENE := "res://commons/interactables/slider_smooth.tscn"
const SLIDER_HORIZONTAL_SCENE := "res://commons/interactables/slider_horizontal.tscn"
const RIGHT_HAND_SCENE := "res://commons/body/hands/right_hand.tscn"
const LEFT_HAND_SCENE := "res://commons/body/hands/left_hand.tscn"
const HAND_REFERENCE_LENGTH_M := 0.21
const HAND_REFERENCE_WIDTH_M := 0.07


## Row 2: Passive elements — speakers, meters, working monitors (use real scenes)
const DEFAULT_PASSIVE_ELEMENTS = [
	{ "builder": "build_speaker_dots", "label": "SPEAKER DOTS", "width": 1 },
	{ "builder": "build_speaker_lines", "label": "SPEAKER LINES", "width": 1 },
	{ "builder": "build_speaker_grid", "label": "SPEAKER GRID", "width": 1 },
	{ "builder": "build_vu_meter_v", "label": "VU METER V", "width": 1 },
	{ "builder": "build_vu_meter_h", "label": "VU METER H", "width": 1 },
	{ "monitor": "scope", "slots": 2, "label": "SCOPE", "width": 2 },
	{ "monitor": "scope", "slots": 3, "label": "SCOPE WIDE", "width": 3 },
	{ "monitor": "spectrum", "slots": 2, "label": "SPECTRUM", "width": 2 },
	{ "monitor": "lissajous", "slots": 2, "label": "LISSAJOUS", "width": 2 },
]

const DEFAULT_ROW2_Y := 0.65  # Second row below first
const DEFAULT_ROW3_Y := 0.20  # Third row (compounds)

## Row 3: Compound layouts — double/triple footprint allowed
const DEFAULT_COMPOUNDS = [
	{ "type": "sliders_v", "count": 2, "label": "2x SLIDER V", "width": 2 },
	{ "type": "sliders_v", "count": 3, "label": "3x SLIDER V", "width": 2 },
	{ "type": "sliders_v", "count": 4, "label": "4x SLIDER V", "width": 2 },
	{ "type": "sliders_h", "count": 2, "label": "2x SLIDER H", "width": 2 },
	{ "type": "sliders_h", "count": 3, "label": "3x SLIDER H", "width": 2 },
	{ "type": "sliders_h", "count": 4, "label": "4x SLIDER H", "width": 2 },
	{ "type": "monitor_sliders", "count": 3, "label": "MONITOR+SLIDERS", "width": 2 },
	{ "type": "speaker_meters", "count": 2, "label": "SPEAKER+METERS", "width": 2 },
	{ "type": "meters_v", "count": 3, "label": "3x METERS", "width": 1 },
]

@export var auto_build: bool = true

var controls: Array = []
var extra_buttons: Array = []
var passive_elements: Array = []
var compounds: Array = []
var new_modules: Array = []

var spacing: float = DEFAULT_SPACING
var control_z: float = DEFAULT_CONTROL_Z
var label_y_offset: float = DEFAULT_LABEL_Y_OFFSET
var row_y: float = DEFAULT_ROW_Y
var row2_y: float = DEFAULT_ROW2_Y
var row3_y: float = DEFAULT_ROW3_Y
var row4_y: float = -0.25

var panel_color: Color = Color(0.78, 0.75, 0.67)
var frame_color: Color = Color(0.25, 0.23, 0.20)
var accent_color: Color = Color(0.75, 0.38, 0.13)
var dark_color: Color = Color(0.10, 0.10, 0.10)
var cream_color: Color = Color(0.78, 0.75, 0.67)

var main_title_text: String = "INTERACTABLE CONTROLS"
var row2_title_text: String = "PASSIVE ELEMENTS & MONITORS"
var row3_title_text: String = "COMPOUND LAYOUTS"
var row4_title_text: String = "NEW MODULES + TEXT DISPLAYS"
var demo_info: Dictionary = {}
var show_hand_scale_guides: bool = false


func _init() -> void:
	_restore_defaults()


func _restore_defaults() -> void:
	controls = DEFAULT_CONTROLS.duplicate(true)
	extra_buttons = DEFAULT_EXTRA_BUTTONS.duplicate(true)
	passive_elements = DEFAULT_PASSIVE_ELEMENTS.duplicate(true)
	compounds = DEFAULT_COMPOUNDS.duplicate(true)
	new_modules = DEFAULT_NEW_MODULES.duplicate(true)
	spacing = DEFAULT_SPACING
	control_z = DEFAULT_CONTROL_Z
	label_y_offset = DEFAULT_LABEL_Y_OFFSET
	row_y = DEFAULT_ROW_Y
	row2_y = DEFAULT_ROW2_Y
	row3_y = DEFAULT_ROW3_Y
	row4_y = -0.25
	panel_color = Color(0.78, 0.75, 0.67)
	frame_color = Color(0.25, 0.23, 0.20)
	accent_color = Color(0.75, 0.38, 0.13)
	dark_color = Color(0.10, 0.10, 0.10)
	cream_color = Color(0.78, 0.75, 0.67)
	main_title_text = "INTERACTABLE CONTROLS"
	row2_title_text = "PASSIVE ELEMENTS & MONITORS"
	row3_title_text = "COMPOUND LAYOUTS"
	row4_title_text = "NEW MODULES + TEXT DISPLAYS"
	demo_info = {}
	show_hand_scale_guides = false


func _ready():
	if not auto_build:
		return
	_build_back_panel()
	_spawn_controls()
	_spawn_passive_elements()
	_spawn_compounds()
	_spawn_new_modules()
	_add_title()
	print("InteractableDemo: %d controls + %d passive + %d compounds + %d new modules" % [controls.size(), passive_elements.size(), compounds.size(), new_modules.size()])


func load_demo_config_from_dict(data: Dictionary) -> void:
	_restore_defaults()
	if data.has("demo_info") and data["demo_info"] is Dictionary:
		demo_info = data["demo_info"]
	if data.has("controls") and data["controls"] is Array:
		controls = data["controls"].duplicate(true)
	if data.has("extra_buttons") and data["extra_buttons"] is Array:
		extra_buttons = data["extra_buttons"].duplicate(true)
	if data.has("passive_elements") and data["passive_elements"] is Array:
		passive_elements = data["passive_elements"].duplicate(true)
	if data.has("compounds") and data["compounds"] is Array:
		compounds = data["compounds"].duplicate(true)
	if data.has("new_modules") and data["new_modules"] is Array:
		new_modules = data["new_modules"].duplicate(true)
	if data.has("titles") and data["titles"] is Dictionary:
		var titles: Dictionary = data["titles"]
		main_title_text = str(titles.get("main", main_title_text))
		row2_title_text = str(titles.get("row2", row2_title_text))
		row3_title_text = str(titles.get("row3", row3_title_text))
		row4_title_text = str(titles.get("row4", row4_title_text))
	if data.has("layout") and data["layout"] is Dictionary:
		_apply_layout_dict(data["layout"])


func _apply_layout_dict(layout: Dictionary) -> void:
	if layout.has("spacing"):
		spacing = float(layout["spacing"])
	if layout.has("control_z"):
		control_z = float(layout["control_z"])
	if layout.has("label_y_offset"):
		label_y_offset = float(layout["label_y_offset"])
	if layout.has("row_y"):
		row_y = float(layout["row_y"])
	if layout.has("row2_y"):
		row2_y = float(layout["row2_y"])
	if layout.has("row3_y"):
		row3_y = float(layout["row3_y"])
	if layout.has("row4_y"):
		row4_y = float(layout["row4_y"])
	if layout.has("show_hand_scale_guides"):
		show_hand_scale_guides = bool(layout["show_hand_scale_guides"])
	panel_color = _color_from_value(layout.get("panel_color", panel_color), panel_color)
	frame_color = _color_from_value(layout.get("frame_color", frame_color), frame_color)
	accent_color = _color_from_value(layout.get("accent_color", accent_color), accent_color)
	dark_color = _color_from_value(layout.get("dark_color", dark_color), dark_color)
	cream_color = _color_from_value(layout.get("cream_color", cream_color), cream_color)


func _color_from_value(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is Array:
		var c: Array = value
		if c.size() >= 3:
			return Color(float(c[0]), float(c[1]), float(c[2]), float(c[3]) if c.size() > 3 else 1.0)
	return fallback


func _build_back_panel():
	var total_w: float = (controls.size() + extra_buttons.size()) * spacing + 0.2
	var panel := MeshInstance3D.new()
	panel.name = "BackPanel"
	var box := BoxMesh.new()
	box.size = Vector3(total_w, 0.45, 0.008)
	panel.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = panel_color
	mat.metallic = 0.3
	mat.roughness = 0.6
	panel.material_override = mat
	panel.transform.origin = Vector3(0, row_y, -0.005)
	add_child(panel)

	# Subtle border frame
	var frame := MeshInstance3D.new()
	frame.name = "Frame"
	var frame_box := BoxMesh.new()
	frame_box.size = Vector3(total_w + 0.02, 0.47, 0.004)
	frame.mesh = frame_box
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = panel_color.darkened(0.16)
	frame_mat.metallic = 0.2
	frame_mat.roughness = 0.7
	frame.material_override = frame_mat
	frame.transform.origin = Vector3(0, row_y, -0.008)
	add_child(frame)


func _make_frame_material() -> StandardMaterial3D:
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = frame_color
	frame_mat.metallic = 0.3
	frame_mat.roughness = 0.7
	return frame_mat


func _add_outline_frame(frame_name: String, center: Vector3, width: float, height: float) -> void:
	var frame_root := Node3D.new()
	frame_root.name = frame_name
	frame_root.transform.origin = center + Vector3(0, 0, FRAME_Z_OFFSET)
	add_child(frame_root)

	var frame_mat := _make_frame_material()
	var horizontal_width: float = maxf(width, FRAME_BAR_THICKNESS)
	var vertical_height: float = maxf(height - FRAME_BAR_THICKNESS * 2.0, FRAME_BAR_THICKNESS)

	var segments := [
		{ "name": "Top", "size": Vector3(horizontal_width, FRAME_BAR_THICKNESS, FRAME_BAR_DEPTH), "pos": Vector3(0, height * 0.5 - FRAME_BAR_THICKNESS * 0.5, 0) },
		{ "name": "Bottom", "size": Vector3(horizontal_width, FRAME_BAR_THICKNESS, FRAME_BAR_DEPTH), "pos": Vector3(0, -height * 0.5 + FRAME_BAR_THICKNESS * 0.5, 0) },
		{ "name": "Left", "size": Vector3(FRAME_BAR_THICKNESS, vertical_height, FRAME_BAR_DEPTH), "pos": Vector3(-width * 0.5 + FRAME_BAR_THICKNESS * 0.5, 0, 0) },
		{ "name": "Right", "size": Vector3(FRAME_BAR_THICKNESS, vertical_height, FRAME_BAR_DEPTH), "pos": Vector3(width * 0.5 - FRAME_BAR_THICKNESS * 0.5, 0, 0) },
	]

	for segment in segments:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "%s_%s" % [frame_name, segment["name"]]
		var box := BoxMesh.new()
		box.size = segment["size"]
		mesh_instance.mesh = box
		mesh_instance.material_override = frame_mat
		mesh_instance.transform.origin = segment["pos"]
		frame_root.add_child(mesh_instance)


func _measure_local_visual_aabb(root_node: Node3D) -> AABB:
	var total := AABB()
	var first := true
	var stack: Array = [{ "node": root_node, "xf": Transform3D.IDENTITY }]
	while not stack.is_empty():
		var item: Dictionary = stack.pop_back()
		var current: Node3D = item["node"]
		var current_xf: Transform3D = item["xf"]
		if current is MeshInstance3D and current.mesh:
			var mesh_aabb: AABB = current_xf * current.get_aabb()
			if first:
				total = mesh_aabb
				first = false
			else:
				total = total.merge(mesh_aabb)
		for child in current.get_children():
			if child is Node3D:
				stack.append({ "node": child, "xf": current_xf * child.transform })
	if first:
		return AABB(Vector3(-0.04, -0.04, 0), Vector3(0.08, 0.08, 0.01))
	return total


func _frame_container_content(frame_name: String, container: Node3D, min_size: Vector2 = Vector2.ZERO, margin: Vector2 = Vector2(CONTENT_FRAME_MARGIN_X, CONTENT_FRAME_MARGIN_Y)) -> void:
	var local_aabb := _measure_local_visual_aabb(container)
	var local_center := local_aabb.get_center()
	var width := maxf(local_aabb.size.x + margin.x * 2.0, min_size.x)
	var height := maxf(local_aabb.size.y + margin.y * 2.0, min_size.y)
	var center := container.transform.origin + local_center
	_add_outline_frame(frame_name, center, width, height)


func _get_control_frame_size(scene_path: String) -> Vector2:
	if "slider_horizontal" in scene_path:
		return Vector2(0.25, 0.10)
	if "slider_plane" in scene_path:
		return Vector2(0.18, 0.18)
	if "push_button" in scene_path:
		return Vector2(0.10, 0.10)
	if "dial_smooth" in scene_path or "wheel_smooth" in scene_path:
		return Vector2(0.12, 0.12)
	if "lever_smooth" in scene_path:
		return Vector2(0.10, 0.18)
	if "joystick" in scene_path:
		return Vector2(0.12, 0.14)
	if "slider_" in scene_path:
		return Vector2(0.10, 0.24)
	return Vector2(0.12, 0.12)


func _get_passive_frame_size(def: Dictionary, elem_width: int) -> Vector2:
	if def.has("monitor"):
		return Vector2(elem_width * spacing - 0.05, 0.21)

	match String(def.get("builder", "")):
		"build_speaker_dots", "build_speaker_lines", "build_speaker_grid":
			return Vector2(0.19, 0.19)
		"build_vu_meter_v":
			return Vector2(0.055, 0.22)
		"build_vu_meter_h":
			return Vector2(0.15, 0.06)
		_:
			return Vector2(0.14, 0.14)


func _get_compound_frame_size(comp_type: String, count: int, frame_width: float) -> Vector2:
	match comp_type:
		"sliders_v":
			var width: float = count * VERTICAL_SLIDER_SIZE.x + float(maxi(0, count - 1)) * VERTICAL_SLIDER_GAP + COMPOUND_INNER_MARGIN * 2.0
			return Vector2(minf(width, frame_width - 0.02), 0.25)
		"sliders_h":
			if count >= 4:
				return Vector2(minf(frame_width - 0.03, 0.52), 0.22)
			var scale: float = 1.0 if count == 2 else 0.975
			var total_height: float = HORIZONTAL_SLIDER_SIZE.y * scale * count + HORIZONTAL_SLIDER_GAP * float(maxi(0, count - 1))
			return Vector2(0.25, total_height + 0.03)
		"monitor_sliders":
			return Vector2(frame_width - 0.05, 0.23)
		"speaker_meters":
			return Vector2(0.17, 0.20)
		"meters_v":
			return Vector2(0.13, 0.22)
		_:
			return Vector2(frame_width - 0.05, 0.20)


func _spawn_controls():
	var total_controls: int = controls.size() + extra_buttons.size()
	var start_x: float = -(total_controls - 1) * spacing / 2.0

	for i in controls.size():
		var def: Dictionary = controls[i]
		var scene_path: String = def["scene"]
		var label_text: String = def["label"]
		var y_offset: float = def.get("y", 0.0)

		var x_pos: float = start_x + i * spacing

		# Load and instantiate control
		var scene := load(scene_path) as PackedScene
		if not scene:
			push_warning("InteractableDemo: Failed to load %s" % scene_path)
			continue

		var frame_size := _get_control_frame_size(scene_path)
		_add_outline_frame("Frame_%d" % i, Vector3(x_pos, row_y + y_offset, control_z), frame_size.x, frame_size.y)

		var control := scene.instantiate()
		control.name = "Control_%d" % i
		control.transform.origin = Vector3(x_pos, row_y + y_offset, control_z)
		if def.has("rot_y"):
			control.rotation_degrees.y = def["rot_y"]
		add_child(control)

		# Name label below — white text with dark outline for contrast on gray
		var lbl := Label3D.new()
		lbl.name = "Label_%d" % i
		lbl.text = label_text
		lbl.font_size = 32
		lbl.pixel_size = 0.0006
		lbl.modulate = Color(1.0, 1.0, 1.0)
		lbl.outline_size = 6
		lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		lbl.transform.origin = Vector3(x_pos, row_y + label_y_offset, control_z + 0.01)
		add_child(lbl)

		# Index number above — bright copper with dark outline
		var idx_lbl := Label3D.new()
		idx_lbl.name = "Index_%d" % i
		idx_lbl.text = "%d" % (i + 1)
		idx_lbl.font_size = 24
		idx_lbl.pixel_size = 0.0005
		idx_lbl.modulate = Color(1.0, 0.6, 0.2)
		idx_lbl.outline_size = 4
		idx_lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
		idx_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		idx_lbl.transform.origin = Vector3(x_pos, row_y + 0.20, control_z + 0.01)
		add_child(idx_lbl)

	if show_hand_scale_guides:
		_add_hand_scale_guides(start_x)

	# Extra procedural buttons after the scene-loaded controls
	for j in extra_buttons.size():
		var bdef: Dictionary = extra_buttons[j]
		var bx: float = start_x + (controls.size() + j) * spacing
		var bc := Node3D.new()
		bc.name = "ExtraBtn_%d" % j
		bc.transform.origin = Vector3(bx, row_y, control_z)
		add_child(bc)
		_build_extra_button(bc, bdef["type"], accent_color, dark_color)
		var blbl := Label3D.new()
		blbl.text = bdef["label"]
		blbl.font_size = 28
		blbl.pixel_size = 0.0006
		blbl.modulate = Color(1, 1, 1)
		blbl.outline_size = 5
		blbl.outline_modulate = Color(0, 0, 0, 0.9)
		blbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		blbl.transform.origin = Vector3(bx, row_y + label_y_offset, control_z + 0.01)
		add_child(blbl)


func _add_hand_scale_guides(start_x: float) -> void:
	var vertical_idx := _find_slider_control_index(false)
	var horizontal_idx := _find_slider_control_index(true)
	if vertical_idx >= 0:
		var x_pos := start_x + float(vertical_idx) * spacing
		_add_hand_scale_probe(RIGHT_HAND_SCENE, Vector3(x_pos + 0.095, row_y, control_z + 0.055), "hand 21cm", HAND_REFERENCE_LENGTH_M, false)
	if horizontal_idx >= 0:
		var x_pos := start_x + float(horizontal_idx) * spacing
		_add_hand_scale_probe(LEFT_HAND_SCENE, Vector3(x_pos, row_y + 0.120, control_z + 0.055), "palm 7cm", HAND_REFERENCE_WIDTH_M, true)


func _find_slider_control_index(horizontal: bool) -> int:
	for i in controls.size():
		var def: Dictionary = controls[i]
		var scene_path := str(def.get("scene", ""))
		if horizontal and "slider_horizontal" in scene_path:
			return i
		if not horizontal and "slider_" in scene_path and not "slider_horizontal" in scene_path and not "slider_plane" in scene_path:
			return i
	return -1


func _add_hand_scale_probe(scene_path: String, pos: Vector3, label_text: String, tick_length: float, rotate_flat: bool) -> void:
	var scene := load(scene_path) as PackedScene
	if not scene:
		push_warning("InteractableDemo: Failed to load hand scale scene %s" % scene_path)
		return
	var hand := scene.instantiate() as Node3D
	if not hand:
		return
	hand.name = "HandScaleProbe"
	hand.transform.origin = pos
	if rotate_flat:
		hand.rotation_degrees.z = -90.0
	hand.scale = Vector3.ONE
	_strip_hand_runtime_scripts(hand)
	_apply_hand_probe_material(hand)
	add_child(hand)

	_add_scale_tick(pos + Vector3(0.0, -0.125, -0.006), tick_length, label_text)


func _strip_hand_runtime_scripts(root_node: Node3D) -> void:
	var stack: Array = [root_node]
	while not stack.is_empty():
		var current = stack.pop_back()
		if current is AnimationTree:
			current.active = false
		if current.get_script() != null:
			current.set_script(null)
		for child in current.get_children():
			if child is Node:
				stack.append(child)


func _apply_hand_probe_material(root_node: Node3D) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.75, 0.95, 0.32)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.0
	mat.roughness = 0.35
	mat.no_depth_test = true
	var stack: Array = [root_node]
	while not stack.is_empty():
		var current = stack.pop_back()
		if current is MeshInstance3D:
			current.material_override = mat
		for child in current.get_children():
			if child is Node3D:
				stack.append(child)


func _add_scale_tick(center: Vector3, length: float, label_text: String) -> void:
	var tick_root := Node3D.new()
	tick_root.name = "HandScaleTick"
	tick_root.transform.origin = center
	add_child(tick_root)

	var mat := _make_mat(accent_color, 0.35)
	var bar := MeshInstance3D.new()
	bar.mesh = BoxMesh.new()
	bar.mesh.size = Vector3(length, 0.004, 0.002)
	bar.material_override = mat
	tick_root.add_child(bar)

	for x in [-length * 0.5, length * 0.5]:
		var end_tick := MeshInstance3D.new()
		end_tick.mesh = BoxMesh.new()
		end_tick.mesh.size = Vector3(0.004, 0.020, 0.002)
		end_tick.material_override = mat
		end_tick.transform.origin = Vector3(x, 0, 0)
		tick_root.add_child(end_tick)

	var lbl := Label3D.new()
	lbl.text = label_text
	lbl.font_size = 14
	lbl.pixel_size = 0.0005
	lbl.modulate = Color(1, 1, 1)
	lbl.outline_size = 4
	lbl.outline_modulate = Color(0, 0, 0, 0.9)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.transform.origin = Vector3(0, -0.024, 0.004)
	tick_root.add_child(lbl)


func _build_extra_button(c: Node3D, t: String, copper: Color, dark: Color) -> void:
	match t:
		"rect_sm":
			# Small rectangular button (Rams power switch)
			var btn := MeshInstance3D.new()
			btn.mesh = BoxMesh.new()
			btn.mesh.size = Vector3(0.025, 0.015, 0.008)
			btn.material_override = _make_mat(dark, 0.0)
			btn.transform.origin.z = 0.004
			c.add_child(btn)
			var ind := MeshInstance3D.new()
			ind.mesh = BoxMesh.new()
			ind.mesh.size = Vector3(0.008, 0.003, 0.001)
			ind.material_override = _make_mat(copper, 0.4)
			ind.transform.origin = Vector3(0, 0, 0.009)
			c.add_child(ind)
		"rect_wide":
			# Wide rectangular rocker
			var btn := MeshInstance3D.new()
			btn.mesh = BoxMesh.new()
			btn.mesh.size = Vector3(0.06, 0.02, 0.008)
			btn.material_override = _make_mat(dark, 0.0)
			btn.transform.origin.z = 0.004
			c.add_child(btn)
			# Divider line in center
			var div := MeshInstance3D.new()
			div.mesh = BoxMesh.new()
			div.mesh.size = Vector3(0.001, 0.018, 0.001)
			div.material_override = _make_mat(Color(0.3, 0.3, 0.3), 0.0)
			div.transform.origin = Vector3(0, 0, 0.009)
			c.add_child(div)
			var ind := MeshInstance3D.new()
			ind.mesh = BoxMesh.new()
			ind.mesh.size = Vector3(0.005, 0.003, 0.001)
			ind.material_override = _make_mat(copper, 0.4)
			ind.transform.origin = Vector3(-0.015, 0, 0.009)
			c.add_child(ind)
		"rect_tall":
			# Tall rectangular slider-button
			var btn := MeshInstance3D.new()
			btn.mesh = BoxMesh.new()
			btn.mesh.size = Vector3(0.02, 0.04, 0.008)
			btn.material_override = _make_mat(dark, 0.0)
			btn.transform.origin.z = 0.004
			c.add_child(btn)
			var ind := MeshInstance3D.new()
			ind.mesh = BoxMesh.new()
			ind.mesh.size = Vector3(0.012, 0.003, 0.001)
			ind.material_override = _make_mat(copper, 0.4)
			ind.transform.origin = Vector3(0, 0.012, 0.009)
			c.add_child(ind)
		"toggle":
			# Round toggle with on/off states
			var ring := MeshInstance3D.new()
			ring.mesh = TorusMesh.new()
			ring.mesh.inner_radius = 0.012
			ring.mesh.outer_radius = 0.015
			ring.mesh.rings = 8
			ring.mesh.ring_segments = 24
			ring.material_override = _make_mat(dark, 0.0)
			c.add_child(ring)
			var cap := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.010
			cm.bottom_radius = 0.010
			cm.height = 0.008
			cm.radial_segments = 24
			cap.mesh = cm
			cap.material_override = _make_mat(copper, 0.3)
			cap.rotation_degrees.x = 90
			cap.transform.origin.z = 0.005
			c.add_child(cap)


static func _make_mat(color: Color, emission: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = 0.5
	m.roughness = 0.4
	if emission > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m


func _spawn_passive_elements():
	if passive_elements.is_empty():
		return
	# Calculate total width accounting for element widths
	var total_slots: float = 0
	for def in passive_elements:
		total_slots += def.get("width", 1)
	var total_w2: float = total_slots * spacing + 0.2

	var panel2 := MeshInstance3D.new()
	panel2.name = "BackPanel2"
	var box2 := BoxMesh.new()
	box2.size = Vector3(total_w2, 0.45, 0.008)
	panel2.mesh = box2
	var mat2 := StandardMaterial3D.new()
	mat2.albedo_color = panel_color
	mat2.metallic = 0.3
	mat2.roughness = 0.6
	panel2.material_override = mat2
	panel2.transform.origin = Vector3(0, row2_y, -0.005)
	add_child(panel2)

	var title2 := Label3D.new()
	title2.text = row2_title_text
	title2.font_size = 28
	title2.pixel_size = 0.0007
	title2.modulate = Color(1.0, 1.0, 1.0)
	title2.outline_size = 5
	title2.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	title2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title2.transform.origin = Vector3(0, row2_y + 0.22, control_z + 0.01)
	add_child(title2)

	var x_cursor: float = -total_w2 / 2.0 + 0.1
	for i in passive_elements.size():
		var def: Dictionary = passive_elements[i]
		var label_text: String = def["label"]
		var elem_width: int = def.get("width", 1)
		var x_pos: float = x_cursor + (elem_width * spacing) / 2.0

		var element := Node3D.new()
		element.name = "Passive_%d" % i
		element.transform.origin = Vector3(x_pos, row2_y, control_z)
		add_child(element)
		if def.has("monitor"):
			RackPassiveElementsScript.build_monitor_grid(element, def.get("slots", 2), def["monitor"])
		elif def.has("builder"):
			match def["builder"]:
				"build_speaker_dots": RackPassiveElementsScript.build_speaker_dots(element)
				"build_speaker_lines": RackPassiveElementsScript.build_speaker_lines(element)
				"build_speaker_grid": RackPassiveElementsScript.build_speaker_grid(element)
				"build_vu_meter_v": RackPassiveElementsScript.build_vu_meter_v(element)
				"build_vu_meter_h": RackPassiveElementsScript.build_vu_meter_h(element)

		_frame_container_content("PassiveFrame_%d" % i, element, Vector2(0.05, 0.05))

		var lbl := Label3D.new()
		lbl.name = "PassiveLabel_%d" % i
		lbl.text = label_text
		lbl.font_size = 24
		lbl.pixel_size = 0.0006
		lbl.modulate = Color(1.0, 1.0, 1.0)
		lbl.outline_size = 5
		lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.transform.origin = Vector3(x_pos, row2_y - 0.14, control_z + 0.01)
		add_child(lbl)

		x_cursor += elem_width * spacing


func _spawn_compounds():
	if compounds.is_empty():
		return
	var total_slots: float = 0
	for def in compounds:
		total_slots += def.get("width", 1)
	var total_w3: float = total_slots * spacing + 0.2

	var panel3 := MeshInstance3D.new()
	panel3.name = "BackPanel3"
	var box3 := BoxMesh.new()
	box3.size = Vector3(total_w3, 0.45, 0.008)
	panel3.mesh = box3
	var mat3 := StandardMaterial3D.new()
	mat3.albedo_color = panel_color
	mat3.metallic = 0.3
	mat3.roughness = 0.6
	panel3.material_override = mat3
	panel3.transform.origin = Vector3(0, row3_y, -0.005)
	add_child(panel3)

	var title3 := Label3D.new()
	title3.text = row3_title_text
	title3.font_size = 28
	title3.pixel_size = 0.0007
	title3.modulate = Color(1.0, 1.0, 1.0)
	title3.outline_size = 5
	title3.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	title3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title3.transform.origin = Vector3(0, row3_y + 0.22, control_z + 0.01)
	add_child(title3)

	var x_cursor: float = -total_w3 / 2.0 + 0.1
	for i in compounds.size():
		var def: Dictionary = compounds[i]
		var comp_type: String = def["type"]
		var count: int = def.get("count", 2)
		var label_text: String = def["label"]
		var elem_width: int = def.get("width", 1)
		var x_pos: float = x_cursor + (elem_width * spacing) / 2.0

		var frame_width := elem_width * spacing - 0.02
		var container := Node3D.new()
		container.name = "Compound_%d" % i
		container.transform.origin = Vector3(x_pos, row3_y, control_z)
		add_child(container)

		_build_compound(container, comp_type, count, frame_width)
		_frame_container_content("CompFrame_%d" % i, container, Vector2(0.08, 0.08))

		var lbl := Label3D.new()
		lbl.name = "CompLabel_%d" % i
		lbl.text = label_text
		lbl.font_size = 22
		lbl.pixel_size = 0.0006
		lbl.modulate = Color(1.0, 1.0, 1.0)
		lbl.outline_size = 5
		lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.transform.origin = Vector3(x_pos, row3_y - 0.14, control_z + 0.01)
		add_child(lbl)

		x_cursor += elem_width * spacing


func _instantiate_compound_control(scene_path: String) -> Node3D:
	var scene := load(scene_path) as PackedScene
	if not scene:
		push_warning("InteractableDemo: Failed to load %s" % scene_path)
		return null
	return scene.instantiate() as Node3D


func _add_vertical_slider_pack(container: Node3D, count: int, frame_width: float) -> void:
	var ideal_spread: float = (VERTICAL_SLIDER_SIZE.x + VERTICAL_SLIDER_GAP) * float(count - 1)
	var spread: float = minf(frame_width - COMPOUND_INNER_MARGIN * 2.0 - VERTICAL_SLIDER_SIZE.x, ideal_spread)
	spread = maxf(spread, 0.0)
	var step: float = spread / float(maxi(1, count - 1))
	var start_x: float = -spread * 0.5

	for j in count:
		var ctrl := _instantiate_compound_control(SLIDER_VERTICAL_SCENE)
		if not ctrl:
			continue
		ctrl.transform.origin = Vector3(start_x + step * j, 0, 0)
		container.add_child(ctrl)


func _add_horizontal_slider_pack(container: Node3D, count: int, frame_width: float) -> void:
	if count >= 4:
		var columns := 2
		var rows := int(ceil(float(count) / float(columns)))
		var usable_width: float = frame_width - COMPOUND_INNER_MARGIN * 2.0
		var usable_height: float = COMPOUND_FRAME_HEIGHT - COMPOUND_INNER_MARGIN * 2.0
		var gap_x: float = 0.04
		var gap_y: float = 0.025
		var scale_x: float = (usable_width - gap_x * float(columns - 1)) / (HORIZONTAL_SLIDER_SIZE.x * float(columns))
		var scale_y: float = (usable_height - gap_y * float(rows - 1)) / (HORIZONTAL_SLIDER_SIZE.y * float(rows))
		var scale: float = clampf(minf(scale_x, scale_y), 0.85, 1.0)
		var x_step: float = HORIZONTAL_SLIDER_SIZE.x * scale + gap_x
		var y_step: float = HORIZONTAL_SLIDER_SIZE.y * scale + gap_y
		var start_x: float = -x_step * 0.5
		var start_y: float = y_step * 0.5

		for j in count:
			var ctrl := _instantiate_compound_control(SLIDER_HORIZONTAL_SCENE)
			if not ctrl:
				continue
			var col := j % columns
			var row := int(j / columns)
			ctrl.scale = Vector3.ONE * scale
			ctrl.transform.origin = Vector3(start_x + col * x_step, start_y - row * y_step, 0)
			container.add_child(ctrl)
		return

	var usable_height: float = COMPOUND_FRAME_HEIGHT - COMPOUND_INNER_MARGIN * 2.0
	var scale: float = (usable_height - HORIZONTAL_SLIDER_GAP * float(count - 1)) / (HORIZONTAL_SLIDER_SIZE.y * float(count))
	scale = clampf(scale, 0.7, 1.0)

	var slider_height: float = HORIZONTAL_SLIDER_SIZE.y * scale
	var total_height: float = slider_height * count + HORIZONTAL_SLIDER_GAP * float(count - 1)
	var top_y: float = total_height * 0.5 - slider_height * 0.5

	for j in count:
		var ctrl := _instantiate_compound_control(SLIDER_HORIZONTAL_SCENE)
		if not ctrl:
			continue
		ctrl.scale = Vector3.ONE * scale
		ctrl.transform.origin = Vector3(0, top_y - j * (slider_height + HORIZONTAL_SLIDER_GAP), 0)
		container.add_child(ctrl)


func _build_compound(container: Node3D, comp_type: String, count: int, frame_width: float) -> void:
	match comp_type:
		"sliders_v":
			_add_vertical_slider_pack(container, count, frame_width)

		"sliders_h":
			_add_horizontal_slider_pack(container, count, frame_width)

		"monitor_sliders":
			# Monitor on top, sliders below
			RackPassiveElementsScript.build_monitor(container, 0.09, 0.04)
			# Shift monitor up
			for child in container.get_children():
				if child is Node3D:
					child.transform.origin.y += 0.03
			# Add sliders below
			var gap := 0.03
			var offset := -(count - 1) * gap / 2.0
			for j in count:
				var ctrl := _instantiate_compound_control(SLIDER_VERTICAL_SCENE)
				if not ctrl:
					continue
				ctrl.transform.origin = Vector3(offset + j * gap, -0.03, 0)
				ctrl.scale = Vector3.ONE * 0.55
				container.add_child(ctrl)

		"speaker_meters":
			# Speaker on top, meters below
			var sp := Node3D.new()
			sp.transform.origin = Vector3(0, 0.025, 0)
			sp.scale = Vector3.ONE * 0.6
			container.add_child(sp)
			RackPassiveElementsScript.build_speaker_dots(sp)
			# Meters below
			var gap := 0.035
			for j in count:
				var m := Node3D.new()
				m.transform.origin = Vector3((j - 0.5) * gap, -0.04, 0)
				m.scale = Vector3.ONE * 0.5
				container.add_child(m)
				RackPassiveElementsScript.build_vu_meter_v(m)

		"meters_v":
			# Multiple VU meters side by side
			var gap := 0.03
			var offset := -(count - 1) * gap / 2.0
			for j in count:
				var m := Node3D.new()
				m.transform.origin = Vector3(offset + j * gap, 0, 0)
				m.scale = Vector3.ONE * 0.7
				container.add_child(m)
				RackPassiveElementsScript.build_vu_meter_v(m)


func _spawn_new_modules():
	if new_modules.is_empty():
		return
	var total_slots: float = 0
	for def in new_modules:
		total_slots += def.get("width", 1)
	var total_w4: float = total_slots * spacing + 0.2

	var panel4 := MeshInstance3D.new()
	panel4.name = "BackPanel4"
	var box4 := BoxMesh.new()
	box4.size = Vector3(total_w4, 0.45, 0.008)
	panel4.mesh = box4
	var mat4 := StandardMaterial3D.new()
	mat4.albedo_color = panel_color
	mat4.metallic = 0.3
	mat4.roughness = 0.6
	panel4.material_override = mat4
	panel4.transform.origin = Vector3(0, row4_y, -0.005)
	add_child(panel4)

	var title4 := Label3D.new()
	title4.text = row4_title_text
	title4.font_size = 28
	title4.pixel_size = 0.0007
	title4.modulate = Color(1.0, 1.0, 1.0)
	title4.outline_size = 5
	title4.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	title4.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title4.transform.origin = Vector3(0, row4_y + 0.28, control_z + 0.01)
	add_child(title4)

	var x_cursor: float = -total_w4 / 2.0 + 0.1
	for i in new_modules.size():
		var def: Dictionary = new_modules[i]
		var mod_type: String = def["type"]
		var label_text: String = def["label"]
		var elem_width: int = def.get("width", 1)
		var x_pos: float = x_cursor + (elem_width * spacing) / 2.0

		var container := Node3D.new()
		container.name = "NewModule_%d" % i
		container.transform.origin = Vector3(x_pos, row4_y, control_z)
		add_child(container)

		_build_new_module(container, mod_type, accent_color, dark_color, cream_color, def)
		_frame_container_content("NewFrame_%d" % i, container, Vector2(0.06, 0.06), Vector2(0.01, 0.01))

		var lbl := Label3D.new()
		lbl.name = "NewLabel_%d" % i
		lbl.text = label_text
		lbl.font_size = 24
		lbl.pixel_size = 0.0006
		lbl.modulate = Color(1.0, 1.0, 1.0)
		lbl.outline_size = 5
		lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		lbl.transform.origin = Vector3(x_pos, row4_y - 0.18, control_z + 0.01)
		add_child(lbl)

		x_cursor += elem_width * spacing


func _build_new_module(c: Node3D, t: String, copper: Color, dark: Color, cream: Color, def: Dictionary = {}) -> void:
	match t:
		"touch_grid":
			# XY touch surface — dark pad with grid lines + copper cursor
			var s := 0.09
			var pad_mat := StandardMaterial3D.new()
			pad_mat.albedo_color = Color(0.05, 0.05, 0.05)
			pad_mat.metallic = 0.2
			pad_mat.roughness = 0.8
			var pad := MeshInstance3D.new()
			pad.mesh = BoxMesh.new()
			pad.mesh.size = Vector3(s, s, 0.005)
			pad.material_override = pad_mat
			c.add_child(pad)
			# Grid lines
			var grid_mat := StandardMaterial3D.new()
			grid_mat.albedo_color = Color(0.2, 0.2, 0.2)
			for gi in 5:
				var line_h := MeshInstance3D.new()
				line_h.mesh = BoxMesh.new()
				line_h.mesh.size = Vector3(s * 0.9, 0.0008, 0.001)
				line_h.material_override = grid_mat
				line_h.transform.origin = Vector3(0, -s * 0.4 + gi * s * 0.2, 0.004)
				c.add_child(line_h)
				var line_v := MeshInstance3D.new()
				line_v.mesh = BoxMesh.new()
				line_v.mesh.size = Vector3(0.0008, s * 0.9, 0.001)
				line_v.material_override = grid_mat
				line_v.transform.origin = Vector3(-s * 0.4 + gi * s * 0.2, 0, 0.004)
				c.add_child(line_v)
			# Cursor
			var cursor_mat := StandardMaterial3D.new()
			cursor_mat.albedo_color = copper
			cursor_mat.emission_enabled = true
			cursor_mat.emission = copper
			cursor_mat.emission_energy_multiplier = 0.6
			var cursor := MeshInstance3D.new()
			cursor.mesh = SphereMesh.new()
			cursor.mesh.radius = 0.006
			cursor.mesh.height = 0.012
			cursor.material_override = cursor_mat
			cursor.transform.origin = Vector3(0.01, -0.01, 0.006)
			c.add_child(cursor)
			# Crosshair lines from cursor
			var ch_mat := StandardMaterial3D.new()
			ch_mat.albedo_color = Color(copper, 0.4)
			var ch_h := MeshInstance3D.new()
			ch_h.mesh = BoxMesh.new()
			ch_h.mesh.size = Vector3(s, 0.0005, 0.001)
			ch_h.material_override = ch_mat
			ch_h.transform.origin = Vector3(0, -0.01, 0.005)
			c.add_child(ch_h)
			var ch_v := MeshInstance3D.new()
			ch_v.mesh = BoxMesh.new()
			ch_v.mesh.size = Vector3(0.0005, s, 0.001)
			ch_v.material_override = ch_mat
			ch_v.transform.origin = Vector3(0.01, 0, 0.005)
			c.add_child(ch_v)

		"rotary_selector":
			# Stepped rotary — circle with position dots around edge
			var r := 0.035
			var steps := 8
			# Body
			var body_mat := StandardMaterial3D.new()
			body_mat.albedo_color = Color(0.12, 0.12, 0.12)
			body_mat.metallic = 0.7
			body_mat.roughness = 0.3
			var body := MeshInstance3D.new()
			var bm := CylinderMesh.new()
			bm.top_radius = r * 0.75
			bm.bottom_radius = r * 0.8
			bm.height = 0.014
			bm.radial_segments = 32
			body.mesh = bm
			body.material_override = body_mat
			body.rotation_degrees.x = 90
			body.transform.origin.z = 0.007
			c.add_child(body)
			# Outer ring
			var ring_mat := StandardMaterial3D.new()
			ring_mat.albedo_color = dark
			var ring := MeshInstance3D.new()
			var rm := TorusMesh.new()
			rm.inner_radius = r
			rm.outer_radius = r + 0.003
			rm.rings = 8
			rm.ring_segments = 32
			ring.mesh = rm
			ring.material_override = ring_mat
			c.add_child(ring)
			# Position dots
			var start_a := deg_to_rad(135.0)
			var sweep_a := deg_to_rad(270.0)
			for si in steps:
				var pct := float(si) / float(steps - 1)
				var angle := start_a + sweep_a * pct
				var is_selected := si == 2  # default position
				var dot_mat := StandardMaterial3D.new()
				dot_mat.albedo_color = copper if is_selected else Color(0.4, 0.4, 0.4)
				if is_selected:
					dot_mat.emission_enabled = true
					dot_mat.emission = copper
					dot_mat.emission_energy_multiplier = 0.5
				var dot := MeshInstance3D.new()
				dot.mesh = SphereMesh.new()
				dot.mesh.radius = 0.003 if is_selected else 0.002
				dot.mesh.height = 0.006 if is_selected else 0.004
				dot.material_override = dot_mat
				dot.transform.origin = Vector3(cos(angle) * (r + 0.008), sin(angle) * (r + 0.008), 0.003)
				c.add_child(dot)
			# Pointer
			var ptr_mat := StandardMaterial3D.new()
			ptr_mat.albedo_color = Color(0.9, 0.9, 0.85)
			var ptr_angle := start_a + sweep_a * (2.0 / 7.0)
			var ptr := MeshInstance3D.new()
			ptr.mesh = BoxMesh.new()
			ptr.mesh.size = Vector3(0.002, r * 0.5, 0.002)
			ptr.material_override = ptr_mat
			ptr.transform.origin = Vector3(cos(ptr_angle) * r * 0.35, sin(ptr_angle) * r * 0.35, 0.015)
			ptr.rotation.z = -ptr_angle
			c.add_child(ptr)

		"needle_meter":
			# Analog needle meter — cream face, arc scale, needle
			var mw := 0.09
			var mh := 0.07
			# Face
			var face_mat := StandardMaterial3D.new()
			face_mat.albedo_color = cream
			face_mat.metallic = 0.1
			face_mat.roughness = 0.8
			var face := MeshInstance3D.new()
			face.mesh = BoxMesh.new()
			face.mesh.size = Vector3(mw, mh, 0.004)
			face.material_override = face_mat
			c.add_child(face)
			# Arc scale (tick marks)
			var arc_r := mw * 0.38
			var arc_center := Vector3(0, -mh * 0.25, 0.003)
			var arc_mat := StandardMaterial3D.new()
			arc_mat.albedo_color = dark
			for ti in 11:
				var pct := float(ti) / 10.0
				var angle := deg_to_rad(180.0 + pct * 180.0)
				var is_major := ti % 5 == 0
				var t_inner := arc_r * 0.85
				var t_outer := arc_r * (1.05 if is_major else 0.98)
				var tick := MeshInstance3D.new()
				tick.mesh = BoxMesh.new()
				tick.mesh.size = Vector3(0.001, (t_outer - t_inner), 0.001)
				tick.material_override = arc_mat
				var mid_r := (t_inner + t_outer) / 2.0
				tick.transform.origin = arc_center + Vector3(cos(angle) * mid_r, sin(angle) * mid_r, 0)
				tick.rotation.z = angle - deg_to_rad(90)
				c.add_child(tick)
			# Needle
			var needle_mat := StandardMaterial3D.new()
			needle_mat.albedo_color = copper
			needle_mat.emission_enabled = true
			needle_mat.emission = copper
			needle_mat.emission_energy_multiplier = 0.4
			var needle_angle := deg_to_rad(180.0 + 0.65 * 180.0)
			var needle := MeshInstance3D.new()
			needle.mesh = BoxMesh.new()
			needle.mesh.size = Vector3(0.0015, arc_r * 0.9, 0.001)
			needle.material_override = needle_mat
			needle.transform.origin = arc_center + Vector3(cos(needle_angle) * arc_r * 0.45, sin(needle_angle) * arc_r * 0.45, 0.001)
			needle.rotation.z = needle_angle - deg_to_rad(90)
			c.add_child(needle)
			# Pivot dot
			var pivot_mat := StandardMaterial3D.new()
			pivot_mat.albedo_color = dark
			var pivot := MeshInstance3D.new()
			pivot.mesh = SphereMesh.new()
			pivot.mesh.radius = 0.003
			pivot.mesh.height = 0.006
			pivot.material_override = pivot_mat
			pivot.transform.origin = arc_center + Vector3(0, 0, 0.002)
			c.add_child(pivot)

		"patch_matrix":
			# 4x2 jack grid — output row on top, input row on bottom
			var cols := 4
			var gap_x := 0.022
			var gap_y := 0.04
			var start_x := -(cols - 1) * gap_x / 2.0
			# Output jacks (top row, orange rings)
			for ji in cols:
				var jx := start_x + ji * gap_x
				var socket_mat := StandardMaterial3D.new()
				socket_mat.albedo_color = Color(0.02, 0.02, 0.02)
				var socket := MeshInstance3D.new()
				var sm := CylinderMesh.new()
				sm.top_radius = 0.005
				sm.bottom_radius = 0.004
				sm.height = 0.005
				sm.radial_segments = 16
				socket.mesh = sm
				socket.material_override = socket_mat
				socket.rotation_degrees.x = 90
				socket.transform.origin = Vector3(jx, gap_y / 2.0, 0)
				c.add_child(socket)
				var ring_mat := StandardMaterial3D.new()
				ring_mat.albedo_color = copper
				ring_mat.emission_enabled = true
				ring_mat.emission = copper
				ring_mat.emission_energy_multiplier = 0.4
				var ring := MeshInstance3D.new()
				var rrm := TorusMesh.new()
				rrm.inner_radius = 0.006
				rrm.outer_radius = 0.008
				rrm.rings = 8
				rrm.ring_segments = 16
				ring.mesh = rrm
				ring.material_override = ring_mat
				ring.transform.origin = Vector3(jx, gap_y / 2.0, 0.003)
				c.add_child(ring)
			# Input jacks (bottom row, blue rings)
			for ji in cols:
				var jx := start_x + ji * gap_x
				var socket_mat := StandardMaterial3D.new()
				socket_mat.albedo_color = Color(0.02, 0.02, 0.02)
				var socket := MeshInstance3D.new()
				var sm := CylinderMesh.new()
				sm.top_radius = 0.005
				sm.bottom_radius = 0.004
				sm.height = 0.005
				sm.radial_segments = 16
				socket.mesh = sm
				socket.material_override = socket_mat
				socket.rotation_degrees.x = 90
				socket.transform.origin = Vector3(jx, -gap_y / 2.0, 0)
				c.add_child(socket)
				var ring_mat := StandardMaterial3D.new()
				ring_mat.albedo_color = Color(0.27, 0.55, 0.95)
				ring_mat.emission_enabled = true
				ring_mat.emission = Color(0.27, 0.55, 0.95)
				ring_mat.emission_energy_multiplier = 0.4
				var ring := MeshInstance3D.new()
				var rrm := TorusMesh.new()
				rrm.inner_radius = 0.006
				rrm.outer_radius = 0.008
				rrm.rings = 8
				rrm.ring_segments = 16
				ring.mesh = rrm
				ring.material_override = ring_mat
				ring.transform.origin = Vector3(jx, -gap_y / 2.0, 0.003)
				c.add_child(ring)
			# Divider line between rows
			var div_mat := StandardMaterial3D.new()
			div_mat.albedo_color = Color(0.3, 0.3, 0.3)
			var div := MeshInstance3D.new()
			div.mesh = BoxMesh.new()
			div.mesh.size = Vector3(cols * gap_x + 0.01, 0.001, 0.001)
			div.material_override = div_mat
			div.transform.origin = Vector3(0, 0, 0.003)
			c.add_child(div)
			# Labels
			var out_lbl := Label3D.new()
			out_lbl.text = "OUT"
			out_lbl.font_size = 14
			out_lbl.pixel_size = 0.0004
			out_lbl.modulate = copper
			out_lbl.transform.origin = Vector3(0, gap_y / 2.0 + 0.015, 0.005)
			c.add_child(out_lbl)
			var in_lbl := Label3D.new()
			in_lbl.text = "IN"
			in_lbl.font_size = 14
			in_lbl.pixel_size = 0.0004
			in_lbl.modulate = Color(0.27, 0.55, 0.95)
			in_lbl.transform.origin = Vector3(0, -gap_y / 2.0 - 0.015, 0.005)
			c.add_child(in_lbl)

		"text_static_1":
			RackPassiveElementsScript.build_text_display_static(c, 1, "440 Hz")
		"text_static_2":
			RackPassiveElementsScript.build_text_display_static(c, 2, "FREQUENCY: 440 Hz")
		"text_static_3":
			RackPassiveElementsScript.build_text_display_static(c, 3, "ADA RESEARCH — DIETER RAMS RACK")
		"text_scroll_1":
			RackPassiveElementsScript.build_text_display_scroll(c, 1, "SINE 440Hz")
		"text_scroll_2":
			RackPassiveElementsScript.build_text_display_scroll(c, 2, "FREQUENCY MODULATION — CARRIER 440Hz — DEPTH 0.5")
		"text_scroll_3":
			RackPassiveElementsScript.build_text_display_scroll(c, 3, "ADA RESEARCH — ALGORITHMS THROUGH ARCHITECTURE — DIETER RAMS EURORACK INTERFACE")
		"audio_controller_preset":
			_build_audio_controller_preset_module(c, def, copper, dark, cream)
		"rack_scene_preset":
			_build_rack_scene_preset_module(c, def, copper, dark, cream)
		"audio_token_strip":
			_build_audio_token_strip(c, def, copper, dark, cream)
		"live_audio_controller":
			_build_live_audio_controller_module(c, def, copper, dark, cream)


func _build_audio_controller_preset_module(c: Node3D, def: Dictionary, copper: Color, dark: Color, cream: Color) -> void:
	var preset := str(def.get("preset", "basic_mono"))
	var token := str(def.get("token", "AudioContr#preset:%s" % preset))
	var width := 0.48
	var height := 0.20
	var face := _make_box(Vector3(width, height, 0.006), cream, 0.0)
	c.add_child(face)

	var header := _make_box(Vector3(width, 0.028, 0.004), dark, 0.0)
	header.transform.origin = Vector3(0.0, height * 0.5 - 0.014, 0.006)
	c.add_child(header)
	_add_small_label(c, "AudioContr", Vector3(-width * 0.32, height * 0.5 - 0.014, 0.011), 13, copper)
	_add_small_label(c, preset.to_upper(), Vector3(width * 0.18, height * 0.5 - 0.014, 0.011), 11, Color(1, 1, 1))

	var knob_count := int(def.get("knobs", 3))
	var slider_count := int(def.get("sliders", 2))
	var start_x := -0.155
	for i in knob_count:
		var x := start_x + float(i) * 0.060
		_add_embedded_control(c, "res://commons/interactables/dial_smooth.tscn", Vector3(x, 0.030, 0.016), 0.42, Vector2(0.060, 0.060))

	for i in slider_count:
		var x := 0.105 + float(i) * 0.060
		var slider_scene := "res://commons/interactables/slider_smooth.tscn" if i % 2 == 0 else "res://commons/interactables/slider_horizontal.tscn"
		var slider_scale := 0.42 if i % 2 == 0 else 0.36
		var frame_size := Vector2(0.060, 0.120) if i % 2 == 0 else Vector2(0.105, 0.050)
		_add_embedded_control(c, slider_scene, Vector3(x, -0.020, 0.016), slider_scale, frame_size)

	_add_small_label(c, token, Vector3(0.0, -height * 0.5 + 0.022, 0.012), 9, dark)


func _build_rack_scene_preset_module(c: Node3D, def: Dictionary, copper: Color, dark: Color, cream: Color) -> void:
	var config := str(def.get("config", "rack_303_acid"))
	var sound := str(def.get("sound", "ACID"))
	var width := 0.52
	var height := 0.21
	var face := _make_box(Vector3(width, height, 0.006), Color(0.08, 0.09, 0.10), 0.0)
	c.add_child(face)

	var rail_top := _make_box(Vector3(width, 0.010, 0.004), cream, 0.0)
	rail_top.transform.origin = Vector3(0.0, height * 0.5 - 0.010, 0.007)
	c.add_child(rail_top)
	var rail_bottom := _make_box(Vector3(width, 0.010, 0.004), cream, 0.0)
	rail_bottom.transform.origin = Vector3(0.0, -height * 0.5 + 0.010, 0.007)
	c.add_child(rail_bottom)

	var modules := int(def.get("modules", 5))
	var usable_w := width - 0.04
	var slot_w := usable_w / float(maxi(1, modules))
	var left := -usable_w * 0.5 + slot_w * 0.5
	for i in modules:
		var h := 0.09 + 0.025 * float((i + modules) % 3) / 2.0
		var module_color := cream if i % 2 == 0 else Color(0.72, 0.75, 0.78)
		var module := _make_box(Vector3(slot_w * 0.74, h, 0.005), module_color, 0.0)
		module.transform.origin = Vector3(left + float(i) * slot_w, -0.004, 0.010)
		c.add_child(module)
		if i % 3 == 0:
			_add_embedded_control(c, "res://commons/interactables/dial_smooth.tscn", module.transform.origin + Vector3(0, 0.020, 0.010), 0.32, Vector2(0.046, 0.046))
		elif i % 3 == 1:
			_add_embedded_control(c, "res://commons/interactables/slider_horizontal.tscn", module.transform.origin + Vector3(0, 0.018, 0.010), 0.27, Vector2(0.080, 0.040))
		else:
			_add_embedded_control(c, "res://commons/interactables/push_button.tscn", module.transform.origin + Vector3(0, 0.020, 0.010), 0.36, Vector2(0.044, 0.044))

	_add_small_label(c, "RackPreset#config:%s" % config, Vector3(0.0, -height * 0.5 + 0.024, 0.012), 9, copper)
	_add_small_label(c, sound.to_upper(), Vector3(0.0, height * 0.5 - 0.028, 0.012), 10, Color(1, 1, 1))


func _build_audio_token_strip(c: Node3D, def: Dictionary, copper: Color, dark: Color, cream: Color) -> void:
	var token := str(def.get("token", "AudioContr:-90#preset:basic_mono"))
	var width := 0.58
	var height := 0.070
	var base := _make_box(Vector3(width, height, 0.006), dark, 0.0)
	c.add_child(base)
	var line := _make_box(Vector3(width - 0.04, 0.004, 0.002), copper, 0.65)
	line.transform.origin = Vector3(0.0, 0.020, 0.009)
	c.add_child(line)
	_add_small_label(c, token, Vector3(0.0, -0.008, 0.012), 10, Color(1, 1, 1))


func _build_live_audio_controller_module(c: Node3D, def: Dictionary, copper: Color, dark: Color, cream: Color) -> void:
	var preset := str(def.get("preset", "basic_mono"))
	var token := str(def.get("token", "AudioContr#preset:%s" % preset))
	var width := 0.74
	var height := 0.46
	var back := _make_box(Vector3(width, height, 0.008), cream, 0.0)
	c.add_child(back)

	var header := _make_box(Vector3(width, 0.032, 0.004), dark, 0.0)
	header.transform.origin = Vector3(0.0, height * 0.5 - 0.016, 0.007)
	c.add_child(header)
	_add_small_label(c, "LIVE AudioContr", Vector3(-width * 0.30, height * 0.5 - 0.016, 0.013), 13, copper)
	_add_small_label(c, preset.to_upper(), Vector3(width * 0.23, height * 0.5 - 0.016, 0.013), 11, Color(1, 1, 1))
	_add_local_outline_frame(c, "LiveAudioFrame", Vector3(0, -0.015, 0.010), width - 0.06, height - 0.070)

	var uvac_scene := load("res://commons/audio/UniversalVRAudioController.tscn") as PackedScene
	if uvac_scene:
		var uvac := uvac_scene.instantiate() as Node3D
		if uvac:
			uvac.name = "LiveAudioContr"
			uvac.set("eurorack_preset_name", preset)
			if def.has("config"):
				uvac.set("rack_config_path", "res://commons/audio/rack_configs/%s.json" % str(def["config"]))
			uvac.scale = Vector3.ONE * float(def.get("live_scale", 0.34))
			uvac.transform.origin = Vector3(0.0, -0.020, 0.035)
			c.add_child(uvac)

	_add_small_label(c, token, Vector3(0.0, -height * 0.5 + 0.024, 0.013), 9, dark)


func _make_box(size: Vector3, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _make_mat(color, emission)
	return mi


func _add_mini_knob(c: Node3D, pos: Vector3, dark: Color, copper: Color) -> void:
	var knob := MeshInstance3D.new()
	var km := CylinderMesh.new()
	km.top_radius = 0.009
	km.bottom_radius = 0.010
	km.height = 0.005
	km.radial_segments = 16
	knob.mesh = km
	knob.rotation_degrees.x = 90
	knob.material_override = _make_mat(dark, 0.0)
	knob.transform.origin = pos
	c.add_child(knob)
	var marker := _make_box(Vector3(0.002, 0.008, 0.001), copper, 0.35)
	marker.transform.origin = pos + Vector3(0.002, 0.003, 0.004)
	marker.rotation.z = 0.7
	c.add_child(marker)


func _add_embedded_control(c: Node3D, scene_path: String, pos: Vector3, scale_value: float, frame_size: Vector2 = Vector2.ZERO) -> void:
	if frame_size != Vector2.ZERO:
		_add_local_outline_frame(c, "EmbeddedFrame", pos - Vector3(0, 0, 0.006), frame_size.x, frame_size.y)
	var control := _instantiate_compound_control(scene_path)
	if not control:
		return
	control.transform.origin = pos
	control.scale = Vector3.ONE * scale_value
	c.add_child(control)


func _add_local_outline_frame(parent: Node3D, frame_name: String, center: Vector3, width: float, height: float) -> void:
	var frame_root := Node3D.new()
	frame_root.name = frame_name
	frame_root.transform.origin = center + Vector3(0, 0, FRAME_Z_OFFSET)
	parent.add_child(frame_root)

	var frame_mat := _make_frame_material()
	var horizontal_width: float = maxf(width, FRAME_BAR_THICKNESS)
	var vertical_height: float = maxf(height - FRAME_BAR_THICKNESS * 2.0, FRAME_BAR_THICKNESS)
	var segments := [
		{ "size": Vector3(horizontal_width, FRAME_BAR_THICKNESS, FRAME_BAR_DEPTH), "pos": Vector3(0, height * 0.5 - FRAME_BAR_THICKNESS * 0.5, 0) },
		{ "size": Vector3(horizontal_width, FRAME_BAR_THICKNESS, FRAME_BAR_DEPTH), "pos": Vector3(0, -height * 0.5 + FRAME_BAR_THICKNESS * 0.5, 0) },
		{ "size": Vector3(FRAME_BAR_THICKNESS, vertical_height, FRAME_BAR_DEPTH), "pos": Vector3(-width * 0.5 + FRAME_BAR_THICKNESS * 0.5, 0, 0) },
		{ "size": Vector3(FRAME_BAR_THICKNESS, vertical_height, FRAME_BAR_DEPTH), "pos": Vector3(width * 0.5 - FRAME_BAR_THICKNESS * 0.5, 0, 0) },
	]
	for i in segments.size():
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "%s_%d" % [frame_name, i]
		var box := BoxMesh.new()
		box.size = segments[i]["size"]
		mesh_instance.mesh = box
		mesh_instance.material_override = frame_mat
		mesh_instance.transform.origin = segments[i]["pos"]
		frame_root.add_child(mesh_instance)


func _add_small_label(c: Node3D, text_value: String, pos: Vector3, size: int, color_value: Color) -> void:
	var lbl := Label3D.new()
	lbl.text = text_value
	lbl.font_size = size
	lbl.pixel_size = 0.00045
	lbl.width = 1200
	lbl.modulate = color_value
	lbl.outline_size = 3
	lbl.outline_modulate = Color(0, 0, 0, 0.9)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.transform.origin = pos
	c.add_child(lbl)


func _add_title():
	if main_title_text.is_empty():
		return
	var title := Label3D.new()
	title.name = "Title"
	title.text = main_title_text
	title.font_size = 36
	title.pixel_size = 0.0008
	title.modulate = Color(0.10, 0.10, 0.10)
	title.outline_size = 3
	title.outline_modulate = Color(0.7, 0.68, 0.64, 0.4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.transform.origin = Vector3(0, row_y + 0.28, control_z + 0.005)
	add_child(title)


func apply_grid_config(_config: Dictionary) -> void:
	pass  # Map placement compatibility
