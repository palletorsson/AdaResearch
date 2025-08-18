extends Node3D

var time = 0.0
var graph_nodes = []
var graph_edges = []
var distances = {}
var previous = {}
var visited = {}
var unvisited = []
var current_node = null
var start_node = null
var end_node = null
var path_found = false
var algorithm_step_timer = 0.0
var algorithm_step_interval = 0.5

class DijkstraNode:
	var id: String
	var position: Vector3
	var visual_object: CSGSphere3D
	var distance: float = INF
	var visited: bool = false
	
	func _init(node_id: String, pos: Vector3):
		id = node_id
		position = pos

class DijkstraEdge:
	var from_node: String
	var to_node: String
	var weight: float
	var visual_object: CSGCylinder3D
	
	func _init(from: String, to: String, w: float):
		from_node = from
		to_node = to
		weight = w

func _ready():
	create_sample_graph()
	setup_materials()
	initialize_dijkstra()

func create_sample_graph():
	var node_positions = [
		Vector3(-4, -2, 0), Vector3(-2, 0, 0), Vector3(0, -1, 0),
		Vector3(2, 1, 0), Vector3(4, 2, 0), Vector3(1, -2, 0),
		Vector3(-1, 2, 0), Vector3(3, -1, 0)
	]
	
	# Create nodes
	for i in range(node_positions.size()):
		var node = DijkstraNode.new("node_" + str(i), node_positions[i])
		
		var node_sphere = CSGSphere3D.new()
		node_sphere.radius = 0.2
		node_sphere.position = node.position
		get_or_create_container("GraphNodes").add_child(node_sphere)
		node.visual_object = node_sphere
		
		graph_nodes.append(node)
	
	# Create edges with random weights
	var connections = [
		[0, 1, 2.3], [0, 2, 1.8], [1, 2, 1.5], [1, 3, 2.1],
		[2, 3, 1.2], [2, 5, 2.7], [3, 4, 1.9], [3, 7, 2.4],
		[1, 6, 3.1], [6, 3, 1.7], [5, 7, 1.6], [7, 4, 1.4]
	]
	
	for conn in connections:
		var edge = DijkstraEdge.new("node_" + str(conn[0]), "node_" + str(conn[1]), conn[2])
		
		var from_pos = graph_nodes[conn[0]].position
		var to_pos = graph_nodes[conn[1]].position
		var distance = from_pos.distance_to(to_pos)
		
		var edge_cylinder = CSGCylinder3D.new()
		edge_cylinder.height = distance
		edge_cylinder.radius = 0.03
		#edge_cylinder.radius = 0.03
		
		edge_cylinder.position = (from_pos + to_pos) * 0.5
		
		var direction = (to_pos - from_pos).normalized()
		edge_cylinder.look_at(from_pos + direction, Vector3.UP)
		edge_cylinder.rotate_object_local(Vector3.RIGHT, PI/2)
		
		get_or_create_container("GraphEdges").add_child(edge_cylinder)
		edge.visual_object = edge_cylinder
		
		graph_edges.append(edge)

func get_or_create_container(container_name: String) -> Node3D:
	"""Get or create a container node"""
	var container = get_node_or_null(container_name)
	if not container:
		container = Node3D.new()
		container.name = container_name
		add_child(container)
	return container

func setup_materials():
	# Create and setup indicator materials
	setup_indicator_materials()

func setup_indicator_materials():
	# Distance indicator
	var distance_indicator = get_or_create_indicator("DistanceIndicator", 0.15, 1.0)
	var distance_material = StandardMaterial3D.new()
	distance_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	distance_material.emission_enabled = true
	distance_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	distance_material.emission_energy = 1.0
	distance_indicator.material_override = distance_material
	
	# Visited count indicator
	var visited_indicator = get_or_create_box_indicator("VisitedCount", Vector3(0.3, 1.0, 0.3))
	var visited_material = StandardMaterial3D.new()
	visited_material.albedo_color = Color(0.2, 0.8, 1.0, 1.0)
	visited_material.emission_enabled = true
	visited_material.emission = Color(0.05, 0.2, 0.3, 1.0)
	visited_material.emission_energy = 1.0
	visited_indicator.material_override = visited_material

func get_or_create_indicator(indicator_name: String, radius: float, height: float) -> CSGCylinder3D:
	"""Get or create an indicator CSGCylinder3D"""
	var indicator = get_node_or_null(indicator_name)
	if not indicator:
		indicator = CSGCylinder3D.new()
		indicator.name = indicator_name
		indicator.top_radius = radius
		indicator.bottom_radius = radius
		indicator.height = height
		indicator.position = Vector3(0, -3, 0)
		add_child(indicator)
	return indicator

func get_or_create_box_indicator(indicator_name: String, size: Vector3) -> CSGBox3D:
	"""Get or create an indicator CSGBox3D"""
	var indicator = get_node_or_null(indicator_name)
	if not indicator:
		indicator = CSGBox3D.new()
		indicator.name = indicator_name
		indicator.size = size
		indicator.position = Vector3(0, -3, 0)
		add_child(indicator)
	return indicator

func initialize_dijkstra():
	# Reset algorithm state
	distances.clear()
	previous.clear()
	visited.clear()
	unvisited.clear()
	
	start_node = "node_0"
	end_node = "node_4"
	current_node = start_node
	path_found = false
	
	# Initialize distances
	for node in graph_nodes:
		distances[node.id] = INF
		previous[node.id] = null
		visited[node.id] = false
		unvisited.append(node.id)
		node.distance = INF
		node.visited = false
	
	distances[start_node] = 0.0
	get_node_by_id(start_node).distance = 0.0
	
	update_node_visuals()

func _process(delta):
	time += delta
	algorithm_step_timer += delta
	
	if algorithm_step_timer >= algorithm_step_interval and not path_found:
		algorithm_step_timer = 0.0
		dijkstra_step()
	
	animate_dijkstra()
	animate_indicators()

func dijkstra_step():
	if unvisited.size() == 0:
		path_found = true
		return
	
	# Find unvisited node with minimum distance
	var min_distance = INF
	var min_node = null
	
	for node_id in unvisited:
		if distances.get(node_id, INF) < min_distance:
			min_distance = distances.get(node_id, INF)
			min_node = node_id
	
	if min_node == null or min_distance == INF:
		path_found = true
		return
	
	current_node = min_node
	visited[current_node] = true
	var current_node_obj = get_node_by_id(current_node)
	if current_node_obj:
		current_node_obj.visited = true
	unvisited.erase(current_node)
	
	# Update distances to neighbors
	for edge in graph_edges:
		var neighbor = null
		if edge.from_node == current_node:
			neighbor = edge.to_node
		elif edge.to_node == current_node:
			neighbor = edge.from_node
		else:
			continue
		
		if not visited.get(neighbor, false):
			var alt_distance = distances.get(current_node, INF) + edge.weight
			if alt_distance < distances.get(neighbor, INF):
				distances[neighbor] = alt_distance
				previous[neighbor] = current_node
				var neighbor_node = get_node_by_id(neighbor)
				if neighbor_node:
					neighbor_node.distance = alt_distance
	
	# Check if we reached the end
	if current_node == end_node:
		path_found = true
	
	update_node_visuals()

func get_node_by_id(id: String) -> DijkstraNode:
	for node in graph_nodes:
		if node.id == id:
			return node
	return null

func update_node_visuals():
	for node in graph_nodes:
		if not node.visual_object or not is_instance_valid(node.visual_object):
			continue
			
		var material = StandardMaterial3D.new()
		
		if node.id == start_node:
			material.albedo_color = Color(0.2, 1.0, 0.2, 1.0)
		elif node.id == end_node:
			material.albedo_color = Color(1.0, 0.2, 0.2, 1.0)
		elif node.id == current_node:
			material.albedo_color = Color(1.0, 1.0, 0.2, 1.0)
		elif node.visited:
			material.albedo_color = Color(0.8, 0.4, 0.8, 1.0)
		else:
			var distance_intensity = 1.0 - min(node.distance / 10.0, 1.0)
			material.albedo_color = Color(
				0.5 + distance_intensity * 0.5,
				0.5,
				0.5 + distance_intensity * 0.5,
				1.0
			)
		
		material.emission_enabled = true
		material.emission = material.albedo_color
		material.emission_energy = 0.5
		node.visual_object.material_override = material
	
	# Update edge colors based on path
	for edge in graph_edges:
		if not edge.visual_object or not is_instance_valid(edge.visual_object):
			continue
			
		var material = StandardMaterial3D.new()
		
		if is_edge_in_shortest_path(edge):
			material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
			material.emission_enabled = true
			material.emission = Color(0.5, 0.3, 0.1, 1.0)
			material.emission_energy = 1.0
		else:
			material.albedo_color = Color(0.6, 0.6, 0.6, 1.0)
		
		edge.visual_object.material_override = material

func is_edge_in_shortest_path(edge: DijkstraEdge) -> bool:
	if not path_found:
		return false
	
	# Reconstruct path and check if edge is part of it
	var path = reconstruct_path()
	for i in range(path.size() - 1):
		if (path[i] == edge.from_node and path[i + 1] == edge.to_node) or \
		   (path[i] == edge.to_node and path[i + 1] == edge.from_node):
			return true
	return false

func reconstruct_path() -> Array:
	var path = []
	var current = end_node
	
	while current != null:
		path.push_front(current)
		current = previous.get(current)
	
	return path

func animate_dijkstra():
	# Animate current node
	if current_node != null:
		var current_visual_node = get_node_by_id(current_node)
		if current_visual_node and current_visual_node.visual_object and is_instance_valid(current_visual_node.visual_object):
			var pulse = 1.0 + sin(time * 8.0) * 0.4
			current_visual_node.visual_object.scale = Vector3.ONE * pulse
	
	# Animate all nodes
	for i in range(graph_nodes.size()):
		var node = graph_nodes[i]
		if node.id != current_node and node.visual_object and is_instance_valid(node.visual_object):
			var wave = 1.0 + sin(time * 4.0 + i * 0.5) * 0.2
			node.visual_object.scale = Vector3.ONE * wave
	
	# Animate edges
	for i in range(graph_edges.size()):
		var edge = graph_edges[i]
		if edge.visual_object and is_instance_valid(edge.visual_object):
			var edge_pulse = 1.0 + sin(time * 6.0 + i * 0.3) * 0.1
			edge.visual_object.scale = Vector3.ONE * edge_pulse

func animate_indicators():
	# Distance indicator
	var current_distance = distances.get(current_node, 0.0)
	var distance_height = min(current_distance / 10.0, 1.0) * 2.0 + 0.5
	var distance_indicator = get_node_or_null("DistanceIndicator")
	if distance_indicator and distance_indicator is CSGCylinder3D:
		distance_indicator.height = distance_height
		distance_indicator.position.y = -3 + distance_height/2
	
	# Visited count indicator
	var visited_count = 0
	for node_id in visited.keys():
		if visited.get(node_id, false):
			visited_count += 1
	
	var visited_height = (float(visited_count) / graph_nodes.size()) * 2.0 + 0.5
	var visited_indicator = get_node_or_null("VisitedCount")
	if visited_indicator and visited_indicator is CSGBox3D:
		visited_indicator.size.y = visited_height
		visited_indicator.position.y = -3 + visited_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	if distance_indicator and is_instance_valid(distance_indicator):
		distance_indicator.scale.x = pulse
		distance_indicator.scale.z = pulse
	if visited_indicator and is_instance_valid(visited_indicator):
		visited_indicator.scale.x = pulse
		visited_indicator.scale.z = pulse
	
	# Reset if path found
	if path_found and time > 10.0:
		time = 0.0  # Reset time to prevent immediate restart
		initialize_dijkstra()

func get_algorithm_info() -> Dictionary:
	var visited_count = 0
	for v in visited.values():
		if v:
			visited_count += 1
	
	return {
		"current_node": current_node,
		"visited_nodes": visited_count,
		"shortest_distance": distances.get(end_node, INF),
		"path_found": path_found,
		"total_nodes": graph_nodes.size(),
		"path": reconstruct_path() if path_found else []
	}

# Additional utility functions
func reset_algorithm():
	"""Reset the algorithm to initial state"""
	initialize_dijkstra()

func set_start_node(node_id: String):
	"""Set a new start node"""
	if get_node_by_id(node_id):
		start_node = node_id
		initialize_dijkstra()

func set_end_node(node_id: String):
	"""Set a new end node"""
	if get_node_by_id(node_id):
		end_node = node_id
		initialize_dijkstra()

func get_shortest_distance() -> float:
	"""Get the shortest distance to the end node"""
	return distances.get(end_node, INF)

func is_algorithm_complete() -> bool:
	"""Check if the algorithm has completed"""
	return path_found or unvisited.size() == 0
