extends Node3D

var time = 0.0
var grid_size = 8  # Reduced for clearer visualization
var wfc_grid = []
var tile_types = ["empty", "wall", "floor", "corner"]
var adjacency_rules = {}
var collapsed_cells = 0
var generation_timer = 0.0
var generation_interval = 1.0  # Slower for observation

# Visualization state
var propagation_wave: Array = []  # Cells currently being affected by propagation
var min_entropy_candidates: Array = []  # Current candidates for selection
var currently_collapsing_cell = null  # Cell being collapsed this frame
var propagation_timer: float = 0.0
var selection_highlight_timer: float = 0.0
var is_selecting: bool = false

# Colors for tile types (for superposition visualization)
var tile_colors = {
	"empty": Color(0.8, 0.8, 0.8, 0.6),
	"wall": Color(0.6, 0.3, 0.2, 1.0),
	"floor": Color(0.4, 0.8, 0.4, 1.0),
	"corner": Color(0.8, 0.6, 0.2, 1.0)
}

class WFCCell:
	var possible_states: Array
	var collapsed_state: String = ""
	var entropy: int
	var visual_object: CSGBox3D
	var position: Vector2
	var entropy_label: Label3D  # NEW: Show entropy number
	var superposition_visuals: Array = []  # NEW: Mini-tiles showing possible states
	var is_candidate: bool = false  # NEW: Is min entropy candidate
	var propagation_highlight: float = 0.0  # NEW: Highlight from propagation wave

	func _init(pos: Vector2, states: Array):
		position = pos
		possible_states = states.duplicate()
		entropy = possible_states.size()

func _ready():
	setup_adjacency_rules()
	create_wfc_grid()
	setup_materials()
	create_adjacency_legend()  # NEW: Visual reference of rules
	create_concept_labels()    # NEW: Labels explaining what's happening
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
	var cell_spacing = 0.8  # Larger spacing for clarity
	var offset = -grid_size * cell_spacing / 2.0

	for x in range(grid_size):
		wfc_grid.append([])
		for y in range(grid_size):
			var cell_pos = Vector2(x, y)
			var cell = WFCCell.new(cell_pos, tile_types)

			# Create cell container
			var cell_container = Node3D.new()
			cell_container.position = Vector3(
				offset + x * cell_spacing + cell_spacing/2,
				offset + y * cell_spacing + cell_spacing/2,
				0
			)
			grid_parent.add_child(cell_container)

			# Main visual box
			var cell_box = CSGBox3D.new()
			cell_box.size = Vector3(0.5, 0.5, 0.3)
			cell_container.add_child(cell_box)
			cell.visual_object = cell_box

			# Entropy label (shows uncertainty level)
			var entropy_label = Label3D.new()
			entropy_label.text = str(cell.entropy)
			entropy_label.font_size = 32
			entropy_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			entropy_label.position = Vector3(0, 0, 0.2)
			entropy_label.modulate = Color(1, 1, 1, 0.9)
			entropy_label.outline_size = 6
			cell_container.add_child(entropy_label)
			cell.entropy_label = entropy_label

			# Create superposition visuals (mini-tiles for each possible state)
			cell.superposition_visuals = create_superposition_display(cell_container, cell.possible_states)

			wfc_grid[x].append(cell)

func create_superposition_display(parent: Node3D, possible_states: Array) -> Array:
	# Create mini-tile representations for superposition
	var visuals = []
	var positions = [
		Vector3(-0.15, 0.15, 0.15),  # top-left
		Vector3(0.15, 0.15, 0.15),   # top-right
		Vector3(-0.15, -0.15, 0.15), # bottom-left
		Vector3(0.15, -0.15, 0.15)   # bottom-right
	]

	for i in range(tile_types.size()):
		var mini_tile = CSGBox3D.new()
		mini_tile.size = Vector3(0.12, 0.12, 0.08)
		if i < positions.size():
			mini_tile.position = positions[i]
		else:
			mini_tile.position = Vector3(0, 0, 0.15)

		var mat = StandardMaterial3D.new()
		var tile_type = tile_types[i]
		mat.albedo_color = tile_colors.get(tile_type, Color.WHITE)
		mat.emission_enabled = true
		mat.emission = mat.albedo_color * 0.3
		mini_tile.material_override = mat
		mini_tile.visible = tile_type in possible_states

		parent.add_child(mini_tile)
		visuals.append({"tile": mini_tile, "type": tile_type})

	return visuals

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

func create_adjacency_legend():
	# Show the adjacency rules visually
	var legend_parent = Node3D.new()
	legend_parent.name = "AdjacencyLegend"
	legend_parent.position = Vector3(6, 2, 0)
	add_child(legend_parent)

	# Title
	var title = Label3D.new()
	title.text = "ADJACENCY RULES"
	title.font_size = 28
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.position = Vector3(0, 2, 0)
	title.outline_size = 4
	legend_parent.add_child(title)

	# Show each tile type and what it can be next to
	var y_offset = 1.2
	for tile_type in tile_types:
		var row = Node3D.new()
		row.position = Vector3(0, y_offset, 0)
		legend_parent.add_child(row)

		# Source tile
		var source = CSGBox3D.new()
		source.size = Vector3(0.4, 0.4, 0.2)
		source.position = Vector3(-1.5, 0, 0)
		var source_mat = StandardMaterial3D.new()
		source_mat.albedo_color = tile_colors.get(tile_type, Color.WHITE)
		source_mat.emission_enabled = true
		source_mat.emission = source_mat.albedo_color * 0.3
		source.material_override = source_mat
		row.add_child(source)

		# Label
		var label = Label3D.new()
		label.text = tile_type.to_upper()
		label.font_size = 18
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(-1.5, 0.4, 0)
		row.add_child(label)

		# Arrow
		var arrow = Label3D.new()
		arrow.text = "→"
		arrow.font_size = 24
		arrow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		arrow.position = Vector3(-0.8, 0, 0)
		row.add_child(arrow)

		# Adjacent tiles
		var adjacent = adjacency_rules.get(tile_type, [])
		for i in range(adjacent.size()):
			var adj_tile = CSGBox3D.new()
			adj_tile.size = Vector3(0.35, 0.35, 0.15)
			adj_tile.position = Vector3(-0.2 + i * 0.5, 0, 0)
			var adj_mat = StandardMaterial3D.new()
			adj_mat.albedo_color = tile_colors.get(adjacent[i], Color.WHITE)
			adj_mat.emission_enabled = true
			adj_mat.emission = adj_mat.albedo_color * 0.3
			adj_tile.material_override = adj_mat
			row.add_child(adj_tile)

		y_offset -= 1.0

func create_concept_labels():
	# Labels explaining WFC concepts

	# Superposition explanation
	var super_label = Label3D.new()
	super_label.text = "SUPERPOSITION\n(All possible states)"
	super_label.font_size = 20
	super_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	super_label.position = Vector3(-6, 3, 0)
	super_label.outline_size = 4
	add_child(super_label)

	# Entropy explanation
	var entropy_label = Label3D.new()
	entropy_label.text = "ENTROPY\n(Number = uncertainty)"
	entropy_label.font_size = 20
	entropy_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	entropy_label.position = Vector3(-6, 1.5, 0)
	entropy_label.outline_size = 4
	add_child(entropy_label)

	# Collapse explanation
	var collapse_label = Label3D.new()
	collapse_label.text = "COLLAPSE\n(Pick lowest entropy)"
	collapse_label.font_size = 20
	collapse_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	collapse_label.position = Vector3(-6, 0, 0)
	collapse_label.outline_size = 4
	add_child(collapse_label)

	# Propagate explanation
	var prop_label = Label3D.new()
	prop_label.text = "PROPAGATE\n(Wave removes invalid)"
	prop_label.font_size = 20
	prop_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prop_label.position = Vector3(-6, -1.5, 0)
	prop_label.outline_size = 4
	add_child(prop_label)

func start_wfc_generation():
	collapsed_cells = 0
	propagation_wave.clear()
	min_entropy_candidates.clear()
	currently_collapsing_cell = null
	is_selecting = false

	# Reset all cells
	for x in range(grid_size):
		for y in range(grid_size):
			var cell = wfc_grid[x][y]
			cell.possible_states = tile_types.duplicate()
			cell.collapsed_state = ""
			cell.entropy = tile_types.size()
			cell.is_candidate = false
			cell.propagation_highlight = 0.0

			# Reset superposition display
			update_superposition_display(cell)

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
		await get_tree().create_timer(2.0).timeout  # Pause to see final result
		start_wfc_generation()
		return

	# Clear previous candidate highlights
	for cell in min_entropy_candidates:
		cell.is_candidate = false
	min_entropy_candidates.clear()

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

	# Highlight all minimum entropy candidates
	min_entropy_candidates = candidates
	for cell in candidates:
		cell.is_candidate = true
	is_selecting = true
	selection_highlight_timer = 0.0

	# Randomly select from candidates
	var selected_cell = candidates[randi() % candidates.size()]
	currently_collapsing_cell = selected_cell

	# Collapse the cell
	collapse_cell(selected_cell)

	# Propagate constraints with visual wave
	propagate_constraints_with_wave(selected_cell)

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
	update_superposition_display(cell)

func propagate_constraints_with_wave(changed_cell: WFCCell):
	# Clear previous wave
	propagation_wave.clear()

	# Get neighbors and update their possible states
	var neighbors = get_neighbors(changed_cell.position)

	for neighbor in neighbors:
		if neighbor.collapsed_state != "":
			continue

		var old_states = neighbor.possible_states.duplicate()
		var new_possible_states = []
		for state in neighbor.possible_states:
			if can_be_adjacent(changed_cell.collapsed_state, state):
				new_possible_states.append(state)

		if new_possible_states.size() != old_states.size():
			# States were removed - this is the propagation wave!
			neighbor.possible_states = new_possible_states
			neighbor.entropy = neighbor.possible_states.size()
			neighbor.propagation_highlight = 1.0  # Start highlight
			propagation_wave.append(neighbor)

			update_cell_visual(neighbor)
			update_superposition_display(neighbor)

			# Recursive propagation if entropy becomes 1 (forced collapse)
			if neighbor.entropy == 1 and neighbor.collapsed_state == "":
				collapse_cell(neighbor)
				# Continue propagation from this newly collapsed cell
				propagate_constraints_with_wave(neighbor)

# Keep old function for compatibility
func propagate_constraints(changed_cell: WFCCell):
	propagate_constraints_with_wave(changed_cell)

func update_superposition_display(cell: WFCCell):
	# Update the mini-tiles showing possible states
	for visual_data in cell.superposition_visuals:
		var tile = visual_data["tile"]
		var tile_type = visual_data["type"]

		if cell.collapsed_state != "":
			# Cell is collapsed - hide all superposition visuals
			tile.visible = false
		else:
			# Show only possible states
			tile.visible = tile_type in cell.possible_states

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
		# Collapsed state - solid color
		material.albedo_color = tile_colors.get(cell.collapsed_state, Color.WHITE)
		if cell.collapsed_state == "empty":
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_color.a = 0.3
	else:
		# Uncollapsed - neutral base, show entropy through size/glow
		var entropy_ratio = float(cell.entropy) / tile_types.size()
		# Higher entropy = more purple/uncertain, lower = more white/certain
		material.albedo_color = Color(
			0.4 + entropy_ratio * 0.3,
			0.3 + entropy_ratio * 0.2,
			0.6 + entropy_ratio * 0.3,
			0.7
		)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	material.emission_enabled = true
	material.emission = material.albedo_color * 0.3
	cell.visual_object.material_override = material

	# Update entropy label
	if cell.entropy_label:
		if cell.collapsed_state != "":
			cell.entropy_label.text = cell.collapsed_state.substr(0, 1).to_upper()
			cell.entropy_label.modulate = Color(1, 1, 1, 1)
		else:
			cell.entropy_label.text = str(cell.entropy)
			# Color code: lower entropy = brighter (more certain)
			var certainty = 1.0 - (float(cell.entropy) / tile_types.size())
			cell.entropy_label.modulate = Color(1, 1 - certainty * 0.5, 1 - certainty * 0.8, 1)

func update_all_visuals():
	for x in range(grid_size):
		for y in range(grid_size):
			var cell = wfc_grid[x][y]
			update_cell_visual(cell)
			update_superposition_display(cell)

func animate_wfc():
	# Animate cells based on their state
	for x in range(grid_size):
		for y in range(grid_size):
			var cell = wfc_grid[x][y]

			if cell.collapsed_state == "":
				# Uncollapsed cells pulse based on entropy
				var entropy_pulse = 1.0 + sin(time * 3.0 + cell.entropy) * 0.15

				# Highlight minimum entropy candidates (pulsing yellow border effect)
				if cell.is_candidate:
					var candidate_pulse = 1.2 + sin(time * 8.0) * 0.2
					cell.visual_object.scale = Vector3.ONE * candidate_pulse
					# Brighten emission for candidates
					if cell.visual_object.material_override:
						cell.visual_object.material_override.emission_energy_multiplier = 1.5 + sin(time * 8.0) * 0.5
				else:
					cell.visual_object.scale = Vector3.ONE * entropy_pulse
					if cell.visual_object.material_override:
						cell.visual_object.material_override.emission_energy_multiplier = 0.3

				# Propagation wave highlight (fades over time)
				if cell.propagation_highlight > 0:
					cell.propagation_highlight = max(0, cell.propagation_highlight - 0.02)
					# Flash white during propagation
					if cell.visual_object.material_override:
						var flash = cell.propagation_highlight
						cell.visual_object.material_override.emission = Color(1, 1, 1, 1) * flash + cell.visual_object.material_override.albedo_color * 0.3 * (1 - flash)
						cell.visual_object.material_override.emission_energy_multiplier = 1.0 + flash * 2.0
			else:
				# Collapsed cells have gentle wave
				var wave = 1.0 + sin(time * 2.0 + x + y) * 0.05
				cell.visual_object.scale = Vector3.ONE * wave

				# Highlight recently collapsed cell
				if cell == currently_collapsing_cell:
					var collapse_pulse = 1.1 + sin(time * 10.0) * 0.1
					cell.visual_object.scale = Vector3.ONE * collapse_pulse
					if cell.visual_object.material_override:
						cell.visual_object.material_override.emission_energy_multiplier = 2.0

			# Animate superposition mini-tiles
			for i in range(cell.superposition_visuals.size()):
				var visual_data = cell.superposition_visuals[i]
				var tile = visual_data["tile"]
				if tile.visible:
					# Gentle floating animation
					var float_offset = sin(time * 4.0 + i * 1.5) * 0.03
					tile.position.z = 0.15 + float_offset

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
