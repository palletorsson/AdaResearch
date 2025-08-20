extends Node3D

var time = 0.0
var nodes = []
var edges = []
var node_count = 8
var spring_length = 2.0
var spring_strength = 0.1
var repulsion_strength = 50.0
var damping = 0.9
var total_energy = 0.0

class ForceGraphNode:
	var id: int
	var position: Vector2
	var velocity: Vector2
	var force: Vector2
	var visual_object: CSGSphere3D
	
	func _init(node_id: int, pos: Vector2):
		id = node_id
		position = pos
		velocity = Vector2.ZERO
		force = Vector2.ZERO

class ForceGraphEdge:
	var from_id: int
	var to_id: int
	var visual_object: CSGCylinder3D
	
	func _init(from: int, to: int):
		from_id = from
		to_id = to

func _ready():
	create_graph()
	setup_materials()

func create_graph():
	# Create nodes with random positions
	for i in range(node_count):
		var angle = i * 2.0 * PI / node_count
		var radius = 3.0
		var pos = Vector2(cos(angle) * radius, sin(angle) * radius)
		pos += Vector2(randf() * 2 - 1, randf() * 2 - 1)  # Add randomness
		
		var node = ForceGraphNode.new(i, pos)
		
		var node_sphere = CSGSphere3D.new()
		node_sphere.radius = 0.2
		node_sphere.position = Vector3(pos.x, pos.y, 0)
		get_or_create_container("GraphNodes").add_child(node_sphere)
		node.visual_object = node_sphere
		
		nodes.append(node)
	
	# Create edges (random connections)
	var connections = [
		[0, 1], [1, 2], [2, 3], [3, 0], [0, 4], [1, 5], 
		[2, 6], [3, 7], [4, 5], [5, 6], [6, 7], [7, 4]
	]
	
	for conn in connections:
		if conn[0] < node_count and conn[1] < node_count:
			var edge = ForceGraphEdge.new(conn[0], conn[1])
			create_edge_visual(edge)
			edges.append(edge)

func get_or_create_container(container_name: String) -> Node3D:
	"""Get or create a container node"""
	var container = get_node_or_null(container_name)
	if not container:
		container = Node3D.new()
		container.name = container_name
		add_child(container)
	return container

func create_edge_visual(edge: ForceGraphEdge):
	var from_node = nodes[edge.from_id]
	var to_node = nodes[edge.to_id]
	
	var edge_cylinder = CSGCylinder3D.new()
	# FIXED: Use proper Godot 4 CSGCylinder3D properties
	edge_cylinder.radius = 0.03
	#edge_cylinder.bottom_radius = 0.03
	
	get_or_create_container("GraphEdges").add_child(edge_cylinder)
	edge.visual_object = edge_cylinder
	
	update_edge_visual(edge)

func update_edge_visual(edge: ForceGraphEdge):
	var from_pos = nodes[edge.from_id].position
	var to_pos = nodes[edge.to_id].position
	var distance = from_pos.distance_to(to_pos)
	
	edge.visual_object.height = distance
	edge.visual_object.position = Vector3((from_pos + to_pos).x * 0.5, (from_pos + to_pos).y * 0.5, 0)
	
	var direction = (to_pos - from_pos).normalized()
	var angle = atan2(direction.y, direction.x)
	edge.visual_object.rotation_degrees = Vector3(0, 0, angle * 180.0 / PI - 90)

func setup_materials():
	# Node materials
	for node in nodes:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.8, 1.0, 1.0)
		material.emission_enabled = true
		material.emission = Color(0.1, 0.3, 0.5, 1.0)
		material.emission_energy = 1.0
		node.visual_object.material_override = material
	
	# Edge materials
	for edge in edges:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.7, 0.7, 0.7, 1.0)
		material.emission_enabled = true
		material.emission = Color(0.2, 0.2, 0.2, 1.0)
		material.emission_energy = 1.0
		edge.visual_object.material_override = material
	
	# Create and setup indicator materials
	setup_indicator_materials()

func setup_indicator_materials():
	# Force indicator
	var force_indicator = get_or_create_box_indicator("ForceIndicator", Vector3(0.3, 1.0, 0.3))
	var force_material = StandardMaterial3D.new()
	force_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	force_material.emission_enabled = true
	force_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	force_material.emission_energy = 1.0
	force_indicator.material_override = force_material
	
	# Energy level indicator
	var energy_indicator = get_or_create_box_indicator("EnergyLevel", Vector3(0.3, 1.0, 0.3))
	var energy_material = StandardMaterial3D.new()
	energy_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	energy_material.emission_enabled = true
	energy_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	energy_material.emission_energy = 1.0
	energy_indicator.material_override = energy_material

func get_or_create_box_indicator(indicator_name: String, size: Vector3):
	"""Get or create an indicator CSGBox3D - FIXED: Renamed for clarity"""
	var indicator = get_node_or_null(indicator_name)
	if not indicator:
		indicator = CSGBox3D.new()
		indicator.name = indicator_name
		indicator.size = size
		indicator.position = Vector3(0, -3, 0)
		add_child(indicator)
	return indicator

func get_or_create_cylinder_indicator(indicator_name: String, radius: float, height: float) -> CSGCylinder3D:
	"""Get or create an indicator CSGCylinder3D - FIXED: Added separate function for cylinders"""
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

func _process(delta):
	time += delta
	
	# Calculate forces
	calculate_forces()
	
	# Update positions
	update_positions(delta)
	
	# Update visuals
	update_visuals()
	
	animate_indicators()

func calculate_forces():
	total_energy = 0.0
	
	# Reset forces
	for node in nodes:
		node.force = Vector2.ZERO
	
	# Spring forces (attraction between connected nodes)
	for edge in edges:
		var from_node = nodes[edge.from_id]
		var to_node = nodes[edge.to_id]
		
		var distance_vec = to_node.position - from_node.position
		var distance = distance_vec.length()
		
		# FIXED: Prevent division by zero
		if distance > 0:
			var direction = distance_vec.normalized()
			var force_magnitude = spring_strength * (distance - spring_length)
			var force = direction * force_magnitude
			
			from_node.force += force
			to_node.force -= force
			
			total_energy += 0.5 * spring_strength * pow(distance - spring_length, 2)
	
	# Repulsion forces (all nodes repel each other)
	for i in range(nodes.size()):
		for j in range(i + 1, nodes.size()):
			var node1 = nodes[i]
			var node2 = nodes[j]
			
			var distance_vec = node2.position - node1.position
			var distance = distance_vec.length()
			
			# FIXED: Better distance checking and minimum distance
			if distance > 0.01:  # Minimum distance to prevent extreme forces
				var direction = distance_vec.normalized()
				var force_magnitude = repulsion_strength / (distance * distance)
				var force = direction * force_magnitude
				
				node1.force -= force
				node2.force += force
				
				total_energy += repulsion_strength / distance

func update_positions(delta):
	for node in nodes:
		# Update velocity with force
		node.velocity += node.force * delta
		
		# Apply damping
		node.velocity *= damping
		
		# FIXED: Clamp velocity to prevent instability
		var max_velocity = 10.0
		if node.velocity.length() > max_velocity:
			node.velocity = node.velocity.normalized() * max_velocity
		
		# Update position
		node.position += node.velocity * delta
		
		# Keep nodes within bounds
		var bound = 6.0
		node.position.x = clamp(node.position.x, -bound, bound)
		node.position.y = clamp(node.position.y, -bound, bound)

func update_visuals():
	# Update node positions
	for node in nodes:
		if node.visual_object and is_instance_valid(node.visual_object):
			node.visual_object.position = Vector3(node.position.x, node.position.y, 0)
			
			# Scale based on force magnitude
			var force_magnitude = node.force.length()
			var scale = 1.0 + min(force_magnitude * 0.1, 0.5)  # FIXED: Clamp scale
			node.visual_object.scale = Vector3.ONE * scale
	
	# Update edge visuals
	for edge in edges:
		if edge.visual_object and is_instance_valid(edge.visual_object):
			update_edge_visual(edge)

func animate_indicators():
	# Force indicator (average force magnitude)
	var avg_force = 0.0
	for node in nodes:
		avg_force += node.force.length()
	
	if nodes.size() > 0:
		avg_force /= nodes.size()
	
	var force_height = min(avg_force / 10.0, 1.0) * 2.0 + 0.5
	var force_indicator = get_node_or_null("ForceIndicator")
	if force_indicator and force_indicator is CSGBox3D:
		force_indicator.size.y = force_height
		force_indicator.position.y = -3 + force_height/2
	
	# Energy level indicator
	var energy_height = min(total_energy / 100.0, 1.0) * 2.0 + 0.5
	var energy_indicator = get_node_or_null("EnergyLevel")
	if energy_indicator and energy_indicator is CSGBox3D:
		energy_indicator.size.y = energy_height
		energy_indicator.position.y = -3 + energy_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	if force_indicator and is_instance_valid(force_indicator):
		force_indicator.scale.x = pulse
		force_indicator.scale.z = pulse  # FIXED: Also animate Z scale for better effect
	if energy_indicator and is_instance_valid(energy_indicator):
		energy_indicator.scale.x = pulse
		energy_indicator.scale.z = pulse  # FIXED: Also animate Z scale for better effect

# FIXED: Added utility functions for better debugging
func print_debug_info():
	"""Print debug information about the graph state"""
	print("=== Graph Debug Info ===")
	print("Node count: ", nodes.size())
	print("Edge count: ", edges.size())
	print("Total energy: ", total_energy)
	print("Average force: ", get_average_force())

func get_average_force() -> float:
	"""Get the average force magnitude across all nodes"""
	var avg_force = 0.0
	for node in nodes:
		avg_force += node.force.length()
	return avg_force / nodes.size() if nodes.size() > 0 else 0.0

func reset_simulation():
	"""Reset the simulation to initial state"""
	# Clear existing objects
	for node in nodes:
		if node.visual_object and is_instance_valid(node.visual_object):
			node.visual_object.queue_free()
	for edge in edges:
		if edge.visual_object and is_instance_valid(edge.visual_object):
			edge.visual_object.queue_free()
	
	# Clear arrays
	nodes.clear()
	edges.clear()
	time = 0.0
	total_energy = 0.0
	
	# Recreate graph
	create_graph()
	setup_materials()
