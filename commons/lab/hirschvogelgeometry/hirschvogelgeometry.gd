extends Node3D
class_name HirschvogelGeometry

# Hirschvogel Geometric Construction Generator
# Based on Augustin Hirschvogel's 1543 "Geometria"

@export var paper_color: Color = Color(0.95, 0.92, 0.85, 1)
@export var ink_color: Color = Color(0.2, 0.15, 0.1, 1)
@export var construction_scale: float = 1.0

var paper_material: StandardMaterial3D
var ink_material: StandardMaterial3D
var triangle_materials: Array[StandardMaterial3D] = []

func _ready():
	setup_materials()
	create_paper_background()
	generate_geometric_constructions()
	setup_lighting()

func setup_materials():
	# Paper material
	paper_material = StandardMaterial3D.new()
	paper_material.albedo_color = paper_color
	paper_material.roughness = 0.8
	paper_material.normal_scale = 0.3
	
	# Ink material for lines
	ink_material = StandardMaterial3D.new()
	ink_material.albedo_color = ink_color
	ink_material.roughness = 0.9
	ink_material.metallic = 0.1
	
	# Triangle fill materials
	var colors = [
		Color(0.8, 0.75, 0.6, 1),
		Color(0.6, 0.55, 0.45, 1),
		Color(0.7, 0.65, 0.5, 1),
		Color(0.75, 0.7, 0.55, 1)
	]
	
	for color in colors:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.7
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		triangle_materials.append(mat)

func create_paper_background():
	var background = StaticBody3D.new()
	background.name = "PaperBackground"
	add_child(background)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "BackgroundPlane"
	mesh_instance.transform = Transform3D.IDENTITY
	mesh_instance.transform.basis = mesh_instance.transform.basis.rotated(Vector3.RIGHT, -PI/2)
	mesh_instance.position.y = -0.01
	
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(6, 4) * construction_scale
	mesh_instance.mesh = quad_mesh
	mesh_instance.material_override = paper_material
	
	background.add_child(mesh_instance)

func generate_geometric_constructions():
	var constructions = Node3D.new()
	constructions.name = "GeometricConstructions"
	add_child(constructions)
	
	# I. Top Left - Circle with inscribed octahedron
	create_circle_with_octahedron(constructions, Vector3(-1.5, 1, 0) * construction_scale)
	
	# II. Top Right - Pyramid
	create_pyramid(constructions, Vector3(0.5, 1, 0) * construction_scale)
	
	# III. Bottom Left - Second circle with octahedron
	create_second_circle_octahedron(constructions, Vector3(-1.5, -0.5, 0) * construction_scale)
	
	# IV. Central/Right - Triangular net
	create_triangular_net(constructions, Vector3(0.8, -0.8, 0) * construction_scale)
	
	# Add labels
	create_labels(constructions)

func create_circle_with_octahedron(parent: Node3D, pos: Vector3):
	var group = StaticBody3D.new()
	group.name = "TopLeftCircle"
	group.position = pos
	parent.add_child(group)
	
	# Circle outline
	var circle_mesh = create_circle_outline(0.5 * construction_scale, 64)
	var circle_node = MeshInstance3D.new()
	circle_node.name = "CircleOutline"
	circle_node.mesh = circle_mesh
	circle_node.material_override = ink_material
	group.add_child(circle_node)
	
	# Inscribed octahedron
	var octa_mesh = create_inscribed_octahedron(0.5 * construction_scale)
	var octa_node = MeshInstance3D.new()
	octa_node.name = "InscribedOctahedron"
	octa_node.mesh = octa_mesh
	octa_node.material_override = ink_material
	group.add_child(octa_node)

func create_pyramid(parent: Node3D, pos: Vector3):
	var group = StaticBody3D.new()
	group.name = "TopRightPyramid"
	group.position = pos
	parent.add_child(group)
	
	var base_size = 0.4 * construction_scale
	var height = 0.5 * construction_scale
	
	# Solid pyramid
	var pyramid_mesh = create_pyramid_solid(base_size, height)
	var pyramid_node = MeshInstance3D.new()
	pyramid_node.name = "PyramidSolid"
	pyramid_node.mesh = pyramid_mesh
	pyramid_node.material_override = triangle_materials[0]
	group.add_child(pyramid_node)
	
	# Outline
	var outline_mesh = create_pyramid_outline(base_size, height)
	var outline_node = MeshInstance3D.new()
	outline_node.name = "PyramidOutline"
	outline_node.mesh = outline_mesh
	outline_node.material_override = ink_material
	outline_node.position.z = 0.001
	group.add_child(outline_node)

func create_second_circle_octahedron(parent: Node3D, pos: Vector3):
	var group = StaticBody3D.new()
	group.name = "BottomLeftCircleOcta"
	group.position = pos
	parent.add_child(group)
	
	# Circle
	var circle_mesh = create_circle_outline(0.5 * construction_scale, 64)
	var circle_node = MeshInstance3D.new()
	circle_node.name = "CircleOutline2"
	circle_node.mesh = circle_mesh
	circle_node.material_override = ink_material
	group.add_child(circle_node)
	
	# Internal octahedron with horizontal division
	var octa_mesh = create_divided_octahedron(0.5 * construction_scale)
	var octa_node = MeshInstance3D.new()
	octa_node.name = "OctahedronInside"
	octa_node.mesh = octa_mesh
	octa_node.material_override = ink_material
	group.add_child(octa_node)

func create_triangular_net(parent: Node3D, pos: Vector3):
	var group = StaticBody3D.new()
	group.name = "CentralNet"
	group.position = pos
	parent.add_child(group)
	
	var triangle_net = Node3D.new()
	triangle_net.name = "TriangleNet"
	group.add_child(triangle_net)
	
	var triangle_size = 0.35 * construction_scale
	var height = triangle_size * sqrt(3) / 2
	
	# Triangle positions matching the original diagram
	var positions = [
		Vector3(0, 0.6, 0) * construction_scale,           # Top
		Vector3(-0.433, 0.25, 0) * construction_scale,     # Upper left
		Vector3(0.433, 0.25, 0) * construction_scale,      # Upper right
		Vector3(-0.866, -0.5, 0) * construction_scale,     # Lower left
		Vector3(0, -0.5, 0) * construction_scale,          # Lower center
		Vector3(0.866, -0.5, 0) * construction_scale,      # Lower right
		Vector3(-0.433, -1.25, 0) * construction_scale,    # Bottom left
		Vector3(0.433, -1.25, 0) * construction_scale      # Bottom right
	]
	
	for i in range(positions.size()):
		var triangle = MeshInstance3D.new()
		triangle.name = "Triangle" + str(i + 1)
		triangle.position = positions[i]
		triangle.mesh = create_triangle_mesh(triangle_size)
		triangle.material_override = triangle_materials[i % triangle_materials.size()]
		triangle_net.add_child(triangle)
		
		# Add outline
		var outline = MeshInstance3D.new()
		outline.name = "TriangleOutline" + str(i + 1)
		outline.position = positions[i] + Vector3(0, 0, 0.001)
		outline.mesh = create_triangle_outline(triangle_size)
		outline.material_override = ink_material
		triangle_net.add_child(outline)

func create_labels(parent: Node3D):
	var labels = Node3D.new()
	labels.name = "Labels"
	parent.add_child(labels)
	
	var label_data = [
		["I", Vector3(-1.5, 1.5, 0.01) * construction_scale],
		["II", Vector3(0.5, 1.5, 0.01) * construction_scale],
		["III", Vector3(-1.5, 0, 0.01) * construction_scale],
		["IV", Vector3(0.8, 0.5, 0.01) * construction_scale]
	]
	
	for data in label_data:
		var label = Label3D.new()
		label.text = data[0]
		label.position = data[1]
		label.font_size = int(32 * construction_scale)
		label.modulate = ink_color
		labels.add_child(label)

# Mesh creation functions
func create_circle_outline(radius: float, segments: int) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	for i in range(segments):
		var angle = i * 2.0 * PI / segments
		vertices.append(Vector3(cos(angle) * radius, sin(angle) * radius, 0))
	
	for i in range(segments):
		indices.append(i)
		indices.append((i + 1) % segments)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh

func create_inscribed_octahedron(radius: float) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var r = radius * 0.707  # sqrt(2)/2
	vertices.append(Vector3(r, 0, 0))      # Right
	vertices.append(Vector3(0, r, 0))      # Top
	vertices.append(Vector3(-r, 0, 0))     # Left
	vertices.append(Vector3(0, -r, 0))     # Bottom
	vertices.append(Vector3(0, 0, 0))      # Center
	
	var connections = [
		[0, 1], [1, 2], [2, 3], [3, 0],  # Outer diamond
		[4, 0], [4, 1], [4, 2], [4, 3]   # Center lines
	]
	
	for connection in connections:
		indices.append(connection[0])
		indices.append(connection[1])
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh

func create_divided_octahedron(radius: float) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var r = radius * 0.707
	vertices.append(Vector3(r, 0, 0))       # Right
	vertices.append(Vector3(0, r, 0))       # Top
	vertices.append(Vector3(-r, 0, 0))      # Left
	vertices.append(Vector3(0, -r, 0))      # Bottom
	vertices.append(Vector3(-r*0.8, 0, 0))  # Left horizontal
	vertices.append(Vector3(r*0.8, 0, 0))   # Right horizontal
	
	var connections = [
		[0, 1], [1, 2], [2, 3], [3, 0],  # Diamond
		[4, 5]  # Horizontal divider
	]
	
	for connection in connections:
		indices.append(connection[0])
		indices.append(connection[1])
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh

func create_pyramid_solid(base_size: float, height: float) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Base triangle + apex
	vertices.append(Vector3(-base_size, -base_size/2, 0))
	vertices.append(Vector3(base_size, -base_size/2, 0))
	vertices.append(Vector3(0, base_size, 0))
	vertices.append(Vector3(0, 0, height))
	
	for i in range(4):
		normals.append(Vector3(0, 0, 1))
	
	# Faces
	indices.append_array([2, 1, 0])  # Base
	indices.append_array([0, 1, 3])  # Side 1
	indices.append_array([1, 2, 3])  # Side 2
	indices.append_array([2, 0, 3])  # Side 3
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_pyramid_outline(base_size: float, height: float) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	vertices.append(Vector3(-base_size, -base_size/2, 0))
	vertices.append(Vector3(base_size, -base_size/2, 0))
	vertices.append(Vector3(0, base_size, 0))
	vertices.append(Vector3(0, 0, height))
	
	var edges = [
		[0, 1], [1, 2], [2, 0],  # Base
		[0, 3], [1, 3], [2, 3]   # To apex
	]
	
	for edge in edges:
		indices.append(edge[0])
		indices.append(edge[1])
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh

func create_triangle_mesh(size: float) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var height = size * sqrt(3) / 2
	
	vertices.append(Vector3(0, height * 2/3, 0))
	vertices.append(Vector3(-size/2, -height/3, 0))
	vertices.append(Vector3(size/2, -height/3, 0))
	
	for i in range(3):
		normals.append(Vector3(0, 0, 1))
	
	indices.append_array([0, 2, 1])
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_triangle_outline(size: float) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var height = size * sqrt(3) / 2
	
	vertices.append(Vector3(0, height * 2/3, 0))
	vertices.append(Vector3(-size/2, -height/3, 0))
	vertices.append(Vector3(size/2, -height/3, 0))
	
	indices.append_array([0, 1, 1, 2, 2, 0])
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh

func setup_lighting():
	var lighting = Node3D.new()
	lighting.name = "Lighting"
	add_child(lighting)
	
	var main_light = DirectionalLight3D.new()
	main_light.name = "MainLight"
	main_light.transform.origin = Vector3(0, 4, 4) * construction_scale
	main_light.transform = main_light.transform.looking_at(Vector3.ZERO, Vector3.UP)
	main_light.light_energy = 1.2
	main_light.light_color = Color(1, 0.95, 0.85, 1)
	main_light.shadow_enabled = true
	lighting.add_child(main_light)
	
	# Environment
	var world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = paper_color
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.9, 0.85, 0.75, 1)
	environment.ambient_light_energy = 0.8
	world_env.environment = environment
	add_child(world_env)