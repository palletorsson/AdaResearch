extends Node3D

# Graph Structures Visualization
# Demonstrates different types of graphs and their properties

var time := 0.0
var traversal_timer := 0.0
var current_node := 0

# Graph data structures
var directed_graph := {}
var undirected_graph := {}
var weighted_graph := {}

# Node positions for visualization
var node_positions := []
var traversal_order := []
var visited_nodes := {}

func _ready():
	initialize_graphs()
	setup_node_positions()

func _process(delta):
	time += delta
	traversal_timer += delta
	
	animate_directed_graph()
	animate_undirected_graph()
	animate_weighted_graph()
	demonstrate_graph_traversal()

func initialize_graphs():
	# Initialize directed graph (adjacency list)
	directed_graph = {
		0: [1, 2],
		1: [3, 4],
		2: [4, 5],
		3: [6],
		4: [6, 7],
		5: [7],
		6: [],
		7: []
	}
	
	# Initialize undirected graph
	undirected_graph = {
		0: [1, 2, 3],
		1: [0, 2, 4],
		2: [0, 1, 5],
		3: [0, 4, 6],
		4: [1, 3, 7],
		5: [2, 6, 7],
		6: [3, 5],
		7: [4, 5]
	}
	
	# Initialize weighted graph (with weights)
	weighted_graph = {
		0: [[1, 2.5], [2, 1.8]],
		1: [[3, 3.2], [4, 1.2]],
		2: [[4, 2.7], [5, 1.9]],
		3: [[6, 1.5]],
		4: [[6, 2.1], [7, 3.0]],
		5: [[7, 1.4]],
		6: [],
		7: []
	}

func setup_node_positions():
	# Create circular layout for nodes
	var radius = 3.0
	var node_count = 8
	
	for i in range(node_count):
		var angle = float(i) / node_count * TAU
		var pos = Vector3(cos(angle) * radius, sin(angle) * radius, 0)
		node_positions.append(pos)

func animate_directed_graph():
	var container = $DirectedGraph
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create nodes
	for i in range(node_positions.size()):
		var node = CSGSphere3D.new()
		node.radius = 0.3
		node.position = node_positions[i]
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.7, 1.0)
		material.metallic = 0.4
		material.roughness = 0.3
		material.emission_enabled = true
		material.emission = Color(0.3, 0.7, 1.0) * 0.2
		node.material_override = material
		
		container.add_child(node)
	
	# Create directed edges
	for from_node in directed_graph:
		for to_node in directed_graph[from_node]:
			create_directed_edge(container, node_positions[from_node], node_positions[to_node])

func animate_undirected_graph():
	var container = $UndirectedGraph
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create nodes with pulsing animation
	for i in range(node_positions.size()):
		var node = CSGSphere3D.new()
		var pulse = 1.0 + sin(time * 2 + i * 0.5) * 0.2
		node.radius = 0.3 * pulse
		node.position = node_positions[i]
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.5, 0.3)
		material.metallic = 0.3
		material.roughness = 0.4
		material.emission_enabled = true
		material.emission = Color(1.0, 0.5, 0.3) * 0.3
		node.material_override = material
		
		container.add_child(node)
	
	# Create undirected edges
	var processed_edges = {}
	for from_node in undirected_graph:
		for to_node in undirected_graph[from_node]:
			var edge_key = str(min(from_node, to_node)) + "-" + str(max(from_node, to_node))
			if edge_key not in processed_edges:
				create_undirected_edge(container, node_positions[from_node], node_positions[to_node])
				processed_edges[edge_key] = true

func animate_weighted_graph():
	var container = $WeightedGraph
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Create nodes
	for i in range(node_positions.size()):
		var node = CSGBox3D.new()
		node.size = Vector3(0.6, 0.6, 0.6)
		node.position = node_positions[i]
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.5, 1.0, 0.3)
		material.metallic = 0.2
		material.roughness = 0.5
		material.emission_enabled = true
		material.emission = Color(0.5, 1.0, 0.3) * 0.2
		node.material_override = material
		
		container.add_child(node)
	
	# Create weighted edges
	for from_node in weighted_graph:
		for edge_data in weighted_graph[from_node]:
			var to_node = edge_data[0]
			var weight = edge_data[1]
			create_weighted_edge(container, node_positions[from_node], node_positions[to_node], weight)

func create_directed_edge(container: Node3D, from_pos: Vector3, to_pos: Vector3):
	var direction = (to_pos - from_pos).normalized()
	var distance = from_pos.distance_to(to_pos)
	
	# Edge line
	var edge = CSGCylinder3D.new()
	edge.radius = 0.05
	#
	edge.height = distance - 0.6  # Account for node radius
	
	edge.position = (from_pos + to_pos) * 0.5
	edge.look_at(to_pos, Vector3.UP)
	edge.rotate_object_local(Vector3.RIGHT, PI / 2)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.8, 1.0)
	edge.material_override = material
	
	container.add_child(edge)
	
	# Arrow head
	var arrow =  CSGCylinder3D.new()
	arrow.radius = 0.0
	arrow.height = 0.3
	arrow.position = to_pos - direction * 0.4
	arrow.look_at(to_pos, Vector3.UP)
	
	var arrow_material = StandardMaterial3D.new()
	arrow_material.albedo_color = Color(1.0, 0.2, 0.2)
	arrow_material.emission_enabled = true
	arrow_material.emission = Color(1.0, 0.2, 0.2) * 0.4
	arrow.material_override = arrow_material
	
	container.add_child(arrow)

func create_undirected_edge(container: Node3D, from_pos: Vector3, to_pos: Vector3):
	var distance = from_pos.distance_to(to_pos)
	
	var edge = CSGCylinder3D.new()
	edge.radius = 0.06
	
	edge.height = distance - 0.6
	
	edge.position = (from_pos + to_pos) * 0.5
	edge.look_at(to_pos, Vector3.UP)
	edge.rotate_object_local(Vector3.RIGHT, PI / 2)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.7, 0.3)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.7, 0.3) * 0.2
	edge.material_override = material
	
	container.add_child(edge)

func create_weighted_edge(container: Node3D, from_pos: Vector3, to_pos: Vector3, weight: float):
	var distance = from_pos.distance_to(to_pos)
	var thickness = weight * 0.03  # Scale thickness by weight
	
	var edge = CSGCylinder3D.new()
	edge.radius = thickness
	edge.height = distance - 0.6
	
	edge.position = (from_pos + to_pos) * 0.5
	edge.look_at(to_pos, Vector3.UP)
	edge.rotate_object_local(Vector3.RIGHT, PI / 2)
	
	var material = StandardMaterial3D.new()
	# Color based on weight
	var weight_ratio = (weight - 1.0) / 2.5  # Normalize weight to 0-1
	material.albedo_color = Color(1.0, 1.0 - weight_ratio, 1.0 - weight_ratio)
	material.emission_enabled = true
	material.emission = Color(1.0, 1.0 - weight_ratio, 1.0 - weight_ratio) * 0.3
	edge.material_override = material
	
	container.add_child(edge)
	
	# Weight label (small sphere)
	var weight_label = CSGSphere3D.new()
	weight_label.radius = 0.1
	weight_label.position = (from_pos + to_pos) * 0.5 + Vector3(0, 0.3, 0)
	
	var label_material = StandardMaterial3D.new()
	label_material.albedo_color = Color(1.0, 1.0, 0.0)
	label_material.emission_enabled = true
	label_material.emission = Color(1.0, 1.0, 0.0) * 0.6
	weight_label.material_override = label_material
	
	container.add_child(weight_label)

func demonstrate_graph_traversal():
	var container = $GraphTraversal
	
	# Clear previous visualization
	for child in container.get_children():
		child.queue_free()
	
	# Update traversal state
	if traversal_timer > 1.0:
		traversal_timer = 0.0
		current_node = (current_node + 1) % node_positions.size()
		
		# Perform BFS/DFS simulation
		if current_node == 0:
			visited_nodes.clear()
			traversal_order.clear()
		
		simulate_breadth_first_search()
	
	# Visualize traversal
	visualize_traversal(container)

func simulate_breadth_first_search():
	if current_node not in visited_nodes:
		visited_nodes[current_node] = true
		traversal_order.append(current_node)

func visualize_traversal(container: Node3D):
	# Create nodes with traversal state
	for i in range(node_positions.size()):
		var node = CSGSphere3D.new()
		node.radius = 0.3
		node.position = node_positions[i]
		
		var material = StandardMaterial3D.new()
		
		if i in visited_nodes:
			if i == current_node:
				# Current node
				material.albedo_color = Color(1.0, 0.0, 0.0)
				material.emission_enabled = true
				material.emission = Color(1.0, 0.0, 0.0) * 0.8
			else:
				# Visited node
				material.albedo_color = Color(0.0, 1.0, 0.0)
				material.emission_enabled = true
				material.emission = Color(0.0, 1.0, 0.0) * 0.4
		else:
			# Unvisited node
			material.albedo_color = Color(0.5, 0.5, 0.5)
		
		material.metallic = 0.3
		material.roughness = 0.4
		node.material_override = material
		
		container.add_child(node)
	
	# Create edges for the graph being traversed
	for from_node in undirected_graph:
		for to_node in undirected_graph[from_node]:
			if from_node < to_node:  # Avoid duplicate edges
				var edge_color = Color(0.7, 0.7, 0.7)
				
				# Highlight edge if both nodes are visited
				if from_node in visited_nodes and to_node in visited_nodes:
					edge_color = Color(0.0, 0.8, 1.0)
				
				create_traversal_edge(container, node_positions[from_node], node_positions[to_node], edge_color)

func create_traversal_edge(container: Node3D, from_pos: Vector3, to_pos: Vector3, color: Color):
	var distance = from_pos.distance_to(to_pos)
	
	var edge = CSGCylinder3D.new()
	edge.radius = 0.05
	
	edge.height = distance - 0.6
	
	edge.position = (from_pos + to_pos) * 0.5
	edge.look_at(to_pos, Vector3.UP)
	edge.rotate_object_local(Vector3.RIGHT, PI / 2)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	if color != Color(0.7, 0.7, 0.7):
		material.emission_enabled = true
		material.emission = color * 0.3
	edge.material_override = material
	
	container.add_child(edge)
