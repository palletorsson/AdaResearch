# perlin_terrain_sculptor.gd
# Voxel sculpture tool where Perlin noise is the brush
# Add/remove voxels based on noise thresholding

extends Node3D

class_name PerlinTerrainSculptor

## Grid dimensions
@export var grid_size: int = 24
@export var voxel_size: float = 0.04  # Total size ≈ 1m

## Noise parameters
@export_group("Noise")
@export var noise_scale: float = 4.0:
	set(value):
		noise_scale = value
		_noise.frequency = noise_scale * 0.1
@export var noise_octaves: int = 3:
	set(value):
		noise_octaves = value
		_noise.fractal_octaves = noise_octaves
@export var threshold: float = 0.0:
	set(value):
		threshold = value
		_update_info()

## Sculpting
@export_group("Sculpting")
@export var brush_radius: int = 3
@export var auto_sculpt: bool = true
@export var sculpt_speed: float = 2.0

## Colors
@export var voxel_color: Color = Color(0.3, 0.7, 0.4)
@export var height_gradient: bool = true

# Internal
var _voxels: Array = []  # 3D bool array
var _multimesh: MultiMesh
var _multimesh_instance: MultiMeshInstance3D
var _noise: FastNoiseLite
var _active_voxel_count: int = 0
var _sculpt_time: float = 0.0
var _info_label: Label3D

func _ready():
	_init_noise()
	_init_voxels()
	_create_multimesh()
	_create_base()
	_create_labels()
	_generate_initial_terrain()

func _init_noise():
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.frequency = noise_scale * 0.1
	_noise.fractal_octaves = noise_octaves
	_noise.seed = randi()

func _init_voxels():
	_voxels.clear()
	for x in range(grid_size):
		var plane = []
		for y in range(grid_size):
			var row = []
			row.resize(grid_size)
			for z in range(grid_size):
				row[z] = false
			plane.append(row)
		_voxels.append(plane)

func _create_multimesh():
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	
	var max_voxels = grid_size * grid_size * grid_size
	_multimesh.instance_count = max_voxels
	_multimesh.visible_instance_count = 0
	
	var box = BoxMesh.new()
	box.size = Vector3.ONE * voxel_size * 0.95
	_multimesh.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.15
	
	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "VoxelMultiMesh"
	_multimesh_instance.multimesh = _multimesh
	_multimesh_instance.material_override = mat
	add_child(_multimesh_instance)

func _create_base():
	var base = MeshInstance3D.new()
	base.name = "Base"
	
	var total_size = grid_size * voxel_size
	var box = BoxMesh.new()
	box.size = Vector3(total_size + 0.06, 0.03, total_size + 0.06)
	base.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.15)
	mat.metallic = 0.6
	mat.roughness = 0.4
	base.material_override = mat
	
	base.position = Vector3(0, -0.015 - total_size/2, 0)
	add_child(base)

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 24
	var total_size = grid_size * voxel_size
	_info_label.position = Vector3(0, total_size/2 + 0.15, -total_size/2 - 0.08)
	add_child(_info_label)
	_update_info()
	
	var hint = Label3D.new()
	hint.name = "ControlsHint"
	hint.pixel_size = 0.001
	hint.font_size = 18
	hint.text = "↑↓ Threshold | ←→ Scale | R Reset | N New Seed"
	hint.position = Vector3(0, 0.03, total_size/2 + 0.06)
	hint.modulate = Color(0.6, 0.6, 0.6)
	add_child(hint)

func _update_info():
	if _info_label:
		_info_label.text = "PERLIN TERRAIN\nScale: %.1f | Thresh: %.2f\nVoxels: %d" % [noise_scale, threshold, _active_voxel_count]

func _generate_initial_terrain():
	# Generate terrain based on noise
	var half = grid_size / 2.0
	
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				var wx = (x - half) * voxel_size
				var wy = (y - half) * voxel_size
				var wz = (z - half) * voxel_size
				
				var n = _noise.get_noise_3d(wx * 10, wy * 10, wz * 10)
				
				# Height bias - more likely to have voxels at bottom
				var height_bias = (float(y) / grid_size - 0.5) * 0.5
				
				_voxels[x][y][z] = n - height_bias > threshold
	
	_rebuild_multimesh()

func _rebuild_multimesh():
	var half = grid_size / 2.0
	var idx = 0
	_active_voxel_count = 0
	
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				if _voxels[x][y][z]:
					var pos = Vector3(
						(x - half + 0.5) * voxel_size,
						(y - half + 0.5) * voxel_size,
						(z - half + 0.5) * voxel_size
					)
					
					var transform = Transform3D()
					transform.origin = pos
					_multimesh.set_instance_transform(idx, transform)
					
					# Color based on height
					var color = voxel_color
					if height_gradient:
						var t = float(y) / grid_size
						color = voxel_color.lerp(Color(0.8, 0.9, 1.0), t * 0.5)
					_multimesh.set_instance_color(idx, color)
					
					idx += 1
					_active_voxel_count += 1
	
	_multimesh.visible_instance_count = idx
	_update_info()

func _process(delta):
	if auto_sculpt:
		_sculpt_time += delta * sculpt_speed
		# Slowly evolve the noise offset
		_noise.offset = Vector3(_sculpt_time * 0.1, 0, 0)
		
		# Periodically regenerate
		if fmod(_sculpt_time, 2.0) < delta * sculpt_speed:
			_generate_initial_terrain()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				threshold += 0.05
				_generate_initial_terrain()
			KEY_DOWN:
				threshold -= 0.05
				_generate_initial_terrain()
			KEY_LEFT:
				noise_scale = maxf(0.5, noise_scale - 0.5)
				_generate_initial_terrain()
			KEY_RIGHT:
				noise_scale += 0.5
				_generate_initial_terrain()
			KEY_R:
				threshold = 0.0
				noise_scale = 4.0
				_generate_initial_terrain()
			KEY_N:
				_noise.seed = randi()
				_generate_initial_terrain()
			KEY_SPACE:
				auto_sculpt = not auto_sculpt

## Sculpt at world position (for VR controllers)
func sculpt_add(world_pos: Vector3, radius: float = -1):
	if radius < 0:
		radius = brush_radius
	var local_pos = to_local(world_pos)
	_sculpt_sphere(local_pos, radius, true)

func sculpt_remove(world_pos: Vector3, radius: float = -1):
	if radius < 0:
		radius = brush_radius
	var local_pos = to_local(world_pos)
	_sculpt_sphere(local_pos, radius, false)

func _sculpt_sphere(center: Vector3, radius: float, add: bool):
	var half = grid_size / 2.0
	var changed = false
	
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				var pos = Vector3(
					(x - half + 0.5) * voxel_size,
					(y - half + 0.5) * voxel_size,
					(z - half + 0.5) * voxel_size
				)
				
				if pos.distance_to(center) <= radius * voxel_size:
					var n = _noise.get_noise_3d(pos.x * 10, pos.y * 10, pos.z * 10)
					if add:
						if n > threshold - 0.2:
							_voxels[x][y][z] = true
							changed = true
					else:
						if n < threshold + 0.2:
							_voxels[x][y][z] = false
							changed = true
	
	if changed:
		_rebuild_multimesh()

func reset():
	_noise.seed = randi()
	threshold = 0.0
	_generate_initial_terrain()
