**Polyhedra & Their Nets**
From Flat to Solid

Understanding 3D shapes built from flat polygonal faces: from Platonic solids to Johnson solids

---

## What is a Polyhedron?
A polyhedron is a 3D solid made entirely of flat polygon faces.

Code:

```
# A polyhedron needs:
var vertices: Array[Vector3] = []  # Corner points
var faces: Array[Array] = []  # Which vertices form each face

# Example: Tetrahedron (4 triangular faces)
vertices = [
	Vector3(1, 1, 1), Vector3(1, -1, -1),
	Vector3(-1, 1, -1), Vector3(-1, -1, 1)
]
faces = [[0, 2, 1], [0, 1, 3], [0, 3, 2], [1, 2, 3]]
```

A polyhedron is defined by its vertices (corner points) and faces (which vertices connect to form polygons).
The simplest polyhedron is the tetrahedron with 4 vertices and 4 triangular faces.
Concepts: polyhedron, vertices, faces, 3D solid, polygons
From points to polygons to polyhedra - dimensions unfold.

---

## The Platonic Solids
The Platonic Solids are the 5 regular convex polyhedra.
Code

```
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
```

Only 5 polyhedra can be made with identical regular polygon faces.
These were known to ancient Greek mathematicians and have perfect symmetry.
Concepts: Platonic solids, regular polyhedra, tetrahedron, cube, octahedron
Five perfect forms emerge from symmetry