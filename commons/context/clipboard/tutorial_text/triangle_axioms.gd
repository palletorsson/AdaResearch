extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]The Triangle[/b][/font_size][/center]
[center][i]The First Enclosure[/i][/center]

If the Point is position, the Line is measured relation, and the Grid is indexed space, then the Triangle is the first geometry that closes. Three positions connected by three relations produce something new: an inside and an outside.

The Triangle introduces enclosure.

[hr]

[b]Three Positions, One Closure[/b]

Two positions define a line.
Three non-collinear positions define a plane and enclose space.

[color=yellow][b]Code: Defining the Triangle[/b][/color]
[code]
var point_a = Vector3(0, 0, 0)
var point_b = Vector3(2, 0, 0)
var point_c = Vector3(1, 0, 2)

var edges = [
[point_a, point_b],
[point_b, point_c],
[point_c, point_a]
]
[/code]

Three vertices. Three edges. One face.

The triangle is the first structure where relations close upon themselves.

[hr]

[b]Orientation and Normal[/b]

Unlike the line, the triangle has orientation.
It faces a direction.

[color=yellow][b]Code: Computing the Normal[/b][/color]
[code]
var edge1 = point_b - point_a
var edge2 = point_c - point_a
var normal = edge1.cross(edge2).normalized()
[/code]

The cross product determines which side is front and which is back.
Winding order matters.

The triangle distinguishes between the side that sees and the side that is seen.

[hr]

[b]Area: Measure of Capture[/b]

If the line measured distance, the triangle measures area.

[color=yellow][b]Code: Computing Triangle Area[/b][/color]
[code]
var cross = edge1.cross(edge2)
var area = cross.length() * 0.5
[/code]

Area quantifies enclosure.
How much space has been captured.

This is the first moment geometry can contain.

[hr]

[b]From Relation to Surface[/b]

To render the triangle, relations become surface.

[color=yellow][b]Code: Creating the Triangle Mesh[/b][/color]
[code]
var surface_tool = SurfaceTool.new()
surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

surface_tool.set_normal(normal)
surface_tool.add_vertex(point_a)
surface_tool.add_vertex(point_b)
surface_tool.add_vertex(point_c)

var triangle_mesh = surface_tool.commit()

var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = triangle_mesh
add_child(mesh_instance)
[/code]

The triangle now exists as a visible boundary.
Space is divided.

[hr]

[b]Inside and Outside[/b]

The triangle introduces a decisive binary.

A position is either inside the boundary or outside it.
There is no third state.

The algorithm returns a boolean.
Inside or outside. True or false.

Ambiguity is excluded.

[hr]

[b]The Atomic Surface[/b]

All polygonal surfaces reduce to triangles.
Every mesh rendered by the GPU is composed of triangular faces.

[color=yellow][b]Code: Triangles Everywhere[/b][/color]
[code]
var sphere = SphereMesh.new()
sphere.radial_segments = 32
sphere.rings = 16
[/code]

Triangles are used because:

• Three points always lie on a plane
• They are computationally stable
• Hardware is optimized to render them

Every complex surface is a repetition of the simplest enclosure.

[hr]

[b]What the Triangle Cannot Hold[/b]

The boundary has no thickness.

It cannot express:

• thresholds
• porous edges
• gradual transitions
• ambiguous belonging

Inside and outside are absolute.

[hr]

[b]The Triangle as Governance[/b]

To draw a triangle is to declare territory.

What was continuous becomes bounded.
What was open becomes enclosed.

Every rendered object is composed of countless small acts of enclosure—each triangle asserting inside and outside, orientation and area.

The Grid made space indexable.
The Triangle makes space containable.

[hr]

[color=cyan][b]Summary:[/b][/color]
The Triangle is the first closed geometry. It introduces enclosure, orientation, and area, producing an inside/outside distinction. All rendered surfaces reduce to triangles—the atomic unit of computational boundaries.'''
