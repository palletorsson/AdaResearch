extends Node

# Auto-generated from infoboard progression
var text = '''
[center][b]The Cube[/b][/center]
[center][i]Six Faces, First Volume[/i][/center]

The cube as the simplest volumetric primitive

[hr]
[b]Six Square Faces[/b]
AXIOM 1: A cube has 6 faces, 12 edges, 8 vertices.
[color=yellow]Code[/color]
[code]
var box = BoxMesh.new()
box.size = Vector3(1, 1, 1)
[/code]
First closed volumetric primitive All faces perpendicular to neighbors
[i]Concepts: six faces, volume, edges, vertices[/i]

[hr]
[b]Mesh Structure[/b]
AXIOM 2: Cube = 12 triangles (2 per face).
Each face: - 2 triangles - 4 vertices (shared) - Outward-facing normals
Total: 24 vertices (4 x 6 unique normals)
[i]Concepts: mesh structure, face normals, vertex sharing[/i]

[hr]
[b]Collision and Physics[/b]
AXIOM 3: Volume enables collision detection.
[color=yellow]Code[/color]
[code]
var shape = BoxShape3D.new()
shape.size = Vector3(1, 1, 1)
[/code]
Volumetric presence: - Collision detection - Physics simulation - Spatial partitioning
[i]Concepts: collision, physics, volume, bounding box[/i]
'''
