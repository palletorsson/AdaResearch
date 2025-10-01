[b][color=cyan]Axiom 1:[/color][/b] A point in the 3D dimensional coordinate system is a vector representing a position in x, y, z.

[color=yellow]Code:[/color]
[code]var point_position = Vector3(0, 0, 0)[/code]

The vector [color=lime](0,0,0)[/color] is the [b]origin[/b] - the root of all vectors.

[color=orange]This point is not visible; it needs representation.[/color]

[b][color=cyan]Axiom 2:[/color][/b] A visible point can be represented by a small sphere at its position.

[color=yellow]Code:[/color]
[code]var sphere_mesh = SphereMesh.new()
radius = 0.02 # a small sphere
sphere_mesh.radius = radius
sphere_mesh.height = radius * 2 # SphereMesh height is double radius[/code]

[b][color=cyan]Axiom 2.5:[/color][/b] A mesh must be instantiated as a scene object to exist in the world.

[color=yellow]Code:[/color]
[code]var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = sphere_mesh
mesh_instance.position = point_position

add_child(mesh_instance)[/code]

[b][color=cyan]Axiom 3:[/color][/b] The identity of a point is represented as a text label close to the point.

[color=yellow]Code:[/color]
[code]var label_3d = Label3D.new()
label_3d.text = str(point_position)
off_set = Vector3(0, 0.15, 0)
label_3d.position = point_position + off_set
label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
add_child(label_3d)[/code]

[i]Note: Null check and parents[/i]

[b][color=cyan]Axiom 4:[/color][/b] The text label must update when the point's position changes.

[color=yellow]Code:[/color]
[code]func _process(delta):
	label_3d.text = str(point_position)
	label_3d.position = point_position + label_offset[/code]
