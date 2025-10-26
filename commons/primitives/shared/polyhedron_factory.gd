# PolyhedronFactory.gd - Factory for creating any polyhedron including Johnson solids
extends Object
class_name PolyhedronFactory

const PrimitiveMeshBuilder = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")
const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")

## Create a polyhedron from vertices and faces
## vertices: Array[Vector3] - The vertex positions
## faces: Array[Array[int]] - Face indices (triangulated)
## config: Dictionary with optional keys:
##   - name: String - Name of the polyhedron
##   - base_color: Color - Base color for the material
##   - double_sided: bool - Whether to render both sides of faces
##   - scale: float - Uniform scale factor
##   - material: Material - Override material (skips color-based material)
static func create_polyhedron(vertices: Array, faces: Array, config: Dictionary = {}) -> Node3D:
	var container := Node3D.new()
	container.name = config.get("name", "Polyhedron")

	# Apply scale if specified
	var scale_factor: float = config.get("scale", 1.0)
	var scaled_vertices := vertices.duplicate()
	if scale_factor != 1.0:
		for i in range(scaled_vertices.size()):
			scaled_vertices[i] = scaled_vertices[i] * scale_factor

	# Build material
	var material: Material
	if config.has("material"):
		material = config["material"]
	else:
		var base_color: Color = config.get("base_color", Color.WHITE)
		var material_opts := {}
		if config.has("double_sided"):
			material_opts["double_sided"] = config["double_sided"]
		material = GridMaterialFactory.make(base_color, material_opts)

	# Build mesh
	var mesh_config := {
		"name": container.name + "_Mesh",
		"material": material,
		"double_sided": config.get("double_sided", false)
	}

	var mesh_instance := PrimitiveMeshBuilder.build_mesh_instance(
		scaled_vertices,
		faces,
		mesh_config
	)

	container.add_child(mesh_instance)
	return container

## Create a net (unfolded surface) of a polyhedron
## This creates a 2D representation of the 3D shape's faces laid flat
static func create_net(vertices: Array, faces: Array, config: Dictionary = {}) -> Node3D:
	var container := Node3D.new()
	container.name = config.get("name", "Net") + "_Net"

	# For now, this is a placeholder for net generation
	# Full net unfolding would require:
	# 1. Selecting a spanning tree of face adjacency graph
	# 2. Rotating faces to lie flat
	# 3. Positioning faces to avoid overlaps

	# Simple version: just lay out faces in a grid
	var base_color: Color = config.get("base_color", Color(1.0, 0.8, 0.6, 1.0))
	var material := GridMaterialFactory.make(base_color, {"double_sided": true})

	push_warning("PolyhedronFactory: create_net() is a placeholder - full net unfolding not yet implemented")
	return container

## Platonic solids (regular polyhedra)
static func create_tetrahedron(scale := 0.6, color := Color.MAGENTA) -> Node3D:
	var vertices: Array[Vector3] = [
		Vector3(1, 1, 1),
		Vector3(1, -1, -1),
		Vector3(-1, 1, -1),
		Vector3(-1, -1, 1)
	]
	var faces: Array = [
		[0, 2, 1],
		[0, 1, 3],
		[0, 3, 2],
		[1, 2, 3]
	]
	return create_polyhedron(vertices, faces, {
		"name": "Tetrahedron",
		"base_color": color,
		"scale": scale
	})

static func create_octahedron(scale := 0.5, color := Color.YELLOW) -> Node3D:
	var vertices: Array[Vector3] = [
		Vector3(0, 1, 0),
		Vector3(0, -1, 0),
		Vector3(1, 0, 0),
		Vector3(-1, 0, 0),
		Vector3(0, 0, 1),
		Vector3(0, 0, -1)
	]
	var faces: Array = [
		[0, 4, 2], [0, 2, 5], [0, 5, 3], [0, 3, 4],
		[1, 2, 4], [1, 5, 2], [1, 3, 5], [1, 4, 3]
	]
	return create_polyhedron(vertices, faces, {
		"name": "Octahedron",
		"base_color": color,
		"scale": scale
	})

static func create_cube(scale := 0.5, color := Color.CYAN) -> Node3D:
	var vertices: Array[Vector3] = [
		Vector3(-1, -1, 1),  Vector3(1, -1, 1),  Vector3(1, 1, 1),  Vector3(-1, 1, 1),
		Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(-1, 1, -1)
	]
	var faces: Array = [
		[0, 1, 2], [0, 2, 3],  # Front
		[5, 4, 7], [5, 7, 6],  # Back
		[4, 0, 3], [4, 3, 7],  # Left
		[1, 5, 6], [1, 6, 2],  # Right
		[3, 2, 6], [3, 6, 7],  # Top
		[4, 5, 1], [4, 1, 0]   # Bottom
	]
	return create_polyhedron(vertices, faces, {
		"name": "Cube",
		"base_color": color,
		"scale": scale
	})

static func create_icosahedron(scale := 0.5, color := Color(0.5, 1.0, 0.5)) -> Node3D:
	# 12 vertices using the correct icosahedron coordinates
	var vertices: Array[Vector3] = [
		Vector3(0.8507, 0.5257, 0.0000),   # 0
		Vector3(-0.8507, 0.5257, 0.0000),  # 1
		Vector3(0.8507, -0.5257, 0.0000),  # 2
		Vector3(-0.8507, -0.5257, 0.0000), # 3
		Vector3(0.5257, 0.0000, 0.8507),   # 4
		Vector3(0.5257, 0.0000, -0.8507),  # 5
		Vector3(-0.5257, 0.0000, 0.8507),  # 6
		Vector3(-0.5257, 0.0000, -0.8507), # 7
		Vector3(0.0000, 0.8507, 0.5257),   # 8
		Vector3(0.0000, -0.8507, 0.5257),  # 9
		Vector3(0.0000, 0.8507, -0.5257),  # 10
		Vector3(0.0000, -0.8507, -0.5257)  # 11
	]

	# 20 triangular faces
	var faces: Array = [
		[0, 8, 4],   # 0
		[0, 5, 10],  # 1
		[2, 4, 9],   # 2
		[2, 11, 5],  # 3
		[1, 6, 8],   # 4
		[1, 10, 7],  # 5
		[3, 9, 6],   # 6
		[3, 7, 11],  # 7
		[0, 10, 8],  # 8
		[1, 8, 10],  # 9
		[2, 9, 11],  # 10
		[3, 11, 9],  # 11
		[4, 2, 0],   # 12
		[5, 0, 2],   # 13
		[6, 1, 3],   # 14
		[7, 3, 1],   # 15
		[8, 6, 4],   # 16
		[9, 4, 6],   # 17
		[10, 5, 7],  # 18
		[11, 7, 5]   # 19
	]

	return create_polyhedron(vertices, faces, {
		"name": "Icosahedron",
		"base_color": color,
		"scale": scale
	})

static func create_dodecahedron(scale := 0.5, color := Color(1.0, 0.5, 1.0)) -> Node3D:
	# 20 vertices using the correct dodecahedron coordinates
	var vertices: Array[Vector3] = [
		Vector3(0.5774, 0.5774, 0.5774),    # 0
		Vector3(0.5774, 0.5774, -0.5774),   # 1
		Vector3(0.5774, -0.5774, 0.5774),   # 2
		Vector3(0.5774, -0.5774, -0.5774),  # 3
		Vector3(-0.5774, 0.5774, 0.5774),   # 4
		Vector3(-0.5774, 0.5774, -0.5774),  # 5
		Vector3(-0.5774, -0.5774, 0.5774),  # 6
		Vector3(-0.5774, -0.5774, -0.5774), # 7
		Vector3(0.3568, 0.9342, 0.0000),    # 8
		Vector3(-0.3568, 0.9342, 0.0000),   # 9
		Vector3(0.3568, -0.9342, 0.0000),   # 10
		Vector3(-0.3568, -0.9342, 0.0000),  # 11
		Vector3(0.9342, 0.0000, 0.3568),    # 12
		Vector3(0.9342, 0.0000, -0.3568),   # 13
		Vector3(-0.9342, 0.0000, 0.3568),   # 14
		Vector3(-0.9342, 0.0000, -0.3568),  # 15
		Vector3(0.0000, 0.3568, 0.9342),    # 16
		Vector3(0.0000, -0.3568, 0.9342),   # 17
		Vector3(0.0000, 0.3568, -0.9342),   # 18
		Vector3(0.0000, -0.3568, -0.9342)   # 19
	]

	# 12 pentagonal faces (each pentagon triangulated into 3 triangles from a fan)
	# Pentagon vertices listed in counter-clockwise order when viewed from outside
	var faces: Array = [
		# Pentagon 1: (0, 8, 9, 4, 16)
		[0, 8, 9], [0, 9, 4], [0, 4, 16],
		# Pentagon 2: (0, 12, 13, 1, 8)
		[0, 12, 13], [0, 13, 1], [0, 1, 8],
		# Pentagon 3: (0, 16, 17, 2, 12)
		[0, 16, 17], [0, 17, 2], [0, 2, 12],
		# Pentagon 4: (1, 13, 3, 19, 18)
		[1, 13, 3], [1, 3, 19], [1, 19, 18],
		# Pentagon 5: (1, 18, 5, 9, 8)
		[1, 18, 5], [1, 5, 9], [1, 9, 8],
		# Pentagon 6: (2, 17, 6, 11, 10)
		[2, 17, 6], [2, 6, 11], [2, 11, 10],
		# Pentagon 7: (2, 10, 3, 13, 12)
		[2, 10, 3], [2, 3, 13], [2, 13, 12],
		# Pentagon 8: (4, 9, 5, 15, 14)
		[4, 9, 5], [4, 5, 15], [4, 15, 14],
		# Pentagon 9: (4, 14, 6, 17, 16)
		[4, 14, 6], [4, 6, 17], [4, 17, 16],
		# Pentagon 10: (5, 18, 19, 7, 15)
		[5, 18, 19], [5, 19, 7], [5, 7, 15],
		# Pentagon 11: (6, 14, 15, 7, 11)
		[6, 14, 15], [6, 15, 7], [6, 7, 11],
		# Pentagon 12: (3, 10, 11, 7, 19)
		[3, 10, 11], [3, 11, 7], [3, 7, 19]
	]

	return create_polyhedron(vertices, faces, {
		"name": "Dodecahedron",
		"base_color": color,
		"scale": scale
	})

## Example Johnson solid: Square Pyramid (J1)
static func create_square_pyramid(scale := 0.5, color := Color(1.0, 0.7, 0.3)) -> Node3D:
	var h := sqrt(2.0) / 2.0  # Height for unit edge length
	var vertices: Array[Vector3] = [
		Vector3(-0.5, 0, -0.5),  # Base corners
		Vector3(0.5, 0, -0.5),
		Vector3(0.5, 0, 0.5),
		Vector3(-0.5, 0, 0.5),
		Vector3(0, h, 0)  # Apex
	]
	var faces: Array = [
		[0, 1, 2], [0, 2, 3],  # Square base (2 triangles)
		[4, 1, 0],  # Triangle faces
		[4, 2, 1],
		[4, 3, 2],
		[4, 0, 3]
	]
	return create_polyhedron(vertices, faces, {
		"name": "SquarePyramid_J1",
		"base_color": color,
		"scale": scale
	})

## Example Johnson solid: Triangular Cupola (J3)
static func create_triangular_cupola(scale := 0.5, color := Color(0.7, 0.9, 1.0)) -> Node3D:
	# Simplified triangular cupola vertices
	var h1 := 0.0
	var h2 := 0.4
	var vertices: Array[Vector3] = [
		# Bottom hexagon
		Vector3(1, h1, 0), Vector3(0.5, h1, 0.866), Vector3(-0.5, h1, 0.866),
		Vector3(-1, h1, 0), Vector3(-0.5, h1, -0.866), Vector3(0.5, h1, -0.866),
		# Top triangle
		Vector3(0.5, h2, 0.289), Vector3(-0.5, h2, 0.289), Vector3(0, h2, -0.577)
	]
	var faces: Array = [
		# Bottom hexagon
		[0, 1, 5], [1, 2, 5], [2, 3, 4], [2, 4, 5],
		# Triangular top
		[6, 7, 8],
		# Connecting faces
		[0, 6, 1], [1, 6, 7], [1, 7, 2], [2, 7, 3],
		[3, 7, 8], [3, 8, 4], [4, 8, 5], [5, 8, 6], [5, 6, 0]
	]
	return create_polyhedron(vertices, faces, {
		"name": "TriangularCupola_J3",
		"base_color": color,
		"scale": scale
	})
