# Dodecahedron.gd - Regular dodecahedron (12 pentagonal faces)
extends Node3D

const PHI = 1.618033988749895  # Golden ratio
var base_color: Color = Color(1.0, 0.8, 0.2)  # Golden yellow

func _ready():
	create_dodecahedron()

func create_dodecahedron():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertices = create_dodecahedron_vertices()
	var faces = create_dodecahedron_faces()
	
	# Convert pentagonal faces to triangles
	for face in faces:
		# Fan triangulation from first vertex
		for i in range(1, face.size() - 1):
			add_triangle_with_normal(st, vertices, [face[0], face[i], face[i + 1]])
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "Dodecahedron"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)

func create_dodecahedron_vertices() -> Array:
	var vertices = []
	var scale = 0.4
	
	# Create vertices using the proper dodecahedron construction
	# Based on the golden ratio relationships
	var a = 1.0
	var b = 1.0 / PHI  # 1/φ ≈ 0.618
	
	# 20 vertices of regular dodecahedron
	# First set: cube vertices (±1, ±1, ±1)
	vertices.append_array([
		Vector3(a, a, a),     # 0
		Vector3(a, a, -a),    # 1
		Vector3(a, -a, a),    # 2
		Vector3(a, -a, -a),   # 3
		Vector3(-a, a, a),    # 4
		Vector3(-a, a, -a),   # 5
		Vector3(-a, -a, a),   # 6
		Vector3(-a, -a, -a),  # 7
	])
	
	# Second set: rectangles in YZ plane (0, ±1/φ, ±φ)
	vertices.append_array([
		Vector3(0, b, PHI),   # 8
		Vector3(0, -b, PHI),  # 9
		Vector3(0, b, -PHI),  # 10
		Vector3(0, -b, -PHI), # 11
	])
	
	# Third set: rectangles in XZ plane (±1/φ, ±φ, 0)
	vertices.append_array([
		Vector3(b, PHI, 0),   # 12
		Vector3(-b, PHI, 0),  # 13
		Vector3(b, -PHI, 0),  # 14
		Vector3(-b, -PHI, 0), # 15
	])
	
	# Fourth set: rectangles in XY plane (±φ, 0, ±1/φ)
	vertices.append_array([
		Vector3(PHI, 0, b),   # 16
		Vector3(-PHI, 0, b),  # 17
		Vector3(PHI, 0, -b),  # 18
		Vector3(-PHI, 0, -b), # 19
	])
	
	# Scale and normalize all vertices
	for i in range(vertices.size()):
		vertices[i] = vertices[i].normalized() * scale
	
	return vertices

func create_dodecahedron_faces() -> Array:
	# 12 pentagonal faces of dodecahedron
	# Each face connects 5 vertices in the correct order
	var faces = [
		# Face 1: around vertex 0
		[0, 16, 2, 9, 8],
		# Face 2: around vertex 1  
		[1, 10, 5, 13, 12],
		# Face 3: around vertex 2
		[2, 14, 6, 17, 9],
		# Face 4: around vertex 3
		[3, 11, 7, 15, 14],
		# Face 5: around vertex 4
		[4, 8, 9, 17, 13],
		# Face 6: around vertex 5
		[5, 19, 18, 12, 10],
		# Face 7: around vertex 6
		[6, 15, 7, 19, 17],
		# Face 8: around vertex 7
		[7, 11, 10, 18, 19],
		# Face 9: top cap
		[0, 8, 4, 13, 12, 1, 18, 16],  # This should be split
		# Face 10: bottom cap  
		[3, 14, 2, 16, 18, 1, 12, 0],  # This should be split
		# Face 11
		[6, 9, 2, 14, 15],
		# Face 12
		[5, 10, 11, 3, 18]
	]
	
	# Let's use the correct dodecahedron face definition
	# Based on proper geometric construction
	faces = [
		[0, 16, 2, 9, 8],      # Pentagon 1
		[0, 8, 4, 13, 12],     # Pentagon 2
		[0, 12, 1, 18, 16],    # Pentagon 3
		[1, 10, 5, 13, 12],    # Pentagon 4
		[2, 14, 6, 9, 16],     # Pentagon 5 - corrected
		[3, 11, 7, 15, 14],    # Pentagon 6
		[4, 8, 9, 6, 17],      # Pentagon 7 - corrected
		[4, 17, 19, 5, 13],    # Pentagon 8 - corrected
		[5, 19, 18, 1, 10],    # Pentagon 9 - corrected
		[6, 14, 15, 7, 17],    # Pentagon 10 - corrected
		[7, 11, 10, 19, 17],   # Pentagon 11 - corrected
		[11, 3, 14, 2, 16, 18] # Pentagon 12 - this needs fixing
	]
	
	# Simplified correct faces for regular dodecahedron
	faces = [
		[0, 8, 9, 2, 16],      # Face 1
		[0, 16, 18, 1, 12],    # Face 2
		[0, 12, 13, 4, 8],     # Face 3
		[1, 18, 19, 5, 10],    # Face 4
		[1, 10, 11, 3, 12],    # Face 5 - corrected
		[2, 9, 6, 14, 16],     # Face 6 - corrected
		[3, 14, 15, 7, 11],    # Face 7
		[4, 13, 5, 17, 8],     # Face 8 - corrected
		[5, 19, 7, 15, 17],    # Face 9 - corrected
		[6, 9, 8, 17, 15],     # Face 10 - corrected
		[6, 15, 14, 3, 11],    # Face 11 - corrected
		[7, 19, 18, 16, 14]    # Face 12 - corrected
	]
	
	return faces

# Helper function to add triangle with calculated normal
func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]  
	var v2 = vertices[face[2]]
	
	# Calculate face normal
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()
	
	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v1)
	st.set_normal(normal)
	st.add_vertex(v2)

func apply_queer_material(mesh_instance: MeshInstance3D, color: Color):
	# Create shader material using the solid wireframe shader
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		
		# Set shader parameters
		material.set_shader_parameter("base_color", color)
		material.set_shader_parameter("edge_color", Color.WHITE)
		material.set_shader_parameter("edge_width", 1.5)
		material.set_shader_parameter("edge_sharpness", 2.0)
		material.set_shader_parameter("emission_strength", 1.0)
		
		mesh_instance.material_override = material
	else:
		# Fallback to standard material if shader not found
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.emission_enabled = true
		standard_material.emission = color * 0.3
		mesh_instance.material_override = standard_material

func set_base_color(color: Color):
	base_color = color
	var mesh_instance = get_child(0) as MeshInstance3D
	if mesh_instance:
		apply_queer_material(mesh_instance, base_color)
