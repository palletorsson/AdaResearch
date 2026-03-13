extends Node3D

# Spring-Mass System Physics Simulation
# Interactive network of masses connected by springs with real-time physics

@export_category("Spring System Parameters")
@export var mass_count: int = 20
@export var spring_stiffness: float = 50.0
@export var damping: float = 0.95
@export var gravity: float = -9.8
@export var rest_length: float = 2.0
@export var max_spring_length: float = 8.0

@export_category("Mass Properties")
@export var mass_value: float = 1.0
@export var mass_radius: float = 0.2
@export var fixed_anchor_points: bool = true
@export var anchor_count: int = 4

@export_category("Interaction")
@export var enable_mouse_interaction: bool = true
@export var mouse_force_strength: float = 10.0
@export var enable_wind_force: bool = true
@export var wind_strength: float = 2.0

@export_category("Visualization")
@export var show_springs: bool = true
@export var show_velocity_vectors: bool = false
@export var color_by_tension: bool = true
@export var animate_springs: bool = true
@export var auto_rotate: bool = true
@export var auto_interaction: bool = true

# System state
var masses: Array = []
var springs: Array = []
var anchors: Array = []
var time_step: float = 0.016
var wind_time: float = 0.0
var rotation_time: float = 0.0
var interaction_timer: float = 0.0

# Visual elements
var mass_meshes: Array = []
var spring_lines: Array = []
var velocity_arrows: Array = []
var system_container: Node3D

# MultiMesh instances for batched rendering
var _mass_multimesh_instance: MultiMeshInstance3D
var _spring_multimesh_instance: MultiMeshInstance3D

# Vibrant queer color palette
var queer_colors = [
	Color(1.0, 0.4, 0.7, 1.0),    # Hot pink
	Color(0.8, 0.3, 1.0, 1.0),    # Purple
	Color(0.3, 0.9, 1.0, 1.0),    # Cyan
	Color(1.0, 0.8, 0.2, 1.0),    # Gold
	Color(0.5, 1.0, 0.4, 1.0),    # Lime
	Color(1.0, 0.5, 0.3, 1.0),    # Coral
	Color(0.4, 0.7, 1.0, 1.0),    # Sky blue
	Color(1.0, 0.3, 0.5, 1.0)     # Rose
]

# Mass class
class Mass:
	var position: Vector3
	var velocity: Vector3
	var acceleration: Vector3
	var mass: float
	var radius: float
	var is_fixed: bool = false
	var mesh_instance: MeshInstance3D
	var connected_springs: Array = []
	
	func _init(pos: Vector3, m: float, r: float) -> void:
		position = pos
		velocity = Vector3.ZERO
		acceleration = Vector3.ZERO
		mass = m
		radius = r
	
	func apply_force(force: Vector3) -> void:
		if not is_fixed:
			acceleration += force / mass
	
	func update(delta: float) -> void:
		if not is_fixed:
			# Verlet integration
			velocity += acceleration * delta
			position += velocity * delta
			
			# Reset acceleration
			acceleration = Vector3.ZERO
	
	func set_fixed(fixed: bool) -> void:
		is_fixed = fixed
		if is_fixed:
			velocity = Vector3.ZERO

# Spring class
class Spring:
	var mass1: Mass
	var mass2: Mass
	var rest_length: float
	var stiffness: float
	var current_length: float
	var tension: float
	var line_mesh: MeshInstance3D
	
	func _init(m1: Mass, m2: Mass, length: float, k: float) -> void:
		mass1 = m1
		mass2 = m2
		rest_length = length
		stiffness = k
		
		# Add this spring to both masses
		mass1.connected_springs.append(self)
		mass2.connected_springs.append(self)
	
	func update_physics() -> void:
		var direction = mass2.position - mass1.position
		current_length = direction.length()
		
		if current_length > 0:
			direction = direction.normalized()
			var displacement = current_length - rest_length
			var force_magnitude = stiffness * displacement
			tension = abs(force_magnitude)
			
			var force = direction * force_magnitude
			
			# Apply equal and opposite forces
			mass1.apply_force(force)
			mass2.apply_force(-force)
	
	func update_visual() -> void:
		if line_mesh:
			# Update line position and orientation
			var center = (mass1.position + mass2.position) / 2
			line_mesh.position = center
			
			# Orient line toward mass2
			line_mesh.look_at_from_position(line_mesh.position, mass2.position, Vector3.UP)
			
			# Scale line to match spring length
			line_mesh.scale.z = current_length
			
			# Color by tension if enabled
			var material = line_mesh.material_override
			if material:
				var tension_normalized = clamp(tension / 100.0, 0.0, 1.0)
				# Cycle through vibrant colors based on tension
				var base_color = Color(
					0.5 + sin(tension_normalized * 3.14) * 0.5,
					0.5 + cos(tension_normalized * 3.14 * 1.5) * 0.5,
					0.7 + sin(tension_normalized * 3.14 * 2.0) * 0.3,
					0.9
				)
				material.albedo_color = base_color
				material.emission_enabled = true
				material.emission = base_color * 0.6
				material.emission_energy_multiplier = 1.5

func _ready() -> void:
	setup_environment()
	initialize_system()
	create_visuals()
	setup_camera()

func _process(delta: float) -> void:
	simulate_physics(delta)
	update_wind_force(delta)
	update_visuals()

	# Auto-rotate for 3D effect
	if auto_rotate:
		rotation_time += delta
		rotation.y = sin(rotation_time * 0.3) * 0.5
		rotation.x = cos(rotation_time * 0.2) * 0.2

	# Automatic interaction
	if auto_interaction:
		interaction_timer += delta
		if interaction_timer >= 2.0:
			interaction_timer = 0.0
			_apply_auto_force()

	# Handle mouse interaction
	if enable_mouse_interaction:
		handle_mouse_interaction()

func setup_environment() -> void:
	# Lighting
	var light = DirectionalLight3D.new()
	light.light_energy = 1.0
	light.rotation_degrees = Vector3(-30, 45, 0)
	add_child(light)
	
	# Environment
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.05, 0.1)
	environment.ambient_light_color = Color(0.3, 0.3, 0.4)
	environment.ambient_light_energy = 0.6
	env.environment = environment
	add_child(env)
	
	# Container for all system elements
	system_container = Node3D.new()
	system_container.name = "SpringSystem"
	add_child(system_container)

func initialize_system() -> void:
	masses.clear()
	springs.clear()
	anchors.clear()
	
	# Create masses in a grid-like pattern
	var grid_size = int(sqrt(mass_count))
	var spacing = rest_length * 1.2
	var center_offset = Vector3(
		-grid_size * spacing / 2,
		5,
		-grid_size * spacing / 2
	)
	
	# Create masses
	for i in range(mass_count):
		var x = i % grid_size
		var y = i / grid_size
		
		var position = center_offset + Vector3(
			x * spacing + randf_range(-0.5, 0.5),
			randf_range(-1, 1),
			y * spacing + randf_range(-0.5, 0.5)
		)
		
		var mass = Mass.new(position, mass_value, mass_radius)
		masses.append(mass)
	
	# Create anchor points (fixed masses)
	if fixed_anchor_points and anchor_count > 0:
		for i in range(min(anchor_count, masses.size())):
			var anchor_index = i * (masses.size() / anchor_count)
			masses[anchor_index].set_fixed(true)
			anchors.append(masses[anchor_index])
	
	# Create springs between nearby masses
	for i in range(masses.size()):
		for j in range(i + 1, masses.size()):
			var distance = masses[i].position.distance_to(masses[j].position)
			
			# Connect masses that are close enough
			if distance < rest_length * 2.0:
				var spring = Spring.new(masses[i], masses[j], rest_length, spring_stiffness)
				springs.append(spring)

func create_visuals() -> void:
	mass_meshes.clear()
	spring_lines.clear()

	# --- Mass MultiMesh ---
	var sphere := SphereMesh.new()
	sphere.radius = mass_radius
	sphere.height = mass_radius * 2

	var mass_mat := StandardMaterial3D.new()
	mass_mat.vertex_color_use_as_albedo = true
	mass_mat.emission_enabled = true
	mass_mat.metallic = 0.3
	mass_mat.roughness = 0.7

	var mass_mm := MultiMesh.new()
	mass_mm.transform_format = MultiMesh.TRANSFORM_3D
	mass_mm.use_colors = true
	mass_mm.instance_count = masses.size()
	mass_mm.mesh = sphere
	mass_mm.mesh.material = mass_mat

	_mass_multimesh_instance = MultiMeshInstance3D.new()
	_mass_multimesh_instance.name = "MassMultiMesh"
	_mass_multimesh_instance.multimesh = mass_mm
	system_container.add_child(_mass_multimesh_instance)

	for i in masses.size():
		var mass = masses[i]
		mass_mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, mass.position))
		var color: Color = queer_colors[i % queer_colors.size()]
		if mass.is_fixed:
			color = color * 0.7
		mass_mm.set_instance_color(i, color)

	# --- Spring MultiMesh ---
	if show_springs and not springs.is_empty():
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.03
		cyl.bottom_radius = 0.03
		cyl.height = 1.0

		var spring_mat := StandardMaterial3D.new()
		spring_mat.vertex_color_use_as_albedo = true
		spring_mat.emission_enabled = true
		spring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

		var spring_mm := MultiMesh.new()
		spring_mm.transform_format = MultiMesh.TRANSFORM_3D
		spring_mm.use_colors = true
		spring_mm.instance_count = springs.size()
		spring_mm.mesh = cyl
		spring_mm.mesh.material = spring_mat

		_spring_multimesh_instance = MultiMeshInstance3D.new()
		_spring_multimesh_instance.name = "SpringMultiMesh"
		_spring_multimesh_instance.multimesh = spring_mm
		system_container.add_child(_spring_multimesh_instance)

		for i in springs.size():
			var s = springs[i]
			var t := _compute_spring_transform(s.mass1.position, s.mass2.position)
			spring_mm.set_instance_transform(i, t)
			spring_mm.set_instance_color(i, Color(0.6, 0.6, 0.6, 0.8))

func _compute_spring_transform(from_pos: Vector3, to_pos: Vector3) -> Transform3D:
	"""Compute transform for a unit cylinder to span between two points"""
	var mid := (from_pos + to_pos) * 0.5
	var diff := to_pos - from_pos
	var dist := diff.length()
	if dist < 0.001:
		return Transform3D(Basis.IDENTITY, mid)
	var dir := diff / dist
	var up := Vector3.UP
	if abs(dir.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right := dir.cross(up).normalized()
	up = right.cross(dir).normalized()
	var basis := Basis(right, dir * dist, up)
	return Transform3D(basis, mid)

func setup_camera() -> void:
	var camera = Camera3D.new()
	camera.position = Vector3(0, 8, 12)
	add_child(camera)
	camera.look_at_from_position(camera.position, Vector3(0, 3, 0), Vector3.UP)

func simulate_physics(_delta) -> void:
	var fixed_delta = time_step
	
	# Apply gravity to all masses
	for mass in masses:
		if not mass.is_fixed:
			mass.apply_force(Vector3(0, gravity * mass.mass, 0))
	
	# Update spring forces
	for spring in springs:
		spring.update_physics()
	
	# Apply damping
	for mass in masses:
		if not mass.is_fixed:
			mass.velocity *= damping
	
	# Update mass positions
	for mass in masses:
		mass.update(fixed_delta)
		
		# Simple boundary constraints
		if mass.position.y < -5:
			mass.position.y = -5
			mass.velocity.y = abs(mass.velocity.y) * 0.5

func update_wind_force(delta) -> void:
	if enable_wind_force:
		wind_time += delta
		
		# Create oscillating wind force
		var wind_direction = Vector3(
			sin(wind_time * 0.8) * wind_strength,
			0,
			cos(wind_time * 0.5) * wind_strength * 0.5
		)
		
		for mass in masses:
			if not mass.is_fixed:
				mass.apply_force(wind_direction)

func handle_mouse_interaction() -> void:
	# This is a simplified version - in a real implementation you'd use proper mouse raycasting
	# For now, we'll just apply a random force to simulate interaction
	if Input.is_action_pressed("ui_accept"):  # Space bar
		if masses.size() > 0:
			var random_mass = masses[randi() % masses.size()]
			if not random_mass.is_fixed:
				var random_force = Vector3(
					randf_range(-mouse_force_strength, mouse_force_strength),
					randf_range(0, mouse_force_strength),
					randf_range(-mouse_force_strength, mouse_force_strength)
				)
				random_mass.apply_force(random_force)

func update_visuals() -> void:
	# Update mass positions and colors via MultiMesh
	if _mass_multimesh_instance:
		var mm := _mass_multimesh_instance.multimesh
		for i in masses.size():
			var mass = masses[i]
			mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, mass.position))
			# Update color based on velocity
			var speed: float = mass.velocity.length()
			var base_color: Color = queer_colors[i % queer_colors.size()]
			if mass.is_fixed:
				base_color = base_color * 0.7
			if speed > 1.0 and not mass.is_fixed:
				var intensity: float = clamp(speed / 5.0, 0.0, 1.0)
				base_color = base_color.lerp(Color(1.0, 0.4, 0.8), intensity)
			mm.set_instance_color(i, base_color)

	# Update spring transforms and colors via MultiMesh
	if show_springs and _spring_multimesh_instance:
		var smm := _spring_multimesh_instance.multimesh
		for i in springs.size():
			var s = springs[i]
			var t := _compute_spring_transform(s.mass1.position, s.mass2.position)
			smm.set_instance_transform(i, t)
			# Color by tension
			if color_by_tension:
				var tension_normalized: float = clamp(s.tension / 100.0, 0.0, 1.0)
				var c := Color(
					0.5 + sin(tension_normalized * 3.14) * 0.5,
					0.5 + cos(tension_normalized * 3.14 * 1.5) * 0.5,
					0.7 + sin(tension_normalized * 3.14 * 2.0) * 0.3,
					0.9
				)
				smm.set_instance_color(i, c)

func _apply_auto_force() -> void:
	# Apply random forces to create automatic interaction
	if masses.size() > 0:
		var random_indices = []
		for i in range(min(3, masses.size())):
			random_indices.append(randi() % masses.size())

		for idx in random_indices:
			var mass = masses[idx]
			if not mass.is_fixed:
				var random_force = Vector3(
					randf_range(-mouse_force_strength, mouse_force_strength),
					randf_range(-mouse_force_strength, mouse_force_strength),
					randf_range(-mouse_force_strength, mouse_force_strength)
				)
				mass.apply_force(random_force)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

