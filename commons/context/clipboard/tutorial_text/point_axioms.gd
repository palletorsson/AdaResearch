extends Node

# Auto-generated from infoboard progression
var text = '''
[center][b]The Point[/b][/center]
[center][i]The Atom of Space[/i][/center]

Understanding points as the fundamental building block of all 3D graphics and simulations

[hr]
[b]The Point: The Atom of Space[/b]
- A point in 3D space is a vector defining a position (x, y, z).
[color=yellow]Code[/color]
[code]
var point_position = Vector3(3.0, 1.5, 4.0)
[/code]
[i]Concepts: Vector3, position, origin, coordinate system[/i]

[hr]
[b]Visualizing the Point[/b]
- A visible point can be represented by a small sphere.
[color=yellow]Code[/color]
[code]
var sphere_mesh = SphereMesh.new()
var radius = 0.01  # one centimeter
sphere_mesh.radius = radius
sphere_mesh.height = radius * 2  # height is diameter
[/code]
[i]Concepts: SphereMesh, radius, visualization, scale[/i]

[hr]
[b]Instantiating the Point[/b]
- Instantiat a mesh into the scene tree to hold the sphere.
[color=yellow]Code[/color]
[code]
var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = sphere_mesh
mesh_instance.position = point_position
add_child(mesh_instance)
[/code]
The add_child() add mesh_instace scene
[i]Concepts: MeshInstance3D, scene tree, add_child, instantiation[/i]

[hr]
[b]Labeling the Point[/b]
- The identity of a point is represented as a text label close to the point.
[color=yellow]Code[/color]
[code]
var label_3d = Label3D.new()
label_3d.text = str(point_position)
var offset = Vector3(0, 0.15, 0)
label_3d.position = point_position + offset
add_child(label_3d)
[/code]
What does offset do?
[i]Concepts: Label3D, billboard, text rendering, offset[/i]

[hr]
[b]Dynamic Updates[/b]
- The text label must update when the point's position changes.
[color=yellow]Code[/color]
[code]
func _process(delta):
	label_3d.text = str(point_position)
	label_3d.position = point_position + label_offset
[/code]
[i]Concepts: _process, delta, dynamic updates, real-time[/i]
'''
