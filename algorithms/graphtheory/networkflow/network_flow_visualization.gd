class_name NetworkFlowVisualization
extends Node3D

# Network Flow: Flow Distribution & Capacity Politics
# Visualizes maximum flow algorithms and capacity constraints
# Explores resource distribution and bottleneck identification

@export_category("Network Flow Configuration")
@export var algorithm_type: String = "ford_fulkerson"  # ford_fulkerson, edmonds_karp, dinic
@export var max_flow_value: int = 0
@export var graph_size: int = 8  # Number of nodes
@export var edge_density: float = 0.4  # Connection probability
@export var min_capacity: int = 1
@export var max_capacity: int = 10

@export_category("Visualization")
@export var show_capacity_labels: bool = true
@export var show_flow_values: bool = true
@export var show_residual_graph: bool = true
@export var show_augmenting_paths: bool = true
@export var animate_flow_search: bool = true
@export var flow_animation_speed: float = 0.5

@export_category("Interactive Mode")
@export var enable_graph_editing: bool = true
@export var allow_capacity_editing: bool = true
@export var real_time_flow_update: bool = true
@export var show_cut_visualization: bool = true

@export_category("Animation")
@export var auto_start: bool = true
@export var step_by_step: bool = true
@export var animation_delay: float = 0.8
@export var highlight_duration: float = 1.5

# Colors for visualization
@export var node_color: Color = Color(0.3, 0.5, 0.8, 1.0)
@export var source_color: Color = Color(0.2, 0.8, 0.2, 1.0)
@export var sink_color: Color = Color(0.8, 0.2, 0.2, 1.0)
@export var edge_color: Color = Color(0.6, 0.6, 0.6, 1.0)
@export var flow_color: Color = Color(0.9, 0.3, 0.3, 1.0)
@export var augmenting_path_color: Color = Color(0.9, 0.9, 0.2, 1.0)
@export var cut_color: Color = Color(0.9, 0.2, 0.9, 1.0)

# Graph representation
var nodes: Array = []
var edges: Array = []
var adjacency_matrix: Array = []
var capacity_matrix: Array = []
var flow_matrix: Array = []
var residual_matrix: Array = []

# Algorithm state
var source_node: int = 0
var sink_node: int = -1
var current_flow: int = 0
var is_computing: bool = false
var computation_complete: bool = false
var current_augmenting_path: Array = []
var all_augmenting_paths: Array = []
var min_cut_nodes: Array = []

# Visualization elements
var node_meshes: Array = []
var edge_meshes: Array = []
var flow_indicators: Array = []
var path_highlights: Array = []
var ui_display: CanvasLayer
var computation_timer: Timer

# Network flow algorithms
var visited_nodes: Array = []
var parent_nodes: Array = []
var path_capacities: Array = []

func _init():
	name = "NetworkFlow_Visualization"

func _ready():
	setup_ui()
	setup_timer()
	initialize_graph()
	create_visualization()
	
	if auto_start:
		call_deferred("start_flow_computation")

func setup_ui():
	"""Create comprehensive UI for network flow visualization"""
	ui_display = CanvasLayer.new()
	add_child(ui_display)
	
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.size = Vector2(450, 800)
	panel.position = Vector2(-460, 10)
	ui_display.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Create labels for network flow information
	for i in range(30):
		var label = Label.new()
		label.name = "info_label_" + str(i)
		label.text = ""
		vbox.add_child(label)
	
	update_ui()

func setup_timer():
	"""Setup timer for step-by-step animation"""
	computation_timer = Timer.new()
	computation_timer.wait_time = animation_delay
	computation_timer.timeout.connect(_on_computation_timer_timeout)
	add_child(computation_timer)

func initialize_graph():
	"""Initialize the flow network graph"""
	nodes.clear()
	edges.clear()
	
	# Create nodes
	for i in range(graph_size):
		var node = {
			"id": i,
			"position": Vector3.ZERO,
			"is_source": i == source_node,
			"is_sink": i == (graph_size - 1),
			"label": "Node " + str(i)
		}
		nodes.append(node)
	
	sink_node = graph_size - 1
	
	# Generate node positions in a circular layout
	generate_node_positions()
	
	# Initialize matrices
	initialize_matrices()
	
	# Generate random graph structure
	generate_graph_structure()
	
	print("Initialized network with ", nodes.size(), " nodes and ", edges.size(), " edges")

func generate_node_positions():
	"""Generate positions for nodes in a circular layout"""
	var radius = 6.0
	var angle_increment = 2.0 * PI / graph_size
	
	for i in range(graph_size):
		var angle = i * angle_increment
		var x = radius * cos(angle)
		var y = radius * sin(angle)
		var z = randf_range(-0.5, 0.5)  # Small random z variation
		
		nodes[i].position = Vector3(x, y, z)

func initialize_matrices():
	"""Initialize adjacency, capacity, and flow matrices"""
	adjacency_matrix.clear()
	capacity_matrix.clear()
	flow_matrix.clear()
	residual_matrix.clear()
	
	for i in range(graph_size):
		var adj_row = []
		var cap_row = []
		var flow_row = []
		var res_row = []
		
		for j in range(graph_size):
			adj_row.append(false)
			cap_row.append(0)
			flow_row.append(0)
			res_row.append(0)
		
		adjacency_matrix.append(adj_row)
		capacity_matrix.append(cap_row)
		flow_matrix.append(flow_row)
		residual_matrix.append(res_row)

func generate_graph_structure():
	"""Generate random graph structure with capacity constraints"""
	edges.clear()
	
	# Ensure connectivity from source to sink
	ensure_source_sink_connectivity()
	
	# Add additional random edges
	for i in range(graph_size):
		for j in range(graph_size):
			if i != j and not adjacency_matrix[i][j]:
				if randf() < edge_density:
					add_edge(i, j, randi_range(min_capacity, max_capacity))

func ensure_source_sink_connectivity():
	"""Ensure there's at least one path from source to sink"""
	# Create a path from source to sink
	var path_nodes = range(graph_size)
	path_nodes.shuffle()
	
	# Ensure source is first and sink is last
	path_nodes.erase(source_node)
	path_nodes.erase(sink_node)
	path_nodes.push_front(source_node)
	path_nodes.push_back(sink_node)
	
	# Connect consecutive nodes in path
	for i in range(path_nodes.size() - 1):
		var from_node = path_nodes[i]
		var to_node = path_nodes[i + 1]
		add_edge(from_node, to_node, randi_range(min_capacity, max_capacity))

func add_edge(from_node: int, to_node: int, capacity: int):
	"""Add an edge with given capacity"""
	if from_node >= 0 and from_node < graph_size and to_node >= 0 and to_node < graph_size:
		adjacency_matrix[from_node][to_node] = true
		capacity_matrix[from_node][to_node] = capacity
		residual_matrix[from_node][to_node] = capacity
		
		var edge = {
			"from": from_node,
			"to": to_node,
			"capacity": capacity,
			"flow": 0,
			"residual": capacity
		}
		edges.append(edge)

func create_visualization():
	"""Create 3D visualization of the network"""
	clear_visualization()
	create_node_visualization()
	create_edge_visualization()

func clear_visualization():
	"""Clear existing visualization elements"""
	for mesh in node_meshes:
		if mesh:
			mesh.queue_free()
	for mesh in edge_meshes:
		if mesh:
			mesh.queue_free()
	for indicator in flow_indicators:
		if indicator:
			indicator.queue_free()
	for highlight in path_highlights:
		if highlight:
			highlight.queue_free()
	
	node_meshes.clear()
	edge_meshes.clear()
	flow_indicators.clear()
	path_highlights.clear()

func create_node_visualization():
	"""Create visual representation of nodes"""
	for i in range(nodes.size()):
		var node = nodes[i]
		var mesh_instance = MeshInstance3D.new()
		
		# Create node mesh
		var mesh = SphereMesh.new()
		mesh.radius = 0.3
		mesh.height = 0.6
		mesh_instance.mesh = mesh
		
		# Set node material based on type
		var material = StandardMaterial3D.new()
		if node.is_source:
			material.albedo_color = source_color
			material.emission_enabled = true
			material.emission = source_color * 0.3
		elif node.is_sink:
			material.albedo_color = sink_color
			material.emission_enabled = true
			material.emission = sink_color * 0.3
		else:
			material.albedo_color = node_color
			material.emission_enabled = true
			material.emission = node_color * 0.2
		
		mesh_instance.material_override = material
		mesh_instance.position = node.position
		
		# Add label
		if show_capacity_labels:
			create_node_label(mesh_instance, node.label, Vector3(0, 0.8, 0))
		
		add_child(mesh_instance)
		node_meshes.append(mesh_instance)

func create_edge_visualization():
	"""Create visual representation of edges"""
	for edge in edges:
		var from_pos = nodes[edge.from].position
		var to_pos = nodes[edge.to].position
		
		# Create edge line
		var edge_mesh = create_edge_line(from_pos, to_pos, edge_color)
		add_child(edge_mesh)
		edge_meshes.append(edge_mesh)
		
		# Create capacity label
		if show_capacity_labels:
			var mid_pos = (from_pos + to_pos) / 2.0
			create_edge_label(edge_mesh, str(edge.capacity), mid_pos + Vector3(0, 0.3, 0))
		
		# Create flow indicator
		if show_flow_values:
			var flow_indicator = create_flow_indicator(from_pos, to_pos, edge.flow, edge.capacity)
			add_child(flow_indicator)
			flow_indicators.append(flow_indicator)

func create_edge_line(from_pos: Vector3, to_pos: Vector3, color: Color) -> MeshInstance3D:
	"""Create a line mesh between two positions"""
	var mesh_instance = MeshInstance3D.new()
	var mesh = create_line_mesh(from_pos, to_pos)
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.2
	mesh_instance.material_override = material
	
	return mesh_instance

func create_line_mesh(from_pos: Vector3, to_pos: Vector3) -> ArrayMesh:
	"""Create mesh for line between two points"""
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	vertices.append(from_pos)
	vertices.append(to_pos)
	indices.append(0)
	indices.append(1)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	
	return array_mesh

func create_flow_indicator(from_pos: Vector3, to_pos: Vector3, flow: int, capacity: int) -> MeshInstance3D:
	"""Create visual indicator for flow on edge"""
	var mesh_instance = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	
	# Scale cylinder based on flow ratio
	var flow_ratio = float(flow) / float(capacity) if capacity > 0 else 0.0
	mesh.top_radius = 0.05 * flow_ratio
	mesh.bottom_radius = 0.05 * flow_ratio
	mesh.height = from_pos.distance_to(to_pos) * 0.8
	
	mesh_instance.mesh = mesh
	
	# Position and orient cylinder
	var mid_pos = (from_pos + to_pos) / 2.0
	mesh_instance.position = mid_pos
	mesh_instance.look_at(to_pos, Vector3.UP)
	
	# Color based on flow intensity
	var material = StandardMaterial3D.new()
	material.albedo_color = flow_color
	material.emission_enabled = true
	material.emission = flow_color * flow_ratio
	mesh_instance.material_override = material
	
	return mesh_instance

func create_node_label(parent: MeshInstance3D, text: String, offset: Vector3):
	"""Create text label for node"""
	var label = Label3D.new()
	label.text = text
	label.position = offset
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)

func create_edge_label(parent: MeshInstance3D, text: String, position: Vector3):
	"""Create text label for edge"""
	var label = Label3D.new()
	label.text = text
	label.position = position
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)

func start_flow_computation():
	"""Start the maximum flow computation"""
	if is_computing:
		return
	
	is_computing = true
	computation_complete = false
	current_flow = 0
	
	# Reset flow matrices
	for i in range(graph_size):
		for j in range(graph_size):
			flow_matrix[i][j] = 0
			residual_matrix[i][j] = capacity_matrix[i][j]
	
	# Reset tracking arrays
	all_augmenting_paths.clear()
	min_cut_nodes.clear()
	
	match algorithm_type:
		"ford_fulkerson":
			start_ford_fulkerson()
		"edmonds_karp":
			start_edmonds_karp()
		"dinic":
			start_dinic()
		_:
			start_ford_fulkerson()
	
	print("Starting ", algorithm_type, " algorithm...")

func start_ford_fulkerson():
	"""Start Ford-Fulkerson algorithm"""
	if step_by_step:
		computation_timer.start()
	else:
		run_ford_fulkerson_complete()

func run_ford_fulkerson_complete():
	"""Run complete Ford-Fulkerson algorithm"""
	while true:
		var path = find_augmenting_path_dfs(source_node, sink_node)
		if path.size() == 0:
			break
		
		var path_flow = get_path_flow(path)
		augment_flow_along_path(path, path_flow)
		current_flow += path_flow
		all_augmenting_paths.append(path.duplicate())
	
	max_flow_value = current_flow
	find_min_cut()
	finalize_computation()

func find_augmenting_path_dfs(source: int, sink: int) -> Array:
	"""Find augmenting path using Depth-First Search"""
	visited_nodes.clear()
	parent_nodes.clear()
	
	for i in range(graph_size):
		visited_nodes.append(false)
		parent_nodes.append(-1)
	
	var path = []
	if dfs_search(source, sink):
		# Reconstruct path
		var current = sink
		while current != source:
			path.push_front(current)
			current = parent_nodes[current]
		path.push_front(source)
	
	return path

func dfs_search(node: int, sink: int) -> bool:
	"""Depth-first search for augmenting path"""
	visited_nodes[node] = true
	
	if node == sink:
		return true
	
	for neighbor in range(graph_size):
		if not visited_nodes[neighbor] and residual_matrix[node][neighbor] > 0:
			parent_nodes[neighbor] = node
			if dfs_search(neighbor, sink):
				return true
	
	return false

func find_augmenting_path_bfs(source: int, sink: int) -> Array:
	"""Find augmenting path using Breadth-First Search (for Edmonds-Karp)"""
	visited_nodes.clear()
	parent_nodes.clear()
	
	for i in range(graph_size):
		visited_nodes.append(false)
		parent_nodes.append(-1)
	
	var queue = [source]
	visited_nodes[source] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		for neighbor in range(graph_size):
			if not visited_nodes[neighbor] and residual_matrix[current][neighbor] > 0:
				visited_nodes[neighbor] = true
				parent_nodes[neighbor] = current
				queue.append(neighbor)
				
				if neighbor == sink:
					# Reconstruct path
					var path = []
					var node = sink
					while node != source:
						path.push_front(node)
						node = parent_nodes[node]
					path.push_front(source)
					return path
	
	return []

func get_path_flow(path: Array) -> int:
	"""Get maximum flow that can be pushed through path"""
	var min_capacity = INF
	
	for i in range(path.size() - 1):
		var from_node = path[i]
		var to_node = path[i + 1]
		var available_capacity = residual_matrix[from_node][to_node]
		min_capacity = min(min_capacity, available_capacity)
	
	return min_capacity

func augment_flow_along_path(path: Array, flow_amount: int):
	"""Augment flow along the given path"""
	for i in range(path.size() - 1):
		var from_node = path[i]
		var to_node = path[i + 1]
		
		# Forward edge
		residual_matrix[from_node][to_node] -= flow_amount
		flow_matrix[from_node][to_node] += flow_amount
		
		# Backward edge (for residual graph)
		residual_matrix[to_node][from_node] += flow_amount

func start_edmonds_karp():
	"""Start Edmonds-Karp algorithm (Ford-Fulkerson with BFS)"""
	if step_by_step:
		computation_timer.start()
	else:
		run_edmonds_karp_complete()

func run_edmonds_karp_complete():
	"""Run complete Edmonds-Karp algorithm"""
	while true:
		var path = find_augmenting_path_bfs(source_node, sink_node)
		if path.size() == 0:
			break
		
		var path_flow = get_path_flow(path)
		augment_flow_along_path(path, path_flow)
		current_flow += path_flow
		all_augmenting_paths.append(path.duplicate())
	
	max_flow_value = current_flow
	find_min_cut()
	finalize_computation()

func start_dinic():
	"""Start Dinic's algorithm (simplified version)"""
	# For now, use Edmonds-Karp as placeholder
	start_edmonds_karp()

func find_min_cut():
	"""Find minimum cut using DFS from source in residual graph"""
	visited_nodes.clear()
	for i in range(graph_size):
		visited_nodes.append(false)
	
	dfs_min_cut(source_node)
	
	# All visited nodes are on source side of cut
	min_cut_nodes.clear()
	for i in range(graph_size):
		if visited_nodes[i]:
			min_cut_nodes.append(i)

func dfs_min_cut(node: int):
	"""DFS to find reachable nodes from source in residual graph"""
	visited_nodes[node] = true
	
	for neighbor in range(graph_size):
		if not visited_nodes[neighbor] and residual_matrix[node][neighbor] > 0:
			dfs_min_cut(neighbor)

func _on_computation_timer_timeout():
	"""Handle step-by-step computation timer"""
	if not is_computing:
		return
	
	# Perform one step of the algorithm
	var path = []
	match algorithm_type:
		"ford_fulkerson":
			path = find_augmenting_path_dfs(source_node, sink_node)
		"edmonds_karp":
			path = find_augmenting_path_bfs(source_node, sink_node)
		_:
			path = find_augmenting_path_dfs(source_node, sink_node)
	
	if path.size() > 0:
		var path_flow = get_path_flow(path)
		augment_flow_along_path(path, path_flow)
		current_flow += path_flow
		all_augmenting_paths.append(path.duplicate())
		
		# Highlight current path
		highlight_augmenting_path(path)
		
		# Update visualization
		update_flow_visualization()
		update_ui()
	else:
		max_flow_value = current_flow
		find_min_cut()
		finalize_computation()

func highlight_augmenting_path(path: Array):
	"""Highlight the current augmenting path"""
	clear_path_highlights()
	
	for i in range(path.size() - 1):
		var from_node = path[i]
		var to_node = path[i + 1]
		var from_pos = nodes[from_node].position
		var to_pos = nodes[to_node].position
		
		var highlight = create_edge_line(from_pos, to_pos, augmenting_path_color)
		add_child(highlight)
		path_highlights.append(highlight)

func clear_path_highlights():
	"""Clear path highlight visualizations"""
	for highlight in path_highlights:
		if highlight:
			highlight.queue_free()
	path_highlights.clear()

func update_flow_visualization():
	"""Update flow visualization"""
	# Update flow indicators
	for i in range(flow_indicators.size()):
		if i < edges.size():
			var edge = edges[i]
			var indicator = flow_indicators[i]
			
			# Update flow indicator based on current flow
			var flow_amount = flow_matrix[edge.from][edge.to]
			var flow_ratio = float(flow_amount) / float(edge.capacity) if edge.capacity > 0 else 0.0
			
			# Update cylinder mesh
			var mesh = indicator.mesh as CylinderMesh
			mesh.top_radius = 0.05 * flow_ratio
			mesh.bottom_radius = 0.05 * flow_ratio
			
			# Update material
			var material = indicator.material_override as StandardMaterial3D
			material.emission = flow_color * flow_ratio

func finalize_computation():
	"""Finalize the flow computation"""
	is_computing = false
	computation_complete = true
	computation_timer.stop()
	
	# Highlight min cut if requested
	if show_cut_visualization:
		highlight_min_cut()
	
	print("Flow computation complete!")
	print("Maximum flow: ", max_flow_value)
	print("Number of augmenting paths: ", all_augmenting_paths.size())
	print("Min cut nodes: ", min_cut_nodes)
	
	update_ui()

func highlight_min_cut():
	"""Highlight the minimum cut"""
	# Color nodes in min cut
	for i in range(min_cut_nodes.size()):
		var node_id = min_cut_nodes[i]
		if node_id < node_meshes.size():
			var mesh = node_meshes[node_id]
			var material = mesh.material_override as StandardMaterial3D
			material.emission = cut_color * 0.5

func update_ui():
	"""Update UI with current algorithm state"""
	if not ui_display:
		return
	
	var labels = []
	for i in range(30):
		var label = ui_display.get_node("Panel/VBoxContainer/info_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 30:
		labels[0].text = "🌊 Network Flow - Resource Distribution"
		labels[1].text = "Algorithm: " + algorithm_type.capitalize()
		labels[2].text = "Graph Size: " + str(graph_size) + " nodes"
		labels[3].text = "Edge Count: " + str(edges.size())
		labels[4].text = ""
		labels[5].text = "Status: " + ("Computing..." if is_computing else "Complete" if computation_complete else "Ready")
		labels[6].text = "Current Flow: " + str(current_flow)
		labels[7].text = "Maximum Flow: " + str(max_flow_value)
		labels[8].text = "Paths Found: " + str(all_augmenting_paths.size())
		labels[9].text = ""
		labels[10].text = "Source Node: " + str(source_node)
		labels[11].text = "Sink Node: " + str(sink_node)
		labels[12].text = "Min Cut Size: " + str(min_cut_nodes.size())
		labels[13].text = "Min Cut Nodes: " + str(min_cut_nodes)
		labels[14].text = ""
		labels[15].text = "Graph Properties:"
		labels[16].text = "Density: " + str(edge_density * 100).pad_decimals(1) + "%"
		labels[17].text = "Capacity Range: " + str(min_capacity) + "-" + str(max_capacity)
		labels[18].text = "Total Capacity: " + str(get_total_capacity())
		labels[19].text = "Flow Efficiency: " + str(get_flow_efficiency() * 100).pad_decimals(1) + "%"
		labels[20].text = ""
		labels[21].text = "Visualization:"
		labels[22].text = "Capacity Labels: " + ("On" if show_capacity_labels else "Off")
		labels[23].text = "Flow Values: " + ("On" if show_flow_values else "Off")
		labels[24].text = "Residual Graph: " + ("On" if show_residual_graph else "Off")
		labels[25].text = "Cut Highlight: " + ("On" if show_cut_visualization else "Off")
		labels[26].text = ""
		labels[27].text = "Controls:"
		labels[28].text = "SPACE - Start/Stop, R - Reset, 1-3 - Algorithms"
		labels[29].text = "🏳️‍🌈 Explores capacity politics & resource flow"

func get_total_capacity() -> int:
	"""Get total capacity of all edges"""
	var total = 0
	for edge in edges:
		total += edge.capacity
	return total

func get_flow_efficiency() -> float:
	"""Get efficiency of flow utilization"""
	var total_capacity = get_total_capacity()
	if total_capacity == 0:
		return 0.0
	return float(max_flow_value) / float(total_capacity)

func _input(event):
	"""Handle user input"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				if is_computing:
					stop_computation()
				else:
					start_flow_computation()
			KEY_R:
				reset_network()
			KEY_1:
				change_algorithm("ford_fulkerson")
			KEY_2:
				change_algorithm("edmonds_karp")
			KEY_3:
				change_algorithm("dinic")
			KEY_C:
				show_cut_visualization = not show_cut_visualization
				if computation_complete:
					highlight_min_cut()
			KEY_F:
				show_flow_values = not show_flow_values
				create_visualization()
			KEY_L:
				show_capacity_labels = not show_capacity_labels
				create_visualization()

func stop_computation():
	"""Stop the flow computation"""
	is_computing = false
	computation_timer.stop()

func reset_network():
	"""Reset the network and computation"""
	stop_computation()
	computation_complete = false
	current_flow = 0
	max_flow_value = 0
	
	initialize_graph()
	create_visualization()
	update_ui()

func change_algorithm(new_algorithm: String):
	"""Change the flow algorithm"""
	algorithm_type = new_algorithm
	reset_network()
	print("Changed to ", new_algorithm, " algorithm")

func get_algorithm_info() -> Dictionary:
	"""Get comprehensive algorithm information"""
	return {
		"name": "Network Flow",
		"algorithm": algorithm_type,
		"description": "Maximum flow computation with min-cut theorem",
		"graph_properties": {
			"nodes": graph_size,
			"edges": edges.size(),
			"density": edge_density,
			"capacity_range": [min_capacity, max_capacity]
		},
		"flow_results": {
			"maximum_flow": max_flow_value,
			"current_flow": current_flow,
			"augmenting_paths": all_augmenting_paths.size(),
			"min_cut_nodes": min_cut_nodes,
			"flow_efficiency": get_flow_efficiency()
		},
		"status": {
			"is_computing": is_computing,
			"computation_complete": computation_complete,
			"source_node": source_node,
			"sink_node": sink_node
		}
	} 