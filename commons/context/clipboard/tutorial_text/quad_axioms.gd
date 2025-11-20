extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]The Quad[/b][/font_size][/center]
[center][i]Four Points, Two Triangles[/i][/center]

The quad is a surface of deception. It appears to be a single unified face, but it is always already divided. Four points. Two triangles. The GPU only understands triangles - the quad is merely a convenience for human modeling.

The Quad is the first geometry that can lie about its own planarity.

[hr]

[b]Four Coplanar Points[/b]

A proper quad requires four coplanar points - all lying on the same plane. But unlike the triangle, which is always planar by definition, the quad can betray this requirement.

[color=yellow][b]Code: Defining a Quad[/b][/color]
[code]
var v0 = Vector3(-0.5, -0.5, 0)
var v1 = Vector3(0.5, -0.5, 0)
var v2 = Vector3(0.5, 0.5, 0)
var v3 = Vector3(-0.5, 0.5, 0)

# Four vertices forming a planar quad
# Order matters: v0 -> v1 -> v2 -> v3 -> back to v0
[/code]

Four corners. Four edges. One face (apparently).

[hr]

[b]The Hidden Diagonal: Triangulation[/b]

But the GPU does not render quads. It only renders triangles. Every quad must be secretly divided along a diagonal - split into two triangular faces.

[color=yellow][b]Code: The Decomposition[/b][/color]
[code]
# The quad becomes two triangles:
# Triangle 1: v0, v1, v2
# Triangle 2: v0, v2, v3

var st = SurfaceTool.new()
st.begin(Mesh.PRIMITIVE_TRIANGLES)

# First triangle
st.add_vertex(v0)
st.add_vertex(v1)
st.add_vertex(v2)

# Second triangle
st.add_vertex(v0)
st.add_vertex(v2)
st.add_vertex(v3)

var mesh = st.commit()
[/code]

The diagonal (v0 to v2) is invisible, but it is always there - the hidden cut that makes the quad renderable.

You model with quads. The GPU renders with triangles. This is the fundamental deception of 3D graphics.

[hr]

[b]The Choice of Diagonal Matters[/b]

There are two ways to divide a quad into triangles: diagonal v0-v2, or diagonal v1-v3. The choice seems arbitrary, but it determines how the surface will shade and deform.

[color=yellow][b]Code: Alternative Triangulation[/b][/color]
[code]
# Alternative: use diagonal v1 to v3
# Triangle 1: v0, v1, v3
# Triangle 2: v1, v2, v3
[/code]

For a perfectly planar quad, both diagonals produce identical results. But if the quad is even slightly non-planar, the choice of diagonal creates visible artifacts - a crease, a fold, an unwanted shadow.

The diagonal is where the lie becomes visible.

[hr]

[b]Non-Planar Quads: The First Geometry That Can Fail[/b]

Move any of the four points out of the shared plane, and the quad becomes non-planar - a twisted surface that cannot exist as a single flat face.

[color=yellow][b]Code: Breaking Planarity[/b][/color]
[code]
# Twist one corner out of plane
v3 = Vector3(-0.5, 0.5, 0.2)  # Moved in Z direction

# The quad is no longer planar
# Triangulation will create a visible fold
[/code]

The triangle was always planar by definition (three points always define a plane). The quad is the first shape that can fail to be flat - the first geometry that can betray its own form.

[hr]

[b]The Quad as Modeling Convenience[/b]

Despite being triangulated internally, quads are preferred in 3D modeling because they simplify topology.

Advantages of quad-based modeling:
- Easier subdivision (splits cleanly into smaller quads)
- Cleaner edge loops for animation
- Natural for rectangular surfaces (walls, floors, screens)
- Predictable deformation

But this is a human convenience, not a computational truth. The GPU sees only triangles.

[hr]

[b]The Grid of Quads: Tiled Space[/b]

Quads naturally tile space - creating regular grids of rectangular cells. This makes them ideal for terrain meshes, UV maps, and texture coordinates.

[color=yellow][b]Code: Creating a Quad Grid[/b][/color]
[code]
var grid_size = 10
var quad_width = 1.0

for x in range(grid_size):
    for z in range(grid_size):
        var v0 = Vector3(x * quad_width, 0, z * quad_width)
        var v1 = Vector3((x + 1) * quad_width, 0, z * quad_width)
        var v2 = Vector3((x + 1) * quad_width, 0, (z + 1) * quad_width)
        var v3 = Vector3(x * quad_width, 0, (z + 1) * quad_width)

        # Each quad becomes two triangles
        # Creates 10x10 = 100 quads = 200 triangles
[/code]

A grid of quads creates the appearance of continuous tiled space, but underneath, it is hundreds of tiny triangular cuts.

[hr]

[b]What the Quad Reveals[/b]

The quad exposes the gap between human-friendly modeling and machine-level rendering. We think in quads (rectangular, regular, clean). The GPU thinks in triangles (atomic, irreducible, efficient).

The quad is a lie we tell ourselves to make 3D modeling easier. But the diagonal is always there, waiting to reveal itself when the geometry twists or the lighting changes.

[hr]

[b]The Quad and The Triangle[/b]

The triangle was honest - it was exactly what it appeared to be. The quad is diplomatic - it pretends to be a unified surface while secretly being two triangles.

This is the beginning of abstraction in 3D graphics: modeling representations that differ from rendering reality.

[hr]

[color=cyan][b]Summary:[/b][/color]
The Quad is four points forming a surface that always decomposes into two triangles. It is the first geometry that can be non-planar, and the first that requires a choice (which diagonal to use). It is a modeling convenience, not a rendering primitive - we model in quads, but GPUs render in triangles.

'''
