@tool
extends Node3D

# Network configuration
@export var sphere_count: int = 5
@export var sphere_radius: float = 10.0
@export var pipe_radius: float = 6.0
@export var network_width: float = 50.0
@export var walkway_radius: float = 5.0
@export var material: StandardMaterial3D

# Generate network when button is pressed in editor
@export var generate_network: bool = false : set = _generate_network

var sphere_positions: Array[Vector3] = []

func _ready():
	if Engine.is_editor_hint():
		_setup_default_material()

func _setup_default_material():
	if not material:
		material = StandardMaterial3D.new()
		material.albedo_color = Color(0.7, 0.7, 0.9)
		material.metallic = 0.3
		material.roughness = 0.4

func _generate_network(value):
	if not value:
		return
		
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	# Generate sphere positions in a horizontal line with some variation
	sphere_positions.clear()
	for i in sphere_count:
		var x = (float(i) / (sphere_count - 1)) * network_width - network_width * 0.5
		var y = randf_range(-1.0, 1.0)  # Small vertical variation
		var z = randf_range(-2.0, 2.0)  # Small depth variation
		sphere_positions.append(Vector3(x, y, z))
	
	# Create the network
	_create_sphere_network()

func _create_sphere_network():
	# Create each sphere with carved walkways
	for i in sphere_positions.size():
		_create_carved_sphere(i)
	
	# Create pipes between adjacent spheres
	for i in sphere_positions.size() - 1:
		_create_carved_pipe(i, i + 1)

func _create_carved_sphere(sphere_index: int):
	var pos = sphere_positions[sphere_index]
	
	# Create the main sphere
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = sphere_radius
	sphere_mesh.height = sphere_radius * 2
	
	# Create walkway carve-outs
	var carve_spheres: Array[Mesh] = []
	
	# Carve horizontal walkway through the center
	var horizontal_carve = SphereMesh.new()
	horizontal_carve.radius = walkway_radius
	horizontal_carve.height = walkway_radius * 2
	carve_spheres.append(horizontal_carve)
	
	# If connected to previous sphere, carve in that direction
	if sphere_index > 0:
		var prev_pos = sphere_positions[sphere_index - 1]
		var direction = (prev_pos - pos).normalized()
		var carve_pos = direction * (sphere_radius * 0.7)
		
		var connection_carve = SphereMesh.new()
		connection_carve.radius = walkway_radius * 1.1
		carve_spheres.append(connection_carve)
	
	# If connected to next sphere, carve in that direction
	if sphere_index < sphere_positions.size() - 1:
		var next_pos = sphere_positions[sphere_index + 1]
		var direction = (next_pos - pos).normalized()
		var carve_pos = direction * (sphere_radius * 0.7)
		
		var connection_carve = SphereMesh.new()
		connection_carve.radius = walkway_radius * 1.1
		carve_spheres.append(connection_carve)
	
	# Create the carved sphere using CSG
	var sphere_node = _create_csg_carved_mesh(sphere_mesh, carve_spheres, pos)
	sphere_node.name = "Sphere_" + str(sphere_index)
	add_child(sphere_node)
	
	if Engine.is_editor_hint():
		sphere_node.owner = get_tree().edited_scene_root

func _create_carved_pipe(from_index: int, to_index: int):
	var from_pos = sphere_positions[from_index]
	var to_pos = sphere_positions[to_index]
	
	var direction = to_pos - from_pos
	var direction_normalized = direction.normalized()
	
	# Calculate the actual connection points on sphere surfaces
	var from_surface = from_pos + direction_normalized * sphere_radius
	var to_surface = to_pos - direction_normalized * sphere_radius
	
	# Calculate the actual pipe distance and center
	var pipe_direction = to_surface - from_surface
	var pipe_distance = pipe_direction.length()
	var center = from_surface + pipe_direction * 0.5
	
	# Create pipe mesh
	var pipe_mesh = CylinderMesh.new()
	pipe_mesh.top_radius = pipe_radius
	pipe_mesh.bottom_radius = pipe_radius
	pipe_mesh.height = pipe_distance
	
	# Create walkway carve-out
	var walkway_carve = CylinderMesh.new()
	walkway_carve.top_radius = walkway_radius
	walkway_carve.bottom_radius = walkway_radius
	walkway_carve.height = pipe_distance + 0.1  # Slightly longer to ensure clean boolean
	
	# Create the carved pipe
	var pipe_node = _create_csg_carved_mesh(pipe_mesh, [walkway_carve], center)
	
	# Orient the pipe to align with the direction between spheres
	# Cylinder's default orientation is along Y-axis, we need to rotate it to align with direction
	var look_direction = pipe_direction.normalized()
	
	# Calculate rotation to align cylinder's Y-axis with the direction vector
	if look_direction != Vector3.UP and look_direction != -Vector3.UP:
		# Use cross product to find rotation axis
		var rotation_axis = Vector3.UP.cross(look_direction).normalized()
		var rotation_angle = Vector3.UP.angle_to(look_direction)
		pipe_node.rotation = rotation_axis * rotation_angle
	else:
		# Handle edge case where direction is parallel to Y-axis
		if look_direction == -Vector3.UP:
			pipe_node.rotation = Vector3.RIGHT * PI
	
	pipe_node.name = "Pipe_" + str(from_index) + "_to_" + str(to_index)
	add_child(pipe_node)
	
	if Engine.is_editor_hint():
		pipe_node.owner = get_tree().edited_scene_root

func _create_csg_carved_mesh(base_mesh: Mesh, carve_meshes: Array[Mesh], position: Vector3) -> Node3D:
	# Create main CSG shape
	var csg_combiner = CSGCombiner3D.new()
	csg_combiner.position = position
	csg_combiner.material_override = material
	csg_combiner.use_collision = true
	
	# Add base shape
	var base_shape = CSGMesh3D.new()
	base_shape.mesh = base_mesh
	csg_combiner.add_child(base_shape)
	
	if Engine.is_editor_hint():
		base_shape.owner = get_tree().edited_scene_root
	
	# Add carve-out shapes
	for i in carve_meshes.size():
		var carve_shape = CSGMesh3D.new()
		carve_shape.mesh = carve_meshes[i]
		carve_shape.operation = CSGShape3D.OPERATION_SUBTRACTION
		csg_combiner.add_child(carve_shape)
		
		if Engine.is_editor_hint():
			carve_shape.owner = get_tree().edited_scene_root
	
	return csg_combiner

# Alternative method using MeshInstance3D with ArrayMesh for more control
func _create_walkable_sphere_mesh(sphere_pos: Vector3, connections: Array[Vector3]) -> ArrayMesh:
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Generate sphere vertices with carved areas
	var rings = 16
	var sectors = 32
	
	for ring in rings:
		var phi = PI * float(ring) / float(rings - 1)
		for sector in sectors:
			var theta = 2.0 * PI * float(sector) / float(sectors)
			
			var x = sin(phi) * cos(theta)
			var y = cos(phi)
			var z = sin(phi) * sin(theta)
			
			var vertex = Vector3(x, y, z) * sphere_radius
			
			# Check if this vertex should be carved out
			var should_carve = false
			
			# Check for walkway carve-out (horizontal tunnel)
			if abs(vertex.y) < walkway_radius and vertex.length() < sphere_radius - 0.1:
				should_carve = true
			
			# Check for connection carve-outs
			for connection in connections:
				var direction = (connection - sphere_pos).normalized()
				var projected = vertex.dot(direction)
				var distance_to_line = (vertex - direction * projected).length()
				
				if projected > 0 and distance_to_line < walkway_radius * 1.1:
					should_carve = true
			
			if not should_carve:
				vertices.append(vertex)
				normals.append(vertex.normalized())
				uvs.append(Vector2(float(sector) / sectors, float(ring) / rings))
	
	# Generate indices (simplified - you'd need proper triangulation)
	# This is a basic example - for production use, consider using a proper mesh generation library
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	if vertices.size() > 0:
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return array_mesh
