extends Node

# Auto-generated from infoboard progression
var text = '''
[center][b]The Line[/b][/center]
[center][i]Connecting Points[/i][/center]

Lines create direction, distance, and paths through space

[hr]
[b]The Line: Connecting Points[/b]
- A line is the relation between two distinct points - the shortest path through space.
[color=yellow]Code[/color]
[code]
var point_a = Vector3(0, 0, 0)
var point_b = Vector3(1, 1, 0)
[/code]
[i]Concepts: two points, direction, distance, line segment[/i]

[hr]
[b]Cylinders as Lines[/b]
- A cylinder can represent a line segment by connecting two points with a visible 3D form aligned along their direction.
[color=yellow]Code[/color]
[code]
var cylinder = MeshInstance3D.new()
var cylinder_mesh = CylinderMesh.new()
cylinder_mesh.height = distance
cylinder_mesh.top_radius = 0.02   
cylinder_mesh.bottom_radius = 0.02
cylinder.mesh = cylinder_mesh

# Position at midpoint
cylinder.position = (point_a + point_b) / 2.0

# Rotate to align with direction
cylinder.look_at_from_position(
    cylinder.position, point_b, Vector3.UP
)

add_child(cylinder)
[/code]
[i]Concepts: CylinderMesh, look_at, rotation, thickness[/i]

[hr]
[b]Multiple Lines and Paths[/b]
AXIOM 4 4: A sequence of connected lines forms a path.
[color=yellow]Code[/color]
[code]
var points = [
    Vector3(0, 0, 0),
    Vector3(1, 1, 0),
    Vector3(2, 0.5, 0),
    Vector3(3, 1.5, 0)
[/code]
Lines can connect multiple points to create paths and shapes.
]
immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP) for point in points: immediate_mesh.surface_add_vertex(point) immediate_mesh.surface_end()
LINE_STRIP connects consecutive points with lines. LINES requires pairs of points (every 2 vertices = 1 line).
Paths are fundamental to curves, splines, and trajectories.
[i]Concepts: LINE_STRIP, paths, curves, trajectories[/i]
'''
