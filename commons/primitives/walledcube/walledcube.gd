# WalledCube.gd - Cube with walls on four sides (open top and bottom)
extends Node3D

var base_color: Color = Color(0.8, 0.3, 0.9)  # Purple
var cube_size: float = 1.0

func _ready():
	create_walled_cube()

func create_walled_cube():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertices = create_cube_vertices()
	var faces = create_wall_faces()
	
	# Add all wall faces (no top or bottom)
	for face in faces:
		add_triangle_with_normal(st, vertices, face)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "WalledCube"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)

func create_cube_vertices() -> Array:
	var vertices = []
	var half_size = cube_size * 0.5
	
	# 8 vertices of a cube
	vertices.append_array([
		# Bottom vertices (Y = -half_size)
		Vector3(-half_size, -half_size, -half_size),  # 0: bottom back-left
		Vector3(half_size, -half_size, -half_size),   # 1: bottom back-right
		Vector3(half_size, -half_size, half_size),    # 2: bottom front-right
		Vector3(-half_size, -half_size, half_size),   # 3: bottom front-left
		
		# Top vertices (Y = half_size)
		Vector3(-half_size, half_size, -half_size),   # 4: top back-left
		Vector3(half_size, half_size, -half_size),    # 5: top back-right
		Vector3(half_size, half_size, half_size),     # 6: top front-right
		Vector3(-half_size, half_size, half_size)     # 7: top front-left
	])
	
	return vertices

func create_wall_faces() -> Array:
	# Only create 4 wall faces (no top or bottom)
	var faces = [
		# Front wall (Z = half_size)
		[3, 6, 2],  # Triangle 1
		[3, 7, 6],  # Triangle 2
		
		# Back wall (Z = -half_size)
		[1, 5, 4],  # Triangle 1
		[1, 4, 0],  # Triangle 2
		
		# Left wall (X = -half_size)
		[0, 7, 3],  # Triangle 1
		[0, 4, 7],  # Triangle 2
		
		# Right wall (X = half_size)
		[2, 5, 1],  # Triangle 1
		[2, 6, 5]   # Triangle 2
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
	# Create shader material using the SimpleGrid shader
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

func set_cube_size(size: float):
	cube_size = size
	# Remove old cube and create new one
	if get_child_count() > 0:
		get_child(0).queue_free()
	call_deferred("create_walled_cube")