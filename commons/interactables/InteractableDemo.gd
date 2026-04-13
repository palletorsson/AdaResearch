extends Node3D

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


func _ready():
	_build_back_panel()
	_spawn_controls()
	_add_title()
	print("InteractableDemo: %d controls spawned in a row" % CONTROLS.size())


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
