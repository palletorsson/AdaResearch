Three points can close a boundary. What must the machine add before there is a face to look at?

You have connected endpoints, recorded a path and given positions addresses you can return to. Now bring three edges together. Something can close without becoming a surface.

<!-- @triangle_line_puzzle -->

Bring two edges into place. Look through the remaining opening before adding the third. What do you expect to arrive with the last connection?

The boundary closes. You can still look through its centre into the room. Press **SHOW / HIDE FILL** on the small panel beside it. A translucent patch now hangs between the same three corners. Press again: the patch disappears and the edges stay.

We have made two things happen separately. Connecting the endpoints closes a loop. Adding a triangle mesh gives that loop a visible face. The first operation does not secretly contain the second.

The button waits for the completed boundary. Once it is closed, its mesh receives the three target positions:

```gdscript
mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
for p: Vector3 in target_positions: mesh.surface_add_vertex(p)
mesh.surface_end()
```

The word `TRIANGLES` asks the renderer to treat each three vertices as a face. The positions alone did not ask for this. Their order, the primitive type and the material participate in what you see.

![Three identical sets of points A, B and C: points alone, connected boundary, and pink triangular face.](/book-review/doc/book/iterations/2026-09-23-triangle-illustration/figures/triangle-construction.png)

*One set of positions. Connecting them closes a boundary; filling it adds a face.*

This fill is visible from both sides. Walk around it, looking for a view where the patch narrows almost to a line. Its three corners have not moved; you have. Move back and watch the face open again.[^point-triangle-winding]

Three distinct, non-collinear points determine a triangle and a unique plane. “Non-collinear” means that the third point is not on the line through the other two. Without that condition, the boundary can collapse into a line with no area.

## Close a loop, then inspect the fill

<!-- @draw_triangle_faces -->

Pick up the drawing point and make a small triangle in the air. Move to each intended corner and wait for its number to appear. The tool needs a second between recorded corners and enough movement away from the previous point. It rounds positions to a ten-centimetre grid, so the addresses we met in Grid now help corners meet. Return near your first point to close the loop.

Look for the filled face. The side instrument distinguishes **filled loops** from **triangles**: one three-corner loop makes one triangle. Press **SHOW / HIDE FILL** and compare the surface with its retained boundary. Hiding the fill preserves the points and edges.

Release the tool where the triangle closed. Its corners remain grabbable: move one, then release it to rebuild the faces that use it. Press **NEW OUTLINE**. The triangle stays while you begin another boundary.

Make a six-corner L in one horizontal plane: a 1.2-metre square with a 0.8-metre square missing from one corner. Begin where the two long outer edges meet. Follow one long edge, go around the notch and return to your beginning. Wait for each numbered corner before moving on.[^point-triangle-construction]

Look at the fill, then release the tool at that first corner. Press **SHIFT START** once. The same six points now begin their order at the next corner. Should beginning elsewhere change what lies inside the L?

The boundary has not moved, but the added fill reaches into the missing notch. Something is covering a place you left open.

Every triangle in this fill shares the first corner. The tool connects it to successive pairs around the loop: a fan of triangles. Call the original start A and the next corner B. Beginning at B, it submits these four triangles:

```text
B C D
B D E
B E F
B F A
```

Follow their edges across the notch. The code kept its rule; the rule failed to keep your boundary. Choosing another start changed the input order, not the polygon's interior.

Keep shifting the start around the six corners. The fill changes; the count remains four triangles for this L. When START returns to A, the original fill returns. The counter includes the triangles that overspill. It can count a construction without deciding whether it fills the intended region.

The method works for a triangle and for a convex planar polygon. Some concave polygons also work from suitable starting vertices. Concavity by itself does not guarantee failure, which is why this comparison keeps the boundary fixed and changes the start deliberately.

You could choose a better starting vertex where one exists, redraw a shape the fan handles, or keep this outline and ask for another filling algorithm.[^point-triangle-triangulation] You might also want that unwanted patch for another work: a wing, a pleat, something extending beyond its frame. Changing its use would give the result another purpose. It would not repair the original fill.

Carry this distinction onward: closing a boundary, making a face and choosing how to show it are operations we can separate. A convenient method need not require everyone to want a convenient shape.

Next, faces meet at a corner. What must we add to enclose a volume?

[^point-triangle-winding]: For the rendering convention, see [Godot 4.6’s SurfaceTool documentation](https://docs.godotengine.org/en/4.6/classes/class_surfacetool.html): triangle front faces use clockwise winding. Vertex order, shading normals and the material’s culling setting have different jobs. The puzzle deliberately displays both sides. That choice changes visibility; it does not give the face thickness or a collider.

[^point-triangle-triangulation]: One available development route is Godot’s [`Geometry2D.triangulate_polygon`](https://docs.godotengine.org/en/4.6/classes/class_geometry2d.html#class-geometry2d-method-triangulate-polygon), which returns triangle indices for a 2D polygon and an empty result if triangulation fails. A planar 3D drawing would first need coordinates in its plane, followed by mapping the returned indices back to its vertices and handling winding. This room still uses its first-vertex fan; no alternate triangulator is installed by this note.

[^point-triangle-construction]: The [technical companion](/book?map=Point_Triangle_Context&section=technical) gives the six coordinates and the manual two-fill comparison. SHIFT START changes the last completed loop; release the pen and every corner, and leave no unfinished outline. The instrument reports START and whether the action is ready. Letters A–F name our route here; the tool displays numbered corners.
