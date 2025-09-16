@tool
extends Node3D

# Simple example that creates a 3-sphere network with walkable paths
func _ready():
	create_simple_network()

func create_simple_network():
	# Create 3 spheres in a line
	var positions = [
		Vector3(-10, 0, 0),
		Vector3(0, 0, 0),
		Vector3(10, 2, 0)
	]
	
	# Create each sphere with carved walkways
	for i in positions.size():
		create_walkable_sphere(positions[i], i)
		
		# Create pipe to next sphere
		if i < positions.size() - 1:
			create_walkable_pipe(positions[i], positions[i + 1], i)

func create_walkable_sphere(pos: Vector3, index: int):
	var csg_combiner = CSGCombiner3D.new()
	csg_combiner.name = "Sphere_" + str(index)
	csg_combiner.position = pos
	csg_combiner.use_collision = true
	
	# Main sphere
	var sphere = CSGSphere3D.new()
	sphere.radius = 3.0
	sphere.radial_segments = 16
	sphere.rings = 8
	csg_combiner.add_child(sphere)
	
	# Horizontal walkway carve-out
	var horizontal_tunnel = CSGCylinder3D.new()
	horizontal_tunnel.radius = 1.0
	horizontal_tunnel.height = 8.0
	horizontal_tunnel.operation = CSGShape3D.OPERATION_SUBTRACTION
	horizontal_tunnel.rotation_degrees = Vector3(0, 0, 90)  # Rotate to horizontal
	csg_combiner.add_child(horizontal_tunnel)
	
	# Vertical entrance/exit
	var vertical_tunnel = CSGCylinder3D.new()
	vertical_tunnel.radius = 1.0
	vertical_tunnel.height = 4.0
	vertical_tunnel.operation = CSGShape3D.OPERATION_SUBTRACTION
	vertical_tunnel.position.y = -1.0
	csg_combiner.add_child(vertical_tunnel)
	
	# Add material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.6, 0.4)
	material.roughness = 0.7
	csg_combiner.material_override = material
	
	add_child(csg_combiner)

func create_walkable_pipe(from_pos: Vector3, to_pos: Vector3, index: int):
	var direction = to_pos - from_pos
	var distance = direction.length()
	var center = from_pos + direction * 0.5
	
	var csg_combiner = CSGCombiner3D.new()
	csg_combiner.name = "Pipe_" + str(index)
	csg_combiner.position = center
	csg_combiner.use_collision = true
	
	# Main pipe
	var pipe = CSGCylinder3D.new()
	pipe.radius = 1.5
	pipe.height = distance
	#pipe.radial_segments = 12
	csg_combiner.add_child(pipe)
	
	# Walkway tunnel
	var tunnel = CSGCylinder3D.new()
	tunnel.radius = 0.8
	tunnel.height = distance + 0.2  # Slightly longer for clean boolean
	tunnel.operation = CSGShape3D.OPERATION_SUBTRACTION
	csg_combiner.add_child(tunnel)
	
	# Orient pipe correctly
	var up = Vector3.UP
	var forward = direction.normalized()
	var right = up.cross(forward).normalized()
	if right.length() < 0.1:  # Handle vertical pipes
		right = Vector3.RIGHT
	up = forward.cross(right).normalized()
	
	csg_combiner.look_at(to_pos, up)
	
	# Add material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.7, 0.8)
	material.metallic = 0.3
	material.roughness = 0.5
	csg_combiner.material_override = material
	
	add_child(csg_combiner)
