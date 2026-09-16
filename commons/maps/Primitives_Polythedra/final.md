The face you made in the last room could be seen from either side. Now let faces meet. When do they begin to enclose something?

<!-- @grab_trihedron -->

Pick up the open corner and turn it. Follow the three triangles toward the point they share. Then look through the opening opposite that point. Something suggests an inside, although one side is missing.

Count the faces before looking at the code. Three. The artifact is a finite model of a trihedral corner: three faces meeting at one vertex. Its four stored positions are connected like this:

```gdscript
[0, 1, 2]
[0, 2, 3]
[0, 3, 1]
```

Position `0` belongs to all three triangles. The other positions make a rim around the opening. No row joins those three rim points into a base.

We have turned the face into a corner. We have not yet closed a surface around a volume.

<!-- @grab_tetrahedron -->

Turn the tetrahedron beside it. Find a face where the first object has an opening. Follow its edges toward the opposite vertex. Four faces now complete the enclosure.[^polyhedra-separation]

Adding a base to the open corner would close a tetrahedron. This neighbouring example is regular, with four congruent equilateral faces. Its proportions differ, so compare how the faces connect before comparing their shapes.

Look at the tetrahedron as a little room with no door. Imagine it large enough to stand inside: where would you enter? The renderer draws the boundary without filling the interior with material. Enclosing a region has not supplied a way into it.

Now look back through the open corner. Would a small object fit through its missing side?

The same four positions used for drawing enter another construction:

```gdscript
var convex_shape = ConvexPolygonShape3D.new()
convex_shape.points = geometry["vertices"]
collision_shape.shape = convex_shape
```

The convex collision hull spans the four positions, including the base absent from the drawing.[^polyhedra-hull] Rendering leaves an opening; physics receives a closed shape. The points have entered two rules and acquired different boundaries.

That does not mean your tracked hand must stop there. Which body collides, with which layers, matters too. The geometric surface remains open; passage for a particular simulated body is another question.

## A face meets the floor

<!-- @prism_block -->

Find the bare prism examples toward the entrance side of the room. Follow a triangular end, then an edge joining it to the other end. The triangle has acquired a length. Two triangular ends and three connecting faces bound a triangular prism.

Compare the whole block with the quartered version and the open frame. Their visible construction changes; all three retain the original prism's collision surface. The gaps offered to your eye have no corresponding cutouts in that surface.

Approach a utility wedge from its low end and try walking toward the raised floor. Compare that approach with an upright face. Where can forward movement become upward movement?

The museum builds these wedges from a walkable prism scene, scaling the rise and the run:

```gdscript
w.scale = Vector3(1.0, maxf(0.05, rise), maxf(0.2, run_cells))
```

The low edge must meet the floor; the upper edge needs somewhere to arrive. The moving body's collision and slope settings also participate.[^polyhedra-gibson] If a join catches you, notice where. A continuous-looking route still has to work as a route.

You can hold a small solid and inspect it. A larger arrangement of faces begins to carry the inspector. The lesson has moved from the object in your hand to the conditions of your own movement.

<!-- @concrete_barrier -->

Approach the striped concrete enclosure and follow its outside edge. Its stepped profile is carried along a length too, with a collision body added. Related constructions can offer ascent or interrupt a route. Geometry does not decide the use.

A barrier might protect a place to stand; a slope might lead somewhere difficult to leave. Follow what this arrangement permits before deciding what you would change.

<!-- @street_sign -->

STOP stands beside the concrete. Did you pause at the word or at the physical boundary? Recall WALK THIS LINE: an instruction can orient you without enforcing collision. This sign has no collision body of its own.[^polyhedra-ahmed]

Read one blue arrow, then look where it points. An arrow can propose a direction without knowing whether the route is traversable.

We could follow these forms into many other arrangements. For now, ask which one you would change, and whose movement it would change. The fixtures are fixed here; this is a proposal to carry onward.

The pyramid, cube, stacks and rocks remain for a [return visit](/book?map=Primitives_Polythedra&section=tutorial). Keep the distinction: enclosing a region, admitting a body and suggesting a direction require different decisions. Next, a cube is taken apart so we can follow how its faces are made.

[^polyhedra-separation]: For the Jordan–Brouwer separation theorem, see Zuoqin Wang's [Topology lecture 23](https://staff.ustc.edu.cn/~wangzuoq/Courses/20S-Topology/Notes/Lec23.pdf), Theorem 2.7 (2020). In three dimensions, a surface embedded in Euclidean space and homeomorphic to a sphere separates its complement into two components, one bounded and one unbounded. The tetrahedron's boundary fits these conditions. This establishes separation, not a collider, an entrance or habitability.

[^polyhedra-hull]: Godot's [ConvexPolygonShape3D](https://docs.godotengine.org/en/4.6/classes/class_convexpolygonshape3d.html) is a solid collision shape. The opening here belongs to the rendered mesh, not to that hull. A collision model assembled from surface triangles is a different construction; Godot's [ConcavePolygonShape3D](https://docs.godotengine.org/en/4.6/classes/class_concavepolygonshape3d.html) is intended chiefly for static geometry. This is not an instruction to replace a held object's hull with a concave shape without considering its physics behavior.

[^polyhedra-gibson]: James J. Gibson, [The Ecological Approach to Visual Perception](https://memoof.me/download/1058/pdf/1058.pdf) (1979; linked Classic Edition), chapter 8, relates a surface's affordance of support to the animal's size, weight and behavior. The wedge invites a computational comparison: passage depends on the surface and the moving body's implementation. The engine's settings do not exhaust Gibson's account of perception or the visitor's bodily experience.

[^polyhedra-ahmed]: See Sara Ahmed, [Queer Phenomenology](https://www.dukeupress.edu/queer-phenomenology) (2006), Introduction; the fuller discussion accompanies WALK THIS LINE. Here orientation returns through a sign beside a physical boundary. Reading an instruction and meeting collision remain different operations.
