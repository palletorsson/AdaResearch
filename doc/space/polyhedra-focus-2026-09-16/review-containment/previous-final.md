The face you made in the last room could be seen from either side. Now let faces meet. When do they begin to enclose something?

<!-- @grab_trihedron -->

Pick up the open corner and turn it. Follow the three triangles toward the point they share. Then look through the opening opposite that point. Something suggests an inside, although one side is missing.

Count the faces before looking at the code. Three. The artifact is a finite model of a trihedral corner: three faces meeting at one vertex. Its four stored positions are connected like this:

```gdscript
[0, 1, 2]
[0, 2, 3]
[0, 3, 1]
```

Each row names a triangle. Position `0` belongs to all three. The other positions make a rim around the opening. No row joins those three rim points into a base.

We have turned the face into a corner. We have not yet closed a surface around a volume.

<!-- @grab_tetrahedron -->

Turn the tetrahedron beside it. Find a face where the first object has an opening. Trace the edges around that face, then follow them toward the opposite vertex. Four faces now complete the enclosure.

Adding the missing base to the open corner would close a tetrahedron. This neighbouring example is regular: its four faces are congruent equilateral triangles. Its proportions differ from the open corner's, so compare how the faces connect before comparing their shapes.

Look at the tetrahedron as a little room with no door. The renderer draws its boundary; it does not have to pack the interior with smaller triangles. A closed surface can enclose space without filling it with rendered material.

Now look back through the open corner. Would a small object fit through its missing side?

The source gives us a complication. The same four positions used for drawing also enter another construction:

```gdscript
var convex_shape = ConvexPolygonShape3D.new()
convex_shape.points = geometry["vertices"]
collision_shape.shape = convex_shape
```

This is a collision shape. The convex hull spans the four positions, including the base absent from the drawing.[^polyhedra-hull] Rendering leaves an opening; physics receives a closed shape. The points have entered two rules and acquired different boundaries.

That does not mean your tracked hand must stop at the opening. Which body collides, with which layers, matters too. For now, keep the question specific: seeing through a place does not tell us whether a particular simulated body can pass through it.

## A face meets the floor

<!-- @prism_block -->

Find the bare prism examples toward the entrance side of the room. Follow a triangular end, then an edge joining it to the other end. The triangle has acquired a length. Two triangular ends and three connecting faces bound a triangular prism.

Compare the whole block with the quartered version and the open frame. The last one offers gaps to your eye. Their visible construction changes, but all three retain the original prism's collision surface. A frame has appeared without cutting corresponding holes in what physics meets.

There is another use of this family of forms under your feet. Approach a wedge from its low end and try walking toward the raised floor. Compare that approach with walking toward an upright face. Notice where forward movement can become upward movement, and where it is interrupted.

The museum builds its utility wedges from a walkable prism scene. It scales the rise and the length of the run:

```gdscript
w.scale = Vector3(1.0, maxf(0.05, rise), maxf(0.2, run_cells))
```

Those dimensions do not settle the whole passage. The low edge must meet the floor; the upper edge needs somewhere to arrive. The moving body's collision and slope settings also participate. If a join catches you, notice where. A continuous-looking route still has to work as a route.

You can hold a small solid and inspect it. A larger arrangement of faces begins to carry the inspector. The lesson has moved from the object in your hand to the conditions of your own movement.

<!-- @concrete_barrier -->

Approach the striped concrete enclosure, then follow its outside edge. Where does the route bend?

Look at the end of a section. A wide foot narrows through sloping shoulders into a small crown. This profile is more elaborate than the prism's triangle, but it too is carried along a length:

```gdscript
var outline := MF.jersey_outline(base_width, top_width, barrier_height)
body.mesh = MF.extrude_profile(outline, barrier_length, barrier_height)
```

The placed sections also have collision bodies. The stripes can announce the boundary before you reach it; the collision shape makes another kind of intervention.

A slope and a barrier share a vocabulary of faces. Their uses depend on how those faces meet the floor and a body approaching them. A barrier might protect a place to stand. A slope might carry you somewhere difficult to leave. Follow the arrangement before deciding what its invitation is worth.

<!-- @street_sign -->

STOP. Did you pause at the word, at the concrete, or somewhere before either?

This sign has no collision body of its own. Its instruction reaches you through reading. The concrete addresses the player's physics body. Recall WALK THIS LINE: an instruction can affect movement without mechanically enforcing it. Here the instruction and the physical boundary stand close together. Try to notice their separate contributions.

Find the blue arrows. Ahead, left, right, both ways. Stand where one becomes legible, then inspect the route it suggests. An arrow has a direction without knowing whether the passage is open. Its rectangular shaft and triangular head are meshes too. The face from the previous hall has become a request about where you should go.

Choose one pause you would keep, one arrow you would turn, or one barrier you would move. Whose movement would change? These fixtures cannot currently be rearranged by grabbing them; carry your proposal as a question for another version. Changing a use and changing its implementation are different work.

The pyramid's handles, the cube, the stacks and the rocks remain here for a [return visit](/book?map=Primitives_Polythedra&section=tutorial). For this walk, carry one distinction onward: enclosing a region, admitting a body and suggesting a direction require different decisions. The next room takes a cube apart so we can follow how its faces are made.

[^polyhedra-hull]: Godot's [ConvexPolygonShape3D](https://docs.godotengine.org/en/4.6/classes/class_convexpolygonshape3d.html) is a solid collision shape. The opening here belongs to the rendered mesh, not to that hull. A collision model assembled from surface triangles is a different construction; Godot's [ConcavePolygonShape3D](https://docs.godotengine.org/en/4.6/classes/class_concavepolygonshape3d.html) is intended chiefly for static geometry. This is not an instruction to replace a held object's hull with a concave shape without considering its physics behavior.
