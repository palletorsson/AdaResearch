extends Node

# Auto-generated from infoboard progression
var text = '''
[center][b]The Cylinder[/b][/center]
[center][i]Circular Extrusion[/i][/center]

The cylinder as a hybrid of planar and curved surfaces

[hr]
[b]Two Circles, One Curve[/b]
AXIOM 1: Two parallel circles + curved surface.
[color=yellow]Code[/color]
[code]
var cyl = CylinderMesh.new()
cyl.top_radius = 0.5
cyl.bottom_radius = 0.5
cyl.height = 2.0
[/code]
Extruded circle along axis
[i]Concepts: circles, extrusion, axis, curved surface[/i]

[hr]
[b]Caps and Sides[/b]
AXIOM 2: Cylinder = 2 caps + 1 side surface.
[color=yellow]Code[/color]
[code]
cyl.top_radius = 0.5
cyl.bottom_radius = 0.3  # Cone
cyl.cap_top = true
cyl.cap_bottom = true
[/code]
Varying radii creates cones Caps can be toggled
[i]Concepts: caps, side surface, cone, radii[/i]

[hr]
[b]Radial Segments[/b]
AXIOM 3: Circular sections tessellate to triangles.
[color=yellow]Code[/color]
[code]
cyl.radial_segments = 32
cyl.rings = 8

More segments = smoother circles
[/code]
Rings add horizontal subdivisions
[i]Concepts: radial segments, rings, tessellation, smoothness[/i]
'''
