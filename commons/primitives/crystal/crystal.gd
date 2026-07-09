# Crystal.gd - Sharp crystalline polyhedron with faceted surfaces
extends Node3D

# @identity
# essence: a hexagonal-prism crystal with pyramidal terminations — stacked hexagons of shifting radius fan-triangulated into clean facets
# desire: the learner reads mineral form as rule-bound growth — six-fold symmetry repeated up an axis, tapering to a point
# critical_parameter: the per-ring radius (base 0.8 → mid 0.9 → upper 0.6); the taper profile is what separates quartz from a plain prism
# triggers: create_crystal on ready lays the hexagon rings, then fan-triangulates each face for sharp faceting
# emerges: that crystalline order is symmetry plus a growth axis — the same primitive that governs snowflakes and lattices
# needs: [has a faceted tapering hex-crystal [has], missing crystal_type actually switching quartz/amethyst/emerald geometry]
# relationships: sibling to diamond in the faceted-gem family; distant kin to the lattice and tiling primitives that share its symmetry
# truth: a crystal is a rule made visible — grow the same angle long enough and matter remembers the geometry


var base_color: Color = Color(0.3, 0.8, 1.0)  # Crystal blue
var crystal_type: String = "quartz"  # quartz, amethyst, emerald, diamond

func _ready():
	create_crystal()

func create_crystal():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertices = create_crystal_vertices()
	var faces = create_crystal_faces()
	
	# Create triangulated crystal faces
	for face in faces:
		if face.size() >= 3:
			# Fan triangulation for clean facets
			for i in range(1, face.size() - 1):
				add_triangle_with_normal(st, vertices, [face[0], face[i], face[i + 1]])
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "Crystal"
	apply_crystal_material(mesh_instance, base_color)
	add_child(mesh_instance)

func create_crystal_vertices() -> Array:
	var vertices = []
	var scale = 0.5
	
	# Crystal structure: hexagonal prism base with pyramidal terminations
	# Base hexagon vertices (bottom)
	var base_height = -0.4
	var base_radius = 0.8
	for i in range(6):
		var angle = i * PI * 2.0 / 6.0
		var x = cos(angle) * base_radius
		var z = sin(angle) * base_radius
		vertices.append(Vector3(x, base_height, z) * scale)
	
	# Mid-section hexagon (slightly smaller, creating taper)
	var mid_height = 0.0
	var mid_radius = 0.9
	for i in range(6):
		var angle = i * PI * 2.0 / 6.0
		var x = cos(angle) * mid_radius
		var z = sin(angle) * mid_radius
		vertices.append(Vector3(x, mid_height, z) * scale)
	
	# Upper hexagon (smaller for crystal tapering)
	var upper_height = 0.4
	var upper_radius = 0.6
	for i in range(6):
		var angle = i * PI * 2.0 / 6.0
		var x = cos(angle) * upper_radius
		var z = sin(angle) * upper_radius
		vertices.append(Vector3(x, upper_height, z) * scale)
	
	# Crystal termination points (sharp pyramid tops)
	vertices.append(Vector3(0, 1.0 * scale, 0))      # Main apex (18)
	vertices.append(Vector3(0, -0.8 * scale, 0))     # Base point (19)

	return vertices

func create_crystal_faces() -> Array:
	var faces = []
	
	# Base of crystal (hexagon at bottom - indices 0-5)
	faces.append([5, 4, 3, 2, 1, 0])  # Base hexagon (reversed for outward normal)
	
	# Lower crystal faces: base to mid-section (0-5 to 6-11)
	for i in range(6):
		var next_i = (i + 1) % 6
		faces.append([i, next_i, 6 + next_i, 6 + i])
	
	# Middle crystal faces: mid to upper section (6-11 to 12-17)
	for i in range(6):
		var next_i = (i + 1) % 6
		faces.append([6 + i, 6 + next_i, 12 + next_i, 12 + i])
	
	# Upper crystal termination: hexagon to apex (12-17 to 18)
	for i in range(6):
		var next_i = (i + 1) % 6
		faces.append([12 + i, 12 + next_i, 18])  # Triangular faces to main apex
	
	# Base termination: base hexagon to base point (0-5 to 19)
	for i in range(6):
		var next_i = (i + 1) % 6
		faces.append([i, 19, next_i])  # Triangular faces to base point

	return faces

func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]  
	var v2 = vertices[face[2]]
	
	# Calculate proper face normal for crystal facets
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()
	
	# Ensure normal points outward from crystal center
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

func apply_crystal_material(mesh_instance: MeshInstance3D, color: Color):
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	
	if shader:
		material.shader = shader
		
		# Crystal-like appearance with bright edges
		material.set_shader_parameter("base_color", color)
		material.set_shader_parameter("edge_color", Color.WHITE)
		material.set_shader_parameter("edge_width", 0.5)
		material.set_shader_parameter("edge_sharpness", 4.0)
		material.set_shader_parameter("emission_strength", 1.2)
		
		mesh_instance.material_override = material
	else:
		# Fallback crystal material
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.metallic = 0.1
		standard_material.roughness = 0.1  # Very smooth for crystal
		standard_material.emission_enabled = true
		standard_material.emission = color * 0.4
		mesh_instance.material_override = standard_material

func set_crystal_type(type: String):
	crystal_type = type
	match type:
		"quartz":
			base_color = Color(0.9, 0.9, 1.0)  # Clear/white
		"amethyst":
			base_color = Color(0.6, 0.3, 0.8)  # Purple
		"emerald":
			base_color = Color(0.2, 0.8, 0.4)  # Green
		"diamond":
			base_color = Color(1.0, 1.0, 1.0)  # Pure white
		"sapphire":
			base_color = Color(0.1, 0.3, 0.9)  # Deep blue
		"ruby":
			base_color = Color(0.9, 0.1, 0.2)  # Deep red
	
	var mesh_instance = get_child(0) as MeshInstance3D
	if mesh_instance:
		apply_crystal_material(mesh_instance, base_color)

func set_base_color(color: Color):
	base_color = color
	var mesh_instance = get_child(0) as MeshInstance3D
	if mesh_instance:
		apply_crystal_material(mesh_instance, base_color)
