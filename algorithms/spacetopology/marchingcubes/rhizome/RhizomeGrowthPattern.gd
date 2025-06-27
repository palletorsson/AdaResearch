# RhizomeGrowthPattern.gd
# Implements rhizomatic growth patterns for organic cave system generation
# Models underground root-like spreading with interconnected chambers

extends RefCounted
class_name RhizomeGrowthPattern

# Growth parameters
@export var branch_probability: float = 0.7
@export var merge_distance: float = 8.0
@export var vertical_bias: float = 0.3
@export var chamber_probability: float = 0.2
@export var max_depth: int = 6
@export var min_branch_length: float = 5.0
@export var max_branch_length: float = 20.0

# Growth nodes represent points where the rhizome can grow
class GrowthNode:
	var position: Vector3
	var radius: float
	var depth: int
	var energy: float  # Growth potential
	var direction: Vector3  # Preferred growth direction
	var parent: GrowthNode
	var children: Array[GrowthNode] = []
	var is_chamber: bool = false
	
	func _init(pos: Vector3, rad: float = 2.0, d: int = 0):
		position = pos
		radius = rad
		depth = d
		energy = 1.0
		direction = Vector3.ZERO
		parent = null

# Network of growth nodes
var growth_nodes: Array[GrowthNode] = []
var active_nodes: Array[GrowthNode] = []
var chamber_nodes: Array[GrowthNode] = []

# Random number generator for consistent patterns
var rng: RandomNumberGenerator

func _init(seed_value: int = -1):
	rng = RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()

func add_growth_node(position: Vector3, radius: float = 2.0) -> GrowthNode:
	"""Add a new growth node to start rhizomatic expansion"""
	var node = GrowthNode.new(position, radius, 0)
	growth_nodes.append(node)
	active_nodes.append(node)
	
	print("RhizomeGrowth: Added growth node at %v with radius %.2f" % [position, radius])
	return node

func set_growth_rules(rules: Dictionary):
	"""Configure growth behavior with parameter dictionary"""
	if rules.has("branch_probability"):
		branch_probability = rules.branch_probability
	if rules.has("merge_distance"):
		merge_distance = rules.merge_distance
	if rules.has("vertical_bias"):
		vertical_bias = rules.vertical_bias
	if rules.has("chamber_probability"):
		chamber_probability = rules.chamber_probability
	if rules.has("max_depth"):
		max_depth = rules.max_depth

func generate_rhizome_network(iterations: int = 50) -> Dictionary:
	"""Generate the complete rhizomatic network through iterative growth"""
	print("RhizomeGrowth: Starting network generation with %d iterations" % iterations)
	
	for i in range(iterations):
		if active_nodes.is_empty():
			break
			
		grow_iteration()
		
		# Occasionally create chambers at intersection points
		if i % 10 == 0:
			create_chambers()
			
		# Remove exhausted nodes
		prune_inactive_nodes()
	
	print("RhizomeGrowth: Generated network with %d total nodes, %d chambers" % [growth_nodes.size(), chamber_nodes.size()])
	
	return {
		"all_nodes": growth_nodes,
		"chamber_nodes": chamber_nodes,
		"connections": get_all_connections()
	}

func grow_iteration():
	"""Perform one iteration of rhizomatic growth"""
	var new_nodes: Array[GrowthNode] = []
	
	for node in active_nodes:
		if node.depth >= max_depth or node.energy <= 0.1:
			continue
			
		# Attempt to branch
		if rng.randf() < branch_probability * node.energy:
			var branches = create_branches(node)
			new_nodes.append_array(branches)
	
	# Add new nodes to the network
	for node in new_nodes:
		growth_nodes.append(node)
		active_nodes.append(node)

func create_branches(parent_node: GrowthNode) -> Array[GrowthNode]:
	"""Create new branches from a parent node"""
	var branches: Array[GrowthNode] = []
	var num_branches = rng.randi_range(1, 3)
	
	# Reduce parent energy
	parent_node.energy *= 0.7
	
	for i in range(num_branches):
		var branch_direction = generate_growth_direction(parent_node)
		var branch_length = rng.randf_range(min_branch_length, max_branch_length)
		var new_position = parent_node.position + branch_direction * branch_length
		
		# Check for merging with nearby nodes
		var merge_target = find_merge_candidate(new_position)
		if merge_target != null:
			create_connection(parent_node, merge_target)
			continue
		
		# Create new branch node
		var branch_radius = parent_node.radius * rng.randf_range(0.7, 1.0)
		var branch_node = GrowthNode.new(new_position, branch_radius, parent_node.depth + 1)
		branch_node.parent = parent_node
		branch_node.direction = branch_direction
		branch_node.energy = parent_node.energy * 0.8
		
		parent_node.children.append(branch_node)
		branches.append(branch_node)
	
	return branches

func generate_growth_direction(node: GrowthNode) -> Vector3:
	"""Generate a biased growth direction for rhizomatic spreading"""
	var direction = Vector3.ZERO
	
	# Start with random spherical direction
	var theta = rng.randf() * TAU
	var phi = acos(1.0 - 2.0 * rng.randf())
	direction = Vector3(sin(phi) * cos(theta), sin(phi) * sin(theta), cos(phi))
	
	# Apply vertical bias (prefer horizontal spreading)
	direction.y *= vertical_bias
	
	# Add influence from parent direction
	if node.parent != null:
		var parent_influence = node.direction * 0.3
		direction = (direction + parent_influence).normalized()
	
	# Avoid going too far up
	if direction.y > 0.5:
		direction.y = 0.5
		direction = direction.normalized()
	
	return direction

func find_merge_candidate(position: Vector3) -> GrowthNode:
	"""Find nearby nodes that this position could merge with"""
	for node in growth_nodes:
		if position.distance_to(node.position) < merge_distance:
			return node
	return null

func create_connection(node1: GrowthNode, node2: GrowthNode):
	"""Create a connection between two nodes"""
	if node1 != node2 and not node1.children.has(node2):
		node1.children.append(node2)
		print("RhizomeGrowth: Connected nodes at %v and %v" % [node1.position, node2.position])

func create_chambers():
	"""Create chamber nodes at intersection points"""
	for node in growth_nodes:
		if node.children.size() >= 2 and not node.is_chamber:
			if rng.randf() < chamber_probability:
				node.is_chamber = true
				node.radius *= rng.randf_range(2.0, 4.0)  # Expand for chamber
				chamber_nodes.append(node)
				print("RhizomeGrowth: Created chamber at %v with radius %.2f" % [node.position, node.radius])

func prune_inactive_nodes():
	"""Remove nodes with low energy from active list"""
	var still_active: Array[GrowthNode] = []
	for node in active_nodes:
		if node.energy > 0.1 and node.depth < max_depth:
			still_active.append(node)
	active_nodes = still_active

func get_all_connections() -> Array[Dictionary]:
	"""Get all node connections for tunnel generation"""
	var connections: Array[Dictionary] = []
	
	for node in growth_nodes:
		for child in node.children:
			connections.append({
				"start": node.position,
				"end": child.position,
				"start_radius": node.radius,
				"end_radius": child.radius,
				"is_chamber_connection": node.is_chamber or child.is_chamber
			})
	
	return connections

func get_network_bounds() -> AABB:
	"""Get the bounding box of the entire network"""
	if growth_nodes.is_empty():
		return AABB()
	
	var min_pos = growth_nodes[0].position
	var max_pos = growth_nodes[0].position
	
	for node in growth_nodes:
		min_pos = min_pos.min(node.position - Vector3.ONE * node.radius)
		max_pos = max_pos.max(node.position + Vector3.ONE * node.radius)
	
	return AABB(min_pos, max_pos - min_pos)

func export_network_data() -> Dictionary:
	"""Export network data for serialization or analysis"""
	var nodes_data = []
	for node in growth_nodes:
		nodes_data.append({
			"position": [node.position.x, node.position.y, node.position.z],
			"radius": node.radius,
			"depth": node.depth,
			"is_chamber": node.is_chamber
		})
	
	return {
		"nodes": nodes_data,
		"connections": get_all_connections(),
		"bounds": get_network_bounds(),
		"parameters": {
			"branch_probability": branch_probability,
			"merge_distance": merge_distance,
			"vertical_bias": vertical_bias,
			"chamber_probability": chamber_probability
		}
	} 