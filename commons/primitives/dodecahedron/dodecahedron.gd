# Dodecahedron.gd - Fixed Regular dodecahedron (12 pentagonal faces)
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
	
	# Convert pentagonal faces to triangles using fan triangulation
	for face in faces:
		# Fan triangulation from center vertex (more uniform triangles)
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
	
	# Correct dodecahedron vertices using golden ratio
	var a = 1.0 / PHI  # 1/φ ≈ 0.618
	var b = PHI        # φ ≈ 1.618
	
	# 20 vertices of regular dodecahedron
	# Group 1: (±1, ±1, ±1) - cube vertices
	vertices.append_array([
		Vector3(1, 1, 1),      # 0
		Vector3(1, 1, -1),     # 1
		Vector3(1, -1, 1),     # 2
		Vector3(-1, 1, 1),     # 3
		Vector3(-1, -1, 1),    # 4
		Vector3(-1, 1, -1),    # 5
		Vector3(1, -1, -1),    # 6
		Vector3(-1, -1, -1),   # 7
	])
	
	# Group 2: (0, ±1/φ, ±φ) - rectangles in YZ plane
	vertices.append_array([
		Vector3(0, a, b),      # 8
		Vector3(0, -a, b),     # 9
		Vector3(0, a, -b),     # 10
		Vector3(0, -a, -b),    # 11
	])
	
	# Group 3: (±1/φ, ±φ, 0) - rectangles in XZ plane  
	vertices.append_array([
		Vector3(a, b, 0),      # 12
		Vector3(-a, b, 0),     # 13
		Vector3(a, -b, 0),     # 14
		Vector3(-a, -b, 0),    # 15
	])
	
	# Group 4: (±φ, 0, ±1/φ) - rectangles in XY plane
	vertices.append_array([
		Vector3(b, 0, a),      # 16
		Vector3(-b, 0, a),     # 17
		Vector3(b, 0, -a),     # 18
		Vector3(-b, 0, -a),    # 19
	])
	
	# Scale and normalize all vertices to lie on unit sphere
	for i in range(vertices.size()):
		vertices[i] = vertices[i].normalized() * scale
	
	return vertices

func create_dodecahedron_faces() -> Array:
	# 12 pentagonal faces of dodecahedron
	# Each pentagon connects 5 vertices in counter-clockwise order when viewed from outside
	var faces = [
		# Pentagon faces - corrected connectivity
		[8, 9, 4, 17, 3],      # Face 1: front pentagon
		[10, 5, 19, 18, 1],    # Face 2: back pentagon
		[12, 0, 16, 2, 14],    # Face 3: right pentagon
		[13, 15, 4, 3, 0],     # Face 4: top-left pentagon
		[8, 3, 17, 19, 5],     # Face 5: left pentagon
		[9, 8, 0, 12, 2],      # Face 6: front-right pentagon
		[16, 18, 6, 14, 2],    # Face 7: bottom-right pentagon
		[17, 4, 15, 7, 19],    # Face 8: bottom-left pentagon
		[10, 1, 0, 3, 5],      # Face 9: top pentagon
		[11, 7, 15, 13, 12],   # Face 10: bottom pentagon
		[6, 18, 1, 10, 11],    # Face 11: back-right pentagon
		[7, 11, 6, 14, 4]      # Face 12: bottom pentagon
	]
	
	# Corrected faces based on proper dodecahedron geometry
	faces = [
		[3, 17, 4, 9, 8],      # Face 1
		[0, 12, 13, 3, 8],     # Face 2  
		[0, 8, 9, 2, 16],      # Face 3
		[0, 16, 18, 1, 12],    # Face 4
		[1, 18, 6, 14, 12],    # Face 5
		[2, 9, 4, 15, 14],     # Face 6
		[2, 14, 6, 18, 16],    # Face 7
		[3, 13, 5, 19, 17],    # Face 8
		[4, 17, 19, 7, 15],    # Face 9
		[5, 13, 12, 1, 10],    # Face 10
		[5, 10, 11, 7, 19],    # Face 11
		[6, 11, 10, 1, 18]     # Face 12 - corrected
	]
	
	return faces

# Helper function to add triangle with calculated normal
func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]  
	var v2 = vertices[face[2]]
	
	# Calculate face normal pointing outward
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()
	
	# Ensure normal points outward (away from center)
	var center_to_face = v0.normalized()  # Since vertices are on unit sphere
	if normal.dot(center_to_face) < 0:
		normal = -normal
	
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
		material.set_shader_parameter("edge_color", Color.CYAN)
		material.set_shader_parameter("edge_width", 1.0)
		material.set_shader_parameter("edge_sharpness", 2.0)
		material.set_shader_parameter("emission_strength", 0.8)
		
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
