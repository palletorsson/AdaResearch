var text = '''[b]The Line[/b]
[i]Connecting Points in Space[/i]

A line connects two points in space, creating direction and distance.

[code]
var point_a = Vector3(0, 0, 0)
var point_b = Vector3(1, 1, 0)

var direction = point_b - point_a
var distance = direction.length()
[/code]

[hr]

[b]Drawing Lines[/b]

Using ImmediateMesh for simple, flexible line drawing:

[code]
var mesh_instance = MeshInstance3D.new()
var immediate_mesh = ImmediateMesh.new()
mesh_instance.mesh = immediate_mesh

immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
immediate_mesh.surface_add_vertex(point_a)
immediate_mesh.surface_add_vertex(point_b)
immediate_mesh.surface_end()

add_child(mesh_instance)
[/code]

[hr]

[b]Direction and Magnitude[/b]

A line has both direction and magnitude (length).

[code]
var direction = (point_b - point_a).normalized()
var distance = point_a.distance_to(point_b)

# Move along the line
var t = 0.5  # halfway
var midpoint = point_a + direction * distance * t
[/code]

The parameter 't' (0 to 1) finds any point along the line:
- t = 0.0 → point_a (start)
- t = 0.5 → midpoint
- t = 1.0 → point_b (end)

This is called [i]linear interpolation[/i] or 'lerp'.

[hr]

[b]Cylinders as Lines[/b]

For thicker, more visible lines, use cylinders:

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

[hr]

[b]Multiple Lines and Paths[/b]

Lines connect multiple points to create paths and shapes.

[code]
var points = [
    Vector3(0, 0, 0),
    Vector3(1, 1, 0),
    Vector3(2, 0.5, 0),
    Vector3(3, 1.5, 0)
]

immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
for point in points:
    immediate_mesh.surface_add_vertex(point)
immediate_mesh.surface_end()
[/code]

LINE_STRIP connects consecutive points.
LINES requires pairs (every 2 vertices = 1 line).

Paths are fundamental to curves, splines, and trajectories.
'''
