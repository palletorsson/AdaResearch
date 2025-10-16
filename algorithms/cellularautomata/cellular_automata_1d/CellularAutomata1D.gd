extends Node3D

# Preload the cube scene
const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

var time = 0.0
var grid_width = 20  # Width of each wall (20 cubes at 0.5m = 10m)
var grid_height = 20  # Height of each wall (20 cubes at 0.5m = 10m)
var cube_size = 0.55  # Spacing for 0.5m cubes with small gap
var current_generation = 0
var generation_timer = 0.0
var generation_interval = 0.5
var rule_timer = 0.0
var rule_interval = 15.0

# Four walls with different rules
var walls = []  # Array of wall data {cells, current_state, history, rule, direction}
var wall_rules = [30, 110, 90, 150]  # Different rule for each wall
var wall_names = ["North", "South", "East", "West"]

func _ready():
	print("Cellular Automata 1D - Wall Pattern initialized")
	# Remove unused nodes
	if has_node("RuleTable"):
		$RuleTable.queue_free()
	if has_node("GenerationIndicator"):
		$GenerationIndicator.queue_free()
	if has_node("RuleNumber"):
		$RuleNumber.queue_free()

	create_four_walls()
	initialize_all_walls()

func create_four_walls():
	# Create parent node for walls
	var walls_parent = $AutomatonGrid

	# Create 4 walls arranged in a square (10x10 meter space)
	for wall_idx in range(4):
		var wall_data = {
			"cells": [],
			"current_state": [],
			"history": [],
			"rule": wall_rules[wall_idx],
			"name": wall_names[wall_idx],
			"parent": Node3D.new()
		}

		walls_parent.add_child(wall_data["parent"])

		# Create grid for this wall
		for y in range(grid_height):
			wall_data["cells"].append([])
			for x in range(grid_width):
				# Only create cells for alive states initially (will be created dynamically)
				wall_data["cells"][y].append(null)

		walls.append(wall_data)

func initialize_all_walls():
	# Initialize each wall with a starting pattern
	for wall_idx in range(4):
		var wall = walls[wall_idx]
		wall["current_state"].clear()
		wall["history"].clear()

		# Initialize state
		for i in range(grid_width):
			wall["current_state"].append(0)

		# Set center cell to 1 for starting pattern
		wall["current_state"][grid_width / 2] = 1
		wall["history"].append(wall["current_state"].duplicate())

	current_generation = 0
	update_all_walls_display()

func _process(delta):
	time += delta
	generation_timer += delta
	rule_timer += delta

	# Generate next generation
	if generation_timer >= generation_interval and current_generation < grid_height - 1:
		generation_timer = 0.0
		generate_next_generation_all_walls()

	# Reset when complete
	if rule_timer >= rule_interval:
		rule_timer = 0.0
		reset_all_walls()

	animate_walls(delta)

func generate_next_generation_all_walls():
	# Generate next generation for each wall with its own rule
	for wall in walls:
		var new_state = []

		for i in range(grid_width):
			# Get neighborhood (left, center, right)
			var left = wall["current_state"][(i - 1 + grid_width) % grid_width]
			var center = wall["current_state"][i]
			var right = wall["current_state"][(i + 1) % grid_width]

			# Apply wall-specific rule
			var neighborhood = left * 4 + center * 2 + right
			var new_cell = apply_rule(neighborhood, wall["rule"])
			new_state.append(new_cell)

		wall["current_state"] = new_state
		wall["history"].append(wall["current_state"].duplicate())

	current_generation += 1
	update_all_walls_display()

func apply_rule(neighborhood: int, rule_number: int) -> int:
	# Apply elementary cellular automaton rule
	return (rule_number >> neighborhood) & 1

func reset_all_walls():
	# Reset and optionally rotate rules
	initialize_all_walls()

func update_all_walls_display():
	# Update display for all 4 walls
	for wall_idx in range(4):
		update_wall_display(wall_idx)

func update_wall_display(wall_idx: int):
	var wall = walls[wall_idx]

	# Update all visible generations for this wall
	for gen in range(min(wall["history"].size(), grid_height)):
		var generation = wall["history"][gen]

		for x in range(grid_width):
			var cell_state = generation[x]

			if cell_state == 1:
				# Create or update alive cell
				if wall["cells"][gen][x] == null:
					var cell = CUBE_SCENE.instantiate()
					# Scale to 0.5x0.5x0.5 meters
					cell.scale = Vector3(0.5, 0.5, 0.5)

					# Calculate position based on wall
					# Start at top (y=5) and work down to floor (y=-5)
					var world_pos = Vector3.ZERO
					var y_pos = 5.0 - (gen * cube_size)  # Start at top, go down

					match wall_idx:
						0:  # North wall (facing south, at Z = -5.25)
							world_pos = Vector3((x - grid_width/2.0 + 0.5) * cube_size, y_pos, -5.25)
						1:  # South wall (facing north, at Z = 5.25)
							world_pos = Vector3((x - grid_width/2.0 + 0.5) * cube_size, y_pos, 5.25)
						2:  # East wall (facing west, at X = 5.25)
							world_pos = Vector3(5.25, y_pos, (x - grid_width/2.0 + 0.5) * cube_size)
						3:  # West wall (facing east, at X = -5.25)
							world_pos = Vector3(-5.25, y_pos, (x - grid_width/2.0 + 0.5) * cube_size)

					cell.position = world_pos

					# Keep default cube color (no color changes)

					wall["parent"].add_child(cell)
					wall["cells"][gen][x] = cell
			else:
				# Remove dead cell (make it black/empty)
				if wall["cells"][gen][x] != null:
					wall["cells"][gen][x].queue_free()
					wall["cells"][gen][x] = null

func get_wall_color(wall_idx: int) -> Color:
	# Different color for each wall based on its rule
	match wall_idx:
		0:  # North - Rule 30 (Chaotic) - Orange
			return Color(1.0, 0.6, 0.2, 1.0)
		1:  # South - Rule 110 (Turing Complete) - Cyan
			return Color(0.2, 1.0, 0.8, 1.0)
		2:  # East - Rule 90 (Sierpinski) - Magenta
			return Color(1.0, 0.2, 0.8, 1.0)
		3:  # West - Rule 150 (Balanced) - Yellow-Green
			return Color(0.8, 1.0, 0.2, 1.0)
		_:
			return Color(1.0, 1.0, 1.0, 1.0)

func animate_walls(delta):
	# Animate current generation row on all walls
	if current_generation < grid_height:
		for wall in walls:
			for x in range(grid_width):
				var cell = wall["cells"][current_generation][x]
				if cell != null:
					# Pulse animation for newest generation
					var pulse = 1.0 + sin(time * 5.0 + x * 0.3) * 0.15
					cell.scale = Vector3.ONE * pulse
