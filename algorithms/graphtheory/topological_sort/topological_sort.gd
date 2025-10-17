class_name TopologicalSort
extends Node3D

# Topological Sort: Dependency Ordering in DAGs
# Visualizes the ordering of vertices in a directed acyclic graph
# Explores dependency resolution and task scheduling concepts

@export_category("Topological Sort Configuration")
@export var graph_size: int = 8  # Number of vertices
@export var edge_density: float = 0.3  # Connection probability
@export var auto_start: bool = true
@export var step_by_step: bool = true
@export var animation_delay: float = 1.0

@export_category("Visualization")
@export var show_in_degrees: bool = true
@export var show_queue_state: bool = true
@export var highlight_current_vertex: bool = true
@export var show_sorting_order: bool = true
@export var animate_dependency_resolution: bool = true
@export var show_levels: bool = true

@export_category("Interactive Mode")
@export var enable_graph_editing: bool = true
@export var allow_edge_editing: bool = true
@export var real_time_sort_update: bool = true
@export var show_algorithm_state: bool = true

# Colors for visualization
@export var vertex_color: Color = Color(0.4, 0.6, 0.9, 1.0)
@export var ready_color: Color = Color(0.2, 0.9, 0.2, 1.0)  # In-degree 0
@export var processing_color: Color = Color(0.9, 0.9, 0.2, 1.0)  # Currently processing
@export var processed_color: Color = Color(0.9, 0.2, 0.2, 1.0)  # Already processed
@export var level_1_color: Color = Color(0.9, 0.2, 0.2, 1.0)
@export var level_2_color: Color = Color(0.9, 0.5, 0.2, 1.0)
@export var level_3_color: Color = Color(0.9, 0.9, 0.2, 1.0)
@export var level_4_color: Color = Color(0.5, 0.9, 0.2, 1.0)
@export var level_5_color: Color = Color(0.2, 0.9, 0.2, 1.0)
@export var edge_color: Color = Color(0.6, 0.6, 0.6, 0.8)
@export var dependency_edge_color: Color = Color(0.9, 0.3, 0.3, 1.0)

# Graph representation
var vertices: Array = []
var edges: Array = []
var adjacency_list: Dictionary = {}
var in_degrees: Dictionary = {}

# Topological sort state
var sorted_order: Array = []
var queue: Array = []
var current_vertex: String = ""
var algorithm_running: bool = false
var algorithm_step: int = 0
var level: int = 0
var level_vertices: Dictionary = {}

# Visual elements
var vertex_nodes: Dictionary = {}
var edge_lines: Dictionary = {}
var level_indicators: Array = []
var info_label: Label3D
var queue_label: Label3D
var order_label: Label3D

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
	in_degrees.clear()
	sorted_order.clear()
	queue.clear()
	level = 0
	level_vertices.clear()
	algorithm_running = false
	algorithm_step = 0
	
	# Generate random DAG
	generate_random_dag()
	
	# Initialize in-degrees
	for vertex in vertices:
		in_degrees[vertex] = 0
	
	# Calculate in-degrees
	for edge in edges:
		in_degrees[edge.to] += 1

func generate_random_dag():
	# Create vertices
	for i in range(graph_size):
		var vertex = "v" + str(i)
		vertices.append(vertex)
		adjacency_list[vertex] = []
	
	# Create edges ensuring DAG property (no cycles)
	# Only allow edges from lower indices to higher indices
	for i in range(graph_size):
		for j in range(i + 1, graph_size):
			if randf() < edge_density:
				var from_vertex = "v" + str(i)
				var to_vertex = "v" + str(j)
				edges.append({"from": from_vertex, "to": to_vertex})
				adjacency_list[from_vertex].append(to_vertex)
	
	# Ensure some connectivity by adding a few more edges
	var additional_edges = 0
	while additional_edges < 2 and edges.size() < graph_size * (graph_size - 1) / 2:
		var i = randi() % (graph_size - 1)
		var j = randi() % (graph_size - i - 1) + i + 1
		var from_vertex = "v" + str(i)
		var to_vertex = "v" + str(j)
		
		if not has_edge(from_vertex, to_vertex):
			edges.append({"from": from_vertex, "to": to_vertex})
			adjacency_list[from_vertex].append(to_vertex)
			additional_edges += 1

func has_edge(from: String, to: String) -> bool:
	for edge in edges:
		if edge.from == from and edge.to == to:
			return true
	return false

func create_visual_elements():
	# Clear existing visuals
	for child in get_children():
		if child.name.begins_with("Vertex_") or child.name.begins_with("Edge_") or child.name.begins_with("Level_"):
			child.queue_free()
	
	vertex_nodes.clear()
	edge_lines.clear()
	level_indicators.clear()
	
	# Create vertex spheres arranged in levels
	create_hierarchical_layout()
	
	# Create edge lines
	for edge in edges:
		create_edge_visual(edge)
	
	# Create info labels
	create_info_labels()

func create_hierarchical_layout():
	var level_height = 1.5
	var level_width = 4.0
	
	# Group vertices by level based on in-degree
	var level_groups = {}
	for vertex in vertices:
		var vertex_level = in_degrees[vertex]
		if not level_groups.has(vertex_level):
			level_groups[vertex_level] = []
		level_groups[vertex_level].append(vertex)
	
	# Position vertices by level
	for level_key in level_groups.keys():
		var level_vertices_list = level_groups[level_key]
		var y_pos = level_key * level_height
		
		for i in range(level_vertices_list.size()):
			var vertex = level_vertices_list[i]
			var x_pos = (i - level_vertices_list.size() / 2.0) * 1.2
			var z_pos = 0.0
			
			var sphere := MeshInstance3D.new()
			sphere.name = "Vertex_" + vertex
			sphere.mesh = SphereMesh.new()
			sphere.mesh.radius = 0.15
			sphere.mesh.height = 0.3
			sphere.position = Vector3(x_pos, y_pos, z_pos)
			
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
			
			# Add in-degree label
			var in_degree_label := Label3D.new()
			in_degree_label.text = "in:" + str(in_degrees[vertex])
			in_degree_label.font_size = 12
			in_degree_label.position = Vector3(0, -0.4, 0)
			sphere.add_child(in_degree_label)
			
			# Store level information
			level_vertices[vertex] = level_key
		
		# Create level indicator
		create_level_indicator(level_key, level_vertices_list.size())

func create_level_indicator(level_num: int, vertex_count: int):
	var indicator := MeshInstance3D.new()
	indicator.name = "Level_" + str(level_num)
	indicator.mesh = create_level_plane(level_num, vertex_count)
	
	var material := StandardMaterial3D.new()
	material.albedo_color = get_level_color(level_num)
	material.emission = get_level_color(level_num) * 0.1
	material.flags_transparent = true
	material.flags_unshaded = true
	indicator.material_override = material
	
	add_child(indicator)
	level_indicators.append(indicator)

func create_level_plane(level_num: int, vertex_count: int) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices_array := PackedVector3Array()
	var indices := PackedInt32Array()
	
	var y_pos = level_num * 1.5
	var width = max(2.0, vertex_count * 1.2)
	
	# Create plane vertices
	vertices_array.append(Vector3(-width/2, y_pos - 0.1, -0.5))
	vertices_array.append(Vector3(width/2, y_pos - 0.1, -0.5))
	vertices_array.append(Vector3(width/2, y_pos - 0.1, 0.5))
	vertices_array.append(Vector3(-width/2, y_pos - 0.1, 0.5))
	
	# Create indices for two triangles
	indices.append(0)
	indices.append(1)
	indices.append(2)
	indices.append(0)
	indices.append(2)
	indices.append(3)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices_array
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func get_level_color(level_num: int) -> Color:
	var colors = [level_1_color, level_2_color, level_3_color, level_4_color, level_5_color]
	return colors[level_num % colors.size()]

func create_edge_visual(edge: Dictionary):
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

func create_info_labels():
	info_label = Label3D.new()
	info_label.text = "Topological Sort: Dependency Ordering"
	info_label.font_size = 20
	info_label.position = Vector3(0, 6, 0)
	add_child(info_label)
	
	queue_label = Label3D.new()
	queue_label.text = "Queue: []"
	queue_label.font_size = 16
	queue_label.position = Vector3(0, 5.5, 0)
	add_child(queue_label)
	
	order_label = Label3D.new()
	order_label.text = "Sorted Order: []"
	order_label.font_size = 16
	order_label.position = Vector3(0, 5, 0)
	add_child(order_label)

func start_algorithm():
	if algorithm_running:
		return
	
	algorithm_running = true
	algorithm_step = 0
	sorted_order.clear()
	queue.clear()
	
	# Reset all vertices
	for vertex in vertices:
		update_vertex_color(vertex, vertex_color)
	
	# Find vertices with in-degree 0
	for vertex in vertices:
		if in_degrees[vertex] == 0:
			queue.append(vertex)
			update_vertex_color(vertex, ready_color)
	
	update_queue_display()
	call_deferred("process_queue")

func process_queue():
	if not algorithm_running or queue.is_empty():
		algorithm_running = false
		update_info_text("Topological sort completed!")
		return
	
	current_vertex = queue.pop_front()
	algorithm_step += 1
	
	# Process current vertex
	update_vertex_color(current_vertex, processing_color)
	update_info_text("Processing vertex: " + current_vertex)
	
	if step_by_step:
		await get_tree().create_timer(animation_delay).timeout
	
	# Add to sorted order
	sorted_order.append(current_vertex)
	update_order_display()
	
	# Process neighbors
	for neighbor in adjacency_list[current_vertex]:
		in_degrees[neighbor] -= 1
		update_in_degree_display(neighbor)
		
		# Highlight dependency edge
		update_edge_color(current_vertex, neighbor, dependency_edge_color)
		await get_tree().create_timer(animation_delay * 0.5).timeout
		
		# If in-degree becomes 0, add to queue
		if in_degrees[neighbor] == 0:
			queue.append(neighbor)
			update_vertex_color(neighbor, ready_color)
	
	# Mark as processed
	update_vertex_color(current_vertex, processed_color)
	update_queue_display()
	
	# Continue processing
	await get_tree().create_timer(animation_delay * 0.5).timeout
	call_deferred("process_queue")

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

func update_in_degree_display(vertex: String):
	if vertex_nodes.has(vertex):
		var in_degree_label = vertex_nodes[vertex].get_child(1)  # Second child is in-degree label
		if in_degree_label and in_degree_label.text.begins_with("in:"):
			in_degree_label.text = "in:" + str(in_degrees[vertex])

func update_queue_display():
	if queue_label:
		queue_label.text = "Queue: " + str(queue)

func update_order_display():
	if order_label:
		order_label.text = "Sorted Order: " + str(sorted_order)

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
	update_info_text("Algorithm stopped. Sorted order: " + str(sorted_order))

func reset_algorithm():
	algorithm_running = false
	algorithm_step = 0
	initialize_graph()
	create_visual_elements()
	update_info_text("Topological Sort: Dependency Ordering")

func get_algorithm_info() -> Dictionary:
	return {
		"name": "Topological Sort",
		"description": "Orders vertices in a directed acyclic graph based on dependencies",
		"time_complexity": "O(V + E)",
		"space_complexity": "O(V)",
		"sorted_count": sorted_order.size(),
		"current_step": algorithm_step,
		"queue_size": queue.size()
	}
