extends Node3D

# PlatonicSolids.gd - Creates all five Platonic solids in Godot 4
# For Ada Research VR project

# Constants for the Platonic solids
const PHI = 1.618033988749895  # Golden ratio, used for some solids

# Called when the node enters the scene tree for the first time
func _ready():
	create_all_solids()

# Create all five Platonic solids
func create_all_solids():
	var tetrahedron = create_tetrahedron()
	tetrahedron.position = Vector3(-4, 0, 0)
	add_child(tetrahedron)
	
	var cube = create_cube()
	cube.position = Vector3(-2, 0, 0)
	add_child(cube)
	
	var octahedron = create_octahedron()
	octahedron.position = Vector3(0, 0, 0)
	add_child(octahedron)
	
	var dodecahedron = create_dodecahedron()
	dodecahedron.position = Vector3(2, 0, 0)
	add_child(dodecahedron)
	
	var icosahedron = create_icosahedron()
	icosahedron.position = Vector3(4, 0, 0)
	add_child(icosahedron)
	
	print("Created all Platonic solids")

# Create tetrahedron (4 faces, 4 vertices, 6 edges)
func create_tetrahedron():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Define vertices at equal distance from origin
	var vertices = [
		Vector3(1, 1, 1).normalized(),
		Vector3(-1, -1, 1).normalized(),
		Vector3(-1, 1, -1).normalized(),
		Vector3(1, -1, -1).normalized()
	]
	
	# Define faces (triangles)
	var faces = [
		[0, 1, 2],
		[0, 3, 1],
		[0, 2, 3],
		[1, 3, 2]
	]
	
	# Create the mesh
	for face in faces:
		var v0 = vertices[face[0]]
		var v1 = vertices[face[1]]
		var v2 = vertices[face[2]]
		
		# Calculate normal
		var normal = (v1 - v0).cross(v2 - v0).normalized()
		
		# Add vertices with normals
		st.set_normal(normal)
		st.add_vertex(v0)
		st.add_vertex(v1)
		st.add_vertex(v2)
	
	# Create the mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "Tetrahedron"
	
	# Add a material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.2, 0.2)  # Red
	mesh_instance.set_surface_override_material(0, material)
	
	return mesh_instance

# Create cube (6 faces, 8 vertices, 12 edges)
func create_cube():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Define vertices
	var vertices = [
		Vector3(-0.5, -0.5, -0.5),  # 0: bottom-left-back
		Vector3(0.5, -0.5, -0.5),   # 1: bottom-right-back
		Vector3(0.5, 0.5, -0.5),    # 2: top-right-back
		Vector3(-0.5, 0.5, -0.5),   # 3: top-left-back
		Vector3(-0.5, -0.5, 0.5),   # 4: bottom-left-front
		Vector3(0.5, -0.5, 0.5),    # 5: bottom-right-front
		Vector3(0.5, 0.5, 0.5),     # 6: top-right-front
		Vector3(-0.5, 0.5, 0.5)     # 7: top-left-front
	]
	
	# Define faces (as quads that we'll split into triangles)
	var faces = [
		[0, 1, 2, 3],  # back
		[5, 4, 7, 6],  # front
		[4, 0, 3, 7],  # left
		[1, 5, 6, 2],  # right
		[3, 2, 6, 7],  # top
		[4, 5, 1, 0]   # bottom
	]
	
	# Create the mesh
	for face in faces:
		var v0 = vertices[face[0]]
		var v1 = vertices[face[1]]
		var v2 = vertices[face[2]]
		var v3 = vertices[face[3]]
		
		# Calculate normal (same for both triangles of the quad)
		var normal = (v1 - v0).cross(v3 - v0).normalized()
		
		# Add first triangle
		st.set_normal(normal)
		st.add_vertex(v0)
		st.add_vertex(v1)
		st.add_vertex(v2)
		
		# Add second triangle
		st.set_normal(normal)
		st.add_vertex(v0)
		st.add_vertex(v2)
		st.add_vertex(v3)
	
	# Create the mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "Cube"
	
	# Add a material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 1, 0.2)  # Green
	mesh_instance.set_surface_override_material(0, material)
	
	return mesh_instance

# Create octahedron (8 faces, 6 vertices, 12 edges)
func create_octahedron():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Define vertices
	var vertices = [
		Vector3(0, 1, 0),   # 0: top
		Vector3(0, -1, 0),  # 1: bottom
		Vector3(1, 0, 0),   # 2: right
		Vector3(-1, 0, 0),  # 3: left
		Vector3(0, 0, 1),   # 4: front
		Vector3(0, 0, -1)   # 5: back
	]
	
	# Define faces (triangles)
	var faces = [
		[0, 4, 2],
		[0, 2, 5],
		[0, 5, 3],
		[0, 3, 4],
		[1, 2, 4],
		[1, 5, 2],
		[1, 3, 5],
		[1, 4, 3]
	]
	
	# Create the mesh
	for face in faces:
		var v0 = vertices[face[0]]
		var v1 = vertices[face[1]]
		var v2 = vertices[face[2]]
		
		# Calculate normal
		var normal = (v1 - v0).cross(v2 - v0).normalized()
		
		# Add vertices with normals
		st.set_normal(normal)
		st.add_vertex(v0)
		st.add_vertex(v1)
		st.add_vertex(v2)
	
	# Create the mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "Octahedron"
	
	# Add a material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.2, 1)  # Blue
	mesh_instance.set_surface_override_material(0, material)
	
	return mesh_instance

# Create dodecahedron (12 faces, 20 vertices, 30 edges)
func create_dodecahedron():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Define vertices
	var vertices = []
	
	# Build vertices using golden ratio
	# Start with a cube
	for x in [-1, 1]:
		for y in [-1, 1]:
			for z in [-1, 1]:
				vertices.append(Vector3(x, y, z))
	
	# Add vertices based on golden ratio
	for i in range(3):
		var axis1 = i
		var axis2 = (i + 1) % 3
		var axis3 = (i + 2) % 3
		
		for j in range(2):
			for k in range(2):
				var v = Vector3.ZERO
				v[axis1] = 0
				v[axis2] = j * 2 - 1
				v[axis3] = (k * 2 - 1) * PHI
				vertices.append(v)
	
	# Normalize all vertices to make them equidistant from origin
	for i in range(vertices.size()):
		vertices[i] = vertices[i].normalized() * 0.5
	
	# Define pentagonal faces
	# This is a complex polyhedron, so we'll define faces programmatically
	var face_indices = []
	
	# Find pentagonal faces by checking all combinations of 5 vertices
	var possible_vertices = range(vertices.size())
	var done_faces = []
	
	# We know there are 12 pentagonal faces in a dodecahedron
	# Rather than generating them algorithmically, we'll define them manually
	# These indices correspond to the vertices we created
	face_indices = [
		[0, 8, 10, 2, 16],
		[0, 16, 18, 1, 9],
		[0, 9, 4, 17, 8],
		[1, 18, 19, 3, 12],
		[1, 12, 13, 5, 9],
		[2, 10, 11, 3, 19],
		[2, 19, 18, 16, 2],
		[3, 11, 14, 7, 12],
		[4, 9, 5, 15, 6],
		[4, 6, 7, 14, 17],
		[5, 13, 6, 15, 5],
		[6, 13, 12, 7, 6]
	]
	
	# Create the mesh
	for face in face_indices:
		# For each pentagonal face, we'll create 3 triangles
		var center = Vector3.ZERO
		for idx in face:
			center += vertices[idx]
		center /= face.size()
		
		# Now create triangles from center to each edge
		for i in range(face.size()):
			var v0 = center
			var v1 = vertices[face[i]]
			var v2 = vertices[face[(i + 1) % face.size()]]
			
			# Calculate normal
			var normal = (v1 - v0).cross(v2 - v0).normalized()
			
			# Add vertices with normals
			st.set_normal(normal)
			st.add_vertex(v0)
			st.add_vertex(v1)
			st.add_vertex(v2)
	
	# Create the mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "Dodecahedron"
	
	# Add a material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 0.2)  # Yellow
	mesh_instance.set_surface_override_material(0, material)
	
	return mesh_instance

# Create icosahedron (20 faces, 12 vertices, 30 edges)
func create_icosahedron():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Define vertices
	var vertices = []
	
	# Using golden ratio to create vertices
	var gr = (1.0 + sqrt(5.0)) / 2.0
	
	# Create the 12 vertices of the icosahedron
	vertices.append(Vector3(0, 1, gr).normalized() * 0.5)
	vertices.append(Vector3(0, -1, gr).normalized() * 0.5)
	vertices.append(Vector3(0, 1, -gr).normalized() * 0.5)
	vertices.append(Vector3(0, -1, -gr).normalized() * 0.5)
	vertices.append(Vector3(1, gr, 0).normalized() * 0.5)
	vertices.append(Vector3(-1, gr, 0).normalized() * 0.5)
	vertices.append(Vector3(1, -gr, 0).normalized() * 0.5)
	vertices.append(Vector3(-1, -gr, 0).normalized() * 0.5)
	vertices.append(Vector3(gr, 0, 1).normalized() * 0.5)
	vertices.append(Vector3(-gr, 0, 1).normalized() * 0.5)
	vertices.append(Vector3(gr, 0, -1).normalized() * 0.5)
	vertices.append(Vector3(-gr, 0, -1).normalized() * 0.5)
	
	# Define the 20 triangular faces
	var faces = [
		[0, 1, 8],
		[0, 4, 5],
		[0, 5, 9],
		[0, 8, 4],
		[0, 9, 1],
		[1, 6, 8],
		[1, 7, 6],
		[1, 9, 7],
		[2, 3, 11],
		[2, 4, 10],
		[2, 5, 4],
		[2, 10, 3],
		[2, 11, 5],
		[3, 6, 7],
		[3, 7, 11],
		[3, 10, 6],
		[4, 8, 10],
		[5, 11, 9],
		[6, 10, 8],
		[7, 9, 11]
	]
	
	# Create the mesh
	for face in faces:
		var v0 = vertices[face[0]]
		var v1 = vertices[face[1]]
		var v2 = vertices[face[2]]
		
		# Calculate normal
		var normal = (v1 - v0).cross(v2 - v0).normalized()
		
		# Add vertices with normals
		st.set_normal(normal)
		st.add_vertex(v0)
		st.add_vertex(v1)
		st.add_vertex(v2)
	
	# Create the mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "Icosahedron"
	
	# Add a material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.2, 1)  # Purple
	mesh_instance.set_surface_override_material(0, material)
	
	return mesh_instance

# Make the shapes interactable if needed for VR
func make_interactable(mesh_instance):
	# Add a rigid body and collision shape if needed for your VR interaction
	var rigid_body = RigidBody3D.new()
	rigid_body.name = mesh_instance.name + "Body"
	
	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.5  # Approximate size of our solids
	collision_shape.shape = shape
	
	# Add mesh instance to rigid body
	rigid_body.add_child(mesh_instance)
	rigid_body.add_child(collision_shape)
	
	return rigid_body

# Helper function to organize solids around a circle
func arrange_in_circle(radius=3.0):
	var num_solids = 5
	var angle_step = 2 * PI / num_solids
	
	for i in range(get_child_count()):
		var child = get_child(i)
		var angle = i * angle_step
		
		child.position = Vector3(
			radius * cos(angle),
			0,
			radius * sin(angle)
		)
