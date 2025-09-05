# CrystalCluster.gd - Multiple small crystals arranged in a cluster
extends Node3D

var base_color: Color = Color(0.0, 0.4, 1.0)  # Blue from pride colors

func _ready():
	create_crystal_cluster()

func create_crystal_cluster():
	# Create multiple small crystals
	for i in range(5):
		var crystal = create_single_crystal(randf_range(0.1, 0.25))
		var crystal_node = Node3D.new()
		crystal_node.name = "Crystal_%d" % i
		crystal_node.add_child(crystal)
		
		# Position crystals deterministically for consistency
		var rng = RandomNumberGenerator.new()
		rng.seed = i * 42  # Deterministic seeding
		
		crystal_node.position = Vector3(
			rng.randf_range(-0.2, 0.2),
			rng.randf_range(-0.1, 0.1), 
			rng.randf_range(-0.2, 0.2)
		)
		crystal_node.rotation_degrees = Vector3(
			rng.randf_range(0, 360),
			rng.randf_range(0, 360),
			rng.randf_range(0, 360)
		)
		
		apply_queer_material(crystal, base_color)
		add_child(crystal_node)

func create_single_crystal(size: float) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Hexagonal prism crystal
	var vertices = []
	var height = size * 1.5
	
	# Bottom hex
	for i in range(6):
		var angle = i * PI / 3.0
		vertices.append(Vector3(cos(angle) * size, -height/2, sin(angle) * size))
	
	# Top hex  
	for i in range(6):
		var angle = i * PI / 3.0
		vertices.append(Vector3(cos(angle) * size * 0.7, height/2, sin(angle) * size * 0.7))
	
	# Create faces
	# Bottom
	for i in range(4):
		add_triangle_with_normal(st, vertices, [0, i + 1, i + 2])
	
	# Top
	for i in range(4):
		add_triangle_with_normal(st, vertices, [6, 7 + i, 8 + i])
	
	# Sides
	for i in range(6):
		var next_i = (i + 1) % 6
		add_triangle_with_normal(st, vertices, [i, next_i, 6 + next_i])
		add_triangle_with_normal(st, vertices, [i, 6 + next_i, 6 + i])
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "SingleCrystal"
	return mesh_instance

# Helper function to add triangle with calculated normal
func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]  
	var v2 = vertices[face[2]]
	
	var face_center = (v0 + v1 + v2) / 3.0
	var normal = face_center.normalized()
	
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
	# Apply to all child crystals
	for child in get_children():
		var crystal_mesh = child.get_child(0) as MeshInstance3D
		if crystal_mesh:
			apply_queer_material(crystal_mesh, base_color)
