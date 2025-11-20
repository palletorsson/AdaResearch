extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[b]The Point[/b]
[i]The Atom of Space[/i]

Points are the smallest discrete unit of computational geometry. A point in 3D space is a vector defining a position (x, y, z).

[color=yellow]Code[/color]
[code]
var point_position = Vector3(3.0, 1.5, 4.0)
[/code]
[hr]

- A visible point can be represented by a small sphere.

[color=yellow]Code[/color]
[code]
var sphere_mesh = SphereMesh.new()
var radius = 0.01  # one centimeter
sphere_mesh.radius = radius
sphere_mesh.height = radius * 2  # height is diameter

[hr]

- Instantiat a mesh into the scene tree to hold the sphere.

[color=yellow]Code[/color]
[code]
var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = sphere_mesh
mesh_instance.position = point_position
add_child(mesh_instance)
[/code]
The add_child() add mesh_instace scene

[hr]

- The position of the point is represented as a text label close to the point.

[color=yellow]Code[/color]
[code]
var label_3d = Label3D.new()
label_3d.text = str(point_position)
var offset = Vector3(0, 0.15, 0)
label_3d.position = point_position + offset
add_child(label_3d)
[/code]
[hr]

- The text label  updates when the point's position changes.

[color=yellow]Code[/color]
[code]
func _process(delta):
	label_3d.text = str(point_position)
	label_3d.position = point_position + label_offset
[/code]
[hr]
'''
