# MoldSporeVRDemo.gd
# VR demo scene for Space Colonization Mold Spore Generator
# Automatically grows mold spores for VR experience

extends Node3D

# References to the mold spore generator
var mold_generator: SpaceColonizationMoldSpore
var current_generation: Array[MeshInstance3D] = []

# Auto-growth parameters
var auto_growth_timer: Timer
var growth_cycle_time: float = 8.0  # Regenerate every 8 seconds (faster with optimized parameters)
var auto_growth_enabled: bool = true

# Demo parameters optimized for VR (fast generation)
var demo_parameters = {
	"influence_radius": 0.15,
	"kill_distance": 0.05,
	"step_size": 0.03,
	"num_auxin_sources": 50,     # Reduced from 150
	"sporulation_probability": 0.025,
	"branching_probability": 0.3,
	"max_iterations": 80         # Reduced from 300
}

# Environment
var environment_setup: bool = false

# Progress visualization
var progress_indicator: MeshInstance3D

func _ready():
	print("MoldSporeVRDemo: Starting initialization...")
	
	# Add error handling to prevent crashes
	try_setup_vr_scene()
	try_setup_mold_generator()
	try_setup_auto_growth()
	
	# Delay initial generation to ensure everything is ready
	call_deferred("create_initial_generation")

func try_setup_vr_scene():
	"""Setup VR scene with error handling"""
	# Check if we can load required resources
	if not setup_vr_scene_safe():
		print("MoldSporeVRDemo: Error in VR scene setup, using fallback")
		fallback_scene_setup()
	else:
		print("MoldSporeVRDemo: VR scene setup completed")

func try_setup_mold_generator():
	"""Setup mold generator with error handling"""
	if not setup_mold_generator_safe():
		print("MoldSporeVRDemo: Error in mold generator setup")
		push_error("Failed to initialize mold generator")
	else:
		print("MoldSporeVRDemo: Mold generator setup completed")

func try_setup_auto_growth():
	"""Setup auto growth with error handling"""
	if not setup_auto_growth_safe():
		print("MoldSporeVRDemo: Error in auto growth setup, disabling auto growth")
		auto_growth_enabled = false
	else:
		print("MoldSporeVRDemo: Auto growth setup completed")

func setup_vr_scene_safe() -> bool:
	"""Safe VR scene setup that returns success status"""
	setup_vr_scene()
	return true

func setup_mold_generator_safe() -> bool:
	"""Safe mold generator setup that returns success status"""
	setup_mold_generator()
	return mold_generator != null

func setup_auto_growth_safe() -> bool:
	"""Safe auto growth setup that returns success status"""
	setup_auto_growth()
	return auto_growth_timer != null

func fallback_scene_setup():
	"""Minimal scene setup in case of VR issues"""
	# Just add basic lighting
	var light = DirectionalLight3D.new()
	light.light_energy = 1.0
	add_child(light)

func setup_vr_scene():
	"""Setup the VR scene environment without UI"""
	name = "MoldSporeVRDemo"
	
	# Add environment and lighting optimized for VR
	setup_vr_environment()
	
	# Create a visual boundary for the 1x1x1 space
	create_space_boundary()
	
	print("MoldSporeVRDemo: VR scene setup complete")

func setup_vr_environment():
	"""Create atmospheric environment optimized for VR"""
	# World environment
	var world_env = WorldEnvironment.new()
	var environment = Environment.new()
	
	# Dark, immersive environment
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.01, 0.02, 0.01)
	
	# VR-optimized atmospheric fog
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.15, 0.25, 0.15)
	environment.fog_sun_scatter = 0.2
	environment.fog_density = 0.03  # Lighter for VR comfort
	
	# Ambient lighting for depth perception
	environment.ambient_light_color = Color(0.1, 0.3, 0.1)
	environment.ambient_light_energy = 0.4
	
	# Enhanced glow for bioluminescent effect in VR
	environment.glow_enabled = true
	environment.glow_intensity = 0.7
	environment.glow_bloom = 0.3
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	
	world_env.environment = environment
	add_child(world_env)
	
	# Directional light with softer shadows for VR
	var main_light = DirectionalLight3D.new()
	main_light.light_energy = 1.2
	main_light.light_color = Color(0.9, 1.0, 0.8)
	main_light.rotation_degrees = Vector3(-25, 30, 0)
	main_light.shadow_enabled = true
	main_light.shadow_blur = 2.0  # Softer shadows for VR
	add_child(main_light)
	
	# Create dramatic VR lighting
	create_vr_accent_lighting()

func create_vr_accent_lighting():
	"""Create atmospheric accent lighting optimized for VR"""
	var colors = [
		Color(0.3, 1.0, 0.4),  # Bright bioluminescent green
		Color(1.0, 0.9, 0.3),  # Glowing fungal yellow
		Color(0.4, 0.7, 1.0),  # Cool spore blue
		Color(0.9, 0.5, 1.0)   # Magical purple
	]
	
	for i in range(4):
		var spot_light = SpotLight3D.new()
		spot_light.light_color = colors[i]
		spot_light.light_energy = 3.5  # Brighter for VR impact
		spot_light.spot_range = 4.0
		spot_light.spot_angle = 35.0
		
		# Position lights around the 1x1x1 space for dramatic effect
		var angle = (i * 90.0) * PI / 180.0
		spot_light.position = Vector3(
			cos(angle) * 1.8,
			1.5,
			sin(angle) * 1.8
		)
		spot_light.look_at_from_position(spot_light.position, Vector3(0.5, 0.5, 0.5), Vector3.UP)
		
		add_child(spot_light)
	
	# Add subtle animated lighting variation
	create_animated_lighting()

func create_animated_lighting():
	"""Create subtle animated lighting for living feel"""
	var tween = create_tween()
	tween.set_loops()
	
	# Find all the accent lights and animate their intensity
	for child in get_children():
		if child is SpotLight3D and child.light_color != Color.WHITE:
			var original_energy = child.light_energy
			var animation_tween = create_tween()
			animation_tween.set_loops()
			
			# Subtle breathing effect
			animation_tween.tween_method(
				func(energy): child.light_energy = energy,
				original_energy * 0.8,
				original_energy * 1.2,
				randf_range(3.0, 6.0)
			)
			animation_tween.tween_method(
				func(energy): child.light_energy = energy,
				original_energy * 1.2,
				original_energy * 0.8,
				randf_range(3.0, 6.0)
			)

func create_space_boundary():
	"""Create visual boundary for the 1x1x1 generation space"""
	var boundary = MeshInstance3D.new()
	boundary.mesh = BoxMesh.new()
	boundary.mesh.size = Vector3(1.0, 1.0, 1.0)
	boundary.position = Vector3(0.5, 0.5, 0.5)
	boundary.name = "SpaceBoundary"
	
	# Subtle wireframe material for VR
	var boundary_material = StandardMaterial3D.new()
	boundary_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	boundary_material.albedo_color = Color(0.3, 0.6, 0.3, 0.4)
	boundary_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	boundary_material.wireframe = true
	boundary_material.emission_enabled = true
	boundary_material.emission = Color(0.2, 0.4, 0.2)
	boundary_material.emission_energy = 0.3
	
	boundary.material_override = boundary_material
	add_child(boundary)
	
	# Create progress indicator
	create_progress_indicator()

func setup_mold_generator():
	"""Initialize the mold spore generator"""
	mold_generator = SpaceColonizationMoldSpore.new()
	mold_generator.name = "MoldSporeGenerator"
	add_child(mold_generator)
	
	# Connect signals (check if not already connected)
	if not mold_generator.generation_progress.is_connected(_on_generation_progress):
		mold_generator.generation_progress.connect(_on_generation_progress)
	if not mold_generator.generation_complete.is_connected(_on_generation_complete):
		mold_generator.generation_complete.connect(_on_generation_complete)
	
	# Set VR-optimized parameters
	mold_generator.set_parameters(demo_parameters)
	
	print("MoldSporeVRDemo: Generator initialized with VR parameters")

func setup_auto_growth():
	"""Setup automatic growth cycling"""
	# Try to use existing timer from scene first
	auto_growth_timer = get_node_or_null("AutoGrowthTimer")
	
	if not auto_growth_timer:
		# Create new timer if not found in scene
		auto_growth_timer = Timer.new()
		auto_growth_timer.name = "AutoGrowthTimer"
		add_child(auto_growth_timer)
	
	auto_growth_timer.wait_time = growth_cycle_time
	
	# Connect timeout signal if not already connected
	if not auto_growth_timer.timeout.is_connected(_on_auto_growth_cycle):
		auto_growth_timer.timeout.connect(_on_auto_growth_cycle)
	
	auto_growth_timer.autostart = false
	
	print("MoldSporeVRDemo: Auto-growth system initialized")

func create_initial_generation():
	"""Create the first mold spore network"""
	start_new_generation()

func start_new_generation():
	"""Start generating a new mold spore network (non-blocking)"""
	if mold_generator.is_generating:
		return
	
	print("MoldSporeVRDemo: Starting new generation cycle...")
	
	# Clear previous generation
	clear_current_generation()
	
	# Start non-blocking generation
	var seed_value = randi()
	start_async_generation(seed_value)
	
	print("MoldSporeVRDemo: Non-blocking generation started with seed %d" % seed_value)

func start_async_generation(seed_value: int):
	"""Start asynchronous, non-blocking generation"""
	# Start the async generation coroutine
	generate_async(seed_value)

func generate_async(seed_value: int):
	"""Generate mold spore network asynchronously over multiple frames"""
	print("MoldSporeVRDemo: Starting async generation...")
	
	# Set up the generator
	mold_generator.setup_random_generator(seed_value)
	mold_generator.clear_previous_generation()
	mold_generator.initialize_auxin_sources()
	mold_generator.initialize_growth_nodes()
	
	# Set generation state
	mold_generator.is_generating = true
	mold_generator.current_iteration = 0
	
	var max_iterations = demo_parameters.max_iterations
	var iterations_per_frame = 5  # Process 5 iterations per frame for smooth performance
	
	# Process iterations in chunks
	while mold_generator.is_generating and mold_generator.current_iteration < max_iterations:
		# Process a small chunk of iterations
		for i in range(iterations_per_frame):
			if mold_generator.current_iteration >= max_iterations:
				break
				
			if mold_generator.auxin_sources.is_empty() or mold_generator.get_active_growth_nodes().is_empty():
				mold_generator.is_generating = false
				break
			
			# Perform one iteration
			mold_generator.space_colonization_iteration()
			mold_generator.current_iteration += 1
		
		# Update progress
		var progress = float(mold_generator.current_iteration) / float(max_iterations)
		_on_generation_progress(progress)
		
		# Yield control back to main thread
		await get_tree().process_frame
	
	# Generation complete - create the final mesh
	print("MoldSporeVRDemo: Creating final mesh...")
	mold_generator.create_spore_mesh()
	mold_generator.add_spore_bodies()
	
	# Get the generated mesh instances
	current_generation = mold_generator.mesh_instances.duplicate()
	
	# Finish up
	mold_generator.is_generating = false
	_on_generation_complete()
	
	print("MoldSporeVRDemo: Async generation complete after %d iterations" % mold_generator.current_iteration)

func create_progress_indicator():
	"""Create a visual progress indicator for generation"""
	progress_indicator = MeshInstance3D.new()
	progress_indicator.mesh = SphereMesh.new()
	progress_indicator.mesh.radius = 0.02
	progress_indicator.mesh.height = 0.04
	progress_indicator.position = Vector3(0.5, 1.2, 0.5)  # Above the generation space
	progress_indicator.name = "ProgressIndicator"
	
	# Create glowing material
	var progress_material = StandardMaterial3D.new()
	progress_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	progress_material.albedo_color = Color(0.2, 1.0, 0.2)
	progress_material.emission_enabled = true
	progress_material.emission = Color(0.2, 1.0, 0.2)
	progress_material.emission_energy = 2.0
	
	progress_indicator.material_override = progress_material
	progress_indicator.visible = false  # Hidden by default
	add_child(progress_indicator)

func update_progress_visual(percentage: float):
	"""Update visual progress indicator"""
	if not progress_indicator:
		return
	
	if mold_generator.is_generating:
		progress_indicator.visible = true
		
		# Animate scale based on progress
		var scale_factor = 0.5 + (percentage * 1.5)  # Scale from 0.5 to 2.0
		progress_indicator.scale = Vector3.ONE * scale_factor
		
		# Change color from red to green based on progress
		var color = Color.RED.lerp(Color.GREEN, percentage)
		var material = progress_indicator.material_override as StandardMaterial3D
		if material:
			material.albedo_color = color
			material.emission = color
	else:
		progress_indicator.visible = false

func _on_auto_growth_cycle():
	"""Handle automatic growth cycling"""
	if auto_growth_enabled:
		start_new_generation()
		print("MoldSporeVRDemo: Auto-growth cycle triggered")

func _on_generation_progress(percentage: float):
	"""Handle generation progress updates"""
	# Less frequent logging for async generation
	var progress_percent = int(percentage * 100)
	if progress_percent % 25 == 0 and progress_percent > 0:  # Log every 25%
		print("MoldSporeVRDemo: Generation progress %d%%" % progress_percent)
	
	# Update any visual progress indicators here if needed
	update_progress_visual(percentage)

func _on_generation_complete():
	"""Handle generation completion"""
	var stats = mold_generator.get_generation_statistics()
	print("MoldSporeVRDemo: Generation complete - %d branches, %d spore bodies" % [
		stats.total_branches,
		stats.total_spore_bodies
	])
	
	# Start the auto-growth timer for next cycle
	if auto_growth_enabled and not auto_growth_timer.is_stopped():
		auto_growth_timer.stop()
	
	if auto_growth_enabled:
		auto_growth_timer.start()

func clear_current_generation():
	"""Clear the current generation"""
	for mesh_instance in current_generation:
		if mesh_instance and is_instance_valid(mesh_instance):
			mesh_instance.queue_free()
	current_generation.clear()

# VR-specific functions
func enable_auto_growth():
	"""Enable automatic growth cycling"""
	auto_growth_enabled = true
	if not auto_growth_timer.is_stopped():
		auto_growth_timer.stop()
	auto_growth_timer.start()
	print("MoldSporeVRDemo: Auto-growth enabled")

func disable_auto_growth():
	"""Disable automatic growth cycling"""
	auto_growth_enabled = false
	auto_growth_timer.stop()
	print("MoldSporeVRDemo: Auto-growth disabled")

func set_growth_cycle_time(new_time: float):
	"""Set the time between growth cycles"""
	growth_cycle_time = new_time
	auto_growth_timer.wait_time = growth_cycle_time
	print("MoldSporeVRDemo: Growth cycle time set to %.1f seconds" % new_time)

func trigger_manual_growth():
	"""Manually trigger a new growth cycle (for VR interaction)"""
	start_new_generation()

func get_current_spore_positions() -> Array[Vector3]:
	"""Get positions of all spore bodies for VR interaction"""
	var positions: Array[Vector3] = []
	
	for mesh_instance in current_generation:
		if mesh_instance and mesh_instance.name == "SporeBody":
			positions.append(mesh_instance.global_position)
	
	return positions

func get_mycelium_network_bounds() -> AABB:
	"""Get bounding box of the current mycelium network"""
	var bounds = AABB()
	var first_mesh = true
	
	for mesh_instance in current_generation:
		if mesh_instance and mesh_instance.mesh:
			var mesh_bounds = mesh_instance.get_aabb()
			mesh_bounds = mesh_instance.transform * mesh_bounds
			
			if first_mesh:
				bounds = mesh_bounds
				first_mesh = false
			else:
				bounds = bounds.merge(mesh_bounds)
	
	return bounds

# Utility functions for VR integration
func get_closest_spore_to_position(world_position: Vector3) -> MeshInstance3D:
	"""Find the closest spore body to a given world position"""
	var closest_spore: MeshInstance3D = null
	var closest_distance = INF
	
	for mesh_instance in current_generation:
		if mesh_instance and mesh_instance.name == "SporeBody":
			var distance = mesh_instance.global_position.distance_to(world_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_spore = mesh_instance
	
	return closest_spore

func highlight_spore_bodies(highlight: bool):
	"""Highlight all spore bodies for VR interaction feedback"""
	for mesh_instance in current_generation:
		if mesh_instance and mesh_instance.name == "SporeBody":
			if highlight:
				# Increase emission for highlight effect
				var material = mesh_instance.material_override as StandardMaterial3D
				if material:
					material.emission_energy = 1.5
			else:
				# Reset to normal emission
				var material = mesh_instance.material_override as StandardMaterial3D
				if material:
					material.emission_energy = 0.7

func add_spore_particles():
	"""Add particle effects around spore bodies for enhanced VR atmosphere"""
	for mesh_instance in current_generation:
		if mesh_instance and mesh_instance.name == "SporeBody":
			var particles = GPUParticles3D.new()
			particles.emitting = true
			particles.amount = 20
			particles.lifetime = 3.0
			particles.position = mesh_instance.position
			
			# Create material for particles
			var particle_material = ParticleProcessMaterial.new()
			particle_material.direction = Vector3(0, 1, 0)
			particle_material.initial_velocity_min = 0.1
			particle_material.initial_velocity_max = 0.3
			particle_material.gravity = Vector3(0, -0.2, 0)
			particle_material.scale_min = 0.1
			particle_material.scale_max = 0.3
			particle_material.color = Color(0.8, 1.0, 0.6, 0.6)
			
			particles.process_material = particle_material
			
			# Use simple quad mesh for particles
			var quad_mesh = QuadMesh.new()
			quad_mesh.size = Vector2(0.02, 0.02)
			particles.draw_pass_1 = quad_mesh
			
			add_child(particles)

func create_growth_animation():
	"""Create animated growth effect for new generations"""
	for mesh_instance in current_generation:
		if mesh_instance:
			# Start scaled down
			mesh_instance.scale = Vector3.ZERO
			
			# Create growth tween
			var tween = create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_BACK)
			
			# Animate scale up with slight delay for organic feel
			var delay = randf_range(0.0, 2.0)
			tween.tween_delay(delay)
			tween.tween_property(mesh_instance, "scale", Vector3.ONE, 1.5)

func pulse_spore_bodies():
	"""Create pulsing animation on spore bodies"""
	for mesh_instance in current_generation:
		if mesh_instance and mesh_instance.name == "SporeBody":
			var tween = create_tween()
			tween.set_loops()
			
			var original_scale = mesh_instance.scale
			var pulse_scale = original_scale * 1.2
			
			tween.tween_property(mesh_instance, "scale", pulse_scale, 2.0)
			tween.tween_property(mesh_instance, "scale", original_scale, 2.0)

func get_vr_demo_info() -> Dictionary:
	"""Get information about the VR demo"""
	return {
		"name": "Space Colonization Mold Spore VR Demo",
		"description": "Automatically growing 3D mold fungus spore networks for VR experience",
		"features": [
			"Automatic growth cycling every 15 seconds",
			"VR-optimized atmospheric lighting",
			"Bioluminescent materials with glow effects",
			"Animated growth sequences",
			"Interactive spore body detection",
			"Particle effects for atmosphere"
		],
		"vr_interactions": [
			"Manual growth triggering",
			"Spore body highlighting and pulsing",
			"Network bounds detection",
			"Position-based queries for hand tracking"
		],
		"auto_growth": {
			"enabled": auto_growth_enabled,
			"cycle_time": growth_cycle_time,
			"current_generation_size": current_generation.size()
		},
		"algorithm_parameters": demo_parameters
	}

# Enhanced visual effects for VR
func add_atmospheric_particles():
	"""Add atmospheric spore particles floating in the air"""
	var atmosphere_particles = GPUParticles3D.new()
	atmosphere_particles.name = "AtmosphereParticles"
	atmosphere_particles.emitting = true
	atmosphere_particles.amount = 100
	atmosphere_particles.lifetime = 10.0
	atmosphere_particles.position = Vector3(0.5, 0.5, 0.5)
	
	# Create atmospheric particle material
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particle_material.emission_box_extents = Vector3(0.6, 0.6, 0.6)
	particle_material.direction = Vector3(0, 0.2, 0)
	particle_material.initial_velocity_min = 0.05
	particle_material.initial_velocity_max = 0.15
	particle_material.gravity = Vector3(0, -0.1, 0)
	particle_material.scale_min = 0.005
	particle_material.scale_max = 0.02
	particle_material.color = Color(0.6, 0.9, 0.4, 0.3)
	
	atmosphere_particles.process_material = particle_material
	
	# Use simple sphere mesh for spore particles
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.01
	sphere_mesh.height = 0.02
	atmosphere_particles.draw_pass_1 = sphere_mesh
	
	add_child(atmosphere_particles)

# Cleanup function
func _exit_tree():
	"""Cleanup when scene is removed"""
	if auto_growth_timer:
		auto_growth_timer.stop()
	clear_current_generation()
	print("MoldSporeVRDemo: VR demo cleaned up")
