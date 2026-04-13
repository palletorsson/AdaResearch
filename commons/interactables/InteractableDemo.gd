extends Node3D

const RackPassiveElementsScript = preload("res://commons/interactables/RackPassiveElements.gd")

## Interactable Demo — one row of every control type with labels.
## For inspecting, testing, and improving each VR control element.
## Run this scene directly or place as artifact in a map.

## Control definitions — scenes loaded at runtime (not preload) to avoid
## RigidBody3D script compilation errors with interactable_handle.gd
var CONTROLS := [
	{ "scene": "res://commons/interactables/push_button.tscn", "label": "BUTTON", "y": 0.0 },
	{ "scene": "res://commons/interactables/push_button_front.tscn", "label": "BUTTON\nFRONT", "y": 0.0 },
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

const SPACING := 0.30  # meters between each control
const CONTROL_Z := 0.02  # forward from back panel
const LABEL_Y_OFFSET := -0.18  # below control center
const ROW_Y := 1.1  # height of row center


const PASSIVE_ELEMENTS = [
	{ "builder": "build_speaker_dots", "label": "SPEAKER\nDOTS" },
	{ "builder": "build_speaker_lines", "label": "SPEAKER\nLINES" },
	{ "builder": "build_speaker_grid", "label": "SPEAKER\nGRID" },
	{ "builder": "build_vu_meter_v", "label": "VU METER\nV" },
	{ "builder": "build_vu_meter_h", "label": "VU METER\nH" },
	{ "builder": "build_monitor_sm", "label": "MONITOR\nSM" },
	{ "builder": "build_monitor_lg", "label": "MONITOR\nLG" },
]

const ROW2_Y := 0.65  # Second row below first


func _ready():
	_build_back_panel()
	_spawn_controls()
	_spawn_passive_elements()
	_add_title()
	print("InteractableDemo: %d controls + %d passive elements" % [CONTROLS.size(), PASSIVE_ELEMENTS.size()])


func _build_back_panel():
	var total_w: float = CONTROLS.size() * SPACING + 0.2
	var panel := MeshInstance3D.new()
	panel.name = "BackPanel"
	var box := BoxMesh.new()
	box.size = Vector3(total_w, 0.45, 0.008)
	panel.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.50, 0.48, 0.44)  # Warm gray (Rams)
	mat.metallic = 0.3
	mat.roughness = 0.6
	panel.material_override = mat
	panel.transform.origin = Vector3(0, ROW_Y, -0.005)
	add_child(panel)

	# Subtle border frame
	var frame := MeshInstance3D.new()
	frame.name = "Frame"
	var frame_box := BoxMesh.new()
	frame_box.size = Vector3(total_w + 0.02, 0.47, 0.004)
	frame.mesh = frame_box
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.35, 0.33, 0.30)
	frame_mat.metallic = 0.2
	frame_mat.roughness = 0.7
	frame.material_override = frame_mat
	frame.transform.origin = Vector3(0, ROW_Y, -0.008)
	add_child(frame)


func _spawn_controls():
	var start_x: float = -(CONTROLS.size() - 1) * SPACING / 2.0

	for i in CONTROLS.size():
		var def: Dictionary = CONTROLS[i]
		var scene_path: String = def["scene"]
		var label_text: String = def["label"]
		var y_offset: float = def.get("y", 0.0)

		var x_pos: float = start_x + i * SPACING

		# Load and instantiate control
		var scene := load(scene_path) as PackedScene
		if not scene:
			push_warning("InteractableDemo: Failed to load %s" % scene_path)
			continue

		# Black accent frame behind each control
		var frame := MeshInstance3D.new()
		frame.name = "Frame_%d" % i
		var frame_box := BoxMesh.new()
		frame_box.size = Vector3(0.12, 0.28, 0.004)
		frame.mesh = frame_box
		var frame_mat := StandardMaterial3D.new()
		frame_mat.albedo_color = Color(0.08, 0.08, 0.08)
		frame_mat.metallic = 0.3
		frame_mat.roughness = 0.7
		frame.material_override = frame_mat
		frame.transform.origin = Vector3(x_pos, ROW_Y + y_offset, CONTROL_Z - 0.004)
		add_child(frame)

		var control := scene.instantiate()
		control.name = "Control_%d" % i
		control.transform.origin = Vector3(x_pos, ROW_Y + y_offset, CONTROL_Z)
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
		lbl.transform.origin = Vector3(x_pos, ROW_Y + LABEL_Y_OFFSET, CONTROL_Z + 0.01)
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
		idx_lbl.transform.origin = Vector3(x_pos, ROW_Y + 0.20, CONTROL_Z + 0.01)
		add_child(idx_lbl)


func _spawn_passive_elements():
	var start_x: float = -(PASSIVE_ELEMENTS.size() - 1) * SPACING / 2.0

	# Back panel for row 2
	var total_w2: float = PASSIVE_ELEMENTS.size() * SPACING + 0.2
	var panel2 := MeshInstance3D.new()
	panel2.name = "BackPanel2"
	var box2 := BoxMesh.new()
	box2.size = Vector3(total_w2, 0.35, 0.008)
	panel2.mesh = box2
	var mat2 := StandardMaterial3D.new()
	mat2.albedo_color = Color(0.50, 0.48, 0.44)
	mat2.metallic = 0.3
	mat2.roughness = 0.6
	panel2.material_override = mat2
	panel2.transform.origin = Vector3(0, ROW2_Y, -0.005)
	add_child(panel2)

	# Title for row 2
	var title2 := Label3D.new()
	title2.text = "PASSIVE ELEMENTS"
	title2.font_size = 30
	title2.pixel_size = 0.0007
	title2.modulate = Color(1.0, 1.0, 1.0)
	title2.outline_size = 5
	title2.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	title2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title2.transform.origin = Vector3(0, ROW2_Y + 0.22, CONTROL_Z + 0.01)
	add_child(title2)

	for i in PASSIVE_ELEMENTS.size():
		var def: Dictionary = PASSIVE_ELEMENTS[i]
		var builder: String = def["builder"]
		var label_text: String = def["label"]
		var x_pos: float = start_x + i * SPACING

		# Black accent frame
		var frame := MeshInstance3D.new()
		frame.name = "PassiveFrame_%d" % i
		var frame_box := BoxMesh.new()
		frame_box.size = Vector3(0.12, 0.14, 0.004)
		frame.mesh = frame_box
		var frame_mat := StandardMaterial3D.new()
		frame_mat.albedo_color = Color(0.08, 0.08, 0.08)
		frame_mat.metallic = 0.3
		frame_mat.roughness = 0.7
		frame.material_override = frame_mat
		frame.transform.origin = Vector3(x_pos, ROW2_Y, CONTROL_Z - 0.004)
		add_child(frame)

		# Build the element
		var element := Node3D.new()
		element.name = "Passive_%d" % i
		element.transform.origin = Vector3(x_pos, ROW2_Y, CONTROL_Z)
		add_child(element)

		match builder:
			"build_speaker_dots":
				RackPassiveElementsScript.build_speaker_dots(element)
			"build_speaker_lines":
				RackPassiveElementsScript.build_speaker_lines(element)
			"build_speaker_grid":
				RackPassiveElementsScript.build_speaker_grid(element)
			"build_vu_meter_v":
				RackPassiveElementsScript.build_vu_meter_v(element)
			"build_vu_meter_h":
				RackPassiveElementsScript.build_vu_meter_h(element)
			"build_monitor_sm":
				RackPassiveElementsScript.build_monitor(element, 0.09, 0.06)
			"build_monitor_lg":
				RackPassiveElementsScript.build_monitor(element, 0.12, 0.08)

		# Label
		var lbl := Label3D.new()
		lbl.name = "PassiveLabel_%d" % i
		lbl.text = label_text
		lbl.font_size = 28
		lbl.pixel_size = 0.0006
		lbl.modulate = Color(1.0, 1.0, 1.0)
		lbl.outline_size = 5
		lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		lbl.transform.origin = Vector3(x_pos, ROW2_Y - 0.12, CONTROL_Z + 0.01)
		add_child(lbl)


func _add_title():
	var title := Label3D.new()
	title.name = "Title"
	title.text = "INTERACTABLE CONTROLS"
	title.font_size = 36
	title.pixel_size = 0.0008
	title.modulate = Color(0.10, 0.10, 0.10)
	title.outline_size = 3
	title.outline_modulate = Color(0.7, 0.68, 0.64, 0.4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.transform.origin = Vector3(0, ROW_Y + 0.28, CONTROL_Z + 0.005)
	add_child(title)


func apply_grid_config(_config: Dictionary) -> void:
	pass  # Map placement compatibility
