extends Node

# Auto-generated from infoboard progression
var text = '''
[center][b]The Sphere[/b][/center]
[center][i]Perfect Curvature[/i][/center]

The sphere as a perfectly curved surface

[hr]
[b]Equidistant Points[/b]
AXIOM 1: All points equidistant from center.
[color=yellow]Code[/color]
[code]
var sphere = SphereMesh.new()
sphere.radius = 1.0
sphere.height = 2.0
[/code]
Defines: radius, center Perfectly smooth (conceptually)
[i]Concepts: radius, center, equidistant, curved surface[/i]

[hr]
[b]Tessellation[/b]
AXIOM 2: Digital spheres approximate with triangles.
[color=yellow]Code[/color]
[code]
sphere.radial_segments = 32
sphere.rings = 16
# Creates triangle mesh

More segments = smoother appearance
[/code]
Parameterized by latitude/longitude
[i]Concepts: tessellation, segments, rings, approximation[/i]

[hr]
[b]Surface Normals[/b]
AXIOM 3: Normal always points from center.
For point P on sphere: normal = (P - center).normalized()
Perfect for smooth shading Defines light reflection at every point
[i]Concepts: surface normals, smooth shading, lighting, radial[/i]
'''
