extends Node3D

# Cloud generation parameters
@export var cloud_size: Vector3 = Vector3(50, 20, 50)  # Overall cloud field size
@export var cloud_density: float = 0.3  # How dense the clouds are (0-1)
@export var noise_scale: float = 0.05  # Scale of the noise pattern
@export var cloud_layers: int = 3  # Number of noise octaves
@export var animation_speed: float = 0.5  # How fast clouds move
@export var particle_count: int = 5000  # Total number of cloud particles
@export var fade_distance: float = 100.0  # Distance at which clouds fade

# Internal variables
var noise: FastNoiseLite
var cloud_particles: Array[MeshInstance3D] = []
var time_offset: float = 0.0
var cloud_container: Node3D
var cloud_material: StandardMaterial3D
var cloud_mesh: SphereMesh

func _ready():
	# Initialize noise generator
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = noise_scale
	noise.fractal_octaves = cloud_layers
	noise.seed = randi()
	
	# Get references
	cloud_container = $CloudContainer
	
	# Create cloud material
	setup_cloud_material()
	
	# Create cloud mesh
	setup_cloud_mesh()
	
	# Generate initial cloud field
	generate_cloud_field()

func setup_cloud_material():
	cloud_material = StandardMaterial3D.new()
	cloud_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud_material.albedo_color = Color(1.0, 1.0, 1.0, 0.15)
	cloud_material.emission_enabled = true
	cloud_material.emission = Color(0.8, 0.9, 1.0)
	cloud_material.emission_energy = 0.1
	cloud_material.no_depth_test = true
	cloud_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	cloud_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED

func setup_cloud_mesh():
	cloud_mesh = SphereMesh.new()
	cloud_mesh.radius = 1.0
	cloud_mesh.height = 2.0
	cloud_mesh.radial_segments = 6
	cloud_mesh.rings = 4

func generate_cloud_field():
	# Clear existing particles
	for particle in cloud_particles:
		if is_instance_valid(particle):
			particle.queue_free()
	cloud_particles.clear()
	
	# Generate cloud particles using 3D Perlin noise
	for i in range(particle_count):
		var pos = Vector3(
			randf_range(-cloud_size.x * 0.5, cloud_size.x * 0.5),
			randf_range(0, cloud_size.y),
			randf_range(-cloud_size.z * 0.5, cloud_size.z * 0.5)
		)
		
		# Sample 3D noise at this position
		var noise_value = get_3d_noise(pos)
		
		# Only place cloud particles where noise exceeds threshold
		if noise_value > (1.0 - cloud_density):
			create_cloud_particle(pos, noise_value)

func get_3d_noise(pos: Vector3) -> float:
	# Sample multiple noise layers for more complex cloud shapes
	var value = 0.0
	var amplitude = 1.0
	var frequency = noise_scale
	
	for i in range(cloud_layers):
		value += noise.get_noise_3d(
			pos.x * frequency + time_offset,
			pos.y * frequency,
			pos.z * frequency + time_offset * 0.7
		) * amplitude
		
		amplitude *= 0.5
		frequency *= 2.0
	
	# Normalize to 0-1 range
	return (value + 1.0) * 0.5

func create_cloud_particle(pos: Vector3, noise_value: float):
	var particle = MeshInstance3D.new()
	particle.mesh = cloud_mesh
	particle.position = pos
	
	# Create unique material instance for this particle
	var material = cloud_material.duplicate()
	
	# Vary opacity and size based on noise value
	var opacity = noise_value * 0.3 + 0.05
	material.albedo_color.a = opacity
	
	# Vary emission based on height (higher clouds are brighter)
	var height_factor = (pos.y / cloud_size.y)
	material.emission_energy = 0.05 + height_factor * 0.15
	
	# Scale particle based on noise intensity
	var scale = noise_value * 2.0 + 0.5
	particle.scale = Vector3.ONE * scale
	
	particle.material_override = material
	cloud_container.add_child(particle)
	cloud_particles.append(particle)

func _process(delta):
	time_offset += delta * animation_speed
	
	# Animate existing cloud particles
	animate_clouds(delta)
	
	# Periodically regenerate some clouds for variation
	if randf() < 0.001:  # Small chance each frame
		regenerate_random_clouds()

func animate_clouds(delta):
	for particle in cloud_particles:
		if not is_instance_valid(particle):
			continue
			
		var pos = particle.position
		
		# Sample noise for movement
		var noise_x = noise.get_noise_3d(pos.x * 0.01, pos.y * 0.01, time_offset * 2.0) * 2.0
		var noise_z = noise.get_noise_3d(pos.x * 0.01 + 100, pos.y * 0.01 + 100, time_offset * 2.0) * 2.0
		
		# Apply gentle movement
		particle.position.x += noise_x * delta
		particle.position.z += noise_z * delta
		
		# Slowly drift upward and cycle
		particle.position.y += delta * 0.5
		if particle.position.y > cloud_size.y:
			particle.position.y = 0.0
		
		# Update opacity based on current 3D noise
		var current_noise = get_3d_noise(particle.position)
		if particle.material_override:
			var material = particle.material_override as StandardMaterial3D
			material.albedo_color.a = current_noise * 0.3 + 0.05
			
			# Fade based on distance to camera (VR optimization)
			var camera = get_viewport().get_camera_3d()
			if camera:
				var distance = particle.position.distance_to(camera.global_position)
				var fade_factor = 1.0 - clamp(distance / fade_distance, 0.0, 1.0)
				material.albedo_color.a *= fade_factor

func regenerate_random_clouds():
	# Regenerate a small portion of clouds for dynamic feel
	var count_to_regen = min(50, cloud_particles.size() / 10)
	
	for i in range(count_to_regen):
		var idx = randi() % cloud_particles.size()
		var particle = cloud_particles[idx]
		
		if is_instance_valid(particle):
			# Move to new random position
			var new_pos = Vector3(
				randf_range(-cloud_size.x * 0.5, cloud_size.x * 0.5),
				randf_range(0, cloud_size.y),
				randf_range(-cloud_size.z * 0.5, cloud_size.z * 0.5)
			)
			
			var new_noise = get_3d_noise(new_pos)
			if new_noise > (1.0 - cloud_density):
				particle.position = new_pos
				if particle.material_override:
					var material = particle.material_override as StandardMaterial3D
					material.albedo_color.a = new_noise * 0.3 + 0.05

# Public functions for runtime adjustment
func set_cloud_density(value: float):
	cloud_density = clamp(value, 0.0, 1.0)
	generate_cloud_field()

func set_animation_speed(value: float):
	animation_speed = value

func set_noise_scale(value: float):
	noise_scale = value
	noise.frequency = value
	generate_cloud_field()

func regenerate_clouds():
	noise.seed = randi()
	generate_cloud_field()
