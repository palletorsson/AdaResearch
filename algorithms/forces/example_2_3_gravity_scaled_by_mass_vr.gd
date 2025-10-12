# ===========================================================================
# NOC Example 2.3: Gravity Scaled by Mass
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const PARAMETER_CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const DEFAULT_GRAVITY_STRENGTH := 0.9
const ARROW_LENGTH_SCALE := 0.8
const MIN_ARROW_LENGTH := 0.05
const MAX_ARROW_LENGTH := 1.0

var movers: Array[Mover] = []
var mover_labels: Dictionary = {}
var force_visuals: Dictionary = {}
var mover_initial_positions: Dictionary = {}

var gravity_strength: float = DEFAULT_GRAVITY_STRENGTH
var show_force_vectors: bool = true

var info_label: Label3D
var instructions_label: Label3D
var gravity_controller: ParameterController3D
var auto_reset_timer: Timer

func _ready() -> void:
	create_ui()
	spawn_movers()
	setup_auto_reset()
	print("Example 2.3: Gravity scaled by mass")

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

		var gravity_force: Vector3 = Vector3(0, -gravity_strength * mover.mass, 0)
		mover.apply_force(gravity_force)
		update_force_visual(mover, gravity_force)

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
	info_label.position = Vector3(0, 0.68, 0)
	add_child(info_label)

	instructions_label = Label3D.new()
	instructions_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions_label.font_size = 18
	instructions_label.modulate = Color(0.8, 1.0, 0.9)
	instructions_label.position = Vector3(0, 0.58, 0)
	instructions_label.text = "[F] Toggle weight arrows  |  [R] Reset"
	add_child(instructions_label)

	gravity_controller = PARAMETER_CONTROLLER_SCENE.instantiate()
	gravity_controller.parameter_name = "Gravity"
	gravity_controller.min_value = 0.1
	gravity_controller.max_value = 2.5
	gravity_controller.default_value = gravity_strength
	gravity_controller.step_size = 0.05
	gravity_controller.position = Vector3(0, 0.48, 0.25)
	gravity_controller.rotation_degrees = Vector3.ZERO
	add_child(gravity_controller)
	gravity_controller.value_changed.connect(_on_gravity_changed)
	gravity_controller.set_value(gravity_strength)

func spawn_movers() -> void:
	clear_existing_movers()

	var configs: Array = [
		{ "mass": 0.5, "position": Vector3(-0.25, 0.35, 0.0) },
		{ "mass": 1.5, "position": Vector3(0.0, 0.35, 0.0) },
		{ "mass": 3.0, "position": Vector3(0.25, 0.35, 0.0) }
	]

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for config in configs:
		var mover := Mover.new()
		mover.mass = float(config["mass"])
		mover.position_v = config["position"]
		mover.velocity = Vector3.ZERO
		mover.acceleration = Vector3.ZERO
		mover.bounce_damping = 0.6
		add_child(mover)
		mover.set_size(0.03 + mover.mass * 0.01)

		var random_color := Color(
			rng.randf_range(0.7, 1.0),
			rng.randf_range(0.4, 0.7),
			rng.randf_range(0.8, 1.0)
		)
		mover.set_color(random_color)

		movers.append(mover)
		mover_initial_positions[mover] = config["position"]

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
	mover_initial_positions.clear()


func create_force_arrow() -> Node3D:
	var arrow_root := Node3D.new()
	arrow_root.name = "WeightArrow"
	arrow_root.visible = show_force_vectors

	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var shaft_mesh: CylinderMesh = CylinderMesh.new()
	shaft_mesh.top_radius = 0.005
	shaft_mesh.bottom_radius = 0.005
	shaft_mesh.height = 1.0
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0, 0, -0.5)
	shaft.rotation_degrees = Vector3(90, 0, 0)
	shaft.material_override = create_arrow_material()
	arrow_root.add_child(shaft)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh: CylinderMesh = CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.02
	head_mesh.height = 0.08
	head.mesh = head_mesh
	head.position = Vector3(0, 0, -1.0)
	head.rotation_degrees = Vector3(90, 0, 0)
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

func update_info_label() -> void:
	if info_label:
		info_label.text = "Example 2.3: Gravity scaled by mass\nGravity %.2f m/s^2" % gravity_strength


func update_force_visual(mover: Mover, gravity_force: Vector3) -> void:
	var arrow: Node3D = force_visuals.get(mover, null)
	if not arrow or not is_instance_valid(arrow):
		return

	var magnitude: float = gravity_force.length()
	if not show_force_vectors or magnitude < 0.01:
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

	var basis := Basis().looking_at(Vector3.DOWN, Vector3.FORWARD)
	arrow.transform = Transform3D(basis, Vector3.ZERO)

func reset_scene() -> void:
	gravity_strength = DEFAULT_GRAVITY_STRENGTH
	if gravity_controller:
		gravity_controller.set_value(gravity_strength)
	restore_initial_positions()

func restore_initial_positions() -> void:
	for mover in movers:
		if not is_instance_valid(mover):
			continue
		var start: Vector3 = mover_initial_positions.get(mover, mover.position_v)
		mover.position_v = start
		mover.velocity = Vector3.ZERO
		mover.acceleration = Vector3.ZERO

func toggle_force_vectors() -> void:
	show_force_vectors = !show_force_vectors
	for arrow in force_visuals.values():
		if is_instance_valid(arrow):
			arrow.visible = show_force_vectors

func _on_gravity_changed(value: float) -> void:
	gravity_strength = value
	for mover in movers:
		if is_instance_valid(mover):
			mover.acceleration = Vector3.ZERO

