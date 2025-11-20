extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]The Triangle[/b][/font_size][/center]
[center][i]The First Enclosure[/i][/center]

If the Point was discrete, the Line measured, and the Grid indexed, then the Triangle is the first geometry that creates an inside and an outside. Three points. Three lines. One enclosed space.

The Triangle introduces the boundary.

[hr]

[b]Three Points Define a Plane[/b]

Where two points created a line (1D), three non-collinear points define a plane (2D) and enclose space within their perimeter.

[color=yellow][b]Code: Defining the Triangle[/b][/color]
[code]
var point_a = Vector3(0, 0, 0)
var point_b = Vector3(2, 0, 0)
var point_c = Vector3(1, 0, 2)

# Three points, three edges
var edges = [
    [point_a, point_b],
    [point_b, point_c],
    [point_c, point_a]
]
[/code]

Three vertices. Three edges. One face. The triangle introduces interior, orientation, and area.

[hr]

[b]Winding Order and Normals: The Triangle Has a Face[/b]

Unlike the line, the triangle has orientation. It faces a direction. The normal vector points outward from the surface - defining front versus back.

[color=yellow][b]Code: Computing the Normal[/b][/color]
[code]
var edge1 = point_b - point_a
var edge2 = point_c - point_a
var normal = edge1.cross(edge2).normalized()
[/code]

The cross product determines which direction the triangle is facing. Counter-clockwise winding = front face. Clockwise = back face.

The triangle knows which way it is looking. It distinguishes the side that sees from the side that is seen.

[hr]

[b]Area: The Measure of Enclosure[/b]

If the Line measured distance, the Triangle measures area - the quantity of 2D space captured within its perimeter.

[color=yellow][b]Code: Computing Triangle Area[/b][/color]
[code]
var cross = edge1.cross(edge2)
var area = cross.length() * 0.5
[/code]

Area is the metric of capture. How much space has been enclosed. How much territory claimed.

The triangle is the first shape that can contain.

[hr]

[b]The Mesh: Materializing the Boundary[/b]

To render the triangle as a visible surface, we construct a mesh - vertices connected by faces that the GPU can rasterize.

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

The triangle now exists as a renderable surface - a boundary that divides space.

[hr]

[b]Inside and Outside: The Binary of Enclosure[/b]

The triangle creates the most fundamental spatial binary: you are either inside the boundary or outside it. There is no third position. The perimeter enforces the distinction.

The algorithm returns a boolean. True or false. Inside or outside. No ambiguity permitted.

[hr]

[b]The Atomic Surface[/b]

All polygons can be reduced to triangles. Every complex mesh is ultimately a collection of triangular faces. The triangle is the primitive unit of 3D rendering.

[color=yellow][b]Code: Why Triangles?[/b][/color]
[code]
var sphere = SphereMesh.new()
sphere.radial_segments = 32
sphere.rings = 16
# Creates approximately 1024 triangles
[/code]

Why triangles?
- Always planar (three points always lie on one plane)
- GPU optimized (hardware accelerated triangle rasterization)
- Any polygon can be decomposed into triangles

Complex forms are always decomposable into the simplest enclosure. All boundaries reduce to triangles.

[hr]

[b]What the Triangle Cannot Hold[/b]

The boundary is a line of zero thickness. It has no depth, no porosity, no gradual transition. You are inside or you are outside. The triangle cannot represent:

- The threshold - The space of crossing, of being between
- The permeable - Boundaries that leak, that allow passage
- The fuzzy edge - Where inside and outside blur together
- The refusal - The point that will not be classified

[hr]

[b]The Triangle as Governance[/b]

To draw a triangle is to assert: this space is now bounded. What was open is now enclosed. What was continuous is now divided. The triangle is the geometry of territory - the minimal unit of spatial claim.

Every mesh you render is thousands of tiny boundaries, each one asserting inside/outside, each one measuring area, each one facing a direction.

The Grid made space indexed. The Triangle makes space enclosed. Both are systems of containment.

[hr]

[color=cyan][b]Summary:[/b][/color]
The Triangle is the first polygon - three points creating enclosed 2D space. It has orientation (normal vector), area (measure of containment), and defines the inside/outside binary. All 3D meshes decompose into triangles - the atomic unit of rendered surfaces.

'''
