extends Node3D

# Ada Research: A Meta-Quest into the World of Algorithms
# Main controller script

# Module settings
@export_category("Module Configuration")
@export var modules_path: String = "res://modules"
@export var use_science_modules: bool = true
@export var queer_factor: float = 0.2

# Grid settings
@export_category("Grid Configuration")
@export var grid_size: Vector3i = Vector3i(8, 1, 8)
@export var cell_size: float = 1.0
@export var generate_on_start: bool = true

# Visualization settings
@export_category("Visualization")
@export var show_entropy: bool = true
@export var entropy_material: Material

@export_category("Environment Settings")
@export var enable_post_processing: bool = true
@export var sky_color_top: Color = Color(0.2, 0.4, 0.8)
@export var sky_color_horizon: Color = Color(0.6, 0.7, 0.9)
@export var ground_color: Color = Color(0.1, 0.1, 0.1)
@export var fog_enabled: bool = true
@export var fog_color: Color = Color(0.5, 0.5, 0.75, 1.0)

@export_category("Grid Visualization")
@export var show_grid: bool = true
@export var grid_divisions: int = 20
@export var grid_color: Color = Color(0.3, 0.3, 0.3, 0.5)

@export_category("Science Decorations")
@export var add_science_props: bool = true
@export var add_particles: bool = true
@export var algorithm_visualization: bool = true

var world_environment: WorldEnvironment
var camera: Camera3D
var grid: MeshInstance3D
var particle_systems = []
var algorithm_visuals = []

# Components
var module_generator: Node
var wave_function_collapse: Node

# Called when the node enters the scene tree for the first time
func _ready():
	if generate_on_start:
		setup()
		generate_world()

# Here's how to correctly set up the Wave Function Collapse script

# In your wave_function_collapse.gd script, make sure you have this property declared:
# @export var modules_folder: String = "res://modules"

# Then in your main script, modify the setup() function like this:
func setup():
	# Create environment
	setup_environment()
	
	# Create module generator
	var generator_scene = load("res://adaresearch/Tests/Scenes/wave_form_c.tscn")
	if generator_scene:
		module_generator = generator_scene.instantiate()
		module_generator.modules_path = modules_path
		#module_generator.generate_on_ready = true
		add_child(module_generator)
	
	# Create WFC algorithm
	var wfc_script = load("res://adaresearch/Tests/Scenes/wave_form_c.gd")
	if wfc_script:
		wave_function_collapse = Node3D.new()
		wave_function_collapse.name = "WaveFunctionCollapse"
		wave_function_collapse.set_script(wfc_script)
		
		# Configure WFC
		wave_function_collapse.grid_size = grid_size
		wave_function_collapse.cell_size = cell_size
		
		# Make sure this property name matches what's in the WFC script
		# Check if it's "modules_folder" or maybe it's "modules_path" in your script
		if wave_function_collapse.has_method("set") and wave_function_collapse.has_method("get"):
			# This is safer as it uses the built-in setter
			wave_function_collapse.set("modules_folder", modules_path)
		else:
			# Let's check what properties are available
			print("Available properties in WFC script:")
			for prop in wave_function_collapse.get_property_list():
				print(prop.name)
			
			# We could try different possible property names
			if "modules_path" in wave_function_collapse:
				wave_function_collapse.modules_path = modules_path
			elif "modules_dir" in wave_function_collapse:
				wave_function_collapse.modules_dir = modules_path
			else:
				# Last resort fallback
				print("WARNING: Could not find appropriate modules folder property in WFC script")
		
		wave_function_collapse.queer_factor = queer_factor
		wave_function_collapse.use_entropy_visualization = show_entropy
		wave_function_collapse.visualization_material = entropy_material
		
		add_child(wave_function_collapse)

# Alternatively, if you know the exact property name in your WFC script,
# just directly change that line to match:

# If the property is called "modules_path" in your WFC script:
# wave_function_collapse.modules_path = modules_path

# Or if it's called "module_path":
# wave_function_collapse.module_path = modules_path
# Generate a new algorithmic world
func generate_world():
	# Wait a moment for module generation to complete
	await get_tree().create_timer(0.5).timeout
	
	if wave_function_collapse:
		# This runs the WFC algorithm
		wave_function_collapse.run_wfc()

func setup_environment():
	# Ground plane
	var ground = MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = PlaneMesh.new()
	#ground.mesh.size = grid_size
	ground.position = Vector3(0, -0.5, 0)
	
	var ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = ground_color
	
	# Add subtle grid pattern to ground
	ground_material.albedo_texture = create_grid_texture(64, 64, Color(0.15, 0.15, 0.15), Color(0.1, 0.1, 0.1))
	ground_material.uv1_scale = Vector3(grid_divisions, grid_divisions, 1.0)
	ground_material.metallic = 0.1
	ground_material.roughness = 0.9
	
	ground.material_override = ground_material
	add_child(ground)
	
	# Main directional light (sun)
	var dir_light = DirectionalLight3D.new()
	dir_light.name = "SunLight"
	dir_light.position = Vector3(0, 10, 0)
	dir_light.rotation_degrees = Vector3(-45, 45, 0)
	dir_light.light_energy = 1.2
	dir_light.shadow_enabled = true
	
	# Add subtle volumetric light
	dir_light.light_volumetric_fog_energy = 0.1
	
	add_child(dir_light)
	
	# Fill light from opposite direction
	var fill_light = DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.position = Vector3(0, 5, 0)
	fill_light.rotation_degrees = Vector3(-35, -75, 0)
	fill_light.light_energy = 0.4
	fill_light.light_color = Color(0.9, 0.85, 0.8)  # Slightly warm fill
	fill_light.shadow_enabled = false
	
	add_child(fill_light)
	
	# Create an environment with ambient light
	world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var env = Environment.new()
	
	# Ambient settings
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.2, 0.2, 0.3)
	env.ambient_light_energy = 1.0
	
	# Post-processing
	if enable_post_processing:
		# SSAO (Screen Space Ambient Occlusion)
		env.ssao_enabled = true
		env.ssao_radius = 1.0
		env.ssao_intensity = 2.0
		env.ssao_power = 1.5
		env.ssao_detail = 0.5
		
		# Screen Space Reflections
		env.ssr_enabled = true
		env.ssr_max_steps = 64
		env.ssr_fade_in = 0.15
		env.ssr_fade_out = 2.0
		env.ssr_depth_tolerance = 0.2
		
		# Glow
		env.glow_enabled = true
		env.glow_normalized = true
		env.glow_intensity = 0.8
		env.glow_bloom = 0.0
		env.glow_hdr_threshold = 0.9
		
		# Adjustments
		env.adjustment_enabled = true
		env.adjustment_brightness = 1.05
		env.adjustment_contrast = 1.1
		env.adjustment_saturation = 1.1
	
	# Fog
	if fog_enabled:
		env.fog_enabled = true
		env.fog_light_color = fog_color
		env.fog_density = 0.001
		env.fog_sun_scatter = 0.2
		env.fog_height = -1.0
		env.fog_height_density = 0.1
	
	# Create a procedural sky
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = sky_color_top
	sky_material.sky_horizon_color = sky_color_horizon
	sky_material.ground_bottom_color = ground_color
	sky_material.ground_horizon_color = sky_color_horizon.darkened(0.2)
	sky_material.sun_angle_max = 30.0
	sky_material.sun_curve = 0.15
	
	env.sky.sky_material = sky_material
	world_environment.environment = env
	
	add_child(world_environment)


func create_grid():
	# Create a grid overlay for better spatial understanding
	grid = MeshInstance3D.new()
	grid.name = "GridOverlay"
	
	var immediate_mesh = ImmediateMesh.new()
	grid.mesh = immediate_mesh
	
	var grid_material = StandardMaterial3D.new()
	grid_material.albedo_color = grid_color
	grid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grid_material.vertex_color_use_as_albedo = true
	
	grid.material_override = grid_material
	
	# Create grid lines
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var half_size_x = grid_size.x / 2
	var half_size_z = grid_size.y / 2
	var step_x = grid_size.x / grid_divisions
	var step_z = grid_size.y / grid_divisions
	
	# Draw lines along X axis
	for i in range(grid_divisions + 1):
		var pos_z = -half_size_z + i * step_z
		immediate_mesh.surface_add_vertex(Vector3(-half_size_x, 0.01, pos_z))
		immediate_mesh.surface_add_vertex(Vector3(half_size_x, 0.01, pos_z))
	
	# Draw lines along Z axis
	for i in range(grid_divisions + 1):
		var pos_x = -half_size_x + i * step_x
		immediate_mesh.surface_add_vertex(Vector3(pos_x, 0.01, -half_size_z))
		immediate_mesh.surface_add_vertex(Vector3(pos_x, 0.01, half_size_z))
	
	immediate_mesh.surface_end()
	
	add_child(grid)

func add_laboratory_props():
	# Add sci-fi laboratory decorations around the boundaries
	
	# Create pedestals at the corners
	var pedestal_positions = [
		Vector3(-grid_size.x/2 + 1, 0, -grid_size.y/2 + 1),
		Vector3(grid_size.x/2 - 1, 0, -grid_size.y/2 + 1),
		Vector3(-grid_size.x/2 + 1, 0, grid_size.y/2 - 1),
		Vector3(grid_size.x/2 - 1, 0, grid_size.y/2 - 1)
	]
	
	for i in range(pedestal_positions.size()):
		var pedestal = MeshInstance3D.new()
		pedestal.name = "Pedestal_" + str(i)
		pedestal.mesh = CylinderMesh.new()
		pedestal.mesh.top_radius = 0.4
		pedestal.mesh.bottom_radius = 0.5
		pedestal.mesh.height = 1.0
		pedestal.position = pedestal_positions[i]
		
		var pedestal_material = StandardMaterial3D.new()
		pedestal_material.albedo_color = Color(0.2, 0.2, 0.2)
		pedestal_material.metallic = 0.7
		pedestal_material.roughness = 0.2
		pedestal.material_override = pedestal_material
		
		add_child(pedestal)
		
		# Add a holographic projection above each pedestal
		var hologram = create_hologram()
		hologram.position = pedestal.position + Vector3(0, 1.5, 0)
		add_child(hologram)
	
	# Add light pillars at midpoints of boundaries
	var pillar_positions = [
		Vector3(0, 0, -grid_size.y/2 + 1),  # North
		Vector3(grid_size.x/2 - 1, 0, 0),   # East
		Vector3(0, 0, grid_size.y/2 - 1),   # South
		Vector3(-grid_size.x/2 + 1, 0, 0)   # West
	]
	
	for i in range(pillar_positions.size()):
		var pillar = MeshInstance3D.new()
		pillar.name = "LightPillar_" + str(i)
		pillar.mesh = CylinderMesh.new()
		pillar.mesh.top_radius = 0.1
		pillar.mesh.bottom_radius = 0.1
		pillar.mesh.height = 4.0
		pillar.position = pillar_positions[i]
		
		var pillar_material = StandardMaterial3D.new()
		pillar_material.albedo_color = Color(0.1, 0.1, 0.1)
		pillar_material.emission_enabled = true
		pillar_material.emission = Color(0.0, 0.5, 1.0)
		pillar_material.emission_energy_multiplier = 2.0
		pillar.material_override = pillar_material
		
		add_child(pillar)
		
		# Add a light at the top of each pillar
		var omni_light = OmniLight3D.new()
		omni_light.name = "PillarLight_" + str(i)
		omni_light.position = pillar_positions[i] + Vector3(0, 2.0, 0)
		omni_light.light_color = Color(0.0, 0.5, 1.0)
		omni_light.light_energy = 0.5
		omni_light.omni_range = 4.0
		
		add_child(omni_light)

func create_hologram() -> Node3D:
	var hologram = Node3D.new()
	hologram.name = "Hologram"
	
	# Create rotating object
	var holo_mesh = MeshInstance3D.new()
	holo_mesh.name = "HologramMesh"
	
	# Randomly choose a mesh type
	var mesh_type = randi() % 4
	match mesh_type:
		0: # Torus
			holo_mesh.mesh = TorusMesh.new()
			holo_mesh.mesh.inner_radius = 0.2
			holo_mesh.mesh.outer_radius = 0.5
		1: # Sphere with noise
			holo_mesh.mesh = SphereMesh.new()
			holo_mesh.mesh.radius = 0.4
			holo_mesh.mesh.height = 0.8
			# In a full implementation, you would add noise displacement here
		2: # Platonic solid
			holo_mesh.mesh = PrismMesh.new()
			holo_mesh.mesh.size = Vector3(0.6, 0.6, 0.6)
		3: # DNA-like spiral
			holo_mesh.mesh = CylinderMesh.new()
			holo_mesh.mesh.top_radius = 0.05
			holo_mesh.mesh.bottom_radius = 0.05
			holo_mesh.mesh.height = 1.0
	
	# Holographic material
	var holo_material = StandardMaterial3D.new()
	holo_material.albedo_color = Color(0.0, 0.8, 1.0, 0.2)
	holo_material.emission_enabled = true
	holo_material.emission = Color(0.0, 0.8, 1.0)
	holo_material.emission_energy_multiplier = 1.5
	holo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	holo_mesh.material_override = holo_material
	
	hologram.add_child(holo_mesh)
	
	# Add spinning animation
	var animation_player = AnimationPlayer.new()
	hologram.add_child(animation_player)
	
	var animation = Animation.new()
	var track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, ".:rotation")
	
	# Add keyframes for rotation
	animation.track_insert_key(track_idx, 0.0, Vector3(0, 0, 0))
	animation.track_insert_key(track_idx, 2.0, Vector3(0, 2 * PI, 0))
	animation.length = 2.0
	animation.loop_mode = Animation.LOOP_LINEAR
	
	var animation_lib = AnimationLibrary.new()
	animation_lib.add_animation("spin", animation)
	animation_player.add_animation_library("", animation_lib)
	
	# Start the animation
	animation_player.play("spin")
	
	return hologram

func create_particle_systems():
	# Add floating particles to give a sense of space and atmosphere
	var particles = GPUParticles3D.new()
	particles.name = "AtmosphericParticles"
	particles.amount = 500
	particles.lifetime = 10.0
	particles.randomness = 1.0
	particles.fixed_fps = 30
	particles.visibility_aabb = AABB(Vector3(-grid_size.x/2, 0, -grid_size.y/2), Vector3(grid_size.x, 5, grid_size.y))
	
	# Create particle material
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particle_material.emission_box_extents = Vector3(grid_size.x/2, 2.5, grid_size.y/2)
	
	# Particle movement
	particle_material.direction = Vector3(0, 0, 0)
	particle_material.spread = 180.0
	particle_material.gravity = Vector3(0, 0.01, 0)
	particle_material.initial_velocity_min = 0.2
	particle_material.initial_velocity_max = 0.5
	particle_material.damping = 0.1
	
	# Particle appearance
	particle_material.color = Color(0.5, 0.7, 1.0, 0.2)
	particle_material.scale_min = 0.05
	particle_material.scale_max = 0.1
	
	particles.process_material = particle_material
	
	# Create mesh for particles
	var particle_mesh = QuadMesh.new()
	particle_mesh.size = Vector2(0.1, 0.1)
	
	var particle_mesh_material = StandardMaterial3D.new()
	particle_mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	particle_mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	particle_mesh_material.vertex_color_use_as_albedo = true
	particle_mesh_material.billboard_mode = StandardMaterial3D.BILLBOARD_ENABLED
	
	particle_mesh.material = particle_mesh_material
	
	particles.draw_pass_1 = particle_mesh
	add_child(particles)
	
	particle_systems.append(particles)

func create_algorithm_visualizations():
	# Create visual representations of algorithms in the scene
	
	# 1. Binary Tree Visualization
	var binary_tree = create_binary_tree(3)
	binary_tree.position = Vector3(-grid_size.x/4, 1.5, -grid_size.y/4)
	add_child(binary_tree)
	algorithm_visuals.append(binary_tree)
	
	# 2. Wave Pattern Visualization
	var wave_pattern = create_wave_pattern()
	wave_pattern.position = Vector3(grid_size.x/4, 1.5, -grid_size.y/4)
	add_child(wave_pattern)
	algorithm_visuals.append(wave_pattern)
	
	# 3. Sorting Algorithm Visualization
	var sorting_visual = create_sorting_visualization()
	sorting_visual.position = Vector3(-grid_size.x/4, 1.5, grid_size.y/4)
	add_child(sorting_visual)
	algorithm_visuals.append(sorting_visual)
	
	# 4. Fractal Pattern
	var fractal = create_fractal_pattern()
	fractal.position = Vector3(grid_size.x/4, 1.5, grid_size.y/4)
	add_child(fractal)
	algorithm_visuals.append(fractal)


func create_wave_pattern() -> Node3D:
	var root = Node3D.new()
	root.name = "WavePattern"
	
	# Create a sine wave visualization
	var wave_mesh = ImmediateMesh.new()
	wave_mesh.clear_surfaces()
	wave_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	var amplitude = 0.5
	var frequency = 3.0
	var resolution = 50
	for i in range(resolution + 1):
		var t = float(i) / resolution
		var x = t * 2.0 - 1.0
		var y = amplitude * sin(frequency * PI * t)
		wave_mesh.surface_add_vertex(Vector3(x, y, 0))
	
	wave_mesh.surface_end()
	
	var wave_instance = MeshInstance3D.new()
	wave_instance.name = "SineWave"
	wave_instance.mesh = wave_mesh
	
	var wave_material = StandardMaterial3D.new()
	wave_material.albedo_color = Color(0.2, 0.8, 0.2)
	wave_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wave_material.line_width = 3.0
	wave_instance.material_override = wave_material
	
	root.add_child(wave_instance)
	
	# Add animated marker moving along the wave
	var marker = MeshInstance3D.new()
	marker.name = "WaveMarker"
	marker.mesh = SphereMesh.new()
	marker.mesh.radius = 0.08
	marker.mesh.height = 0.16
	
	var marker_material = StandardMaterial3D.new()
	marker_material.albedo_color = Color(1.0, 0.3, 0.3)
	marker_material.emission_enabled = true
	marker_material.emission = Color(1.0, 0.3, 0.3)
	marker_material.emission_energy_multiplier = 2.0
	marker.material_override = marker_material
	
	root.add_child(marker)
	
	# Add animation to move marker along the wave
	var animation_player = AnimationPlayer.new()
	root.add_child(animation_player)
	
	var animation = Animation.new()
	var track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, "WaveMarker:position")
	
	# Add keyframes for marker movement
	for i in range(resolution + 1):
		var t = float(i) / resolution
		var time = t * 3.0  # 3 seconds for full animation
		var x = t * 2.0 - 1.0
		var y = amplitude * sin(frequency * PI * t)
		animation.track_insert_key(track_idx, time, Vector3(x, y, 0))
	
	animation.length = 3.0
	animation.loop_mode = Animation.LOOP_LINEAR
	
	var animation_lib = AnimationLibrary.new()
	animation_lib.add_animation("wave_motion", animation)
	animation_player.add_animation_library("", animation_lib)
	
	# Start the animation
	animation_player.play("wave_motion")
	
	return root

func create_sorting_visualization() -> Node3D:
	var root = Node3D.new()
	root.name = "SortingVisualization"
	
	# Create bars of different heights representing data to be sorted
	var num_elements = 10
	var bar_width = 0.15
	var max_height = 1.0
	
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345  # For reproducible results
	
	# Generate random bar heights
	var heights = []
	for i in range(num_elements):
		heights.append(rng.randf_range(0.1, max_height))
	
	# Create visual bars
	for i in range(num_elements):
		var bar = MeshInstance3D.new()
		bar.name = "Bar_" + str(i)
		bar.mesh = BoxMesh.new()
		
		var height = heights[i]
		bar.mesh.size = Vector3(bar_width, height, bar_width)
		
		# Position bars side by side
		var x_pos = (i - num_elements/2.0 + 0.5) * bar_width * 1.2
		bar.position = Vector3(x_pos, height/2, 0)
		
		var bar_material = StandardMaterial3D.new()
		bar_material.albedo_color = Color(0.3, 0.3, 0.9).lerp(Color(0.9, 0.3, 0.3), height/max_height)
		bar_material.metallic = 0.5
		bar_material.roughness = 0.3
		bar.material_override = bar_material
		
		root.add_child(bar)
	
	# Add animation to show sorting (bubble sort visualization)
	var animation_player = AnimationPlayer.new()
	root.add_child(animation_player)
	
	var animation = Animation.new()
	
	# Sort the heights array to determine final positions
	var sorted_heights = heights.duplicate()
	sorted_heights.sort()
	
	# Create animation tracks for each bar
	for i in range(num_elements):
		var track_idx = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track_idx, "Bar_" + str(i) + ":position")
		
		# Initial position
		var start_x = (i - num_elements/2.0 + 0.5) * bar_width * 1.2
		
		# Find final position
		var final_idx = sorted_heights.find(heights[i])
		if heights.count(heights[i]) > 1:
			# Handle duplicate values
			var count_before = 0
			for j in range(i):
				if heights[j] == heights[i]:
					count_before += 1
			final_idx += count_before
		
		var final_x = (final_idx - num_elements/2.0 + 0.5) * bar_width * 1.2
		
		# Add keyframes
		animation.track_insert_key(track_idx, 0.0, Vector3(start_x, heights[i]/2, 0))
		animation.track_insert_key(track_idx, 2.0, Vector3(final_x, heights[i]/2, 0))
	
	animation.length = 4.0
	animation.loop_mode = Animation.LOOP_PINGPONG
	
	var animation_lib = AnimationLibrary.new()
	animation_lib.add_animation("sort", animation)
	animation_player.add_animation_library("", animation_lib)
	
	# Start the animation
	animation_player.play("sort")
	
	return root

# Add these functions to your main script

func create_grid_texture(width: int, height: int, line_color: Color, bg_color: Color) -> ImageTexture:
	# Creates a grid texture for the ground
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	# Fill with background color
	image.fill(bg_color)
	
	# Draw grid lines
	for x in range(0, width, width/8):
		for y in range(height):
			image.set_pixel(x, y, line_color)
	
	for y in range(0, height, height/8):
		for x in range(width):
			image.set_pixel(x, y, line_color)
	
	return ImageTexture.create_from_image(image)
func create_fractal_pattern() -> Node3D:
	var root = Node3D.new()
	root.name = "FractalPattern"
	
	# Create a Sierpinski triangle-like pattern
	var max_depth = 3
	
	# We need to use a reference to allow recursive calling
	var fractal_ref = RefCounted.new()
	fractal_ref.build_func = func(node: Node3D, pos: Vector3, size: float, depth: int):
		if depth >= max_depth:
			return
		
		# Create triangle at current position
		if depth > 0:  # Skip the very first iteration to avoid overlap
			var triangle = MeshInstance3D.new()
			triangle.name = "Triangle_" + str(depth) + "_" + str(pos.x) + "_" + str(pos.z)
			
			# Create a triangle mesh
			var tri_mesh = ImmediateMesh.new()
			tri_mesh.clear_surfaces()
			tri_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			
			tri_mesh.surface_add_vertex(pos)
			tri_mesh.surface_add_vertex(pos + Vector3(size, 0, 0))
			tri_mesh.surface_add_vertex(pos + Vector3(size/2, 0, size * sqrt(3)/2))
			
			tri_mesh.surface_end()
			
			triangle.mesh = tri_mesh
			
			var tri_material = StandardMaterial3D.new()
			tri_material.albedo_color = Color(0.8, 0.4, 0.9)
			tri_material.metallic = 0.5
			tri_material.roughness = 0.3
			triangle.material_override = tri_material
			
			node.add_child(triangle)
		
		# Recursively create 3 smaller triangles
		var new_size = size / 2
		
		# Bottom left
		fractal_ref.build_func.call(node, pos, new_size, depth + 1)
		
		# Bottom right
		fractal_ref.build_func.call(node, pos + Vector3(size/2, 0, 0), new_size, depth + 1)
		
		# Top center
		fractal_ref.build_func.call(node, pos + Vector3(size/4, 0, size * sqrt(3)/4), new_size, depth + 1)
	
	# Start building the fractal
	fractal_ref.build_func.call(root, Vector3(-1, 0, -1), 2.0, 0)
	
	# Add animation for rotation
	var animation_player = AnimationPlayer.new()
	root.add_child(animation_player)
	
	var animation = Animation.new()
	var track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, ".:rotation")
	
	animation.track_insert_key(track_idx, 0.0, Vector3(0, 0, 0))
	animation.track_insert_key(track_idx, 10.0, Vector3(0, 2 * PI, 0))
	animation.length = 10.0
	animation.loop_mode = Animation.LOOP_LINEAR
	
	var animation_lib = AnimationLibrary.new()
	animation_lib.add_animation("rotate", animation)
	animation_player.add_animation_library("", animation_lib)
	
	animation_player.play("rotate")
	
	return root

# Fix for binary_tree function to properly define the closure
func create_binary_tree(depth: int) -> Node3D:
	var root = Node3D.new()
	root.name = "BinaryTree"
	
	# Recursive function to build the tree (using a self-referential closure)
	var build_tree_ref = RefCounted.new()
	build_tree_ref.build_tree_func = func(node: Node3D, current_depth: int, max_depth: int, position: Vector3, branch_width: float):
		if current_depth > max_depth:
			return
		
		# Create node representation
		var sphere = MeshInstance3D.new()
		sphere.name = "Node_" + str(current_depth) + "_" + str(position.x)
		sphere.mesh = SphereMesh.new()
		sphere.mesh.radius = 0.1
		sphere.mesh.height = 0.2
		sphere.position = position
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.8, 0.3, 0.3)
		material.metallic = 0.7
		material.roughness = 0.2
		sphere.material_override = material
		
		node.add_child(sphere)
		
		# Create left branch
		if current_depth < max_depth:
			var left_pos = position + Vector3(-branch_width, -0.5, 0)
			
			# Line connecting to left child
			var left_line = MeshInstance3D.new()
			left_line.name = "LeftBranch_" + str(current_depth)
			
			var line_mesh = ImmediateMesh.new()
			line_mesh.clear_surfaces()
			line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
			line_mesh.surface_add_vertex(position)
			line_mesh.surface_add_vertex(left_pos)
			line_mesh.surface_end()
			
			left_line.mesh = line_mesh
			
			var line_material = StandardMaterial3D.new()
			line_material.albedo_color = Color(0.3, 0.6, 0.9)
			line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			left_line.material_override = line_material
			
			node.add_child(left_line)
			
			# Recursively build left subtree
			build_tree_ref.build_tree_func.call(node, current_depth + 1, max_depth, left_pos, branch_width / 2)
		
		# Create right branch
		if current_depth < max_depth:
			var right_pos = position + Vector3(branch_width, -0.5, 0)
			
			# Line connecting to right child
			var right_line = MeshInstance3D.new()
			right_line.name = "RightBranch_" + str(current_depth)
			
			var line_mesh = ImmediateMesh.new()
			line_mesh.clear_surfaces()
			line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
			line_mesh.surface_add_vertex(position)
			line_mesh.surface_add_vertex(right_pos)
			line_mesh.surface_end()
			
			right_line.mesh = line_mesh
			
			var line_material = StandardMaterial3D.new()
			line_material.albedo_color = Color(0.3, 0.6, 0.9)
			line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			right_line.material_override = line_material
			
			node.add_child(right_line)
			
			# Recursively build right subtree
			build_tree_ref.build_tree_func.call(node, current_depth + 1, max_depth, right_pos, branch_width / 2)
	
	# Start building tree from root
	build_tree_ref.build_tree_func.call(root, 0, depth, Vector3(0, 0, 0), 0.6)
	
	return root


# Function to setup the camera with nice position and animation
func setup_camera():
	camera = Camera3D.new()
	camera.name = "MainCamera"
	camera.position = Vector3(0, 5, 10)
	camera.rotation_degrees = Vector3(-25, 0, 0)
	
	# Set as current camera
	camera.current = true
	
	add_child(camera)
	
	# Add a slight animation to the camera for more dynamic feel
	var animation_player = AnimationPlayer.new()
	camera.add_child(animation_player)
	
	var animation = Animation.new()
	var pos_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(pos_track, ".:position")
	
	var rot_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(rot_track, ".:rotation_degrees")
	
	# Add keyframes for smooth camera movement
	animation.track_insert_key(pos_track, 0.0, Vector3(0, 5, 10))
	animation.track_insert_key(pos_track, 10.0, Vector3(10, 6, 8))
	animation.track_insert_key(pos_track, 20.0, Vector3(8, 7, 0))
	animation.track_insert_key(pos_track, 30.0, Vector3(0, 8, -8))
	animation.track_insert_key(pos_track, 40.0, Vector3(-8, 7, 0))
	animation.track_insert_key(pos_track, 50.0, Vector3(-10, 6, 8))
	animation.track_insert_key(pos_track, 60.0, Vector3(0, 5, 10))
	
	animation.track_insert_key(rot_track, 0.0, Vector3(-25, 0, 0))
	animation.track_insert_key(rot_track, 10.0, Vector3(-30, -45, 0))
	animation.track_insert_key(rot_track, 20.0, Vector3(-35, -90, 0))
	animation.track_insert_key(rot_track, 30.0, Vector3(-30, -180, 0))
	animation.track_insert_key(rot_track, 40.0, Vector3(-35, -270, 0))
	animation.track_insert_key(rot_track, 50.0, Vector3(-30, -315, 0))
	animation.track_insert_key(rot_track, 60.0, Vector3(-25, -360, 0))
	
	animation.length = 60.0
	animation.loop_mode = Animation.LOOP_LINEAR
	
	var animation_lib = AnimationLibrary.new()
	animation_lib.add_animation("orbit", animation)
	animation_player.add_animation_library("", animation_lib)
	
	# Start the camera animation
	animation_player.play("orbit")
