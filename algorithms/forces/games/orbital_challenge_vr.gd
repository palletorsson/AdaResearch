# ===========================================================================
# Orbital Challenge VR - Interactive Game Expansion of Example 2.6: Attraction
# Navigate satellites through gravitational fields and achieve stable orbits!
# ===========================================================================

extends Node3D

const PARAMETER_CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const ATTRACTOR_SCENE := preload("res://commons/primitives/point/grab_sphere_point_with_color.tscn")

# Game constants
const MAX_SATELLITES := 5
const TARGET_ORBIT_RADIUS_MIN := 0.25
const TARGET_ORBIT_RADIUS_MAX := 0.35
const ORBIT_STABLE_TIME := 3.0
const LEVEL_TIME_LIMIT := 60.0

# Physics
var gravity_strength: float = 0.65
var attractor_mass: float = 5.0
var central_attractor_pos: Vector3 = Vector3.ZERO

# Game objects
var central_attractor: Node3D
var satellites: Array[Mover] = []
var collectibles: Array[Node3D] = []
var force_arrows: Dictionary = {}

# VR interaction
var satellite_launch_ready: bool = true
var launch_position: Vector3 = Vector3(-0.4, 0.2, 0)
var launch_velocity: Vector3 = Vector3.ZERO

# Game state
var satellites_in_orbit: int = 0
var level: int = 1
var score: int = 0
var time_remaining: float = LEVEL_TIME_LIMIT
var game_active: bool = false

# Level objectives
var required_satellites_in_orbit: int = 3
var collectibles_remaining: int = 0

# UI
var info_label: Label3D
var score_label: Label3D
var time_label: Label3D
var objective_label: Label3D
var instructions_label: Label3D
var gravity_controller: ParameterController3D

# Settings
var show_orbits: bool = true
var show_gravity_field: bool = true

func _ready():
	# Scale down for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	create_central_attractor()
	create_gravity_field_visualization()
	create_launch_platform()
	create_ui()
	setup_level(1)

	print("Orbital Challenge VR - Master gravity to achieve perfect orbits!")

func _process(delta: float):
	if game_active:
		time_remaining -= delta
		if time_remaining <= 0.0:
			fail_level()

	update_satellite_orbits()
	update_ui()

func _physics_process(_delta: float):
	# Update central attractor position (if grabbable)
	if is_instance_valid(central_attractor):
		central_attractor_pos = central_attractor.global_position

	# Apply gravitational forces to all satellites
	for satellite in satellites:
		if not is_instance_valid(satellite):
			continue

		var force := calculate_gravity(satellite)
		satellite.apply_force(force)

		# Update force visualization
		if show_orbits:
			update_force_arrow(satellite, force)

	# Check collisions with collectibles
	check_collectible_collection()

func create_central_attractor():
	central_attractor = ATTRACTOR_SCENE.instantiate()
	central_attractor.name = "CentralAttractor"
	central_attractor.position = central_attractor_pos
	add_child(central_attractor)

	# Make it larger and more visible
	if central_attractor.has_node("GrabSphere/MeshInstance3D"):
		var mesh := central_attractor.get_node("GrabSphere/MeshInstance3D")
		mesh.scale = Vector3(3, 3, 3)

func create_gravity_field_visualization():
	if not show_gravity_field:
		return

	# Create concentric rings showing gravity field
	for radius in [0.15, 0.25, 0.35, 0.45, 0.55]:
		create_orbit_ring(radius, Color(0.5, 0.7, 1.0, 0.15))

	# Highlight target orbit zone
	create_orbit_ring(TARGET_ORBIT_RADIUS_MIN, Color.GREEN)
	create_orbit_ring(TARGET_ORBIT_RADIUS_MAX, Color.GREEN)

func create_orbit_ring(radius: float, color: Color):
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.01
	torus.outer_radius = radius + 0.01
	torus.rings = 32
	torus.ring_segments = 6
	ring.mesh = torus
	ring.position = Vector3.ZERO
	ring.rotation_degrees = Vector3(90, 0, 0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat

	add_child(ring)

func create_launch_platform():
	var platform := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.15, 0.05, 0.15)
	platform.mesh = box
	platform.position = launch_position

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.8, 1.0, 0.6)
	mat.emission_enabled = true
	mat.emission = Color.CYAN * 0.3
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	platform.material_override = mat

	add_child(platform)

func setup_level(level_number: int):
	level = level_number
	game_active = true
	time_remaining = LEVEL_TIME_LIMIT
	satellites_in_orbit = 0

	# Clear existing satellites
	for satellite in satellites:
		if is_instance_valid(satellite):
			satellite.queue_free()
	satellites.clear()
	force_arrows.clear()

	# Clear existing collectibles
	for collectible in collectibles:
		if is_instance_valid(collectible):
			collectible.queue_free()
	collectibles.clear()

	# Set level objectives
	required_satellites_in_orbit = 2 + level
	collectibles_remaining = level * 2

	# Spawn collectibles
	spawn_collectibles(collectibles_remaining)

	satellite_launch_ready = true

func spawn_collectibles(count: int):
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(count):
		var angle := rng.randf_range(0, TAU)
		var radius := rng.randf_range(0.3, 0.5)
		var collectible_pos := Vector3(
			cos(angle) * radius,
			rng.randf_range(-0.1, 0.1),
			sin(angle) * radius
		)

		var collectible := create_collectible(collectible_pos)
		collectibles.append(collectible)

func create_collectible(pos: Vector3) -> Node3D:
	var col := Area3D.new()
	col.name = "Collectible"
	col.position = pos

	var collider := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.04
	collider.shape = sphere
	col.add_child(collider)

	var mesh_instance := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.04
	mesh_instance.mesh = sphere_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.YELLOW
	mat.emission_enabled = true
	mat.emission = Color.YELLOW
	mat.emission_energy_multiplier = 1.5
	mesh_instance.material_override = mat
	col.add_child(mesh_instance)

	add_child(col)

	# Rotate for visual appeal
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(mesh_instance, "rotation_degrees:y", 360, 2.0)

	return col

func check_collectible_collection():
	for i in range(collectibles.size() - 1, -1, -1):
		var collectible := collectibles[i]
		if not is_instance_valid(collectible):
			continue

		for satellite in satellites:
			if not is_instance_valid(satellite):
				continue

			var distance := satellite.global_position.distance_to(collectible.global_position)
			if distance < 0.08:
				# Collected!
				score += 100
				create_collection_effect(collectible.global_position)
				collectible.queue_free()
				collectibles.remove_at(i)
				collectibles_remaining -= 1
				break

func create_collection_effect(pos: Vector3):
	var particles := CPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.5
	particles.position = pos
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.06
	particles.gravity = Vector3.ZERO
	particles.initial_velocity_min = 0.3
	particles.initial_velocity_max = 0.6
	particles.scale_amount_min = 0.015
	particles.scale_amount_max = 0.03
	particles.color = Color.YELLOW

	add_child(particles)

	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func launch_satellite(velocity: Vector3):
	if not satellite_launch_ready or satellites.size() >= MAX_SATELLITES:
		return

	var satellite := Mover.new()
	satellite.mass = 0.4
	satellite.position_v = launch_position
	satellite.velocity = velocity
	satellite.bounce_damping = 0.9
	satellite.set_meta("stable_orbit_time", 0.0)
	satellite.set_meta("in_target_orbit", false)
	add_child(satellite)
	satellite.set_size(0.04)
	satellite.set_color(Color(0.7, 0.9, 1.0))

	satellites.append(satellite)

	# Create force arrow
	var arrow := create_force_arrow()
	satellite.add_child(arrow)
	force_arrows[satellite] = arrow

	satellite_launch_ready = false

	# Cooldown before next launch
	await get_tree().create_timer(1.5).timeout
	satellite_launch_ready = true

func calculate_gravity(satellite: Mover) -> Vector3:
	var direction := central_attractor_pos - satellite.global_position
	var distance := direction.length()
	distance = clamp(distance, 0.05, 1.0)
	direction = direction.normalized()

	var strength := (gravity_strength * attractor_mass * satellite.mass) / (distance * distance)
	return direction * strength

func update_satellite_orbits():
	satellites_in_orbit = 0

	for satellite in satellites:
		if not is_instance_valid(satellite):
			continue

		var distance := satellite.global_position.distance_to(central_attractor_pos)
		var in_target := distance >= TARGET_ORBIT_RADIUS_MIN and distance <= TARGET_ORBIT_RADIUS_MAX

		if in_target:
			var stable_time: float = satellite.get_meta("stable_orbit_time", 0.0)
			stable_time += get_process_delta_time()
			satellite.set_meta("stable_orbit_time", stable_time)

			if stable_time >= ORBIT_STABLE_TIME:
				if not satellite.get_meta("in_target_orbit", false):
					satellite.set_meta("in_target_orbit", true)
					satellites_in_orbit += 1
					score += 50
					create_orbit_achieved_effect(satellite.global_position)
		else:
			satellite.set_meta("stable_orbit_time", 0.0)
			satellite.set_meta("in_target_orbit", false)

		# Count currently stable satellites
		if satellite.get_meta("in_target_orbit", false):
			satellites_in_orbit += 1

	# Check win condition
	if satellites_in_orbit >= required_satellites_in_orbit and collectibles_remaining == 0:
		complete_level()

func create_orbit_achieved_effect(pos: Vector3):
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.05
	torus.outer_radius = 0.08
	ring.mesh = torus
	ring.position = pos
	ring.rotation_degrees = Vector3(90, 0, 0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.GREEN
	mat.emission_enabled = true
	mat.emission = Color.GREEN
	mat.emission_energy_multiplier = 2.0
	ring.material_override = mat

	add_child(ring)

	# Animate and remove
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector3(3, 3, 3), 0.8)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.8)
	tween.tween_callback(ring.queue_free)

func create_force_arrow() -> Node3D:
	var arrow_root := Node3D.new()
	arrow_root.name = "GravityArrow"

	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.003
	shaft_mesh.bottom_radius = 0.003
	shaft_mesh.height = 1.0
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0, 0, 0.5)
	shaft.rotation_degrees = Vector3(-90, 0, 0)
	arrow_root.add_child(shaft)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.015
	head_mesh.height = 0.05
	head.mesh = head_mesh
	head.position = Vector3(0, 0, 1.0)
	head.rotation_degrees = Vector3(-90, 0, 0)
	arrow_root.add_child(head)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 1.0, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 1.0) * 0.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shaft.material_override = mat
	head.material_override = mat

	arrow_root.visible = show_orbits
	return arrow_root

func update_force_arrow(satellite: Mover, force: Vector3):
	var arrow: Node3D = force_arrows.get(satellite, null)
	if not arrow or not is_instance_valid(arrow):
		return

	var magnitude := force.length()
	if magnitude < 0.01:
		arrow.visible = false
		return

	arrow.visible = show_orbits
	var length: float = clamp(magnitude * 0.3, 0.05, 0.6)

	var shaft: Node = arrow.get_node_or_null("Shaft") if arrow.has_node("Shaft") else null
	var head: Node = arrow.get_node_or_null("Head") if arrow.has_node("Head") else null

	if shaft and shaft is MeshInstance3D:
		shaft.scale = Vector3(1, 1, length)
		shaft.position = Vector3(0, 0, length * 0.5)

	if head and head is MeshInstance3D:
		head.position = Vector3(0, 0, length)

	var direction := -force.normalized()
	var up_vector := Vector3.UP
	if abs(direction.dot(up_vector)) > 0.95:
		up_vector = Vector3.RIGHT
	var basis := Basis().looking_at(direction, up_vector)
	arrow.transform = Transform3D(basis, Vector3.ZERO)

func create_ui():
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 32
	info_label.outline_size = 4
	info_label.modulate = Color.WHITE
	info_label.position = Vector3(0, 0.8, -0.3)
	add_child(info_label)

	score_label = Label3D.new()
	score_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	score_label.font_size = 28
	score_label.modulate = Color.YELLOW
	score_label.position = Vector3(0, 0.65, -0.3)
	add_child(score_label)

	time_label = Label3D.new()
	time_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	time_label.font_size = 24
	time_label.modulate = Color.CYAN
	time_label.position = Vector3(0, 0.52, -0.3)
	add_child(time_label)

	objective_label = Label3D.new()
	objective_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	objective_label.font_size = 20
	objective_label.modulate = Color(0.8, 1.0, 0.8)
	objective_label.position = Vector3(0, 0.4, -0.3)
	add_child(objective_label)

	instructions_label = Label3D.new()
	instructions_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions_label.font_size = 16
	instructions_label.modulate = Color(0.7, 0.9, 1.0)
	instructions_label.position = Vector3(0, 0.28, -0.3)
	instructions_label.text = "[SPACE] Launch | [R] Reset | [T] Toggle Orbits"
	add_child(instructions_label)

	gravity_controller = PARAMETER_CONTROLLER_SCENE.instantiate()
	gravity_controller.parameter_name = "Gravity"
	gravity_controller.min_value = 0.3
	gravity_controller.max_value = 1.0
	gravity_controller.default_value = gravity_strength
	gravity_controller.step_size = 0.05
	gravity_controller.position = Vector3(0.5, 0.35, -0.2)
	gravity_controller.rotation_degrees = Vector3(0, -25, 0)
	add_child(gravity_controller)
	gravity_controller.value_changed.connect(_on_gravity_changed)
	gravity_controller.set_value(gravity_strength)

func update_ui():
	if info_label:
		info_label.text = "ORBITAL CHALLENGE\nLevel %d" % level

	if score_label:
		score_label.text = "Score: %d" % score

	if time_label:
		time_label.text = "Time: %d" % int(time_remaining)

	if objective_label:
		objective_label.text = "Orbits: %d/%d | Collect: %d" % [satellites_in_orbit, required_satellites_in_orbit, collectibles_remaining]

func _on_gravity_changed(value: float):
	gravity_strength = value

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				setup_level(level)
			KEY_SPACE:
				# Launch with test velocity
				var test_velocity := Vector3(0.4, 0, 0.6)
				launch_satellite(test_velocity)
			KEY_T:
				show_orbits = !show_orbits

func complete_level():
	game_active = false

	if info_label:
		info_label.text = "LEVEL %d COMPLETE!\nScore: %d" % [level, score]

	await get_tree().create_timer(3.0).timeout
	setup_level(level + 1)

func fail_level():
	game_active = false

	if info_label:
		info_label.text = "TIME'S UP!\nTry Again"

	await get_tree().create_timer(3.0).timeout
	setup_level(level)
