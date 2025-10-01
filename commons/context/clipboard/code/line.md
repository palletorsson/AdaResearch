[b][color=cyan]Axiom 1:[/color][/b] A line is defined by two distinct points in 3D space.

[color=yellow]Code:[/color]
[code]var start_point = Vector3(0, 0, 0)
var end_point = Vector3(1, 0, 0)[/code]

A line connects [color=lime]point A[/color] to [color=lime]point B[/color], creating a [b]linear path[/b] between them.

[b][color=cyan]Axiom 2:[/color][/b] A line can be visualized using a mesh with two vertices connected by a line primitive.

[color=yellow]Code:[/color]
[code]var surface_tool = SurfaceTool.new()
surface_tool.begin(Mesh.PRIMITIVE_LINES)
surface_tool.add_vertex(start_point)
surface_tool.add_vertex(end_point)
var line_mesh = surface_tool.commit()[/code]

[b][color=cyan]Axiom 3:[/color][/b] The mesh must be instantiated as a scene object to be visible.

[color=yellow]Code:[/color]
[code]var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = line_mesh
add_child(mesh_instance)[/code]

[b][color=cyan]Axiom 4:[/color][/b] A line has direction and magnitude (length).

[color=yellow]Code:[/color]
[code]var direction = end_point - start_point
var length = direction.length()
var normalized_direction = direction.normalized()[/code]

The [color=orange]direction vector[/color] points from start to end, and [color=orange]length[/color] is the distance between them.

[b][color=cyan]Axiom 5:[/color][/b] Lines can be styled with materials for better visibility.

[color=yellow]Code:[/color]
[code]var material = StandardMaterial3D.new()
material.albedo_color = Color.CYAN
material.emission_enabled = true
material.emission = Color.CYAN * 0.5
mesh_instance.material_override = material[/code]
