# RightTriangle.gd - 90 degree right triangle leaning right in black
extends Node3D
class_name RightTriangle

# @identity
# essence: right_triangle(base, height) with 90° angle at origin — the geometric primitive of Pythagoras
# desire: learner has a reference form for right angles to which other geometry is compared
# critical_parameter: the right angle at the origin — this defines the shape; moving it makes it non-right
# triggers: nothing — static reference object; thin (0.05 depth) for readability as a 2D form in 3D space
# emerges: the usefulness of black — a neutral diagnostic color that does not compete with adjacent color coding
# needs: [missing VR controls — static display only]
# relationships: used in Trans_RotationSpectacle map; sibling to pythagorean_triangle_angles
# truth: the right angle is the basis of all rectangular coordinate systems — it defines what "perpendicular" means

var base_color: Color = Color(0.1, 0.1, 0.1)  # Black
var triangle_size: float = 1.0

func _ready():
	create_right_triangle()

func create_right_triangle():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertices = create_triangle_vertices()
	var faces = create_triangle_faces()
	
	# Add all triangular faces
	for face in faces:
		add_triangle_with_normal(st, vertices, face)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "RightTriangle"
	apply_queer_material(mesh_instance, base_color)
	add_child(mesh_instance)

func create_triangle_vertices() -> Array:
	var vertices = []
	var size = triangle_size
	
	# Create a 90-degree right triangle leaning right
	# The triangle will have its right angle at the origin
	# and lean towards the positive X direction
	vertices.append_array([
		# Front face vertices (Z = 0)
		Vector3(0, 0, 0),           # 0: origin (right angle)
		Vector3(size, 0, 0),        # 1: right point
		Vector3(0, size, 0),        # 2: top point
		
		# Back face vertices (Z = -0.1 for thin depth)
		Vector3(0, 0, -0.1),        # 3: origin back
		Vector3(size, 0, -0.1),     # 4: right point back  
		Vector3(0, size, -0.1)      # 5: top point back
	])
	
	return vertices

func create_triangle_faces() -> Array:
	# Create faces for a thin 3D triangle
	var faces = [
		# Front face
		[0, 1, 2],  # Main triangle face (counter-clockwise)
		
		# Back face  
		[3, 5, 4],  # Back triangle face (clockwise from back)
		
		# Side edges (thin rectangular faces)
		# Bottom edge (connecting origins to right points)
		[0, 4, 3],  # Triangle 1
		[0, 1, 4],  # Triangle 2
		
		# Right edge (connecting right points to top points)
		[1, 5, 4],  # Triangle 1
		[1, 2, 5],  # Triangle 2
		
		# Hypotenuse edge (connecting top points to origins)
		[2, 3, 5],  # Triangle 1
		[2, 0, 3]   # Triangle 2
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
	call_deferred("create_right_triangle")
