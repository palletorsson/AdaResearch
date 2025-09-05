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
	var scale = 0.3
	
	# Create vertices using golden ratio relationships
	var a = 1.0
	var b = 1.0 / PHI  # 1/φ
	var c = 2.0 - PHI  # 2-φ
	
	# 20 vertices of regular dodecahedron
	vertices.append_array([
		# Cube vertices
		Vector3(a, a, a), Vector3(a, a, -a), Vector3(a, -a, a), Vector3(a, -a, -a),
		Vector3(-a, a, a), Vector3(-a, a, -a), Vector3(-a, -a, a), Vector3(-a, -a, -a),
		
		# Face centers of cube scaled by golden ratio
		Vector3(0, b, PHI), Vector3(0, -b, PHI), Vector3(0, b, -PHI), Vector3(0, -b, -PHI),
		Vector3(b, PHI, 0), Vector3(-b, PHI, 0), Vector3(b, -PHI, 0), Vector3(-b, -PHI, 0),
		Vector3(PHI, 0, b), Vector3(-PHI, 0, b), Vector3(PHI, 0, -b), Vector3(-PHI, 0, -b)
	])
	
	# Scale all vertices
	for i in range(vertices.size()):
		vertices[i] *= scale
	
	return vertices

func create_dodecahedron_faces() -> Array:
	# 12 pentagonal faces of dodecahedron
	var faces = [
		[0, 16, 2, 9, 8],      # Face 1
		[0, 8, 4, 13, 12],     # Face 2  
		[0, 12, 1, 18, 16],    # Face 3
		[1, 10, 3, 14, 18],    # Face 4
		[1, 12, 13, 5, 10],    # Face 5
		[2, 14, 3, 11, 9],     # Face 6
		[3, 10, 5, 19, 11],    # Face 7
		[4, 8, 9, 11, 17],     # Face 8
		[4, 17, 6, 15, 13],    # Face 9
		[5, 13, 15, 7, 19],    # Face 10
		[6, 17, 19, 7, 15],    # Face 11
		[6, 15, 14, 2, 16]     # Face 12 (corrected)
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
