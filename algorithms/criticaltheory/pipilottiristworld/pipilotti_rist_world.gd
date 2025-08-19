extends Node3D
class_name PipilottiRistWorld

# Visual settings
@export_category("Visual Settings")
@export var saturation_amount: float = 1.5
@export var color_shift_speed: float = 0.2
@export var projection_intensity: float = 1.2
@export var use_post_processing: bool = true

# Environment settings
@export_category("Environment")
@export var fog_color: Color = Color(0.8, 0.2, 0.5, 1.0)
@export var ambient_light_color: Color = Color(0.1, 0.3, 0.6, 1.0)
@export var sky_color: Color = Color(0.9, 0.6, 0.8, 1.0)

# Projection settings
@export_category("Projection Content")
@export var video_paths: Array[String] = []
@export var image_paths: Array[String] = []
@export var projection_scale: float = 1.0
@export var projection_overlap: bool = true

# Animation settings
@export_category("Animation")
@export var pulsating_speed: float = 0.5
@export var floating_objects_speed: float = 0.3
@export var rotation_speed: float = 0.1

# References to nodes
var world_environment: WorldEnvironment
var projection_surfaces = []
var floating_objects = []
var video_players = []
var projection_viewports = []
var post_processing_material: ShaderMaterial

# Animation variables
var time: float = 0.0

func _ready():
	# Create the basic environment
	setup_environment()
	
	# Create projection surfaces
	create_projection_surfaces()
	
	# Create floating objects
	create_floating_objects()
	
	# Setup post-processing
	if use_post_processing:
		setup_post_processing()
	
	# Start video playback
	start_video_projections()

func _process(delta):
	time += delta
	
	# Animate color shifts
	animate_colors(delta)
	
	# Animate floating objects
	animate_floating_objects(delta)
	
	# Update post-processing effects
	if use_post_processing and post_processing_material:
		post_processing_material.set_shader_parameter("time", time)

func setup_environment():
	# Create a world environment for the surreal atmosphere
	world_environment = WorldEnvironment.new()
	var environment = Environment.new()
	
	# Sky settings
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = sky_color
	
	# Fog settings
	environment.fog_enabled = true
	#environment.fog_color = fog_color
	#environment.fog_sun_color = Color(1.0, 0.7, 0.8)
	environment.fog_density = 0.02
	
	# Ambient light
	environment.ambient_light_color = ambient_light_color
	environment.ambient_light_energy = 1.5
	
	# Glow effect
	environment.glow_enabled = true
	environment.glow_intensity = 0.8
	environment.glow_bloom = 0.5
	environment.glow_hdr_threshold = 0.7
	
	# Assign the environment
	world_environment.environment = environment
	add_child(world_environment)
	
	# Create a base light
	var directional_light = DirectionalLight3D.new()
	directional_light.light_color = Color(1.0, 0.9, 0.8)
	directional_light.light_energy = 0.8
	directional_light.rotation_degrees = Vector3(-45, 45, 0)
	add_child(directional_light)

func create_projection_surfaces():
	# Create various surfaces for projections
	
	# 1. Large curved screen
	var curved_screen = create_curved_projection_surface(
		Vector3(0, 2, -5),  # Position
		Vector2(10, 5),     # Size
		180,                # Arc degrees
		12                  # Segments
	)
	projection_surfaces.append(curved_screen)
	
	# 2. Floor projection
	var floor_projection = create_flat_projection_surface(
		Vector3(0, 0.01, 0),  # Position (slightly above ground to avoid z-fighting)
		Vector2(10, 10),      # Size
		Vector3(-90, 0, 0)    # Rotation (flat on floor)
	)
	projection_surfaces.append(floor_projection)
	
	# 3. Floating transparent screens
	for i in range(5):
		var angle = i * (360.0 / 5.0)
		var pos = Vector3(cos(deg_to_rad(angle)) * 3, 1.5 + sin(time * 0.2 + i) * 0.5, sin(deg_to_rad(angle)) * 3)
		var rot = Vector3(0, angle, 0)
		
		var floating_screen = create_flat_projection_surface(
			pos,
			Vector2(2, 3),
			rot
		)
		
		# Make it transparent
		var mesh_instance = floating_screen.get_child(0) as MeshInstance3D
		if mesh_instance and mesh_instance.material_override:
			mesh_instance.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh_instance.material_override.albedo_color.a = 0.7
		
		projection_surfaces.append(floating_screen)
	
	# 4. Dome ceiling projection
	var dome = create_dome_projection_surface(
		Vector3(0, 5, 0),  # Position
		3.0,              # Radius
		16,               # Rings
		32                # Segments
	)
	projection_surfaces.append(dome)

func create_curved_projection_surface(position: Vector3, size: Vector2, arc_degrees: float, segments: int) -> Node3D:
	var surface = Node3D.new()
	surface.position = position
	
	var mesh_instance = MeshInstance3D.new()
	var material = StandardMaterial3D.new()
	material.roughness = 0.2
	material.metallic = 0.0
	material.emission_enabled = true
	material.emission_energy = 0.5
	
	# Create curved surface mesh
	var mesh = ImmediateMesh.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	
	var arc_radians = deg_to_rad(arc_degrees)
	var radius = (size.x / 2.0) / sin(arc_radians / 2.0)
	var height = size.y
	
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(segments + 1):
		var angle_percent = float(i) / float(segments)
		var angle = -arc_radians / 2.0 + arc_radians * angle_percent
		
		var x = radius * sin(angle)
		var z = radius * cos(angle)
		
		# Bottom vertex
		mesh.surface_set_normal(Vector3(sin(angle), 0, cos(angle)).normalized())
		mesh.surface_set_uv(Vector2(angle_percent, 0))
		mesh.surface_add_vertex(Vector3(x, -height/2.0, z))
		
		# Top vertex
		mesh.surface_set_normal(Vector3(sin(angle), 0, cos(angle)).normalized())
		mesh.surface_set_uv(Vector2(angle_percent, 1))
		mesh.surface_add_vertex(Vector3(x, height/2.0, z))
		

		
	mesh.surface_end()
	
	surface.add_child(mesh_instance)
	add_child(surface)
	
	return surface

func create_flat_projection_surface(position: Vector3, size: Vector2, rotation: Vector3 = Vector3.ZERO) -> Node3D:
	var surface = Node3D.new()
	surface.position = position
	surface.rotation_degrees = rotation
	
	var mesh_instance = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = size
	
	var material = StandardMaterial3D.new()
	material.roughness = 0.2
	material.metallic = 0.0
	material.emission_enabled = true
	material.emission_energy = 0.5
	
	mesh_instance.mesh = plane_mesh
	mesh_instance.material_override = material
	
	surface.add_child(mesh_instance)
	add_child(surface)
	
	return surface

func create_dome_projection_surface(position: Vector3, radius: float, rings: int, segments: int) -> Node3D:
	var surface = Node3D.new()
	surface.position = position
	
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2
	sphere_mesh.is_hemisphere = true
	
	var material = StandardMaterial3D.new()
	material.roughness = 0.2
	material.metallic = 0.0
	material.emission_enabled = true
	material.emission_energy = 0.5
	
	mesh_instance.mesh = sphere_mesh
	mesh_instance.material_override = material
	
	# Flip it upside down to create a dome
	mesh_instance.rotation_degrees = Vector3(180, 0, 0)
	
	surface.add_child(mesh_instance)
	add_child(surface)
	
	return surface

func create_floating_objects():
	# Create various floating objects typical of Rist's installations
	
	# 1. Floating flowers
	for i in range(15):
		var flower = create_floating_flower(
			Vector3(randf_range(-5, 5), randf_range(1, 4), randf_range(-5, 5)),  # Position
			randf_range(0.2, 0.6)  # Size
		)
		floating_objects.append(flower)
	
	# 2. Hanging fabric strips
	for i in range(8):
		var angle = i * (360.0 / 8.0)
		var radius = 4.0
		var fabric = create_hanging_fabric(
			Vector3(cos(deg_to_rad(angle)) * radius, 5, sin(deg_to_rad(angle)) * radius),  # Position
			Vector2(0.5, randf_range(3, 6)),  # Size
			Color(randf(), randf(), randf(), 0.7)  # Random color
		)
		floating_objects.append(fabric)
	
	# 3. Glowing orbs
	for i in range(10):
		var orb = create_glowing_orb(
			Vector3(randf_range(-6, 6), randf_range(0.5, 4.5), randf_range(-6, 6)),  # Position
			randf_range(0.1, 0.3),  # Size
			Color(randf(), randf(), randf())  # Random color
		)
		floating_objects.append(orb)
	
	# 4. Water-like objects
	for i in range(5):
		var water = create_water_object(
			Vector3(randf_range(-4, 4), randf_range(0.5, 2), randf_range(-4, 4)),  # Position
			Vector3(randf_range(0.5, 1.5), randf_range(0.1, 0.3), randf_range(0.5, 1.5))  # Size
		)
		floating_objects.append(water)

func create_floating_flower(position: Vector3, size: float) -> Node3D:
	var flower = Node3D.new()
	flower.position = position
	
	var mesh_instance = MeshInstance3D.new()
	var material = StandardMaterial3D.new()
	
	# Randomize petal color
	var hue = randf()
	material.albedo_color = Color.from_hsv(hue, 0.8, 0.9)
	material.roughness = 0.2
	material.metallic = 0.0
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy = 0.3
	
	# Create simple flower shape
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = size * 0.2
	sphere_mesh.height = sphere_mesh.radius * 2
	
	mesh_instance.mesh = sphere_mesh
	mesh_instance.material_override = material
	
	flower.add_child(mesh_instance)
	
	# Add petals
	var petal_count = randi_range(5, 8)
	for i in range(petal_count):
		var angle = i * (2.0 * PI / petal_count)
		var petal = MeshInstance3D.new()
		
		var petal_material = material.duplicate()
		petal_material.albedo_color = material.albedo_color.lightened(0.2)
		
		var capsule_mesh = CapsuleMesh.new()
		capsule_mesh.radius = size * 0.1
		capsule_mesh.height = size * 0.6
		
		petal.mesh = capsule_mesh
		petal.material_override = petal_material
		
		petal.position = Vector3(cos(angle) * size * 0.3, 0, sin(angle) * size * 0.3)
		
		flower.add_child(petal)
		petal.look_at(position + Vector3(cos(angle), 0.2, sin(angle)), Vector3.UP)
	
	add_child(flower)
	return flower

func create_hanging_fabric(position: Vector3, size: Vector2, color: Color) -> Node3D:
	var fabric = Node3D.new()
	fabric.position = position
	
	var mesh_instance = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = size
	plane_mesh.subdivide_width = 10
	plane_mesh.subdivide_depth = 20
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.3
	material.metallic = 0.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color
	material.emission_energy = 0.3
	
	mesh_instance.mesh = plane_mesh
	mesh_instance.material_override = material
	
	fabric.add_child(mesh_instance)
	add_child(fabric)
	
	return fabric

func create_glowing_orb(position: Vector3, size: float, color: Color) -> Node3D:
	var orb = Node3D.new()
	orb.position = position
	
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = size
	sphere_mesh.height = size * 2
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.1
	material.metallic = 0.2
	material.emission_enabled = true
	material.emission = color
	material.emission_energy = 1.0
	
	mesh_instance.mesh = sphere_mesh
	mesh_instance.material_override = material
	
	# Add point light
	var light = OmniLight3D.new()
	light.light_color = color
	light.light_energy = 0.5
	light.omni_range = size * 10
	orb.add_child(light)
	
	orb.add_child(mesh_instance)
	add_child(orb)
	
	return orb

func create_water_object(position: Vector3, size: Vector3) -> Node3D:
	var water = Node3D.new()
	water.position = position
	
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 0.9, 0.6)
	material.roughness = 0.1
	material.metallic = 0.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0.2, 0.3, 0.9)
	material.emission_energy = 0.3
	
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = material
	
	water.add_child(mesh_instance)
	add_child(water)
	
	return water

func setup_post_processing():
	# Create a shader for post-processing effects typical in Rist's work
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	var color_rect = ColorRect.new()
	color_rect.material = ShaderMaterial.new()
	color_rect.material.shader = preload("res://algorithms/criticaltheory/pipilottiristworld/pippi.gdshader")
	post_processing_material = color_rect.material
	
	# Set initial shader parameters
	post_processing_material.set_shader_parameter("saturation", saturation_amount)
	post_processing_material.set_shader_parameter("color_shift_speed", color_shift_speed)
	
	color_rect.size = Vector2(1920, 1080)  # Will be resized in _process
	canvas_layer.add_child(color_rect)
	
	# Ensure the rect covers the full viewport
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)

func start_video_projections():
	# Set up video projections for surfaces
	var default_videos = [

	]
	
	# Use provided videos if available, otherwise use defaults
	var videos_to_use = video_paths if video_paths.size() > 0 else default_videos
	


func create_projection_for_surface(surface: Node3D, video_path: String):
	# Check if we have a mesh to project onto
	var mesh_instance = find_mesh_instance(surface)
	if not mesh_instance:
		return
	
	# Create video player
	var video_player = VideoStreamPlayer.new()
	var video_stream
	
	# Try to load the video
	if ResourceLoader.exists(video_path):
		video_stream = load(video_path)
	else:
		# If video doesn't exist, create a placeholder pattern
		print("Video not found: ", video_path)
		return
	
	video_player.stream = video_stream
	video_player.autoplay = true
	video_player.loop = true
	video_player.expand = true
	add_child(video_player)
	video_players.append(video_player)
	
	# Create viewport for the video
	var viewport = SubViewport.new()
	viewport.size = Vector2(1024, 1024)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	projection_viewports.append(viewport)
	
	# Move video player to viewport
	remove_child(video_player)
	viewport.add_child(video_player)
	
	# Set video player size to match viewport
	video_player.size = Vector2(1024, 1024)
	
	# Apply the viewport texture to the surface
	var material = mesh_instance.material_override.duplicate()
	material.albedo_texture = viewport.get_texture()
	material.emission_texture = viewport.get_texture()
	mesh_instance.material_override = material

func find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	
	for child in node.get_children():
		var result = find_mesh_instance(child)
		if result:
			return result
	
	return null

func animate_colors(delta):
	# Animate environment colors
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		
		# Shift fog color hue
		var h = fog_color.h
		var s = fog_color.s
		var v = fog_color.v
		
		h = wrapf(h + delta * color_shift_speed * 0.1, 0.0, 1.0)
		fog_color = Color.from_hsv(h, s, v)
		
		#env.fog_color = fog_color
		env.ambient_light_color = ambient_light_color.lerp(fog_color, sin(time * 0.3) * 0.5 + 0.5)
	
	# Animate projection intensities
	for i in range(projection_surfaces.size()):
		var mesh_instance = find_mesh_instance(projection_surfaces[i])
		if mesh_instance and mesh_instance.material_override:
			var mat = mesh_instance.material_override
			var pulse = (sin(time * pulsating_speed + i * 0.5) * 0.3 + 0.7) * projection_intensity
			mat.emission_energy = pulse

func animate_floating_objects(delta):
	# Animate all floating objects
	for i in range(floating_objects.size()):
		var obj = floating_objects[i]
		var initial_y = obj.position.y
		
		# Gentle floating motion
		obj.position.y = initial_y + sin(time * floating_objects_speed + i) * 0.2
		
		# Slow rotation
		obj.rotate_y(delta * rotation_speed)
		
		# Slight swaying
		var sway = sin(time * 0.3 + i * 0.7) * 0.01
		obj.rotate_x(sway)
		obj.rotate_z(sway)

# Helper functions to add or modify elements at runtime

func add_floating_object(position: Vector3, type: String = "flower"):
	match type.to_lower():
		"flower":
			var flower = create_floating_flower(position, randf_range(0.2, 0.6))
			floating_objects.append(flower)
			return flower
		"fabric":
			var fabric = create_hanging_fabric(
				position,
				Vector2(0.5, randf_range(3, 6)),
				Color(randf(), randf(), randf(), 0.7)
			)
			floating_objects.append(fabric)
			return fabric
		"orb":
			var orb = create_glowing_orb(
				position,
				randf_range(0.1, 0.3),
				Color(randf(), randf(), randf())
			)
			floating_objects.append(orb)
			return orb
		"water":
			var water = create_water_object(
				position,
				Vector3(randf_range(0.5, 1.5), randf_range(0.1, 0.3), randf_range(0.5, 1.5))
			)
			floating_objects.append(water)
			return water
	
	return null

func change_all_videos(video_path: String):
	for i in range(video_players.size()):
		if ResourceLoader.exists(video_path):
			var video_stream = load(video_path)
			video_players[i].stream = video_stream
			video_players[i].play()

func set_color_theme(main_color: Color):
	fog_color = main_color
	ambient_light_color = main_color.darkened(0.5)
	sky_color = main_color.lightened(0.3)
	
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		env.fog_color = fog_color
		env.ambient_light_color = ambient_light_color
		env.background_color = sky_color
