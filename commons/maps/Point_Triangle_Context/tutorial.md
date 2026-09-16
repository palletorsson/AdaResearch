# From a closed boundary to a visible face

In [Grid](../Point_Line_Grid/tutorial.md), positions became addresses we could return to. This hall uses that repeatability to make corners meet. Its first question is small: **does closing three edges also make their centre visible?**

## Close, look, then fill

At `triangle_line_puzzle`, fit two edges and look through the opening. Fit the third. The instrument reports a closed boundary; the centre is still unfilled. Press SHOW / HIDE FILL. Compare the coloured face with the retained outline, and walk around it before hiding it again.

The completed puzzle's fill uses three target positions. This is the actual submission in its script:

```gdscript
mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
for p: Vector3 in target_positions: mesh.surface_add_vertex(p)
mesh.surface_end()
```

The primitive type tells the renderer how to interpret the vertices. Connecting line endpoints and submitting a filled triangle are separate operations. The button is enabled in effect only after the puzzle is complete: pressing it earlier creates no face.

Three distinct, non-collinear points determine a unique plane. Move your viewpoint until the face looks narrow. Its projected width can shrink while its area stays fixed. Making the points themselves collinear would be a different change, leaving zero triangle area. The puzzle's material displays both sides; an edge-on view is not proof that a side has been culled.

## Record your own corners

At `draw_triangle_faces`, pick up the drawing point. Hold at each intended corner until a numbered point appears. The held-placement interval is one second, with at least 0.15 metres of travel from the last corner; positions round to a 0.1-metre world grid. Returning within the existing-point snap radius can reuse a point. Make a triangle, returning to the first point to close it.

The instrument separates filled loops from logical triangles. A three-corner loop adds one of each. SHOW / HIDE FILL changes visibility without deleting corners or boundary lines.

Release at the closing corner. The release callback can record that position, but an unheld tool does not continue timed sampling. Existing corner handles remain editable; moving and releasing one stores its new snapped position and rebuilds its faces. This editor can change side lengths; it is not a linkage of rigid rods.

For an independent comparison, release, press NEW OUTLINE and pick up again. Completed faces and their numbered corners remain. START identifies the first point in the new path; it is not a command to clear everything.

## Keep the outline, change its start

Make this simple L in a horizontal plane, clear of the practice triangle so its points do not catch the new corners. Coordinates are metres along two horizontal directions from a chosen origin; hold the height fixed. The labels A–F are our recipe, not labels supplied by the tool.

```text
A (0.0, 0.0)     B (1.2, 0.0)     C (1.2, 0.4)
D (0.4, 0.4)     E (0.4, 1.2)     F (0.0, 1.2)
```

1. Follow A → B → C → D → E → F → A. Inspect the fill.
2. Release, start a new outline and reuse those six corners in B → C → D → E → F → A → B order.
3. Keep the boundary direction, positions and height fixed. Check START before closing; look into the missing notch after each fill.

Both routes bound the same region. The fan from B extends into the notch. To locate the decision, read these lines from `_create_triangles_from_path()`:

```gdscript
var first_point = placed_points[loop_points[0]]
for i in range(1, loop_points.size() - 1):
    var v0 = first_point
    var v1 = placed_points[loop_points[i]]
    var v2 = placed_points[loop_points[i + 1]]
```

The following code submits each triple as a triangle, with normals, colour and a reversed copy. Here the important choice is which indices share `first_point`. From B, the logical triangles are BCD, BDE, BEF and BFA. Some cross the region you left open.

For `n` corners, this loop makes `n - 2` logical triangles. Both Ls together add two loops and eight triangles. If you kept the first practice triangle and made no extra loops, the total becomes three loops and nine triangles. Hiding a fill does not subtract it from the counter.

A first-vertex fan fills a convex planar polygon. Some concave polygons also admit this fan from a suitable vertex. The failure is not “concave means impossible”; it is a particular method applied from a particular start. The artifact does not check coplanarity, self-intersections or whether the fan stays inside an intended polygon.

## Carry a distinction to the next room

Explain the overspill by pointing to one emitted triangle. Then choose what you would preserve: the outline, this filling method or the unexpected surface as material for another work. A new use is possible without changing code; a different filling algorithm would require an implementation change.

The [secondary studies](detours.md) extend this into shared edges, folds, symbols and measurement. We can return to them. [Polyhedra](../Primitives_Polythedra/tutorial.md) asks what faces need to enclose a volume. Three faces meeting at a corner still leave an opening; a tetrahedron needs four triangular faces.

Source details and validation limits are in [technical.md](technical.md) and [encounter-reference.md](encounter-reference.md).
