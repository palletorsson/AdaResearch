extends Node

# Auto-generated from infoboard progression
var text = '''
[center][b]The Quad[/b][/center]
[center][i]Four Points, Two Triangles[/i][/center]

The quad as a planar surface composed of two triangles

[hr]
[b]Four Coplanar Points[/b]
AXIOM 1: A quad requires four coplanar points.
[color=yellow]Code[/color]
[code]
var v0 = Vector3(-0.5, -0.5, 0)
var v1 = Vector3(0.5, -0.5, 0)
var v2 = Vector3(0.5, 0.5, 0)
var v3 = Vector3(-0.5, 0.5, 0)
[/code]
Non-planar quads cause rendering artifacts
[i]Concepts: four points, coplanar, quad, planarity[/i]

[hr]
[b]Triangulation[/b]
AXIOM 2: GPUs render quads as two triangles.
[color=yellow]Code[/color]
[code]
# Triangle 1: v0, v1, v2
# Triangle 2: v0, v2, v3
[/code]
Triangulation pattern affects shading Diagonal choice matters for non-planar quads
[i]Concepts: triangulation, diagonal, GPU rendering[/i]

[hr]
[b]Modeling with Quads[/b]
AXIOM 3: Quads simplify mesh topology.
Advantages: - Easier subdivision - Cleaner edge loops - Natural for rectangular surfaces
Limitation: Must remain planar
[i]Concepts: topology, subdivision, edge loops, mesh modeling[/i]
'''
