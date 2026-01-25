# quest_controller.gd - Procedural Quest controller model for tutorials
# Simple representation of Meta Quest Touch controller
extends Node3D

const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")

@export var is_right_hand: bool = true
@export var body_color: Color = Color(0.9, 0.9, 0.9)  # White/light gray
@export var button_color: Color = Color(0.2, 0.2, 0.2)  # Dark gray
@export var highlight_color: Color = Color(0.2, 0.9, 1.0)  # Cyan highlight

## Which button to highlight (for tutorials)
@export_enum("none", "trigger", "grip", "thumbstick", "button_a", "button_b", "menu") var highlight_button: String = "none"

var _body_mesh: MeshInstance3D
var _ring_mesh: MeshInstance3D
var _thumbstick_mesh: MeshInstance3D
var _button_a_mesh: MeshInstance3D
var _button_b_mesh: MeshInstance3D
var _trigger_mesh: MeshInstance3D
var _grip_mesh: MeshInstance3D
var _menu_mesh: MeshInstance3D

func _ready():
	_build_controller()

func _build_controller():
	# Clean up existing
	for child in get_children():
		child.queue_free()

	var mirror = -1.0 if is_right_hand else 1.0

	# Main body - elongated capsule shape
	_body_mesh = _create_body()
	add_child(_body_mesh)

	# Tracking ring at top
	_ring_mesh = _create_tracking_ring()
	_ring_mesh.position = Vector3(0, 0.06, -0.02)
	add_child(_ring_mesh)

	# Thumbstick
	_thumbstick_mesh = _create_thumbstick()
	_thumbstick_mesh.position = Vector3(0.012 * mirror, 0.045, 0.015)
	add_child(_thumbstick_mesh)

	# Face buttons (A/B for right, X/Y for left)
	_button_a_mesh = _create_face_button()
	_button_a_mesh.position = Vector3(0.018 * mirror, 0.035, -0.005)
	add_child(_button_a_mesh)

	_button_b_mesh = _create_face_button()
	_button_b_mesh.position = Vector3(0.005 * mirror, 0.04, -0.015)
	add_child(_button_b_mesh)

	# Menu button (small, near thumbstick)
	_menu_mesh = _create_menu_button()
	_menu_mesh.position = Vector3(-0.008 * mirror, 0.042, 0.005)
	add_child(_menu_mesh)

	# Trigger
	_trigger_mesh = _create_trigger()
	_trigger_mesh.position = Vector3(0, -0.01, 0.025)
	add_child(_trigger_mesh)

	# Grip button
	_grip_mesh = _create_grip()
	_grip_mesh.position = Vector3(0.022 * mirror, -0.02, 0)
	add_child(_grip_mesh)

	# Add labels
	_add_button_labels(mirror)

	# Apply highlight
	_apply_highlight()

func _create_body() -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Body"

	# Capsule for grip
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.022
	capsule.height = 0.12
	mesh_instance.mesh = capsule

	var material = StandardMaterial3D.new()
	material.albedo_color = body_color
	material.roughness = 0.3
	mesh_instance.material_override = material

	return mesh_instance

func _create_tracking_ring() -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TrackingRing"

	var torus = TorusMesh.new()
	torus.inner_radius = 0.035
	torus.outer_radius = 0.045
	torus.rings = 16
	torus.ring_segments = 12
	mesh_instance.mesh = torus

	# Rotate to be horizontal and tilt forward
	mesh_instance.rotation_degrees = Vector3(75, 0, 0)

	var material = StandardMaterial3D.new()
	material.albedo_color = body_color
	material.roughness = 0.3
	mesh_instance.material_override = material

	return mesh_instance

func _create_thumbstick() -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Thumbstick"

	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.008
	cylinder.bottom_radius = 0.006
	cylinder.height = 0.012
	mesh_instance.mesh = cylinder

	var material = StandardMaterial3D.new()
	material.albedo_color = button_color
	material.roughness = 0.5
	mesh_instance.material_override = material

	return mesh_instance

func _create_face_button() -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "FaceButton"

	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.005
	cylinder.bottom_radius = 0.005
	cylinder.height = 0.004
	mesh_instance.mesh = cylinder

	var material = StandardMaterial3D.new()
	material.albedo_color = button_color
	material.roughness = 0.4
	mesh_instance.material_override = material

	return mesh_instance

func _create_menu_button() -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MenuButton"

	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.003
	cylinder.bottom_radius = 0.003
	cylinder.height = 0.002
	mesh_instance.mesh = cylinder

	var material = StandardMaterial3D.new()
	material.albedo_color = button_color
	material.roughness = 0.4
	mesh_instance.material_override = material

	return mesh_instance

func _create_trigger() -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Trigger"

	# Simple box for trigger
	var box = BoxMesh.new()
	box.size = Vector3(0.015, 0.025, 0.01)
	mesh_instance.mesh = box

	# Tilt trigger
	mesh_instance.rotation_degrees = Vector3(-30, 0, 0)

	var material = StandardMaterial3D.new()
	material.albedo_color = button_color
	material.roughness = 0.4
	mesh_instance.material_override = material

	return mesh_instance

func _create_grip() -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Grip"

	var box = BoxMesh.new()
	box.size = Vector3(0.008, 0.04, 0.02)
	mesh_instance.mesh = box

	var material = StandardMaterial3D.new()
	material.albedo_color = button_color
	material.roughness = 0.4
	mesh_instance.material_override = material

	return mesh_instance

func _add_button_labels(mirror: float):
	# A/X button label
	var label_a = Label3D.new()
	label_a.text = "B" if is_right_hand else "Y"
	label_a.font_size = 64
	label_a.pixel_size = 0.0003
	label_a.position = _button_a_mesh.position + Vector3(0, 0.003, 0)
	label_a.rotation_degrees = Vector3(-90, 0, 0)
	label_a.modulate = Color.WHITE
	label_a.outline_size = 0
	add_child(label_a)

	# B/Y button label
	var label_b = Label3D.new()
	label_b.text = "A" if is_right_hand else "X"
	label_b.font_size = 64
	label_b.pixel_size = 0.0003
	label_b.position = _button_b_mesh.position + Vector3(0, 0.003, 0)
	label_b.rotation_degrees = Vector3(-90, 0, 0)
	label_b.modulate = Color.WHITE
	label_b.outline_size = 0
	add_child(label_b)

func _apply_highlight():
	var target_mesh: MeshInstance3D = null

	match highlight_button:
		"trigger":
			target_mesh = _trigger_mesh
		"grip":
			target_mesh = _grip_mesh
		"thumbstick":
			target_mesh = _thumbstick_mesh
		"button_a":
			target_mesh = _button_a_mesh
		"button_b":
			target_mesh = _button_b_mesh
		"menu":
			target_mesh = _menu_mesh

	if target_mesh:
		var material = StandardMaterial3D.new()
		material.albedo_color = highlight_color
		material.emission_enabled = true
		material.emission = highlight_color
		material.emission_energy_multiplier = 0.8
		target_mesh.material_override = material

func set_highlight(button_name: String):
	highlight_button = button_name
	_apply_highlight()

func set_right_hand(is_right: bool):
	is_right_hand = is_right
	_build_controller()

## Grid system configuration
## Use: quest_controller#highlight:button_b#right:true
func apply_grid_config(config_data: Dictionary) -> void:
	var needs_rebuild = false

	if config_data.has("highlight"):
		highlight_button = str(config_data.highlight)

	if config_data.has("right"):
		var right_val = config_data.right
		if right_val is bool:
			is_right_hand = right_val
		else:
			is_right_hand = str(right_val).to_lower() == "true"
		needs_rebuild = true

	if config_data.has("left"):
		var left_val = config_data.left
		if left_val is bool:
			is_right_hand = not left_val
		else:
			is_right_hand = str(left_val).to_lower() != "true"
		needs_rebuild = true

	if needs_rebuild:
		_build_controller()
	else:
		_apply_highlight()
