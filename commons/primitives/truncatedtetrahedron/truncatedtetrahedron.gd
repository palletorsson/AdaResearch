# TruncatedTetrahedron.gd - Tetrahedron with cut corners
extends Node3D

var base_color: Color = Color(1.0, 0.5, 0.0)  # Orange from pride colors

func _ready():
	create_truncated_tetrahedron()

func create_truncated_tetrahedron():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Simplified version - create a smaller tetrahedron with cut corners
	var vertices = [
		Vector3(0.2, 0.2, 0.2),
		Vector3(-0.2, -0.2, 0.2),
		Vector3(-0.2, 0.2, -0.2),
		Vector3(0.2, -0.2, -0.2),
		# Cut corners
		Vector3(0.1, 0.1, -0.1),
		Vector3(-0.1, -0.1, -0.1),
		Vector3(-0.1, 0.1, 0.1),
		Vector3(0.1, -0.1, 0.1)
	]
	
	var faces = [
		[0, 4, 6], [1, 5, 7], [2, 6, 4], [3, 7, 5],
		[4, 5, 6, 7], [0, 1, 2, 3]
	]
	
	for face in faces:
		if face.size() == 3:
			add_triangle_with_normal(st, vertices, face)
		else:
			add_triangle_with_normal(st, vertices, [face[0], face[1], face[2]])
			add_triangle_with_normal(st, vertices, [face[0], face[2], face[3]])
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "TruncatedTetrahedron"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)

# Helper function to add triangle with calculated normal
func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]  
	var v2 = vertices[face[2]]
	
	var face_center = (v0 + v1 + v2) / 3.0
	var normal = face_center.normalized()
	
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
