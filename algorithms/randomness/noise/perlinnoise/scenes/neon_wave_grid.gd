extends Node3D

# Enhanced Neon Waves Grid
# An improved implementation with more visual options and effects

@export_group("Grid Settings")
@export var grid_width := 4
@export var grid_height := 4
@export var cell_spacing := 2.0

@export_group("Wave Appearance")
@export var wave_segments := 20
@export var wave_amplitude := 0.5
@export var neon_color := Color(1.0, 0.0, 1.0)  # Magenta/Pink
@export var neon_intensity := 3.5
@export var neon_thickness := 0.03
@export var use_trail_effect := true

@export_group("Animation")
@export var variation_amount := 0.6
@export var animate := true
@export var animation_speed := 1.0
@export var wave_complexity := 2.0
@export var sync_waves := false

# Internal variables
var wave_container : Node3D
var waves = []
var noise : FastNoiseLite
var materials = []
var time_offset = 0.0

func _ready():
	# Create noise generator for random wave variations
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.5
	noise.fractal_octaves = 2
	
	# Create container for all waves
	wave_container = Node3D.new()
	wave_container.name = "WaveContainer"
	add_child(wave_container)
	
	# Set up environment
	setup_environment()
	
	# Generate the wave grid
	generate_wave_grid()

func setup_environment():
	# Create environment if not already present
	if get_tree().root.get_node_or_null("WorldEnvironment") == null:
		var world_env = WorldEnvironment.new()
		var environment = Environment.new()
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(0, 0, 0)  # Black background
		
		# Glow effect for the neon
		environment.glow_enabled = true
		environment.glow_intensity = 1.5
		environment.glow_bloom = 0.3
		#environment.glow_blend_mode = Environment.GLOW_BLEND_ADD
		environment.glow_hdr_threshold = 0.7
		
		world_env.environment = environment
		add_child(world_env)

func generate_wave_grid():
	# Calculate grid dimensions
	var grid_half_width = (grid_width - 1) * cell_spacing * 0.5
	var grid_half_height = (grid_height - 1) * cell_spacing * 0.5
	
	# Create waves in a grid pattern
	for y in range(grid_height):
		for x in range(grid_width):
			# Calculate position for this wave
			var pos_x = x * cell_spacing - grid_half_width
			var pos_y = y * cell_spacing - grid_half_height
			
			# Generate a unique seed for this wave based on position
			var wave_seed = x + y * grid_width
			var wave = create_wave(Vector3(pos_x, pos_y, 0), wave_seed)
			wave_container.add_child(wave)
			waves.append(wave)

func create_wave(position: Vector3, seed_offset: int) -> MeshInstance3D:
	# Create a path for our wave
	var curve = Curve3D.new()
	
	# Generate points for our wave
	var phase_offset = noise.get_noise_2d(position.x * 10, position.y * 10 + seed_offset)
	
	for i in range(wave_segments + 1):
		var t = float(i) / wave_segments
		var x = t * 1.5 - 0.75  # -0.75 to 0.75 range
		
		# Base sine wave
		var wave_phase = t * TAU * wave_complexity + phase_offset * 10
		var y = sin(wave_phase) * wave_amplitude
		
		# Add some variation based on position
		y += noise.get_noise_2d(seed_offset, t * 10) * variation_amount * wave_amplitude
		
		curve.add_point(Vector3(x, y, 0))
	
	# Create a path follow for the wave
	var wave_mesh = create_neon_path_mesh(curve, seed_offset)
	wave_mesh.position = position
	
	# Store info for animation
	wave_mesh.set_meta("seed_offset", seed_offset)
	wave_mesh.set_meta("curve", curve)
	wave_mesh.set_meta("base_pos", position)
	
	return wave_mesh

func create_neon_path_mesh(curve: Curve3D, seed_offset: int) -> MeshInstance3D:
	# Create immediate mesh for the path
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	mesh_instance.mesh = immediate_mesh
	
	# Create or reuse material
	var material = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = neon_color
	material.emission_energy_multiplier = neon_intensity
	material.albedo_color = neon_color
	
	# Make it unshaded for that neon glow look
	material.flags_unshaded = true
	
	# Enable transparency
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	
	# Add slight color variation
	var color_variation = noise.get_noise_1d(seed_offset) * 0.2
	material.emission = Color(
		clamp(neon_color.r + color_variation, 0, 1),
		clamp(neon_color.g + color_variation, 0, 1),
		clamp(neon_color.b + color_variation, 0, 1)
	)
	
	mesh_instance.material_override = material
	materials.append(material)
	
	# Draw the path as a tube
	draw_curve_tube(immediate_mesh, curve, neon_thickness)
	
	# Add trail effect if enabled
	if use_trail_effect:
		add_trail_effect(mesh_instance, material, seed_offset)
	
	return mesh_instance

func add_trail_effect(wave_mesh: MeshInstance3D, material: Material, seed_offset: int):
	# Create subtle trail or glow particles behind the wave
	var particles = GPUParticles3D.new()
	particles.name = "TrailEffect"
	wave_mesh.add_child(particles)
	
	var particles_material = ParticleProcessMaterial.new()
	particles_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particles_material.emission_box_extents = Vector3(1.5, wave_amplitude, 0.1)
	
	particles_material.direction = Vector3(0, 0, -1)
	particles_material.spread = 30.0
	particles_material.gravity = Vector3(0, 0, 0)
	particles_material.initial_velocity_min = 0.2
	particles_material.initial_velocity_max = 0.5
	particles_material.damping_min = 0.1
	particles_material.damping_max = 0.2
	particles_material.scale_min = 0.02
	particles_material.scale_max = 0.04
	particles_material.color = neon_color
	particles_material.emission_color_texture = null
	
	# Vary the lifetime based on seed
	var lifetime_offset = noise.get_noise_1d(seed_offset) * 0.5 + 1.0
	particles_material.lifetime_randomness = 0.3
	particles.lifetime = 1.0 * lifetime_offset
	particles.amount = 20
	particles.explosiveness = 0.0
	particles.randomness = 0.2
	particles.process_material = particles_material
	
	# Create a simple quad mesh for particles
	var particle_mesh = QuadMesh.new()
	particle_mesh.size = Vector2(0.1, 0.1)
	particles.draw_pass_1 = particle_mesh
	
	# Set particle material
	var particle_material = StandardMaterial3D.new()
	particle_material.flags_transparent = true
	particle_material.flags_unshaded = true
	particle_material.albedo_color = neon_color
	particle_material.emission_enabled = true
	particle_material.emission = neon_color
	particle_material.emission_energy_multiplier = neon_intensity * 0.5
	particle_mesh.material = particle_material

func draw_curve_tube(immediate_mesh: ImmediateMesh, curve: Curve3D, thickness: float, segments: int = 8):
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Get points on the curve
	var points = []
	var point_count = 100
	for i in range(point_count):
		var t = float(i) / (point_count - 1)
		points.append(curve.sample_baked(t * curve.get_baked_length()))
	
	# Generate a tube around the curve
	for i in range(points.size() - 1):
		var current = points[i]
		var next = points[i + 1]
		
		# Calculate direction and perpendicular vectors
		var direction = (next - current).normalized()
		var perpendicular = direction.cross(Vector3.BACK).normalized()
		if perpendicular.length() < 0.1:
			perpendicular = direction.cross(Vector3.UP).normalized()
		
		var circle_points_current = []
		var circle_points_next = []
		
		# Generate circle points around each curve point
		for j in range(segments):
			var angle = j * TAU / segments
			var x = cos(angle) * thickness
			var y = sin(angle) * thickness
			
			var circle_point_current = current + perpendicular * x + direction.cross(perpendicular) * y
			var circle_point_next = next + perpendicular * x + direction.cross(perpendicular) * y
			
			circle_points_current.append(circle_point_current)
			circle_points_next.append(circle_point_next)
		
		# Create triangles between current and next circles
		for j in range(segments):
			var j_next = (j + 1) % segments
			
			# First triangle
			immediate_mesh.surface_set_normal(direction)
			immediate_mesh.surface_add_vertex(circle_points_current[j])
			immediate_mesh.surface_set_normal(direction)
			immediate_mesh.surface_add_vertex(circle_points_next[j])
			immediate_mesh.surface_set_normal(direction)
			immediate_mesh.surface_add_vertex(circle_points_next[j_next])
			
			# Second triangle
			immediate_mesh.surface_set_normal(direction)
			immediate_mesh.surface_add_vertex(circle_points_current[j])
			immediate_mesh.surface_set_normal(direction)
			immediate_mesh.surface_add_vertex(circle_points_next[j_next])
			immediate_mesh.surface_set_normal(direction)
			immediate_mesh.surface_add_vertex(circle_points_current[j_next])
	
	immediate_mesh.surface_end()

func _process(delta):
	if animate:
		time_offset += delta * animation_speed
		
		for wave in waves:
			animate_wave(wave, delta)
		
		# Occasionally add a pulse effect to all materials
		if randf() < 0.01:
			pulse_effect()

func animate_wave(wave: MeshInstance3D, delta: float):
	var seed_offset = wave.get_meta("seed_offset")
	var curve = wave.get_meta("curve")
	var base_pos = wave.get_meta("base_pos")
	
	# Use either synced time or unique time per wave
	var time = time_offset
	if not sync_waves:
		time += seed_offset * 0.1
	
	for i in range(curve.point_count):
		var t = float(i) / wave_segments
		var x = t * 1.5 - 0.75
		
		# Animate the y value over time
		var phase_offset = noise.get_noise_2d(base_pos.x * 10, base_pos.y * 10 + seed_offset)
		
		# More complex wave with multiple frequencies
		var wave_phase = t * TAU * wave_complexity + phase_offset * 10 + time
		var y = sin(wave_phase) * wave_amplitude
		y += sin(wave_phase * 2.7) * wave_amplitude * 0.3
		
		# Add noise-based variation
		y += noise.get_noise_2d(seed_offset, t * 10 + time * 0.5) * variation_amount * wave_amplitude
		
		curve.set_point_position(i, Vector3(x, y, 0))
	
	# Update the mesh
	var immediate_mesh = wave.mesh as ImmediateMesh
	draw_curve_tube(immediate_mesh, curve, neon_thickness)

func pulse_effect():
	# Add a brief pulse of increased brightness to all neon materials
	for material in materials:
		var original_energy = material.emission_energy_multiplier
		
		# Create tween for pulse effect
		var tween = create_tween()
		tween.tween_property(material, "emission_energy_multiplier", original_energy * 1.5, 0.1)
		tween.tween_property(material, "emission_energy_multiplier", original_energy, 0.3)
