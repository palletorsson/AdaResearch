# ===========================================================================
# NOC Example 2.2: Forces: Mass Variation
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const PARAMETER_CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const DEFAULT_WIND_STRENGTH := 0.4
const DEFAULT_DRAG_COEFFICIENT := 0.02
const ARROW_LENGTH_SCALE := 0.6
const MIN_ARROW_LENGTH := 0.08
const MAX_ARROW_LENGTH := 0.9

var movers: Array[Mover] = []
var mover_labels: Dictionary = {}
var force_visuals: Dictionary = {}

var gravity: Vector3 = Vector3(0, -0.6, 0)
var wind_strength: float = DEFAULT_WIND_STRENGTH
var drag_coefficient: float = DEFAULT_DRAG_COEFFICIENT
var show_force_vectors: bool = true

var info_label: Label3D
var instructions_label: Label3D
var wind_controller: ParameterController3D
var drag_controller: ParameterController3D
var auto_reset_timer: Timer

func _ready() -> void:
	create_ui()
	spawn_movers()
	setup_auto_reset()
	print("Example 2.2: Forces with mass variation")

func setup_auto_reset() -> void:
	auto_reset_timer = Timer.new()
	auto_reset_timer.wait_time = 20.0
	auto_reset_timer.autostart = true
	auto_reset_timer.timeout.connect(reset_scene)
	add_child(auto_reset_timer)

func _process(_delta: float) -> void:
	update_info_label()

func _physics_process(_delta: float) -> void:
	for mover in movers:
		if not is_instance_valid(mover):
			continue

		var gravity_force: Vector3 = gravity * mover.mass
		mover.apply_force(gravity_force)

		var wind_force: Vector3 = Vector3(wind_strength, 0, 0)
		mover.apply_force(wind_force)

		var drag_force: Vector3 = compute_drag_force(mover)
		mover.apply_force(drag_force)

		var total_force: Vector3 = gravity_force + wind_force + drag_force
		update_force_visual(mover, total_force)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				reset_scene()
			KEY_F:
				toggle_force_vectors()

func create_ui() -> void:
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(1.0, 0.9, 1.0)
	info_label.position = Vector3(0, 0.65, 0)
	add_child(info_label)

	instructions_label = Label3D.new()
	instructions_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions_label.font_size = 18
	instructions_label.modulate = Color(0.8, 1.0, 0.9)
	instructions_label.position = Vector3(0, 0.55, 0)
	instructions_label.text = "[F] Force arrows  |  [R] Reset"
	add_child(instructions_label)

	create_parameter_controls()

func create_parameter_controls() -> void:
	wind_controller = PARAMETER_CONTROLLER_SCENE.instantiate()
	wind_controller.parameter_name = "Wind"
	wind_controller.min_value = -1.0
	wind_controller.max_value = 1.0
	wind_controller.default_value = wind_strength
	wind_controller.step_size = 0.05
	wind_controller.position = Vector3(-0.45, 0.45, 0.12)
	wind_controller.rotation_degrees = Vector3(0, 35, 0)
	add_child(wind_controller)
	wind_controller.value_changed.connect(_on_wind_changed)
	wind_controller.set_value(wind_strength)

	drag_controller = PARAMETER_CONTROLLER_SCENE.instantiate()
	drag_controller.parameter_name = "Drag"
	drag_controller.min_value = 0.0
	drag_controller.max_value = 0.1
	drag_controller.default_value = drag_coefficient
	drag_controller.step_size = 0.005
	drag_controller.position = Vector3(0.45, 0.45, 0.12)
	drag_controller.rotation_degrees = Vector3(0, -35, 0)
	add_child(drag_controller)
	drag_controller.value_changed.connect(_on_drag_changed)
	drag_controller.set_value(drag_coefficient)

func spawn_movers() -> void:
	clear_existing_movers()

	var configs: Array = [
		{ "mass": 0.4, "position": Vector3(-0.25, 0.25, 0.0) },
		{ "mass": 1.0, "position": Vector3(0.0, 0.25, 0.0) },
		{ "mass": 2.0, "position": Vector3(0.25, 0.25, 0.0) }
	]

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for config in configs:
		var mover := Mover.new()
		mover.mass = float(config["mass"])
		mover.position_v = config["position"]
		mover.velocity = Vector3.ZERO
		mover.bounce_damping = 0.7
		add_child(mover)
		mover.set_size(0.03 + mover.mass * 0.012)

		var random_color := Color(
			rng.randf_range(0.7, 1.0),
			rng.randf_range(0.4, 0.7),
			rng.randf_range(0.8, 1.0)
		)
		mover.set_color(random_color)

		movers.append(mover)

		var arrow := create_force_arrow()
		force_visuals[mover] = arrow
		mover.add_child(arrow)

func clear_existing_movers() -> void:
	for mover in movers:
		if is_instance_valid(mover):
			mover.queue_free()
	movers.clear()
	mover_labels.clear()
	force_visuals.clear()


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

func update_info_label() -> void:
	if info_label:
		info_label.text = "Example 2.2: Forces with mass\nWind %.2f  |  Drag %.3f" % [wind_strength, drag_coefficient]


func compute_drag_force(mover: Mover) -> Vector3:
	var speed: float = mover.velocity.length()
	if speed <= 0.01:
		return Vector3.ZERO

	var drag_magnitude: float = drag_coefficient * speed * speed
	var drag_direction: Vector3 = -mover.velocity.normalized()
	return drag_direction * drag_magnitude

func update_force_visual(mover: Mover, force: Vector3) -> void:
	var arrow: Node3D = force_visuals.get(mover, null)
	if not arrow or not is_instance_valid(arrow):
		return

	if not show_force_vectors or force.length() < 0.01:
		arrow.visible = false
		return

	arrow.visible = true
	var length: float = clamp(force.length() * ARROW_LENGTH_SCALE, MIN_ARROW_LENGTH, MAX_ARROW_LENGTH)

	var shaft: Node = arrow.get_node("Shaft") if arrow.has_node("Shaft") else null
	var head: Node = arrow.get_node("Head") if arrow.has_node("Head") else null

	if shaft and shaft is MeshInstance3D:
		shaft.scale = Vector3(1, 1, length)
		shaft.position = Vector3(0, 0, length * 0.5)

	if head and head is MeshInstance3D:
		head.position = Vector3(0, 0, length)
		head.scale = Vector3(1, 1, clamp(length * 0.4, 0.3, 0.8))

	var direction: Vector3 = force.normalized()
	var up_vector := Vector3.UP
	if abs(direction.dot(up_vector)) > 0.95:
		up_vector = Vector3.RIGHT
	var basis := Basis().looking_at(-direction, up_vector)
	arrow.transform = Transform3D(basis, Vector3.ZERO)

func reset_scene() -> void:
	wind_strength = DEFAULT_WIND_STRENGTH
	drag_coefficient = DEFAULT_DRAG_COEFFICIENT
	if wind_controller:
		wind_controller.set_value(wind_strength)
	if drag_controller:
		drag_controller.set_value(drag_coefficient)
	spawn_movers()

func toggle_force_vectors() -> void:
	show_force_vectors = !show_force_vectors
	for arrow in force_visuals.values():
		if is_instance_valid(arrow):
			arrow.visible = show_force_vectors

func _on_wind_changed(value: float) -> void:
	wind_strength = value

func _on_drag_changed(value: float) -> void:
	drag_coefficient = value
