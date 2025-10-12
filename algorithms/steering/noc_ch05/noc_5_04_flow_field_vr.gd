# ===========================================================================
# NOC Example 5.04: Flow Field
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_VEHICLE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_FIELD := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")

@export var noise_scale: float = 0.25
@export var max_speed: float = 0.4
@export var max_force: float = 0.08

var _sim_root: Node3D
var _vehicle: Vehicle
var _field_mesh: MeshInstance3D
var _status_label: Label3D
var _field := FlowField.new()
var _controller_root: Node3D

func _ready() -> void:
	_setup_environment()
	_field.generate(noise_scale)
	_spawn_vehicle()
	_update_field_mesh()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_field_mesh = MeshInstance3D.new()
	_sim_root.add_child(_field_mesh)

	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 20
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_sim_root.add_child(_status_label)

	_controller_root = Node3D.new()
	_controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(_controller_root)

	var noise_controller := CONTROLLER_SCENE.instantiate()
	noise_controller.parameter_name = "Noise Scale"
	noise_controller.min_value = 0.1
	noise_controller.max_value = 0.6
	noise_controller.default_value = noise_scale
	noise_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(noise_controller)
	noise_controller.value_changed.connect(func(v: float) -> void:
		noise_scale = v
		_field.generate(noise_scale)
		_update_field_mesh()
	)
	noise_controller.set_value(noise_scale)

	_update_status()

func _spawn_vehicle() -> void:
	_vehicle = Vehicle.new()
	_vehicle.init(_sim_root, MAT_VEHICLE)
	_vehicle.position = Vector3(-0.35, 0.5, 0)
	_vehicle.max_speed = max_speed
	_vehicle.max_force = max_force

func _process(delta: float) -> void:
	_vehicle.follow(_field)
	_vehicle.update(delta)
	_vehicle.wrap_bounds()
	_update_status()

class FlowField:
	var cols: int = 24
	var rows: int = 24
	var field: Array[Vector3] = []
	var noise_obj: FastNoiseLite

	func _init():
		noise_obj = FastNoiseLite.new()
		noise_obj.seed = randi()
		noise_obj.frequency = 0.1

	func generate(scale: float) -> void:
		field.clear()
		var yoff := 0.0
		for y in range(rows):
			var xoff := 0.0
			for x in range(cols):
				var angle: float = noise_obj.get_noise_2d(xoff, yoff) * TAU * 2.0
				field.append(Vector3(cos(angle), sin(angle), 0))
				xoff += scale
			yoff += scale

	func lookup(pos: Vector3) -> Vector3:
		var x := int(clamp((pos.x + 0.45) / 0.9 * cols, 0, cols - 1))
		var y := int(clamp((pos.y - 0.05) / 0.9 * rows, 0, rows - 1))
		return field[y * cols + x]

func _update_field_mesh() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var cell_w := 0.9 / float(_field.cols)
	var cell_h := 0.9 / float(_field.rows)
	for y in range(_field.rows):
		for x in range(_field.cols):
			var vector := _field.field[y * _field.cols + x]
			var start := Vector3(-0.45 + x * cell_w, 0.1 + y * cell_h, 0)
			var end := start + vector * 0.08
			mesh.surface_set_color(Color(1.0, 0.7, 0.95, 0.6))
			mesh.surface_add_vertex(start)
			mesh.surface_add_vertex(end)
	_field_mesh.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.7, 0.95, 0.2)
	_field_mesh.material_override = mat

func _update_status() -> void:
	_status_label.text = "Flow Field"

class Vehicle:
	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var max_speed: float = 0.5
	var max_force: float = 0.08

	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, body_mat: Material) -> void:
		root = Node3D.new()
		root.name = "Vehicle"
		parent.add_child(root)

		body = MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.05
		cone.bottom_radius = 0.05
		cone.height = 0.14
		body.mesh = cone
		body.material_override = body_mat
		body.rotation_degrees = Vector3(0, 0, -90)
		root.add_child(body)

	func follow(field: FlowField) -> void:
		var desired := field.lookup(position)
		var steer := desired * max_speed - velocity
		steer = steer.limit_length(max_force)
		apply_force(steer)

	func apply_force(force: Vector3) -> void:
		acceleration += force

	func update(delta: float) -> void:
		velocity += acceleration
		velocity = velocity.limit_length(max_speed)
		position += velocity * delta * 60.0
		acceleration = Vector3.ZERO
		var angle := atan2(velocity.y, velocity.x)
		root.rotation = Vector3(0, 0, angle)

	func wrap_bounds() -> void:
		var pos := position
		if pos.x < -0.45:
			pos.x = 0.45
		elif pos.x > 0.45:
			pos.x = -0.45
		if pos.y < 0.05:
			pos.y = 0.95
		elif pos.y > 0.95:
			pos.y = 0.05
		position = pos

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()
