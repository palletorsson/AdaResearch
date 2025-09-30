class_name PushRelabel
extends Node3D

# Push-Relabel Algorithm: Maximum Flow
# Visualizes the preflow-based approach to finding maximum flow in networks
# Explores the concepts of excess flow, height labels, and push/relabel operations

@export_category("Push-Relabel Configuration")
@export var graph_size: int = 6  # Number of nodes
@export var edge_density: float = 0.5  # Connection probability
@export var auto_start: bool = true
@export var step_by_step: bool = true
@export var animation_delay: float = 1.2

@export_category("Visualization")
@export var show_excess_flow: bool = true
@export var show_height_labels: bool = true
@export var show_flow_values: bool = true
@export var show_capacity_labels: bool = true
@export var highlight_active_nodes: bool = true
@export var animate_push_operations: bool = true
@export var show_residual_graph: bool = true

@export_category("Interactive Mode")
@export var enable_graph_editing: bool = true
@export var allow_capacity_editing: bool = true
@export var real_time_flow_update: bool = true
@export var show_algorithm_state: bool = true

# Colors for visualization
@export var node_color: Color = Color(0.3, 0.5, 0.8, 1.0)
@export var source_color: Color = Color(0.2, 0.8, 0.2, 1.0)
@export var sink_color: Color = Color(0.8, 0.2, 0.2, 1.0)
@export var active_color: Color = Color(0.9, 0.9, 0.2, 1.0)  # Nodes with excess
@export var edge_color: Color = Color(0.6, 0.6, 0.6, 0.8)
@export var flow_color: Color = Color(0.9, 0.3, 0.3, 1.0)
@export var residual_color: Color = Color(0.3, 0.9, 0.3, 0.8)
@export var push_highlight_color: Color = Color(0.9, 0.5, 0.2, 1.0)

# Graph representation
var nodes: Array = []
var edges: Array = []
var adjacency_list: Dictionary = {}
var capacity_matrix: Array = []
var flow_matrix: Array = []
var source: String = ""
var sink: String = ""

# Push-Relabel algorithm state
var height: Dictionary = {}
var excess: Dictionary = {}
var active_nodes: Array = []
var max_flow: int = 0
var algorithm_running: bool = false
var algorithm_step: int = 0
var current_operation: String = ""

# Visual elements
var node_spheres: Dictionary = {}
var edge_lines: Dictionary = {}
var flow_particles: Array = []
var info_label: Label3D
var flow_label: Label3D
var operation_label: Label3D

func _ready():
	setup_environment()
	initialize_graph()
	create_visual_elements()
	
	if auto_start:
		call_deferred("start_algorithm")

func setup_environment():
	# Add lighting
	var light := DirectionalLight3D.new()
	light.name = "SunLight"
	light.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	light.light_energy = 1.2
	add_child(light)
	
	# Add ambient lighting
	var ambient := WorldEnvironment.new()
	ambient.environment = Environment.new()
	ambient.environment.background_color = Color(0.05, 0.05, 0.1)
	ambient.environment.background_mode = Environment.BG_COLOR
	add_child(ambient)
	
	# Add camera
	var camera := Camera3D.new()
	camera.name = "AlgorithmCamera"
	camera.position = Vector3(8.0, 6.0, 12.0)
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	camera.current = true
	add_child(camera)

func initialize_graph():
	nodes.clear()
	edges.clear()
	adjacency_list.clear()
	height.clear()
	excess.clear()
	active_nodes.clear()
	max_flow = 0
	algorithm_running = false
	algorithm_step = 0
	current_operation = ""
	
	# Generate random flow network
	generate_random_network()
	
	# Initialize algorithm state
	for node in nodes:
		height[node] = 0
		excess[node] = 0

func generate_random_network():
	# Create nodes
	for i in range(graph_size):
		var node = "n" + str(i)
		nodes.append(node)
		adjacency_list[node] = []
	
	# Set source and sink
	source = nodes[0]
	sink = nodes[graph_size - 1]
	
	# Initialize matrices
	capacity_matrix.resize(graph_size)
	flow_matrix.resize(graph_size)
	for i in range(graph_size):
		capacity_matrix[i] = []
		flow_matrix[i] = []
		for j in range(graph_size):
			capacity_matrix[i].append(0)
			flow_matrix[i].append(0)
	
	# Create edges with random capacities
	for i in range(graph_size):
		for j in range(graph_size):
			if i != j and randf() < edge_density:
				var capacity = randi() % 10 + 1
				edges.append({"from": nodes[i], "to": nodes[j], "capacity": capacity})
				adjacency_list[nodes[i]].append(nodes[j])
				capacity_matrix[i][j] = capacity
	
	# Ensure connectivity from source to sink
	ensure_connectivity()

func ensure_connectivity():
	# Add a path from source to sink if none exists
	var has_path = false
	for edge in edges:
		if edge.from == source and edge.to == sink:
			has_path = true
			break
	
	if not has_path:
		# Create a simple path through middle nodes
		var middle_nodes = nodes.slice(1, graph_size - 1)
		if middle_nodes.size() > 0:
			var path_node = middle_nodes[0]
			edges.append({"from": source, "to": path_node, "capacity": 5})
			edges.append({"from": path_node, "to": sink, "capacity": 5})
			adjacency_list[source].append(path_node)
			adjacency_list[path_node].append(sink)
			capacity_matrix[0][1] = 5
			capacity_matrix[1][graph_size - 1] = 5

func create_visual_elements():
	# Clear existing visuals
	for child in get_children():
		if child.name.begins_with("Node_") or child.name.begins_with("Edge_") or child.name.begins_with("Flow_"):
			child.queue_free()
	
	node_spheres.clear()
	edge_lines.clear()
	flow_particles.clear()
	
	# Create node spheres
	var radius = 2.0
	var angle_step = 2.0 * PI / nodes.size()
	
	for i in range(nodes.size()):
		var node = nodes[i]
		var angle = i * angle_step
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		var y = 0.0
		
		var sphere := MeshInstance3D.new()
		sphere.name = "Node_" + node
		sphere.mesh = SphereMesh.new()
		sphere.mesh.radius = 0.2
		sphere.mesh.height = 0.4
		sphere.position = Vector3(x, y, z)
		
		var material := StandardMaterial3D.new()
		if node == source:
			material.albedo_color = source_color
		elif node == sink:
			material.albedo_color = sink_color
		else:
			material.albedo_color = node_color
		material.emission = material.albedo_color * 0.3
		sphere.material_override = material
		
		add_child(sphere)
		node_spheres[node] = sphere
		
		# Add node label
		var label := Label3D.new()
		label.text = node
		label.font_size = 16
		label.position = Vector3(0, 0.5, 0)
		sphere.add_child(label)
		
		# Add height label
		var height_label := Label3D.new()
		height_label.text = "h:0"
		height_label.font_size = 12
		height_label.position = Vector3(0, -0.5, 0)
		sphere.add_child(height_label)
		
		# Add excess label
		var excess_label := Label3D.new()
		excess_label.text = "e:0"
		excess_label.font_size = 12
		excess_label.position = Vector3(0, -0.7, 0)
		sphere.add_child(excess_label)
	
	# Create edge lines
	for edge in edges:
		create_edge_visual(edge)
	
	# Create info labels
	create_info_labels()

func create_edge_visual(edge: Dictionary):
	var from_pos = node_spheres[edge.from].position
	var to_pos = node_spheres[edge.to].position
	
	var line := MeshInstance3D.new()
	line.name = "Edge_" + edge.from + "_" + edge.to
	line.mesh = create_arrow_mesh(from_pos, to_pos)
	
	var material := StandardMaterial3D.new()
	material.albedo_color = edge_color
	material.emission = edge_color * 0.2
	line.material_override = material
	
	add_child(line)
	edge_lines[edge.from + "_" + edge.to] = line
	
	# Add capacity label
	var capacity_label := Label3D.new()
	capacity_label.text = "c:" + str(edge.capacity)
	capacity_label.font_size = 10
	capacity_label.position = (from_pos + to_pos) / 2 + Vector3(0, 0.3, 0)
	add_child(capacity_label)

func create_arrow_mesh(from: Vector3, to: Vector3) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices_array := PackedVector3Array()
	var indices := PackedInt32Array()
	
	# Create arrow line
	var direction = (to - from).normalized()
	var length = from.distance_to(to)
	var mid_point = from + direction * (length * 0.7)
	
	# Line vertices
	vertices_array.append(from)
	vertices_array.append(mid_point)
	
	# Arrow head
	var arrow_size = 0.1
	var perpendicular = Vector3(-direction.z, 0, direction.x).normalized()
	
	vertices_array.append(mid_point)
	vertices_array.append(to)
	vertices_array.append(to + perpendicular * arrow_size - direction * arrow_size)
	vertices_array.append(to - perpendicular * arrow_size - direction * arrow_size)
	
	# Indices for line
	indices.append(0)
	indices.append(1)
	
	# Indices for arrow head
	indices.append(2)
	indices.append(3)
	indices.append(4)
	indices.append(2)
	indices.append(3)
	indices.append(5)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices_array
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh

func create_info_labels():
	info_label = Label3D.new()
	info_label.text = "Push-Relabel Algorithm: Maximum Flow"
	info_label.font_size = 20
	info_label.position = Vector3(0, 4, 0)
	add_child(info_label)
	
	flow_label = Label3D.new()
	flow_label.text = "Max Flow: 0"
	flow_label.font_size = 16
	flow_label.position = Vector3(0, 3.5, 0)
	add_child(flow_label)
	
	operation_label = Label3D.new()
	operation_label.text = "Operation: Initializing"
	operation_label.font_size = 16
	operation_label.position = Vector3(0, 3, 0)
	add_child(operation_label)

func start_algorithm():
	if algorithm_running:
		return
	
	algorithm_running = true
	algorithm_step = 0
	max_flow = 0
	
	# Initialize preflow
	initialize_preflow()
	
	# Start push-relabel operations
	call_deferred("push_relabel_loop")

func initialize_preflow():
	# Set source height to number of nodes
	height[source] = len(nodes)
	
	# Saturate all edges from source
	for edge in edges:
		if edge.from == source:
			var flow = edge.capacity
			flow_matrix[0][get_node_index(edge.to)] = flow
			excess[edge.to] += flow
			excess[source] -= flow
			
			# Add to active nodes if not sink
			if edge.to != sink and edge.to not in active_nodes:
				active_nodes.append(edge.to)
	
	update_visuals()

func push_relabel_loop():
	if not algorithm_running or active_nodes.is_empty():
		algorithm_running = false
		max_flow = excess[sink]
		update_flow_display()
		update_operation_text("Algorithm completed! Max flow: " + str(max_flow))
		return
	
	# Select active node (first in list)
	var u = active_nodes[0]
	current_operation = "Processing node: " + u
	
	# Try to push flow
	var pushed = false
	for edge in edges:
		if edge.from == u and excess[u] > 0:
			var v = edge.to
			var residual_capacity = edge.capacity - flow_matrix[get_node_index(u)][get_node_index(v)]
			
			if residual_capacity > 0 and height[u] > height[v]:
				# Push operation
				var push_amount = min(excess[u], residual_capacity)
				flow_matrix[get_node_index(u)][get_node_index(v)] += push_amount
				excess[u] -= push_amount
				excess[v] += push_amount
				
				# Add to active nodes if not sink
				if v != sink and v not in active_nodes:
					active_nodes.append(v)
				
				pushed = true
				update_operation_text("Push: " + str(push_amount) + " from " + u + " to " + v)
				highlight_push_operation(u, v)
				break
	
	if not pushed and excess[u] > 0:
		# Relabel operation
		var min_height = INF
		for edge in edges:
			if edge.from == u:
				var v = edge.to
				var residual_capacity = edge.capacity - flow_matrix[get_node_index(u)][get_node_index(v)]
				if residual_capacity > 0:
					min_height = min(min_height, height[v])
		
		if min_height != INF:
			height[u] = min_height + 1
			update_operation_text("Relabel: " + u + " height = " + str(height[u]))
	
	# Remove from active nodes if no excess
	if excess[u] <= 0:
		active_nodes.erase(u)
	
	update_visuals()
	algorithm_step += 1
	
	if step_by_step:
		await get_tree().create_timer(animation_delay).timeout
	
	call_deferred("push_relabel_loop")

func get_node_index(node: String) -> int:
	return nodes.find(node)

func highlight_push_operation(from: String, to: String):
	# Highlight the edge being used for push
	var edge_key = from + "_" + to
	if edge_lines.has(edge_key):
		var material := StandardMaterial3D.new()
		material.albedo_color = push_highlight_color
		material.emission = push_highlight_color * 0.5
		edge_lines[edge_key].material_override = material

func update_visuals():
	# Update node colors based on state
	for node in nodes:
		var sphere = node_spheres[node]
		var material := StandardMaterial3D.new()
		
		if node == source:
			material.albedo_color = source_color
		elif node == sink:
			material.albedo_color = sink_color
		elif node in active_nodes:
			material.albedo_color = active_color
		else:
			material.albedo_color = node_color
		
		material.emission = material.albedo_color * 0.3
		sphere.material_override = material
		
		# Update height and excess labels
		var height_label = sphere.get_child(1)
		var excess_label = sphere.get_child(2)
		height_label.text = "h:" + str(height[node])
		excess_label.text = "e:" + str(excess[node])
	
	# Update edge colors based on flow
	for edge in edges:
		var edge_key = edge.from + "_" + edge.to
		if edge_lines.has(edge_key):
			var flow = flow_matrix[get_node_index(edge.from)][get_node_index(edge.to)]
			var material := StandardMaterial3D.new()
			
			if flow > 0:
				material.albedo_color = flow_color
				material.emission = flow_color * 0.3
			else:
				material.albedo_color = edge_color
				material.emission = edge_color * 0.2
			
			edge_lines[edge_key].material_override = material

func update_flow_display():
	if flow_label:
		flow_label.text = "Max Flow: " + str(max_flow)

func update_operation_text(text: String):
	if operation_label:
		operation_label.text = "Operation: " + text

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if algorithm_running:
			stop_algorithm()
		else:
			start_algorithm()
	elif event.is_action_pressed("ui_cancel"):
		reset_algorithm()

func stop_algorithm():
	algorithm_running = false
	update_operation_text("Algorithm stopped")

func reset_algorithm():
	algorithm_running = false
	algorithm_step = 0
	initialize_graph()
	create_visual_elements()
	update_operation_text("Initializing")

func get_algorithm_info() -> Dictionary:
	return {
		"name": "Push-Relabel Algorithm",
		"description": "Preflow-based algorithm for finding maximum flow",
		"time_complexity": "O(V²E)",
		"space_complexity": "O(V + E)",
		"max_flow": max_flow,
		"current_step": algorithm_step,
		"active_nodes": active_nodes.size()
	}
