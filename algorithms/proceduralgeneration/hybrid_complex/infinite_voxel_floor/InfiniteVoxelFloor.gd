@tool
extends Node3D

# InfiniteVoxelFloor.gd
# High-performance procedurally generated floor that follows the player.
# Uses MultiMeshInstance3D for voxel-style rendering.

@export_category("Grid Settings")
@export var grid_radius: int = 25:
	set(v): grid_radius = v; if is_inside_tree(): _init_multimesh()
@export var cube_size: float = 1.0:
	set(v): cube_size = v; if is_inside_tree(): _init_multimesh()

@export_category("Procedural Settings")
@export var height_scale: float = 2.0
@export var noise_frequency: float = 0.05
@export var color_speed: float = 0.5

@export_category("Lighting Settings")
@export var light_radius: float = 10.0
@export var base_emission: float = 2.0
@export var highlight_emission: float = 8.0

var _multimesh_instance: MultiMeshInstance3D
var _multimesh: MultiMesh
var _noise: FastNoiseLite
var _time: float = 0.0

var _grid_size: int:
	get: return grid_radius * 2 + 1

func _ready() -> void:
	_setup_noise()
	_init_multimesh()

func _setup_noise() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.frequency = noise_frequency
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN

func _init_multimesh() -> void:
	# Cleanup existing
	if _multimesh_instance:
		_multimesh_instance.queue_free()
	
	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "VoxelGrid"
	add_child(_multimesh_instance)
	
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.use_custom_data = true
	
	# Create a simple box mesh
	var box = BoxMesh.new()
	box.size = Vector3(cube_size, cube_size, cube_size)
	_multimesh.mesh = box
	
	_multimesh.instance_count = _grid_size * _grid_size
	_multimesh_instance.multimesh = _multimesh
	
	# Setup material (using StandardMaterial3D with vertex colors for now, or fetch Grid.gdshader)
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 1.0
	_multimesh_instance.material_override = mat

func _process(delta: float) -> void:
	_time += delta * color_speed
	
	var player = GameManager.get_player()
	var player_pos = Vector3.ZERO
	if player:
		player_pos = player.global_position
	
	# Snapping logic for sliding window
	var grid_center_x = round(player_pos.x / cube_size) * cube_size
	var grid_center_z = round(player_pos.z / cube_size) * cube_size
	
	var start_x = grid_center_x - (grid_radius * cube_size)
	var start_z = grid_center_z - (grid_radius * cube_size)
	
	if not _multimesh: return
	
	for gz in range(_grid_size):
		for gx in range(_grid_size):
			var index = gz * _grid_size + gx
			
			var world_x = start_x + (gx * cube_size)
			var world_z = start_z + (gz * cube_size)
			
			# Procedural Height
			var noise_val = _noise.get_noise_2d(world_x, world_z)
			var h = (noise_val + 1.0) * height_scale
			
			# Transform
			var transform = Transform3D()
			transform.origin = Vector3(world_x, h / 2.0, world_z) # Pivot at base
			transform = transform.scaled(Vector3(1.0, h, 1.0))
			_multimesh.set_instance_transform(index, transform)
			
			# Color & Lighting
			var dist_to_player = player_pos.distance_to(Vector3(world_x, h, world_z))
			var light_factor = clamp(1.0 - (dist_to_player / light_radius), 0.0, 1.0)
			
			# Generate a vibrant color based on noise and time
			var hue = fmod(abs(noise_val) + _time * 0.1, 1.0)
			var color = Color.from_hsv(hue, 0.7, 0.9)
			
			# Apply emission factor to color
			var emission_val = lerp(base_emission, highlight_emission, light_factor)
			color = color * (1.0 + emission_val) # Boost brightness
			
			_multimesh.set_instance_color(index, color)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

