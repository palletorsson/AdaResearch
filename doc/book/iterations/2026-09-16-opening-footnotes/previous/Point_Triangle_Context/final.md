Three points can close a boundary. What must the machine add before there is a face to look at?

You have connected endpoints, recorded a path and given positions addresses you can return to. Now bring three edges together. Something can close without becoming a surface.

<!-- @triangle_line_puzzle -->

Bring two edges into place. Look through the remaining opening before adding the third. What do you expect to arrive with the last connection?

The boundary closes. Its centre stays unfilled. The small instrument beside it reports the closed boundary and the hidden fill. Press **SHOW / HIDE FILL**, then look from another side. Press again. The edges remain while the patch of colour comes and goes.

We have made two things happen separately. Connecting the endpoints closes a loop. Adding a triangle mesh gives that loop a visible face. The first operation does not secretly contain the second.

The button waits for the completed boundary. Once it is closed, its mesh receives the three target positions:

```gdscript
mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
for p: Vector3 in target_positions: mesh.surface_add_vertex(p)
mesh.surface_end()
```

The word `TRIANGLES` asks the renderer to treat each three vertices as a face. The positions alone did not ask for this. Their order, the primitive type and the material participate in what you see.

This fill is visible from both sides. Walk around it. Its appearance can narrow almost to a line without its three corners moving. The material permits a view from either side; the edge-on projection leaves little of the surface to show.

Three distinct, non-collinear points determine a triangle and a unique plane. “Non-collinear” means that the third point is not on the line through the other two. Without that condition, the boundary can collapse into a line with no area.

## Close a loop, then inspect the fill

<!-- @draw_triangle_faces -->

Pick up the drawing point and make a small triangle in the air. The tool records a corner while held once its one-second interval has elapsed and the tip has moved far enough from the previous point. Move to each intended corner, watch for the numbered point, then return near the first to close the loop. Positions round to a ten-centimetre grid. The addressing we met in Grid helps corners meet here.

Look for the filled face. The side instrument distinguishes **filled loops** from **triangles**: one three-corner loop makes one triangle. Press **SHOW / HIDE FILL** and compare the surface with its retained boundary. Hiding the fill preserves the points and edges.

Each corner has a number. **START** marks the first point of the current path. That number is about order, not importance. We will give it a different job in a moment.

Release the tool at the corner where you closed the loop. Release can record a final position; after that the resting tool adds no timed samples. Your earlier corners remain grabbable. Move one and release it; the faces that use it rebuild.

For another independent outline, release the pen and press **NEW OUTLINE**, then pick it up again. The button keeps completed faces and lets you choose a new first corner. Use it before each comparison below.

Beside your first triangle, in a clear patch of space, make a six-corner L in one horizontal plane. Think of a 1.2-metre square with a 0.8-metre square missing from one corner. Each arm of the L is 0.4 metres wide. Keep the line from crossing itself.

For a precise version, the coordinates below name the two horizontal directions in metres, relative to the lower-left outer corner; keep every point at the same height:

```text
A (0.0, 0.0)     B (1.2, 0.0)     C (1.2, 0.4)
D (0.4, 0.4)     E (0.4, 1.2)     F (0.0, 1.2)
```

First follow **A → B → C → D → E → F → A**. Inspect the fill. Begin a new outline and follow the same boundary from its next corner: **B → C → D → E → F → A → B**. Reuse the six existing corner points. These letters name our route; the tool shows numbers. Check START before closing. Should beginning elsewhere change which region lies inside the L?

The boundary has not moved, but from B the added fill reaches into the missing notch. Something is covering a place you left open.

The tool uses the first point as the centre of a triangle fan, connecting it to successive pairs around the loop. For the second L it submits these four triangles:

```text
B C D
B D E
B E F
B F A
```

Follow their edges across the notch. The code kept its rule; the rule failed to keep your boundary. Choosing another start changed the input order, not the polygon's interior.

Each six-corner loop adds four triangles to the readout. Keeping both Ls adds two filled loops and eight triangles to whatever you already made. The counter includes the triangles that overspill. It can count a construction without deciding whether it fills the intended region.

The method works for a triangle and for a convex planar polygon. Some concave polygons also work from suitable starting vertices. Concavity by itself does not guarantee failure, which is why this comparison keeps the boundary fixed and changes the start deliberately.

You could choose a better starting vertex where one exists, redraw a shape the fan handles, or keep this outline and ask for another filling algorithm. You might also want that unwanted patch for another work: a wing, a pleat, something extending beyond its frame. Changing its use would give the result another purpose. It would not repair the original fill.

We need not settle every use of a triangle before leaving. The folds, symbols and other surfaces remain here to return to. Carry this distinction onward: closing a boundary, making a face and choosing how to show it are operations we can separate. A convenient method need not require everyone to want a convenient shape.

Next, faces meet at a corner. What must we add to enclose a volume?
