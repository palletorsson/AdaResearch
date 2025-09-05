# PyramidLong.gd - Long pyramid with rectangular base (6 faces total)
extends Node3D

var base_color: Color = Color(1.0, 0.4, 0.8)  # Pink color
var pyramid_height: float = 2.8  # Keep the height you set
var base_width: float = 0.8      # Width (X axis)
var base_length: float = 0.8     # Length (Z axis) - square base

func _ready():
	create_pyramid()

func create_pyramid():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertices = create_pyramid_vertices()
	var faces = create_pyramid_faces()
	
	# Add all triangular faces
	for face in faces:
		add_triangle_with_normal(st, vertices, face)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "PyramidLong"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)

func create_pyramid_vertices() -> Array:
	var vertices = []
	var half_width = base_width * 0.5
	var half_length = base_length * 0.5
	
	# 5 vertices: 4 base corners + 1 apex
	vertices.append_array([
		# Base vertices (square on XZ plane, Y=0)
		Vector3(-half_width, 0, -half_length),  # 0: back-left
		Vector3(half_width, 0, -half_length),   # 1: back-right
		Vector3(half_width, 0, half_length),    # 2: front-right
		Vector3(-half_width, 0, half_length),   # 3: front-left
		
		# Apex vertex
		Vector3(0, pyramid_height, 0)           # 4: top point
	])
	
	return vertices

func create_pyramid_faces() -> Array:
	# 6 triangular faces (2 for square base + 4 triangular sides)
	var faces = [
		# Base (split square into 2 triangles)
		[0, 2, 1],  # Triangle 1 of base (counter-clockwise from below)
		[0, 3, 2],  # Triangle 2 of base
		
		# Side faces (4 triangular faces)
		[0, 1, 4],  # Back face
		[1, 2, 4],  # Right face  
		[2, 3, 4],  # Front face
		[3, 0, 4]   # Left face
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
		
		# Set shader parameters to match the shader uniforms
		material.set_shader_parameter("fill_color", color)
		material.set_shader_parameter("wireframe_color", Color.HOT_PINK)
		material.set_shader_parameter("wireframe_width", 3.0)
		material.set_shader_parameter("wireframe_brightness", 2.0)
		
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

func set_pyramid_size(height: float, width: float, length: float):
	pyramid_height = height
	base_width = width
	base_length = length
	# Remove old pyramid and create new one
	if get_child_count() > 0:
		get_child(0).queue_free()
	call_deferred("create_pyramid")
