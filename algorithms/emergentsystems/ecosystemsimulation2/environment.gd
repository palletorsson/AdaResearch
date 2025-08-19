# environment.gd
class_name EcosystemEnvironment
extends Node3D

signal resource_spawned(resource)
signal environment_changed(change_type, location, intensity)
signal boundary_formed(boundary_type, location, strength)
signal season_changed(season)

# Configuration
@export_category("Environment Parameters")
@export var size: Vector3 = Vector3(50, 20, 50)
@export var enable_day_night_cycle: bool = true
@export var day_duration: float = 300.0  # seconds
@export var enable_seasons: bool = true
@export var season_duration: float = 1200.0  # seconds
@export var enable_weather: bool = true
@export var entropy_influence: float = 1.0
@export var terrain_resolution: int = 64  # Resolution of terrain heightmap

# Environment state
var current_time: float = 0.5  # 0-1 representing time of day (0.5 = noon)
var current_season: int = 0    # 0=spring, 1=summer, 2=autumn, 3=winter
var current_weather: String = "clear"
var current_entropy: float = 0.0
var regions: Array = []
var features: Array = []
var env_features 
var terrain_mesh: MeshInstance3D
var sky_environment: WorldEnvironment
var directional_light: DirectionalLight3D
var ambient_sound: AudioStreamPlayer3D
var particles_manager: Node3D

func _ready():
	# Generate the basic environment
	_create_terrain()
	_setup_sky()
	_setup_lighting()
	_setup_environment_features()
	
	# Set initial time and season
	#update_time_of_day(current_time)
	set_season(current_season)
	
	print("Environment initialized with size: ", size)

func _create_terrain():
	# Create a terrain mesh
	terrain_mesh = MeshInstance3D.new()
	terrain_mesh.name = "Terrain"
	add_child(terrain_mesh)
	
	# Generate terrain mesh
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(size.x, size.z)
	plane_mesh.subdivide_width = terrain_resolution
	plane_mesh.subdivide_depth = terrain_resolution
	
	# Apply heightmap to terrain
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(plane_mesh, 0)
	var array_mesh = surface_tool.commit()
	
	# Get vertex array
	var mesh_data_tool = MeshDataTool.new()
	mesh_data_tool.create_from_surface(array_mesh, 0)
	
	# Apply random height to vertices
	for i in range(mesh_data_tool.get_vertex_count()):
		var vertex = mesh_data_tool.get_vertex(i)
		
		# Calculate height based on position
		var x_norm = (vertex.x + size.x/2) / size.x
		var z_norm = (vertex.z + size.z/2) / size.z
		
		# Use simplex noise for natural terrain
		var height = _generate_terrain_height(x_norm, z_norm)
		
		# Apply height
		vertex.y = height
		mesh_data_tool.set_vertex(i, vertex)
	
	# Recalculate normals
	for i in range(mesh_data_tool.get_face_count()):
		var a = mesh_data_tool.get_face_vertex(i, 0)
		var b = mesh_data_tool.get_face_vertex(i, 1)
		var c = mesh_data_tool.get_face_vertex(i, 2)
		
		var vertices = [
			mesh_data_tool.get_vertex(a),
			mesh_data_tool.get_vertex(b),
			mesh_data_tool.get_vertex(c)
		]
		
		var normal = (vertices[1] - vertices[0]).cross(vertices[2] - vertices[0]).normalized()
		
		mesh_data_tool.set_vertex_normal(a, normal)
		mesh_data_tool.set_vertex_normal(b, normal)
		mesh_data_tool.set_vertex_normal(c, normal)
	
	# Create new mesh
	array_mesh = ArrayMesh.new()
	mesh_data_tool.commit_to_surface(array_mesh)
	terrain_mesh.mesh = array_mesh
	
	# Create terrain material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.5, 0.2)
	material.roughness = 0.9
	terrain_mesh.material_override = material
	
	# Add collision
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var shape = ConcavePolygonShape3D.new()
	
	# Get faces as triangles array
	var face_array = []
	
	for i in range(mesh_data_tool.get_face_count()):
		var a = mesh_data_tool.get_face_vertex(i, 0)
		var b = mesh_data_tool.get_face_vertex(i, 1)
		var c = mesh_data_tool.get_face_vertex(i, 2)
		
		face_array.append(mesh_data_tool.get_vertex(a))
		face_array.append(mesh_data_tool.get_vertex(b))
		face_array.append(mesh_data_tool.get_vertex(c))
	
	shape.set_faces(face_array)
	collision_shape.shape = shape
	static_body.add_child(collision_shape)
	terrain_mesh.add_child(static_body)

func _generate_terrain_height(x: float, z: float) -> float:
	# Generate height using multiple noise frequencies
	# This is a simplified implementation without actual noise functions
	
	# Without access to OpenSimplexNoise, we'll fake the noise pattern
	var height = 0.0
	
	# Large features
	height += sin(x * 3.0) * cos(z * 2.0) * 2.0
	
	# Medium features
	height += sin(x * 7.0) * cos(z * 9.0) * 1.0
	
	# Small features
	height += sin(x * 15.0) * cos(z * 17.0) * 0.5
	
	# Scale and clamp
	height = clamp(height, -3.0, 5.0)
	
	return height

func _setup_sky():
	# Create sky environment
	sky_environment = WorldEnvironment.new()
	sky_environment.name = "SkyEnvironment"
	add_child(sky_environment)
	
	var environment = Environment.new()
	#environment.background_mode = Environment.BACKGROUND_SKY
	
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_horizon_color = Color(0.5, 0.7, 1.0)
	sky_material.sky_top_color = Color(0.1, 0.4, 0.8)
	sky_material.ground_horizon_color = Color(0.6, 0.7, 0.5)
	sky_material.ground_bottom_color = Color(0.4, 0.5, 0.3)
	sky_material.sun_angle_max = deg_to_rad(10.0)
	sky_material.sun_curve = 0.2
	
	sky.sky_material = sky_material
	environment.sky = sky
	
	# Fog and ambient settings
	environment.fog_enabled = true
	environment.fog_density = 0.001
	environment.fog_sun_scatter = 0.5
	#environment.fog_color = Color(0.7, 0.8, 1.0, 1.0)
	
	environment.ambient_light_color = Color(0.5, 0.5, 0.5)
	environment.ambient_light_energy = 0.5
	
	sky_environment.environment = environment

func _setup_lighting():
	# Create directional light (sun)
	directional_light = DirectionalLight3D.new()
	directional_light.name = "DirectionalLight"
	add_child(directional_light)
	
	directional_light.light_color = Color(1.0, 0.95, 0.8)
	directional_light.light_energy = 1.5
	directional_light.shadow_enabled = true
	
	# Position for noon
	directional_light.rotation = Vector3(deg_to_rad(-50), deg_to_rad(45), 0)

func _setup_environment_features():
	# Create a root node for features
	env_features = Node3D.new()
	env_features.name = "EnvironmentFeatures"
	add_child(env_features)
	
	# Create environment regions
	_create_environment_regions()
	
	# Create natural features
	_create_natural_features()
	
	# Setup particles
	particles_manager = Node3D.new()
	particles_manager.name = "ParticlesManager"
	add_child(particles_manager)
	
	# Setup ambient sound
	ambient_sound = AudioStreamPlayer3D.new()
	ambient_sound.name = "AmbientSound"
	ambient_sound.autoplay = true
	ambient_sound.unit_size = 20.0  # Makes the sound audible from further away
	add_child(ambient_sound)

func _create_environment_regions():
	# Create different biome-like regions in the environment
	var region_count = 4 + randi() % 3  # 4-6 regions
	
	# Clear existing regions
	regions.clear()
	
	# Create region data
	for i in range(region_count):
		var region = {
			"position": Vector3(
				randf_range(-size.x/3, size.x/3),
				0,
				randf_range(-size.z/3, size.z/3)
			),
			"radius": randf_range(5, 15),
			"type": _get_random_region_type(),
			"intensity": randf_range(0.5, 1.0),
			"color": Color(randf(), randf(), randf()),
			"particles": null
		}
		
		regions.append(region)
	
	# Create visual markers for regions (in a full implementation)
	for region in regions:
		var marker = Node3D.new()
		marker.name = "Region_" + region.type
		marker.position = region.position
		
		# In a full implementation, you would add visual elements
		# and particle effects based on region type
		
		env_features.add_child(marker)
		region.marker = marker

func _get_random_region_type() -> String:
	var types = [
		"lush", "arid", "flowing", "crystalline", 
		"unstable", "harmonic", "entangled", "transformative"
	]
	return types[randi() % types.size()]

func _create_natural_features():
	# Create various natural features like trees, rocks, etc.
	
	# Number of features based on size
	var feature_count = int(size.x * size.z / 100)
	
	for i in range(feature_count):
		# Random position within environment bounds
		var position = Vector3(
			randf_range(-size.x/2 + 5, size.x/2 - 5),
			0,  # Will be adjusted to terrain height
			randf_range(-size.z/2 + 5, size.z/2 - 5)
		)
		
		# Adjust height to terrain
		position.y = _get_terrain_height_at(position.x, position.z)
		
		# Determine feature type based on location
		var feature_type = _get_feature_type_for_location(position)
		
		# Create feature
		match feature_type:
			"tree": _create_tree(position)
			"rock": _create_rock(position)
			"crystal": _create_crystal(position)
			"plant": _create_plant(position)
			"water": _create_water_feature(position)

func _get_terrain_height_at(x: float, z: float) -> float:
	# Get the height of the terrain at a specific position
	# This is a simplified implementation
	
	# Convert world coordinates to normalized coordinates
	var x_norm = (x + size.x/2) / size.x
	var z_norm = (z + size.z/2) / size.z
	
	return _generate_terrain_height(x_norm, z_norm)

func _get_feature_type_for_location(position: Vector3) -> String:
	# Determine what type of feature should spawn at this location
	# Based on height, regions, etc.
	
	# Check if in special region
	for region in regions:
		if position.distance_to(region.position) < region.radius:
			match region.type:
				"lush": return "tree" if randf() < 0.7 else "plant"
				"arid": return "rock" if randf() < 0.8 else "plant"
				"flowing": return "water" if randf() < 0.6 else "plant"
				"crystalline": return "crystal" if randf() < 0.7 else "rock"
				"unstable", "transformative": 
					var types = ["tree", "rock", "crystal", "plant", "water"]
					return types[randi() % types.size()]
				_: return "tree"
	
	# Based on height
	var height = position.y
	
	if height < -1.0:
		return "water"
	elif height < 0.0:
		return "plant"
	elif height < 2.0:
		return "tree" if randf() < 0.7 else "plant"
	else:
		return "rock" if randf() < 0.7 else "crystal"

func _create_tree(position: Vector3):
	var tree = Node3D.new()
	tree.name = "Tree"
	tree.position = position
	
	# Create trunk
	var trunk = MeshInstance3D.new()
	trunk.name = "Trunk"
	
	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.2
	trunk_mesh.bottom_radius = 0.3
	trunk_mesh.height = randf_range(1.5, 3.0)
	trunk.mesh = trunk_mesh
	
	var trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.5, 0.35, 0.2)
	trunk.material_override = trunk_material
	
	trunk.position.y = trunk_mesh.height / 2
	tree.add_child(trunk)
	
	# Create foliage
	var foliage = MeshInstance3D.new()
	foliage.name = "Foliage"
	
	var foliage_mesh = SphereMesh.new()
	foliage_mesh.radius = randf_range(0.8, 1.2)
	foliage_mesh.height = foliage_mesh.radius * 2
	foliage.mesh = foliage_mesh
	
	var foliage_material = StandardMaterial3D.new()
	foliage_material.albedo_color = Color(0.2, 0.5 + randf() * 0.3, 0.1)
	foliage.material_override = foliage_material
	
	foliage.position.y = trunk_mesh.height + foliage_mesh.radius * 0.5
	tree.add_child(foliage)
	
	env_features.add_child(tree)

func _create_rock(position: Vector3):
	var rock = MeshInstance3D.new()
	rock.name = "Rock"
	rock.position = position
	
	# Randomize rock shape
	var mesh_type = randi() % 3
	var rock_mesh
	
	match mesh_type:
		0:  # Spherical rock
			rock_mesh = SphereMesh.new()
			rock_mesh.radius = randf_range(0.5, 1.2)
			rock_mesh.height = rock_mesh.radius * 2
		1:  # Cubic rock
			rock_mesh = BoxMesh.new()
			var size = randf_range(0.5, 1.5)
			rock_mesh.size = Vector3(size, size * randf_range(0.5, 1.0), size)
		2:  # Irregular rock
			rock_mesh = PrismMesh.new()
			rock_mesh.size = Vector3(
				randf_range(0.5, 1.5),
				randf_range(0.3, 1.0),
				randf_range(0.5, 1.5)
			)
	
	rock.mesh = rock_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	var gray = randf_range(0.3, 0.6)
	material.albedo_color = Color(gray, gray, gray)
	rock.material_override = material
	
	# Adjust position to sit on ground
	if rock_mesh is SphereMesh:
		rock.position.y += rock_mesh.height / 2
	elif rock_mesh is BoxMesh:
		rock.position.y += rock_mesh.size.y / 2
	elif rock_mesh is CylinderMesh:
		rock.position.y += rock_mesh.height / 2
	elif rock_mesh is PrismMesh:
		rock.position.y += rock_mesh.size.y / 2
	
	# Random rotation
	rock.rotation = Vector3(randf() * 0.3, randf() * TAU, randf() * 0.3)
	
	env_features.add_child(rock)

func _create_crystal(position: Vector3):
	var crystal = MeshInstance3D.new()
	crystal.name = "Crystal"
	crystal.position = position
	
	# Create crystal mesh
	var crystal_mesh = PrismMesh.new()
	crystal_mesh.size = Vector3(
		randf_range(0.2, 0.6),
		randf_range(0.5, 1.5),
		randf_range(0.2, 0.6)
	)
	crystal.mesh = crystal_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	
	# Random crystal color
	var crystal_colors = [
		Color(0.8, 0.2, 0.8),  # Purple
		Color(0.2, 0.8, 0.8),  # Cyan
		Color(0.8, 0.8, 0.2),  # Yellow
		Color(0.2, 0.4, 0.8)   # Blue
	]
	
	material.albedo_color = crystal_colors[randi() % crystal_colors.size()]
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy = 0.5
	material.metallic = 0.8
	material.roughness = 0.1
	
	crystal.material_override = material
	
	# Adjust position to sit on ground
	crystal.position.y += crystal_mesh.size.y / 2
	
	# Random rotation around y-axis
	crystal.rotation.y = randf() * TAU
	
	env_features.add_child(crystal)

func _create_plant(position: Vector3):
	var plant = Node3D.new()
	plant.name = "Plant"
	plant.position = position
	
	# Create stem
	var stem = MeshInstance3D.new()
	stem.name = "Stem"
	
	var stem_mesh = CylinderMesh.new()
	stem_mesh.top_radius = 0.05
	stem_mesh.bottom_radius = 0.08
	stem_mesh.height = randf_range(0.3, 0.8)
	stem.mesh = stem_mesh
	
	var stem_material = StandardMaterial3D.new()
	stem_material.albedo_color = Color(0.2, 0.5, 0.1)
	stem.material_override = stem_material
	
	stem.position.y = stem_mesh.height / 2
	plant.add_child(stem)
	
	# Create leaves/flowers
	var flower_count = randi() % 3 + 1
	
	for i in range(flower_count):
		var flower = MeshInstance3D.new()
		flower.name = "Flower_" + str(i)
		
		var flower_mesh = SphereMesh.new()
		flower_mesh.radius = randf_range(0.1, 0.2)
		flower_mesh.height = flower_mesh.radius * 2
		flower.mesh = flower_mesh
		
		var flower_material = StandardMaterial3D.new()
		flower_material.albedo_color = Color(
			randf_range(0.5, 1.0),
			randf_range(0.5, 1.0),
			randf_range(0.5, 1.0)
		)
		flower.material_override = flower_material
		
		flower.position = Vector3(
			randf_range(-0.1, 0.1),
			stem_mesh.height + randf_range(0.0, 0.1),
			randf_range(-0.1, 0.1)
		)
		
		plant.add_child(flower)
	
	env_features.add_child(plant)

func _create_water_feature(position: Vector3):
	var water = MeshInstance3D.new()
	water.name = "WaterFeature"
	water.position = position
	
	# Create water mesh
	var water_mesh = PlaneMesh.new()
	water_mesh.size = Vector2(randf_range(1.0, 3.0), randf_range(1.0, 3.0))
	water.mesh = water_mesh
	
	# Create water material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.1, 0.3, 0.8, 0.7)
	material.metallic = 0.2
	material.roughness = 0.1
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	water.material_override = material
	
	# Position slightly above ground to avoid z-fighting
	water.position.y += 0.05
	
	env_features.add_child(water)

func update(delta: float, current_day: int):
	# Update time of day
	if enable_day_night_cycle:
		current_time = fmod(current_time + delta / day_duration, 1.0)
		#update_time_of_day(current_time)
	
	# Update season
	if enable_seasons:
		var season_progress = fmod((current_day % int(season_duration)) / season_duration, 1.0)
		var new_season = int(season_progress * 4) % 4
		
		if new_season != current_season:
			set_season(new_season)
	
	# Update weather
	if enable_weather:
		_update_weather(delta)
	
	# Update entropy-based effects
	_update_entropy_effects(delta)



func set_season(season: int):
	current_season = season
	
	# Update environment based on season
	var terrain_material = terrain_mesh.material_override
	
	match current_season:
		0:  # Spring
			terrain_material.albedo_color = Color(0.3, 0.5, 0.2)  # Vibrant green
		1:  # Summer
			terrain_material.albedo_color = Color(0.2, 0.4, 0.1)  # Deep green
		2:  # Autumn
			terrain_material.albedo_color = Color(0.4, 0.3, 0.1)  # Brown/orange
		3:  # Winter
			terrain_material.albedo_color = Color(0.8, 0.8, 0.8)  # White with blue tint
	
	# Emit signal for other systems to respond
	emit_signal("season_changed", current_season)

func _update_weather(delta: float):
	# Simple weather system
	# In a full implementation, this would include more complex logic
	# for transitions between weather states
	
	# Random chance to change weather
	if randf() < 0.001 * delta:  # Approx once every 1000 seconds
		var weathers = ["clear", "cloudy", "rainy", "foggy", "stormy"]
		var new_weather = weathers[randi() % weathers.size()]
		
		if new_weather != current_weather:
			set_weather(new_weather)

func set_weather(weather: String):
	current_weather = weather
	
	# Update sky and lighting based on weather
	match weather:
		"clear":
			# Clear settings (default)
			sky_environment.environment.fog_density = 0.001
			directional_light.light_energy *= 1.0
		"cloudy":
			# Increase fog, reduce directional light
			sky_environment.environment.fog_density = 0.003
			directional_light.light_energy *= 0.7
		"rainy":
			# Dark clouds, more fog, less light
			sky_environment.environment.fog_density = 0.005
			directional_light.light_energy *= 0.5
			_start_rain_particles()
		"foggy":
			# Heavy fog
			sky_environment.environment.fog_density = 0.01
			directional_light.light_energy *= 0.6
		"stormy":
			# Dark, lots of fog, very little light
			sky_environment.environment.fog_density = 0.008
			directional_light.light_energy *= 0.4
			_start_storm_particles()
	
	# Update ambient sound based on weather
	_update_ambient_sound()

func _start_rain_particles():
	# Clear existing particles
	for child in particles_manager.get_children():
		child.queue_free()
	
	# Create rain particles
	var rain = GPUParticles3D.new()
	rain.name = "RainParticles"
	
	# In a full implementation, you would set up the particle material
	# and emission shape. This is a simplified placeholder.
	
	particles_manager.add_child(rain)

func _start_storm_particles():
	# Similar to rain but with different parameters and
	# additional lightning effects
	_start_rain_particles()  # Reuse rain for simplicity
	
	# Add lightning flashes
	# In a full implementation, you would add a timer for random flashes

func _update_ambient_sound():
	# Update ambient sound based on weather and time of day
	
	# In a full implementation, you would load different audio streams
	# based on current conditions
	pass

func _update_entropy_effects(delta: float):
	# Apply entropy-based distortions to the environment
	
	# Skip if entropy influence is disabled
	if entropy_influence <= 0:
		return
	
	# Apply subtle distortions based on current entropy level
	if current_entropy > 0.3:
		# Subtle terrain distortions
		# This would be enhanced in a full implementation
		
		# Distort region boundaries
		for region in regions:
			if randf() < 0.01 * delta * current_entropy:
				region.radius += randf_range(-0.2, 0.2) * current_entropy
				
				# Keep within reasonable bounds
				region.radius = clamp(region.radius, 2.0, 20.0)
	
	# More extreme effects at high entropy
	if current_entropy > 0.7:
		# Create temporary reality distortions
		if randf() < 0.005 * delta * current_entropy:
			_create_reality_distortion()

func _create_reality_distortion():
	# Create a temporary visual distortion in the environment
	# In a full implementation, this would include shader effects
	# and more complex distortions
	
	# Choose random location
	var position = Vector3(
		randf_range(-size.x/2, size.x/2),
		randf_range(1, 5),
		randf_range(-size.z/2, size.z/2)
	)
	
	# Create distortion visual
	var distortion = MeshInstance3D.new()
	distortion.name = "RealityDistortion"
	
	var distortion_mesh = SphereMesh.new()
	distortion_mesh.radius = randf_range(1, 3)
	distortion_mesh.height = distortion_mesh.radius * 2
	distortion.mesh = distortion_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1, 0.3)
	material.emission_enabled = true
	material.emission = Color(randf(), randf(), randf())
	material.emission_energy = 2.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	distortion.material_override = material
	
	distortion.position = position
	
	# Add to scene temporarily
	add_child(distortion)
	
	# Remove after random duration
	var duration = randf_range(3, 10)
	await get_tree().create_timer(duration).timeout
	distortion.queue_free()
	
	# Emit signal about environment change
	emit_signal("environment_changed", "distortion", position, duration)

func set_entropy(value: float):
	current_entropy = clamp(value, 0.0, 1.0)

func get_current_entropy() -> float:
	return current_entropy

func get_time_of_day() -> float:
	return current_time

func get_current_season() -> int:
	return current_season

func get_current_weather() -> String:
	return current_weather

func get_environment_size() -> Vector3:
	return size

func get_terrain_dimensions() -> Vector2:
	return Vector2(size.x, size.z)

func get_region_at_position(position: Vector3) -> Dictionary:
	# Check if position is within any region
	for region in regions:
		if position.distance_to(region.position) <= region.radius:
			return region
	
	return {}  # Empty dictionary if not in any region

func spawn_feature_at_position(feature_type: String, position: Vector3) -> Node3D:
	# Create a new feature at specified position
	var feature = null
	
	match feature_type:
		"tree": feature = _create_tree(position)
		"rock": feature = _create_rock(position)
		"crystal": feature = _create_crystal(position)
		"plant": feature = _create_plant(position)
		"water": feature = _create_water_feature(position)
	
	return feature

func create_custom_region(position: Vector3, radius: float, type: String, intensity: float, color: Color) -> Dictionary:
	# Create a custom region
	var region = {
		"position": position,
		"radius": radius,
		"type": type,
		"intensity": intensity,
		"color": color,
		"marker": null
	}
	
	# Create visual marker
	var marker = Node3D.new()
	marker.name = "Region_" + type
	marker.position = position
	
	# In a full implementation, you would add visual elements
	
	env_features.add_child(marker)
	region.marker = marker
	
	# Add to regions list
	regions.append(region)
	
	return region
