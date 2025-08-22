extends Node3D
class_name QueerNoiseTerrain

# Terrain parameters
@export var terrain_size: int = 100
@export var terrain_resolution: int = 200
@export var noise_scale: float = 1.0
@export var height_multiplier: float = 5.0
@export var bulginess: float = 1.0
@export var octaves: int = 4
@export var color_shift: float = 0.5

# Noise generators
var noise: FastNoiseLite
var secondary_noise: FastNoiseLite
var bulge_noise: FastNoiseLite

# Terrain mesh and collision
var terrain_mesh: ArrayMesh
var terrain_material: StandardMaterial3D
var heightmap_material: ShaderMaterial
var vertices: PackedVector3Array
var normals: PackedVector3Array
var uvs: PackedVector2Array
var indices: PackedInt32Array
var colors: PackedColorArray

# Material settings
var use_heightmap_shader: bool = true  # Make heightmap shader the default
var contour_frequency: float = 20.0
var contour_strength: float = 0.3
var enable_contours: bool = true

# Player controller (removed - using external player)
# var player: CharacterBody3D
var player_speed: float = 8.0
var jump_velocity: float = 12.0
var gravity: float = 25.0
var mouse_sensitivity: float = 0.002
# var camera: Camera3D

# Animation
var time: float = 0.0
var animate_terrain: bool = true

# Blob system
var blob_spawner: NoiseBlobSpawner

func _ready():
	setup_noise_generators()
	setup_materials()
	setup_ui_connections()
	update_ui_button_states()
	setup_blob_system()
	generate_terrain()

func _process(delta):
	time += delta
	
	if animate_terrain:
		animate_terrain_colors(delta)

func setup_noise_generators():
	print("Setting up noise generators...")
	
	# Primary terrain noise - smoother settings
	noise = FastNoiseLite.new()
	if noise == null:
		print("ERROR: Failed to create primary noise!")
		return
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.008  # Lower frequency for smoother terrain
	noise.fractal_octaves = octaves
	noise.fractal_gain = 0.4  # Less gain for smoother transitions
	noise.fractal_lacunarity = 2.0
	
	# Secondary detail noise - gentler
	secondary_noise = FastNoiseLite.new()
	if secondary_noise == null:
		print("ERROR: Failed to create secondary noise!")
		return
	secondary_noise.seed = randi()
	secondary_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	secondary_noise.frequency = 0.03  # Smaller details
	secondary_noise.fractal_octaves = 2  # Fewer octaves
	
	# Bulge/warp noise for queer distortion - much gentler
	bulge_noise = FastNoiseLite.new()
	if bulge_noise == null:
		print("ERROR: Failed to create bulge noise!")
		return
	bulge_noise.seed = randi()
	bulge_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	bulge_noise.frequency = 0.01  # Lower frequency
	bulge_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	
	print("Noise generators created successfully!")

func setup_materials():
	# Create heightmap material
	var shader = load("res://algorithms/randomness/noiseterrain/heightmap_shader.gdshader")
	if shader == null:
		print("ERROR: Could not load heightmap shader!")
		return
	
	heightmap_material = ShaderMaterial.new()
	heightmap_material.shader = shader
	heightmap_material.set_shader_parameter("height_scale", 1.0)
	heightmap_material.set_shader_parameter("contour_frequency", contour_frequency)
	heightmap_material.set_shader_parameter("contour_strength", contour_strength)
	heightmap_material.set_shader_parameter("enable_contours", enable_contours)
	
	print("Heightmap material created successfully")

func update_ui_button_states():
	# Set button states based on current material mode
	$ParameterUI/ParameterPanel/MaterialButtons/StandardMaterialButton.button_pressed = not use_heightmap_shader
	$ParameterUI/ParameterPanel/MaterialButtons/HeightmapShaderButton.button_pressed = use_heightmap_shader

func setup_ui_connections():
	$ParameterUI/ParameterPanel/NoiseScaleSlider.value_changed.connect(_on_noise_scale_changed)
	$ParameterUI/ParameterPanel/HeightMultiplierSlider.value_changed.connect(_on_height_multiplier_changed)
	$ParameterUI/ParameterPanel/BulginessSlider.value_changed.connect(_on_bulginess_changed)
	$ParameterUI/ParameterPanel/OctavesSlider.value_changed.connect(_on_octaves_changed)
	$ParameterUI/ParameterPanel/ColorShiftSlider.value_changed.connect(_on_color_shift_changed)
	
	$ParameterUI/ParameterPanel/ButtonContainer/RegenerateButton.pressed.connect(_on_regenerate_pressed)
	$ParameterUI/ParameterPanel/ButtonContainer/RandomizeButton.pressed.connect(_on_randomize_pressed)
	
	# Material switching connections
	$ParameterUI/ParameterPanel/MaterialButtons/StandardMaterialButton.pressed.connect(_on_standard_material_pressed)
	$ParameterUI/ParameterPanel/MaterialButtons/HeightmapShaderButton.pressed.connect(_on_heightmap_shader_pressed)
	
	# Shader parameter connections
	$ParameterUI/ParameterPanel/ContourFrequencySlider.value_changed.connect(_on_contour_frequency_changed)
	$ParameterUI/ParameterPanel/ContourStrengthSlider.value_changed.connect(_on_contour_strength_changed)
	$ParameterUI/ParameterPanel/EnableContoursCheckbox.toggled.connect(_on_enable_contours_toggled)
	
	# Blob system connections
	$ParameterUI/ParameterPanel/BlobButtonContainer/SpawnBlobButton.pressed.connect(_on_spawn_blob_pressed)
	$ParameterUI/ParameterPanel/BlobButtonContainer/ClearBlobsButton.pressed.connect(_on_clear_blobs_pressed)
	$ParameterUI/ParameterPanel/BlobCountSlider.value_changed.connect(_on_blob_count_changed)
	$ParameterUI/ParameterPanel/BlobSpeedSlider.value_changed.connect(_on_blob_speed_changed)

# Removed camera and player movement functions
# setup_camera_follow(), handle_player_movement(), update_camera_follow(), _input()

func generate_terrain():
	clear_terrain()
	create_terrain_mesh()
	create_terrain_collision()
	apply_terrain_material()
	
	print("Terrain generated: %d vertices, %d triangles" % [vertices.size(), indices.size() / 3])

func clear_terrain():
	vertices.clear()
	normals.clear()
	uvs.clear()
	indices.clear()
	colors.clear()

func create_terrain_mesh():
	var mesh_instance = $TerrainMesh
	terrain_mesh = ArrayMesh.new()
	
	print("Generating terrain mesh...")
	
	# Generate vertex grid
	for z in range(terrain_resolution + 1):
		for x in range(terrain_resolution + 1):
			var world_x = (x / float(terrain_resolution) - 0.5) * terrain_size
			var world_z = (z / float(terrain_resolution) - 0.5) * terrain_size
			
			# Generate height using multiple noise layers
			var height = generate_height_at_position(world_x, world_z)
			
			vertices.append(Vector3(world_x, height, world_z))
			
			# Generate UV coordinates
			uvs.append(Vector2(x / float(terrain_resolution), z / float(terrain_resolution)))
			
			# Generate colors based on height and noise
			var color = generate_color_at_position(world_x, world_z, height)
			colors.append(color)
	
	print("Generated %d vertices" % vertices.size())
	
	# Generate indices for triangles - FIXED winding order
	for z in range(terrain_resolution):
		for x in range(terrain_resolution):
			var i = z * (terrain_resolution + 1) + x
			
			# First triangle: counter-clockwise from top view
			indices.append(i)
			indices.append(i + 1)
			indices.append(i + terrain_resolution + 1)
			
			# Second triangle: counter-clockwise from top view
			indices.append(i + 1)
			indices.append(i + terrain_resolution + 2)
			indices.append(i + terrain_resolution + 1)
	
	print("Generated %d triangles" % (indices.size() / 3))
	
	# Calculate normals
	calculate_normals()
	
	# Create mesh arrays
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	# Add surface to mesh
	terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = terrain_mesh
	
	print("Mesh created successfully with %d surfaces!" % terrain_mesh.get_surface_count())

func generate_height_at_position(x: float, z: float) -> float:
	# Safety check: ensure noise generators are initialized
	if noise == null:
		print("ERROR: noise is null, reinitializing...")
		setup_noise_generators()
	
	if noise == null:
		print("CRITICAL ERROR: Failed to initialize noise generators!")
		return 0.0
	
	# Primary noise layer - smoother
	var primary_height = noise.get_noise_2d(x * noise_scale, z * noise_scale)
	
	# Secondary detail layer - reduced intensity
	var detail_height = 0.0
	if secondary_noise != null:
		detail_height = secondary_noise.get_noise_2d(x * noise_scale * 2.0, z * noise_scale * 2.0) * 0.2
	
	# Bulge/warp effect - much gentler
	var bulge_x = x
	var bulge_z = z
	if bulge_noise != null:
		bulge_x = x + bulge_noise.get_noise_2d(x * 0.003, z * 0.003) * bulginess * 5.0
		bulge_z = z + bulge_noise.get_noise_2d(x * 0.004, z * 0.004) * bulginess * 5.0
	var bulge_height = noise.get_noise_2d(bulge_x * noise_scale, bulge_z * noise_scale) * bulginess * 0.3
	
	# Combine layers with smoother blending
	var total_height = (primary_height + detail_height + bulge_height) * height_multiplier
	
	# Gentler center elevation
	var distance_from_center = sqrt(x * x + z * z) / (terrain_size * 0.5)
	var center_bulge = max(0.0, (1.0 - distance_from_center * 0.3)) * bulginess * 1.0
	
	# Smoother base level without sharp cutoffs
	return total_height + center_bulge

func generate_color_at_position(x: float, z: float, height: float) -> Color:
	# Base queer color palette
	var base_pink = Color(0.9, 0.3, 0.7, 1.0)
	var base_purple = Color(0.6, 0.2, 0.9, 1.0)
	var base_cyan = Color(0.2, 0.8, 0.9, 1.0)
	
	# Height-based color mixing
	var height_ratio = (height + height_multiplier) / (height_multiplier * 2.0)
	height_ratio = clamp(height_ratio, 0.0, 1.0)
	
	# Noise-based color variation
	var color_noise = 0.0
	if secondary_noise != null:
		color_noise = secondary_noise.get_noise_2d(x * 0.02, z * 0.02)
	var color_variation = (color_noise + 1.0) * 0.5  # Normalize to 0-1
	
	# Mix colors based on height and noise
	var color1 = base_pink.lerp(base_purple, height_ratio)
	var color2 = base_purple.lerp(base_cyan, color_variation)
	var final_color = color1.lerp(color2, color_shift)
	
	# Add some sparkle/variation
	var sparkle = 0.0
	if bulge_noise != null:
		sparkle = abs(bulge_noise.get_noise_2d(x * 0.1, z * 0.1))
	final_color = final_color.lerp(Color.WHITE, sparkle * 0.2)
	
	return final_color

func calculate_normals():
	normals.resize(vertices.size())
	
	# Initialize all normals to up vector
	for i in range(normals.size()):
		normals[i] = Vector3.UP
	
	# Calculate face normals and accumulate to vertices
	for i in range(0, indices.size(), 3):
		var i0 = indices[i]
		var i1 = indices[i + 1]
		var i2 = indices[i + 2]
		
		# Bounds check
		if i0 >= vertices.size() or i1 >= vertices.size() or i2 >= vertices.size():
			continue
		
		# Get vertices
		var v0 = vertices[i0]
		var v1 = vertices[i1]
		var v2 = vertices[i2]
		
		# Calculate face normal
		var edge1 = v1 - v0
		var edge2 = v2 - v0
		var face_normal = edge1.cross(edge2)
		
		# Only use if not zero length
		if face_normal.length() > 0.001:
			face_normal = face_normal.normalized()
			
			# Accumulate to vertex normals
			normals[i0] += face_normal
			normals[i1] += face_normal
			normals[i2] += face_normal
	
	# Normalize all vertex normals
	for i in range(normals.size()):
		if normals[i].length() > 0.001:
			normals[i] = normals[i].normalized()
		else:
			normals[i] = Vector3.UP
	
	print("Normals calculated for %d vertices" % normals.size())

func create_terrain_collision():
	var collision_shape = $TerrainBody/TerrainCollision
	
	# CRITICAL: Use ConcavePolygonShape3D for detailed terrain collision
	var shape = ConcavePolygonShape3D.new()
	
	# Create collision mesh that exactly matches the visual mesh
	var collision_vertices: PackedVector3Array = []
	
	# Use the same triangulation as the visual mesh
	for i in range(0, indices.size(), 3):
		collision_vertices.append(vertices[indices[i]])
		collision_vertices.append(vertices[indices[i + 1]])
		collision_vertices.append(vertices[indices[i + 2]])
	
	shape.set_faces(collision_vertices)
	collision_shape.shape = shape
	
	print("Collision mesh created with %d triangles" % (collision_vertices.size() / 3))
	print("IMPORTANT: Make sure TerrainCollision uses ConcavePolygonShape3D, not ConvexPolygonShape3D!")

func apply_terrain_material():
	var mesh_instance = $TerrainMesh
	
	if use_heightmap_shader:
		# Apply heightmap shader material
		if heightmap_material == null:
			print("ERROR: Heightmap material is null!")
			return
		mesh_instance.material_override = heightmap_material
		print("Applied heightmap shader material")
	else:
		# Create and apply standard material
		terrain_material = StandardMaterial3D.new()
		
		# Simpler material settings that definitely work
		terrain_material.albedo_color = Color(0.8, 0.4, 0.9, 1.0)
		terrain_material.emission_enabled = true
		terrain_material.emission = Color(0.3, 0.1, 0.4, 1.0)
		terrain_material.emission_energy = 1.5
		terrain_material.metallic = 0.2
		terrain_material.roughness = 0.6
		terrain_material.vertex_color_use_as_albedo = true
		terrain_material.vertex_color_is_srgb = true
		
		# Keep culling enabled for now to avoid issues
		terrain_material.cull_mode = BaseMaterial3D.CULL_BACK
		
		mesh_instance.material_override = terrain_material
		print("Applied standard material")

func animate_terrain_colors(delta):
	if not terrain_mesh:
		return
	
	# Animate emission energy for breathing effect
	if terrain_material:
		terrain_material.emission_energy = 1.5 + sin(time * 2.0) * 0.5

# Removed player movement and camera functions

func update_ui_labels():
	$ParameterUI/ParameterPanel/NoiseScaleLabel.text = "Noise Scale: %.1f" % noise_scale
	$ParameterUI/ParameterPanel/HeightMultiplierLabel.text = "Height Multiplier: %.1f" % height_multiplier
	$ParameterUI/ParameterPanel/BulginessLabel.text = "Bulginess: %.1f" % bulginess
	$ParameterUI/ParameterPanel/OctavesLabel.text = "Octaves: %d" % octaves
	$ParameterUI/ParameterPanel/ColorShiftLabel.text = "Color Shift: %.1f" % color_shift
	$ParameterUI/ParameterPanel/ContourFrequencyLabel.text = "Contour Frequency: %.1f" % contour_frequency
	$ParameterUI/ParameterPanel/ContourStrengthLabel.text = "Contour Strength: %.2f" % contour_strength

# UI Event Handlers
func _on_noise_scale_changed(value: float):
	noise_scale = value
	noise.frequency = 0.01 * noise_scale
	update_ui_labels()
	generate_terrain()

func _on_height_multiplier_changed(value: float):
	height_multiplier = value
	update_ui_labels()
	generate_terrain()

func _on_bulginess_changed(value: float):
	bulginess = value
	update_ui_labels()
	generate_terrain()

func _on_octaves_changed(value: float):
	octaves = int(value)
	noise.fractal_octaves = octaves
	update_ui_labels()
	generate_terrain()

func _on_color_shift_changed(value: float):
	color_shift = value
	update_ui_labels()
	generate_terrain()

func _on_regenerate_pressed():
	# Generate new noise seeds
	noise.seed = randi()
	secondary_noise.seed = randi()
	bulge_noise.seed = randi()
	generate_terrain()

func _on_randomize_pressed():
	# Randomize all parameters
	noise_scale = randf_range(0.3, 3.0)
	height_multiplier = randf_range(2.0, 15.0)
	bulginess = randf_range(0.2, 2.5)
	octaves = randi_range(2, 7)
	color_shift = randf_range(0.0, 1.5)
	
	# Update sliders
	$ParameterUI/ParameterPanel/NoiseScaleSlider.value = noise_scale
	$ParameterUI/ParameterPanel/HeightMultiplierSlider.value = height_multiplier
	$ParameterUI/ParameterPanel/BulginessSlider.value = bulginess
	$ParameterUI/ParameterPanel/OctavesSlider.value = octaves
	$ParameterUI/ParameterPanel/ColorShiftSlider.value = color_shift
	
	# Update noise settings
	noise.frequency = 0.01 * noise_scale
	noise.fractal_octaves = octaves
	
	# Generate new seeds and terrain
	_on_regenerate_pressed()
	
	update_ui_labels()

# Material switching event handlers
func _on_standard_material_pressed():
	if not use_heightmap_shader:
		return
	use_heightmap_shader = false
	$ParameterUI/ParameterPanel/MaterialButtons/StandardMaterialButton.button_pressed = true
	$ParameterUI/ParameterPanel/MaterialButtons/HeightmapShaderButton.button_pressed = false
	apply_terrain_material()

func _on_heightmap_shader_pressed():
	if use_heightmap_shader:
		return
	use_heightmap_shader = true
	$ParameterUI/ParameterPanel/MaterialButtons/StandardMaterialButton.button_pressed = false
	$ParameterUI/ParameterPanel/MaterialButtons/HeightmapShaderButton.button_pressed = true
	apply_terrain_material()

# Shader parameter event handlers
func _on_contour_frequency_changed(value: float):
	contour_frequency = value
	if heightmap_material:
		heightmap_material.set_shader_parameter("contour_frequency", contour_frequency)
	update_ui_labels()

func _on_contour_strength_changed(value: float):
	contour_strength = value
	if heightmap_material:
		heightmap_material.set_shader_parameter("contour_strength", contour_strength)
	update_ui_labels()

func _on_enable_contours_toggled(enabled: bool):
	enable_contours = enabled
	if heightmap_material:
		heightmap_material.set_shader_parameter("enable_contours", enable_contours)

# Blob system setup and event handlers
func setup_blob_system():
	blob_spawner = $NoiseBlobSpawner
	if blob_spawner:
		print("Blob spawner found and connected!")
	else:
		print("WARNING: Blob spawner not found!")

func _on_spawn_blob_pressed():
	if blob_spawner:
		blob_spawner.spawn_single_blob()
		update_blob_ui_labels()

func _on_clear_blobs_pressed():
	if blob_spawner:
		blob_spawner.clear_all_blobs()
		update_blob_ui_labels()

func _on_blob_count_changed(value: float):
	if blob_spawner:
		blob_spawner.blob_count = int(value)
		update_blob_ui_labels()

func _on_blob_speed_changed(value: float):
	if blob_spawner:
		blob_spawner.blob_speed = value
		update_blob_ui_labels()

func update_blob_ui_labels():
	if blob_spawner:
		var stats = blob_spawner.get_blob_stats()
		$ParameterUI/ParameterPanel/BlobCountLabel.text = "Active Blobs: %d/%d" % [stats.active_blobs, stats.max_blobs]
		$ParameterUI/ParameterPanel/BlobSpeedLabel.text = "Blob Speed: %.1f" % blob_spawner.blob_speed

# Public API
func get_height_at_world_position(world_pos: Vector3) -> float:
	return generate_height_at_position(world_pos.x, world_pos.z)

func set_terrain_parameters(params: Dictionary):
	if params.has("noise_scale"):
		noise_scale = params.noise_scale
	if params.has("height_multiplier"):
		height_multiplier = params.height_multiplier
	if params.has("bulginess"):
		bulginess = params.bulginess
	if params.has("octaves"):
		octaves = params.octaves
	if params.has("color_shift"):
		color_shift = params.color_shift
	
	generate_terrain()
	update_ui_labels()

func get_terrain_info() -> Dictionary:
	return {
		"noise_scale": noise_scale,
		"height_multiplier": height_multiplier,
		"bulginess": bulginess,
		"octaves": octaves,
		"color_shift": color_shift,
		"terrain_size": terrain_size,
		"resolution": terrain_resolution
	}
