extends Node3D

class_name WaveFunctionCollapse

# Tile/module definitions with their connection rules
class Module:
	var id: String
	var model: PackedScene  # 3D model to instantiate
	var connections: Dictionary  # Dictionary mapping direction to allowed module IDs
	
	func _init(p_id: String, p_model: PackedScene, p_connections: Dictionary):
		id = p_id
		model = p_model
		connections = p_connections

# Cell in the wave function collapse grid
class Cell:
	var position: Vector3i
	var possible_modules: Array  # Array of module IDs that could go here
	var collapsed: bool = false
	var final_module_id: String = ""
	
	func _init(p_position: Vector3i, p_possible_modules: Array):
		position = p_position
		possible_modules = p_possible_modules
	
	func collapse_to(module_id: String):
		collapsed = true
		final_module_id = module_id
		possible_modules = [module_id]
	
	func get_entropy() -> int:
		return possible_modules.size()

# Grid dimensions
@export var grid_size: Vector3i = Vector3i(10, 1, 10)
@export var cell_size: float = 1.0

# Configuration
@export var modules_folder: String = "res://modules/"
var modules: Dictionary = {}  # Module ID to Module object
var grid: Dictionary = {}  # Vector3i position to Cell object
var module_ids: Array = []

# Directions - six directions in 3D space
const DIRECTIONS = {
	"pos_x": Vector3i(1, 0, 0),
	"neg_x": Vector3i(-1, 0, 0),
	"pos_y": Vector3i(0, 1, 0),
	"neg_y": Vector3i(0, -1, 0),
	"pos_z": Vector3i(0, 0, 1),
	"neg_z": Vector3i(0, 0, -1)
}

# Opposite directions lookup
const OPPOSITE = {
	"pos_x": "neg_x",
	"neg_x": "pos_x",
	"pos_y": "neg_y",
	"neg_y": "pos_y",
	"pos_z": "neg_z",
	"neg_z": "pos_z"
}

# Ada Research specific variables
@export var use_entropy_visualization: bool = true
@export var visualization_material: Material
@export var queer_factor: float = 0.2  # Chance to introduce unexpected connections

func _ready():
	load_modules()
	initialize_grid()
	run_wfc()

func load_modules():
	# This would normally load from files, but for this example we'll define hardcoded modules
	# In a full implementation, you would scan the modules_folder for module definitions
	
	# For Ada Research, these could be geometric shapes, algorithmic patterns, or queer forms
	
	# Example module definitions (simplified for demonstration)
	var empty_module = Module.new("empty", preload("res://adaresearch/Tests/modules/empty.tscn"), {
		"pos_x": ["empty", "cube"],
		"neg_x": ["empty", "cube"],
		"pos_y": ["empty", "cube"],
		"neg_y": ["empty", "cube"],
		"pos_z": ["empty", "cube"],
		"neg_z": ["empty", "cube"]
	})
	
	var cube_module = Module.new("cube", preload("res://adaresearch/Tests/modules/cube.tscn"), {
		"pos_x": ["empty", "cube", "cylinder"],
		"neg_x": ["empty", "cube", "cylinder"],
		"pos_y": ["empty", "cube"],
		"neg_y": ["empty", "cube"],
		"pos_z": ["empty", "cube", "cylinder"],
		"neg_z": ["empty", "cube", "cylinder"]
	})
	
	var cylinder_module = Module.new("cylinder", preload("res://adaresearch/Tests/modules/cylinder.tscn"), {
		"pos_x": ["sphere", "cylinder"],
		"neg_x": ["sphere", "cylinder"],
		"pos_y": ["empty", "cube"],
		"neg_y": ["empty", "cube"],
		"pos_z": ["sphere", "cylinder"],
		"neg_z": ["sphere", "cylinder"]
	})
	
	var sphere_module = Module.new("sphere", preload("res://adaresearch/Tests/modules/sphere.tscn"), {
		"pos_x": ["cylinder"],
		"neg_x": ["cylinder"],
		"pos_y": ["empty"],
		"neg_y": ["empty"],
		"pos_z": ["cylinder"],
		"neg_z": ["cylinder"]
	})
	
	# Add modules to our dictionary
	modules["empty"] = empty_module
	modules["cube"] = cube_module
	modules["cylinder"] = cylinder_module
	modules["sphere"] = sphere_module
	
	# Create a list of all module IDs for convenience
	module_ids = modules.keys()
	
	# Apply queer factor to create unexpected connections
	apply_queer_connections()

func apply_queer_connections():
	# Introduce unexpected connections based on queer_factor
	# This makes the algorithm less rigid and allows for surprising combinations
	if queer_factor <= 0:
		return
		
	for module_id in modules:
		var module = modules[module_id]
		for direction in module.connections:
			if randf() < queer_factor:
				# Randomly add a connection that wasn't previously allowed
				var all_possible = module_ids.duplicate()
				for allowed in module.connections[direction]:
					if all_possible.has(allowed):
						all_possible.erase(allowed)
				
				if all_possible.size() > 0:
					var random_module = all_possible[randi() % all_possible.size()]
					module.connections[direction].append(random_module)
					print("Queer connection added: %s can connect to %s in direction %s" % [module_id, random_module, direction])

func initialize_grid():
	# Create a grid of cells, each with all possibilities initially
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			for z in range(grid_size.z):
				var pos = Vector3i(x, y, z)
				var cell = Cell.new(pos, module_ids.duplicate())
				grid[pos] = cell

func run_wfc():
	# The main wave function collapse algorithm
	var iterations = 0
	var max_iterations = grid_size.x * grid_size.y * grid_size.z * 4  # Prevent infinite loops
	
	while has_uncollapsed_cells() and iterations < max_iterations:
		iterations += 1
		
		# Find cell with minimum entropy (but not already collapsed)
		var min_entropy_cell = find_min_entropy_cell()
		if min_entropy_cell == null:
			break
			
		# Collapse this cell to a random possible module
		collapse_cell(min_entropy_cell)
		
		# Propagate constraints
		propagate_constraints(min_entropy_cell)
		
		# Visualization update for the Ada Research project
		if use_entropy_visualization and iterations % 5 == 0:
			visualize_entropy()
	
	# Instantiate the final modules
	instantiate_modules()
	
	print("WFC completed in %d iterations" % iterations)
	if iterations >= max_iterations:
		print("Warning: Reached maximum iterations - solution may be incomplete")

func has_uncollapsed_cells() -> bool:
	for pos in grid:
		if not grid[pos].collapsed:
			return true
	return false

func find_min_entropy_cell() -> Cell:
	var min_entropy = 999999
	var candidates = []
	
	for pos in grid:
		var cell = grid[pos]
		if not cell.collapsed and cell.possible_modules.size() > 0:
			var entropy = cell.get_entropy()
			
			if entropy < min_entropy:
				min_entropy = entropy
				candidates = [cell]
			elif entropy == min_entropy:
				candidates.append(cell)
	
	if candidates.size() > 0:
		# Return a random cell among those with minimum entropy
		return candidates[randi() % candidates.size()]
	
	return null

func collapse_cell(cell: Cell):
	# Choose a random module from the possible ones for this cell
	var possible = cell.possible_modules
	var chosen_module_id = possible[randi() % possible.size()]
	
	# Collapse the cell to this single possibility
	cell.collapse_to(chosen_module_id)
	
	print("Collapsed cell at %s to %s" % [cell.position, chosen_module_id])

func propagate_constraints(start_cell: Cell):
	# Track which cells we've visited to avoid cycles
	var stack = [start_cell.position]
	
	while stack.size() > 0:
		var current_pos = stack.pop_back()
		var current_cell = grid[current_pos]
		
		# Check all neighbors
		for dir_name in DIRECTIONS:
			var direction = DIRECTIONS[dir_name]
			var neighbor_pos = current_pos + direction
			
			# Skip if outside grid
			if not grid.has(neighbor_pos):
				continue
				
			var neighbor_cell = grid[neighbor_pos]
			var original_possibilities = neighbor_cell.possible_modules.duplicate()
			
			# Apply constraints from current cell to neighbor
			constrain_neighbor(current_cell, neighbor_cell, dir_name)
			
			# If neighbor's possibilities changed, add it to the stack
			if neighbor_cell.possible_modules.size() != original_possibilities.size():
				stack.push_back(neighbor_pos)

func constrain_neighbor(cell: Cell, neighbor: Cell, direction: String):
	if neighbor.collapsed:
		return
		
	var allowed_neighbors = []
	var opposite_dir = OPPOSITE[direction]
	
	# For each possible module in the current cell
	for module_id in cell.possible_modules:
		var module = modules[module_id]
		
		# Get what modules it can connect to in this direction
		var can_connect_to = module.connections.get(direction, [])
		
		# Add these to our allowed list
		for allowed in can_connect_to:
			if not allowed_neighbors.has(allowed):
				allowed_neighbors.append(allowed)
	
	# Now filter the neighbor's possibilities to only those allowed
	var new_possibilities = []
	for possible in neighbor.possible_modules:
		if allowed_neighbors.has(possible):
			new_possibilities.append(possible)
	
	neighbor.possible_modules = new_possibilities

func instantiate_modules():
	# Create the actual 3D scene based on collapsed cells
	for pos in grid:
		var cell = grid[pos]
		if cell.collapsed and cell.final_module_id != "empty":
			var module = modules[cell.final_module_id]
			var instance = module.model.instantiate()
			
			# Position the instance in the world
			instance.position = Vector3(
				cell.position.x * cell_size,
				cell.position.y * cell_size,
				cell.position.z * cell_size
			)
			
			add_child(instance)

func visualize_entropy():
	# Create a visualization of the current entropy state
	# This is Ada Research specific - showing the underlying algorithm
	for pos in grid:
		var cell = grid[pos]
		
		# Visualize entropy as color and scale
		var entropy_node_name = "entropy_vis_%d_%d_%d" % [pos.x, pos.y, pos.z]
		var entropy_node = get_node_or_null(entropy_node_name)
		
		if not entropy_node:
			entropy_node = MeshInstance3D.new()
			entropy_node.name = entropy_node_name
			entropy_node.mesh = SphereMesh.new()
			entropy_node.material_override = visualization_material.duplicate()
			entropy_node.position = Vector3(
				pos.x * cell_size,
				pos.y * cell_size + 0.5,  # Hover above the grid
				pos.z * cell_size
			)
			add_child(entropy_node)
		
		# Update visualization
		if cell.collapsed:
			entropy_node.visible = false
		else:
			entropy_node.visible = true
			var normalized_entropy = float(cell.get_entropy()) / float(module_ids.size())
			
			# Use entropy to adjust visualization
			entropy_node.scale = Vector3.ONE * (0.2 + normalized_entropy * 0.5)
			
			# Adjust material color
			var material = entropy_node.material_override
			material.albedo_color = Color(
				0.2 + normalized_entropy * 0.8,  # More red with higher entropy
				0.2 + (1.0 - normalized_entropy) * 0.8,  # More green with lower entropy
				normalized_entropy * 0.5,  # Blue component
				0.7  # Alpha
			)

# Extension for Ada Research: Define seed patterns or constraints
func set_predefined_patterns():
	# This function could be used to set specific patterns or 
	# starting points for the wave function collapse
	
	# For example, creating a specific pattern in the center:
	var center = Vector3i(grid_size.x / 2, 0, grid_size.z / 2)
	if grid.has(center):
		grid[center].collapse_to("sphere")
		print("Set predefined sphere at center")
	
	# Or creating a line of cubes
	for x in range(grid_size.x):
		var line_pos = Vector3i(x, 0, 0)
		if grid.has(line_pos):
			grid[line_pos].collapse_to("cube")
	
	# After setting predefined patterns, we need to propagate constraints
	for pos in grid:
		if grid[pos].collapsed:
			propagate_constraints(grid[pos])
