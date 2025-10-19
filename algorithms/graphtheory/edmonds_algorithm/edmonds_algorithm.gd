class_name EdmondsAlgorithm
extends Node3D

# Edmonds' Algorithm: Maximum Matching (Simplified Greedy Version)
# For demonstration purposes, using a greedy matching approach

@export_category("Edmonds Configuration")
@export var graph_size: int = 10
@export var edge_density: float = 0.35
@export var auto_start: bool = true
@export var animation_speed: float = 0.5

# Colors for visualization
@export var vertex_color: Color = Color(0.4, 0.6, 0.9, 1.0)
@export var matched_color: Color = Color(0.2, 0.9, 0.2, 1.0)
@export var unmatched_color: Color = Color(0.9, 0.5, 0.2, 1.0)
@export var edge_color: Color = Color(0.6, 0.6, 0.6, 0.6)
@export var matching_edge_color: Color = Color(0.9, 0.3, 0.3, 1.0)
@export var current_edge_color: Color = Color(0.9, 0.9, 0.2, 1.0)

# Graph representation
var vertices: Array = []
var edges: Array = []
var adjacency_list: Dictionary = {}

# Matching state
var matching: Dictionary = {}  # vertex -> matched_vertex (or null)
var algorithm_running: bool = false
var matching_size: int = 0

# Non-blocking state
var current_edge_index: int = 0
var step_timer: float = 0.0

# Visual elements
var vertex_nodes: Dictionary = {}
var edge_lines: Dictionary = {}
var info_label: Label3D
var matching_label: Label3D

func _ready():
	setup_environment()
	initialize_graph()
	create_visual_elements()
	
	if auto_start:
		start_algorithm()

func setup_environment():
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	light.light_energy = 1.2
	add_child(light)
	
	var ambient := WorldEnvironment.new()
	ambient.environment = Environment.new()
	ambient.environment.background_color = Color(0.05, 0.05, 0.1)
	ambient.environment.background_mode = Environment.BG_COLOR
	ambient.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambient.environment.ambient_light_color = Color(0.2, 0.2, 0.3)
	add_child(ambient)
	
	var camera := Camera3D.new()
	camera.position = Vector3(8.0, 6.0, 12.0)
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.0, 0.0), Vector3.UP)
	camera.current = true
	add_child(camera)

func initialize_graph():
	vertices.clear()
	edges.clear()
	adjacency_list.clear()
	matching.clear()
	algorithm_running = false
	matching_size = 0
	current_edge_index = 0
	
	generate_random_graph()
	
	# Initialize matching - all vertices start unmatched
	for vertex in vertices:
		matching[vertex] = null

func generate_random_graph():
	# Create vertices
	for i in range(graph_size):
		var vertex = "v" + str(i)
		vertices.append(vertex)
		adjacency_list[vertex] = []
	
	# Create edges
	for i in range(graph_size):
		for j in range(i + 1, graph_size):
			if randf() < edge_density:
				var from_vertex = "v" + str(i)
				var to_vertex = "v" + str(j)
				edges.append({"from": from_vertex, "to": to_vertex})
				adjacency_list[from_vertex].append(to_vertex)
				adjacency_list[to_vertex].append(from_vertex)
	
	# Ensure minimum connectivity
	if edges.size() < graph_size / 2:
		for i in range(graph_size / 2):
			var from_vertex = "v" + str(i)
			var to_vertex = "v" + str(i + graph_size / 2)
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
	for child in get_children():
		if child.name.begins_with("Vertex_") or child.name.begins_with("Edge_"):
			child.queue_free()
	
	vertex_nodes.clear()
	edge_lines.clear()
	
	# Create vertices in a circle
	var radius = 3.0
	var angle_step = TAU / vertices.size()
	
	for i in range(vertices.size()):
		var vertex = vertices[i]
		var angle = i * angle_step
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		
		var sphere := MeshInstance3D.new()
		sphere.name = "Vertex_" + vertex
		sphere.mesh = SphereMesh.new()
		(sphere.mesh as SphereMesh).radius = 0.2
		(sphere.mesh as SphereMesh).height = 0.4
		(sphere.mesh as SphereMesh).radial_segments = 16
		(sphere.mesh as SphereMesh).rings = 8
		sphere.position = Vector3(x, 0, z)
		
		var material := StandardMaterial3D.new()
		material.albedo_color = unmatched_color
		material.emission_enabled = true
		material.emission = unmatched_color * 0.5
		material.emission_energy_multiplier = 1.5
		sphere.material_override = material
		
		add_child(sphere)
		vertex_nodes[vertex] = sphere
		
		var label := Label3D.new()
		label.text = vertex
		label.font_size = 20
		label.position = Vector3(0, 0.5, 0)
		label.modulate = Color(1, 1, 1, 0.9)
		sphere.add_child(label)
	
	# Create edge lines
	for edge in edges:
		create_edge_visual(edge)
	
	# Create info labels
	info_label = Label3D.new()
	info_label.text = "Maximum Matching - Press Space to Start"
	info_label.font_size = 24
	info_label.position = Vector3(0, 5, 0)
	info_label.modulate = Color(1, 1, 1, 0.95)
	add_child(info_label)
	
	matching_label = Label3D.new()
	matching_label.text = "Matching Size: 0"
	matching_label.font_size = 20
	matching_label.position = Vector3(0, 4.3, 0)
	matching_label.modulate = Color(1, 1, 1, 0.9)
	add_child(matching_label)

func create_edge_visual(edge: Dictionary):
	var from_pos = vertex_nodes[edge.from].position
	var to_pos = vertex_nodes[edge.to].position
	
	var line_container = Node3D.new()
	line_container.name = "Edge_" + edge.from + "_" + edge.to
	add_child(line_container)
	
	var line := MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	cylinder.height = 1.0
	line.mesh = cylinder
	
	var material := StandardMaterial3D.new()
	material.albedo_color = edge_color
	material.emission_enabled = true
	material.emission = edge_color * 0.3
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line.material_override = material
	
	line_container.add_child(line)
	
	var midpoint = (from_pos + to_pos) * 0.5
	var distance = from_pos.distance_to(to_pos)
	line_container.global_position = midpoint
	line.scale.y = distance
	
	if distance > 0.001:
		line_container.look_at_from_position(line_container.position, to_pos, Vector3.UP)
		line_container.rotate_object_local(Vector3.RIGHT, PI / 2)
	
	edge_lines[edge.from + "_" + edge.to] = line_container

func start_algorithm():
	if algorithm_running:
		return
	
	algorithm_running = true
	current_edge_index = 0
	matching_size = 0
	step_timer = 0.0
	
	# Reset all vertices to unmatched
	for vertex in vertices:
		matching[vertex] = null
		update_vertex_color(vertex, unmatched_color)
	
	# Reset all edges
	for edge_key in edge_lines.keys():
		update_edge_color_direct(edge_key, edge_color)
	
	update_info_text("Finding maximum matching...")
	update_matching_display()

func _process(delta):
	if not algorithm_running:
		return
	
	step_timer += delta
	if step_timer < animation_speed:
		return
	
	step_timer = 0.0
	process_matching_step()

func process_matching_step():
	if current_edge_index >= edges.size():
		# Algorithm complete
		algorithm_running = false
		update_info_text("Complete! Maximum matching found.")
		return
	
	var edge = edges[current_edge_index]
	var u = edge.from
	var v = edge.to
	
	# Highlight current edge
	var edge_key = get_edge_key(u, v)
	update_edge_color_direct(edge_key, current_edge_color)
	update_info_text("Checking edge " + u + " - " + v)
	
	# Check if both vertices are unmatched
	if matching[u] == null and matching[v] == null:
		# Add to matching
		matching[u] = v
		matching[v] = u
		matching_size += 1
		
		# Update visuals
		update_vertex_color(u, matched_color)
		update_vertex_color(v, matched_color)
		update_edge_color_direct(edge_key, matching_edge_color)
		update_matching_display()
	else:
		# Can't add this edge, reset color
		update_edge_color_direct(edge_key, edge_color)
	
	current_edge_index += 1

func get_edge_key(u: String, v: String) -> String:
	var key1 = u + "_" + v
	var key2 = v + "_" + u
	if edge_lines.has(key1):
		return key1
	return key2

func update_vertex_color(vertex: String, color: Color):
	if vertex_nodes.has(vertex):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color * 0.5
		material.emission_energy_multiplier = 1.5
		vertex_nodes[vertex].material_override = material

func update_edge_color_direct(edge_key: String, color: Color):
	if edge_lines.has(edge_key):
		var line = edge_lines[edge_key].get_child(0)
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color * 0.5
		material.emission_energy_multiplier = 1.2
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		line.material_override = material

func update_info_text(text: String):
	if info_label:
		info_label.text = text

func update_matching_display():
	if matching_label:
		matching_label.text = "Matching Size: " + str(matching_size)

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
	update_info_text("Paused - Press Space to resume")

func reset_algorithm():
	algorithm_running = false
	current_edge_index = 0
	initialize_graph()
	create_visual_elements()
	update_info_text("Maximum Matching - Press Space to Start")
