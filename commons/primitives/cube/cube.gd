# Cube.gd - Regular cube/hexahedron (6 square faces)
extends Node3D

var base_color: Color = Color(0.0, 1.0, 1.0)  # Cyan

func _ready():
	create_cube()

func create_cube():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var size = 0.5
	var vertices = [
		# Front face
		Vector3(-size, -size, size),   # 0
		Vector3(size, -size, size),    # 1
		Vector3(size, size, size),     # 2
		Vector3(-size, size, size),    # 3
		# Back face
		Vector3(-size, -size, -size),  # 4
		Vector3(size, -size, -size),   # 5
		Vector3(size, size, -size),    # 6
		Vector3(-size, size, -size)    # 7
	]
	
	# 6 faces (each split into 2 triangles)
	var faces = [
		# Front face
		[0, 1, 2], [0, 2, 3],
		# Back face  
		[5, 4, 7], [5, 7, 6],
		# Left face
		[4, 0, 3], [4, 3, 7],
		# Right face
		[1, 5, 6], [1, 6, 2],
		# Top face
		[3, 2, 6], [3, 6, 7],
		# Bottom face
		[4, 5, 1], [4, 1, 0]
	]
	
	for face in faces:
		add_triangle_with_normal(st, vertices, face)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "Cube"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)

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
	var shader = load("res://commons/resourses/shaders/grid_solid.gdshaderr")
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
