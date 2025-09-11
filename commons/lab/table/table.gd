# Table.gd - Procedural table using SurfaceTool
extends Node3D

var base_color: Color = Color(0.6, 0.3, 0.1)  # Dark wood

func _ready():
	create_table()

func create_table():
	var table_node = Node3D.new()
	table_node.name = "Table"
	
	# Create table components
	create_tabletop(table_node)
	create_table_legs(table_node)
	create_table_frame(table_node)  # Optional support frame
	
	add_child(table_node)

func create_tabletop(parent: Node3D):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var top_size = Vector3(1.2, 0.05, 0.8)
	var top_pos = Vector3(0, 0.35, 0)  # Raised above ground
	var vertices = create_rounded_box_vertices(top_pos, top_size, 0.03)
	var faces = create_box_faces()
	
	# Add all triangles for the tabletop
	for face in faces:
		add_triangle_with_normal(st, vertices, [face[0], face[1], face[2]])
		add_triangle_with_normal(st, vertices, [face[0], face[2], face[3]])
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "Tabletop"
	apply_furniture_material(mesh_instance, base_color)
	parent.add_child(mesh_instance)

func create_table_legs(parent: Node3D):
	var leg_positions = [
		Vector3(-0.5, 0.175, -0.3),   # Front left
		Vector3(0.5, 0.175, -0.3),    # Front right
		Vector3(-0.5, 0.175, 0.3),    # Back left
		Vector3(0.5, 0.175, 0.3)      # Back right
	]
	
	for i in range(leg_positions.size()):
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		var leg_size = Vector3(0.06, 0.35, 0.06)  # Square legs
		var vertices = create_box_vertices(leg_positions[i], leg_size)
		var faces = create_box_faces()
		
		# Add triangles for leg
		for face in faces:
			add_triangle_with_normal(st, vertices, [face[0], face[1], face[2]])
			add_triangle_with_normal(st, vertices, [face[0], face[2], face[3]])
		
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = st.commit()
		mesh_instance.name = "Leg_" + str(i)
		apply_furniture_material(mesh_instance, base_color * 0.8)
		parent.add_child(mesh_instance)

func create_table_frame(parent: Node3D):
	# Create support beams between legs
	var beam_configs = [
		# Horizontal beams (lower)
		{
			"start": Vector3(-0.5, 0.1, -0.3),
			"end": Vector3(0.5, 0.1, -0.3),
			"size": Vector3(1.0, 0.03, 0.03)
		},
		{
			"start": Vector3(-0.5, 0.1, 0.3),
			"end": Vector3(0.5, 0.1, 0.3),
			"size": Vector3(1.0, 0.03, 0.03)
		},
		{
			"start": Vector3(-0.5, 0.1, -0.3),
			"end": Vector3(-0.5, 0.1, 0.3),
			"size": Vector3(0.03, 0.03, 0.6)
		},
		{
			"start": Vector3(0.5, 0.1, -0.3),
			"end": Vector3(0.5, 0.1, 0.3),
			"size": Vector3(0.03, 0.03, 0.6)
		}
	]
	
	for i in range(beam_configs.size()):
		var config = beam_configs[i]
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		var center = (config.start + config.end) * 0.5
		var vertices = create_box_vertices(center, config.size)
		var faces = create_box_faces()
		
		# Add triangles for beam
		for face in faces:
			add_triangle_with_normal(st, vertices, [face[0], face[1], face[2]])
			add_triangle_with_normal(st, vertices, [face[0], face[2], face[3]])
		
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = st.commit()
		mesh_instance.name = "Beam_" + str(i)
		apply_furniture_material(mesh_instance, base_color * 0.7)
		parent.add_child(mesh_instance)

func create_rounded_box_vertices(center: Vector3, size: Vector3, bevel: float) -> Array:
	# For simplicity, just return regular box vertices
	# In a full implementation, you'd add rounded corners
	return create_box_vertices(center, size)

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
	# Create shader material using the same approach as dodecahedron
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		
		# Set shader parameters for table
		material.set_shader_parameter("base_color", color)
		material.set_shader_parameter("edge_color", Color(0.9, 0.9, 0.7))
		material.set_shader_parameter("edge_width", 0.8)
		material.set_shader_parameter("edge_sharpness", 2.5)
		material.set_shader_parameter("emission_strength", 0.6)
		
		mesh_instance.material_override = material
	else:
		# Fallback to standard material
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.roughness = 0.8
		standard_material.metallic = 0.1
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
