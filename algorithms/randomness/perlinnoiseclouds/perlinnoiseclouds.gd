extends Node3D

# VR Performance Settings
enum VRQuality { HIGH, BALANCED, PERFORMANCE }
@export var vr_quality: VRQuality = VRQuality.BALANCED
@export var enable_adaptive_quality: bool = true
@export var target_fps: float = 90.0  # VR target framerate
@export var max_frame_time: float = 11.0  # milliseconds

# Cloud generation parameters (VR-optimized defaults)
@export var cloud_size: Vector3 = Vector3(50, 20, 50)
@export var cloud_density: float = 0.3
@export var noise_scale: float = 0.05
@export var cloud_layers: int = 2  # Reduced for VR
@export var animation_speed: float = 0.5
@export var fade_distance: float = 80.0  # Reduced for VR

# Dynamic quality parameters
var particle_count: int = 2000  # Will be adjusted based on VR quality
var current_lod_level: int = 0
var performance_counter: int = 0
var frame_time_accumulator: float = 0.0

# Culling and batching
@export var frustum_culling: bool = true
@export var use_instancing: bool = true
@export var batch_size: int = 100  # Process clouds in batches
var current_batch_index: int = 0

# Internal variables
var noise: FastNoiseLite
var cloud_particles: Array[CloudParticle] = []
var active_particles: Array[CloudParticle] = []
var time_offset: float = 0.0
var cloud_container: Node3D
var cloud_material: StandardMaterial3D
var cloud_mesh: SphereMesh

# VR-specific optimizations
var camera_position: Vector3
var camera_frustum: Array[Plane] = []
var multimesh_instance: MultiMeshInstance3D
var multimesh: MultiMesh

# Custom cloud particle class for better memory management
class CloudParticle:
	var position: Vector3
	var scale: float
	var opacity: float
	var velocity: Vector3
	var active: bool = true
	var last_noise_value: float
	var distance_to_camera: float
	
	func _init(pos: Vector3, s: float, op: float):
		position = pos
		scale = s
		opacity = op
		velocity = Vector3.ZERO

func _ready():
	# Set quality-based parameters
	setup_vr_quality()
	
	# Initialize noise generator
	setup_noise()
	
	# Get references
	cloud_container = $CloudContainer
	
	# Create VR-optimized cloud material first
	setup_vr_cloud_material()
	
	# Create cloud mesh (low-poly for VR)
	setup_vr_cloud_mesh()
	
	# Create optimized cloud rendering (after material and mesh)
	setup_multimesh_rendering()
	
	# Generate initial cloud field
	generate_cloud_field()
	
	# Start adaptive quality monitoring if enabled
	if enable_adaptive_quality:
		set_process(true)

func setup_vr_quality():
	match vr_quality:
		VRQuality.HIGH:
			particle_count = 3000
			cloud_layers = 3
			fade_distance = 100.0
			batch_size = 150
		VRQuality.BALANCED:
			particle_count = 2000
			cloud_layers = 2
			fade_distance = 80.0
			batch_size = 100
		VRQuality.PERFORMANCE:
			particle_count = 1000
			cloud_layers = 1
			fade_distance = 60.0
			batch_size = 50

func setup_noise():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = noise_scale
	noise.fractal_octaves = cloud_layers
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.seed = randi()

func setup_multimesh_rendering():
	# Use MultiMesh for efficient instanced rendering in VR
	if use_instancing:
		multimesh_instance = MultiMeshInstance3D.new()
		multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.instance_count = particle_count
		multimesh.use_colors = true  # Enable per-instance colors
		
		# Set the mesh if it's already created
		if cloud_mesh:
			multimesh.mesh = cloud_mesh
		
		multimesh_instance.multimesh = multimesh
		
		# Apply material to the MultiMeshInstance3D (not the MultiMesh)
		if cloud_material:
			multimesh_instance.material_override = cloud_material
		
		cloud_container.add_child(multimesh_instance)

func setup_vr_cloud_material():
	cloud_material = StandardMaterial3D.new()
	
	# VR-optimized material settings
	cloud_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud_material.albedo_color = Color(1.0, 1.0, 1.0, 0.12)  # Slightly lower alpha for VR
	cloud_material.emission_enabled = true
	cloud_material.emission = Color(0.8, 0.9, 1.0)
	cloud_material.emission_energy = 0.08
	cloud_material.no_depth_test = false  # Enable depth test for VR
	cloud_material.cull_mode = BaseMaterial3D.CULL_BACK  # Enable culling for performance
	cloud_material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED  # Disable billboard for VR immersion
	
	# VR performance flags
	cloud_material.flags_unshaded = false
	cloud_material.flags_vertex_lighting = true  # Use vertex lighting for performance
	cloud_material.flags_use_point_size = false

func setup_vr_cloud_mesh():
	cloud_mesh = SphereMesh.new()
	cloud_mesh.radius = 1.0
	cloud_mesh.height = 2.0
	cloud_mesh.radial_segments = 4  # Reduced polygon count for VR
	cloud_mesh.rings = 3  # Reduced polygon count for VR
	
	if use_instancing and multimesh:
		multimesh.mesh = cloud_mesh

func generate_cloud_field():
	# Clear existing particles
	cloud_particles.clear()
	active_particles.clear()
	
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
			var particle = create_cloud_particle(pos, noise_value)
			cloud_particles.append(particle)
			active_particles.append(particle)
	
	# Update MultiMesh if using instancing
	if use_instancing:
		update_multimesh()

func get_3d_noise(pos: Vector3) -> float:
	# Optimized noise sampling for VR
	var value = 0.0
	var amplitude = 1.0
	var frequency = noise_scale
	
	# Use fewer octaves for VR performance
	for i in range(cloud_layers):
		value += noise.get_noise_3d(
			pos.x * frequency + time_offset,
			pos.y * frequency,
			pos.z * frequency + time_offset * 0.7
		) * amplitude
		
		amplitude *= 0.5
		frequency *= 2.0
	
	return (value + 1.0) * 0.5

func create_cloud_particle(pos: Vector3, noise_value: float) -> CloudParticle:
	var opacity = noise_value * 0.25 + 0.05  # Reduced opacity for VR
	var scale = noise_value * 1.5 + 0.5  # Slightly smaller for VR
	
	return CloudParticle.new(pos, scale, opacity)

func _process(delta):
	time_offset += delta * animation_speed
	
	# Update camera info for VR optimization
	update_camera_info()
	
	# Animate clouds in batches for VR performance
	animate_clouds_batched(delta)
	
	# Update MultiMesh rendering
	if use_instancing:
		update_multimesh()
	
	# Adaptive quality management
	if enable_adaptive_quality:
		monitor_performance(delta)
	
	# Periodically regenerate some clouds
	if randf() < 0.0005:  # Reduced frequency for VR
		regenerate_random_clouds()

func update_camera_info():
	var camera = get_viewport().get_camera_3d()
	if camera:
		camera_position = camera.global_position
		
		# Update frustum for culling (VR optimization)
		if frustum_culling:
			camera_frustum = camera.get_frustum()

func animate_clouds_batched(delta):
	# Process clouds in batches to spread load across frames
	var batch_start = current_batch_index
	var batch_end = min(current_batch_index + batch_size, active_particles.size())
	
	for i in range(batch_start, batch_end):
		if i >= active_particles.size():
			break
			
		var particle = active_particles[i]
		animate_single_particle(particle, delta)
	
	# Move to next batch
	if active_particles.size() > 0:
		current_batch_index = (current_batch_index + batch_size) % active_particles.size()
	else:
		current_batch_index = 0  # or handle the empty case appropriately
		
func animate_single_particle(particle: CloudParticle, delta):
	# Sample noise for movement (cached for performance)
	var noise_x = noise.get_noise_2d(particle.position.x * 0.01, time_offset * 2.0) * 1.5
	var noise_z = noise.get_noise_2d(particle.position.z * 0.01, time_offset * 2.0) * 1.5
	
	# Apply gentle movement
	particle.position.x += noise_x * delta
	particle.position.z += noise_z * delta
	
	# Vertical drift
	particle.position.y += delta * 0.4
	if particle.position.y > cloud_size.y:
		particle.position.y = 0.0
	
	# Update distance to camera for LOD
	particle.distance_to_camera = particle.position.distance_to(camera_position)
	
	# Frustum culling
	if frustum_culling and not is_in_frustum(particle.position):
		particle.active = false
		return
	
	particle.active = true
	
	# Update opacity based on distance (VR fade optimization)
	var fade_factor = 1.0 - clamp(particle.distance_to_camera / fade_distance, 0.0, 1.0)
	particle.opacity = (particle.last_noise_value * 0.25 + 0.05) * fade_factor
	
	# LOD scaling based on distance
	var lod_scale = 1.0
	if particle.distance_to_camera > fade_distance * 0.5:
		lod_scale = 0.5
	particle.scale = (particle.last_noise_value * 1.5 + 0.5) * lod_scale

func is_in_frustum(pos: Vector3) -> bool:
	# Simple frustum culling check
	for plane in camera_frustum:
		if plane.distance_to(pos) > 2.0:  # 2.0 is margin for cloud size
			return false
	return true

func update_multimesh():
	if not use_instancing or not multimesh:
		return
	
	var visible_count = 0
	
	# Update transforms for visible particles only
	for i in range(active_particles.size()):
		var particle = active_particles[i]
		
		if not particle.active or particle.opacity < 0.01:
			continue
		
		if visible_count >= particle_count:
			break
		
		var transform = Transform3D()
		transform.origin = particle.position
		transform.basis = transform.basis.scaled(Vector3.ONE * particle.scale)
		
		multimesh.set_instance_transform(visible_count, transform)
		
		# Set per-instance color for opacity
		var color = Color(1.0, 1.0, 1.0, particle.opacity)
		multimesh.set_instance_color(visible_count, color)
		
		visible_count += 1
	
	# Hide unused instances
	for i in range(visible_count, particle_count):
		multimesh.set_instance_color(i, Color.TRANSPARENT)

func monitor_performance(delta):
	frame_time_accumulator += delta * 1000.0  # Convert to milliseconds
	performance_counter += 1
	
	# Check performance every 60 frames
	if performance_counter >= 60:
		var avg_frame_time = frame_time_accumulator / 60.0
		
		# Adaptive quality adjustment
		if avg_frame_time > max_frame_time:
			# Performance is poor, reduce quality
			reduce_quality()
		elif avg_frame_time < max_frame_time * 0.7:
			# Performance is good, can increase quality
			increase_quality()
		
		frame_time_accumulator = 0.0
		performance_counter = 0

func reduce_quality():
	if current_lod_level < 2:
		current_lod_level += 1
		match current_lod_level:
			1:
				batch_size = max(50, batch_size - 25)
				fade_distance *= 0.8
			2:
				particle_count = max(500, int(particle_count * 0.7))
				cloud_layers = max(1, cloud_layers - 1)
				regenerate_clouds()

func increase_quality():
	if current_lod_level > 0:
		current_lod_level -= 1
		match current_lod_level:
			1:
				batch_size = min(150, batch_size + 25)
				fade_distance *= 1.2
			0:
				setup_vr_quality()  # Reset to original quality
				regenerate_clouds()

func regenerate_random_clouds():
	# VR-optimized regeneration
	var count_to_regen = min(25, cloud_particles.size() / 20.0)  # Reduced for VR
	
	for i in range(count_to_regen):
		var idx = randi() % cloud_particles.size()
		var particle = cloud_particles[idx]
		
		var new_pos = Vector3(
			randf_range(-cloud_size.x * 0.5, cloud_size.x * 0.5),
			randf_range(0, cloud_size.y),
			randf_range(-cloud_size.z * 0.5, cloud_size.z * 0.5)
		)
		
		var new_noise = get_3d_noise(new_pos)
		if new_noise > (1.0 - cloud_density):
			particle.position = new_pos
			particle.last_noise_value = new_noise
			particle.scale = new_noise * 1.5 + 0.5
			particle.opacity = new_noise * 0.25 + 0.05

# Public functions for runtime adjustment
func set_vr_quality(quality: VRQuality):
	vr_quality = quality
	setup_vr_quality()
	regenerate_clouds()

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

func toggle_adaptive_quality(enabled: bool):
	enable_adaptive_quality = enabled
	if not enabled:
		current_lod_level = 0
		setup_vr_quality()

# VR-specific public functions
func get_performance_stats() -> Dictionary:
	return {
		"active_particles": active_particles.size(),
		"lod_level": current_lod_level,
		"batch_size": batch_size,
		"fade_distance": fade_distance
	}

func force_quality_level(level: int):
	current_lod_level = clamp(level, 0, 2)
	if level == 0:
		setup_vr_quality()
	else:
		for i in range(level):
			reduce_quality()
