extends Node3D

# Sierpinski Triangle - 3D Recursive Triangle Subdivision
# Starts with a 1-meter equilateral triangle and subdivides it recursively
# Creates a beautiful fractal pattern by removing the center triangle each time

# Settings
@export var subdivision_interval: float = 1.0  # Time between subdivisions
@export var max_iterations: int = 6  # Maximum subdivision depth
@export var auto_start: bool = true  # Auto-start subdivision
@export var triangle_size: float = 1.0  # Size of initial triangle (meters)
@export var triangle_thickness: float = 0.05  # Thickness of 3D triangles
@export var extrude_on_subdivision: bool = true  # Extrude triangles upward with each iteration
@export var extrusion_height: float = 0.15  # How much to extrude per iteration
@export var colorize_by_depth: bool = true  # Color triangles by subdivision depth

# Internal state
var current_iteration: int = 0
var subdivision_timer: float = 0.0
var is_subdividing: bool = false
var current_triangles: Array = []  # Array of triangle data

func _ready():
	print("SierpinskiTriangle: Ready")
	print("SierpinskiTriangle: Will subdivide to %d iterations" % max_iterations)

	# Create the initial triangle
	create_initial_triangle()

	# Start automatic subdivision if enabled
	if auto_start:
		is_subdividing = true
		print("SierpinskiTriangle: Auto-subdivision enabled")

func _process(delta: float):
	if not is_subdividing:
		return

	# Update timer
	subdivision_timer += delta

	# Check if it's time to subdivide
	if subdivision_timer >= subdivision_interval:
		subdivision_timer = 0.0
		perform_subdivision()

# Create the initial 1-meter equilateral triangle
func create_initial_triangle():
	# Create equilateral triangle vertices (1 meter)
	var height = triangle_size * sqrt(3.0) / 2.0  # Height of equilateral triangle

	var v1 = Vector3(-triangle_size / 2.0, 0, height / 3.0)  # Bottom left
	var v2 = Vector3(triangle_size / 2.0, 0, height / 3.0)   # Bottom right
	var v3 = Vector3(0, 0, -2.0 * height / 3.0)              # Top (centered)

	var triangle_data = {
		"v1": v1,
		"v2": v2,
		"v3": v3,
		"depth": 0,
		"y_offset": 0.0
	}

	create_triangle_mesh(triangle_data)
	current_triangles = [triangle_data]

	print("SierpinskiTriangle: Created initial triangle")

# Perform one subdivision iteration
func perform_subdivision():
	if current_iteration >= max_iterations:
		print("SierpinskiTriangle: Reached maximum iterations (%d)" % max_iterations)
		is_subdividing = false
		return

	current_iteration += 1
	print("SierpinskiTriangle: Subdivision iteration %d" % current_iteration)

	var new_triangles = []

	# For each triangle, subdivide into 3 smaller triangles
	for triangle in current_triangles:
		var subdivided = subdivide_triangle(triangle)
		new_triangles.append_array(subdivided)

	current_triangles = new_triangles

	print("SierpinskiTriangle: Created %d triangles" % current_triangles.size())

# Subdivide a triangle into 3 smaller triangles (Sierpinski pattern)
func subdivide_triangle(triangle: Dictionary) -> Array:
	var v1 = triangle.v1
	var v2 = triangle.v2
	var v3 = triangle.v3
	var depth = triangle.depth + 1
	var base_y = triangle.y_offset

	# Calculate midpoints of each edge
	var m1 = (v1 + v2) / 2.0  # Midpoint of bottom edge
	var m2 = (v2 + v3) / 2.0  # Midpoint of right edge
	var m3 = (v3 + v1) / 2.0  # Midpoint of left edge

	# Calculate new y offset if extruding
	var new_y_offset = base_y
	if extrude_on_subdivision:
		new_y_offset += extrusion_height

	# Create 3 corner triangles (skip the center triangle - that's what creates the fractal!)
	var triangles = []

	# Bottom-left triangle
	var t1 = {
		"v1": v1,
		"v2": m1,
		"v3": m3,
		"depth": depth,
		"y_offset": new_y_offset
	}
	create_triangle_mesh(t1)
	triangles.append(t1)

	# Bottom-right triangle
	var t2 = {
		"v1": m1,
		"v2": v2,
		"v3": m2,
		"depth": depth,
		"y_offset": new_y_offset
	}
	create_triangle_mesh(t2)
	triangles.append(t2)

	# Top triangle
	var t3 = {
		"v1": m3,
		"v2": m2,
		"v3": v3,
		"depth": depth,
		"y_offset": new_y_offset
	}
	create_triangle_mesh(t3)
	triangles.append(t3)

	# Note: We intentionally skip the center triangle (m1, m2, m3)
	# This is what creates the Sierpinski fractal pattern!

	return triangles

# Create a 3D mesh for a triangle
func create_triangle_mesh(triangle: Dictionary):
	var mesh_instance = MeshInstance3D.new()
	var mesh = create_extruded_triangle_mesh(triangle)
	mesh_instance.mesh = mesh

	# Create material with color based on depth
	var material = StandardMaterial3D.new()

	if colorize_by_depth:
		# Rainbow gradient by depth
		var hue = float(triangle.depth) / max_iterations
		material.albedo_color = Color.from_hsv(hue, 0.8, 0.9)
	else:
		# Classic fractal colors
		material.albedo_color = Color(0.2, 0.6, 0.9)

	material.metallic = 0.3
	material.roughness = 0.6

	# Add slight emission for glowing effect
	if triangle.depth > 0:
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.2
		material.emission_energy = 0.3

	mesh_instance.material_override = material

	# Position at y_offset
	mesh_instance.position.y = triangle.y_offset

	add_child(mesh_instance)

# Create an extruded triangle mesh with proper 3D geometry
func create_extruded_triangle_mesh(triangle: Dictionary) -> ArrayMesh:
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var v1 = triangle.v1
	var v2 = triangle.v2
	var v3 = triangle.v3
	var thickness = triangle_thickness

	# Bottom face vertices (y = 0)
	var b1 = v1
	var b2 = v2
	var b3 = v3

	# Top face vertices (y = thickness)
	var t1 = v1 + Vector3(0, thickness, 0)
	var t2 = v2 + Vector3(0, thickness, 0)
	var t3 = v3 + Vector3(0, thickness, 0)

	# Calculate normal for top/bottom faces
	var edge1 = v2 - v1
	var edge2 = v3 - v1
	var face_normal = edge1.cross(edge2).normalized()

	# Bottom face (0, 1, 2)
	vertices.append(b1)
	vertices.append(b2)
	vertices.append(b3)
	normals.append(-face_normal)
	normals.append(-face_normal)
	normals.append(-face_normal)
	indices.append(0)
	indices.append(2)
	indices.append(1)

	# Top face (3, 4, 5)
	vertices.append(t1)
	vertices.append(t2)
	vertices.append(t3)
	normals.append(face_normal)
	normals.append(face_normal)
	normals.append(face_normal)
	indices.append(3)
	indices.append(4)
	indices.append(5)

	# Side faces (3 rectangular sides)
	# Side 1: b1-b2-t2-t1
	var side1_normal = edge1.cross(Vector3.UP).normalized()
	vertices.append(b1)  # 6
	vertices.append(b2)  # 7
	vertices.append(t2)  # 8
	vertices.append(t1)  # 9
	for i in range(4):
		normals.append(side1_normal)
	indices.append(6)
	indices.append(7)
	indices.append(8)
	indices.append(6)
	indices.append(8)
	indices.append(9)

	# Side 2: b2-b3-t3-t2
	edge2 = v3 - v2
	var side2_normal = edge2.cross(Vector3.UP).normalized()
	vertices.append(b2)  # 10
	vertices.append(b3)  # 11
	vertices.append(t3)  # 12
	vertices.append(t2)  # 13
	for i in range(4):
		normals.append(side2_normal)
	indices.append(10)
	indices.append(11)
	indices.append(12)
	indices.append(10)
	indices.append(12)
	indices.append(13)

	# Side 3: b3-b1-t1-t3
	var edge3 = v1 - v3
	var side3_normal = edge3.cross(Vector3.UP).normalized()
	vertices.append(b3)  # 14
	vertices.append(b1)  # 15
	vertices.append(t1)  # 16
	vertices.append(t3)  # 17
	for i in range(4):
		normals.append(side3_normal)
	indices.append(14)
	indices.append(15)
	indices.append(16)
	indices.append(14)
	indices.append(16)
	indices.append(17)

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	return mesh

# Manual control functions
func start_subdivision():
	is_subdividing = true
	subdivision_timer = 0.0
	print("SierpinskiTriangle: Started manually")

func stop_subdivision():
	is_subdividing = false
	print("SierpinskiTriangle: Stopped manually")

func reset():
	# Clear all meshes
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()

	current_iteration = 0
	subdivision_timer = 0.0
	is_subdividing = false
	current_triangles.clear()

	# Recreate initial triangle
	create_initial_triangle()

	print("SierpinskiTriangle: Reset")

func step():
	perform_subdivision()
