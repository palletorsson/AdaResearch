class_name MSTVisualization
extends Node3D

# Minimum Spanning Tree: Connection Politics & Optimal Networks
# Visualizes MST algorithms with edge selection and cost optimization
# Explores network connectivity and resource allocation strategies

@export_category("MST Configuration")
@export var algorithm_type: String = "kruskal"  # kruskal, prim, boruvka
@export var graph_size: int = 10  # Number of vertices
@export var edge_density: float = 0.5  # Connection probability
@export var min_weight: float = 1.0
@export var max_weight: float = 15.0
@export var use_euclidean_weights: bool = true  # Distance-based weights

@export_category("Visualization")
@export var show_edge_weights: bool = true
@export var show_mst_cost: bool = true
@export var animate_edge_selection: bool = true
@export var highlight_current_edgea: bool = true
@export var show_rejected_edges: bool = true

@export_category("Interactive Mode")
@export var enable_graph_editing: bool = true
@export var allow_weight_editing: bool = true
@export var real_time_mst_update: bool = true
@export var show_algorithm_state: bool = true

@export_category("Animation")
@export var auto_start: bool = true
@export var step_by_step: bool = true
@export var animation_delay: float = 1.0
@export var edge_selection_duration: float = 0.8

# Colors for visualization
@export var vertex_color: Color = Color(0.4, 0.6, 0.9, 1.0)
@export var edge_color: Color = Color(0.5, 0.5, 0.5, 0.8)
@export var mst_edge_color: Color = Color(0.2, 0.9, 0.3, 1.0)
@export var current_edge_color: Color = Color(0.9, 0.9, 0.2, 1.0)
@export var rejected_edge_color: Color = Color(0.9, 0.2, 0.2, 0.6)
@export var starting_vertex_color: Color = Color(0.9, 0.3, 0.9, 1.0)

# Graph representation
var vertices: Array = []
var edges: Array = []
var adjacency_list: Dictionary = {}
var edge_weights: Dictionary = {}

# MST algorithm state
var mst_edges: Array = []
var mst_cost: float = 0.0
var current_edge_index: int = 0
var is_computing: bool = false
var computation_complete: bool = false
var rejected_edges: Array = []

# Union-Find data structure (for Kruskal's)
var parent: Array = []
var rank: Array = []

# Prim's algorithm state
var in_mst: Array = []
var key_values: Array = []
var prim_starting_vertex: int = 0

# Visualization elements
var vertex_meshes: Array = []
var edge_meshes: Array = []
var mst_edge_meshes: Array = []
var edge_labels: Array = []
var ui_display: CanvasLayer
var computation_timer: Timer

# Algorithm tracking
var sorted_edges: Array = []
var algorithm_steps: Array = []
var current_step: int = 0

func _init():
	name = "MST_Visualization"

func _ready():
	setup_ui()
	setup_timer()
	initialize_graph()
	create_visualization()
	
	if auto_start:
		call_deferred("start_mst_computation")

func setup_ui():
	"""Create comprehensive UI for MST visualization"""
	ui_display = CanvasLayer.new()
	add_child(ui_display)
	
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(500, 900)
	panel.position = Vector2(10, 10)
	ui_display.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Create labels for MST information
	for i in range(35):
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
	"""Initialize the graph with vertices and edges"""
	vertices.clear()
	edges.clear()
	adjacency_list.clear()
	edge_weights.clear()
	
	# Create vertices
	for i in range(graph_size):
		var vertex = {
			"id": i,
			"position": Vector3.ZERO,
			"label": "V" + str(i)
		}
		vertices.append(vertex)
		adjacency_list[i] = []
	
	# Generate vertex positions
	generate_vertex_positions()
	
	# Generate edges based on density
	generate_graph_edges()
	
	# Initialize algorithm state
	reset_algorithm_state()
	
	print("Initialized graph with ", vertices.size(), " vertices and ", edges.size(), " edges")

func generate_vertex_positions():
	"""Generate positions for vertices"""
	var radius = 8.0
	
	if graph_size <= 8:
		# Circular layout for smaller graphs
		var angle_increment = 2.0 * PI / graph_size
		for i in range(graph_size):
			var angle = i * angle_increment
			var x = radius * cos(angle)
			var y = radius * sin(angle)
			var z = randf_range(-0.5, 0.5)
			vertices[i].position = Vector3(x, y, z)
	else:
		# Grid-like layout for larger graphs
		var grid_size = ceil(sqrt(graph_size))
		var spacing = radius * 2.0 / grid_size
		
		for i in range(graph_size):
			var row = i / grid_size
			var col = fmod(i, grid_size)
			var x = (col - grid_size / 2.0) * spacing
			var y = (row - grid_size / 2.0) * spacing
			var z = randf_range(-0.5, 0.5)
			vertices[i].position = Vector3(x, y, z)

func generate_graph_edges():
	"""Generate edges based on density and weight constraints"""
	edges.clear()
	
	# Generate all possible edges
	var possible_edges = []
	for i in range(graph_size):
		for j in range(i + 1, graph_size):
			possible_edges.append([i, j])
	
	# Shuffle and select based on density
	possible_edges.shuffle()
	var num_edges = int(possible_edges.size() * edge_density)
	
	# Ensure graph connectivity (minimum spanning tree exists)
	ensure_connectivity()
	
	# Add additional edges up to density
	for i in range(min(num_edges, possible_edges.size())):
		var edge_pair = possible_edges[i]
		var from_vertex = edge_pair[0]
		var to_vertex = edge_pair[1]
		
		if not has_edge(from_vertex, to_vertex):
			add_edge(from_vertex, to_vertex)

func ensure_connectivity():
	"""Ensure graph is connected by creating a spanning tree"""
	var connected_vertices = [0]  # Start with vertex 0
	var remaining_vertices = []
	
	for i in range(1, graph_size):
		remaining_vertices.append(i)
	
	# Connect remaining vertices one by one
	while remaining_vertices.size() > 0:
		var from_vertex = connected_vertices[randi() % connected_vertices.size()]
		var to_vertex = remaining_vertices.pop_at(randi() % remaining_vertices.size())
		
		add_edge(from_vertex, to_vertex)
		connected_vertices.append(to_vertex)

func has_edge(from_vertex: int, to_vertex: int) -> bool:
	"""Check if edge already exists"""
	for edge in edges:
		if (edge.from == from_vertex and edge.to == to_vertex) or \
		   (edge.from == to_vertex and edge.to == from_vertex):
			return true
	return false

func add_edge(from_vertex: int, to_vertex: int):
	"""Add an edge with calculated weight"""
	var weight: float
	
	if use_euclidean_weights:
		# Use Euclidean distance as weight
		var pos1 = vertices[from_vertex].position
		var pos2 = vertices[to_vertex].position
		weight = pos1.distance_to(pos2)
	else:
		# Use random weight
		weight = randf_range(min_weight, max_weight)
	
	var edge = {
		"from": from_vertex,
		"to": to_vertex,
		"weight": weight,
		"in_mst": false,
		"rejected": false
	}
	
	edges.append(edge)
	adjacency_list[from_vertex].append(to_vertex)
	adjacency_list[to_vertex].append(from_vertex)
	edge_weights[str(from_vertex) + "_" + str(to_vertex)] = weight
	edge_weights[str(to_vertex) + "_" + str(from_vertex)] = weight

func reset_algorithm_state():
	"""Reset MST algorithm state"""
	mst_edges.clear()
	mst_cost = 0.0
	current_edge_index = 0
	is_computing = false
	computation_complete = false
	rejected_edges.clear()
	algorithm_steps.clear()
	current_step = 0
	
	# Reset edge states
	for edge in edges:
		edge.in_mst = false
		edge.rejected = false
	
	# Initialize Union-Find
	parent.clear()
	rank.clear()
	for i in range(graph_size):
		parent.append(i)
		rank.append(0)
	
	# Initialize Prim's state
	in_mst.clear()
	key_values.clear()
	for i in range(graph_size):
		in_mst.append(false)
		key_values.append(INF)

func create_visualization():
	"""Create 3D visualization of the graph"""
	clear_visualization()
	create_vertex_visualization()
	create_edge_visualization()

func clear_visualization():
	"""Clear existing visualization elements"""
	for mesh in vertex_meshes:
		if mesh:
			mesh.queue_free()
	for mesh in edge_meshes:
		if mesh:
			mesh.queue_free()
	for mesh in mst_edge_meshes:
		if mesh:
			mesh.queue_free()
	for label in edge_labels:
		if label:
			label.queue_free()
	
	vertex_meshes.clear()
	edge_meshes.clear()
	mst_edge_meshes.clear()
	edge_labels.clear()

func create_vertex_visualization():
	"""Create visual representation of vertices"""
	for i in range(vertices.size()):
		var vertex = vertices[i]
		var mesh_instance = MeshInstance3D.new()
		
		# Create vertex mesh
		var mesh = SphereMesh.new()
		mesh.radius = 0.4
		mesh.height = 0.8
		mesh_instance.mesh = mesh
		
		# Set vertex material
		var material = StandardMaterial3D.new()
		if i == prim_starting_vertex and algorithm_type == "prim":
			material.albedo_color = starting_vertex_color
			material.emission_enabled = true
			material.emission = starting_vertex_color * 0.3
		else:
			material.albedo_color = vertex_color
			material.emission_enabled = true
			material.emission = vertex_color * 0.2
		
		mesh_instance.material_override = material
		mesh_instance.position = vertex.position
		
		# Add vertex label
		if show_edge_weights:
			create_vertex_label(mesh_instance, vertex.label, Vector3(0, 1.0, 0))
		
		add_child(mesh_instance)
		vertex_meshes.append(mesh_instance)

func create_edge_visualization():
	"""Create visual representation of edges"""
	for i in range(edges.size()):
		var edge = edges[i]
		var from_pos = vertices[edge.from].position
		var to_pos = vertices[edge.to].position
		
		# Create edge line
		var edge_mesh = create_edge_line(from_pos, to_pos, edge_color)
		add_child(edge_mesh)
		edge_meshes.append(edge_mesh)
		
		# Create weight label
		if show_edge_weights:
			var mid_pos = (from_pos + to_pos) / 2.0
			var label = create_edge_label(str(edge.weight).pad_decimals(1), mid_pos + Vector3(0, 0.5, 0))
			add_child(label)
			edge_labels.append(label)

func create_edge_line(from_pos: Vector3, to_pos: Vector3, color: Color) -> MeshInstance3D:
	"""Create a line mesh between two positions"""
	var mesh_instance = MeshInstance3D.new()
	var mesh = create_line_mesh(from_pos, to_pos)
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.3
	mesh_instance.material_override = material
	
	return mesh_instance

func create_line_mesh(from_pos: Vector3, to_pos: Vector3) -> ArrayMesh:
	"""Create mesh for line between two points"""
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices_array = PackedVector3Array()
	var indices = PackedInt32Array()
	
	vertices_array.append(from_pos)
	vertices_array.append(to_pos)
	indices.append(0)
	indices.append(1)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices_array
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	
	return array_mesh

func create_vertex_label(parent: MeshInstance3D, text: String, offset: Vector3):
	"""Create text label for vertex"""
	var label = Label3D.new()
	label.text = text
	label.position = offset
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color.WHITE
	parent.add_child(label)

func create_edge_label(text: String, position: Vector3) -> Label3D:
	"""Create text label for edge weight"""
	var label = Label3D.new()
	label.text = text
	label.position = position
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color.YELLOW
	return label

func start_mst_computation():
	"""Start the MST computation"""
	if is_computing:
		return
	
	is_computing = true
	computation_complete = false
	reset_algorithm_state()
	
	match algorithm_type:
		"kruskal":
			start_kruskal()
		"prim":
			start_prim()
		"boruvka":
			start_boruvka()
		_:
			start_kruskal()
	
	print("Starting ", algorithm_type, " MST algorithm...")

func start_kruskal():
	"""Start Kruskal's algorithm"""
	# Sort edges by weight
	sorted_edges = edges.duplicate()
	sorted_edges.sort_custom(func(a, b): return a.weight < b.weight)
	
	if step_by_step:
		computation_timer.start()
	else:
		run_kruskal_complete()

func run_kruskal_complete():
	"""Run complete Kruskal's algorithm"""
	for edge in sorted_edges:
		if mst_edges.size() >= graph_size - 1:
			break
		
		var root_from = find_union_find(edge.from)
		var root_to = find_union_find(edge.to)
		
		if root_from != root_to:
			# Add edge to MST
			edge.in_mst = true
			mst_edges.append(edge)
			mst_cost += edge.weight
			union_union_find(edge.from, edge.to)
		else:
			# Reject edge (creates cycle)
			edge.rejected = true
			rejected_edges.append(edge)
	
	finalize_computation()

func start_prim():
	"""Start Prim's algorithm"""
	# Initialize starting vertex
	key_values[prim_starting_vertex] = 0.0
	
	if step_by_step:
		computation_timer.start()
	else:
		run_prim_complete()

func run_prim_complete():
	"""Run complete Prim's algorithm"""
	for i in range(graph_size):
		# Find minimum key vertex not in MST
		var min_key = INF
		var min_vertex = -1
		
		for v in range(graph_size):
			if not in_mst[v] and key_values[v] < min_key:
				min_key = key_values[v]
				min_vertex = v
		
		if min_vertex == -1:
			break
		
		# Add vertex to MST
		in_mst[min_vertex] = true
		
		# Find the edge that brought this vertex to MST
		if min_vertex != prim_starting_vertex:
			for edge in edges:
				if ((edge.from == min_vertex or edge.to == min_vertex) and 
					edge.weight == min_key):
					# Check if the other vertex is in MST
					var other_vertex = edge.to if edge.from == min_vertex else edge.from
					if in_mst[other_vertex]:
						edge.in_mst = true
						mst_edges.append(edge)
						mst_cost += edge.weight
						break
		
		# Update key values of adjacent vertices
		for adj_vertex in adjacency_list[min_vertex]:
			var edge_weight = get_edge_weight(min_vertex, adj_vertex)
			if not in_mst[adj_vertex] and edge_weight < key_values[adj_vertex]:
				key_values[adj_vertex] = edge_weight
	
	finalize_computation()

func start_boruvka():
	"""Start Boruvka's algorithm (simplified version)"""
	# For now, use Kruskal's as placeholder
	start_kruskal()

# Union-Find data structure operations
func find_union_find(vertex: int) -> int:
	"""Find root of vertex with path compression"""
	if parent[vertex] != vertex:
		parent[vertex] = find_union_find(parent[vertex])
	return parent[vertex]

func union_union_find(vertex1: int, vertex2: int):
	"""Union two sets by rank"""
	var root1 = find_union_find(vertex1)
	var root2 = find_union_find(vertex2)
	
	if rank[root1] < rank[root2]:
		parent[root1] = root2
	elif rank[root1] > rank[root2]:
		parent[root2] = root1
	else:
		parent[root2] = root1
		rank[root1] += 1

func get_edge_weight(from_vertex: int, to_vertex: int) -> float:
	"""Get weight of edge between two vertices"""
	var key = str(from_vertex) + "_" + str(to_vertex)
	if key in edge_weights:
		return edge_weights[key]
	
	key = str(to_vertex) + "_" + str(from_vertex)
	if key in edge_weights:
		return edge_weights[key]
	
	return INF

func _on_computation_timer_timeout():
	"""Handle step-by-step computation timer"""
	if not is_computing:
		return
	
	match algorithm_type:
		"kruskal":
			step_kruskal()
		"prim":
			step_prim()
		_:
			step_kruskal()

func step_kruskal():
	"""Perform one step of Kruskal's algorithm"""
	if current_edge_index >= sorted_edges.size() or mst_edges.size() >= graph_size - 1:
		finalize_computation()
		return
	
	var edge = sorted_edges[current_edge_index]
	highlight_current_edge(edge)
	
	var root_from = find_union_find(edge.from)
	var root_to = find_union_find(edge.to)
	
	if root_from != root_to:
		# Add edge to MST
		edge.in_mst = true
		mst_edges.append(edge)
		mst_cost += edge.weight
		union_union_find(edge.from, edge.to)
		create_mst_edge_visualization(edge)
	else:
		# Reject edge (creates cycle)
		edge.rejected = true
		rejected_edges.append(edge)
		#if show_rejected_edges:
			#highlight_rejected_edge(edge)
	
	current_edge_index += 1
	update_ui()

func step_prim():
	"""Perform one step of Prim's algorithm"""
	# Find minimum key vertex not in MST
	var min_key = INF
	var min_vertex = -1
	
	for v in range(graph_size):
		if not in_mst[v] and key_values[v] < min_key:
			min_key = key_values[v]
			min_vertex = v
	
	if min_vertex == -1:
		finalize_computation()
		return
	
	# Add vertex to MST
	in_mst[min_vertex] = true
	
	# Find and highlight the edge that brought this vertex to MST
	if min_vertex != prim_starting_vertex:
		for edge in edges:
			if ((edge.from == min_vertex or edge.to == min_vertex) and 
				edge.weight == min_key):
				var other_vertex = edge.to if edge.from == min_vertex else edge.from
				if in_mst[other_vertex]:
					edge.in_mst = true
					mst_edges.append(edge)
					mst_cost += edge.weight
					create_mst_edge_visualization(edge)
					break
	
	# Update vertex visualization
	if min_vertex < vertex_meshes.size():
		var mesh = vertex_meshes[min_vertex]
		var material = mesh.material_override as StandardMaterial3D
		material.emission = starting_vertex_color * 0.5
	
	# Update key values of adjacent vertices
	for adj_vertex in adjacency_list[min_vertex]:
		var edge_weight = get_edge_weight(min_vertex, adj_vertex)
		if not in_mst[adj_vertex] and edge_weight < key_values[adj_vertex]:
			key_values[adj_vertex] = edge_weight
	
	update_ui()

func highlight_current_edge(edge):
	"""Highlight the currently considered edge"""
	var edge_index = edges.find(edge)
	if edge_index >= 0 and edge_index < edge_meshes.size():
		var mesh = edge_meshes[edge_index]
		var material = mesh.material_override as StandardMaterial3D
		material.albedo_color = current_edge_color
		material.emission = current_edge_color * 0.5

 

func create_mst_edge_visualization(edge):
	"""Create visualization for MST edge"""
	var from_pos = vertices[edge.from].position
	var to_pos = vertices[edge.to].position
	
	var mst_mesh = create_edge_line(from_pos, to_pos, mst_edge_color)
	
	# Make MST edges thicker
	var material = mst_mesh.material_override as StandardMaterial3D
	material.emission = mst_edge_color * 0.6
	
	add_child(mst_mesh)
	mst_edge_meshes.append(mst_mesh)

func finalize_computation():
	"""Finalize the MST computation"""
	is_computing = false
	computation_complete = true
	computation_timer.stop()
	
	print("MST computation complete!")
	print("Algorithm: ", algorithm_type)
	print("MST cost: ", mst_cost)
	print("MST edges: ", mst_edges.size())
	print("Expected edges: ", graph_size - 1)
	
	update_ui()

func update_ui():
	"""Update UI with current algorithm state"""
	if not ui_display:
		return
	
	var labels = []
	for i in range(35):
		var label = ui_display.get_node_or_null("Panel/VBoxContainer/info_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 35:
		labels[0].text = "🌳 Minimum Spanning Tree - Optimal Connections"
		labels[1].text = "Algorithm: " + algorithm_type.capitalize()
		labels[2].text = "Graph Size: " + str(graph_size) + " vertices"
		labels[3].text = "Edge Count: " + str(edges.size())
		labels[4].text = "Edge Density: " + str(edge_density * 100).pad_decimals(1) + "%"
		labels[5].text = ""
		labels[6].text = "Status: " + ("Computing..." if is_computing else "Complete" if computation_complete else "Ready")
		labels[7].text = "MST Cost: " + str(mst_cost).pad_decimals(2)
		labels[8].text = "MST Edges: " + str(mst_edges.size()) + "/" + str(graph_size - 1)
		labels[9].text = "Rejected Edges: " + str(rejected_edges.size())
		labels[10].text = ""
		
		if algorithm_type == "kruskal":
			labels[11].text = "Kruskal's Algorithm State:"
			labels[12].text = "Current Edge: " + str(current_edge_index) + "/" + str(sorted_edges.size())
			labels[13].text = "Edges Processed: " + str(current_edge_index)
			if current_edge_index > 0 and current_edge_index <= sorted_edges.size():
				var current_edge = sorted_edges[current_edge_index - 1]
				labels[14].text = "Last Edge: " + str(current_edge.from) + "-" + str(current_edge.to) + " (w=" + str(current_edge.weight).pad_decimals(1) + ")"
			else:
				labels[14].text = "Last Edge: None"
		elif algorithm_type == "prim":
			labels[11].text = "Prim's Algorithm State:"
			labels[12].text = "Starting Vertex: " + str(prim_starting_vertex)
			labels[13].text = "Vertices in MST: " + str(get_vertices_in_mst())
			labels[14].text = "Current Keys: " + get_current_keys_string()
		
		labels[15].text = ""
		labels[16].text = "Graph Properties:"
		labels[17].text = "Weight Range: " + str(min_weight).pad_decimals(1) + " - " + str(max_weight).pad_decimals(1)
		labels[18].text = "Euclidean Weights: " + ("Yes" if use_euclidean_weights else "No")
		labels[19].text = "Total Weight: " + str(get_total_weight()).pad_decimals(2)
		labels[20].text = "MST Efficiency: " + str(get_mst_efficiency() * 100).pad_decimals(1) + "%"
		labels[21].text = ""
		labels[22].text = "Union-Find State:" if algorithm_type == "kruskal" else "Prim State:"
		labels[23].text = "Components: " + str(get_connected_components()) if algorithm_type == "kruskal" else "Min Key: " + str(get_min_key()).pad_decimals(1)
		labels[24].text = ""
		labels[25].text = "Visualization:"
		labels[26].text = "Edge Weights: " + ("On" if show_edge_weights else "Off")
		labels[27].text = "MST Cost: " + ("On" if show_mst_cost else "Off")
		labels[28].text = "Rejected Edges: " + ("On" if show_rejected_edges else "Off")
		labels[29].text = "Animation: " + ("Step-by-step" if step_by_step else "Complete")
		labels[30].text = ""
		labels[31].text = "Controls:"
		labels[32].text = "SPACE - Start/Stop, R - Reset"
		labels[33].text = "1-3 - Algorithms, W - Toggle Weights"
		labels[34].text = "🏳️‍🌈 Explores optimal connection politics"

func get_vertices_in_mst() -> int:
	"""Count vertices currently in MST (for Prim's)"""
	var count = 0
	for in_tree in in_mst:
		if in_tree:
			count += 1
	return count

func get_current_keys_string() -> String:
	"""Get string representation of current key values"""
	var key_strings = []
	for i in range(min(5, key_values.size())):  # Show first 5 keys
		if key_values[i] == INF:
			key_strings.append("∞")
		else:
			key_strings.append(str(key_values[i]).pad_decimals(1))
	return "[" + ", ".join(key_strings) + ("..." if key_values.size() > 5 else "") + "]"

func get_total_weight() -> float:
	"""Get total weight of all edges"""
	var total = 0.0
	for edge in edges:
		total += edge.weight
	return total

func get_mst_efficiency() -> float:
	"""Get efficiency of MST (MST cost / total edge weight)"""
	var total_weight = get_total_weight()
	if total_weight == 0:
		return 0.0
	return mst_cost / total_weight

func get_connected_components() -> int:
	"""Get number of connected components (for Kruskal's)"""
	var components = {}
	for i in range(graph_size):
		var root = find_union_find(i)
		components[root] = true
	return components.size()

func get_min_key() -> float:
	"""Get minimum key value not in MST (for Prim's)"""
	var min_val = INF
	for i in range(graph_size):
		if not in_mst[i] and key_values[i] < min_val:
			min_val = key_values[i]
	return min_val

func _input(event):
	"""Handle user input"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				if is_computing:
					stop_computation()
				else:
					start_mst_computation()
			KEY_R:
				reset_graph()
			KEY_1:
				change_algorithm("kruskal")
			KEY_2:
				change_algorithm("prim")
			KEY_3:
				change_algorithm("boruvka")
			KEY_W:
				show_edge_weights = not show_edge_weights
				create_visualization()
			KEY_S:
				step_by_step = not step_by_step
				print("Step-by-step mode: ", step_by_step)

func stop_computation():
	"""Stop the MST computation"""
	is_computing = false
	computation_timer.stop()

func reset_graph():
	"""Reset the graph and computation"""
	stop_computation()
	computation_complete = false
	
	initialize_graph()
	create_visualization()

func change_algorithm(new_algorithm: String):
	"""Change the MST algorithm"""
	algorithm_type = new_algorithm
	reset_graph()
	print("Changed to ", new_algorithm, " algorithm")

func get_algorithm_info() -> Dictionary:
	"""Get comprehensive algorithm information"""
	return {
		"name": "Minimum Spanning Tree",
		"algorithm": algorithm_type,
		"description": "Find minimum cost spanning tree",
		"graph_properties": {
			"vertices": graph_size,
			"edges": edges.size(),
			"density": edge_density,
			"weight_range": [min_weight, max_weight],
			"euclidean_weights": use_euclidean_weights
		},
		"mst_results": {
			"mst_cost": mst_cost,
			"mst_edges": mst_edges.size(),
			"expected_edges": graph_size - 1,
			"rejected_edges": rejected_edges.size(),
			"efficiency": get_mst_efficiency(),
			"connected_components": get_connected_components()
		},
		"status": {
			"is_computing": is_computing,
			"computation_complete": computation_complete,
			"current_step": current_step,
			"progress": float(current_edge_index) / float(edges.size()) if edges.size() > 0 else 0.0
		}
	} 
