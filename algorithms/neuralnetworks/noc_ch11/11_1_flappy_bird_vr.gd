extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_PRIMARY := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_SECONDARY := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")
const MAT_ACCENT := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

const BIRD_X: float = -0.35
const MIN_Y: float = 0.1
const MAX_Y: float = 0.9
const PIPE_WIDTH: float = 0.12
const PIPE_DEPTH: float = 0.25
const PIPE_SPAWN_X: float = 0.55
const PIPE_DESPAWN_X: float = -0.65

@export var pipe_spawn_interval: float = 2.4
@export var pipe_gap: float = 0.38
@export var pipe_speed: float = 0.28
@export var gravity: float = 0.55
@export var flap_strength: float = 1.8

var _sim_root: Node3D
var _bird: Bird
var _pipes: Array[Pipe] = []
var _spawn_timer: float = 0.0
var _status_label: Label3D

func _ready() -> void:
	randomize()
	_setup_environment()
	_spawn_bird()
	spawn_pipe()
	_spawn_timer = pipe_spawn_interval
	set_physics_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	_sim_root.name = "SimulationRoot"
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.modulate = Color(1.0, 0.8, 1.0)
	_status_label.visible = false
	_status_label.position = Vector3(0.0, 0.82, 0.0)
	_sim_root.add_child(_status_label)

	_create_controllers()

func _create_controllers() -> void:
	var controller_root := Node3D.new()
	controller_root.name = "Controllers"
	controller_root.position = Vector3(0.75, 0.45, 0.0)
	add_child(controller_root)

	var gravity_controller := CONTROLLER_SCENE.instantiate()
	gravity_controller.parameter_name = "Gravity"
	gravity_controller.min_value = 0.2
	gravity_controller.max_value = 1.2
	gravity_controller.default_value = gravity
	gravity_controller.position = Vector3(0.0, 0.1, 0.0)
	gravity_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(gravity_controller)
	gravity_controller.value_changed.connect(_on_gravity_changed)
	gravity_controller.set_value(gravity)

	var speed_controller := CONTROLLER_SCENE.instantiate()
	speed_controller.parameter_name = "Pipe Speed"
	speed_controller.min_value = 0.15
	speed_controller.max_value = 0.6
	speed_controller.default_value = pipe_speed
	speed_controller.position = Vector3(0.0, -0.15, 0.0)
	speed_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(speed_controller)
	speed_controller.value_changed.connect(_on_pipe_speed_changed)
	speed_controller.set_value(pipe_speed)

func _spawn_bird() -> void:
	_bird = Bird.new()
	_bird.init(_sim_root, MAT_PRIMARY, MAT_ACCENT)
	_bird.position = Vector3(BIRD_X, 0.5, 0.0)
	_bird.gravity = gravity
	_bird.flap_strength = flap_strength

func spawn_pipe() -> void:
	var gap_center := randf_range(MIN_Y + pipe_gap * 0.5, MAX_Y - pipe_gap * 0.5)
	var pipe := Pipe.new()
	pipe.init(_sim_root, MAT_SECONDARY, gap_center, pipe_gap)
	pipe.position_x = PIPE_SPAWN_X
	pipe.update_geometry(PIPE_WIDTH, PIPE_DEPTH)
	_pipes.append(pipe)

func _physics_process(delta: float) -> void:
	if _bird == null:
		return

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		spawn_pipe()
		_spawn_timer = pipe_spawn_interval

	_bird.gravity = gravity
	_bird.update(delta)
	_bird.position = _clamp_bird_position(_bird.position)

	for pipe in _pipes:
		pipe.position_x -= pipe_speed * delta
		pipe.apply_positions()

	for pipe in _pipes.duplicate():
		if pipe.position_x < PIPE_DESPAWN_X:
			pipe.queue_free()
			_pipes.erase(pipe)
			continue

		if pipe.overlaps_x(_bird.position.x, PIPE_WIDTH):
			if not pipe.is_within_gap(_bird.position.y):
				_show_status("Collision!", Color(1.0, 0.4, 0.7))
				_reset_simulation()
				break

func _clamp_bird_position(pos: Vector3) -> Vector3:
	if pos.y < MIN_Y:
		pos.y = MIN_Y
		_bird.velocity.y = 0.0
	elif pos.y > MAX_Y:
		pos.y = MAX_Y
		_bird.velocity.y = 0.0
	return pos

func _show_status(message: String, tint: Color) -> void:
	_status_label.visible = true
	_status_label.modulate = tint
	_status_label.text = message

	var timer := Timer.new()
	timer.wait_time = 1.2
	timer.one_shot = true
	timer.timeout.connect(func() -> void:
		if is_instance_valid(_status_label):
			_status_label.visible = false
			_status_label.text = ""
	)
	add_child(timer)
	timer.start()

func _reset_simulation() -> void:
	for pipe in _pipes:
		pipe.queue_free()
	_pipes.clear()
	_bird.reset(Vector3(BIRD_X, 0.5, 0.0))
	spawn_pipe()
	_spawn_timer = pipe_spawn_interval

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_bird.flap()

func _on_gravity_changed(value: float) -> void:
	gravity = value

func _on_pipe_speed_changed(value: float) -> void:
	pipe_speed = value

class Bird:
	var root: Node3D
	var mesh: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var gravity: float = 0.5
	var flap_strength: float = 1.5

	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, body_material: Material, accent_material: Material) -> void:
		root = Node3D.new()
		root.name = "Bird"
		parent.add_child(root)

		mesh = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.05
		sphere.height = 0.1
		mesh.mesh = sphere
		mesh.material_override = body_material
		root.add_child(mesh)

		var arrow := MeshInstance3D.new()
		var arrow_mesh := CylinderMesh.new()
		arrow_mesh.top_radius = 0.01
		arrow_mesh.bottom_radius = 0.01
		arrow_mesh.height = 0.12
		arrow.mesh = arrow_mesh
		arrow.material_override = accent_material
		arrow.rotation_degrees = Vector3(0, 0, 90)
		arrow.position = Vector3(0.08, 0, 0)
		mesh.add_child(arrow)

	func update(delta: float) -> void:
		velocity.y += gravity * delta
		root.position += velocity * delta

	func flap() -> void:
		velocity.y = -flap_strength

	func reset(start_position: Vector3) -> void:
		root.global_position = start_position
		velocity = Vector3.ZERO

class Pipe:
	var root: Node3D
	var top: MeshInstance3D
	var bottom: MeshInstance3D
	var gap_center: float = 0.5
	var gap_size: float = 0.3
	var position_x: float = 0.5

	func init(parent: Node3D, pipe_material: Material, gap: float, gap_extent: float) -> void:
		root = Node3D.new()
		root.name = "Pipe"
		parent.add_child(root)
		gap_center = gap
		gap_size = gap_extent

		top = MeshInstance3D.new()
		bottom = MeshInstance3D.new()
		top.material_override = pipe_material
		bottom.material_override = pipe_material
		root.add_child(top)
		root.add_child(bottom)

	func update_geometry(width: float, depth_size: float) -> void:
		var top_height := (MAX_Y - gap_center) - gap_size * 0.5
		var bottom_height := (gap_center - MIN_Y) - gap_size * 0.5
		top_height = max(top_height, 0.05)
		bottom_height = max(bottom_height, 0.05)

		var top_mesh := BoxMesh.new()
		top_mesh.size = Vector3(width, top_height, depth_size)
		top.mesh = top_mesh

		var bottom_mesh := BoxMesh.new()
		bottom_mesh.size = Vector3(width, bottom_height, depth_size)
		bottom.mesh = bottom_mesh

		apply_positions()

	func apply_positions() -> void:
		top.position = Vector3(position_x, gap_center + gap_size * 0.5 + top.mesh.size.y * 0.5, 0)
		bottom.position = Vector3(position_x, gap_center - gap_size * 0.5 - bottom.mesh.size.y * 0.5, 0)

	func overlaps_x(bird_x: float, width: float) -> bool:
		return bird_x > position_x - width * 0.5 and bird_x < position_x + width * 0.5

	func is_within_gap(bird_y: float) -> bool:
		return bird_y > gap_center - gap_size * 0.5 and bird_y < gap_center + gap_size * 0.5

	func queue_free() -> void:
		if is_instance_valid(top):
			top.queue_free()
		if is_instance_valid(bottom):
			bottom.queue_free()
		if is_instance_valid(root):
			root.queue_free()
