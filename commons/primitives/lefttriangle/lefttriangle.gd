# LeftTriangle.gd - 90 degree right triangle leaning left in pink
extends Node3D

var base_color: Color = Color(1.0, 0.4, 0.8)  # Pink
var triangle_size: float = 1.0

func _ready():
	create_left_triangle()

func create_left_triangle():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertices = create_triangle_vertices()
	var faces = create_triangle_faces()
	
	# Add all triangular faces
	for face in faces:
		add_triangle_with_normal(st, vertices, face)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "LeftTriangle"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)

func create_triangle_vertices() -> Array:
	var vertices = []
	var size = triangle_size
	
	# Create a 90-degree right triangle leaning left
	# The triangle will have its right angle at the origin
	# and lean towards the negative X direction
	vertices.append_array([
		# Front face vertices (Z = 0)
		Vector3(0, 0, 0),           # 0: origin (right angle)
		Vector3(-size, 0, 0),       # 1: left point
		Vector3(0, size, 0),        # 2: top point
		
		# Back face vertices (Z = -0.1 for thin depth)
		Vector3(0, 0, -0.1),        # 3: origin back
		Vector3(-size, 0, -0.1),    # 4: left point back  
		Vector3(0, size, -0.1)      # 5: top point back
	])
	
	return vertices

func create_triangle_faces() -> Array:
	# Create faces for a thin 3D triangle
	var faces = [
		# Front face
		[0, 2, 1],  # Main triangle face (counter-clockwise)
		
		# Back face  
		[3, 4, 5],  # Back triangle face (clockwise from back)
		
		# Side edges (thin rectangular faces)
		# Bottom edge (connecting origins to left points)
		[0, 3, 4],  # Triangle 1
		[0, 4, 1],  # Triangle 2
		
		# Left edge (connecting left points to top points)
		[1, 4, 5],  # Triangle 1
		[1, 5, 2],  # Triangle 2
		
		# Hypotenuse edge (connecting top points to origins)
		[2, 5, 3],  # Triangle 1
		[2, 3, 0]   # Triangle 2
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

func set_triangle_size(size: float):
	triangle_size = size
	# Remove old triangle and create new one
	if get_child_count() > 0:
		get_child(0).queue_free()
	call_deferred("create_left_triangle")