extends Node3D 

@export var sphere_scene: PackedScene  # Packed scene for the sphere
@export var scale_factor: float = 0.2  # Factor to scale the sphere down
@export var line_thickness: float = 0.05  # Thickness of the connecting lines
@export var structure_radius: float = 5.0  # Radius of the icosphere
@export var subdivisions: int = 2  # Number of subdivisions for smoothing
@export var cylinder_color: Color = Color(1.0, 1.0, 1.0)  # Color of the cylinders

@export var max_displacement: float = 0.5  # Maximum displacement strength
@export var falloff_strength: float = 2.0  # Higher = distortion stronger at poles
@export var control_point: Vector3 = Vector3(0, 1, 0)  # Distortion reference (e.g., north pole)

var sphere_positions: Dictionary = {}  # Stores vertex positions
var index_count: int = 0  # Counter for indexing vertices

func _ready():
	# Generate an icosphere structure
	var data  = generate_icosphere(subdivisions)
	var vertices = data[0]
	var triangles = data[1]

	# Place spheres at vertices
	for v in vertices:
		var sphere = create_sphere_instance()
		
		# Calculate **positional distortion**
		var displacement = calculate_positional_displacement(v)

		var position = (v + displacement).normalized() * structure_radius  # Ensure it remains on the sphere
		sphere.global_transform.origin = position
		add_child(sphere)
		sphere_positions[index_count] = position
		index_count += 1

	# Connect vertices using edges
	for i in range(0, triangles.size(), 3):
		var v1 = sphere_positions[triangles[i]]
		var v2 = sphere_positions[triangles[i + 1]]
		var v3 = sphere_positions[triangles[i + 2]]

		draw_cylinder_between_points(v1, v2)
		draw_cylinder_between_points(v2, v3)
		draw_cylinder_between_points(v3, v1)

# ============================================
#  Generate Icosahedron & Subdivide to Icosphere
# ============================================

func generate_icosphere(subdiv: int):
	var t = (1.0 + sqrt(5.0)) / 2.0
	var vertices = [
		Vector3(-1,  t,  0), Vector3( 1,  t,  0), Vector3(-1, -t,  0), Vector3( 1, -t,  0),
		Vector3( 0, -1,  t), Vector3( 0,  1,  t), Vector3( 0, -1, -t), Vector3( 0,  1, -t),
		Vector3( t,  0, -1), Vector3( t,  0,  1), Vector3(-t,  0, -1), Vector3(-t,  0,  1)
	]
	var triangles = [
		0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11, 
		1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8,
		3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9,
		4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1
	]

	# Normalize vertices to make it a sphere
	for i in range(vertices.size()):
		vertices[i] = vertices[i].normalized()

	# Perform subdivisions
	var middle_point_cache = {}
	for j in range(subdiv):
		var new_triangles = []
		for i in range(0, triangles.size(), 3):
			var a = get_middle_point(triangles[i], triangles[i + 1], vertices, middle_point_cache)
			var b = get_middle_point(triangles[i + 1], triangles[i + 2], vertices, middle_point_cache)
			var c = get_middle_point(triangles[i + 2], triangles[i], vertices, middle_point_cache)

			new_triangles.append_array([
				triangles[i], a, c,
				triangles[i + 1], b, a,
				triangles[i + 2], c, b,
				a, b, c
			])
		triangles = new_triangles
		
	return [vertices, triangles]

func get_middle_point(i1: int, i2: int, vertices: Array, cache: Dictionary) -> int:
	var smaller = min(i1, i2)
	var greater = max(i1, i2)
	var key = str(smaller) + "-" + str(greater)
	
	if key in cache:
		return cache[key]
	
	var middle = (vertices[i1] + vertices[i2]).normalized()
	vertices.append(middle)
	cache[key] = vertices.size() - 1
	return cache[key]

# ============================================
#  Dynamic Positional Distortion
# ============================================

func calculate_positional_displacement(vertex: Vector3) -> Vector3:
	""" Adds more distortion near the control point, using a radial falloff. """
	var distance = vertex.distance_to(control_point.normalized())  # Distance to reference
	var falloff = exp(-falloff_strength * distance)  # Exponential falloff

	# Randomized perturbation with positional control
	var random_offset = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
	return random_offset * max_displacement * falloff

# ============================================
#  Spheres & Cylinders
# ============================================

func create_sphere_instance() -> Node3D:
	if not sphere_scene:
		print("Sphere scene not assigned")
		return null
	
	var sphere = sphere_scene.instantiate() as Node3D
	sphere.scale = Vector3(scale_factor, scale_factor, scale_factor)
	return sphere

# Function to draw a cylinder between two points in 3D space
func draw_cylinder_between_points(start: Vector3, end: Vector3):
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = line_thickness
	cylinder_mesh.bottom_radius = line_thickness
	cylinder_mesh.height = start.distance_to(end)
	
	# Create a new mesh instance for the cylinder
	var cylinder = MeshInstance3D.new()
	cylinder.mesh = cylinder_mesh
	
	# Create a material for the cylinder
	var material = StandardMaterial3D.new()
	material.albedo_color = cylinder_color
	material.emission_enabled = true
	material.emission = cylinder_color * 0.5  # Control the glow intensity of the cylinder
	cylinder.material_override = material

	# Position and rotate the cylinder between the start and end points
	var mid_point = (start + end) * 0.5
	cylinder.global_transform.origin = mid_point
	
	# Calculate the direction and rotation for the cylinder
	var direction = (end - start).normalized()
	var rotation = Quaternion(Vector3(0, 1, 0), direction)
	cylinder.rotation = rotation.get_euler()
	
	# Add the cylinder to the scene
	add_child(cylinder)
