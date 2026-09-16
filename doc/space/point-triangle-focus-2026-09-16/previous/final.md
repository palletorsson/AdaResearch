Three points can close a boundary. What must the machine add before there is a face to look at?

You have connected endpoints, recorded a path and watched a grid choose where samples may land. Begin here by making the first closed triangle. Its applications can wait until you have something to apply.

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

The word `TRIANGLES` asks the renderer to treat each three vertices as a face. Change how vertices are submitted and the same positions can become another kind of drawing. Their order, the primitive type and the material all participate in what you see.

This fill is visible from both sides. Walk around it. Its appearance can narrow almost to a line without its three corners moving. The material permits a view from either side; the edge-on projection leaves little of the surface to show.

Three distinct, non-collinear points determine a triangle and a unique plane. “Non-collinear” means that the third point is not on the line through the other two. Without that condition, the boundary can collapse into a line with no area.

## Close a loop, then inspect the fill

<!-- @draw_triangle_faces -->

Pick up the drawing point and make a small triangle in the air. The tool places a point while held when its one-second interval has elapsed and the tip has moved far enough from the previous point. Move to each intended corner, watch for the placed point, then return near the first to close the loop. The tool also rounds positions to its ten-centimetre grid.

Look for the filled face. The side instrument distinguishes **filled loops** from **triangles**: one three-corner loop makes one triangle. Press **SHOW / HIDE FILL** and compare the surface with its retained boundary. Hiding the fill preserves the points and edges.

Each corner has a number. **START** marks the first point of the current path. That number is about order, not importance. We will give it a different job in a moment.

Release the tool and watch it rest. Its timer stops accepting held samples. The released position can still be placed by the release itself; after that, moving an unheld tool does not continue the drawing. Your earlier corners remain grabbable, and moving one rebuilds the faces that use it.

For another independent outline, release the pen and press **NEW OUTLINE**, then pick it up again. The button keeps completed faces and lets you choose a new first corner. Use it before each comparison below.

Make a six-corner L in one horizontal plane. Think of a 1.2-metre square with a 0.8-metre square missing from one corner. Each arm of the L is 0.4 metres wide. Keep the line from crossing itself.

For a precise version, the coordinates below name the two horizontal directions in metres, relative to the lower-left outer corner; keep every point at the same height:

```text
A (0.0, 0.0)     B (1.2, 0.0)     C (1.2, 0.4)
D (0.4, 0.4)     E (0.4, 1.2)     F (0.0, 1.2)
```

First follow **A → B → C → D → E → F → A**. Inspect the fill. Begin a new outline and follow the same boundary from its next corner: **B → C → D → E → F → A → B**. You can reuse the six existing numbered corner points. Before each loop, check that START marks the corner you intended. Predict whether changing the first corner should change the intended region before closing the second loop.

The polygon has the same boundary and the same interior. The tool can produce a different fill. From B, some of its triangles extend into the missing notch. That is a failure to respect this boundary, not another equally valid interior of the same simple planar polygon.

Here is the choice the tool makes: it uses the first point as the centre of a triangle fan, connecting it to successive pairs around the loop. A six-point loop gives four fan triangles. After keeping both L-shaped outlines, the readout should show two filled loops and eight triangles. It counts the triangles in both constructions, including those that overspill. The triangle count alone cannot tell whether those triangles fill the intended region without overlap or overspill.

The method works for a triangle and for a convex planar polygon. Some concave polygons also work from suitable starting vertices. Concavity by itself does not guarantee failure, which is why this comparison keeps the boundary fixed and changes the start deliberately.

Now choose what to preserve: the outline you intended, or this particular filling method. You could redraw a shape the fan handles, choose a better starting vertex where one exists, or propose another triangulation algorithm. The machine's convenient rule need not become a rule requiring every visitor to want a convenient shape.

<!-- @ -->

## Further encounters

The two main experiments can stand on their own. The other artifacts let you follow particular questions further.

<!-- @ -->

Move one corner toward the line between the other two. Watch the face narrow. Move the corner away again, then to the other side. Predict how the area will change before the next movement.

The handles alter vertex positions and the face follows. They do not hold the edge lengths fixed. A triangle made from three rigid rods cannot change its shape freely while keeping their lengths; this editor allows a different operation, changing the lengths themselves.

Two edges from the same corner give a way to calculate area:

```gdscript
var cross := (b - a).cross(c - a)
var area := 0.5 * cross.length()
```

At the collinear case, that cross product is zero. Away from it, the cross product also supplies a direction perpendicular to the plane. A rendered face needs more than the statement “three points”: it needs their positions and an order in which to use them.

<!-- @ -->

Compare the separate triangle example with the one you deformed. Colour and material can change how a face reads without changing the geometric relation that makes it a triangle.

<!-- @ -->

## Which side you are on

<!-- @ -->

Return to a face you made and compare its two sides. The material makes a choice about visibility available to look at.

A triangle's ordered vertices determine an orientation. Swapping two reverses it. A material may hide back-facing triangles or display both sides. The geometric points do not by themselves decide which side a visitor is allowed to see.

Find a viewpoint from which the face becomes narrow. Has the triangle lost its area, or has its projected image become small? Compare that change of viewpoint with the earlier movement toward collinearity. Two similar pictures can have different causes.

<!-- @ -->

## Four points, and a fold

<!-- @ -->

At the split quad, move one corner out of the other corners' plane. Watch the two triangles beside the diagonal. What had looked like one flat face can acquire a crease while keeping its connectivity.

Three non-collinear points determine a plane. An arbitrary fourth point need not lie on it. Dividing the four-point patch into triangles gives each triangle its own plane; it does not force all four points to agree on one.

<!-- @ -->

Compare the four-line puzzle with your triangle. A square is one particular quadrilateral. Four fixed side lengths alone allow a hinged quadrilateral to lean, while three suitable fixed lengths determine a triangle's shape up to rigid movement and reflection. A square task therefore needs more constraints than a closed four-edge loop.

<!-- @ -->

Use the squares on the triangle's sides as another comparison. For a right triangle, the areas on the two shorter sides sum to the area on the hypotenuse. Check which angle the displayed claim requires. A theorem about a specified triangle is more useful than a promise about every three-sided figure.

<!-- @ -->

Follow the pleats of the profile. Where one face meets another, a local relationship becomes part of a larger form. The unit you constructed can now take on a different role.

<!-- @ -->

The strip begins flat. Wait for one shared edge to become a hinge: the triangles on one side turn together, changing the silhouette without changing their edge lengths. It opens flat again, then a repeated sequence of paired folds gathers the same twenty-four triangles into another arrangement. Follow an edge through the movement. What changed, and what stayed connected?

Pick up a corner to interrupt the study. Your hand can now change the edge lengths as well as the angles; this is a free mesh edit, a different operation from the hinge folds you watched. Release it and your edit stays. When you want to compare it with the study again, let go of every handle and press **REPLAY**.

<!-- @ -->

Before leaving, distinguish three things with an example: closing a boundary, filling it, and deciding which side is visible. Then explain why a different result from the L-shaped outline does not mean that your intended shape was wrong.

The next room brings faces together at a corner and asks what must still be added to enclose a volume.
