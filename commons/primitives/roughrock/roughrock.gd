# RoughRock.gd - Irregular polyhedron with rough surface
extends Node3D

var base_color: Color = Color(0.0, 0.8, 0.0)  # Green from pride colors

func _ready():
	create_rough_rock()

func create_rough_rock():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create irregular vertices with noise
	var vertices = []
	var base_points = [
		Vector3(0.3, 0.2, 0.1),
		Vector3(-0.2, 0.3, 0.15),
		Vector3(-0.25, -0.1, 0.25),
		Vector3(0.1, -0.3, 0.2),
		Vector3(0.25, -0.1, -0.2),
		Vector3(-0.1, 0.2, -0.3),
		Vector3(0.15, 0.35, -0.1),
		Vector3(-0.3, -0.2, -0.1)
	]
	
	# Add roughness to points using deterministic "randomness" for consistency
	for i in range(base_points.size()):
		var point = base_points[i]
		# Use a simple hash function for deterministic variation
		var seed_val = i * 12345 + int(point.x * 1000) + int(point.y * 1000) + int(point.z * 1000)
		var rng = RandomNumberGenerator.new()
		rng.seed = seed_val
		
		var rough_point = point + Vector3(
			rng.randf_range(-0.05, 0.05),
			rng.randf_range(-0.05, 0.05), 
			rng.randf_range(-0.05, 0.05)
		)
		vertices.append(rough_point)
	
	# Create faces connecting points (simplified convex hull approach)
	var faces = [
		[0, 1, 6], [1, 2, 3], [3, 4, 0], [4, 5, 6],
		[6, 1, 2], [2, 7, 3], [3, 7, 4], [4, 7, 5],
		[5, 7, 2], [2, 1, 5], [5, 1, 6], [6, 0, 4]
	]
	
	for face in faces:
		add_triangle_with_normal(st, vertices, face)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "RoughRock"
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
