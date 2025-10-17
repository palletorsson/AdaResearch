class_name TarjanAlgorithm
extends Node3D

# Tarjan's Algorithm: Strongly Connected Components (Non-blocking version)

@export_category("Tarjan Configuration")
@export var graph_size: int = 12
@export var edge_density: float = 0.3
@export var auto_start: bool = true
@export var animation_speed: float = 0.3  # Seconds between steps

@export_category("Visualization")
@export var show_discovery_time: bool = true
@export var show_low_link: bool = true
@export var highlight_current_vertex: bool = true

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
@export var back_edge_color: Color = Color(0.9, 0.3, 0.3, 1.0)
@export var cross_edge_color: Color = Color(0.3, 0.9, 0.3, 1.0)

# Graph representation
var vertices: Array = []
var edges: Array = []
var adjacency_list: Dictionary = {}

# Tarjan's algorithm state
var discovery_time: Dictionary = {}
var low_link: Dictionary = {}
var on_stack: Dictionary = {}
var stack: Array = []
var time_counter: int = 0
var scc_count: int = 0
var sccs: Array = []
var algorithm_running: bool = false

# Non-blocking DFS state
var dfs_stack: Array = []  # Stack of {vertex, state, neighbor_index}
var current_root_index: int = 0

# Visual elements
var vertex_nodes: Dictionary = {}
var edge_lines: Dictionary = {}
var info_label: Label3D
var step_timer: float = 0.0

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
	discovery_time.clear()
	low_link.clear()
	on_stack.clear()
	stack.clear()
	time_counter = 0
	scc_count = 0
	sccs.clear()
	algorithm_running = false
	dfs_stack.clear()
	current_root_index = 0
	
	generate_random_graph()
	
	for vertex in vertices:
		discovery_time[vertex] = -1
		low_link[vertex] = -1
		on_stack[vertex] = false

func generate_random_graph():
	# Create vertices
	for i in range(graph_size):
		var vertex = "v" + str(i)
		vertices.append(vertex)
		adjacency_list[vertex] = []
	
	# Create edges
	for i in range(graph_size):
		for j in range(graph_size):
			if i != j and randf() < edge_density:
				var from_vertex = "v" + str(i)
				var to_vertex = "v" + str(j)
				edges.append({"from": from_vertex, "to": to_vertex})
				adjacency_list[from_vertex].append(to_vertex)
	
	# Ensure connectivity
	for i in range(min(graph_size - 1, 3)):
		var from_vertex = "v" + str(i)
		var to_vertex = "v" + str(i + 1)
		if not has_edge(from_vertex, to_vertex):
			edges.append({"from": from_vertex, "to": to_vertex})
			adjacency_list[from_vertex].append(to_vertex)

func has_edge(from: String, to: String) -> bool:
	for edge in edges:
		if edge.from == from and edge.to == to:
			return true
	return false

func create_visual_elements():
	for child in get_children():
		if child.name.begins_with("Vertex_") or child.name.begins_with("Edge_"):
			child.queue_free()
	
	vertex_nodes.clear()
	edge_lines.clear()
	
	var radius = 3.0
	var angle_step = TAU / vertices.size()
	
	for i in range(vertices.size()):
		var vertex = vertices[i]
		var angle = i * angle_step
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		var y = sin(i * 0.5) * 0.5
		
		var sphere := MeshInstance3D.new()
		sphere.name = "Vertex_" + vertex
		sphere.mesh = SphereMesh.new()
		(sphere.mesh as SphereMesh).radius = 0.2
		(sphere.mesh as SphereMesh).height = 0.4
		(sphere.mesh as SphereMesh).radial_segments = 16
		(sphere.mesh as SphereMesh).rings = 8
		sphere.position = Vector3(x, y, z)
		
		var material := StandardMaterial3D.new()
		material.albedo_color = vertex_color
		material.emission_enabled = true
		material.emission = vertex_color * 0.5
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
	
	for edge in edges:
		create_edge_visual(edge)
	
	info_label = Label3D.new()
	info_label.text = "Tarjan's Algorithm - Press Space to Start"
	info_label.font_size = 24
	info_label.position = Vector3(0, 5, 0)
	info_label.modulate = Color(1, 1, 1, 0.95)
	add_child(info_label)

func create_edge_visual(edge: Dictionary):
	var from_pos = vertex_nodes[edge.from].position
	var to_pos = vertex_nodes[edge.to].position
	
	var direction = (to_pos - from_pos).normalized()
	var distance = from_pos.distance_to(to_pos)
	
	# Create line
	var line_container = Node3D.new()
	line_container.name = "Edge_" + edge.from + "_" + edge.to
	add_child(line_container)
	
	var line := MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	cylinder.height = distance * 0.85
	line.mesh = cylinder
	
	var material := StandardMaterial3D.new()
	material.albedo_color = edge_color
	material.emission_enabled = true
	material.emission = edge_color * 0.3
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line.material_override = material
	
	line_container.add_child(line)
	
	var midpoint = (from_pos + to_pos) * 0.5
	line_container.global_position = midpoint
	
	if distance > 0.001:
		line_container.look_at(to_pos, Vector3.UP)
		line_container.rotate_object_local(Vector3.RIGHT, PI / 2)
	
	# Arrow head
	var arrow = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.1
	cone.height = 0.2
	arrow.mesh = cone
	arrow.material_override = material.duplicate()
	arrow.position = Vector3(0, distance * 0.4, 0)
	line_container.add_child(arrow)
	
	edge_lines[edge.from + "_" + edge.to] = line_container

func start_algorithm():
	if algorithm_running:
		return
	
	algorithm_running = true
	sccs.clear()
	scc_count = 0
	dfs_stack.clear()
	current_root_index = 0
	step_timer = 0.0
	
	for vertex in vertices:
		discovery_time[vertex] = -1
		low_link[vertex] = -1
		on_stack[vertex] = false
		update_vertex_color(vertex, vertex_color)
	
	stack.clear()
	time_counter = 0
	
	update_info_text("Starting Tarjan's Algorithm...")

func _process(delta):
	if not algorithm_running:
		return
	
	step_timer += delta
	if step_timer < animation_speed:
		return
	
	step_timer = 0.0
	
	# Process one step of the algorithm
	process_tarjan_step()

func process_tarjan_step():
	# If DFS stack is empty, try to start from next unvisited root
	if dfs_stack.is_empty():
		while current_root_index < vertices.size():
			var vertex = vertices[current_root_index]
			current_root_index += 1
			
			if discovery_time[vertex] == -1:
				# Start new DFS from this vertex
				start_dfs(vertex)
				return
		
		# All vertices processed
		algorithm_running = false
		update_info_text("Complete! Found " + str(scc_count) + " SCCs")
		return
	
	# Process current DFS frame
	var frame = dfs_stack[-1]
	var vertex = frame["vertex"]
	var state = frame["state"]
	
	if state == "INIT":
		# Initialize vertex
		discovery_time[vertex] = time_counter
		low_link[vertex] = time_counter
		time_counter += 1
		stack.append(vertex)
		on_stack[vertex] = true
		
		update_vertex_color(vertex, current_color)
		update_info_text("Visiting: " + vertex + " (disc=" + str(discovery_time[vertex]) + ")")
		
		frame["state"] = "PROCESS_NEIGHBORS"
		frame["neighbor_index"] = 0
	
	elif state == "PROCESS_NEIGHBORS":
		var neighbors = adjacency_list[vertex]
		var neighbor_index = frame["neighbor_index"]
		
		if neighbor_index < neighbors.size():
			var neighbor = neighbors[neighbor_index]
			frame["neighbor_index"] += 1
			
			if discovery_time[neighbor] == -1:
				# Tree edge
				update_edge_color(vertex, neighbor, Color.WHITE)
				start_dfs(neighbor)
			elif on_stack[neighbor]:
				# Back edge
				update_edge_color(vertex, neighbor, back_edge_color)
				low_link[vertex] = min(low_link[vertex], discovery_time[neighbor])
			else:
				# Cross edge
				update_edge_color(vertex, neighbor, cross_edge_color)
		else:
			# All neighbors processed
			frame["state"] = "FINALIZE"
	
	elif state == "FINALIZE":
		# Check if this is an SCC root
		if low_link[vertex] == discovery_time[vertex]:
			var scc = []
			while true:
				var w = stack.pop_back()
				on_stack[w] = false
				scc.append(w)
				if w == vertex:
					break
			
			sccs.append(scc)
			var scc_color = get_scc_color(scc_count)
			scc_count += 1
			
			for v in scc:
				update_vertex_color(v, scc_color)
			
			update_info_text("Found SCC #" + str(scc_count) + ": " + str(scc))
		else:
			update_vertex_color(vertex, visited_color)
		
		# Pop this frame
		dfs_stack.pop_back()
		
		# Update parent's low link
		if not dfs_stack.is_empty():
			var parent_frame = dfs_stack[-1]
			var parent = parent_frame["vertex"]
			low_link[parent] = min(low_link[parent], low_link[vertex])

func start_dfs(vertex: String):
	dfs_stack.append({
		"vertex": vertex,
		"state": "INIT",
		"neighbor_index": 0
	})

func get_scc_color(index: int) -> Color:
	var colors = [scc_color_1, scc_color_2, scc_color_3, scc_color_4, scc_color_5]
	return colors[index % colors.size()]

func update_vertex_color(vertex: String, color: Color):
	if vertex_nodes.has(vertex):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color * 0.5
		material.emission_energy_multiplier = 1.5
		vertex_nodes[vertex].material_override = material

func update_edge_color(from: String, to: String, color: Color):
	var edge_key = from + "_" + to
	if edge_lines.has(edge_key):
		var line = edge_lines[edge_key].get_child(0)
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color * 0.4
		material.emission_energy_multiplier = 1.2
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		line.material_override = material

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
	update_info_text("Paused - Press Space to resume")

func reset_algorithm():
	algorithm_running = false
	dfs_stack.clear()
	current_root_index = 0
	initialize_graph()
	create_visual_elements()
	update_info_text("Tarjan's Algorithm - Press Space to Start")
