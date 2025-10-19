class_name KosarajuAlgorithm
extends Node3D

# Kosaraju's Algorithm: Strongly Connected Components
# Visualizes the two-pass DFS approach to finding strongly connected components
# Explores the relationship between original graph and its transpose

@export_category("Kosaraju Configuration")
@export var graph_size: int = 10  # Number of vertices
@export var edge_density: float = 0.4  # Connection probability
@export var auto_start: bool = true
@export var step_by_step: bool = true
@export var animation_delay: float = 1.0

@export_category("Visualization")
@export var show_finish_times: bool = true
@export var show_transpose_graph: bool = true
@export var highlight_current_vertex: bool = true
@export var show_scc_colors: bool = true
@export var animate_dfs_traversal: bool = true
@export var show_stack_order: bool = true

@export_category("Interactive Mode")
@export var enable_graph_editing: bool = true
@export var allow_edge_editing: bool = true
@export var real_time_scc_update: bool = true
@export var show_algorithm_state: bool = true

# Colors for visualization
@export var vertex_color: Color = Color(0.4, 0.6, 0.9, 1.0)
@export var visited_color: Color = Color(0.9, 0.6, 0.2, 1.0)
@export var current_color: Color = Color(0.9, 0.9, 0.2, 1.0)
@export var scc_color_1: Color = Color(0.9, 0.2, 0.2, 1.0)
@export var scc_color_2: Color = Color(0.2, 0.9, 0.2, 1.0)
@export var scc_color_3: Color = Color(0.2, 0.2, 0.9, 1.0)
@export var scc_color_4: Color = Color(0.9, 0.2, 0.9, 1.0)
@export var scc_color_5: Color = Color(0.2, 0.9, 0.9, 1.0)
@export var edge_color: Color = Color(0.6, 0.6, 0.6, 0.8)
@export var transpose_edge_color: Color = Color(0.9, 0.5, 0.2, 0.8)
@export var finished_color: Color = Color(0.5, 0.5, 0.5, 1.0)

# Graph representation
var vertices: Array = []
var edges: Array = []
var adjacency_list: Dictionary = {}
var transpose_adjacency_list: Dictionary = {}

# Kosaraju's algorithm state
var visited: Dictionary = {}
var finish_times: Array = []
var scc_count: int = 0
var sccs: Array = []
var current_vertex: String = ""
var algorithm_running: bool = false
var algorithm_step: int = 0
var current_phase: String = "first_pass"  # first_pass, second_pass

# Visual elements
var vertex_nodes: Dictionary = {}
var edge_lines: Dictionary = {}
var transpose_edge_lines: Dictionary = {}
var scc_labels: Array = []
var info_label: Label3D
var phase_label: Label3D

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
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.0, 0.0), Vector3.UP)
	camera.current = true
	add_child(camera)

func initialize_graph():
	vertices.clear()
	edges.clear()
	adjacency_list.clear()
	transpose_adjacency_list.clear()
	visited.clear()
	finish_times.clear()
	scc_count = 0
	sccs.clear()
	algorithm_running = false
	algorithm_step = 0
	current_phase = "first_pass"
	
	# Generate random graph
	generate_random_graph()
	
	# Initialize algorithm state
	for vertex in vertices:
		visited[vertex] = false

func generate_random_graph():
	# Create vertices
	for i in range(graph_size):
		var vertex = "v" + str(i)
		vertices.append(vertex)
		adjacency_list[vertex] = []
		transpose_adjacency_list[vertex] = []
	
	# Create edges with probability edge_density
	for i in range(graph_size):
		for j in range(graph_size):
			if i != j and randf() < edge_density:
				var from_vertex = "v" + str(i)
				var to_vertex = "v" + str(j)
				edges.append({"from": from_vertex, "to": to_vertex})
				adjacency_list[from_vertex].append(to_vertex)
				transpose_adjacency_list[to_vertex].append(from_vertex)
	
	# Ensure graph is connected by adding some guaranteed edges
	if edges.size() < graph_size - 1:
		for i in range(graph_size - 1):
			var from_vertex = "v" + str(i)
			var to_vertex = "v" + str(i + 1)
			if not has_edge(from_vertex, to_vertex):
				edges.append({"from": from_vertex, "to": to_vertex})
				adjacency_list[from_vertex].append(to_vertex)
				transpose_adjacency_list[to_vertex].append(from_vertex)

func has_edge(from: String, to: String) -> bool:
	for edge in edges:
		if edge.from == from and edge.to == to:
			return true
	return false

func create_visual_elements():
	# Clear existing visuals
	for child in get_children():
		if child.name.begins_with("Vertex_") or child.name.begins_with("Edge_") or child.name.begins_with("SCC_"):
			child.queue_free()
	
	vertex_nodes.clear()
	edge_lines.clear()
	transpose_edge_lines.clear()
	scc_labels.clear()
	
	# Create vertex spheres
	var radius = 2.0
	var angle_step = 2.0 * PI / vertices.size()
	
	for i in range(vertices.size()):
		var vertex = vertices[i]
		var angle = i * angle_step
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		var y = sin(i * 0.5) * 0.5  # Add some height variation
		
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
	info_label = Label3D.new()
	info_label.text = "Kosaraju's Algorithm: Strongly Connected Components"
	info_label.font_size = 20
	info_label.position = Vector3(0, 4, 0)
	add_child(info_label)
	
	phase_label = Label3D.new()
	phase_label.text = "Phase 1: First DFS Pass"
	phase_label.font_size = 16
	phase_label.position = Vector3(0, 3.5, 0)
	add_child(phase_label)

func create_edge_visual(edge: Dictionary):
	if not vertex_nodes.has(edge.from) or not vertex_nodes.has(edge.to):
		return
	var from_pos = vertex_nodes[edge.from].position
	var to_pos = vertex_nodes[edge.to].position
	
	var line := MeshInstance3D.new()
	line.name = "Edge_" + edge.from + "_" + edge.to
	line.mesh = create_arrow_mesh(from_pos, to_pos)
	
	var material := StandardMaterial3D.new()
	material.albedo_color = edge_color
	material.emission = edge_color * 0.2
	line.material_override = material
	
	add_child(line)
	edge_lines[edge.from + "_" + edge.to] = line

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

func start_algorithm():
	if algorithm_running:
		return
	
	algorithm_running = true
	algorithm_step = 0
	sccs.clear()
	scc_count = 0
	current_phase = "first_pass"
	
	# Reset all vertices
	for vertex in vertices:
		visited[vertex] = false
		update_vertex_color(vertex, vertex_color)
	
	finish_times.clear()
	
	# Phase 1: First DFS pass to get finish times
	call_deferred("first_dfs_pass")

func first_dfs_pass():
	if not algorithm_running:
		return
	
	phase_label.text = "Phase 1: First DFS Pass (Getting finish times)"
	update_info_text("First DFS pass: Finding finish times for each vertex")
	
	# Perform DFS on original graph
	for vertex in vertices:
		if not visited[vertex]:
			call_deferred("dfs_first_pass", vertex)
	
	# After first pass, start second pass
	await get_tree().create_timer(animation_delay * 2).timeout
	call_deferred("second_dfs_pass")

func dfs_first_pass(vertex: String):
	if not algorithm_running or visited[vertex]:
		return
	
	current_vertex = vertex
	algorithm_step += 1
	
	visited[vertex] = true
	update_vertex_color(vertex, current_color)
	update_info_text("Processing vertex: " + vertex + " (First pass)")
	
	if step_by_step:
		await get_tree().create_timer(animation_delay).timeout
	
	# Process neighbors in original graph
	for neighbor in adjacency_list[vertex]:
		if not visited[neighbor]:
			update_edge_color(vertex, neighbor, Color.WHITE)
			await get_tree().create_timer(animation_delay * 0.5).timeout
			dfs_first_pass(neighbor)
	
	# Add to finish times (in reverse order)
	finish_times.push_front(vertex)
	update_vertex_color(vertex, finished_color)
	update_info_text("Finished vertex: " + vertex + " (Added to finish times)")

func second_dfs_pass():
	if not algorithm_running:
		return
	
	current_phase = "second_pass"
	phase_label.text = "Phase 2: Second DFS Pass (On transpose graph)"
	update_info_text("Second DFS pass: Processing transpose graph in reverse finish time order")
	
	# Reset visited for second pass
	for vertex in vertices:
		visited[vertex] = false
	
	# Show transpose edges
	show_transpose_edges()
	
	# Process vertices in reverse finish time order
	for vertex in finish_times:
		if not visited[vertex]:
			call_deferred("dfs_second_pass", vertex)
			scc_count += 1

func dfs_second_pass(vertex: String):
	if not algorithm_running or visited[vertex]:
		return
	
	current_vertex = vertex
	algorithm_step += 1
	
	visited[vertex] = true
	update_vertex_color(vertex, current_color)
	update_info_text("Processing vertex: " + vertex + " (Second pass - SCC " + str(scc_count) + ")")
	
	if step_by_step:
		await get_tree().create_timer(animation_delay).timeout
	
	# Process neighbors in transpose graph
	for neighbor in transpose_adjacency_list[vertex]:
		if not visited[neighbor]:
			update_transpose_edge_color(vertex, neighbor, Color.WHITE)
			await get_tree().create_timer(animation_delay * 0.5).timeout
			dfs_second_pass(neighbor)
	
	# Color the vertex with its SCC color
	var scc_color = get_scc_color(scc_count - 1)
	update_vertex_color(vertex, scc_color)
	
	# Add to current SCC (ensure capacity to avoid out-of-bounds)
	while sccs.size() <= scc_count - 1:
		sccs.append([])
	sccs[scc_count - 1].append(vertex)

func show_transpose_edges():
	# Create transpose edge visuals
	for edge in edges:
		var transpose_key = edge.to + "_" + edge.from
		if not transpose_edge_lines.has(transpose_key):
			if not vertex_nodes.has(edge.to) or not vertex_nodes.has(edge.from):
				continue
			var from_pos = vertex_nodes[edge.to].position
			var to_pos = vertex_nodes[edge.from].position
			
			var line := MeshInstance3D.new()
			line.name = "TransposeEdge_" + edge.to + "_" + edge.from
			line.mesh = create_arrow_mesh(from_pos, to_pos)
			
			var material := StandardMaterial3D.new()
			material.albedo_color = transpose_edge_color
			material.emission = transpose_edge_color * 0.2
			line.material_override = material
			
			add_child(line)
			transpose_edge_lines[transpose_key] = line

func get_scc_color(index: int) -> Color:
	var colors = [scc_color_1, scc_color_2, scc_color_3, scc_color_4, scc_color_5]
	return colors[index % colors.size()]

func update_vertex_color(vertex: String, color: Color):
	if vertex_nodes.has(vertex):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission = color * 0.3
		vertex_nodes[vertex].material_override = material

func update_edge_color(from: String, to: String, color: Color):
	var edge_key = from + "_" + to
	if edge_lines.has(edge_key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission = color * 0.2
		edge_lines[edge_key].material_override = material

func update_transpose_edge_color(from: String, to: String, color: Color):
	var edge_key = from + "_" + to
	if transpose_edge_lines.has(edge_key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission = color * 0.2
		transpose_edge_lines[edge_key].material_override = material

func update_info_text(text: String):
	if info_label:
		info_label.text = text

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
	update_info_text("Algorithm completed. Found " + str(scc_count) + " strongly connected components.")
	phase_label.text = "Algorithm Complete"

func reset_algorithm():
	algorithm_running = false
	algorithm_step = 0
	current_phase = "first_pass"
	initialize_graph()
	create_visual_elements()
	update_info_text("Kosaraju's Algorithm: Strongly Connected Components")
	phase_label.text = "Phase 1: First DFS Pass"

func get_algorithm_info() -> Dictionary:
	return {
		"name": "Kosaraju's Algorithm",
		"description": "Two-pass DFS algorithm for finding strongly connected components",
		"time_complexity": "O(V + E)",
		"space_complexity": "O(V)",
		"scc_count": scc_count,
		"current_step": algorithm_step,
		"current_phase": current_phase
	}
