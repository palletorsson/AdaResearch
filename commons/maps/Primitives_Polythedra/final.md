# Trihedra and First Solids

The face you made in the last room could be seen from either side. Now let faces meet. When do they begin to enclose something? Volume does not begin as a container. It begins as a corner.

<!-- @grab_trihedron -->

Pick up the open corner and turn it. Follow the three triangles toward the point they share. Then look through the opening opposite that point. Something suggests an inside, although one side is missing. Three faces, each of them the unit from the last room, tilted off the plane until they meet at a single point, and for the first time in this chapter the faces have a side that is *in*. Nothing is enclosed. You could put your hand through it from three directions. But there is an inside now, and there was not before.

Count the faces before looking at the code. Three. The artifact is a finite model of a trihedral corner: three faces meeting at one vertex. Its four stored positions are connected like this:

```gdscript
[0, 1, 2]
[0, 2, 3]
[0, 3, 1]
```

Position `0` belongs to all three triangles. The other positions make a rim around the opening. No row joins those three rim points into a base.

We have turned the face into a corner. We have not yet closed a surface around a volume. Turn it in your hands and find the apex, and notice that the corner is not any of the faces. It is what they agree on. A corner is a place where three flat things have stopped being flat *together*.

<!-- @grab_tetrahedron -->

Turn the tetrahedron a few steps on. Find a face where the first object has an opening. Follow its edges toward the opposite vertex. Four faces now complete the enclosure.[^polyhedra-separation]

Adding a base to the open corner would close a tetrahedron. This neighbouring example is regular, with four congruent equilateral faces. Its proportions differ, so compare how the faces connect before comparing their shapes.

Lay six equilateral triangles around a point and their angles come to 360. They lie flat, and there is no corner, because nothing had to give. Take one away. Five come to 300, and the point rises, because the faces can only meet by tilting, and the sixty degrees they no longer cover is the corner.

That number is the *defect*, and it is the whole argument of this room in one word: a corner is how much of a full turn the faces had to give up to meet in a point instead of a plane. A cube's corner is three right angles, ninety short. The sharper the corner, the more is missing.

<!-- @pyramid_edit -->

Take the apex and move it. Every face tilts to follow, because each one still has to end at the point you are holding, and the corner sharpens or flattens under your hand. Pull it high and the three faces close in, the defect grows, the corner becomes a spike. Push it down toward the base and the faces open, the defect shrinks, and at the moment the apex touches the base plane you have six angles summing to 360 and no corner at all. A pyramid is a corner with a handle on it.

Add up every corner of a closed solid and the answer is **720**. Four corners of 180. Eight corners of 90. Twelve corners of 60. It does not matter what you built: every closed solid there is carries exactly 720 degrees of corner, and the only freedom is how it spends them. Move one vertex of the tetrahedron and its four corners change, one sharpening as another flattens, and the sum does not move. This is Descartes' theorem, and it is the closest thing this chapter has to a conservation law.[^polyhedra-descartes]

Vertices minus edges plus faces. Four minus six plus four. Eight minus twelve plus six. Two, and two. Whatever you build, if it closes, the count comes out the same, the way the corners came out to 720.

That is what a solid is, underneath the faces: two numbers that do not care which solid you built. The faces are where you look. The corners and the count are where it is kept.

Look at the tetrahedron as a little room with no door. Imagine it large enough to stand inside: where would you enter? The renderer draws the boundary without filling the interior with material. Enclosing a region has not supplied a way into it.

Now look back through the open corner. Would a small object fit through its missing side?

The same four positions used for drawing enter another construction:

```gdscript
var convex_shape = ConvexPolygonShape3D.new()
convex_shape.points = geometry["vertices"]
collision_shape.shape = convex_shape
```

The convex collision hull spans the four positions, including the base absent from the drawing.[^polyhedra-hull] Rendering leaves an opening; physics receives a closed shape. The points have entered two rules and acquired different boundaries.

<!-- @polyhedra_boundary_plate -->

Look at the two versions on the wall. The amber base makes visible a boundary you could not see on the object in your hand.

![The open trihedron beside the convex hull of the same four points; an amber face shows where physics closes the missing base.](/book-review/doc/book/figures/Primitives_Polythedra/polyhedra-boundaries.png)

*Four positions, two boundaries. The amber face shows where the convex hull closes the opening.*

That does not mean your tracked hand must stop there. Which body collides, with which layers, matters too. The geometric surface remains open; passage for a particular simulated body is another question.

## A corner makes room

Walk toward a pink corner. A triangular face meets you before the two walls do. Follow its lower edge across the floor, then look up to the point where it ends. The corner looks cut away because we have filled it.

Imagine four points: one at the old floor corner, one farther along each wall at floor level, and one directly above the corner. Join every pair. Three triangular faces lie against the floor and the two walls. The fourth faces you. Behind it, the collision hull occupies the enclosed volume.

This tetrahedron is a **three-dimensional simplex**. We have been approaching it all along: a point, a line segment, a triangle, a tetrahedron. Each step adds a point outside the space spanned by the previous ones. Here four points that do not lie in one plane are enough to enclose a volume.

The small regular tetrahedron has equal edges. This one takes its proportions from the room: three edges leave the old corner at right angles. Follow the pink face into the walls. Its fit depends on their agreement.

Walk up to it. The room has gained a solid and lost a little space for your walk. To make one body fit, we have changed the room available to another.

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

Read one arrow on its blue disc, then look where it points. An arrow can propose a direction without knowing whether the route is traversable.

Look back at the barrier and the slope. Which would you change, and whose movement would it change? The fixtures are fixed here; this is a proposal to carry onward.

<!-- @rock_spawner -->

Last, a pen of walls three cubes high, and thirty rocks dropped into it from three and a half metres, out of a volume three metres by two by three. They are irregular, no two alike, and they fall with physics and come to rest however they land. Look at the gaps. Cubes would have packed. Prisms would have packed. These never will, and the space between them is the first thing in the chapter that no rule made.

<!-- @rock_scanner -->

Beside them a scanner passes a plane up and down through the pile, between the floor and three metres, and draws what it cuts on a panel two metres square: the rocks as slices, a different outline at every height. A solid is what it is in three dimensions; a section is one number's worth less, and the pile looks like a different pile at every level of the cut.

Keep the distinction: enclosing a region, admitting a body and suggesting a direction require different decisions. Next, take hold of a cube's corner. Several faces will answer the same movement. We know how faces can close around a space; now we can ask what keeps them together when their positions change.

[^polyhedra-separation]: For the Jordan–Brouwer separation theorem, see Zuoqin Wang's [Topology lecture 23](https://staff.ustc.edu.cn/~wangzuoq/Courses/20S-Topology/Notes/Lec23.pdf), Theorem 2.7 (2020). In three dimensions, a surface embedded in Euclidean space and homeomorphic to a sphere separates its complement into two components, one bounded and one unbounded. The tetrahedron's boundary fits these conditions. This establishes separation, not a collider, an entrance or habitability.

[^polyhedra-hull]: Godot's [ConvexPolygonShape3D](https://docs.godotengine.org/en/4.6/classes/class_convexpolygonshape3d.html) is a solid collision shape. The opening here belongs to the rendered mesh, not to that hull. A collision model assembled from surface triangles is a different construction; Godot's [ConcavePolygonShape3D](https://docs.godotengine.org/en/4.6/classes/class_concavepolygonshape3d.html) is intended chiefly for static geometry. This is not an instruction to replace a held object's hull with a concave shape without considering its physics behavior.

[^polyhedra-gibson]: James J. Gibson, [The Ecological Approach to Visual Perception](https://memoof.me/download/1058/pdf/1058.pdf) (1979; linked Classic Edition), chapter 8, relates a surface's affordance of support to the animal's size, weight and behavior. The wedge invites a computational comparison: passage depends on the surface and the moving body's implementation. The engine's settings do not exhaust Gibson's account of perception or the visitor's bodily experience.

[^polyhedra-descartes]: Descartes' theorem on total angular defect: for a convex polyhedron, the defects at all the vertices sum to 720 degrees, 4π radians. A surface with a hole keeps a different total; Portals counts one.

[^polyhedra-ahmed]: See Sara Ahmed, [Queer Phenomenology](https://www.dukeupress.edu/queer-phenomenology) (2006), Introduction; the fuller discussion accompanies WALK THIS LINE. Here orientation returns through a sign beside a physical boundary. Reading an instruction and meeting collision remain different operations.
