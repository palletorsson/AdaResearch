# Chair.gd - Procedural chair using SurfaceTool
extends Node3D

var base_color: Color = Color(0.8, 0.4, 0.2)  # Wood brown

func _ready():
	create_chair()

func create_chair():
	var chair_node = Node3D.new()
	chair_node.name = "Chair"
	
	# Create chair components
	create_seat(chair_node)
	create_backrest(chair_node)
	create_legs(chair_node)
	
	add_child(chair_node)

func create_seat(parent: Node3D):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var seat_size = Vector3(0.5, 0.05, 0.5)
	var vertices = create_box_vertices(Vector3.ZERO, seat_size)
	var faces = create_box_faces()
	
	# Add all triangles for the seat
	for face in faces:
		add_triangle_with_normal(st, vertices, [face[0], face[1], face[2]])
		add_triangle_with_normal(st, vertices, [face[0], face[2], face[3]])
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "Seat"
	apply_furniture_material(mesh_instance, base_color)
	parent.add_child(mesh_instance)

func create_backrest(parent: Node3D):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var back_size = Vector3(0.5, 0.6, 0.05)
	var back_pos = Vector3(0, 0.35, -0.225)
	var vertices = create_box_vertices(back_pos, back_size)
	var faces = create_box_faces()
	
	# Add all triangles for the backrest
	for face in faces:
		add_triangle_with_normal(st, vertices, [face[0], face[1], face[2]])
		add_triangle_with_normal(st, vertices, [face[0], face[2], face[3]])
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "Backrest"
	apply_furniture_material(mesh_instance, base_color * 0.9)
	parent.add_child(mesh_instance)

func create_legs(parent: Node3D):
	var leg_positions = [
		Vector3(-0.2, -0.2, -0.2),
		Vector3(0.2, -0.2, -0.2),
		Vector3(-0.2, -0.2, 0.2),
		Vector3(0.2, -0.2, 0.2)
	]
	
	for i in range(leg_positions.size()):
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		var leg_radius = 0.02
		var leg_height = 0.4
		var vertices = create_cylinder_vertices(leg_positions[i], leg_radius, leg_height)
		var faces = create_cylinder_faces(8)  # 8 sides
		
		# Add triangles for cylinder
		for face in faces:
			if face.size() == 3:
				add_triangle_with_normal(st, vertices, face)
			else:  # Quad faces
				add_triangle_with_normal(st, vertices, [face[0], face[1], face[2]])
				add_triangle_with_normal(st, vertices, [face[0], face[2], face[3]])
		
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = st.commit()
		mesh_instance.name = "Leg_" + str(i)
		apply_furniture_material(mesh_instance, base_color * 0.8)
		parent.add_child(mesh_instance)

func create_box_vertices(center: Vector3, size: Vector3) -> Array:
	var half_size = size * 0.5
	return [
		center + Vector3(-half_size.x, -half_size.y, -half_size.z),  # 0
		center + Vector3(half_size.x, -half_size.y, -half_size.z),   # 1
		center + Vector3(half_size.x, half_size.y, -half_size.z),    # 2
		center + Vector3(-half_size.x, half_size.y, -half_size.z),   # 3
		center + Vector3(-half_size.x, -half_size.y, half_size.z),   # 4
		center + Vector3(half_size.x, -half_size.y, half_size.z),    # 5
		center + Vector3(half_size.x, half_size.y, half_size.z),     # 6
		center + Vector3(-half_size.x, half_size.y, half_size.z)     # 7
	]

func create_box_faces() -> Array:
	return [
		[0, 1, 2, 3],  # Front
		[5, 4, 7, 6],  # Back
		[4, 0, 3, 7],  # Left
		[1, 5, 6, 2],  # Right
		[3, 2, 6, 7],  # Top
		[4, 5, 1, 0]   # Bottom
	]

func create_cylinder_vertices(center: Vector3, radius: float, height: float) -> Array:
	var vertices = []
	var segments = 8
	var half_height = height * 0.5
	
	# Bottom circle
	for i in range(segments):
		var angle = 2.0 * PI * i / segments
		var x = center.x + radius * cos(angle)
		var z = center.z + radius * sin(angle)
		vertices.append(Vector3(x, center.y - half_height, z))
	
	# Top circle
	for i in range(segments):
		var angle = 2.0 * PI * i / segments
		var x = center.x + radius * cos(angle)
		var z = center.z + radius * sin(angle)
		vertices.append(Vector3(x, center.y + half_height, z))
	
	# Center points
	vertices.append(Vector3(center.x, center.y - half_height, center.z))  # Bottom center
	vertices.append(Vector3(center.x, center.y + half_height, center.z))   # Top center
	
	return vertices

func create_cylinder_faces(segments: int) -> Array:
	var faces = []
	
	# Side faces
	for i in range(segments):
		var next = (i + 1) % segments
		faces.append([i, next, next + segments, i + segments])
	
	# Bottom faces
	for i in range(segments):
		var next = (i + 1) % segments
		faces.append([segments * 2, next, i])  # Bottom center to edge
	
	# Top faces
	for i in range(segments):
		var next = (i + 1) % segments
		faces.append([segments * 2 + 1, i + segments, next + segments])  # Top center to edge
	
	return faces

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

func apply_furniture_material(mesh_instance: MeshInstance3D, color: Color):
	# Create shader material using the rotated checkers shader
	var material = ShaderMaterial.new()
	var shader = load("res://algorithms/patterngeneration/gridscheckers/rotatedcheckers.gdshader")
	if shader:
		material.shader = shader
		
		# Set shader parameters to match the shader uniforms
		material.set_shader_parameter("uv_scale", Vector2(24.0, 24.0))  # tiles per UV
		material.set_shader_parameter("angle_deg", 45.0)  # rotation of the grid
		material.set_shader_parameter("gutter", 0.08)  # thickness of gaps
		material.set_shader_parameter("edge_soft", 0.02)  # feather for gutter
		
		# Color parameters
		material.set_shader_parameter("col_a", Color(0.05, 0.02, 0.08, 1.0))  # Dark base color
		material.set_shader_parameter("col_b", color)  # Use the passed color as the second checker color
		material.set_shader_parameter("col_gutter", Color(0.02, 0.98, 0.85, 1.0))  # Cyan gutter color
		
		# Material properties
		material.set_shader_parameter("glow", 1.2)  # Emission strength
		material.set_shader_parameter("metallic", 0.0)  # Metallic value
		material.set_shader_parameter("roughness", 0.45)  # Roughness value
		
		mesh_instance.material_override = material
	else:
		# Fallback to standard material
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.emission_enabled = true
		standard_material.emission = color * 0.2
		mesh_instance.material_override = standard_material

func set_base_color(color: Color):
	base_color = color
	# Update all child materials
	for child in get_children():
		update_child_materials(child, color)

func update_child_materials(node: Node, color: Color):
	if node is MeshInstance3D:
		apply_furniture_material(node, color)
	for child in node.get_children():
		update_child_materials(child, color)
