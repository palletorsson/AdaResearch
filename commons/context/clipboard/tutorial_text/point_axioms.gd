extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[b]The Point[/b]
[i]The atom of space[/i]

A point is the smallest unit of computational geometry.

In three-dimensional space, a point [b]is a position[/b], defined by three numbers:
[b]x, y, and z[/b].

A point has:
• no size
• no shape
• no direction

It is defined only by [i]where it is[/i].

[hr]

[b]Position in the engine[/b]

In a game engine like Godot, every point always has a position.
The engine stores this position continuously as a vector.

[color=yellow]Code[/color]
[code]
var point_position = Vector3(3.0, 1.5, 4.0)
[/code]

This vector [i]is[/i] the point.

[hr]

[b]Making a point visible[/b]

To see a point, we represent it with a small sphere.
The sphere is not the point — it is a visual marker for a position.

[color=yellow]Code[/color]
[code]
var sphere_mesh = SphereMesh.new()
var radius = 0.01
sphere_mesh.radius = radius
sphere_mesh.height = radius * 2.0
[/code]

[hr]

[b]Placing the point[/b]

The marker is placed at the point’s coordinates.

[color=yellow]Code[/color]
[code]
var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = sphere_mesh
mesh_instance.position = point_position
add_child(mesh_instance)
[/code]

The scene now shows [b]where[/b] the point is.

Nothing has been added to the point itself.
Only its position has been made visible.

[hr]

[b]What comes next[/b]

The point already has a position.
The next step is not to give it one.

The next step is to make the position [i]readable and comparable[/i].

[hr]'''
