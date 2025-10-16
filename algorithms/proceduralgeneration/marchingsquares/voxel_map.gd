# voxel_map.gd - Voxel map with chunks
extends Node3D

@export var map_size: float = 2.0
@export var voxel_resolution: int = 8
@export var chunk_resolution: int = 2
@export var voxel_material: Material

var chunks: Array = []
var chunk_size: float
var voxel_size: float
var half_size: float

# Stencils
var stencils: Array = []
var fill_type_index: int = 0
var radius_index: int = 0
var stencil_index: int = 0

func _ready():
	half_size = map_size * 0.5
	chunk_size = map_size / float(chunk_resolution)
	voxel_size = chunk_size / float(voxel_resolution)
	
	# Initialize stencils
	stencils = [
		VoxelStencil.new(),
		load("res://voxel_stencil_circle.gd").new()
	]
	
	# Create chunks
	var grid_script = load("res://voxel_grid.gd")
	chunks.resize(chunk_resolution * chunk_resolution)
	
	for y in range(chunk_resolution):
		for x in range(chunk_resolution):
			var i = y * chunk_resolution + x
			create_chunk(i, x, y, grid_script)
	
	# Add collider
	var box = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(map_size, map_size, 0.1)
	box.shape = shape
	box.position = Vector3(0, 0, -0.05)
	
	var static_body = StaticBody3D.new()
	static_body.add_child(box)
	add_child(static_body)

func create_chunk(i: int, x: int, y: int, grid_script):
	var chunk = Node3D.new()
	chunk.set_script(grid_script)
	chunk.voxel_material = voxel_material
	chunk.position = Vector3(
		x * chunk_size - half_size,
		y * chunk_size - half_size,
		0
	)
	add_child(chunk)
	chunk.initialize(voxel_resolution, chunk_size)
	chunks[i] = chunk
	
	# Set up neighbors
	if x > 0:
		chunks[i - 1].x_neighbor = chunk
	if y > 0:
		chunks[i - chunk_resolution].y_neighbor = chunk
		if x > 0:
			chunks[i - chunk_resolution - 1].xy_neighbor = chunk

func _process(_delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var camera = get_viewport().get_camera_3d()
		if camera:
			var from = camera.project_ray_origin(get_viewport().get_mouse_position())
			var to = from + camera.project_ray_normal(get_viewport().get_mouse_position()) * 1000
			
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(from, to)
			var result = space_state.intersect_ray(query)
			
			if result and result.collider.get_parent() == self:
				edit_voxels(to_local(result.position))

func edit_voxels(point: Vector3):
	var center_x = int((point.x + half_size) / voxel_size)
	var center_y = int((point.y + half_size) / voxel_size)
	
	var x_start = (center_x - radius_index - 1) / voxel_resolution
	x_start = max(0, x_start)
	var x_end = (center_x + radius_index) / voxel_resolution
	x_end = min(chunk_resolution - 1, x_end)
	
	var y_start = (center_y - radius_index - 1) / voxel_resolution
	y_start = max(0, y_start)
	var y_end = (center_y + radius_index) / voxel_resolution
	y_end = min(chunk_resolution - 1, y_end)
	
	var active_stencil = stencils[stencil_index]
	active_stencil.initialize(fill_type_index == 0, radius_index)
	
	var voxel_y_offset = y_end * voxel_resolution
	for y in range(y_end, y_start - 1, -1):
		var chunk_i = y * chunk_resolution + x_end
		var voxel_x_offset = x_end * voxel_resolution
		
		for x in range(x_end, x_start - 1, -1):
			active_stencil.set_center(
				center_x - voxel_x_offset,
				center_y - voxel_y_offset
			)
			chunks[chunk_i].apply(active_stencil)
			voxel_x_offset -= voxel_resolution
			chunk_i -= 1
		
		voxel_y_offset -= voxel_resolution

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_6:
			radius_index = event.keycode - KEY_1
		elif event.keycode == KEY_F:
			fill_type_index = 0
		elif event.keycode == KEY_E:
			fill_type_index = 1
		elif event.keycode == KEY_S:
			stencil_index = 0
		elif event.keycode == KEY_C:
			stencil_index = 1
