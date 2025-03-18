extends Node3D

@export var cube_size: float = 1.0
@export var gutter: float = 0.01
@export var grid_size: int = 14
@export var room_count: int = 2
@export var include_floor: bool = true
@export var opening_position: Vector3i = Vector3i(3, 1, 0)
@export var max_room_placement_attempts: int = 10
@export var corridor_max_steps: int = 1000

@onready var base_cube = $CubeBaseStaticBody3D

var rooms: Array = []
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
	generate_structure()
	print("Structure generated")
	create_rooms()
	print("Rooms created:", rooms.size())
	if rooms.size() >= 2:
		create_corridors()
	print("Corridors done")
	create_opening()
	print("Opening done")

func initialize_grid():
	grid = []
	cube_map.clear()
	for x in grid_size:
		grid.append([])
		for y in grid_size:
			grid[x].append([])
			for z in grid_size:
				grid[x][y].append(false)

func generate_structure():
	var total_size = cube_size + gutter
	print("Generating structure with total_size:", total_size)
	for x in grid_size:
		for y in grid_size:
			for z in grid_size:
				if is_wall_or_ceiling(x, y, z):
					add_cube(x, y, z, total_size)
					grid[x][y][z] = true

func is_wall_or_ceiling(x: int, y: int, z: int) -> bool:
	var outer_x = x == 0 or x == grid_size - 1
	var outer_z = z == 0 or z == grid_size - 1
	var ceiling = y == grid_size - 1
	var floor = y == 0 and include_floor
	return outer_x or outer_z or ceiling or floor

func add_cube(x: int, y: int, z: int, total_size: float):
	var new_cube = base_cube.duplicate()
	new_cube.position = Vector3(x * total_size, y * total_size, z * total_size)
	new_cube.visible = true
	add_child(new_cube)
	if get_tree().edited_scene_root:
		new_cube.owner = get_tree().edited_scene_root
	cube_map[Vector3i(x, y, z)] = new_cube
	print("Added cube at:", Vector3(x, y, z))

func create_rooms():
	for _i in range(room_count):
		var room = generate_room()
		if room:
			rooms.append(room)
			carve_room(room)

func generate_room() -> Dictionary:
	for _attempt in range(max_room_placement_attempts):
		var size = Vector3i(2 + randi() % 2, 2 + randi() % 2, 2 + randi() % 2)
		var pos = Vector3i(
			randi_range(1, grid_size - size.x - 2),
			1,  # Fixed at y=1 to keep rooms low
			randi_range(1, grid_size - size.z - 2)
		)
		# Cap room height to avoid ceiling
		size.y = min(size.y, 4)  # Max height of 4 cubes (doors are 3 high)
		if is_space_free(pos, size):
			return {"pos": pos, "size": size}
	return {}

func is_space_free(pos: Vector3i, size: Vector3i) -> bool:
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			for z in range(pos.z, pos.z + size.z):
				if x >= grid_size or y >= grid_size or z >= grid_size or grid[x][y][z]:
					return false
	return true

func carve_room(room: Dictionary):
	var pos = room.pos
	var size = room.size
	var total_size = cube_size + gutter
	
	# Carve interior
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			for z in range(pos.z, pos.z + size.z):
				grid[x][y][z] = false
				remove_cube_at(x, y, z)
	
	# Add walls, leaving door spaces open later
	for x in range(pos.x, pos.x + size.x):
		for z in range(pos.z, pos.z + size.z):
			if x == pos.x or x == pos.x + size.x - 1 or z == pos.z or z == pos.z + size.z - 1:
				for y in range(pos.y, pos.y + size.y):
					if not grid[x][y][z]:
						add_cube(x, y, z, total_size)
						grid[x][y][z] = true

func create_corridors():
	var astar = AStar3D.new()
	var points = {}
	var id = 0
	
	# Add door positions as connection points (at y=1)
	for i in rooms.size():
		var room = rooms[i]
		# Choose a door position on the Z-facing wall (e.g., front wall at z = pos.z)
		var door_pos = Vector3i(room.pos.x + room.size.x / 2, 1, room.pos.z)
		points[id] = door_pos
		astar.add_point(id, door_pos)
		id += 1
	
	# Connect points within a reasonable distance
	for i in points:
		for j in points:
			if i != j and points[i].distance_to(points[j]) < 8:  # Increased threshold
				astar.connect_points(i, j, true)
	
	# Carve paths between doors
	for i in range(rooms.size() - 1):
		var path = astar.get_point_path(i, i + 1)
		if path.size() > 0:
			for point in path:
				var pos = Vector3i(point.round())
				if is_valid_grid_position(pos):
					if is_room_boundary(pos):
						add_door(pos.x, pos.y, pos.z, cube_size + gutter)
					else:
						# Ensure corridor stays at y=1
						pos.y = 1
						if is_valid_grid_position(pos):
							grid[pos.x][pos.y][pos.z] = false
							remove_cube_at(pos.x, pos.y, pos.z)

func is_valid_grid_position(pos: Vector3i) -> bool:
	return pos.x >= 0 and pos.x < grid_size and \
		   pos.y >= 0 and pos.y < grid_size and \
		   pos.z >= 0 and pos.z < grid_size

func is_room_boundary(pos: Vector3i) -> bool:
	for room in rooms:
		var min_pos = room.pos
		var max_pos = room.pos + room.size - Vector3i.ONE
		if (pos.x == min_pos.x or pos.x == max_pos.x or
			pos.y == min_pos.y or pos.y == max_pos.y or
			pos.z == min_pos.z or pos.z == max_pos.z) and \
		   pos >= min_pos and pos <= max_pos:
			return true
	return false

func add_door(x: int, y: int, z: int, total_size: float):
	# Create a 2-wide, 3-high door
	for dx in range(2):  # 2 cubes wide
		for dy in range(3):  # 3 cubes high
			var door_x = x + dx
			var door_y = y + dy
			var key = Vector3i(door_x, door_y, z)
			if cube_map.has(key) or not is_valid_grid_position(key):
				continue
			
			# Remove existing cubes in door space
			grid[door_x][door_y][z] = false
			remove_cube_at(door_x, door_y, z)
	
	# Place a single large door mesh (or multiple cubes)
	var door = base_cube.duplicate()
	door.scale = Vector3(2.0, 3.0, 1.0)  # 2 wide, 3 high, 1 deep
	door.position = Vector3(x * total_size + total_size / 2, y * total_size + total_size, z * total_size)
	door.visible = true
	add_child(door)
	if get_tree().edited_scene_root:
		door.owner = get_tree().edited_scene_root

	cube_map[Vector3i(x, y, z)] = door  # Store base position only

func create_opening():
	for y_offset in 2:
		var pos = opening_position + Vector3i(0, y_offset, 0)
		if is_valid_grid_position(pos):
			remove_cube_at(pos.x, pos.y, pos.z)
			grid[pos.x][pos.y][pos.z] = false

func remove_cube_at(x: int, y: int, z: int):
	var key = Vector3i(x, y, z)
	if cube_map.has(key):
		var cube = cube_map[key]
		if is_instance_valid(cube):
			cube.queue_free()
		cube_map.erase(key)
