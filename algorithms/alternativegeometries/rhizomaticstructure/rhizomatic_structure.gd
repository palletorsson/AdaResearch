extends Node3D

class_name RhizomaticStructure

# Parameters for the rhizomatic structure
@export var num_branches: int = 50
@export var min_branch_length: float = 1.0
@export var max_branch_length: float = 5.0
@export var min_branch_thickness: float = 0.1
@export var max_branch_thickness: float = 0.3
@export var growth_direction_randomness: float = 0.7
@export var connection_probability: float = 0.2
@export var min_distance_for_connection: float = 1.0
@export var max_distance_for_connection: float = 3.0
@export var material: Material = null

# Nodes in the structure
var nodes: Array[Vector3] = []
var connections: Array[Array] = []

# Called when the node enters the scene tree for the first time
func _ready():
	generate_structure()
	draw_structure()

# Generate the rhizomatic structure
func generate_structure():
	# Clear previous data
	nodes.clear()
	connections.clear()
	
	# Start with a root node
	nodes.append(Vector3.ZERO)
	
	# Generate branches
	for i in range(num_branches):
		var parent_idx = randi() % nodes.size()
		var parent_pos = nodes[parent_idx]
		
		# Determine growth direction - partly random, partly influenced by parent's position
		var direction = Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()
		
		# Mix with a tendency to grow away from center
		var away_from_center = parent_pos.normalized()
		if parent_pos.length() < 0.1:
			away_from_center = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		
		direction = direction.lerp(away_from_center, 1.0 - growth_direction_randomness)
		direction = direction.normalized()
		
		# Calculate new node position
		var branch_length = randf_range(min_branch_length, max_branch_length)
		var new_pos = parent_pos + direction * branch_length
		
		# Add new node
		nodes.append(new_pos)
		
		# Add connection to parent
		connections.append([parent_idx, nodes.size() - 1])
		
		# Try to make connections to nearby nodes (rhizomatic property)
		for j in range(nodes.size() - 1):
			if j == parent_idx:
				continue
				
			var other_pos = nodes[j]
			var distance = new_pos.distance_to(other_pos)
			
			if distance >= min_distance_for_connection and distance <= max_distance_for_connection:
				if randf() < connection_probability:
					connections.append([j, nodes.size() - 1])

# Draw the structure using MeshInstances
func draw_structure():
	for i in range(connections.size()):
		var start_idx = connections[i][0]
		var end_idx = connections[i][1]
		
		var start_pos = nodes[start_idx]
		var end_pos = nodes[end_idx]
		
		create_branch(start_pos, end_pos)

# Create a cylindrical branch between two points
func create_branch(start: Vector3, end: Vector3):
	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	var direction = end - start
	var length = direction.length()
	direction = direction.normalized()
	
	# Create cylinder mesh
	var thickness = randf_range(min_branch_thickness, max_branch_thickness)
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = thickness
	cylinder_mesh.bottom_radius = thickness
	cylinder_mesh.height = length
	
	if material:
		cylinder_mesh.material = material
	
	mesh_instance.mesh = cylinder_mesh
	
	# Position and rotate the cylinder
	mesh_instance.position = start + direction * (length / 2)
	
	# Calculate rotation to align with direction
	var origin = Vector3(0, 1, 0)
	var axis = origin.cross(direction).normalized()
	var angle = origin.angle_to(direction)
	
	if axis.length() < 0.001:
		if direction.dot(origin) > 0:
			mesh_instance.rotation = Vector3.ZERO
		else:
			mesh_instance.rotation = Vector3(PI, 0, 0)
	else:
		mesh_instance.transform.basis = Basis(axis, angle)

# Clear the structure
func clear():
	for child in get_children():
		child.queue_free()
	
	nodes.clear()
	connections.clear()
	
# Regenerate the structure
func regenerate():
	clear()
	generate_structure()
	draw_structure()
