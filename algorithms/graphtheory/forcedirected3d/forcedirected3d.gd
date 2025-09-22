class_name ForceDirected3D
extends Node3D

# 3D Force-Directed Layout: Volumetric Graph Physics
# Advanced 3D implementation with realistic physics simulation
# Supports VR interaction and real-time manipulation

@export_category("Graph Configuration")
@export var node_count: int = 20
@export var edge_probability: float = 0.15  # Probability of connection between nodes
@export var layout_bounds: Vector3 = Vector3(50, 30, 50)
@export var initial_distribution: String = "random"  # random, sphere, cube, grid

@export_category("3D Physics")
@export var repulsion_strength: float = 200.0
@export var spring_constant: float = 0.08
@export var rest_length: float = 8.0
@export var damping_factor: float = 0.92
@export var gravity_strength: float = 0.01
@export var min_distance: float = 0.5
@export var max_force: float = 50.0  # Force clamping for stability

@export_category("Simulation Control")
@export var max_iterations: int = 2000
@export var convergence_threshold: float = 0.05
@export var auto_run: bool = true
@export var time_step: float = 0.016
@export var adaptive_timestep: bool = true
@export var temperature_cooling: float = 0.995
@export var pause_on_convergence: bool = true

@export_category("Visualization")
@export var show_forces: bool = true
@export var show_edges: bool = true
@export var show_energy_indicators: bool = true
@export var show_node_trails: bool = false
@export var node_trail_length: int = 30
@export var force_visualization_scale: float = 0.1
@export var stress_color_mapping: bool = true

@export_category("VR Interaction")
@export var enable_vr_manipulation: bool = true
@export var manipulation_sphere_radius: float = 1.0
@export var grabbed_node_mass_multiplier: float = 10.0
@export var comfort_movement_speed: float = 0.5

# Node representation
class GraphNode3D:
	var id: int
	var position: Vector3
	var velocity: Vector3
	var force: Vector3
	var mass: float = 1.0
	var is_fixed: bool = false
	var is_grabbed: bool = false
	var visual_object: Node3D
	var trail_points: PackedVector3Array = PackedVector3Array()
	var stress_level: float = 0.0
	var degree: int = 0
	
	func _init(node_id: int, pos: Vector3):
		id = node_id
		position = pos
		velocity = Vector3.ZERO
		force = Vector3.ZERO

# Edge representation
class GraphEdge3D:
	var from_id: int
	var to_id: int
	var rest_length: float
	var spring_constant: float
	var visual_object: Node3D
	var force_line: Node3D
	
	func _init(from: int, to: int, length: float = 8.0, k: float = 0.1):
		from_id = from
		to_id = to
		rest_length = length
		spring_constant = k

# Graph state
var nodes: Array[GraphNode3D] = []
var edges: Array[GraphEdge3D] = []
var adjacency_list: Dictionary = {}

# Simulation state
var current_iteration: int = 0
var is_running: bool = false
var total_energy: float = 0.0
var kinetic_energy: float = 0.0
var potential_energy: float = 0.0
var convergence_factor: float = 1.0
var temperature: float = 1.0

# Visualization containers
var nodes_container: Node3D
var edges_container: Node3D
var forces_container: Node3D
var ui_container: CanvasLayer

# VR interaction
var grabbed_nodes: Dictionary = {}  # controller_id -> node_id
var controller_positions: Dictionary = {}

# Performance optimization
var spatial_hash: Dictionary = {}
var hash_cell_size: float = 10.0

func _ready():
	setup_environment()
	setup_containers()
	setup_ui()
	initialize_graph()
	create_visualization()
	
	if auto_run:
		start_simulation()

func _process(delta):
	if is_running:
		simulation_step(delta)
		update_visualization()
		update_ui_stats()
		check_convergence()

func setup_environment():
	"""Setup lighting and environment for 3D visualization"""
	# Main directional light
	var main_light = DirectionalLight3D.new()
	main_light.name = "MainLight"
	main_light.light_energy = 1.2
	main_light.rotation_degrees = Vector3(-45, 45, 0)
	main_light.shadow_enabled = true
	add_child(main_light)
	
	# Ambient lighting
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.05, 0.1)
	environment.ambient_light_color = Color(0.3, 0.3, 0.4)
	environment.ambient_light_energy = 0.6
	env.environment = environment
	add_child(env)
	
	# Add some accent lighting
	var accent_light = OmniLight3D.new()
	accent_light.name = "AccentLight"
	accent_light.position = Vector3(20, 15, 20)
	accent_light.light_energy = 0.8
	accent_light.light_color = Color(0.8, 0.9, 1.0)
	accent_light.omni_range = 40.0
	add_child(accent_light)

func setup_containers():
	"""Create containers for different visual elements"""
	nodes_container = Node3D.new()
	nodes_container.name = "NodesContainer"
	add_child(nodes_container)
	
	edges_container = Node3D.new()
	edges_container.name = "EdgesContainer"
	add_child(edges_container)
	
	forces_container = Node3D.new()
	forces_container.name = "ForcesContainer"
	add_child(forces_container)

func setup_ui():
	"""Create UI overlay for statistics and controls"""
	ui_container = CanvasLayer.new()
	ui_container.name = "UIContainer"
	add_child(ui_container)
	
	# Create stats panel
	var stats_panel = Panel.new()
	stats_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	stats_panel.size = Vector2(300, 200)
	stats_panel.position = Vector2(10, 10)
	ui_container.add_child(stats_panel)
	
	var stats_vbox = VBoxContainer.new()
	stats_panel.add_child(stats_vbox)
	
	# Create stat labels
	for i in range(12):
		var label = Label.new()
		label.name = "stat_label_" + str(i)
		label.text = ""
		stats_vbox.add_child(label)

func initialize_graph():
	"""Initialize the 3D graph structure"""
	nodes.clear()
	edges.clear()
	adjacency_list.clear()
	
	# Create nodes with initial 3D positions
	for i in range(node_count):
		var initial_pos = get_initial_position(i)
		var node = GraphNode3D.new(i, initial_pos)
		nodes.append(node)
		adjacency_list[i] = []
	
	# Create edges based on probability
	for i in range(node_count):
		for j in range(i + 1, node_count):
			if randf() < edge_probability:
				create_edge(i, j)
	
	# Ensure graph connectivity
	ensure_connectivity()
	
	# Calculate node degrees
	calculate_node_degrees()
	
	print("Created 3D graph with ", nodes.size(), " nodes and ", edges.size(), " edges")

func get_initial_position(node_id: int) -> Vector3:
	"""Get initial position based on distribution type"""
	match initial_distribution:
		"random":
			return Vector3(
				randf_range(-layout_bounds.x/2, layout_bounds.x/2),
				randf_range(-layout_bounds.y/2, layout_bounds.y/2),
				randf_range(-layout_bounds.z/2, layout_bounds.z/2)
			)
		"sphere":
			var radius = min(layout_bounds.x, layout_bounds.y, layout_bounds.z) * 0.4
			var phi = randf() * 2.0 * PI
			var theta = acos(1 - 2 * randf())
			return Vector3(
				radius * sin(theta) * cos(phi),
				radius * sin(theta) * sin(phi),
				radius * cos(theta)
			)
		"cube":
			var edge_length = min(layout_bounds.x, layout_bounds.y, layout_bounds.z) * 0.8
			return Vector3(
				randf_range(-edge_length/2, edge_length/2),
				randf_range(-edge_length/2, edge_length/2),
				randf_range(-edge_length/2, edge_length/2)
			)
		"grid":
			var grid_size = int(ceil(pow(node_count, 1.0/3.0)))
			var spacing = layout_bounds / grid_size
			var x = node_id % grid_size
			var y = (node_id / grid_size) % grid_size
			var z = node_id / (grid_size * grid_size)
			return Vector3(
				(x - grid_size/2.0) * spacing.x,
				(y - grid_size/2.0) * spacing.y,
				(z - grid_size/2.0) * spacing.z
			)
		_:
			return Vector3.ZERO

func create_edge(from_id: int, to_id: int):
	"""Create an edge between two nodes"""
	var distance = nodes[from_id].position.distance_to(nodes[to_id].position)
	var edge = GraphEdge3D.new(from_id, to_id, distance, spring_constant)
	edges.append(edge)
	
	# Update adjacency list
	adjacency_list[from_id].append(to_id)
	adjacency_list[to_id].append(from_id)

func ensure_connectivity():
	"""Ensure the graph is connected using minimum spanning tree approach"""
	var connected = [0]  # Start with node 0
	var unconnected = []
	
	for i in range(1, node_count):
		unconnected.append(i)
	
	# Connect all nodes with minimum spanning tree
	while unconnected.size() > 0:
		var min_distance = INF
		var best_connected = -1
		var best_unconnected = -1
		
		for connected_id in connected:
			for unconnected_id in unconnected:
				var distance = nodes[connected_id].position.distance_to(nodes[unconnected_id].position)
				if distance < min_distance:
					min_distance = distance
					best_connected = connected_id
					best_unconnected = unconnected_id
		
		if best_unconnected != -1:
			create_edge(best_connected, best_unconnected)
			connected.append(best_unconnected)
			unconnected.erase(best_unconnected)

func calculate_node_degrees():
	"""Calculate degree for each node"""
	for node in nodes:
		node.degree = adjacency_list[node.id].size()

func create_visualization():
	"""Create 3D visual representations"""
	create_node_visuals()
	create_edge_visuals()
	if show_forces:
		create_force_visuals()

func create_node_visuals():
	"""Create visual representations for nodes"""
	for node in nodes:
		var mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		mesh_instance.mesh = sphere
		
		# Create material based on degree
		var material = StandardMaterial3D.new()
		var degree_factor = float(node.degree) / float(edges.size() * 2 / node_count)  # Normalized degree
		material.albedo_color = Color(0.3 + degree_factor * 0.5, 0.6, 0.9 - degree_factor * 0.3)
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.3
		material.metallic = 0.2
		material.roughness = 0.3
		mesh_instance.material_override = material
		
		mesh_instance.position = node.position
		mesh_instance.name = "Node_" + str(node.id)
		
		# Add label
		var label = Label3D.new()
		label.text = str(node.id)
		label.position = Vector3(0, 1.2, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 24
		mesh_instance.add_child(label)
		
		nodes_container.add_child(mesh_instance)
		node.visual_object = mesh_instance

func create_edge_visuals():
	"""Create visual representations for edges"""
	if not show_edges:
		return
	
	for edge in edges:
		var from_pos = nodes[edge.from_id].position
		var to_pos = nodes[edge.to_id].position
		
		var edge_mesh = create_edge_cylinder(from_pos, to_pos)
		edge_mesh.name = "Edge_" + str(edge.from_id) + "_" + str(edge.to_id)
		edges_container.add_child(edge_mesh)
		edge.visual_object = edge_mesh

func create_edge_cylinder(from_pos: Vector3, to_pos: Vector3) -> MeshInstance3D:
	"""Create a cylinder mesh for an edge"""
	var mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	
	var distance = from_pos.distance_to(to_pos)
	cylinder.top_radius = 0.05
	cylinder.bottom_radius = 0.05
	cylinder.height = distance
	
	mesh_instance.mesh = cylinder
	
	# Position and orient the cylinder
	var mid_point = (from_pos + to_pos) * 0.5
	mesh_instance.position = mid_point
	mesh_instance.look_at(to_pos, Vector3.UP)
	mesh_instance.rotate_object_local(Vector3.RIGHT, PI/2)
	
	# Material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.7, 0.7, 0.8)
	material.emission_enabled = true
	material.emission = Color(0.2, 0.2, 0.2)
	material.flags_transparent = true
	mesh_instance.material_override = material
	
	return mesh_instance

func create_force_visuals():
	"""Create visual representations for forces"""
	for node in nodes:
		var arrow = create_force_arrow()
		arrow.name = "Force_" + str(node.id)
		forces_container.add_child(arrow)

func create_force_arrow() -> Node3D:
	"""Create an arrow to visualize force vectors"""
	var arrow_root = Node3D.new()
	
	# Arrow shaft
	var shaft = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	cylinder.height = 1.0
	shaft.mesh = cylinder
	
	# Arrow head
	var head = MeshInstance3D.new()
	var cone = SphereMesh.new()  # Using sphere for simplicity
	cone.radius = 0.08
	cone.height = 0.16
	head.mesh = cone
	head.position = Vector3(0, 0.6, 0)
	
	# Material for forces
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.2, 0.2)
	material.emission_enabled = true
	material.emission = Color(0.5, 0.1, 0.1)
	shaft.material_override = material
	head.material_override = material
	
	arrow_root.add_child(shaft)
	arrow_root.add_child(head)
	arrow_root.visible = false  # Initially hidden
	
	return arrow_root

func start_simulation():
	"""Start the force-directed layout simulation"""
	is_running = true
	current_iteration = 0
	temperature = 1.0
	print("Starting 3D force-directed layout simulation")

func stop_simulation():
	"""Stop the simulation"""
	is_running = false
	print("Simulation stopped at iteration ", current_iteration)

func simulation_step(delta: float):
	"""Perform one step of the physics simulation"""
	if current_iteration >= max_iterations:
		stop_simulation()
		return
	
	# Clear forces
	for node in nodes:
		node.force = Vector3.ZERO
	
	# Calculate repulsion forces
	calculate_repulsion_forces()
	
	# Calculate spring forces
	calculate_spring_forces()
	
	# Apply gravity
	if gravity_strength > 0:
		apply_gravity()
	
	# Update positions and velocities
	integrate_motion(delta)
	
	# Update spatial hash for optimization
	update_spatial_hash()
	
	# Cool down temperature
	temperature *= temperature_cooling
	
	current_iteration += 1

func calculate_repulsion_forces():
	"""Calculate repulsion forces between all node pairs"""
	for i in range(nodes.size()):
		for j in range(i + 1, nodes.size()):
			var node1 = nodes[i]
			var node2 = nodes[j]
			
			if node1.is_fixed and node2.is_fixed:
				continue
			
			var distance_vector = node1.position - node2.position
			var distance = distance_vector.length()
			
			if distance < min_distance:
				distance = min_distance
			
			var force_magnitude = repulsion_strength / (distance * distance)
			var force_direction = distance_vector.normalized()
			var force = force_direction * force_magnitude
			
			# Apply force with mass consideration
			if not node1.is_fixed:
				node1.force += force / node1.mass
			if not node2.is_fixed:
				node2.force -= force / node2.mass

func calculate_spring_forces():
	"""Calculate spring forces along edges"""
	for edge in edges:
		var node1 = nodes[edge.from_id]
		var node2 = nodes[edge.to_id]
		
		if node1.is_fixed and node2.is_fixed:
			continue
		
		var distance_vector = node2.position - node1.position
		var current_length = distance_vector.length()
		var displacement = current_length - edge.rest_length
		
		var force_magnitude = edge.spring_constant * displacement
		var force_direction = distance_vector.normalized()
		var force = force_direction * force_magnitude
		
		# Apply Hooke's law
		if not node1.is_fixed:
			node1.force += force / node1.mass
		if not node2.is_fixed:
			node2.force -= force / node2.mass

func apply_gravity():
	"""Apply gravitational force"""
	for node in nodes:
		if not node.is_fixed:
			node.force.y -= gravity_strength

func integrate_motion(delta: float):
	"""Integrate forces to update positions and velocities"""
	total_energy = 0.0
	kinetic_energy = 0.0
	potential_energy = 0.0
	
	for node in nodes:
		if node.is_fixed or node.is_grabbed:
			continue
		
		# Clamp force to prevent instability
		if node.force.length() > max_force:
			node.force = node.force.normalized() * max_force
		
		# Update velocity with force and damping
		node.velocity += node.force * delta
		node.velocity *= damping_factor
		
		# Apply temperature scaling for simulated annealing
		node.velocity *= temperature
		
		# Update position
		node.position += node.velocity * delta
		
		# Apply bounds constraints
		apply_bounds_constraints(node)
		
		# Calculate energies
		kinetic_energy += 0.5 * node.mass * node.velocity.length_squared()
		node.stress_level = node.force.length()
	
	total_energy = kinetic_energy + potential_energy

func apply_bounds_constraints(node: GraphNode3D):
	"""Keep nodes within the layout bounds"""
	# Soft bounds with spring-like force
	var bounds_force = Vector3.ZERO
	
	if abs(node.position.x) > layout_bounds.x / 2:
		bounds_force.x = -sign(node.position.x) * (abs(node.position.x) - layout_bounds.x / 2) * 0.1
	if abs(node.position.y) > layout_bounds.y / 2:
		bounds_force.y = -sign(node.position.y) * (abs(node.position.y) - layout_bounds.y / 2) * 0.1
	if abs(node.position.z) > layout_bounds.z / 2:
		bounds_force.z = -sign(node.position.z) * (abs(node.position.z) - layout_bounds.z / 2) * 0.1
	
	node.force += bounds_force

func update_spatial_hash():
	"""Update spatial hash for performance optimization"""
	spatial_hash.clear()
	
	for node in nodes:
		var hash_key = get_spatial_hash_key(node.position)
		if not spatial_hash.has(hash_key):
			spatial_hash[hash_key] = []
		spatial_hash[hash_key].append(node.id)

func get_spatial_hash_key(position: Vector3) -> Vector3i:
	"""Get spatial hash key for a position"""
	return Vector3i(
		int(position.x / hash_cell_size),
		int(position.y / hash_cell_size),
		int(position.z / hash_cell_size)
	)

func update_visualization():
	"""Update visual elements based on current positions"""
	update_node_visuals()
	update_edge_visuals()
	if show_forces:
		update_force_visuals()

func update_node_visuals():
	"""Update node visual positions and properties"""
	for node in nodes:
		if node.visual_object:
			node.visual_object.position = node.position
			
			# Update color based on stress if enabled
			if stress_color_mapping:
				var material = node.visual_object.material_override as StandardMaterial3D
				var stress_factor = clamp(node.stress_level / max_force, 0.0, 1.0)
				material.albedo_color = Color(0.3 + stress_factor * 0.7, 0.6 - stress_factor * 0.3, 0.9 - stress_factor * 0.6)
				material.emission = material.albedo_color * 0.3
			
			# Update trails
			if show_node_trails:
				update_node_trail(node)

func update_node_trail(node: GraphNode3D):
	"""Update particle trail for a node"""
	node.trail_points.append(node.position)
	if node.trail_points.size() > node_trail_length:
		node.trail_points = node.trail_points.slice(1)

func update_edge_visuals():
	"""Update edge visual positions and orientations"""
	if not show_edges:
		return
	
	for i in range(edges.size()):
		var edge = edges[i]
		if edge.visual_object:
			var from_pos = nodes[edge.from_id].position
			var to_pos = nodes[edge.to_id].position
			
			# Update position and orientation
			var mid_point = (from_pos + to_pos) * 0.5
			edge.visual_object.position = mid_point
			edge.visual_object.look_at(to_pos, Vector3.UP)
			edge.visual_object.rotate_object_local(Vector3.RIGHT, PI/2)
			
			# Update length
			var distance = from_pos.distance_to(to_pos)
			var cylinder_mesh = edge.visual_object.mesh as CylinderMesh
			cylinder_mesh.height = distance

func update_force_visuals():
	"""Update force vector visualizations"""
	for i in range(nodes.size()):
		var node = nodes[i]
		var force_arrow = forces_container.get_child(i)
		
		if node.force.length() > 0.01:
			force_arrow.visible = true
			force_arrow.position = node.position
			
			# Scale and orient arrow based on force
			var force_magnitude = node.force.length()
			var force_direction = node.force.normalized()
			
			force_arrow.scale = Vector3.ONE * min(force_magnitude * force_visualization_scale, 3.0)
			force_arrow.look_at(node.position + force_direction, Vector3.UP)
		else:
			force_arrow.visible = false

func check_convergence():
	"""Check if the simulation has converged"""
	if current_iteration < 10:  # Skip early iterations
		return
	
	var velocity_sum = 0.0
	for node in nodes:
		velocity_sum += node.velocity.length()
	
	convergence_factor = velocity_sum / nodes.size()
	
	if convergence_factor < convergence_threshold and pause_on_convergence:
		stop_simulation()
		print("Simulation converged at iteration ", current_iteration)

func update_ui_stats():
	"""Update UI statistics display"""
	if not ui_container:
		return
	
	var labels = []
	for i in range(12):
		var label = ui_container.get_node("Panel/VBoxContainer/stat_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 12:
		labels[0].text = "🌌 3D Force-Directed Layout"
		labels[1].text = "Iteration: " + str(current_iteration) + "/" + str(max_iterations)
		labels[2].text = "Status: " + ("Running" if is_running else "Stopped")
		labels[3].text = "Nodes: " + str(nodes.size()) + " | Edges: " + str(edges.size())
		labels[4].text = ""
		labels[5].text = "Total Energy: " + str(total_energy).pad_decimals(2)
		labels[6].text = "Kinetic Energy: " + str(kinetic_energy).pad_decimals(2)
		labels[7].text = "Temperature: " + str(temperature).pad_decimals(3)
		labels[8].text = "Convergence: " + str(convergence_factor).pad_decimals(4)
		labels[9].text = ""
		labels[10].text = "Controls: SPACE-Start/Stop, R-Reset"
		labels[11].text = "F-Toggle Forces, E-Toggle Edges"

func _input(event):
	"""Handle user input for simulation control"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				if is_running:
					stop_simulation()
				else:
					start_simulation()
			KEY_R:
				reset_simulation()
			KEY_F:
				show_forces = not show_forces
				forces_container.visible = show_forces
			KEY_E:
				show_edges = not show_edges
				edges_container.visible = show_edges
			KEY_T:
				show_node_trails = not show_node_trails
			KEY_S:
				stress_color_mapping = not stress_color_mapping

func reset_simulation():
	"""Reset the simulation to initial state"""
	stop_simulation()
	
	# Clear existing visualization
	for child in nodes_container.get_children():
		child.queue_free()
	for child in edges_container.get_children():
		child.queue_free()
	for child in forces_container.get_children():
		child.queue_free()
	
	# Reinitialize
	current_iteration = 0
	temperature = 1.0
	initialize_graph()
	create_visualization()
	
	print("Simulation reset")

# VR Interaction methods
func grab_node(controller_id: int, world_position: Vector3) -> bool:
	"""Attempt to grab a node with VR controller"""
	if not enable_vr_manipulation:
		return false
	
	var nearest_node_id = -1
	var min_distance = manipulation_sphere_radius
	
	for node in nodes:
		var distance = node.position.distance_to(world_position)
		if distance < min_distance:
			min_distance = distance
			nearest_node_id = node.id
	
	if nearest_node_id != -1:
		grabbed_nodes[controller_id] = nearest_node_id
		nodes[nearest_node_id].is_grabbed = true
		nodes[nearest_node_id].mass *= grabbed_node_mass_multiplier
		return true
	
	return false

func release_node(controller_id: int):
	"""Release a grabbed node"""
	if controller_id in grabbed_nodes:
		var node_id = grabbed_nodes[controller_id]
		nodes[node_id].is_grabbed = false
		nodes[node_id].mass /= grabbed_node_mass_multiplier
		grabbed_nodes.erase(controller_id)

func update_grabbed_nodes():
	"""Update positions of grabbed nodes"""
	for controller_id in grabbed_nodes:
		if controller_id in controller_positions:
			var node_id = grabbed_nodes[controller_id]
			var target_position = controller_positions[controller_id]
			var node = nodes[node_id]
			
			# Smooth movement for VR comfort
			node.position = node.position.lerp(target_position, comfort_movement_speed)
			node.velocity = Vector3.ZERO  # Stop natural movement while grabbed

func get_simulation_info() -> Dictionary:
	"""Get comprehensive simulation information"""
	return {
		"name": "3D Force-Directed Layout",
		"description": "Volumetric graph physics simulation",
		"graph_properties": {
			"nodes": nodes.size(),
			"edges": edges.size(),
			"density": float(edges.size()) / float(nodes.size() * (nodes.size() - 1) / 2)
		},
		"simulation_state": {
			"iteration": current_iteration,
			"is_running": is_running,
			"convergence_factor": convergence_factor,
			"temperature": temperature,
			"total_energy": total_energy
		},
		"physics_parameters": {
			"repulsion_strength": repulsion_strength,
			"spring_constant": spring_constant,
			"damping_factor": damping_factor,
			"gravity_strength": gravity_strength
		}
	}
