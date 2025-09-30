class_name KargerAlgorithm
extends Node3D

# Karger's Algorithm: Minimum Cut
# Visualizes the randomized contraction algorithm for finding minimum cuts
# Explores the concept of edge contraction and cut probability

@export_category("Karger Configuration")
@export var graph_size: int = 8  # Number of vertices
@export var edge_density: float = 0.4  # Connection probability
@export var auto_start: bool = true
@export var step_by_step: bool = true
@export var animation_delay: float = 1.0
@export var num_iterations: int = 10  # Number of contraction attempts

@export_category("Visualization")
@export var show_contraction_steps: bool = true
@export var highlight_contracted_edges: bool = true
@export var show_cut_edges: bool = true
@export var animate_contraction: bool = true
@export var show_probability: bool = true
@export var show_best_cut: bool = true

@export_category("Interactive Mode")
@export var enable_graph_editing: bool = true
@export var allow_edge_editing: bool = true
@export var real_time_cut_update: bool = true
@export var show_algorithm_state: bool = true

# Colors for visualization
@export var vertex_color: Color = Color(0.4, 0.6, 0.9, 1.0)
@export var contracted_color: Color = Color(0.9, 0.2, 0.2, 1.0)
@export var cut_edge_color: Color = Color(0.9, 0.9, 0.2, 1.0)
@export var edge_color: Color = Color(0.6, 0.6, 0.6, 0.8)
@export var best_cut_color: Color = Color(0.9, 0.3, 0.9, 1.0)
@export var partition_a_color: Color = Color(0.2, 0.9, 0.2, 1.0)
@export var partition_b_color: Color = Color(0.2, 0.2, 0.9, 1.0)

# Graph representation
var vertices: Array = []
var edges: Array = []
var adjacency_list: Dictionary = {}
var original_edges: Array = []

# Karger's algorithm state
var contracted_vertices: Dictionary = {}
var current_cut: Array = []
var best_cut: Array = []
var min_cut_size: int = INF
var iteration: int = 0
var algorithm_running: bool = false
var algorithm_step: int = 0
var current_operation: String = ""

# Visual elements
var vertex_nodes: Dictionary = {}
var edge_lines: Dictionary = {}
var cut_indicators: Array = []
var info_label: Label3D
var iteration_label: Label3D
var cut_label: Label3D
var probability_label: Label3D

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
	vertices.clear()
	edges.clear()
	adjacency_list.clear()
	contracted_vertices.clear()
	current_cut.clear()
	best_cut.clear()
	min_cut_size = INF
	iteration = 0
	algorithm_running = false
	algorithm_step = 0
	current_operation = ""
	
	# Generate random graph
	generate_random_graph()
	
	# Store original edges
	original_edges = edges.duplicate(true)

func generate_random_graph():
	# Create vertices
	for i in range(graph_size):
		var vertex = "v" + str(i)
		vertices.append(vertex)
		adjacency_list[vertex] = []
		contracted_vertices[vertex] = [vertex]  # Each vertex starts as its own component
	
	# Create edges with probability edge_density
	for i in range(graph_size):
		for j in range(i + 1, graph_size):
			if randf() < edge_density:
				var from_vertex = "v" + str(i)
				var to_vertex = "v" + str(j)
				edges.append({"from": from_vertex, "to": to_vertex})
				adjacency_list[from_vertex].append(to_vertex)
				adjacency_list[to_vertex].append(from_vertex)
	
	# Ensure graph is connected
	ensure_connectivity()

func ensure_connectivity():
	# Add edges to ensure connectivity
	for i in range(graph_size - 1):
		var from_vertex = "v" + str(i)
		var to_vertex = "v" + str(i + 1)
		if not has_edge(from_vertex, to_vertex):
			edges.append({"from": from_vertex, "to": to_vertex})
			adjacency_list[from_vertex].append(to_vertex)
			adjacency_list[to_vertex].append(from_vertex)

func has_edge(from: String, to: String) -> bool:
	for edge in edges:
		if (edge.from == from and edge.to == to) or (edge.from == to and edge.to == from):
			return true
	return false

func create_visual_elements():
	# Clear existing visuals
	for child in get_children():
		if child.name.begins_with("Vertex_") or child.name.begins_with("Edge_") or child.name.begins_with("Cut_"):
			child.queue_free()
	
	vertex_nodes.clear()
	edge_lines.clear()
	cut_indicators.clear()
	
	# Create vertex spheres
	var radius = 2.0
	var angle_step = 2.0 * PI / vertices.size()
	
	for i in range(vertices.size()):
		var vertex = vertices[i]
		var angle = i * angle_step
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		var y = 0.0
		
		var sphere := MeshInstance3D.new()
		sphere.name = "Vertex_" + vertex
		sphere.mesh = SphereMesh.new()
		sphere.mesh.radius = 0.15
		sphere.mesh.height = 0.3
		sphere.position = Vector3(x, y, z)
		
		var material := StandardMaterial3D.new()
		material.albedo_color = vertex_color
		material.emission = vertex_color * 0.3
		sphere.material_override = material
		
		add_child(sphere)
		vertex_nodes[vertex] = sphere
		
		# Add vertex label
		var label := Label3D.new()
		label.text = vertex
		label.font_size = 16
		label.position = Vector3(0, 0.4, 0)
		sphere.add_child(label)
	
	# Create edge lines
	for edge in edges:
		create_edge_visual(edge)
	
	# Create info labels
	create_info_labels()

func create_edge_visual(edge: Dictionary):
	var from_pos = vertex_nodes[edge.from].position
	var to_pos = vertex_nodes[edge.to].position
	
	var line := MeshInstance3D.new()
	line.name = "Edge_" + edge.from + "_" + edge.to
	line.mesh = create_line_mesh(from_pos, to_pos)
	
	var material := StandardMaterial3D.new()
	material.albedo_color = edge_color
	material.emission = edge_color * 0.2
	line.material_override = material
	
	add_child(line)
	edge_lines[edge.from + "_" + edge.to] = line

func create_line_mesh(from: Vector3, to: Vector3) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices_array := PackedVector3Array()
	var indices := PackedInt32Array()
	
	# Create simple line
	vertices_array.append(from)
	vertices_array.append(to)
	
	indices.append(0)
	indices.append(1)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices_array
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh

func create_info_labels():
	info_label = Label3D.new()
	info_label.text = "Karger's Algorithm: Minimum Cut"
	info_label.font_size = 20
	info_label.position = Vector3(0, 4, 0)
	add_child(info_label)
	
	iteration_label = Label3D.new()
	iteration_label.text = "Iteration: 0/" + str(num_iterations)
	iteration_label.font_size = 16
	iteration_label.position = Vector3(0, 3.5, 0)
	add_child(iteration_label)
	
	cut_label = Label3D.new()
	cut_label.text = "Current Cut Size: 0"
	cut_label.font_size = 16
	cut_label.position = Vector3(0, 3, 0)
	add_child(cut_label)
	
	probability_label = Label3D.new()
	probability_label.text = "Success Probability: 0%"
	probability_label.font_size = 16
	probability_label.position = Vector3(0, 2.5, 0)
	add_child(probability_label)

func start_algorithm():
	if algorithm_running:
		return
	
	algorithm_running = true
	algorithm_step = 0
	iteration = 0
	min_cut_size = INF
	best_cut.clear()
	
	call_deferred("run_iterations")

func run_iterations():
	if not algorithm_running or iteration >= num_iterations:
		algorithm_running = false
		show_final_result()
		return
	
	iteration += 1
	update_iteration_display()
	
	# Reset for new iteration
	reset_for_iteration()
	
	# Run contraction algorithm
	call_deferred("contraction_algorithm")

func reset_for_iteration():
	# Reset contracted vertices
	for vertex in vertices:
		contracted_vertices[vertex] = [vertex]
	
	# Reset visual state
	for vertex in vertices:
		update_vertex_color(vertex, vertex_color)
	
	# Reset edges
	for edge in edges:
		update_edge_color(edge.from, edge.to, edge_color)
	
	current_cut.clear()
	algorithm_step = 0

func contraction_algorithm():
	if not algorithm_running:
		return
	
	# Continue until only 2 vertices remain
	var remaining_vertices = vertices.duplicate()
	
	while remaining_vertices.size() > 2:
		# Select random edge
		var available_edges = get_available_edges(remaining_vertices)
		if available_edges.is_empty():
			break
		
		var random_edge = available_edges[randi() % available_edges.size()]
		contract_edge(random_edge, remaining_vertices)
		
		algorithm_step += 1
		current_operation = "Contracting edge: " + random_edge.from + "-" + random_edge.to
		update_operation_display()
		
		if step_by_step:
			await get_tree().create_timer(animation_delay).timeout
	
	# Calculate cut size
	if remaining_vertices.size() == 2:
		var cut_size = calculate_cut_size(remaining_vertices)
		current_cut = get_cut_edges(remaining_vertices)
		
		update_cut_display(cut_size)
		
		# Update best cut if this is better
		if cut_size < min_cut_size:
			min_cut_size = cut_size
			best_cut = current_cut.duplicate(true)
			highlight_best_cut()
		
		update_probability_display()
	
	# Move to next iteration
	await get_tree().create_timer(animation_delay * 2).timeout
	call_deferred("run_iterations")

func get_available_edges(remaining_vertices: Array) -> Array:
	var available = []
	for edge in edges:
		var from_component = get_vertex_component(edge.from)
		var to_component = get_vertex_component(edge.to)
		if from_component != to_component and from_component in remaining_vertices and to_component in remaining_vertices:
			available.append(edge)
	return available

func get_vertex_component(vertex: String) -> String:
	for comp in contracted_vertices.keys():
		if vertex in contracted_vertices[comp]:
			return comp
	return vertex

func contract_edge(edge: Dictionary, remaining_vertices: Array):
	var from_comp = get_vertex_component(edge.from)
	var to_comp = get_vertex_component(edge.to)
	
	# Merge components
	contracted_vertices[from_comp].append_array(contracted_vertices[to_comp])
	contracted_vertices.erase(to_comp)
	remaining_vertices.erase(to_comp)
	
	# Update visual representation
	update_vertex_color(from_comp, contracted_color)
	highlight_contracted_edge(edge.from, edge.to)
	
	# Update vertex label to show contraction
	var from_node = vertex_nodes[from_comp]
	if from_node:
		var label = from_node.get_child(0)
		label.text = from_comp + "(" + str(contracted_vertices[from_comp].size()) + ")"

func calculate_cut_size(remaining_vertices: Array) -> int:
	var cut_size = 0
	for edge in original_edges:
		var from_comp = get_vertex_component(edge.from)
		var to_comp = get_vertex_component(edge.to)
		if from_comp != to_comp:
			cut_size += 1
	return cut_size

func get_cut_edges(remaining_vertices: Array) -> Array:
	var cut_edges = []
	for edge in original_edges:
		var from_comp = get_vertex_component(edge.from)
		var to_comp = get_vertex_component(edge.to)
		if from_comp != to_comp:
			cut_edges.append(edge)
	return cut_edges

func highlight_contracted_edge(from: String, to: String):
	var edge_key = from + "_" + to
	if not edge_lines.has(edge_key):
		edge_key = to + "_" + from
	
	if edge_lines.has(edge_key):
		var material := StandardMaterial3D.new()
		material.albedo_color = cut_edge_color
		material.emission = cut_edge_color * 0.5
		edge_lines[edge_key].material_override = material

func highlight_best_cut():
	# Reset all edges
	for edge in original_edges:
		update_edge_color(edge.from, edge.to, edge_color)
	
	# Highlight best cut edges
	for edge in best_cut:
		update_edge_color(edge.from, edge.to, best_cut_color)

func update_vertex_color(vertex: String, color: Color):
	if vertex_nodes.has(vertex):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission = color * 0.3
		vertex_nodes[vertex].material_override = material

func update_edge_color(from: String, to: String, color: Color):
	var edge_key = from + "_" + to
	if not edge_lines.has(edge_key):
		edge_key = to + "_" + from
	
	if edge_lines.has(edge_key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission = color * 0.2
		edge_lines[edge_key].material_override = material

func update_iteration_display():
	if iteration_label:
		iteration_label.text = "Iteration: " + str(iteration) + "/" + str(num_iterations)

func update_cut_display(cut_size: int):
	if cut_label:
		cut_label.text = "Current Cut Size: " + str(cut_size)

func update_probability_display():
	var n = vertices.size()
	var probability = 2.0 / (n * (n - 1)) * 100.0
	if probability_label:
		probability_label.text = "Success Probability: " + str(probability) + "%"

func update_operation_display():
	if info_label:
		info_label.text = current_operation

func show_final_result():
	update_operation_display()
	update_cut_display(min_cut_size)
	highlight_best_cut()
	
	# Show final message
	var final_message = "Algorithm completed! Minimum cut size: " + str(min_cut_size)
	update_operation_display()

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
	update_operation_display()

func reset_algorithm():
	algorithm_running = false
	algorithm_step = 0
	iteration = 0
	initialize_graph()
	create_visual_elements()
	update_operation_display()

func get_algorithm_info() -> Dictionary:
	return {
		"name": "Karger's Algorithm",
		"description": "Randomized algorithm for finding minimum cut",
		"time_complexity": "O(V²) per iteration",
		"space_complexity": "O(V + E)",
		"min_cut_size": min_cut_size,
		"current_iteration": iteration,
		"success_probability": 2.0 / (vertices.size() * (vertices.size() - 1))
	}
