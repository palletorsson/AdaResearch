extends Node3D

@export var cube_size: float = 1.0
@export var gutter: float = 0.0
@export var grid_y: int = 6  # Fixed height

var grid_x: int = 11 # Fixed width to match layout
var grid_z: int = 11  # Fixed depth to match layout
@export var x_ranges: Array = ["10_11", "9_11", "8_11", "7_11", "6_11", "5_11", "4_11", "3_11", "2_10", "1_10", "1_10"]

@onready var base_cube = $CubeBaseStaticBody3D

var grid: Array = []
var cube_map: Dictionary = {}

func _ready():
	if not base_cube:
		push_error("Base cube not found!")
		return
	
	print("Starting initialization")
	base_cube.visible = false
	initialize_grid()
	print("Grid initialized")
	apply_layout_data()
	print("Layout data applied")

func initialize_grid():
	grid = []
	cube_map.clear()
	for x in grid_x:
		grid.append([])
		for y in grid_y:
			grid[x].append([])
			for z in grid_z:
				grid[x][y].append(false)

func add_cube(x: int, y: int, z: int, total_size: float):
	var new_cube = base_cube.duplicate()
	new_cube.position = Vector3(x * total_size, y * total_size, z * total_size)
	new_cube.visible = true
	add_child(new_cube)
	if get_tree() and get_tree().edited_scene_root:
		new_cube.owner = get_tree().edited_scene_root
	cube_map[Vector3i(x, y, z)] = new_cube
	print("Added cube at:", Vector3(x, y, z))

func apply_layout_data():
	var total_size = cube_size + gutter
	
	# Apply layout data based on x_ranges
	for z in grid_z:
		var range_str = x_ranges[z]
		var range_parts = range_str.split("_")
		if range_parts.size() != 2:
			push_error("Invalid range format at Z=" + str(z))
			continue
		var x_start = int(range_parts[0])
		var x_end = int(range_parts[1])
		
		for x in grid_x:
			# Add floor at y=0 unless outside range (treated as 'x')
			if x < x_start or x >= x_end:
				# 'x' behavior: no floor or structure
				continue
			if 0 < grid_y:
				add_cube(0, x, z, total_size)
				grid[x][0][0] = true
			
	
func remove_cube_at(x: int, y: int, z: int):
	var key = Vector3i(x, y, z)
	if cube_map.has(key):
		var cube = cube_map[key]
		if is_instance_valid(cube):
			cube.queue_free()
		cube_map.erase(key)
