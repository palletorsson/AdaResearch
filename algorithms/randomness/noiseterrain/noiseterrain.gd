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
var vertices: PackedVector3Array
var normals: PackedVector3Array
var uvs: PackedVector2Array
var indices: PackedInt32Array
var colors: PackedColorArray

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

func _ready():
	setup_noise_generators()
	setup_ui_connections()
	generate_terrain()

func _process(delta):
	time += delta
	
	if animate_terrain:
		animate_terrain_colors(delta)

func setup_noise_generators():
	# Primary terrain noise
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.01
	noise.fractal_octaves = octaves
	noise.fractal_gain = 0.5
	noise.fractal_lacunarity = 2.0
	
	# Secondary detail noise
	secondary_noise = FastNoiseLite.new()
	secondary_noise.seed = randi()
	secondary_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	secondary_noise.frequency = 0.05
	secondary_noise.fractal_octaves = 3
	
	# Bulge/warp noise for queer distortion
	bulge_noise = FastNoiseLite.new()
	bulge_noise.seed = randi()
	bulge_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	bulge_noise.frequency = 0.02
	bulge_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE

func setup_ui_connections():
	$ParameterUI/ParameterPanel/NoiseScaleSlider.value_changed.connect(_on_noise_scale_changed)
	$ParameterUI/ParameterPanel/HeightMultiplierSlider.value_changed.connect(_on_height_multiplier_changed)
	$ParameterUI/ParameterPanel/BulginessSlider.value_changed.connect(_on_bulginess_changed)
	$ParameterUI/ParameterPanel/OctavesSlider.value_changed.connect(_on_octaves_changed)
	$ParameterUI/ParameterPanel/ColorShiftSlider.value_changed.connect(_on_color_shift_changed)
	
	$ParameterUI/ParameterPanel/ButtonContainer/RegenerateButton.pressed.connect(_on_regenerate_pressed)
	$ParameterUI/ParameterPanel/ButtonContainer/RandomizeButton.pressed.connect(_on_randomize_pressed)

# Removed camera and player movement functions
# setup_camera_follow(), handle_player_movement(), update_camera_follow(), _input()

func generate_terrain():
	clear_terrain()
	create_terrain_mesh()
	create_terrain_collision()
	apply_terrain_material()

func clear_terrain():
	vertices.clear()
	normals.clear()
	uvs.clear()
	indices.clear()
	colors.clear()

func create_terrain_mesh():
	var mesh_instance = $TerrainMesh
	terrain_mesh = ArrayMesh.new()
	
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
	
	# Generate indices for triangles
	for z in range(terrain_resolution):
		for x in range(terrain_resolution):
			var i = z * (terrain_resolution + 1) + x
			
			# First triangle
			indices.append(i)
			indices.append(i + terrain_resolution + 1)
			indices.append(i + 1)
			
			# Second triangle
			indices.append(i + 1)
			indices.append(i + terrain_resolution + 1)
			indices.append(i + terrain_resolution + 2)
	
	# Calculate normals
	calculate_normals()
	
	# Create mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = terrain_mesh

func generate_height_at_position(x: float, z: float) -> float:
	# Primary noise layer
	var primary_height = noise.get_noise_2d(x * noise_scale, z * noise_scale)
	
	# Secondary detail layer
	var detail_height = secondary_noise.get_noise_2d(x * noise_scale * 3.0, z * noise_scale * 3.0) * 0.3
	
	# Bulge/warp effect for queer aesthetics
	var bulge_x = x + bulge_noise.get_noise_2d(x * 0.005, z * 0.005) * bulginess * 10.0
	var bulge_z = z + bulge_noise.get_noise_2d(x * 0.007, z * 0.007) * bulginess * 10.0
	var bulge_height = noise.get_noise_2d(bulge_x * noise_scale, bulge_z * noise_scale) * bulginess
	
	# Combine layers
	var total_height = (primary_height + detail_height + bulge_height * 0.5) * height_multiplier
	
	# Add some organic curves
	var distance_from_center = sqrt(x * x + z * z) / (terrain_size * 0.5)
	var center_bulge = (1.0 - distance_from_center) * bulginess * 2.0
	
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
	var color_noise = secondary_noise.get_noise_2d(x * 0.02, z * 0.02)
	var color_variation = (color_noise + 1.0) * 0.5  # Normalize to 0-1
	
	# Mix colors based on height and noise
	var color1 = base_pink.lerp(base_purple, height_ratio)
	var color2 = base_purple.lerp(base_cyan, color_variation)
	var final_color = color1.lerp(color2, color_shift)
	
	# Add some sparkle/variation
	var sparkle = abs(bulge_noise.get_noise_2d(x * 0.1, z * 0.1))
	final_color = final_color.lerp(Color.WHITE, sparkle * 0.2)
	
	return final_color

func calculate_normals():
	normals.resize(vertices.size())
	normals.fill(Vector3.ZERO)
	
	# Calculate face normals and accumulate
	for i in range(0, indices.size(), 3):
		var i0 = indices[i]
		var i1 = indices[i + 1]
		var i2 = indices[i + 2]
		
		var v0 = vertices[i0]
		var v1 = vertices[i1]
		var v2 = vertices[i2]
		
		var face_normal = (v1 - v0).cross(v2 - v0).normalized()
		
		normals[i0] += face_normal
		normals[i1] += face_normal
		normals[i2] += face_normal
	
	# Normalize all normals
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()

func create_terrain_collision():
	var collision_shape = $TerrainBody/TerrainCollision
	var shape = ConcavePolygonShape3D.new()
	
	# Create collision from mesh
	var collision_vertices: PackedVector3Array = []
	for i in range(0, indices.size(), 3):
		collision_vertices.append(vertices[indices[i]])
		collision_vertices.append(vertices[indices[i + 1]])
		collision_vertices.append(vertices[indices[i + 2]])
	
	shape.set_faces(collision_vertices)
	collision_shape.shape = shape

func apply_terrain_material():
	var mesh_instance = $TerrainMesh
	terrain_material = StandardMaterial3D.new()
	
	# Queer aesthetic material
	terrain_material.albedo_color = Color(0.8, 0.4, 0.9, 1.0)
	terrain_material.emission_enabled = true
	terrain_material.emission = Color(0.3, 0.1, 0.4, 1.0)
	terrain_material.emission_energy = 1.5
	terrain_material.metallic = 0.3
	terrain_material.roughness = 0.4
	terrain_material.vertex_color_use_as_albedo = true
	terrain_material.vertex_color_is_srgb = true
	
	mesh_instance.material_override = terrain_material

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
