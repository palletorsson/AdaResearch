# Icosahedron.gd - Regular icosahedron (20 triangular faces)
extends Node3D

const PHI = 1.618033988749895  # Golden ratio
var base_color: Color = Color(0.2, 1.0, 0.6)  # Turquoise

func _ready():
	create_icosahedron()

func create_icosahedron():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertices = create_icosahedron_vertices()
	var faces = create_icosahedron_faces()
	
	# Add all triangular faces
	for face in faces:
		add_triangle_with_normal(st, vertices, face)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "Icosahedron"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)

func create_icosahedron_vertices() -> Array:
	var vertices = []
	var scale = 0.4
	
	# 12 vertices of regular icosahedron using golden ratio
	# Three orthogonal golden rectangles
	vertices.append_array([
		# Rectangle in XY plane
		Vector3(-1, PHI, 0), Vector3(1, PHI, 0),
		Vector3(-1, -PHI, 0), Vector3(1, -PHI, 0),
		
		# Rectangle in YZ plane  
		Vector3(0, -1, PHI), Vector3(0, 1, PHI),
		Vector3(0, -1, -PHI), Vector3(0, 1, -PHI),
		
		# Rectangle in XZ plane
		Vector3(PHI, 0, -1), Vector3(PHI, 0, 1),
		Vector3(-PHI, 0, -1), Vector3(-PHI, 0, 1)
	])
	
	# Scale all vertices
	for i in range(vertices.size()):
		vertices[i] = vertices[i].normalized() * scale
	
	return vertices

func create_icosahedron_faces() -> Array:
	# 20 triangular faces of icosahedron
	var faces = [
		# Top cap (5 faces around vertex 0)
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		
		# Upper belt (5 faces)
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		
		# Lower belt (5 faces)  
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		
		# Bottom cap (5 faces around vertex 3)
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]
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
