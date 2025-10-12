# ===========================================================================
# NOC Example 2.6: Single Attractor
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const PARAMETER_CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const ATTRACTOR_SCENE := preload("res://commons/primitives/point/grab_sphere_point_with_color.tscn")
const DEFAULT_GRAVITY := 0.6
const DEFAULT_ATTRACTOR_MASS := 4.0
const ARROW_LENGTH_SCALE := 0.4
const MIN_ARROW_LENGTH := 0.08
const MAX_ARROW_LENGTH := 0.9

var attractor_anchor: Node3D
var attractor_position: Vector3 = Vector3(0, 0, 0.1)
var attractor_mass: float = DEFAULT_ATTRACTOR_MASS
var attractor_strength: float = DEFAULT_GRAVITY

var movers: Array[Mover] = []
var mover_labels: Dictionary = {}
var force_visuals: Dictionary = {}
var mover_initial_states: Dictionary = {}

var info_label: Label3D
var instructions_label: Label3D
var strength_controller: ParameterController3D
var mass_controller: ParameterController3D
var auto_reset_timer: Timer

func _ready() -> void:
	create_attractor()
	create_ui()
	spawn_movers()
	setup_auto_reset()
	print("Example 2.6: Single attractor")

func setup_auto_reset() -> void:
	auto_reset_timer = Timer.new()
	auto_reset_timer.wait_time = 20.0
	auto_reset_timer.autostart = true
	auto_reset_timer.timeout.connect(reset_scene)
	add_child(auto_reset_timer)

func _process(_delta: float) -> void:
	# Update attractor position from the grabbable object
	if is_instance_valid(attractor_anchor):
		attractor_position = attractor_anchor.global_position

	update_info_label()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(attractor_anchor):
		return

	for mover in movers:
		if not is_instance_valid(mover):
			continue

		var force: Vector3 = calculate_attraction(mover)
		mover.apply_force(force)
		update_force_visual(mover, force)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				reset_scene()
			KEY_SPACE:
				spread_movers()

func create_attractor() -> void:
	attractor_anchor = ATTRACTOR_SCENE.instantiate()
	attractor_anchor.name = "Attractor"
	attractor_anchor.position = attractor_position
	add_child(attractor_anchor)

func create_ui() -> void:
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(1.0, 0.9, 1.0)
	info_label.position = Vector3(0, 0.68, -0.2)
	add_child(info_label)

	instructions_label = Label3D.new()
	instructions_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions_label.font_size = 18
	instructions_label.modulate = Color(0.8, 1.0, 0.9)
	instructions_label.position = Vector3(0, 0.58, -0.2)
	instructions_label.text = "[SPACE] Scatter movers  |  [R] Reset"
	add_child(instructions_label)

	strength_controller = PARAMETER_CONTROLLER_SCENE.instantiate()
	strength_controller.parameter_name = "Gravity strength"
	strength_controller.min_value = 0.2
	strength_controller.max_value = 1.2
	strength_controller.default_value = attractor_strength
	strength_controller.step_size = 0.05
	strength_controller.position = Vector3(-0.45, 0.48, 0.2)
	strength_controller.rotation_degrees = Vector3(0, 25, 0)
	add_child(strength_controller)
	strength_controller.value_changed.connect(_on_strength_changed)
	strength_controller.set_value(attractor_strength)

	mass_controller = PARAMETER_CONTROLLER_SCENE.instantiate()
	mass_controller.parameter_name = "Attractor mass"
	mass_controller.min_value = 1.0
	mass_controller.max_value = 8.0
	mass_controller.default_value = attractor_mass
	mass_controller.step_size = 0.2
	mass_controller.position = Vector3(0.45, 0.48, 0.2)
	mass_controller.rotation_degrees = Vector3(0, -25, 0)
	add_child(mass_controller)
	mass_controller.value_changed.connect(_on_mass_changed)
	mass_controller.set_value(attractor_mass)

func spawn_movers() -> void:
	clear_existing_movers()

	var configs: Array = [
		{ "mass": 0.6, "position": Vector3(-0.3, 0.25, 0.0), "velocity": Vector3(0.25, 0, 0.15) },
		{ "mass": 1.0, "position": Vector3(-0.1, 0.35, -0.2), "velocity": Vector3(0.18, 0, 0.2) },
		{ "mass": 1.5, "position": Vector3(0.2, 0.3, -0.3), "velocity": Vector3(-0.1, 0, 0.25) },
		{ "mass": 2.2, "position": Vector3(0.35, 0.4, 0.1), "velocity": Vector3(-0.2, 0, -0.18) }
	]

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for config in configs:
		var mover := Mover.new()
		mover.mass = float(config["mass"])
		mover.position_v = config["position"]
		mover.velocity = config["velocity"]
		mover.acceleration = Vector3.ZERO
		mover.bounce_damping = 0.5
		add_child(mover)
		mover.set_size(0.03 + mover.mass * 0.01)

		var random_color := Color(
			rng.randf_range(0.7, 1.0),
			rng.randf_range(0.4, 0.7),
			rng.randf_range(0.8, 1.0)
		)
		mover.set_color(random_color)

		movers.append(mover)
		mover_initial_states[mover] = {
			"position": config["position"],
			"velocity": config["velocity"]
		}

		var arrow := create_force_arrow()
		mover.add_child(arrow)
		force_visuals[mover] = arrow

func clear_existing_movers() -> void:
	for mover in movers:
		if is_instance_valid(mover):
			mover.queue_free()
	movers.clear()
	mover_labels.clear()
	force_visuals.clear()
	mover_initial_states.clear()


func create_force_arrow() -> Node3D:
	var arrow_root := Node3D.new()
	arrow_root.name = "AttractionArrow"
	arrow_root.visible = false

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
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 1.0) * 0.3
	mat.emission_energy_multiplier = 0.5
	return mat

func calculate_attraction(mover: Mover) -> Vector3:
	var mover_global_pos: Vector3 = mover.global_position
	var dir: Vector3 = attractor_position - mover_global_pos
	var distance: float = dir.length()
	distance = clamp(distance, 0.05, 0.8)
	dir = dir.normalized()
	var strength: float = (attractor_strength * attractor_mass * mover.mass) / (distance * distance)
	return dir * strength

func update_force_visual(mover: Mover, force: Vector3) -> void:
	var arrow: Node3D = force_visuals.get(mover, null)
	if not arrow or not is_instance_valid(arrow):
		return

	var magnitude: float = force.length()
	if magnitude < 0.01:
		arrow.visible = false
		return

	arrow.visible = true
	var length: float = clamp(magnitude * ARROW_LENGTH_SCALE, MIN_ARROW_LENGTH, MAX_ARROW_LENGTH)

	var shaft: Node = arrow.get_node("Shaft") if arrow.has_node("Shaft") else null
	var head: Node = arrow.get_node("Head") if arrow.has_node("Head") else null

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
		info_label.text = "Example 2.6: Single attractor\nStrength %.2f  |  Mass %.1f" % [attractor_strength, attractor_mass]


func reset_scene() -> void:
	attractor_strength = DEFAULT_GRAVITY
	attractor_mass = DEFAULT_ATTRACTOR_MASS
	if strength_controller:
		strength_controller.set_value(attractor_strength)
	if mass_controller:
		mass_controller.set_value(attractor_mass)
	restore_movers()

func restore_movers() -> void:
	for mover in movers:
		if not is_instance_valid(mover):
			continue
		var saved: Dictionary = mover_initial_states.get(mover, null)
		if saved:
			mover.position_v = saved["position"]
			mover.velocity = saved["velocity"]
			mover.acceleration = Vector3.ZERO

func spread_movers() -> void:
	var rng := RandomNumberGenerator.new()
	for mover in movers:
		if not is_instance_valid(mover):
			continue
		mover.velocity += Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(-0.05, 0.05), rng.randf_range(-0.2, 0.2))

func _on_strength_changed(value: float) -> void:
	attractor_strength = value

func _on_mass_changed(value: float) -> void:
	attractor_mass = value
