extends Node3D

# Tutorial script for teaching vertices, edges, and meshes
class_name MeshTutorial

# Scene nodes
var camera: Camera3D
var tutorial_parent: Node3D

# Materials
var grid_material: ShaderMaterial

# Store created meshes
var meshes = []
var current_step = 0

# Tutorial steps - progressive complexity
enum TutorialStep {
	# Row 1: Basic shapes
	CREATE_TRIANGLE,
	CREATE_PLANE,
	CREATE_PYRAMID,
	CREATE_CUBE,
	
	# Row 2: Advanced shapes
	CREATE_STAR,
	CREATE_CYLINDER,
	CREATE_SPHERE,
	CREATE_FISH,
	
	SHOW_PRIMITIVES
}

func _ready():
	setup_scene()
	setup_materials()
	start_tutorial()

func setup_scene():
	# Create camera positioned to see all shapes
	camera = Camera3D.new()
	camera.transform.origin = Vector3(0, 2, 12)
	camera.look_at(Vector3(0, 0, 0), Vector3.UP)
	add_child(camera)
	
	# Create parent node for tutorial objects
	tutorial_parent = Node3D.new()
	add_child(tutorial_parent)

func setup_materials():
	# Load simple double-sided grid shader
	var grid_shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	grid_material = ShaderMaterial.new()
	grid_material.shader = grid_shader
	
	# Set shader parameters for tutorial (simpler parameters)
	grid_material.set_shader_parameter("fill_color", Color(0.2, 0.3, 0.8, 0.7))
	grid_material.set_shader_parameter("wireframe_color", Color.CYAN)
	grid_material.set_shader_parameter("wireframe_width", 3.0)
	grid_material.set_shader_parameter("wireframe_brightness", 2.5)

func start_tutorial():
	print("=== 3D Mesh Tutorial: From Triangle to Primitives ===")
	print("Chapter 1: The Triangle - Simplest Possible Mesh")
	await get_tree().create_timer(1.0).timeout
	create_triangle()

func create_triangle():
	print("Creating triangle mesh - 3 vertices, 1 face")
	var triangle_vertices = [
		Vector3(0, 1, 0),     # Top center
		Vector3(-1, -1, 0),   # Bottom left  
		Vector3(1, -1, 0),    # Bottom right
	]
	var mesh_instance = create_mesh_from_vertices(triangle_vertices, "Triangle")
	meshes.append(mesh_instance)
	tutorial_parent.add_child(mesh_instance)
	
	# Position at origin (leftmost)
	mesh_instance.position.x = -9.0
	print("Triangle positioned at: ", mesh_instance.position)
	
	# Animate appearance
	mesh_instance.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ONE, 1.0)
	
	await get_tree().create_timer(2.0).timeout
	advance_tutorial()

func create_mesh_from_vertices(vertices_array: Array, mesh_name: String) -> MeshInstance3D:
	print("Building %s with %d vertices" % [mesh_name, vertices_array.size()])
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	# Create mesh vertices based on shape
	var mesh_vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	if vertices_array.size() == 3:
		# Triangle - single face
		mesh_vertices.append_array(vertices_array)
		indices = PackedInt32Array([0, 1, 2])
		
	elif vertices_array.size() == 4:
		# Plane - two triangles forming a rectangle
		mesh_vertices.append_array(vertices_array)
		# First triangle: 0,1,3 - Second triangle: 1,2,3
		indices = PackedInt32Array([0, 1, 3, 1, 2, 3])
		
	elif vertices_array.size() == 5:
		# Pyramid - square base + 4 triangular side faces
		mesh_vertices.append_array(vertices_array)
		# Base square: 0,1,2,3 (as two triangles)
		# Side faces: apex(4) with each base edge
		indices = PackedInt32Array([
			0, 1, 2,  # Base triangle 1: bottom-left, bottom-right, top-right
			0, 2, 3,  # Base triangle 2: bottom-left, top-right, top-left
			4, 0, 1,  # Side face 1: apex, bottom-left, bottom-right
			4, 1, 2,  # Side face 2: apex, bottom-right, top-right
			4, 2, 3,  # Side face 3: apex, top-right, top-left
			4, 3, 0   # Side face 4: apex, top-left, bottom-left
		])
	
	arrays[Mesh.ARRAY_VERTEX] = mesh_vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	# Calculate proper normals for each face
	var normals = PackedVector3Array()
	normals.resize(mesh_vertices.size())
	
	# Initialize all normals to zero
	for i in range(mesh_vertices.size()):
		normals[i] = Vector3.ZERO
	
	# Calculate face normals and accumulate to vertex normals
	for i in range(0, indices.size(), 3):
		var i0 = indices[i]
		var i1 = indices[i + 1] 
		var i2 = indices[i + 2]
		
		var v0 = mesh_vertices[i0]
		var v1 = mesh_vertices[i1]
		var v2 = mesh_vertices[i2]
		
		# Calculate face normal using cross product
		var edge1 = v1 - v0
		var edge2 = v2 - v0
		var face_normal = edge1.cross(edge2).normalized()
		
		# Add to each vertex of this triangle
		normals[i0] += face_normal
		normals[i1] += face_normal
		normals[i2] += face_normal
	
	# Normalize all vertex normals
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()
	
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	# Create the mesh
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = array_mesh
	mesh_instance.material_override = grid_material
	
	return mesh_instance

func create_star_mesh(vertices_array: Array, mesh_name: String) -> MeshInstance3D:
	print("Building star with %d vertices" % vertices_array.size())
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var mesh_vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Add center point
	mesh_vertices.append(Vector3.ZERO)
	
	# Add all star points
	for vertex in vertices_array:
		mesh_vertices.append(vertex)
	
	# Create triangles from center to each edge
	for i in range(vertices_array.size()):
		var next_i = (i + 1) % vertices_array.size()
		# Triangle: center, current point, next point
		indices.append(0)  # Center
		indices.append(i + 1)  # Current point
		indices.append(next_i + 1)  # Next point
	
	arrays[Mesh.ARRAY_VERTEX] = mesh_vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	# Calculate proper normals
	var normals = PackedVector3Array()
	normals.resize(mesh_vertices.size())
	
	for i in range(mesh_vertices.size()):
		normals[i] = Vector3.ZERO
	
	for i in range(0, indices.size(), 3):
		var i0 = indices[i]
		var i1 = indices[i + 1] 
		var i2 = indices[i + 2]
		
		var v0 = mesh_vertices[i0]
		var v1 = mesh_vertices[i1]
		var v2 = mesh_vertices[i2]
		
		var edge1 = v1 - v0
		var edge2 = v2 - v0
		var face_normal = edge1.cross(edge2).normalized()
		
		normals[i0] += face_normal
		normals[i1] += face_normal
		normals[i2] += face_normal
	
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()
	
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = array_mesh
	mesh_instance.material_override = grid_material
	
	return mesh_instance

func create_fish_mesh(vertices_array: Array, mesh_name: String) -> MeshInstance3D:
	print("Building fish with %d vertices - perfect for vector tutorials!" % vertices_array.size())
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var mesh_vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Add all fish vertices
	for vertex in vertices_array:
		mesh_vertices.append(vertex)
	
	# Fish body triangles (using the vertices we defined)
	# Main body (diamond shape)
	indices.append_array([1, 0, 2])  # Head-top-bottom triangle
	indices.append_array([0, 3, 2])  # Top-back-bottom triangle
	
	# Tail triangles
	indices.append_array([3, 4, 6])  # Back-tail_top-tail_connection
	indices.append_array([3, 6, 5])  # Back-tail_connection-tail_bottom
	
	# Side fins (small triangles)
	indices.append_array([1, 7, 0])  # Head-side_fin_top-top
	indices.append_array([1, 2, 8])  # Head-bottom-side_fin_bottom
	
	arrays[Mesh.ARRAY_VERTEX] = mesh_vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	# Calculate proper normals
	var normals = PackedVector3Array()
	normals.resize(mesh_vertices.size())
	
	for i in range(mesh_vertices.size()):
		normals[i] = Vector3.ZERO
	
	for i in range(0, indices.size(), 3):
		var i0 = indices[i]
		var i1 = indices[i + 1] 
		var i2 = indices[i + 2]
		
		var v0 = mesh_vertices[i0]
		var v1 = mesh_vertices[i1]
		var v2 = mesh_vertices[i2]
		
		var edge1 = v1 - v0
		var edge2 = v2 - v0
		var face_normal = edge1.cross(edge2).normalized()
		
		normals[i0] += face_normal
		normals[i1] += face_normal
		normals[i2] += face_normal
	
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()
	
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = array_mesh
	mesh_instance.material_override = grid_material
	
	return mesh_instance

func advance_tutorial():
	current_step += 1
	
	match current_step:
		TutorialStep.CREATE_PLANE:
			print("\nChapter 2: The Plane - Two Triangles")
			await get_tree().create_timer(1.0).timeout
			create_plane()
			
		TutorialStep.CREATE_PYRAMID:
			print("\nChapter 3: The Pyramid - First 3D Shape")
			await get_tree().create_timer(1.0).timeout
			create_pyramid()
			
		TutorialStep.CREATE_CUBE:
			print("\nChapter 4: The Cube - Complex 3D Shape")
			await get_tree().create_timer(1.0).timeout
			create_cube()
			
		# Row 2: Advanced shapes
		TutorialStep.CREATE_STAR:
			print("\nChapter 5: The Star - Complex 2D Shape")
			await get_tree().create_timer(1.0).timeout
			create_star()
			
		TutorialStep.CREATE_CYLINDER:
			print("\nChapter 6: The Cylinder - Circular Cross-Section")
			await get_tree().create_timer(1.0).timeout
			create_cylinder()
			
		TutorialStep.CREATE_SPHERE:
			print("\nChapter 7: The Sphere - Curved Surface Approximation")
			await get_tree().create_timer(1.0).timeout
			create_sphere()
			
		TutorialStep.CREATE_FISH:
			print("\nChapter 8: The Fish - Organic Shape for Vector Tutorial")
			await get_tree().create_timer(1.0).timeout
			create_fish()
			
		TutorialStep.SHOW_PRIMITIVES:
			print("\nChapter 9: Tutorial Complete!")
			show_completion()

func create_plane():
	print("Creating plane mesh - 4 vertices, 2 triangles")
	var plane_vertices = [
		Vector3(-1, 1, 0),    # Top left
		Vector3(1, 1, 0),     # Top right  
		Vector3(1, -1, 0),    # Bottom right
		Vector3(-1, -1, 0),   # Bottom left
	]
	var mesh_instance = create_mesh_from_vertices(plane_vertices, "Plane")
	meshes.append(mesh_instance)
	tutorial_parent.add_child(mesh_instance)
	
	# Position offset so it doesn't overlap
	mesh_instance.position.x = -3.0
	
	# Animate appearance
	mesh_instance.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ONE, 1.0)
	
	await get_tree().create_timer(2.0).timeout
	advance_tutorial()

func create_pyramid():
	print("Creating pyramid mesh - 5 vertices, 6 triangles")
	var pyramid_vertices = [
		Vector3(-1, -1, 0),   # Base: bottom front left
		Vector3(1, -1, 0),    # Base: bottom front right  
		Vector3(1, -1, -2),   # Base: bottom back right
		Vector3(-1, -1, -2),  # Base: bottom back left
		Vector3(0, 1.5, -1),  # Apex (standing upright)
	]
	
	print("Pyramid vertices: ", pyramid_vertices)
	var mesh_instance = create_mesh_from_vertices(pyramid_vertices, "Pyramid")
	print("Pyramid mesh created: ", mesh_instance.name)
	
	meshes.append(mesh_instance)
	tutorial_parent.add_child(mesh_instance)
	
	# Position offset
	mesh_instance.position.x = 3.0
	print("Pyramid positioned at: ", mesh_instance.position)
	
	# Animate appearance
	mesh_instance.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ONE, 1.0)
	
	await get_tree().create_timer(2.0).timeout
	advance_tutorial()

func create_cube():
	print("Creating cube mesh - 8 vertices, 12 triangles")
	# Use BoxMesh for simplicity, but show it's built from vertices
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Cube"
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(2, 2, 2)
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = grid_material
	
	meshes.append(mesh_instance)
	tutorial_parent.add_child(mesh_instance)
	
	# Position offset
	mesh_instance.position.x = 9.0
	
	# Animate appearance
	mesh_instance.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ONE, 1.0)
	
	await get_tree().create_timer(2.0).timeout
	advance_tutorial()

# === ROW 2: ADVANCED SHAPES ===

func create_star():
	print("Creating 5-pointed star - multiple triangular sections")
	var star_vertices = []
	var center = Vector3(0, 0, 0)
	var outer_radius = 1.5
	var inner_radius = 0.6
	
	# Create star points (5 outer, 5 inner)
	for i in range(10):
		var angle = (i * PI * 2.0) / 10.0
		var radius = outer_radius if (i % 2 == 0) else inner_radius
		star_vertices.append(Vector3(
			cos(angle) * radius,
			sin(angle) * radius,
			0
		))
	
	var mesh_instance = create_star_mesh(star_vertices, "Star")
	meshes.append(mesh_instance)
	tutorial_parent.add_child(mesh_instance)
	
	# Position on second row
	mesh_instance.position.x = -9.0
	mesh_instance.position.z = -6.0
	
	# Animate appearance
	mesh_instance.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ONE, 1.0)
	
	await get_tree().create_timer(2.0).timeout
	advance_tutorial()

func create_cylinder():
	print("Creating cylinder - circular cross-section with triangular faces")
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Cylinder"
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = 2.0
	cylinder_mesh.top_radius = 1.0
	cylinder_mesh.bottom_radius = 1.0
	cylinder_mesh.radial_segments = 8  # Low poly for education
	mesh_instance.mesh = cylinder_mesh
	mesh_instance.material_override = grid_material
	
	meshes.append(mesh_instance)
	tutorial_parent.add_child(mesh_instance)
	
	# Position on second row
	mesh_instance.position.x = -3.0
	mesh_instance.position.z = -6.0
	
	# Animate appearance
	mesh_instance.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ONE, 1.0)
	
	await get_tree().create_timer(2.0).timeout
	advance_tutorial()

func create_sphere():
	print("Creating sphere approximation - curved surface made of triangles")
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Sphere"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 1.2
	sphere_mesh.height = 2.4
	sphere_mesh.radial_segments = 8   # Low poly for education
	sphere_mesh.rings = 6
	mesh_instance.mesh = sphere_mesh
	mesh_instance.material_override = grid_material
	
	meshes.append(mesh_instance)
	tutorial_parent.add_child(mesh_instance)
	
	# Position on second row
	mesh_instance.position.x = 3.0
	mesh_instance.position.z = -6.0
	
	# Animate appearance
	mesh_instance.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ONE, 1.0)
	
	await get_tree().create_timer(2.0).timeout
	advance_tutorial()

func create_fish():
	print("Creating fish mesh - perfect for vector tutorials!")
	var fish_vertices = [
		# Body (diamond shape)
		Vector3(0, 0.5, 0),      # Top fin connection
		Vector3(-1.5, 0, 0),     # Head (front)
		Vector3(0, -0.5, 0),     # Bottom
		Vector3(1.0, 0, 0),      # Back of body
		
		# Tail
		Vector3(2.0, 0.8, 0),    # Top tail fin
		Vector3(2.0, -0.8, 0),   # Bottom tail fin
		Vector3(1.8, 0, 0),      # Tail connection
		
		# Side fins
		Vector3(-0.5, 0.3, 0.5), # Top side fin
		Vector3(-0.5, -0.3, 0.5), # Bottom side fin
	]
	
	var mesh_instance = create_fish_mesh(fish_vertices, "Fish")
	meshes.append(mesh_instance)
	tutorial_parent.add_child(mesh_instance)
	
	# Position on second row
	mesh_instance.position.x = 9.0
	mesh_instance.position.z = -6.0
	
	# Animate appearance
	mesh_instance.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ONE, 1.0)
	
	await get_tree().create_timer(2.0).timeout
	advance_tutorial()

func show_completion():
	print("Tutorial Complete!")
	print("\nYou've learned procedural mesh construction:")
	print("ROW 1 - Basic Shapes:")
	print("✓ Triangle - simplest mesh (3 vertices, 1 face)")
	print("✓ Plane - two triangles (4 vertices, 2 faces)")  
	print("✓ Pyramid - 3D shape (5 vertices, 6 faces)")
	print("✓ Cube - complex 3D (8 vertices, 12 faces)")
	print("\nROW 2 - Advanced Shapes:")
	print("✓ Star - complex 2D polygon (multiple triangular sections)")
	print("✓ Cylinder - circular cross-section (radial segments)")
	print("✓ Sphere - curved surface approximation (subdivision)")
	print("✓ Fish - organic shape (perfect for vector tutorials!)")
	print("\nNow you understand how ALL 3D objects are built from triangles!")
	
	await get_tree().create_timer(1.0).timeout
	print("Rotating camera to show all angles...")
	
	# Rotate camera around all the meshes (both rows)
	var center_point = Vector3(0, 0, -3)  # Center between both rows
	var radius = 18.0    # Larger radius to see both rows
	var height = 8.0     # Higher to see both rows
	var rotation_time = 12.0  # Longer to appreciate all 8 shapes
	
	var tween = create_tween()
	tween.set_loops()  # Loop forever
	
	# Create circular motion around the shapes
	tween.tween_method(
		func(angle_deg):
			var angle_rad = deg_to_rad(angle_deg)
			var new_pos = Vector3(
				center_point.x + radius * cos(angle_rad),
				height,
				center_point.z + radius * sin(angle_rad)
			)
			camera.transform.origin = new_pos
			camera.look_at(center_point, Vector3.UP),
		0.0, 360.0, rotation_time
	)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		# Restart tutorial
		get_tree().reload_current_scene()
