
# Supporting classes for the rhizomatic maze system

class_name RhizomaticMazeGenerator
extends Node

var growth_points: Array[Vector3] = []
var network_nodes: Array[Dictionary] = []
var connections: Array[Dictionary] = []
var config: Dictionary = {}

func configure(params: Dictionary):
	config = params

func initialize_growth_points(seeds: Array[Vector3]):
	growth_points = seeds.duplicate()

func generate_rhizomatic_network() -> Dictionary:
	"""Generate the rhizomatic network structure"""
	network_nodes.clear()
	connections.clear()
	
	# Convert growth points to network nodes
	for i in range(growth_points.size()):
		network_nodes.append({
			"id": i,
			"position": growth_points[i],
			"connections": [],
			"properties": {"type": "junction", "size": randf_range(0.8, 1.5)}
		})
	
	# Generate rhizomatic connections
	generate_primary_connections()
	generate_secondary_branches()
	prune_redundant_paths()
	
	return {
		"nodes": network_nodes,
		"connections": connections
	}

func generate_primary_connections():
	"""Create main connecting paths between growth points"""
	# Connect nearby nodes using Delaunay-like triangulation
	for i in range(network_nodes.size()):
		var node_a = network_nodes[i]
		var closest_nodes = find_closest_nodes(node_a, 3)
		
		for node_b in closest_nodes:
			if randf() < config.get("branch_prob", 0.7):
				create_connection(node_a, node_b, {"type": "primary", "width_multiplier": 1.0})

func generate_secondary_branches():
	"""Add secondary branching connections"""
	var branch_count = config.get("iterations", 100)
	
	for i in range(branch_count):
		# Pick random existing node
		var source_node = network_nodes[randi() % network_nodes.size()]
		
		# Create new branch node nearby
		var branch_direction = Vector3(
			randf_range(-1, 1),
			randf_range(-0.5, 0.5),  # Less vertical variation
			randf_range(-1, 1)
		).normalized()
		
		var branch_distance = randf_range(3.0, 8.0)
		var branch_pos = source_node.position + branch_direction * branch_distance
		
		# Add new node
		var new_node = {
			"id": network_nodes.size(),
			"position": branch_pos,
			"connections": [],
			"properties": {"type": "branch", "size": randf_range(0.5, 1.0)}
		}
		network_nodes.append(new_node)
		
		# Connect to source
		create_connection(source_node, new_node, {"type": "branch", "width_multiplier": 0.7})

func find_closest_nodes(target_node: Dictionary, count: int) -> Array:
	"""Find closest nodes to target"""
	var distances = []
	
	for node in network_nodes:
		if node.id != target_node.id:
			var distance = target_node.position.distance_to(node.position)
			distances.append({"node": node, "distance": distance})
	
	distances.sort_custom(func(a, b): return a.distance < b.distance)
	
	var result = []
	for i in range(min(count, distances.size())):
		result.append(distances[i].node)
	
	return result

func create_connection(node_a: Dictionary, node_b: Dictionary, properties: Dictionary):
	"""Create connection between two nodes"""
	var connection = {
		"start": node_a.position,
		"end": node_b.position,
		"start_id": node_a.id,
		"end_id": node_b.id,
		"properties": properties
	}
	
	connections.append(connection)
	node_a.connections.append(node_b.id)
	node_b.connections.append(node_a.id)

func prune_redundant_paths():
	"""Remove redundant or problematic connections"""
	# Implementation would remove overly short connections, 
	# connections that create too dense areas, etc.
	pass
