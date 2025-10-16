extends Node3D

const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

@export var grid_size = 20
@export var generation_interval = 0.5

enum GrowthPhase { OUT, UP }
var current_phase = GrowthPhase.OUT
var generation = 0
var current_layer = 0
var grid = []
var generation_timer = 0.0

func _ready():
	initialize_grid()

func _process(delta):
	generation_timer += delta
	if generation_timer >= generation_interval:
		generation_timer = 0.0
		generate_next_layer()

func initialize_grid():
	grid.resize(grid_size)
	for i in range(grid_size):
		grid[i] = []
		grid[i].resize(grid_size)
		for j in range(grid_size):
			grid[i][j] = []
			grid[i][j].resize(grid_size)
			for k in range(grid_size):
				grid[i][j][k] = 0
	
	var start_x = (grid_size - 4) / 2
	var start_z = (grid_size - 4) / 2
	for x in range(start_x, start_x + 4):
		for z in range(start_z, start_z + 4):
			grid[x][0][z] = 1
			create_cube(x, 0, z)

func generate_next_layer():
	generation += 1
	if generation >= 10:
		set_process(false)
		return
	
	match current_phase:
		GrowthPhase.OUT:
			if generation < 4:
				grow_outward()
			else:
				current_phase = GrowthPhase.UP
		GrowthPhase.UP:
			grow_upward()

func grow_outward():
	current_layer += 1
	for x in range(grid_size):
		for z in range(grid_size):
			var neighbors = count_neighbors(current_layer - 1, x, z)
			var current_state = grid[x][current_layer - 1][z]
			var new_state = apply_rules(current_state, neighbors)
			grid[x][current_layer][z] = new_state
			if new_state == 1:
				create_cube(x, current_layer, z)

func grow_upward():
	current_layer += 1
	for x in range(grid_size):
		for z in range(grid_size):
			grid[x][current_layer][z] = grid[x][current_layer - 1][z]
			if grid[x][current_layer][z] == 1:
				create_cube(x, current_layer, z)

func count_neighbors(layer, x, z):
	var count = 0
	for i in range(-1, 2):
		for j in range(-1, 2):
			if i == 0 and j == 0:
				continue
			var nx = x + i
			var nz = z + j
			if nx >= 0 and nx < grid_size and nz >= 0 and nz < grid_size:
				if grid[nx][layer][nz] == 1:
					count += 1
	return count

func apply_rules(current_state, neighbors):
	if current_state == 1:
		if neighbors < 2 or neighbors > 3:
			return 0
		else:
			return 1
	else:
		if neighbors == 3:
			return 1
		else:
			return 0

func create_cube(x, y, z):
	var cell = CUBE_SCENE.instantiate()
	cell.name = "cell_" + str(x) + "_" + str(y) + "_" + str(z)
	cell.scale = Vector3(0.5, 0.5, 0.5)
	var pos_x = (x - grid_size / 2.0) * 0.5
	var pos_y = y * 0.5
	var pos_z = (z - grid_size / 2.0) * 0.5
	cell.position = Vector3(pos_x, pos_y, pos_z)
	add_child(cell)
