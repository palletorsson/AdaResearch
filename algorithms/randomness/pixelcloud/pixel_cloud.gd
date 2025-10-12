extends Node3D

@export var grid_size: int = 16
@export var num_cubes: int = 23
@export var cube_spacing: float = 1.0
@export var upward_bias: float = 3.0  # Higher = more upward movement

var cube_scene = preload("res://commons/primitives/cubes/cube_scene.tscn")
var occupied_cells: Dictionary = {}
var walker_path: Array[Vector3i] = []

# Directions: up, right, forward, left, back, down (3D space)
var directions: Array[Vector3i] = [
	Vector3i(0, 1, 0),   # up
	Vector3i(1, 0, 0),   # right
	Vector3i(0, 0, 1),   # forward
	Vector3i(-1, 0, 0),  # left
	Vector3i(0, 0, -1),  # back
	Vector3i(0, -1, 0)   # down
]

func _ready() -> void:
	generate_pixel_cloud()

func generate_pixel_cloud() -> void:
	# Start at bottom center of grid
	var start_pos = Vector3i(grid_size / 2, 0, grid_size / 2)
	walker_path.clear()
	occupied_cells.clear()

	# Perform self-avoiding walk
	self_avoiding_walk(start_pos, num_cubes)

	# Place cubes along the path
	place_cubes()

func self_avoiding_walk(start: Vector3i, steps: int) -> void:
	var current = start
	walker_path.append(current)
	occupied_cells[current] = true

	for i in range(steps - 1):
		var valid_moves: Array[Vector3i] = []
		var move_weights: Array[float] = []

		# Find all valid adjacent cells with bias weights
		for dir in directions:
			var next = current + dir

			# Check bounds and if cell is unoccupied
			if is_valid_position(next) and not occupied_cells.has(next):
				valid_moves.append(next)

				# Apply upward bias (Y+ direction gets higher weight)
				var weight = 1.0
				if dir.y > 0:  # Moving up
					weight = upward_bias
				move_weights.append(weight)

		# If no valid moves, stop (walker is trapped)
		if valid_moves.is_empty():
			print("Walker trapped after ", walker_path.size(), " steps")
			break

		# Choose weighted random move
		var next_pos = weighted_random_choice(valid_moves, move_weights)
		current = next_pos
		walker_path.append(current)
		occupied_cells[current] = true

	print("Generated path with ", walker_path.size(), " cubes")

func weighted_random_choice(choices: Array[Vector3i], weights: Array[float]) -> Vector3i:
	var total_weight = 0.0
	for w in weights:
		total_weight += w

	var rand_val = randf() * total_weight
	var cumulative = 0.0

	for i in range(choices.size()):
		cumulative += weights[i]
		if rand_val <= cumulative:
			return choices[i]

	return choices[-1]

func is_valid_position(pos: Vector3i) -> bool:
	return pos.x >= 0 and pos.x < grid_size and \
		   pos.y >= 0 and pos.y < grid_size and \
		   pos.z >= 0 and pos.z < grid_size

func place_cubes() -> void:
	for grid_pos in walker_path:
		var cube = cube_scene.instantiate()
		add_child(cube)

		# Convert grid position to 3D world position
		# Center the grid around origin
		var x = (grid_pos.x - grid_size / 2.0) * cube_spacing
		var y = grid_pos.y * cube_spacing
		var z = (grid_pos.z - grid_size / 2.0) * cube_spacing

		cube.position = Vector3(x, y, z)

func _input(event: InputEvent) -> void:
	# Press R to regenerate
	if event.is_action_pressed("ui_accept"):
		# Clear existing cubes
		for child in get_children():
			child.queue_free()
		generate_pixel_cloud()
