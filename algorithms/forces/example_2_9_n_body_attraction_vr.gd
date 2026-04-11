# ===========================================================================
# NOC Example 2.9: N-Body Attraction
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const DEFAULT_GRAVITY_STRENGTH := 0.35
const MAX_BODIES := 8
const ARROW_LENGTH_SCALE := 0.35
const MIN_ARROW_LENGTH := 0.05
const MAX_ARROW_LENGTH := 0.7

var bodies: Array[Mover] = []
var force_visuals: Dictionary = {}
var initial_states: Dictionary = {}

var gravity_strength: float = DEFAULT_GRAVITY_STRENGTH
var body_count: int = 6
var show_force_vectors: bool = true

# UI — Ada rack panel
var _panel: ForcesRackPanel
var _gravity_slider: Node3D
var _bodies_slider: Node3D
var auto_reset_timer: Timer

func _ready() -> void:
	# Scale down for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	_create_panel()
	spawn_bodies(body_count)
	setup_auto_reset()
	print("Example 2.9: N-body attraction")

func setup_auto_reset() -> void:
	auto_reset_timer = Timer.new()
	auto_reset_timer.wait_time = 20.0
	auto_reset_timer.autostart = true
	auto_reset_timer.timeout.connect(reset_scene)
	add_child(auto_reset_timer)

func _process(_delta: float) -> void:
	pass  # Slider labels auto-update

func _physics_process(_delta: float) -> void:
	for i in range(bodies.size()):
		var mover := bodies[i]
		if not is_instance_valid(mover):
			continue

		var total_force: Vector3 = Vector3.ZERO
		for j in range(bodies.size()):
			if i == j:
				continue
			var other := bodies[j]
			if not is_instance_valid(other):
				continue
			total_force += calculate_attraction(mover, other)

		mover.apply_force(total_force)
		update_force_arrow(force_visuals.get(mover, null), total_force)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				reset_scene()
			KEY_T:
				toggle_force_vectors()

func _create_panel() -> void:
	_panel = ForcesRackPanel.new()
	_panel.setup("2.9  N-Body Attraction", 2, 3)
	_panel.set_instructions("[T] Toggle arrows  [R] Reset")

	_gravity_slider = _panel.add_slider("Gravity", 0.1, 0.8, gravity_strength, 0.02)
	_gravity_slider.slider_moved.connect(_on_gravity_slider_moved)

	# Bodies slider — use snap for integer stepping
	_bodies_slider = _panel.add_slider("Bodies", 3.0, 8.0, float(body_count), 1.0, true)
	_bodies_slider.slider_moved.connect(_on_bodies_slider_moved)

	# Position panel to the left, at chest height, angled toward viewer
	_panel.position = Vector3(-0.5, 0.35, 0.15)
	_panel.rotation_degrees = Vector3(0, 30, 0)
	add_child(_panel)

func spawn_bodies(count: int) -> void:
	clear_bodies()

	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	for i in range(count):
		var mass := rng.randf_range(0.6, 2.2)
		var pos := Vector3(
			rng.randf_range(-0.4, 0.4),
			rng.randf_range(-0.1, 0.4),
			rng.randf_range(-0.4, 0.4)
		)
		var velocity := Vector3(
			rng.randf_range(-0.1, 0.1),
			rng.randf_range(-0.08, 0.08),
			rng.randf_range(-0.1, 0.1)
		)

		var random_color := Color(
			rng.randf_range(0.7, 1.0),
			rng.randf_range(0.4, 0.7),
			rng.randf_range(0.8, 1.0)
		)

		var body := create_body("Body_%d" % i, mass, pos, velocity, random_color)

		bodies.append(body)
		initial_states[body] = {
			"position": pos,
			"velocity": velocity,
			"mass": mass
		}

		var arrow := create_force_arrow(random_color)
		body.add_child(arrow)
		force_visuals[body] = arrow

func create_body(body_name: String, mass: float, pos: Vector3, velocity: Vector3, color: Color) -> Mover:
	var body := Mover.new()
	body.name = body_name
	body.mass = mass
	body.position_v = pos
	body.velocity = velocity
	body.acceleration = Vector3.ZERO
	body.bounce_damping = 0.5
	add_child(body)
	body.set_size(0.03 + mass * 0.01)
	body.set_color(color)
	return body

func create_force_arrow(base_color: Color) -> Node3D:
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
	shaft.material_override = _create_arrow_material(base_color)
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
	head.material_override = _create_arrow_material(base_color)
	arrow_root.add_child(head)

	return arrow_root

func _create_arrow_material(base_color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(base_color.r, base_color.g, base_color.b, 0.25)
	mat.emission_enabled = true
	mat.emission = base_color
	mat.emission_energy_multiplier = 0.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

func calculate_attraction(source: Mover, target: Mover) -> Vector3:
	var direction: Vector3 = target.position_v - source.position_v
	var distance: float = direction.length()
	distance = clamp(distance, 0.08, 0.9)
	direction = direction.normalized()
	var strength: float = (gravity_strength * source.mass * target.mass) / (distance * distance)
	return direction * strength

func update_force_arrow(arrow: Node3D, force: Vector3) -> void:
	if not arrow or not is_instance_valid(arrow):
		return

	var magnitude: float = force.length()
	if not show_force_vectors or magnitude < 0.02:
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
		head.scale = Vector3(1, 1, clamp(length * 0.4, 0.25, 0.8))

	var direction: Vector3 = -force.normalized()
	var up_vector := Vector3.UP
	if abs(direction.dot(up_vector)) > 0.95:
		up_vector = Vector3.RIGHT
	var basis := Basis().looking_at(direction, up_vector)
	arrow.transform = Transform3D(basis, Vector3.ZERO)

func reset_scene() -> void:
	body_count = int(_panel.get_slider_value(1))
	spawn_bodies(body_count)

func toggle_force_vectors() -> void:
	show_force_vectors = !show_force_vectors
	for arrow in force_visuals.values():
		if is_instance_valid(arrow):
			arrow.visible = show_force_vectors

func _on_gravity_slider_moved(_position) -> void:
	gravity_strength = _panel.get_slider_value(0)

func _on_bodies_slider_moved(_position) -> void:
	var new_count: int = int(round(_panel.get_slider_value(1)))
	if new_count != body_count:
		body_count = new_count
		spawn_bodies(body_count)

func clear_bodies() -> void:
	for body in bodies:
		if is_instance_valid(body):
			body.queue_free()
	bodies.clear()
	force_visuals.clear()
	initial_states.clear()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
