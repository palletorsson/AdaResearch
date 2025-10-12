# ===========================================================================
# NOC Example 3.11: A Spring Connection
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_SPRING := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")
const MAT_BOB := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

@export var spring_constant: float = 0.1
@export var damping: float = 0.98
@export var rest_length: float = 0.2

var _sim_root: Node3D
var _anchor_pos: Vector3 = Vector3(0, 0.85, 0)
var _bob: Bob
var _spring_mesh: MeshInstance3D
var _status_label: Label3D
var _controller_root: Node3D

func _ready() -> void:
	_setup_environment()
	_spawn_scene()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 22
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_sim_root.add_child(_status_label)

	_controller_root = Node3D.new()
	_controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(_controller_root)

	var k_controller := CONTROLLER_SCENE.instantiate()
	k_controller.parameter_name = "Spring K"
	k_controller.min_value = 0.02
	k_controller.max_value = 0.3
	k_controller.default_value = spring_constant
	k_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(k_controller)
	k_controller.value_changed.connect(func(v: float) -> void:
		spring_constant = v
	)
	k_controller.set_value(spring_constant)

	var damping_controller := CONTROLLER_SCENE.instantiate()
	damping_controller.parameter_name = "Damping"
	damping_controller.min_value = 0.9
	damping_controller.max_value = 0.999
	damping_controller.default_value = damping
	damping_controller.position = Vector3(0, -0.18, 0)
	damping_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(damping_controller)
	damping_controller.value_changed.connect(func(v: float) -> void:
		damping = v
	)
	damping_controller.set_value(damping)

func _spawn_scene() -> void:
	_bob = Bob.new()
	_bob.init(_sim_root, MAT_BOB)
	_bob.position = Vector3(0, 0.5, 0)

	_spring_mesh = MeshInstance3D.new()
	_sim_root.add_child(_spring_mesh)

func _process(delta: float) -> void:
	var spring_dir := _anchor_pos - _bob.position
	var current_length := spring_dir.length()
	var extension := current_length - rest_length
	spring_dir = spring_dir.normalized()
	var spring_force := spring_dir * spring_constant * extension

	_bob.apply_force(spring_force)
	_bob.apply_force(Vector3(0, -0.1, 0))
	_bob.velocity *= damping
	_bob.update(delta)

	_update_spring()

	_status_label.text = "Spring | Ext %.2f" % extension

func _update_spring() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	var num_coils := 12
	var coil_radius := 0.02
	var direction := (_bob.position - _anchor_pos).normalized()
	var length := _anchor_pos.distance_to(_bob.position)

	for i in range(num_coils * 4):
		var t := float(i) / (num_coils * 4)
		var pos_along := _anchor_pos + direction * (length * t)
		var angle := t * num_coils * TAU
		var offset := Vector3(cos(angle), 0, sin(angle)) * coil_radius
		mesh.surface_set_color(Color(1.0, 0.7, 0.95, 0.8))
		mesh.surface_add_vertex(pos_along + offset)

	mesh.surface_end()
	_spring_mesh.mesh = mesh

class Bob:
	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO

	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, mat: Material) -> void:
		root = Node3D.new()
		root.name = "Bob"
		parent.add_child(root)

		body = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.04
		body.mesh = sphere
		body.material_override = mat
		root.add_child(body)

	func apply_force(force: Vector3) -> void:
		acceleration += force

	func update(delta: float) -> void:
		velocity += acceleration
		position += velocity * delta * 60.0
		acceleration = Vector3.ZERO

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()
