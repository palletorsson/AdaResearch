# ModernPolysolid.gd - Modern standing sculptural polysolid
extends Node3D

var base_color: Color = Color(0.8, 0.9, 1.0)  # Cool metallic blue
var accent_color: Color = Color(0.2, 0.6, 0.9)  # Deep blue

func _ready():
	create_modern_polysolid()

func create_modern_polysolid():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertices = create_sculpture_vertices()
	var faces = create_sculpture_faces()
	
	# Create triangulated faces
	for face in faces:
		if face.size() >= 3:
			# Fan triangulation from first vertex
			for i in range(1, face.size() - 1):
				add_triangle_with_normal(st, vertices, [face[0], face[i], face[i + 1]])
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "ModernPolysolid"
	apply_sculptural_material(mesh_instance)
	add_child(mesh_instance)

func create_sculpture_vertices() -> Array:
	var vertices = []
	
	# Modern sculpture design: twisted truncated pyramid with geometric cuts
	var base_scale = 1.0
	var mid_scale = 0.7
	var top_scale = 0.4
	var height = 2.5
	
	# Base vertices (larger octagon at bottom)
	var base_y = 0.0
	for i in range(8):
		var angle = i * PI * 2.0 / 8.0
		var x = cos(angle) * base_scale
		var z = sin(angle) * base_scale
		vertices.append(Vector3(x, base_y, z))
	
	# Mid-level vertices (rotated and scaled)
	var mid_y = height * 0.4
	var mid_rotation = PI / 8.0  # 22.5 degree rotation
	for i in range(8):
		var angle = i * PI * 2.0 / 8.0 + mid_rotation
		var x = cos(angle) * mid_scale
		var z = sin(angle) * mid_scale
		vertices.append(Vector3(x, mid_y, z))
	
	# Upper mid vertices (hexagon, more rotation)
	var upper_y = height * 0.7
	var upper_rotation = PI / 6.0  # 30 degree rotation
	for i in range(6):
		var angle = i * PI * 2.0 / 6.0 + upper_rotation
		var x = cos(angle) * (mid_scale * 0.8)
		var z = sin(angle) * (mid_scale * 0.8)
		vertices.append(Vector3(x, upper_y, z))
	
	# Top vertices (small square, rotated 45 degrees)
	var top_y = height
	var top_rotation = PI / 4.0  # 45 degree rotation
	for i in range(4):
		var angle = i * PI * 2.0 / 4.0 + top_rotation
		var x = cos(angle) * top_scale
		var z = sin(angle) * top_scale
		vertices.append(Vector3(x, top_y, z))
	
	# Add some geometric detail vertices (floating geometric elements)
	# Floating triangular elements around mid section
	var detail_y = height * 0.5
	for i in range(3):
		var angle = i * PI * 2.0 / 3.0
		var radius = mid_scale * 1.3
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		vertices.append(Vector3(x, detail_y, z))
	
	# Internal structural vertices for complexity
	vertices.append(Vector3(0, height * 0.2, 0))  # Lower center
	vertices.append(Vector3(0, height * 0.6, 0))  # Upper center
	vertices.append(Vector3(0, height * 0.9, 0))  # Near top center
	
	return vertices

func create_sculpture_faces() -> Array:
	var faces = []
	
	# Base faces (octagon base - indices 0-7)
	faces.append([0, 1, 2, 3, 4, 5, 6, 7])  # Base octagon
	
	# Lower section: base octagon to mid octagon (0-7 to 8-15)
	for i in range(8):
		var next_i = (i + 1) % 8
		# Create twisted trapezoids
		faces.append([i, next_i, 8 + next_i, 8 + i])
	
	# Mid section: mid octagon to upper hexagon (8-15 to 16-21)
	for i in range(6):
		var mid_i = i + (i / 6.0 * 8.0) as int  # Map to octagon indices
		var mid_next = ((i + 1) % 6) + (((i + 1) % 6) / 6.0 * 8.0) as int
		faces.append([8 + mid_i, 8 + mid_next, 16 + ((i + 1) % 6), 16 + i])
	
	# Upper section: hexagon to square top (16-21 to 22-25)
	for i in range(4):
		var hex_i = i + (i / 4.0 * 6.0) as int
		var hex_next = ((i + 1) % 4) + (((i + 1) % 4) / 4.0 * 6.0) as int
		faces.append([16 + hex_i, 16 + hex_next, 22 + ((i + 1) % 4), 22 + i])
	
	# Top face (square - indices 22-25)
	faces.append([22, 23, 24, 25])
	
	# Floating geometric details (triangular elements - indices 26-28)
	for i in range(3):
		var next_i = (i + 1) % 3
		# Connect floating triangles to mid-level
		var mid_connect = (i * 8 / 3) as int
		faces.append([26 + i, 8 + mid_connect, 8 + ((mid_connect + 2) % 8)])
	
	# Internal structural faces for visual complexity
	var center_base = 29  # Lower center
	var center_mid = 30   # Upper center  
	var center_top = 31   # Near top center
	
	# Create internal support triangles
	for i in range(8):
		if i % 2 == 0:  # Only every other one to avoid overcrowding
			faces.append([i, center_base, (i + 2) % 8])
	
	for i in range(6):
		if i % 2 == 0:
			faces.append([16 + i, center_mid, 16 + ((i + 2) % 6)])
	
	# Connect centers vertically
	faces.append([center_base, 8, center_mid])
	faces.append([center_base, 8 + 4, center_mid])
	faces.append([center_mid, 16, center_top])
	faces.append([center_mid, 16 + 3, center_top])
	
	return faces

func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]  
	var v2 = vertices[face[2]]
	
	# Calculate face normal
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()
	
	# Ensure normal points outward (approximate check)
	var face_center = (v0 + v1 + v2) / 3.0
	var to_center = -face_center.normalized()
	if normal.dot(to_center) > 0:
		normal = -normal
	
	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v1)
	st.set_normal(normal)
	st.add_vertex(v2)

func apply_sculptural_material(mesh_instance: MeshInstance3D):
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	
	if shader:
		material.shader = shader
		
		# Modern sculptural appearance
		material.set_shader_parameter("base_color", base_color)
		material.set_shader_parameter("edge_color", accent_color)
		material.set_shader_parameter("edge_width", 0.8)
		material.set_shader_parameter("edge_sharpness", 3.0)
		material.set_shader_parameter("emission_strength", 0.6)
		
		mesh_instance.material_override = material
	else:
		# Fallback sculptural material
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = base_color
		standard_material.metallic = 0.7
		standard_material.roughness = 0.3
		standard_material.emission_enabled = true
		standard_material.emission = accent_color * 0.2
		mesh_instance.material_override = standard_material

func set_sculpture_colors(main_color: Color, edge_color: Color):
	base_color = main_color
	accent_color = edge_color
	
	var mesh_instance = get_child(0) as MeshInstance3D
	if mesh_instance and mesh_instance.material_override:
		apply_sculptural_material(mesh_instance)
