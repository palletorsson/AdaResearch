extends Node3D

var time = 0.0
var grid_size = 12
var wfc_grid = []
var tile_types = ["empty", "wall", "floor", "corner"]
var adjacency_rules = {}
var collapsed_cells = 0
var generation_timer = 0.0
var generation_interval = 0.2

class WFCCell:
	var possible_states: Array
	var collapsed_state: String = ""
	var entropy: int
	var visual_object: CSGBox3D
	var position: Vector2
	
	func _init(pos: Vector2, states: Array):
		position = pos
		possible_states = states.duplicate()
		entropy = possible_states.size()

func _ready():
	setup_adjacency_rules()
	create_wfc_grid()
	setup_materials()
	start_wfc_generation()

func setup_adjacency_rules():
	# Define which tiles can be adjacent to each other
	adjacency_rules = {
		"empty": ["empty", "wall"],
		"wall": ["empty", "wall", "corner"],
		"floor": ["floor", "corner"],
		"corner": ["wall", "floor", "corner"]
	}

func create_wfc_grid():
	var grid_parent = $WFCGrid
	
	for x in range(grid_size):
		wfc_grid.append([])
		for y in range(grid_size):
			var cell_pos = Vector2(x, y)
			var cell = WFCCell.new(cell_pos, tile_types)
			
			# Create visual representation
			var cell_box = CSGBox3D.new()
			cell_box.size = Vector3(0.3, 0.3, 0.3)
			cell_box.position = Vector3(
				-3 + x * 0.5,
				-3 + y * 0.5,
				0
			)
			grid_parent.add_child(cell_box)
			cell.visual_object = cell_box
			
			wfc_grid[x].append(cell)

func setup_materials():
	# Entropy indicator material
	var entropy_material = StandardMaterial3D.new()
	entropy_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	entropy_material.emission_enabled = true
	entropy_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$EntropyIndicator.material_override = entropy_material
	
	# Collapse progress material
	var progress_material = StandardMaterial3D.new()
	progress_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	progress_material.emission_enabled = true
	progress_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$CollapseProgress.material_override = progress_material

func start_wfc_generation():
	collapsed_cells = 0
	
	# Reset all cells
	for x in range(grid_size):
		for y in range(grid_size):
			var cell = wfc_grid[x][y]
			cell.possible_states = tile_types.duplicate()
			cell.collapsed_state = ""
			cell.entropy = tile_types.size()
	
	update_all_visuals()

func _process(delta):
	time += delta
	generation_timer += delta
	
	if generation_timer >= generation_interval:
		generation_timer = 0.0
		wfc_step()
	
	animate_wfc()
	animate_indicators()

func wfc_step():
	if collapsed_cells >= grid_size * grid_size:
		# Reset and start over
		start_wfc_generation()
		return
	
	# Find cell with minimum entropy > 0
	var min_entropy = INF
	var candidates = []
	
	for x in range(grid_size):
		for y in range(grid_size):
			var cell = wfc_grid[x][y]
			if cell.collapsed_state == "" and cell.entropy > 0:
				if cell.entropy < min_entropy:
					min_entropy = cell.entropy
					candidates.clear()
					candidates.append(cell)
				elif cell.entropy == min_entropy:
					candidates.append(cell)
	
	if candidates.size() == 0:
		return
	
	# Randomly select from candidates
	var selected_cell = candidates[randi() % candidates.size()]
	
	# Collapse the cell
	collapse_cell(selected_cell)
	
	# Propagate constraints
	propagate_constraints(selected_cell)

func collapse_cell(cell: WFCCell):
	if cell.possible_states.size() == 0:
		return
	
	# Randomly choose from possible states
	var chosen_state = cell.possible_states[randi() % cell.possible_states.size()]
	cell.collapsed_state = chosen_state
	cell.possible_states = [chosen_state]
	cell.entropy = 0
	
	collapsed_cells += 1
	update_cell_visual(cell)

func propagate_constraints(changed_cell: WFCCell):
	# Get neighbors and update their possible states
	var neighbors = get_neighbors(changed_cell.position)
	
	for neighbor in neighbors:
		if neighbor.collapsed_state != "":
			continue
		
		var new_possible_states = []
		for state in neighbor.possible_states:
			if can_be_adjacent(changed_cell.collapsed_state, state):
				new_possible_states.append(state)
		
		if new_possible_states.size() != neighbor.possible_states.size():
			neighbor.possible_states = new_possible_states
			neighbor.entropy = neighbor.possible_states.size()
			update_cell_visual(neighbor)
			
			# Recursive propagation if needed
			if neighbor.entropy == 1:
				collapse_cell(neighbor)

func get_neighbors(pos: Vector2) -> Array:
	var neighbors = []
	var directions = [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)]
	
	for dir in directions:
		var neighbor_pos = pos + dir
		if neighbor_pos.x >= 0 and neighbor_pos.x < grid_size and neighbor_pos.y >= 0 and neighbor_pos.y < grid_size:
			neighbors.append(wfc_grid[neighbor_pos.x][neighbor_pos.y])
	
	return neighbors

func can_be_adjacent(state1: String, state2: String) -> bool:
	return state2 in adjacency_rules.get(state1, [])

func update_cell_visual(cell: WFCCell):
	var material = StandardMaterial3D.new()
	
	if cell.collapsed_state != "":
		# Collapsed state
		match cell.collapsed_state:
			"empty":
				material.albedo_color = Color(0.8, 0.8, 0.8, 0.3)
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			"wall":
				material.albedo_color = Color(0.6, 0.3, 0.2, 1.0)
			"floor":
				material.albedo_color = Color(0.4, 0.8, 0.4, 1.0)
			"corner":
				material.albedo_color = Color(0.8, 0.6, 0.2, 1.0)
	else:
		# Uncollapsed - color based on entropy
		var entropy_ratio = float(cell.entropy) / tile_types.size()
		material.albedo_color = Color(
			1.0 - entropy_ratio * 0.5,
			entropy_ratio,
			0.5,
			0.8
		)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.3
	cell.visual_object.material_override = material

func update_all_visuals():
	for x in range(grid_size):
		for y in range(grid_size):
			update_cell_visual(wfc_grid[x][y])

func animate_wfc():
	# Animate cells based on their state
	for x in range(grid_size):
		for y in range(grid_size):
			var cell = wfc_grid[x][y]
			
			if cell.collapsed_state == "":
				# Uncollapsed cells pulse based on entropy
				var pulse = 1.0 + sin(time * 5.0 + cell.entropy) * 0.3
				cell.visual_object.scale = Vector3.ONE * pulse
			else:
				# Collapsed cells have gentle wave
				var wave = 1.0 + sin(time * 3.0 + x + y) * 0.1
				cell.visual_object.scale = Vector3.ONE * wave

func animate_indicators():
	# Entropy indicator (average entropy)
	var total_entropy = 0.0
	var uncollapsed_count = 0
	
	for x in range(grid_size):
		for y in range(grid_size):
			var cell = wfc_grid[x][y]
			if cell.collapsed_state == "":
				total_entropy += cell.entropy
				uncollapsed_count += 1
	
	var avg_entropy = total_entropy / max(uncollapsed_count, 1)
	var entropy_height = (avg_entropy / tile_types.size()) * 2.0 + 0.5
	var entropyindicator = get_node_or_null("EntropyIndicator")
	if entropyindicator and entropyindicator is CSGCylinder3D:
		entropyindicator.height = entropy_height
		entropyindicator.position.y = -3 + entropy_height/2
	
	# Collapse progress indicator
	var progress = float(collapsed_cells) / (grid_size * grid_size)
	var progress_height = progress * 2.0 + 0.5
	$CollapseProgress.size.y = progress_height
	$CollapseProgress.position.y = -3 + progress_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$EntropyIndicator.scale.x = pulse
	$CollapseProgress.scale.x = pulse

func get_wfc_info() -> Dictionary:
	var total_entropy = 0
	for x in range(grid_size):
		for y in range(grid_size):
			total_entropy += wfc_grid[x][y].entropy
	
	return {
		"collapsed_cells": collapsed_cells,
		"total_cells": grid_size * grid_size,
		"progress": float(collapsed_cells) / (grid_size * grid_size),
		"total_entropy": total_entropy
	}
