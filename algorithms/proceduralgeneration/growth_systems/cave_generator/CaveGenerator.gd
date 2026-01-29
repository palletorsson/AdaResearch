extends Node3D

@export var grid_size = 40
@export var initial_fill_percentage = 0.45
@export var generations = 5

var grid = []
var multimesh_instance: MultiMeshInstance3D

func _ready():
	multimesh_instance = $MultiMeshInstance3D
	initialize_grid()
	run_simulation()
	update_multimesh()

func initialize_grid():
	grid.resize(grid_size)
	for x in range(grid_size):
		grid[x] = []
		grid[x].resize(grid_size)
		for y in range(grid_size):
			grid[x][y] = []
			grid[x][y].resize(grid_size)
			for z in range(grid_size):
				if randf() < initial_fill_percentage:
					grid[x][y][z] = 1
				else:
					grid[x][y][z] = 0

func run_simulation():
	for i in range(generations):
		var next_grid = []
		next_grid.resize(grid_size)
		for x in range(grid_size):
			next_grid[x] = []
			next_grid[x].resize(grid_size)
			for y in range(grid_size):
				next_grid[x][y] = []
				next_grid[x][y].resize(grid_size)
				for z in range(grid_size):
					var neighbors = count_neighbors(x, y, z)
					if grid[x][y][z] == 1:
						if neighbors >= 4:
							next_grid[x][y][z] = 1
						else:
							next_grid[x][y][z] = 0
					else:
						if neighbors >= 5:
							next_grid[x][y][z] = 1
						else:
							next_grid[x][y][z] = 0
		grid = next_grid

func count_neighbors(x, y, z):
	var count = 0
	for i in range(-1, 2):
		for j in range(-1, 2):
			for k in range(-1, 2):
				if i == 0 and j == 0 and k == 0:
					continue
				var nx = x + i
				var ny = y + j
				var nz = z + k
				if nx >= 0 and nx < grid_size and ny >= 0 and ny < grid_size and nz >= 0 and nz < grid_size:
					if grid[nx][ny][nz] == 1:
						count += 1
	return count

func update_multimesh():
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(1, 1, 1)
	var multimesh = MultiMesh.new()
	multimesh.mesh = cube_mesh
	# Ensure we can set 3D transforms on instances
	multimesh.transform_format = MultiMesh.TRANSFORM_3D

	var instance_count = 0
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				if grid[x][y][z] == 1:
					instance_count += 1

	multimesh.instance_count = instance_count
	var instance_index = 0
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				if grid[x][y][z] == 1:
					var transform = Transform3D().translated(Vector3(x, y, z))
					multimesh.set_instance_transform(instance_index, transform)
					instance_index += 1

	multimesh_instance.multimesh = multimesh
