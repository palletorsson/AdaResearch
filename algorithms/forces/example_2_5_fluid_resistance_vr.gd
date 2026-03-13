# ===========================================================================
# NOC Example 2.5: Fluid Resistance
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const DEFAULT_GRAVITY := 0.9
const DEFAULT_DRAG_COEFF := 0.8
const DEFAULT_FLUID_DEPTH := 0.45
const ARROW_LENGTH_SCALE := 0.6
const MIN_ARROW_LENGTH := 0.08
const MAX_ARROW_LENGTH := 0.9

var movers: Array[Mover] = []
var mover_labels: Dictionary = {}
var drag_visuals: Dictionary = {}
var mover_initial_positions: Dictionary = {}

var gravity_strength: float = DEFAULT_GRAVITY
var drag_coefficient: float = DEFAULT_DRAG_COEFF
var fluid_depth: float = DEFAULT_FLUID_DEPTH
var fluid_surface_y: float = -0.05

# UI — Ada rack panel
var _panel: ForcesRackPanel
var _drag_slider: Node3D
var _gravity_slider: Node3D
var _depth_slider: Node3D

var fluid_volume: MeshInstance3D
var auto_reset_timer: Timer

func _ready() -> void:
	# Scale down for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	create_fluid_volume()
	_create_panel()
	spawn_movers()
	setup_auto_reset()
	print("Example 2.5: Fluid resistance")

func setup_auto_reset() -> void:
	auto_reset_timer = Timer.new()
	auto_reset_timer.wait_time = 20.0
	auto_reset_timer.autostart = true
	auto_reset_timer.timeout.connect(reset_scene)
	add_child(auto_reset_timer)

func _process(_delta: float) -> void:
	pass  # Slider labels auto-update

func _physics_process(_delta: float) -> void:
	for mover in movers:
		if not is_instance_valid(mover):
			continue

		var gravity_force: Vector3 = Vector3(0, -gravity_strength * mover.mass, 0)
		mover.apply_force(gravity_force)

		var drag_force: Vector3 = compute_drag_force(mover)
		mover.apply_force(drag_force)

		update_drag_visual(mover, drag_force)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				reset_scene()
			KEY_SPACE:
				spread_movers()

func create_fluid_volume() -> void:
	fluid_volume = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(0.9, fluid_depth, 0.9)
	fluid_volume.mesh = mesh
	fluid_volume.position = Vector3(0, fluid_surface_y - fluid_depth * 0.5, 0)

	# Use Ada accent_blue tinted translucent material
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.20, 0.55, 0.95, 0.20)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.6
	material.metallic = 0.0
	material.emission_enabled = true
	material.emission = Color(0.20, 0.55, 0.95)
	material.emission_energy_multiplier = 0.25
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	fluid_volume.material_override = material

	add_child(fluid_volume)

	# Surface label — clean, non-billboard
	var surface_label := Label3D.new()
	surface_label.name = "FluidSurfaceLabel"
	surface_label.text = "Fluid surface"
	surface_label.font_size = 14
	surface_label.pixel_size = 0.001
	surface_label.modulate = Color(0.20, 0.55, 0.95, 1.0)
	surface_label.outline_size = 0
	surface_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	surface_label.position = Vector3(0, fluid_surface_y + 0.02, -0.38)
	add_child(surface_label)

func _create_panel() -> void:
	_panel = ForcesRackPanel.new()
	_panel.setup("2.5  Fluid Resistance", 3, 3)
	_panel.set_instructions("[SPACE] Scatter movers  [R] Reset")

	_drag_slider = _panel.add_slider("Drag", 0.05, 1.5, drag_coefficient, 0.01)
	_drag_slider.slider_moved.connect(_on_drag_slider_moved)

	_gravity_slider = _panel.add_slider("Gravity", 0.3, 2.0, gravity_strength, 0.05)
	_gravity_slider.slider_moved.connect(_on_gravity_slider_moved)

	_depth_slider = _panel.add_slider("Depth", 0.15, 0.9, fluid_depth, 0.02)
	_depth_slider.slider_moved.connect(_on_depth_slider_moved)

	# Position panel to the left, at chest height, angled toward viewer
	_panel.position = Vector3(-0.55, 0.35, 0.15)
	_panel.rotation_degrees = Vector3(0, 30, 0)
	add_child(_panel)

func spawn_movers() -> void:
	clear_existing_movers()

	var configs: Array = [
		{ "mass": 0.6, "position": Vector3(-0.3, 0.35, 0.0) },
		{ "mass": 1.0, "position": Vector3(-0.15, 0.38, 0.0) },
		{ "mass": 1.4, "position": Vector3(0.0, 0.4, 0.0) },
		{ "mass": 2.0, "position": Vector3(0.15, 0.42, 0.0) },
		{ "mass": 2.6, "position": Vector3(0.3, 0.44, 0.0) }
	]

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for config in configs:
		var mover := Mover.new()
		mover.mass = float(config["mass"])
		mover.position_v = config["position"]
		mover.velocity = Vector3.ZERO
		mover.acceleration = Vector3.ZERO
		mover.bounce_damping = 0.4
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

		var arrow := create_drag_arrow()
		mover.add_child(arrow)
		drag_visuals[mover] = arrow

func clear_existing_movers() -> void:
	for mover in movers:
		if is_instance_valid(mover):
			mover.queue_free()
	movers.clear()
	mover_labels.clear()
	drag_visuals.clear()
	mover_initial_positions.clear()


func create_drag_arrow() -> Node3D:
	var arrow_root := Node3D.new()
	arrow_root.name = "DragArrow"
	arrow_root.visible = false

	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var shaft_mesh: CylinderMesh = CylinderMesh.new()
	shaft_mesh.top_radius = 0.005
	shaft_mesh.bottom_radius = 0.005
	shaft_mesh.height = 1.0
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0, 0, -0.5)
	shaft.rotation_degrees = Vector3(90, 0, 0)
	shaft.material_override = _create_drag_arrow_material()
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
	head.material_override = _create_drag_arrow_material()
	arrow_root.add_child(head)

	return arrow_root

func _create_drag_arrow_material() -> StandardMaterial3D:
	# Use Ada accent_cyan for drag arrows
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.00, 0.78, 0.85, 0.25)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.00, 0.78, 0.85)
	mat.emission_energy_multiplier = 0.4
	return mat

func compute_drag_force(mover: Mover) -> Vector3:
	if not is_instance_valid(mover):
		return Vector3.ZERO

	var in_fluid = is_inside_fluid(mover.position_v)
	if not in_fluid:
		return Vector3.ZERO

	var speed: float = mover.velocity.length()
	if speed < 0.01:
		return Vector3.ZERO

	var drag_mag: float = drag_coefficient * speed * speed
	var drag_force = -mover.velocity.normalized() * drag_mag

	return drag_force

func is_inside_fluid(position: Vector3) -> bool:
	var bottom: float = fluid_surface_y - fluid_depth
	return position.y <= fluid_surface_y and position.y >= bottom

func update_drag_visual(mover: Mover, drag_force: Vector3) -> void:
	var arrow: Node3D = drag_visuals.get(mover, null)
	if not arrow or not is_instance_valid(arrow):
		return

	var magnitude: float = drag_force.length()
	if magnitude < 0.01:
		arrow.visible = false
		return

	arrow.visible = true
	var length: float = clamp(magnitude * ARROW_LENGTH_SCALE, MIN_ARROW_LENGTH, MAX_ARROW_LENGTH)

	var shaft: Node = arrow.get_node("Shaft") if arrow.has_node("Shaft") else null
	var head: Node = arrow.get_node("Head") if arrow.has_node("Head") else null

	if shaft and shaft is MeshInstance3D:
		shaft.scale = Vector3(1, 1, length)
		shaft.position = Vector3(0, 0, -length * 0.5)

	if head and head is MeshInstance3D:
		head.position = Vector3(0, 0, -length)
		head.scale = Vector3(1, 1, clamp(length * 0.4, 0.3, 0.9))

	var direction: Vector3 = -drag_force.normalized()
	var up_vector := Vector3.UP
	if abs(direction.dot(up_vector)) > 0.95:
		up_vector = Vector3.RIGHT
	var basis := Basis().looking_at(direction, up_vector)
	arrow.transform = Transform3D(basis, Vector3.ZERO)

func update_fluid_volume() -> void:
	if not is_instance_valid(fluid_volume):
		return

	var mesh := fluid_volume.mesh
	if mesh is BoxMesh:
		(mesh as BoxMesh).size = Vector3(0.9, fluid_depth, 0.9)
	fluid_volume.position = Vector3(0, fluid_surface_y - fluid_depth * 0.5, 0)

	var surface_label := get_node("FluidSurfaceLabel") if has_node("FluidSurfaceLabel") else null
	if surface_label and surface_label is Label3D:
		(surface_label as Label3D).position = Vector3(0, fluid_surface_y + 0.02, -0.38)

func reset_scene() -> void:
	drag_coefficient = DEFAULT_DRAG_COEFF
	gravity_strength = DEFAULT_GRAVITY
	fluid_depth = DEFAULT_FLUID_DEPTH
	if _panel:
		_panel.set_slider_value(0, drag_coefficient)
		_panel.set_slider_value(1, gravity_strength)
		_panel.set_slider_value(2, fluid_depth)
	spawn_movers()
	update_fluid_volume()

func spread_movers() -> void:
	var rng := RandomNumberGenerator.new()
	for mover in movers:
		if not is_instance_valid(mover):
			continue
		mover.velocity += Vector3(rng.randf_range(-0.2, 0.2), 0.0, rng.randf_range(-0.2, 0.2))

func _on_drag_slider_moved(_position) -> void:
	drag_coefficient = _panel.get_slider_value(0)

func _on_gravity_slider_moved(_position) -> void:
	gravity_strength = _panel.get_slider_value(1)
	for mover in movers:
		if is_instance_valid(mover):
			mover.velocity = Vector3.ZERO

func _on_depth_slider_moved(_position) -> void:
	fluid_depth = _panel.get_slider_value(2)
	update_fluid_volume()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

