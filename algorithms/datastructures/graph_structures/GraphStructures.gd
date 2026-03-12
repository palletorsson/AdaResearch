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

# Object pools — created once in _ready(), reused every frame
var _undirected_node_pool: Array[CSGSphere3D] = []
var _traversal_node_pool: Array[CSGSphere3D] = []
var _traversal_node_materials: Array[StandardMaterial3D] = []
var _traversal_edge_pool: Array[CSGCylinder3D] = []
var _traversal_edge_materials: Array[StandardMaterial3D] = []

func _ready():
	initialize_graphs()
	setup_node_positions()
	# Build static graphs once (they never change per-frame)
	_build_directed_graph()
	_build_weighted_graph()
	# Build pools for animated graphs
	_build_undirected_graph_pool()
	_build_traversal_pool()

func _process(delta):
	time += delta
	traversal_timer += delta

	animate_undirected_graph()
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

# ── Static graphs (built once in _ready) ──────────────────────────────

func _build_directed_graph():
	var container = $DirectedGraph

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
			_create_directed_edge(container, node_positions[from_node], node_positions[to_node])

func _build_weighted_graph():
	var container = $WeightedGraph

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
			_create_weighted_edge(container, node_positions[from_node], node_positions[to_node], weight)

func _create_directed_edge(container: Node3D, from_pos: Vector3, to_pos: Vector3):
	var direction = (to_pos - from_pos).normalized()
	var distance = from_pos.distance_to(to_pos)

	# Edge line
	var edge = CSGCylinder3D.new()
	edge.radius = 0.05
	#
	edge.height = distance - 0.6  # Account for node radius

	edge.position = (from_pos + to_pos) * 0.5
	edge.look_at_from_position(edge.position, to_pos, Vector3.UP)
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
	arrow.look_at_from_position(arrow.position, to_pos, Vector3.UP)

	var arrow_material = StandardMaterial3D.new()
	arrow_material.albedo_color = Color(1.0, 0.2, 0.2)
	arrow_material.emission_enabled = true
	arrow_material.emission = Color(1.0, 0.2, 0.2) * 0.4
	arrow.material_override = arrow_material

	container.add_child(arrow)

func _create_weighted_edge(container: Node3D, from_pos: Vector3, to_pos: Vector3, weight: float):
	var distance = from_pos.distance_to(to_pos)
	var thickness = weight * 0.03  # Scale thickness by weight

	var edge = CSGCylinder3D.new()
	edge.radius = thickness
	edge.height = distance - 0.6

	edge.position = (from_pos + to_pos) * 0.5
	edge.look_at_from_position(edge.position, to_pos, Vector3.UP)
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

# ── Undirected graph pool (only radius pulses per-frame) ──────────────

func _build_undirected_graph_pool():
	var container = $UndirectedGraph

	# Pre-create nodes
	for i in range(node_positions.size()):
		var node = CSGSphere3D.new()
		node.radius = 0.3
		node.position = node_positions[i]

		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.5, 0.3)
		material.metallic = 0.3
		material.roughness = 0.4
		material.emission_enabled = true
		material.emission = Color(1.0, 0.5, 0.3) * 0.3
		node.material_override = material

		container.add_child(node)
		_undirected_node_pool.append(node)

	# Pre-create edges (static — no per-frame changes)
	var processed_edges = {}
	for from_node in undirected_graph:
		for to_node in undirected_graph[from_node]:
			var edge_key = str(min(from_node, to_node)) + "-" + str(max(from_node, to_node))
			if edge_key not in processed_edges:
				_create_undirected_edge(container, node_positions[from_node], node_positions[to_node])
				processed_edges[edge_key] = true

func _create_undirected_edge(container: Node3D, from_pos: Vector3, to_pos: Vector3):
	var distance = from_pos.distance_to(to_pos)

	var edge = CSGCylinder3D.new()
	edge.radius = 0.06

	edge.height = distance - 0.6

	edge.position = (from_pos + to_pos) * 0.5
	edge.look_at_from_position(edge.position, to_pos, Vector3.UP)
	edge.rotate_object_local(Vector3.RIGHT, PI / 2)

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.7, 0.3)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.7, 0.3) * 0.2
	edge.material_override = material

	container.add_child(edge)

func animate_undirected_graph():
	# Only update the pulsing radius — no allocation needed
	for i in range(_undirected_node_pool.size()):
		var pulse = 1.0 + sin(time * 2 + i * 0.5) * 0.2
		_undirected_node_pool[i].radius = 0.3 * pulse

# ── Traversal graph pool (node/edge colors change per-frame) ─────────

func _build_traversal_pool():
	var container = $GraphTraversal

	# Pre-create nodes with materials we can mutate
	for i in range(node_positions.size()):
		var node = CSGSphere3D.new()
		node.radius = 0.3
		node.position = node_positions[i]

		var material = StandardMaterial3D.new()
		material.metallic = 0.3
		material.roughness = 0.4
		node.material_override = material

		container.add_child(node)
		_traversal_node_pool.append(node)
		_traversal_node_materials.append(material)

	# Pre-create edges for every unique undirected pair
	for from_node in undirected_graph:
		for to_node in undirected_graph[from_node]:
			if from_node < to_node:  # Avoid duplicate edges
				var from_pos = node_positions[from_node]
				var to_pos = node_positions[to_node]
				var distance = from_pos.distance_to(to_pos)

				var edge = CSGCylinder3D.new()
				edge.radius = 0.05
				edge.height = distance - 0.6
				edge.position = (from_pos + to_pos) * 0.5
				edge.look_at_from_position(edge.position, to_pos, Vector3.UP)
				edge.rotate_object_local(Vector3.RIGHT, PI / 2)

				var material = StandardMaterial3D.new()
				edge.material_override = material

				container.add_child(edge)
				_traversal_edge_pool.append(edge)
				_traversal_edge_materials.append(material)

func demonstrate_graph_traversal():
	# Update traversal state
	if traversal_timer > 1.0:
		traversal_timer = 0.0
		current_node = (current_node + 1) % node_positions.size()

		# Perform BFS/DFS simulation
		if current_node == 0:
			visited_nodes.clear()
			traversal_order.clear()

		simulate_breadth_first_search()

	# Update traversal visuals (no allocation — just material changes)
	_update_traversal_visuals()

func simulate_breadth_first_search():
	if current_node not in visited_nodes:
		visited_nodes[current_node] = true
		traversal_order.append(current_node)

func _update_traversal_visuals():
	# Update node colors based on traversal state
	for i in range(_traversal_node_pool.size()):
		var mat = _traversal_node_materials[i]

		if i in visited_nodes:
			if i == current_node:
				# Current node
				mat.albedo_color = Color(1.0, 0.0, 0.0)
				mat.emission_enabled = true
				mat.emission = Color(1.0, 0.0, 0.0) * 0.8
			else:
				# Visited node
				mat.albedo_color = Color(0.0, 1.0, 0.0)
				mat.emission_enabled = true
				mat.emission = Color(0.0, 1.0, 0.0) * 0.4
		else:
			# Unvisited node
			mat.albedo_color = Color(0.5, 0.5, 0.5)
			mat.emission_enabled = false

	# Update edge colors
	var edge_idx := 0
	for from_node in undirected_graph:
		for to_node in undirected_graph[from_node]:
			if from_node < to_node:
				var mat = _traversal_edge_materials[edge_idx]

				if from_node in visited_nodes and to_node in visited_nodes:
					var color = Color(0.0, 0.8, 1.0)
					mat.albedo_color = color
					mat.emission_enabled = true
					mat.emission = color * 0.3
				else:
					mat.albedo_color = Color(0.7, 0.7, 0.7)
					mat.emission_enabled = false

				edge_idx += 1
