extends Node3D

# Scene for comparing different cube subdivision and smoothing methods

# Generate smooth corner cube geometry 
func generate_smooth_corner_cube_geometry(surface_tool: SurfaceTool, subdivisions: int):
	# Use the existing subdivided cube geometry as a base for now
	# This function will be enhanced with proper smooth corner generation
	generate_subdivided_cube_geometry(surface_tool, subdivisions)

# Method 3: Rounded corner cube using spherical blending
func create_rounded_corner_cube():
	print("Creating rounded corner cube...")
	
	var surface_tool = SurfaceTool.new()
	var subdivisions = 8  # Higher subdivision for smoother corners
	
	# Begin surface creation
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate rounded cube geometry (simplified approach)
	generate_rounded_cube_simple(surface_tool, subdivisions)
	
	# Apply smoothing operations
	surface_tool.generate_normals()
	surface_tool.generate_tangents()
	surface_tool.index()
	
	# Create the mesh
	var array_mesh = surface_tool.commit()
	
	# Create MeshInstance3D and assign the mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = array_mesh
	mesh_instance.position = Vector3(3, 0, 0)  # Position on right
	
	# Apply material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.MAGENTA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	material.roughness = 0.1
	material.metallic = 0.3
	mesh_instance.material_override = material
	
	add_child(mesh_instance)
	
	print("Rounded corner cube created with %d vertices" % array_mesh.surface_get_array_len(0))

# Simplified rounded cube generation
func generate_rounded_cube_simple(surface_tool: SurfaceTool, subdivisions: int):
	var size = 1.0
	var half_size = size * 0.5
	var corner_radius = 0.3  # How rounded the corners are
	
	# Define the 6 faces of a cube with proper winding order
	var faces = [
		# Front face (+Z)
		[Vector3(-half_size, -half_size, half_size), Vector3(half_size, -half_size, half_size), 
		 Vector3(half_size, half_size, half_size), Vector3(-half_size, half_size, half_size)],
		# Back face (-Z) 
		[Vector3(half_size, -half_size, -half_size), Vector3(-half_size, -half_size, -half_size),
		 Vector3(-half_size, half_size, -half_size), Vector3(half_size, half_size, -half_size)],
		# Right face (+X)
		[Vector3(half_size, -half_size, half_size), Vector3(half_size, -half_size, -half_size),
		 Vector3(half_size, half_size, -half_size), Vector3(half_size, half_size, half_size)],
		# Left face (-X)
		[Vector3(-half_size, -half_size, -half_size), Vector3(-half_size, -half_size, half_size),
		 Vector3(-half_size, half_size, half_size), Vector3(-half_size, half_size, -half_size)],
		# Top face (+Y)
		[Vector3(-half_size, half_size, half_size), Vector3(half_size, half_size, half_size),
		 Vector3(half_size, half_size, -half_size), Vector3(-half_size, half_size, -half_size)],
		# Bottom face (-Y)
		[Vector3(-half_size, -half_size, -half_size), Vector3(half_size, -half_size, -half_size),
		 Vector3(half_size, -half_size, half_size), Vector3(-half_size, -half_size, half_size)]
	]
	
	# Subdivide each face with corner rounding
	for face in faces:
		subdivide_face_with_rounding(surface_tool, face, subdivisions, corner_radius)

# Subdivide a face with corner rounding
func subdivide_face_with_rounding(surface_tool: SurfaceTool, corners: Array, subdivisions: int, corner_radius: float):
	var step = 1.0 / subdivisions
	
	# Generate vertices for subdivided face with rounding
	for i in subdivisions:
		for j in subdivisions:
			var u1 = i * step
			var v1 = j * step
			var u2 = (i + 1) * step
			var v2 = (j + 1) * step
			
			# Calculate positions using bilinear interpolation with rounding
			var p1 = lerp_quad_rounded(corners, u1, v1, corner_radius)
			var p2 = lerp_quad_rounded(corners, u2, v1, corner_radius)
			var p3 = lerp_quad_rounded(corners, u2, v2, corner_radius)
			var p4 = lerp_quad_rounded(corners, u1, v2, corner_radius)
			
			# Calculate UV coordinates for texturing
			var uv1 = Vector2(u1, v1)
			var uv2 = Vector2(u2, v1)
			var uv3 = Vector2(u2, v2)
			var uv4 = Vector2(u1, v2)
			
			# Add triangles for this subdivision with UVs
			add_quad_as_triangles_with_uv(surface_tool, p1, p2, p3, p4, uv1, uv2, uv3, uv4)

# Bilinear interpolation with corner rounding
func lerp_quad_rounded(corners: Array, u: float, v: float, corner_radius: float) -> Vector3:
	var top = corners[0].lerp(corners[1], u)
	var bottom = corners[3].lerp(corners[2], u)
	var cube_pos = top.lerp(bottom, v)
	
	# Apply spherical rounding at corners and edges
	var sphere_pos = cube_pos.normalized() * 0.5
	var distance_from_center = abs(u - 0.5) + abs(v - 0.5)  # Simple distance metric
	var rounding_factor = corner_radius * (1.0 - distance_from_center)
	
	return cube_pos.lerp(sphere_pos, rounding_factor)

func _ready():
	# Create cubes with different smoothing approaches
	create_surface_tool_cube()
	create_built_in_smooth_cube()
	create_rounded_corner_cube()
	
	# Add labels and lighting
	setup_scene()

# Method 1: SurfaceTool with manual subdivision and smoothing  
func create_surface_tool_cube():
	print("Creating SurfaceTool subdivided cube...")
	
	var surface_tool = SurfaceTool.new()
	var subdivisions = 6  # Increased subdivisions for smoother result
	
	# Begin surface creation
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate subdivided cube geometry with corner smoothing
	generate_smooth_corner_cube_geometry(surface_tool, subdivisions)
	
	# Apply smoothing operations
	surface_tool.generate_normals()  # Smooth normals
	surface_tool.generate_tangents() # Tangents for advanced materials
	surface_tool.index()             # Optimize mesh
	
	# Create the mesh
	var array_mesh = surface_tool.commit()
	
	# Create MeshInstance3D and assign the mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = array_mesh
	mesh_instance.position = Vector3(-3, 0, 0)  # Position on left
	
	# Apply material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.CYAN
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	material.roughness = 0.2
	material.metallic = 0.1
	mesh_instance.material_override = material
	
	add_child(mesh_instance)
	
	print("Smooth corner cube created with %d vertices" % array_mesh.surface_get_array_len(0))

# Method 2: Built-in BoxMesh with subdivision parameters
func create_built_in_smooth_cube():
	print("Creating built-in subdivided cube...")
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3.ONE
	
	# Set subdivision parameters
	box_mesh.subdivide_width = 4
	box_mesh.subdivide_height = 4
	box_mesh.subdivide_depth = 4
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = box_mesh
	mesh_instance.position = Vector3(0, 0, 0)  # Position in center
	
	# Apply smooth material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.ORANGE
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	material.roughness = 0.3
	mesh_instance.material_override = material
	
	add_child(mesh_instance)
	
	print("Built-in cube created with subdivisions: %dx%dx%d" % [box_mesh.subdivide_width, box_mesh.subdivide_height, box_mesh.subdivide_depth])

# Generate subdivided cube geometry using SurfaceTool
func generate_subdivided_cube_geometry(surface_tool: SurfaceTool, subdivisions: int):
	var size = 1.0
	var half_size = size * 0.5
	
	# Define the 6 faces of a cube with proper winding order
	var faces = [
		# Front face (+Z)
		[Vector3(-half_size, -half_size, half_size), Vector3(half_size, -half_size, half_size), 
		 Vector3(half_size, half_size, half_size), Vector3(-half_size, half_size, half_size)],
		# Back face (-Z) 
		[Vector3(half_size, -half_size, -half_size), Vector3(-half_size, -half_size, -half_size),
		 Vector3(-half_size, half_size, -half_size), Vector3(half_size, half_size, -half_size)],
		# Right face (+X)
		[Vector3(half_size, -half_size, half_size), Vector3(half_size, -half_size, -half_size),
		 Vector3(half_size, half_size, -half_size), Vector3(half_size, half_size, half_size)],
		# Left face (-X)
		[Vector3(-half_size, -half_size, -half_size), Vector3(-half_size, -half_size, half_size),
		 Vector3(-half_size, half_size, half_size), Vector3(-half_size, half_size, -half_size)],
		# Top face (+Y)
		[Vector3(-half_size, half_size, half_size), Vector3(half_size, half_size, half_size),
		 Vector3(half_size, half_size, -half_size), Vector3(-half_size, half_size, -half_size)],
		# Bottom face (-Y)
		[Vector3(-half_size, -half_size, -half_size), Vector3(half_size, -half_size, -half_size),
		 Vector3(half_size, -half_size, half_size), Vector3(-half_size, -half_size, half_size)]
	]
	
	# Subdivide each face
	for face in faces:
		subdivide_face(surface_tool, face, subdivisions)

# Subdivide a single face into smaller quads
func subdivide_face(surface_tool: SurfaceTool, corners: Array, subdivisions: int):
	var step = 1.0 / subdivisions
	
	# Generate vertices for subdivided face
	for i in subdivisions:
		for j in subdivisions:
			var u1 = i * step
			var v1 = j * step
			var u2 = (i + 1) * step
			var v2 = (j + 1) * step
			
			# Calculate positions using bilinear interpolation
			var p1 = lerp_quad(corners, u1, v1)
			var p2 = lerp_quad(corners, u2, v1)
			var p3 = lerp_quad(corners, u2, v2)
			var p4 = lerp_quad(corners, u1, v2)
			
			# Calculate UV coordinates for texturing
			var uv1 = Vector2(u1, v1)
			var uv2 = Vector2(u2, v1)
			var uv3 = Vector2(u2, v2)
			var uv4 = Vector2(u1, v2)
			
			# Add triangles for this subdivision with UVs
			add_quad_as_triangles_with_uv(surface_tool, p1, p2, p3, p4, uv1, uv2, uv3, uv4)

# Bilinear interpolation for quad vertices
func lerp_quad(corners: Array, u: float, v: float) -> Vector3:
	var top = corners[0].lerp(corners[1], u)
	var bottom = corners[3].lerp(corners[2], u)
	return top.lerp(bottom, v)

# Add a quad as two triangles with UV coordinates
func add_quad_as_triangles_with_uv(surface_tool: SurfaceTool, p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3, 
								  uv1: Vector2, uv2: Vector2, uv3: Vector2, uv4: Vector2):
	# First triangle (p1, p2, p3)
	surface_tool.set_uv(uv1)
	surface_tool.set_vertex(p1)
	surface_tool.set_uv(uv2)
	surface_tool.set_vertex(p2)
	surface_tool.set_uv(uv3)
	surface_tool.set_vertex(p3)
	
	# Second triangle (p1, p3, p4)
	surface_tool.set_uv(uv1)
	surface_tool.set_vertex(p1)
	surface_tool.set_uv(uv3)
	surface_tool.set_vertex(p3)
	surface_tool.set_uv(uv4)
	surface_tool.set_vertex(p4)

# Setup scene with camera, lighting, and labels
func setup_scene():
	# Add directional light
	var light = DirectionalLight3D.new()
	light.position = Vector3(5, 5, 5)
	light.look_at(Vector3.ZERO, Vector3.UP)
	light.light_energy = 1.0
	add_child(light)
	
	# Add camera
	var camera = Camera3D.new()
	camera.position = Vector3(0, 2, 6)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	add_child(camera)
	
	# Add environment
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	camera.environment = env
	
	print("Scene setup complete!")
	print("Left (Cyan): SurfaceTool with manual subdivision")
	print("Right (Orange): Built-in BoxMesh with subdivision parameters")

# Optional: Add rotation for better visualization
func _process(delta):
	# Slowly rotate both cubes for better viewing
	for child in get_children():
		if child is MeshInstance3D:
			child.rotation.y += delta * 0.5
			child.rotation.x += delta * 0.3
