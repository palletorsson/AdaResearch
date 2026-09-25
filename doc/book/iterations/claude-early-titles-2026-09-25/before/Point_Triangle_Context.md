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

<!-- @triangle_construction_plate -->

The wall plate places the same three corners side by side: first as points, then as a boundary, then as a face.

![Three identical sets of points A, B and C: points alone, connected boundary, and pink triangular face.](/book-review/doc/book/figures/Point_Triangle_Context/triangle-construction.png)

*One set of positions. Connecting them closes a boundary; filling it adds a face.*

<!-- @triangle_line_puzzle -->

This fill is visible from both sides. Walk around it, looking for a view where the patch narrows almost to a line. Its three corners have not moved; you have. Move back and watch the face open again.[^point-triangle-winding]

Three distinct, non-collinear points determine a triangle and a unique plane. “Non-collinear” means that the third point is not on the line through the other two. Without that condition, the boundary can collapse into a line with no area.

## Close a loop, then inspect the fill

<!-- @draw_triangle_faces -->

Something is already lying here, unclosed: pale corners joined into an open path. It is your bend from Trace, carried in.[^point-triangle-carry]

Three decisions were taken to get it this far. Six positions were kept out of the hundreds you made, sampled at even intervals along the stored order rather than at the turns you thought you were making. The shape was scaled to arm's reach. And your height was dropped, because a fan asks what lies inside a plane, and your hand was not working in one. Your drawing has been made fillable. Look at what that cost before you close it.

Pick up the drawing point and finish the loop: move near the first corner and wait for it to take. Positions fall on a ten-centimetre grid. The addresses we met in Grid now help corners meet.

Look for the filled face. The side instrument counts **loops** and **triangles** separately. Press **SHOW / HIDE FILL** and compare the surface with its retained boundary. Hiding the fill preserves the points and edges.

Now release the tool at the corner where your loop began, and press **SHIFT START** once. The same corners begin their order one place along.

If your bend turned back on itself, the fill may have reached into somewhere your hand never went. Look for a patch beyond the boundary.

Try a six-corner L, drawn flat, with two equal arms. Begin where the two long outer edges meet and follow the boundary around the notch. **NEW OUTLINE** lets you begin without erasing your earlier faces; the drawing guide gives the dimensions and timing.[^point-triangle-construction]

Once the L closes, release the tool at its first corner and press **SHIFT START**. The same six points now begin at the next corner. Should beginning elsewhere change what lies inside the L?

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

You could choose a better starting vertex where one exists, redraw a shape the fan handles, or keep this outline and ask for another filling algorithm.[^point-triangle-triangulation]

Or keep the overspill. Follow the patch beyond the notch: a wing, a pleat, something extending beyond its frame. It has failed to fill this L; it may have given you a shape you want to make.

Carry this distinction onward: closing a boundary, making a face and choosing how to show it are operations we can separate. A convenient method need not require everyone to want a convenient shape.

Try the four-edge puzzle too. Its closed outline still has no face. Nearby, the quad joins two triangular patches along a diagonal. Move a corner away from that diagonal: one patch follows while the other stays. Move an end of the diagonal and both change. Four corners have given us two faces that can tilt differently. Remember their shared edge when a cube offers you what looks like a single square.

Next, faces meet at a corner. What must we add to enclose a volume?

[^point-triangle-winding]: For the rendering convention, see [Godot 4.6’s SurfaceTool documentation](https://docs.godotengine.org/en/4.6/classes/class_surfacetool.html): triangle front faces use clockwise winding. Vertex order, shading normals and the material’s culling setting have different jobs. The puzzle deliberately displays both sides. That choice changes visibility; it does not give the face thickness or a collider.

[^point-triangle-triangulation]: One available development route is Godot’s [`Geometry2D.triangulate_polygon`](https://docs.godotengine.org/en/4.6/classes/class_geometry2d.html#class-geometry2d-method-triangulate-polygon), which returns triangle indices for a 2D polygon and an empty result if triangulation fails. A planar 3D drawing would first need coordinates in its plane, followed by mapping the returned indices back to its vertices and handling winding. This room still uses its first-vertex fan; no alternate triangulator is installed by this note.

[^point-triangle-carry]: The trace travels on the same `TraceData` autoload that brings your drawing to the ruled field in Grid: releasing a drawing dot or stick in Trace appends a snapshot of its retained positions, and this tool reads the most recent one. If nothing was released there, or you have come to this room first, the tool opens empty and every corner below is yours to place by hand. The reduction to six corners, the rescaling and the flattening happen on arrival, not in Trace; the stored positions are unchanged, and the whiteboard's image travels by no route at all.

[^point-triangle-construction]: The [technical companion](/book?map=Point_Triangle_Context&section=technical) gives the six coordinates and the manual two-fill comparison. SHIFT START changes the last completed loop; release the pen and every corner, and leave no unfinished outline. The instrument reports START and whether the action is ready. Letters A–F name our route here; the tool displays numbered corners.
