# ===========================================================================
# NOC Example 2.2: Forces: Mass Variation
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
#
# @identity
# essence: Wind and drag applied to many balls of different masses — F=ma made visible as different responses to identical force
# desire: To turn the equation F=ma into a perceptual event — same wind pushes large and small differently, mass becomes legible as motion
# critical_parameter: wind_strength and drag_coefficient — together they decide whether mass differences read as separation or noise
# triggers: Zero wind makes mass invisible; strong wind separates masses by acceleration; high drag erases the differences over time
# emerges: A row of objects of varying mass under one wind becomes a histogram of inertia, sorted by acceleration response
# needs: per-ball mass [has], wind force application [has], drag force [has], VR sliders [has]
# relationships: Direct successor to example_2_1_forces_vr (adds mass). Anchor artifact in forces/Newton's_Laws map
# truth: Mass is not a number on a scale — it is the resistance that makes one body's response to a force differ from another's.
# ===========================================================================

extends Node3D

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

# UI — Ada rack panel
var _panel: ForcesRackPanel
var _wind_slider: Node3D
var _drag_slider: Node3D
var auto_reset_timer: Timer

func _ready() -> void:
	# Scale down for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	_create_panel()
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
	_update_panel_info()

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

func _create_panel() -> void:
	_panel = ForcesRackPanel.new()
	_panel.setup("2.2  Mass Variation", 2, 3)
	_panel.set_instructions("[F] Force arrows  [R] Reset")

	_wind_slider = _panel.add_slider("Wind", -1.0, 1.0, wind_strength, 0.05)
	_wind_slider.slider_moved.connect(_on_wind_slider_moved)

	_drag_slider = _panel.add_slider("Drag", 0.0, 0.1, drag_coefficient, 0.005)
	_drag_slider.slider_moved.connect(_on_drag_slider_moved)

	# Position panel to the left, at chest height, angled toward viewer
	_panel.position = Vector3(-0.5, 0.35, 0.15)
	_panel.rotation_degrees = Vector3(0, 30, 0)
	add_child(_panel)

func _update_panel_info() -> void:
	pass  # Slider labels auto-update via slider_smooth.gd

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
	shaft.material_override = _create_arrow_material()
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
	head.material_override = _create_arrow_material()
	arrow_root.add_child(head)

	return arrow_root

func _create_arrow_material() -> StandardMaterial3D:
	# Use Ada accent_blue for general force arrows
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.20, 0.55, 0.95, 0.25)
	mat.emission_enabled = true
	mat.emission = Color(0.20, 0.55, 0.95)
	mat.emission_energy_multiplier = 0.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

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


func compute_drag_force(mover: Mover) -> Vector3:
	var speed: float = mover.velocity.length()
	if speed <= 0.01:
		return Vector3.ZERO

	var drag_magnitude: float = drag_coefficient * speed * speed
	var drag_direction: Vector3 = -mover.velocity.normalized()
	return drag_direction * drag_magnitude

func reset_scene() -> void:
	wind_strength = DEFAULT_WIND_STRENGTH
	drag_coefficient = DEFAULT_DRAG_COEFFICIENT
	if _panel:
		_panel.set_slider_value(0, wind_strength)
		_panel.set_slider_value(1, drag_coefficient)
	spawn_movers()

func toggle_force_vectors() -> void:
	show_force_vectors = !show_force_vectors
	for arrow in force_visuals.values():
		if is_instance_valid(arrow):
			arrow.visible = show_force_vectors

func _on_wind_slider_moved(_position) -> void:
	# Read the logical value from the panel helper
	wind_strength = _panel.get_slider_value(0)

func _on_drag_slider_moved(_position) -> void:
	drag_coefficient = _panel.get_slider_value(1)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
