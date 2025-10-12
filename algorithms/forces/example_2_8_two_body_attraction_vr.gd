# ===========================================================================
# NOC Example 2.8: Two-Body Attraction
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const PARAMETER_CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const DEFAULT_GRAVITY_STRENGTH := 0.4
const ARROW_LENGTH_SCALE := 0.5
const MIN_ARROW_LENGTH := 0.08
const MAX_ARROW_LENGTH := 0.9

var body_a: Mover
var body_b: Mover

var gravity_strength: float = DEFAULT_GRAVITY_STRENGTH
var show_force_vectors: bool = true

var info_label: Label3D
var instructions_label: Label3D
var gravity_controller: ParameterController3D

var arrow_a: Node3D
var arrow_b: Node3D
var auto_reset_timer: Timer

func _ready() -> void:
	create_ui()
	spawn_bodies()
	setup_auto_reset()
	print("Example 2.8: Two-body attraction")

func setup_auto_reset() -> void:
	auto_reset_timer = Timer.new()
	auto_reset_timer.wait_time = 20.0
	auto_reset_timer.autostart = true
	auto_reset_timer.timeout.connect(reset_scene)
	add_child(auto_reset_timer)

func _process(_delta: float) -> void:
	update_info_label()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(body_a) or not is_instance_valid(body_b):
		return

	var force_ab: Vector3 = calculate_attraction(body_a, body_b)
	var force_ba: Vector3 = -force_ab

	body_a.apply_force(force_ab)
	body_b.apply_force(force_ba)

	update_force_arrow(arrow_a, force_ab)
	update_force_arrow(arrow_b, force_ba)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				reset_scene()
			KEY_T:
				toggle_force_vectors()

func create_ui() -> void:
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(1.0, 0.9, 1.0)
	info_label.position = Vector3(0, 0.68, 0)
	add_child(info_label)

	instructions_label = Label3D.new()
	instructions_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions_label.font_size = 18
	instructions_label.modulate = Color(0.8, 1.0, 0.9)
	instructions_label.position = Vector3(0, 0.58, 0)
	instructions_label.text = "[T] Toggle force arrows  |  [R] Reset"
	add_child(instructions_label)

	gravity_controller = PARAMETER_CONTROLLER_SCENE.instantiate()
	gravity_controller.parameter_name = "Gravity"
	gravity_controller.min_value = 0.1
	gravity_controller.max_value = 1.0
	gravity_controller.default_value = gravity_strength
	gravity_controller.step_size = 0.02
	gravity_controller.position = Vector3(0, 0.48, 0.22)
	gravity_controller.rotation_degrees = Vector3.ZERO
	add_child(gravity_controller)
	gravity_controller.value_changed.connect(_on_gravity_changed)
	gravity_controller.set_value(gravity_strength)

func spawn_bodies() -> void:
	if is_instance_valid(body_a):
		body_a.queue_free()
	if is_instance_valid(body_b):
		body_b.queue_free()

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	body_a = create_body("BodyA", 1.8, Vector3(-0.25, 0.0, 0.0), Vector3(0.0, 0.05, 0.22), rng)
	body_b = create_body("BodyB", 1.1, Vector3(0.25, 0.0, 0.0), Vector3(0.0, -0.05, -0.18), rng)

	arrow_a = create_force_arrow()
	arrow_b = create_force_arrow()
	body_a.add_child(arrow_a)
	body_b.add_child(arrow_b)

func create_body(name: String, mass: float, position: Vector3, velocity: Vector3, rng: RandomNumberGenerator) -> Mover:
	var body := Mover.new()
	body.name = name
	body.mass = mass
	body.position_v = position
	body.velocity = velocity
	body.acceleration = Vector3.ZERO
	body.bounce_damping = 0.5
	add_child(body)
	body.set_size(0.03 + mass * 0.01)

	var random_color := Color(
		rng.randf_range(0.7, 1.0),
		rng.randf_range(0.4, 0.7),
		rng.randf_range(0.8, 1.0)
	)
	body.set_color(random_color)
	return body

func create_force_arrow() -> Node3D:
	var arrow_root := Node3D.new()
	arrow_root.name = "ForceArrow"
	arrow_root.visible = show_force_vectors

	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var shaft_mesh: CylinderMesh = CylinderMesh.new()
	shaft_mesh.top_radius = 0.005
	shaft_mesh.bottom_radius = 0.005
	shaft_mesh.height = 1.0
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0, 0, 0.5)
	shaft.rotation_degrees = Vector3(-90, 0, 0)
	shaft.material_override = create_arrow_material()
	arrow_root.add_child(shaft)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh: CylinderMesh = CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.02
	head_mesh.height = 0.08
	head.mesh = head_mesh
	head.position = Vector3(0, 0, 1.0)
	head.rotation_degrees = Vector3(-90, 0, 0)
	head.material_override = create_arrow_material()
	arrow_root.add_child(head)

	return arrow_root

func create_arrow_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.6, 1.0, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 1.0) * 0.3
	mat.emission_energy_multiplier = 0.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

func calculate_attraction(source: Mover, target: Mover) -> Vector3:
	var direction: Vector3 = target.position_v - source.position_v
	var distance: float = direction.length()
	distance = clamp(distance, 0.08, 0.8)
	direction = direction.normalized()
	var strength: float = (gravity_strength * source.mass * target.mass) / (distance * distance)
	return direction * strength

func update_force_arrow(arrow: Node3D, force: Vector3) -> void:
	if not arrow or not is_instance_valid(arrow):
		return

	var magnitude: float = force.length()
	if not show_force_vectors or magnitude < 0.01:
		arrow.visible = false
		return

	arrow.visible = true
	var length: float = clamp(magnitude * ARROW_LENGTH_SCALE, MIN_ARROW_LENGTH, MAX_ARROW_LENGTH)

	var shaft := arrow.get_node("Shaft") if arrow.has_node("Shaft") else null
	var head := arrow.get_node("Head") if arrow.has_node("Head") else null

	if shaft and shaft is MeshInstance3D:
		shaft.scale = Vector3(1, 1, length)
		shaft.position = Vector3(0, 0, length * 0.5)

	if head and head is MeshInstance3D:
		head.position = Vector3(0, 0, length)
		head.scale = Vector3(1, 1, clamp(length * 0.4, 0.3, 0.9))

	var direction: Vector3 = -force.normalized()
	var up_vector := Vector3.UP
	if abs(direction.dot(up_vector)) > 0.95:
		up_vector = Vector3.RIGHT
	var basis := Basis().looking_at(direction, up_vector)
	arrow.transform = Transform3D(basis, Vector3.ZERO)

func update_info_label() -> void:
	if info_label:
		info_label.text = "Example 2.8: Two-body attraction\nGravity %.2f" % gravity_strength

func reset_scene() -> void:
	gravity_strength = DEFAULT_GRAVITY_STRENGTH
	if gravity_controller:
		gravity_controller.set_value(gravity_strength)
	spawn_bodies()

func toggle_force_vectors() -> void:
	show_force_vectors = !show_force_vectors
	if is_instance_valid(arrow_a):
		arrow_a.visible = show_force_vectors
	if is_instance_valid(arrow_b):
		arrow_b.visible = show_force_vectors

func _on_gravity_changed(value: float) -> void:
	gravity_strength = value

