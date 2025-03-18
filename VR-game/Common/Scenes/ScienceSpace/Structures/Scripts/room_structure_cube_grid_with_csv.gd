@tool
extends Node3D

@export var cube_size: float = 1.0
@export var gutter: float = 0.0
@export var grid_y: int = 6  # Only y is fixed now
@export var showgrid: bool = false  

var grid_x: int  # Will be set dynamically
var grid_z: int  # Will be set dynamically

@onready var base_cube = $CubeBaseStaticBody3D
@onready var layout_data_script = preload("res://adaresearch/Common/Data/Csv/layout_data.gd").new()

var grid: Array = []
var cube_map: Dictionary = {}

func _ready():
	if not base_cube:
		push_error("Base cube not found!")
		return
	
	# Set grid dimensions from layout_data (both editor and game)
	var layout = layout_data_script.layout_data
	grid_z = layout.size()
	grid_x = layout[0].size() if layout.size() > 0 else 0
	print("Grid dimensions set to: x=", grid_x, " y=", grid_y, " z=", grid_z)
	
	# Initialize and generate the layout
	#if Engine.is_editor_hint():
		#print("Editor initialization")
		#if showgrid:
			#generate_layout()  # Generate once in editor on load
	#else:
	print("Game initialization")
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
	var layout = layout_data_script.layout_data
	var total_size = cube_size + gutter
	
	# Apply layout data, adding floor unless 'x'
	for z in grid_z:
		var row = layout[z]
		for x in grid_x:
			var cell = row[x].strip_edges()
			# Add floor at y=0 unless cell is 'x'
			if cell != "x" and 0 < grid_y:
				add_cube(x, 0, z, total_size)
				grid[x][0][z] = true
			
			# Apply structures on top of floor
			match cell:
				"w":  # Wall: 4 cubes stacked on top of floor
					for y in range(1, 5):
						if y < grid_y:
							add_cube(x, y, z, total_size)
							grid[x][y][z] = true
				"t":  # Table: 1 cube at y=1 on top of floor
					if 1 < grid_y:
						add_cube(x, 1, z, total_size)
						grid[x][1][z] = true
				"o":  # Opening: 2 cubes at y=3 and y=4
					for y in range(3, 5):
						if y < grid_y:
							add_cube(x, y, z, total_size)
							grid[x][y][z] = true
				"c":  # Corridor: 1 cube at y=4
					if 4 < grid_y:
						add_cube(x, 4, z, total_size)
						grid[x][4][z] = true
				"x":  # No floor, no structure
					pass
				" ":  # Empty: Just the floor at y=0
					pass

func remove_cube_at(x: int, y: int, z: int):
	var key = Vector3i(x, y, z)
	if cube_map.has(key):
		var cube = cube_map[key]
		if is_instance_valid(cube):
			cube.queue_free()
		cube_map.erase(key)

func generate_layout():
	if not base_cube:
		print("Base cube not found in editor!")
		return
	
	# Clear existing cubes
	for key in cube_map.keys():
		remove_cube_at(key.x, key.y, key.z)
	
	# Set grid dimensions from layout_data
	var layout = layout_data_script.layout_data
	grid_z = layout.size()
	grid_x = layout[0].size() if layout.size() > 0 else 0
	print("Grid dimensions set to: x=", grid_x, " y=", grid_y, " z=", grid_z)
	
	initialize_grid()
	apply_layout_data()

func _set(property, value):
	if property in ["cube_size", "gutter", "grid_y"]:
		set(property, value)
		if Engine.is_editor_hint():
			generate_layout()
		return true
	return false
