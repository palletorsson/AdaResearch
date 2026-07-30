extends Node3D

# @identity
# essence: SurfaceTool.add_vertex(v) for each face of 9 hand-built polyhedra — diamond, prism, octahedron, rough rock, crystal cluster, bipyramid, truncated tetrahedron, geode, crystal shard — each colored with pride flag palette
# desire: to see nine queer-colored geometric specimens arranged on a rainbow floor under pride-flag lighting — to hold mathematical form in a space that celebrates identity
# critical_parameter: pride_colors array — six colors (red/orange/yellow/green/blue/purple) applied to each solid's wireframe shader, making geometry a vehicle for queer visibility
# triggers: _ready builds all solids, rainbow floor, floating pride/trans banners, and six colored OmniLight3D in a circle; static display with no animation
# emerges: the combination of hand-built polyhedra, pride lighting, and trans banners creates a mathematical cabinet of curiosities that is also a political statement
# needs: [missing] no VR interaction — pure display; no sliders, no buttons, no grabbable objects
# relationships: used in F14_Lab_Bench and F17_Zen_Garden as mathematical specimen; one of the core primitive artifacts alongside rainbow and homagetothesquare
# truth: geometry does not belong to neutrality — every vertex can carry color, and color is never apolitical

# PlatonicSolids.gd - Queer-themed geometric primitives in Godot 4
# Based on Ada Research VR project structure

## STAGE-2 DNA PROMOTION (2026-07-29).
##
## Before this the artifact had zero exports: nine hand-built polyhedra that ALWAYS
## arrived carrying their own room with them — a rainbow floor plane, four floating
## banners and a ring of six pride-coloured lights — whether the map that placed them
## wanted a room or a specimen. Two things were hard-coded that are really arguments:
##
##   staging   whether the geometry brings its own room   pride_room · lit · bare
##   palette   whose colours the geometry is carrying     pride · trans · mono
##
## staging is the question the @identity dodges: is the politics in the ROOM (a floor,
## banners, a light ring the map cannot refuse) or in the OBJECTS (nine coloured solids
## standing in whatever space the map already built)? `bare` puts the claim entirely on
## the vertices; `lit` keeps the coloured light and drops the scenery.
##
## palette is the artifact's own declared critical_parameter, which had never been
## reachable. `mono` is the honest counterfactual to the truth statement "geometry does
## not belong to neutrality" — the same nine solids, the same six lights, the same floor
## bands, drained to one grey. Neutrality is a value you can select and look at.
##
## staging=pride_room, palette=pride is the pre-promotion behaviour EXACTLY, and it is
## the default, so the 6 existing placements are unchanged.
##
## Usage in map_data.json:
##   "platonicsolids#staging:bare"
##   "platonicsolids#staging:lit#palette:trans"

## Does the geometry bring its own room? pride_room = rainbow floor + banners + light
## ring (the legacy default); lit = the coloured light ring only, the map keeps its own
## floor; bare = nine specimens and nothing else.
@export_enum("pride_room", "lit", "bare") var staging: String = "pride_room"
## Whose colours the solids, the floor bands and the lights are carrying.
@export_enum("pride", "trans", "mono") var palette: String = "pride"

# Constants for the Platonic solids
const PHI = 1.618033988749895  # Golden ratio, used for dodecahedron and icosahedron

# Neutrality, held at the same structure: six entries so the light ring and the floor
# banding keep their shape and only the colour is gone.
const MONO_COLORS := [
	Color(0.62, 0.62, 0.62),
	Color(0.62, 0.62, 0.62),
	Color(0.62, 0.62, 0.62),
	Color(0.62, 0.62, 0.62),
	Color(0.62, 0.62, 0.62),
	Color(0.62, 0.62, 0.62)
]

var _built: bool = false

# Pride flag colors
var pride_colors = [
	Color(0.9, 0.0, 0.0),    # Red
	Color(1.0, 0.5, 0.0),    # Orange
	Color(1.0, 1.0, 0.0),    # Yellow
	Color(0.0, 0.8, 0.0),    # Green
	Color(0.0, 0.4, 1.0),    # Blue
	Color(0.6, 0.0, 0.8)     # Purple
]

# Trans flag colors
var trans_colors = [
	Color(0.35, 0.8, 1.0),   # Light blue
	Color(1.0, 0.7, 0.8),    # Pink
	Color(1.0, 1.0, 1.0),    # White
	Color(1.0, 0.7, 0.8),    # Pink
	Color(0.35, 0.8, 1.0)    # Light blue
]

# Positions for the primitives (hand-sized spacing)
var positions = [
	Vector3(-3, 0, 0),   # Diamond
	Vector3(-1.5, 0, 0), # Prism
	Vector3(0, 0, 0),    # Octahedron
	Vector3(1.5, 0, 0),  # Rough Rock
	Vector3(3, 0, 0),    # Crystal Cluster
	Vector3(-2.25, 0, 1.5), # Bipyramid
	Vector3(-0.75, 0, 1.5), # Truncated Tetrahedron
	Vector3(0.75, 0, 1.5),  # Geode
	Vector3(2.25, 0, 1.5)   # Shard
]

func _ready() -> void:
	create_queer_environment()
	create_all_solids()
	_built = true

# --- DNA (stage 2) -----------------------------------------------------------

## The active palette. pride is the six-colour flag (legacy), trans the five-colour
## flag, mono the six-entry grey that keeps the structure and removes the claim.
func _palette() -> Array:
	if palette == "trans":
		return trans_colors
	if palette == "mono":
		return MONO_COLORS
	return pride_colors

## Colour for solid N. Indices were written against the six-entry pride array, so they
## wrap — the five-colour trans flag reuses its first colour for the sixth solid.
func _solid_color(index: int) -> Color:
	var pal: Array = _palette()
	return pal[index % pal.size()]

## The banners keep speaking trans unless neutrality is selected, in which case there is
## nothing left for them to say.
func _banner_colors() -> Array:
	if palette == "mono":
		return MONO_COLORS
	return trans_colors

func create_queer_environment() -> void:
	match staging:
		"bare":
			# The solids stand in the map's own room. No floor plane, no banners, no lights.
			pass
		"lit":
			create_colorful_lighting()
		_:
			# Create rainbow floor
			create_rainbow_floor()

			# Create floating pride banners
			create_floating_banners()

			# Add colorful lighting
			create_colorful_lighting()

func create_rainbow_floor() -> void:
	var floor = MeshInstance3D.new()
	floor.name = "RainbowFloor"
	add_child(floor)
	
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(10, 10)
	plane_mesh.subdivide_width = 6
	plane_mesh.subdivide_depth = 1
	floor.mesh = plane_mesh
	
	# Create rainbow material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.vertex_color_use_as_albedo = true
	material.flags_unshaded = true
	floor.material_override = material
	
	floor.position = Vector3(0, -1, 0)
	
	# Apply rainbow colors to vertices
	apply_rainbow_to_mesh(floor)

func apply_rainbow_to_mesh(mesh_instance: MeshInstance3D) -> void:
	var mesh = mesh_instance.mesh as PlaneMesh
	var array_mesh = ArrayMesh.new()
	var arrays = mesh.surface_get_arrays(0)
	
	# Get vertices and create color array
	var vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var colors = PackedColorArray()
	var pal: Array = _palette()

	for i in range(vertices.size()):
		var vertex = vertices[i]
		var x_pos = vertex.x
		# Map X position to rainbow color
		var color_index = int((x_pos + 5) / 1.67) % pal.size()
		colors.append(pal[color_index])
	
	arrays[Mesh.ARRAY_COLOR] = colors
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = array_mesh

func create_floating_banners() -> void:
	# Create floating pride flag banners
	for i in range(2):
		create_pride_banner(Vector3(-3 + i * 6, 2, -2))
		
	# Create trans flag banners
	for i in range(2):
		create_trans_banner(Vector3(-2 + i * 4, 1.5, 2))

func create_pride_banner(pos: Vector3) -> void:
	var banner = MeshInstance3D.new()
	banner.name = "PrideBanner"
	add_child(banner)
	
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(1.5, 1)
	banner.mesh = quad_mesh
	
	var pal: Array = _palette()
	var material = StandardMaterial3D.new()
	material.albedo_color = pal[randi() % pal.size()]
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.3
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.8
	banner.material_override = material
	
	banner.position = pos
	banner.rotation_degrees = Vector3(0, randf_range(-20, 20), 0)

func create_trans_banner(pos: Vector3) -> void:
	var banner = MeshInstance3D.new()
	banner.name = "TransBanner"
	add_child(banner)
	
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(1.2, 0.8)
	banner.mesh = quad_mesh
	
	var pal: Array = _banner_colors()
	var material = StandardMaterial3D.new()
	material.albedo_color = pal[randi() % pal.size()]
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.2
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.7
	banner.material_override = material
	
	banner.position = pos
	banner.rotation_degrees = Vector3(randf_range(-10, 10), randf_range(-30, 30), 0)

func create_colorful_lighting() -> void:
	# Create multiple colored lights
	var pal: Array = _palette()
	for i in range(pal.size()):
		var light = OmniLight3D.new()
		light.name = "PrideLight_" + str(i)
		add_child(light)

		light.light_color = pal[i]
		light.light_energy = 0.4
		light.omni_range = 8.0
		light.omni_attenuation = 0.5

		# Position lights in a circle around the scene
		var angle = (i / float(pal.size())) * 2 * PI
		light.position = Vector3(cos(angle) * 6, 3, sin(angle) * 6)

# Create all custom primitives
func create_all_solids() -> void:
	var diamond = create_diamond()
	diamond.position = positions[0]
	add_child(diamond)
	
	var prism = create_triangular_prism()
	prism.position = positions[1]
	add_child(prism)
	
	var octahedron = create_octahedron()
	octahedron.position = positions[2]
	add_child(octahedron)
	
	var rock = create_rough_rock()
	rock.position = positions[3]
	add_child(rock)
	
	var crystal = create_crystal_cluster()
	crystal.position = positions[4]
	add_child(crystal)
	
	var bipyramid = create_bipyramid()
	bipyramid.position = positions[5]
	add_child(bipyramid)
	
	var truncated = create_truncated_tetrahedron()
	truncated.position = positions[6]
	add_child(truncated)
	
	var geode = create_geode()
	geode.position = positions[7]
	add_child(geode)
	
	var shard = create_crystal_shard()
	shard.position = positions[8]
	add_child(shard)

# Helper function to add triangle with calculated normal
func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array) -> void:
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

# Create diamond (elongated octahedron)
func create_diamond():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Define vertices for diamond shape
	var vertices = [
		Vector3(0, 0.6, 0),     # Top point
		Vector3(0, -0.4, 0),    # Bottom point
		Vector3(0.25, 0.1, 0.25),  # Upper ring
		Vector3(-0.25, 0.1, 0.25),
		Vector3(-0.25, 0.1, -0.25),
		Vector3(0.25, 0.1, -0.25),
		Vector3(0.15, -0.1, 0.15), # Lower ring  
		Vector3(-0.15, -0.1, 0.15),
		Vector3(-0.15, -0.1, -0.15),
		Vector3(0.15, -0.1, -0.15)
	]
	
	# Define faces for diamond
	var faces = [
		# Top pyramid
		[0, 2, 3], [0, 3, 4], [0, 4, 5], [0, 5, 2],
		# Middle band
		[2, 6, 7, 3], [3, 7, 8, 4], [4, 8, 9, 5], [5, 9, 6, 2],
		# Bottom pyramid
		[1, 7, 6], [1, 8, 7], [1, 9, 8], [1, 6, 9]
	]
	
	# Create triangles
	for face in faces:
		if face.size() == 3:  # Triangle
			add_triangle_with_normal(st, vertices, face)
		else:  # Quad - split into triangles
			add_triangle_with_normal(st, vertices, [face[0], face[1], face[2]])
			add_triangle_with_normal(st, vertices, [face[0], face[2], face[3]])
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "Diamond"
	apply_queer_material(mesh_instance, _solid_color(0))
	return mesh_instance

# Create triangular prism
func create_triangular_prism():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var height = 0.6
	var base_size = 0.3
	
	# Define vertices
	var vertices = [
		# Bottom triangle
		Vector3(base_size, -height/2, 0),
		Vector3(-base_size/2, -height/2, base_size * 0.866),
		Vector3(-base_size/2, -height/2, -base_size * 0.866),
		# Top triangle  
		Vector3(base_size, height/2, 0),
		Vector3(-base_size/2, height/2, base_size * 0.866),
		Vector3(-base_size/2, height/2, -base_size * 0.866)
	]
	
	# Define faces
	var faces = [
		[2, 1, 0],  # Bottom
		[3, 4, 5],  # Top
		[0, 1, 4, 3],  # Side 1
		[1, 2, 5, 4],  # Side 2  
		[2, 0, 3, 5]   # Side 3
	]
	
	# Create triangles
	for face in faces:
		if face.size() == 3:
			add_triangle_with_normal(st, vertices, face)
		else:
			add_triangle_with_normal(st, vertices, [face[0], face[1], face[2]])
			add_triangle_with_normal(st, vertices, [face[0], face[2], face[3]])
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "TriangularPrism"
	apply_queer_material(mesh_instance, _solid_color(1))
	return mesh_instance

# Create octahedron (8 faces, 6 vertices, 12 edges)
func create_octahedron():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Define vertices using proper coordinates (hand-sized)
	var vertices = [
		Vector3(0, 0.5, 0),   # 0: top
		Vector3(0, -0.5, 0),  # 1: bottom
		Vector3(0.5, 0, 0),   # 2: right
		Vector3(-0.5, 0, 0),  # 3: left
		Vector3(0, 0, 0.5),   # 4: front
		Vector3(0, 0, -0.5)   # 5: back
	]
	
	# Define faces (triangles)
	var faces = [
		[0, 4, 2],
		[0, 2, 5],
		[0, 5, 3],
		[0, 3, 4],
		[1, 2, 4],
		[1, 5, 2],
		[1, 3, 5],
		[1, 4, 3]
	]
	
	# Create the mesh
	for face in faces:
		add_triangle_with_normal(st, vertices, face)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "Octahedron"
	apply_queer_material(mesh_instance, _solid_color(2))
	return mesh_instance

# Create rough rock (irregular polyhedron)
func create_rough_rock():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create irregular vertices with noise
	var vertices = []
	var base_points = [
		Vector3(0.3, 0.2, 0.1),
		Vector3(-0.2, 0.3, 0.15),
		Vector3(-0.25, -0.1, 0.25),
		Vector3(0.1, -0.3, 0.2),
		Vector3(0.25, -0.1, -0.2),
		Vector3(-0.1, 0.2, -0.3),
		Vector3(0.15, 0.35, -0.1),
		Vector3(-0.3, -0.2, -0.1)
	]
	
	# Add roughness to points
	for point in base_points:
		var rough_point = point + Vector3(
			randf_range(-0.05, 0.05),
			randf_range(-0.05, 0.05), 
			randf_range(-0.05, 0.05)
		)
		vertices.append(rough_point)
	
	# Create faces connecting points (simplified convex hull approach)
	var faces = [
		[0, 1, 6], [1, 2, 3], [3, 4, 0], [4, 5, 6],
		[6, 1, 2], [2, 7, 3], [3, 7, 4], [4, 7, 5],
		[5, 7, 2], [2, 1, 5], [5, 1, 6], [6, 0, 4]
	]
	
	for face in faces:
		add_triangle_with_normal(st, vertices, face)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "RoughRock"
	apply_queer_material(mesh_instance, _solid_color(3))
	return mesh_instance

# Create crystal cluster
func create_crystal_cluster():
	var cluster = Node3D.new()
	cluster.name = "CrystalCluster"
	
	# Create multiple small crystals
	for i in range(5):
		var crystal = create_single_crystal(randf_range(0.1, 0.25))
		crystal.position = Vector3(
			randf_range(-0.2, 0.2),
			randf_range(-0.1, 0.1), 
			randf_range(-0.2, 0.2)
		)
		crystal.rotation_degrees = Vector3(
			randf_range(0, 360),
			randf_range(0, 360),
			randf_range(0, 360)
		)
		cluster.add_child(crystal)
	
	apply_queer_material(cluster.get_child(0), _solid_color(4))
	return cluster

func create_single_crystal(size: float):
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
	return mesh_instance

# Create bipyramid (double pyramid)
func create_bipyramid():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertices = [
		Vector3(0, 0.4, 0),      # Top apex
		Vector3(0, -0.4, 0),     # Bottom apex
		Vector3(0.3, 0, 0.3),    # Square base
		Vector3(-0.3, 0, 0.3),
		Vector3(-0.3, 0, -0.3),
		Vector3(0.3, 0, -0.3)
	]
	
	var faces = [
		[0, 2, 3], [0, 3, 4], [0, 4, 5], [0, 5, 2],  # Top pyramid
		[1, 3, 2], [1, 4, 3], [1, 5, 4], [1, 2, 5]   # Bottom pyramid
	]
	
	for face in faces:
		add_triangle_with_normal(st, vertices, face)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "Bipyramid"
	apply_queer_material(mesh_instance, _solid_color(5))
	return mesh_instance

# Create truncated tetrahedron
func create_truncated_tetrahedron():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Simplified version - create a smaller tetrahedron with cut corners
	var vertices = [
		Vector3(0.2, 0.2, 0.2),
		Vector3(-0.2, -0.2, 0.2),
		Vector3(-0.2, 0.2, -0.2),
		Vector3(0.2, -0.2, -0.2),
		# Cut corners
		Vector3(0.1, 0.1, -0.1),
		Vector3(-0.1, -0.1, -0.1),
		Vector3(-0.1, 0.1, 0.1),
		Vector3(0.1, -0.1, 0.1)
	]
	
	var faces = [
		[0, 4, 6], [1, 5, 7], [2, 6, 4], [3, 7, 5],
		[4, 5, 6, 7], [0, 1, 2, 3]
	]
	
	for face in faces:
		if face.size() == 3:
			add_triangle_with_normal(st, vertices, face)
		else:
			add_triangle_with_normal(st, vertices, [face[0], face[1], face[2]])
			add_triangle_with_normal(st, vertices, [face[0], face[2], face[3]])
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "TruncatedTetrahedron"
	apply_queer_material(mesh_instance, _solid_color(1))
	return mesh_instance

# Create geode (hollow sphere with crystals inside)
func create_geode():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create a simple hemisphere with some internal points
	var vertices = []
	
	# Outer shell vertices
	for i in range(8):
		var angle = i * PI * 0.25
		vertices.append(Vector3(cos(angle) * 0.3, 0, sin(angle) * 0.3))
	
	# Top point
	vertices.append(Vector3(0, 0.3, 0))
	
	# Internal crystals
	vertices.append(Vector3(0, -0.1, 0))
	vertices.append(Vector3(0.1, -0.1, 0.1))
	vertices.append(Vector3(-0.1, -0.1, -0.1))
	
	var faces = [
		[8, 0, 1], [8, 1, 2], [8, 2, 3], [8, 3, 4],
		[8, 4, 5], [8, 5, 6], [8, 6, 7], [8, 7, 0],
		[9, 10, 11]
	]
	
	for face in faces:
		add_triangle_with_normal(st, vertices, face)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "Geode"
	apply_queer_material(mesh_instance, _solid_color(2))
	return mesh_instance

# Create crystal shard (elongated irregular crystal)
func create_crystal_shard():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertices = [
		Vector3(0, 0.5, 0),       # Top point
		Vector3(0.1, 0.3, 0.1),   # Upper section
		Vector3(-0.1, 0.3, 0.1),
		Vector3(-0.1, 0.3, -0.1),
		Vector3(0.1, 0.3, -0.1),
		Vector3(0.15, 0, 0.15),   # Middle section
		Vector3(-0.15, 0, 0.15),
		Vector3(-0.15, 0, -0.15),
		Vector3(0.15, 0, -0.15),
		Vector3(0, -0.4, 0)       # Bottom point
	]
	
	var faces = [
		[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 1],  # Top
		[1, 5, 6, 2], [2, 6, 7, 3], [3, 7, 8, 4], [4, 8, 5, 1],  # Middle
		[9, 6, 5], [9, 7, 6], [9, 8, 7], [9, 5, 8]   # Bottom
	]
	
	for face in faces:
		if face.size() == 3:
			add_triangle_with_normal(st, vertices, face)
		else:
			add_triangle_with_normal(st, vertices, [face[0], face[1], face[2]])
			add_triangle_with_normal(st, vertices, [face[0], face[2], face[3]])
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "CrystalShard"
	apply_queer_material(mesh_instance, _solid_color(4))
	return mesh_instance

func apply_queer_material(mesh_instance: MeshInstance3D, base_color: Color) -> void:
	# Create shader material using the solid wireframe shader
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/grid_solid.gdshader")
	material.shader = shader
	
	# Set shader parameters
	material.set_shader_parameter("base_color", base_color)
	material.set_shader_parameter("edge_color", Color.WHITE)
	material.set_shader_parameter("edge_width", 1.5)
	material.set_shader_parameter("edge_sharpness", 2.0)
	material.set_shader_parameter("emission_strength", 1.0)
	
	mesh_instance.material_override = material

func _process(_delta):
	# No animation - static display
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Config from map_data.json tokens: #staging:bare#palette:trans
##
## GUARDED. Only rebuilds when a value actually CHANGED and _ready has already built
## once — an unguarded rebuild here would tear down and re-add every child of every
## shipped placement for no reason, which is how promotions break maps.
func apply_grid_config(config: Dictionary) -> void:
	var changed: bool = false
	if config.has("staging"):
		var want_staging: String = str(config["staging"])
		if want_staging != staging:
			staging = want_staging
			changed = true
	if config.has("palette"):
		var want_palette: String = str(config["palette"])
		if want_palette != palette:
			palette = want_palette
			changed = true
	if changed and _built:
		_rebuild()

func _rebuild() -> void:
	var kids: Array = get_children()
	for child in kids:
		if not child.owner:
			remove_child(child)
			child.queue_free()
	create_queer_environment()
	create_all_solids()
