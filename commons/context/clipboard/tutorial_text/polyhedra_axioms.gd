extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''
[center][b]Polyhedra & Their Nets[/b][/center]
[center][i]From Flat to Solid[/i][/center]

Understanding 3D shapes built from flat polygonal faces: from Platonic solids to Johnson solids

[hr]
[b]What is a Polyhedron?[/b]
A polyhedron is a 3D solid made entirely of flat polygon faces.
[color=yellow]Code[/color]
[code]
# A polyhedron needs:
var vertices: Array[Vector3] = []  # Corner points
var faces: Array[Array[int]] = []  # Which vertices form each face

# Example: Tetrahedron (4 triangular faces)
vertices = [
	Vector3(1, 1, 1), Vector3(1, -1, -1),
	Vector3(-1, 1, -1), Vector3(-1, -1, 1)
]
faces = [[0, 2, 1], [0, 1, 3], [0, 3, 2], [1, 2, 3]]
[/code]
A polyhedron is defined by its vertices (corner points) and faces (which vertices connect to form polygons).
The simplest polyhedron is the tetrahedron with 4 vertices and 4 triangular faces.
[i]Concepts: polyhedron, vertices, faces, 3D solid, polygons[/i]
[i]From points to polygons to polyhedra - dimensions unfold.[/i]

[hr]
[b]The Platonic Solids[/b]
The Platonic Solids are the 5 regular convex polyhedra.
[color=yellow]Code[/color]
[code]
# The 5 Platonic Solids:
# 1. Tetrahedron: 4 triangular faces
# 2. Cube: 6 square faces
# 3. Octahedron: 8 triangular faces
# 4. Dodecahedron: 12 pentagonal faces  
# 5. Icosahedron: 20 triangular faces

# Create them with PolyhedronFactory:
var tetra = PolyhedronFactory.create_tetrahedron()
var cube = PolyhedronFactory.create_cube()
var octa = PolyhedronFactory.create_octahedron()
[/code]
Only 5 polyhedra can be made with identical regular polygon faces.
These were known to ancient Greek mathematicians and have perfect symmetry.
[i]Concepts: Platonic solids, regular polyhedra, tetrahedron, cube, octahedron[/i]
[i]Five perfect forms emerge from symmetry's law.[/i]

[hr]
[b]Nets: Unfolding 3D into 2D[/b]
A net is the 2D pattern that folds into a 3D polyhedron.
[color=yellow]Code[/color]
[code]
# Tetrahedron Net: 4 connected triangles laid flat
# When you fold along the edges, they meet to form 3D

# Think of it like unfolding a cardboard box
# The net shows all faces connected by their edges
# Fold lines become the edges of the 3D solid
[/code]
A net is like unfolding a cardboard box flat on a table.
For a tetrahedron, one possible net is 4 triangles arranged in a strip.
Folding along the edges creates the 3D solid.
[i]Concepts: net, unfolding, 2D to 3D, fold lines, flat pattern[/i]
[i]Unfold the solid, see its surface laid bare.[/i]

[hr]
[b]Cube Nets: 11 Ways to Unfold[/b]
The cube has 11 different nets.
[color=yellow]Code[/color]
[code]
# Cube Net Example: 'cross' pattern
# 6 connected squares fold into a cube

#     [top]
# [L] [F] [R] [back]
#     [bottom]

# All 11 nets fold into the same cube
# but look different when laid flat
[/code]
A cube can be unfolded in 11 different ways!
The most famous is the 'cross' or 'Latin cross' pattern.
Each net folds into the same cube.
[i]Concepts: cube net, multiple nets, cross pattern, 6 squares[/i]
[i]One cube, eleven skins - diversity in unity.[/i]

[hr]
[b]Octahedron: Eight Faces[/b]
The octahedron net is 8 connected triangles.
[color=yellow]Code[/color]
[code]
# Octahedron: 8 triangular faces
# 6 vertices arranged like two square pyramids

var octa_vertices = [
	Vector3(0, 1, 0),   # Top
	Vector3(0, -1, 0),  # Bottom  
	Vector3(1, 0, 0),   # +X
	Vector3(-1, 0, 0),  # -X
	Vector3(0, 0, 1),   # +Z
	Vector3(0, 0, -1)   # -Z
]

# 8 faces (4 top + 4 bottom)
var octa = PolyhedronFactory.create_octahedron()
[/code]
The octahedron is two square pyramids stuck base-to-base.
Its net can be arranged as a strip of 8 triangles.
It's the 'dual' of the cube.
[i]Concepts: octahedron, 8 triangles, strip net, dual to cube[/i]
[i]Eight triangles dance, a crystal suspended.[/i]

[hr]
[b]Johnson Solids[/b]
Johnson Solids: 92 convex polyhedra with regular faces.
[color=yellow]Code[/color]
[code]
# There are 92 Johnson Solids
# Mix different regular polygons

# J1: Square Pyramid
var pyramid = PolyhedronFactory.create_square_pyramid()

# J3: Triangular Cupola  
var cupola = PolyhedronFactory.create_triangular_cupola()

# Create any polyhedron:
var vertices = [Vector3(0,0,0), ...]
var faces = [[0,1,2], [1,2,3], ...]
var solid = PolyhedronFactory.create_polyhedron(
	vertices, faces,
	{"name": "Custom", "base_color": Color.GREEN}
)
[/code]
Johnson Solids have regular polygon faces but mix different types.
There are exactly 92 of them.
PolyhedronFactory can create any of them!
[i]Concepts: Johnson solids, 92 polyhedra, regular faces, square pyramid, cupola[/i]
[i]Beyond perfection's five, ninety-two more await.[/i]
'''
