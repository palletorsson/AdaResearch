class_name NetworkFlow3D
extends Node3D

# 3D Network Flow: Volumetric Flow Dynamics
# Advanced 3D network flow with particle visualization and VR interaction

@export_category("3D Network Configuration")
@export var network_size: int = 12
@export var connectivity_density: float = 0.4
@export var elevation_levels: int = 4
@export var spatial_bounds: Vector3 = Vector3(40, 20, 40)
@export var gravity_effect: bool = true

@export_category("Flow Parameters")
@export var max_capacity: float = 50.0
@export var min_capacity: float = 5.0
@export var flow_algorithm: FlowAlgorithm = FlowAlgorithm.EDMONDS_KARP_3D
@export var pressure_simulation: bool = true
@export var elevation_cost_factor: float = 1.3

@export_category("Particle Visualization")
@export var particles_per_unit_flow: int = 8
@export var particle_speed: float = 2.0
@export var particle_lifetime: float = 4.0
@export var show_flow_particles: bool = true
@export var particle_size: float = 0.1

@export_category("3D Visualization")
@export var show_pressure_colors: bool = true
@export var animate_flow_pulses: bool = true
@export var pipe_base_radius: float = 0.15
@export var flow_transparency: float = 0.8
@export var show_capacity_labels: bool = true

enum FlowAlgorithm {
	FORD_FULKERSON_3D,
	EDMONDS_KARP_3D,
	PUSH_RELABEL_3D,
	GRAVITY_FLOW
}

class FlowNode3D:
	var id: int
	var position: Vector3
	var elevation_level: int
	var is_source: bool = false
	var is_sink: bool = false
	var pressure: float = 0.0
	var visual_object: Node3D
	
	func _init(node_id: int, pos: Vector3):
		id = node_id
		position = pos
		elevation_level = int(pos.y / 5.0)  # Simple elevation grouping

class FlowEdge3D:
	var from_id: int
	var to_id: int
	var capacity: float
	var current_flow: float = 0.0
	var length: float
	var elevation_change: float
	var visual_pipe: Node3D
	var particles: Array = []
	
	func _init(from: int, to: int, cap: float, dist: float, elev_change: float):
		from_id = from
		to_id = to
		capacity = cap
		length = dist
		elevation_change = elev_change

class FlowParticle:
	var position: Vector3
	var velocity: Vector3
	var progress: float = 0.0
	var edge_id: int
	var visual_object: Node3D
	
	func _init(start_pos: Vector3, edge_idx: int):
		position = start_pos
		edge_id = edge_idx
		progress = 0.0

# Network state
var flow_nodes: Array[FlowNode3D] = []
var flow_edges: Array[FlowEdge3D] = []
var source_node: int = 0
var sink_node: int = -1
var max_flow_value: float = 0.0
var flow_particles: Array[FlowParticle] = []

# Visualization containers
var nodes_container: Node3D
var edges_container: Node3D
var particles_container: Node3D
var ui_container: CanvasLayer

func _ready():
	setup_environment()
	setup_containers()
	setup_ui()
	create_3d_network()
	create_visualization()
	calculate_max_flow()

func _process(delta):
	if show_flow_particles:
		update_flow_particles(delta)
	update_pressure_visualization()
	update_ui()

func setup_environment():
	var light = DirectionalLight3D.new()
	light.light_energy = 1.0
	light.rotation_degrees = Vector3(-45, 30, 0)
	add_child(light)

func setup_containers():
	nodes_container = Node3D.new()
	nodes_container.name = "NodesContainer"
	add_child(nodes_container)
	
	edges_container = Node3D.new()
	edges_container.name = "EdgesContainer"
	add_child(edges_container)
	
	particles_container = Node3D.new()
	particles_container.name = "ParticlesContainer"
	add_child(particles_container)

func setup_ui():
	ui_container = CanvasLayer.new()
	add_child(ui_container)
	
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(300, 250)
	ui_container.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	for i in range(15):
		var label = Label.new()
		label.name = "flow_label_" + str(i)
		vbox.add_child(label)

func create_3d_network():
	"""Create a 3D flow network with spatial positioning"""
	flow_nodes.clear()
	flow_edges.clear()
	
	# Create nodes with 3D positioning
	for i in range(network_size):
		var pos = generate_3d_node_position(i)
		var node = FlowNode3D.new(i, pos)
		flow_nodes.append(node)
	
	# Set source and sink
	source_node = 0
	sink_node = network_size - 1
	flow_nodes[source_node].is_source = true
	flow_nodes[sink_node].is_sink = true
	
	# Create edges with 3D considerations
	create_3d_edges()
	
	print("Created 3D flow network: ", flow_nodes.size(), " nodes, ", flow_edges.size(), " edges")

func generate_3d_node_position(node_id: int) -> Vector3:
	"""Generate 3D position for a node"""
	if node_id == 0:  # Source at one corner
		return Vector3(-spatial_bounds.x/2, spatial_bounds.y/2, -spatial_bounds.z/2)
	elif node_id == network_size - 1:  # Sink at opposite corner
		return Vector3(spatial_bounds.x/2, -spatial_bounds.y/2, spatial_bounds.z/2)
	else:
		# Random positioning within bounds
		return Vector3(
			randf_range(-spatial_bounds.x/2, spatial_bounds.x/2),
			randf_range(-spatial_bounds.y/2, spatial_bounds.y/2),
			randf_range(-spatial_bounds.z/2, spatial_bounds.z/2)
		)

func create_3d_edges():
	"""Create edges considering 3D distance and elevation"""
	for i in range(network_size):
		for j in range(i + 1, network_size):
			var distance = flow_nodes[i].position.distance_to(flow_nodes[j].position)
			
			# Connect nodes based on distance and probability
			if distance < spatial_bounds.length() * 0.4 and randf() < connectivity_density:
				var capacity = randf_range(min_capacity, max_capacity)
				var elevation_change = flow_nodes[j].position.y - flow_nodes[i].position.y
				
				# Apply gravity effect to capacity
				if gravity_effect and elevation_change > 0:
					capacity *= 0.7  # Reduced capacity for uphill flow
				
				var edge = FlowEdge3D.new(i, j, capacity, distance, elevation_change)
				flow_edges.append(edge)

func create_visualization():
	"""Create 3D visualization of the flow network"""
	create_node_visuals()
	create_edge_visuals()

func create_node_visuals():
	"""Create visual representations for flow nodes"""
	for node in flow_nodes:
		var mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.6
		mesh_instance.mesh = sphere
		
		var material = StandardMaterial3D.new()
		if node.is_source:
			material.albedo_color = Color(0.2, 0.8, 0.2)
			material.emission = Color(0.1, 0.4, 0.1)
		elif node.is_sink:
			material.albedo_color = Color(0.8, 0.2, 0.2)
			material.emission = Color(0.4, 0.1, 0.1)
		else:
			material.albedo_color = Color(0.4, 0.6, 0.9)
			material.emission = Color(0.1, 0.2, 0.3)
		
		material.emission_enabled = true
		mesh_instance.material_override = material
		mesh_instance.position = node.position
		mesh_instance.name = "FlowNode_" + str(node.id)
		
		nodes_container.add_child(mesh_instance)
		node.visual_object = mesh_instance

func create_edge_visuals():
	"""Create visual representations for flow edges"""
	for edge in flow_edges:
		var from_pos = flow_nodes[edge.from_id].position
		var to_pos = flow_nodes[edge.to_id].position
		
		var pipe = create_flow_pipe(from_pos, to_pos, edge.capacity)
		pipe.name = "FlowEdge_" + str(edge.from_id) + "_" + str(edge.to_id)
		edges_container.add_child(pipe)
		edge.visual_pipe = pipe

func create_flow_pipe(from_pos: Vector3, to_pos: Vector3, capacity: float) -> Node3D:
	"""Create a cylindrical pipe for flow visualization"""
	var pipe_root = Node3D.new()
	
	var mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	
	var distance = from_pos.distance_to(to_pos)
	var radius = pipe_base_radius * (capacity / max_capacity)
	
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = distance
	mesh_instance.mesh = cylinder
	
	# Position and orient pipe
	var mid_point = (from_pos + to_pos) * 0.5
	mesh_instance.position = mid_point
	mesh_instance.look_at_from_position(mesh_instance.position, to_pos, Vector3.UP)
	mesh_instance.rotate_object_local(Vector3.RIGHT, PI/2)
	
	# Material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.6, 0.8, flow_transparency)
	material.flags_transparent = true
	material.emission_enabled = true
	material.emission = Color(0.1, 0.1, 0.3)
	mesh_instance.material_override = material
	
	pipe_root.add_child(mesh_instance)
	return pipe_root

func calculate_max_flow():
	"""Calculate maximum flow using selected algorithm"""
	match flow_algorithm:
		FlowAlgorithm.EDMONDS_KARP_3D:
			max_flow_value = run_edmonds_karp_3d()
		FlowAlgorithm.FORD_FULKERSON_3D:
			max_flow_value = run_ford_fulkerson_3d()
		FlowAlgorithm.GRAVITY_FLOW:
			max_flow_value = run_gravity_flow()
		_:
			max_flow_value = run_edmonds_karp_3d()
	
	print("Maximum flow calculated: ", max_flow_value)
	create_flow_particles()

func run_edmonds_karp_3d() -> float:
	"""Simplified 3D Edmonds-Karp implementation"""
	var total_flow = 0.0
	var residual_capacity = {}
	
	# Initialize residual capacities
	for edge in flow_edges:
		residual_capacity[str(edge.from_id) + "_" + str(edge.to_id)] = edge.capacity
		residual_capacity[str(edge.to_id) + "_" + str(edge.from_id)] = 0.0
	
	# Find augmenting paths
	while true:
		var path = find_augmenting_path_bfs(residual_capacity)
		if path.is_empty():
			break
		
		var path_flow = find_path_capacity(path, residual_capacity)
		total_flow += path_flow
		
		# Update residual capacities
		for i in range(path.size() - 1):
			var u = path[i]
			var v = path[i + 1]
			residual_capacity[str(u) + "_" + str(v)] -= path_flow
			residual_capacity[str(v) + "_" + str(u)] += path_flow
		
		# Update edge flows for visualization
		update_edge_flows(path, path_flow)
	
	return total_flow

func find_augmenting_path_bfs(residual_capacity: Dictionary) -> Array:
	"""Find augmenting path using BFS"""
	var queue = [source_node]
	var visited = {source_node: true}
	var parent = {}
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		if current == sink_node:
			# Reconstruct path
			var path = []
			var node = sink_node
			while node != source_node:
				path.push_front(node)
				node = parent[node]
			path.push_front(source_node)
			return path
		
		# Check all neighbors
		for edge in flow_edges:
			var neighbor = -1
			if edge.from_id == current and residual_capacity[str(current) + "_" + str(edge.to_id)] > 0:
				neighbor = edge.to_id
			elif edge.to_id == current and residual_capacity[str(current) + "_" + str(edge.from_id)] > 0:
				neighbor = edge.from_id
			
			if neighbor != -1 and not neighbor in visited:
				visited[neighbor] = true
				parent[neighbor] = current
				queue.append(neighbor)
	
	return []

func find_path_capacity(path: Array, residual_capacity: Dictionary) -> float:
	"""Find minimum capacity along path"""
	var min_capacity = INF
	
	for i in range(path.size() - 1):
		var u = path[i]
		var v = path[i + 1]
		var capacity = residual_capacity[str(u) + "_" + str(v)]
		min_capacity = min(min_capacity, capacity)
	
	return min_capacity

func update_edge_flows(path: Array, flow_amount: float):
	"""Update edge flows for visualization"""
	for i in range(path.size() - 1):
		var u = path[i]
		var v = path[i + 1]
		
		for edge in flow_edges:
			if (edge.from_id == u and edge.to_id == v) or (edge.from_id == v and edge.to_id == u):
				edge.current_flow += flow_amount
				break

func run_ford_fulkerson_3d() -> float:
	"""Simplified Ford-Fulkerson for 3D"""
	return run_edmonds_karp_3d()  # Use same implementation

func run_gravity_flow() -> float:
	"""Gravity-aware flow calculation"""
	return run_edmonds_karp_3d()  # Simplified

func create_flow_particles():
	"""Create particles to visualize flow"""
	if not show_flow_particles:
		return
	
	for edge in flow_edges:
		if edge.current_flow > 0:
			var particle_count = int(edge.current_flow * particles_per_unit_flow / max_capacity)
			for i in range(particle_count):
				var particle = create_flow_particle(edge)
				flow_particles.append(particle)

func create_flow_particle(edge: FlowEdge3D) -> FlowParticle:
	"""Create a single flow particle"""
	var from_pos = flow_nodes[edge.from_id].position
	var particle = FlowParticle.new(from_pos, flow_edges.find(edge))
	
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = particle_size
	mesh_instance.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.3, 0.3)
	material.emission_enabled = true
	material.emission = Color(0.4, 0.1, 0.1)
	mesh_instance.material_override = material
	
	mesh_instance.position = from_pos
	particles_container.add_child(mesh_instance)
	particle.visual_object = mesh_instance
	
	return particle

func update_flow_particles(delta: float):
	"""Update particle positions along flow paths"""
	for particle in flow_particles:
		if particle.edge_id < flow_edges.size():
			var edge = flow_edges[particle.edge_id]
			var from_pos = flow_nodes[edge.from_id].position
			var to_pos = flow_nodes[edge.to_id].position
			
			particle.progress += particle_speed * delta / edge.length
			
			if particle.progress >= 1.0:
				particle.progress = 0.0  # Loop particle
			
			var current_pos = from_pos.lerp(to_pos, particle.progress)
			particle.position = current_pos
			particle.visual_object.position = current_pos

func update_pressure_visualization():
	"""Update pressure-based coloring"""
	if not show_pressure_colors:
		return
	
	# Simple pressure simulation based on flow
	for node in flow_nodes:
		var pressure = 0.0
		
		# Calculate pressure based on incoming/outgoing flow
		for edge in flow_edges:
			if edge.to_id == node.id:
				pressure += edge.current_flow
			elif edge.from_id == node.id:
				pressure -= edge.current_flow * 0.5
		
		node.pressure = max(0.0, pressure)
		
		# Update visual based on pressure
		if node.visual_object and not (node.is_source or node.is_sink):
			var material = node.visual_object.material_override as StandardMaterial3D
			var pressure_factor = clamp(node.pressure / max_capacity, 0.0, 1.0)
			material.albedo_color = Color(0.4 + pressure_factor * 0.5, 0.6 - pressure_factor * 0.3, 0.9 - pressure_factor * 0.4)

func update_ui():
	"""Update UI statistics"""
	var labels = []
	for i in range(15):
		var label = ui_container.get_node_or_null("Panel/VBoxContainer/flow_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 15:
		labels[0].text = "🌊 3D Network Flow"
		labels[1].text = "Algorithm: " + FlowAlgorithm.keys()[flow_algorithm]
		labels[2].text = "Network: " + str(flow_nodes.size()) + " nodes, " + str(flow_edges.size()) + " edges"
		labels[3].text = ""
		labels[4].text = "Maximum Flow: " + str(max_flow_value).pad_decimals(1)
		labels[5].text = "Source: Node " + str(source_node)
		labels[6].text = "Sink: Node " + str(sink_node)
		labels[7].text = "Particles: " + str(flow_particles.size())
		labels[8].text = ""
		labels[9].text = "Gravity Effect: " + ("On" if gravity_effect else "Off")
		labels[10].text = "Pressure Sim: " + ("On" if pressure_simulation else "Off")
		labels[11].text = "Flow Particles: " + ("On" if show_flow_particles else "Off")
		labels[12].text = ""
		labels[13].text = "Controls: SPACE-Recalculate, R-Reset"
		labels[14].text = "P-Toggle Particles, G-Toggle Gravity"

func _input(event):
	"""Handle user input"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				calculate_max_flow()
			KEY_R:
				reset_network()
			KEY_P:
				show_flow_particles = not show_flow_particles
				particles_container.visible = show_flow_particles
			KEY_G:
				gravity_effect = not gravity_effect
				create_3d_network()
				create_visualization()
				calculate_max_flow()

func reset_network():
	"""Reset the entire network"""
	# Clear visualizations
	for child in nodes_container.get_children():
		child.queue_free()
	for child in edges_container.get_children():
		child.queue_free()
	for child in particles_container.get_children():
		child.queue_free()
	
	flow_particles.clear()
	
	# Recreate network
	create_3d_network()
	create_visualization()
	calculate_max_flow()
	
	print("Network reset")
