# ===========================================================================
# ForceVector.gd - Force Arrow Visualization Component
# Draws a 3D arrow representing a force vector (direction + magnitude)
# ===========================================================================
extends Node3D

class_name ForceVector

@export var force_color: Color = Color.RED
@export var force_strength: float = 1.0
@export var label_text: String = ""

var shaft: MeshInstance3D
var head: MeshInstance3D
var label: Label3D
var force_direction: Vector3 = Vector3.UP

func _ready() -> void:
	_create_arrow()

func _create_arrow() -> void:
	# Arrow shaft (cylinder)
	shaft = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.015
	cylinder.bottom_radius = 0.015
	cylinder.height = 1.0
	cylinder.radial_segments = 8
	shaft.mesh = cylinder
	shaft.position = Vector3(0, 0.5, 0)

	var shaft_mat = StandardMaterial3D.new()
	shaft_mat.albedo_color = force_color
	shaft_mat.emission_enabled = true
	shaft_mat.emission = force_color * 0.6
	shaft_mat.emission_energy_multiplier = 1.5
	shaft.material_override = shaft_mat
	add_child(shaft)

	# Arrow head (cone)
	head = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.06
	cone.height = 0.15
	cone.radial_segments = 8
	head.mesh = cone
	head.position = Vector3(0, 1.075, 0)

	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = force_color
	head_mat.emission_enabled = true
	head_mat.emission = force_color * 0.8
	head_mat.emission_energy_multiplier = 2.0
	head.material_override = head_mat
	add_child(head)

	# Optional label
	if label_text != "":
		label = Label3D.new()
		label.text = label_text
		label.font_size = 12
		label.modulate = force_color
		label.outline_size = 2
		label.outline_modulate = Color.BLACK
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0, 1.3, 0)
		add_child(label)

## Point the arrow from origin toward [direction], scaled by magnitude.
func set_force(direction: Vector3, magnitude: float = -1.0) -> void:
	if direction.length() < 0.001:
		visible = false
		return
	visible = true

	force_direction = direction.normalized()
	var mag = magnitude if magnitude >= 0.0 else direction.length()
	force_strength = mag

	# Scale the whole arrow by magnitude (clamped for readability)
	var arrow_scale = clamp(mag / 5.0, 0.15, 2.5)
	scale = Vector3(1, arrow_scale, 1)

	# Orient so local +Y points along the force direction
	if force_direction.length() > 0.001:
		var up = Vector3.RIGHT if abs(force_direction.dot(Vector3.UP)) > 0.99 else Vector3.UP
		look_at(global_position + force_direction, up)
		rotate_object_local(Vector3.RIGHT, -PI / 2.0)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
