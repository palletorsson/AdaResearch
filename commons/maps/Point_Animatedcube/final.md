# Cube Assembly from Primitives

You have been inside boxes since the first room. Now one of them lets you take hold of a corner. What must stay in place for it to remain a cube?

<!-- @cube_lines -->

Begin with the outline. Follow the three edges leaving one corner. Look through to the far side. You can recognise a cube before any faces have appeared, although nothing has yet closed the gaps between these lines.

The previous room gave us forms that could support a foot or interrupt a route. Here we return to their construction. What happens when the parts remain connected but their positions change?

<!-- @animatedcubebuilder -->

The builder may have finished before you arrive. Press **REPLAY** on its front instrument. Corners appear, then edges, then triangular patches. Press **PAUSE** at the moment you recognise the shape. How much did you need to see?

Count what you saw. Eight corners, twelve edges, six faces, and eight minus twelve plus six is two, the way it was for the tetrahedron. Every one of the six faces is a quad, and you know from two rooms ago what a quad is: two triangles agreeing to lie flat. So the cube is twelve triangles and six seams, and the seams are hidden only while the faces stay flat. The box you push in every game is twelve of the unit, wearing a skin.

Only this assembly pauses. The folding net and the rest of the room continue. We have borrowed a little attention from a world already running.

The source has prepared the geometry before this presentation begins. The animation reveals pieces that were hidden. What looks like construction is also an arrangement of when we are allowed to see. This is the whole of an animation: two positions and a duration, and the machine fills the between. Keyframes define the targets. Interpolation invents everything else, at whatever easing you asked for.

You met this in the trace room from the other side. There, the machine invented the path between two samples of a hand and called it a line. Here it invents the path between two states of a solid and calls it motion. Nothing about the cube changes while it moves: still eight corners, still twelve triangles, still 720 degrees of corner. What changes is where it is, and the next chapter is about that and nothing else.

Resume. Once the assembly finishes, the numbered corner handles become available. Keep the second builder unchanged as a reference. On the one you will alter, find `v6`. Follow the square face containing `v4`, `v5`, `v6` and `v7`. Predict what will happen if you pull `v6` out of that face's plane, leaving its other corners where they are.

Move it a little. Look along the face. Where did the crease appear?

Try to locate the seam before pressing **DIAGONALS**. The yellow lines show the six diagonals that divide the cube's square faces into triangle pairs. Your hand has made one of those divisions matter.[^animatedcube-triangulation]

That face is stored as two triples:

```gdscript
[4, 5, 7]
[5, 6, 7]
```

Each number names a vertex. Both triples contain `5` and `7`: their shared edge. Only the second contains `6`. When you move that corner, the second triangle tilts while the first stays in place. A face that appeared to be one flat square can now bend along a choice made in its construction.

<!-- @cube_diagonal_plate -->

![The same cube face before and after corner 6 moves out of its plane. Triangles 4-5-7 and 5-6-7 share the amber diagonal; only the second triangle tilts.](/book-review/doc/book/figures/Point_Animatedcube/cube-hidden-diagonal.png)

*The diagonal was already there. Corners 4, 5 and 7 stay still. Moving corner 6 makes the shared edge into a crease.*

<!-- @animatedcubebuilder -->

The builder reads a moved handle back into its position list:

```gdscript
vertices[i] = handle_nodes[i].position / cube_size
```

The edge and triangle lists still refer to the same vertex numbers. The neighbours remain; equal lengths, right angles and flat square faces need not.[^animatedcube-boundary] The display measures the largest corner shift in local metres. It cannot tell us what the changed form is worth.

Release the handle and press **REPLAY**. The layers return around your altered shape. Then try **RESTORE CUBE**. This time the initial corner positions return too. Repeating a presentation and undoing a change are different ways of beginning again.

Compare the two builders. Name one property your alteration preserved and one it lost. You can keep a crease you like without claiming the result is still a cube.

<!-- @polyhedron_nets_cube -->

Further on, six squares wait in the air. Follow the pink one as the net folds. Predict which faces will meet. The last flap closes. The cube shrinks, then drops to the floor.

It stays there for a moment, as though it needs to think. Above it, another net opens. The first cube remains. Each return leaves something behind; the floor begins to hold a collection.

Here each square stays rigid. The hinges turn. In the builder, you moved a corner and bent a square into two differently tilted triangles. Similar-looking movement can come from different operations. Knowing which data changes helps you predict what a form can do.

There are exactly eleven ways to unfold a cube into a single connected sheet of six squares. Not ten, not twelve. A cube is one solid and eleven flat things, and which flat thing it was depends on where you chose to cut. Cutting is a decision. The solid does not remember which one you made.

<!-- @ -->

Now look down at the floor, then along a wall. Find the box form again in the crates. The museum builds its floor slabs and wall blocks from scaled box meshes. The primitive on display has also been carrying us from room to room.

The initial cube pairs twelve triangle patches into six square faces.[^animatedcube-counts] The crates add geometry for planks and reinforcing strips. We can recognise the box across these different meshes.

You can move a corner on the instrument while the museum's boxes support and redirect your body. What we are learning to inspect is also the place from which we inspect it.

<!-- @prefab_box_library -->

The shelf holds twenty-four pickable copies: cardboard boxes, crates, cargo boxes and printed cartons, followed by variations. Take two copies from one family to the worktable. Moving one leaves the other where it was. Give them a neighbour, leave a gap, or begin a stack. A scene can supply the same made object again; the relation between its copies is yours to arrange. Across the aisle, the conveyor will ask you to follow a matching rule.

<!-- @cube_sorting_line -->

A net folds above a conveyor belt. The closed cube drops onto the moving surface. Passing under the printer, it receives one of two editions: cream and red **AGAIN**, or mint and teal **YET**. The shape stays the same. Its surface now asks for a choice.

These are *prefabs*: reusable objects stored as scenes. A placed copy is an *instance*. The printed carton supplies the basket's sample. Each moving delivery has the same cube geometry and pickup behaviour; two shared textures give it the familiar carton editions. The lettering and stripes arrive together, carrying decisions someone has already made. We can begin with a furnished object before knowing how to build each of its parts.

Take an **AGAIN** cube from the belt and release it into the **AGAIN** basket. It shrinks inside. The **YET** basket receives the other edition. Moving one copy leaves the others carrying on along the belt.

There is pleasure in finding it again: a familiar shape, an interval kept, a difference small enough to search for. A crate can belong to the scenery of many games before it belongs to this room. Its familiarity travels with it.

Warhol's *Brillo Boxes* bring another kind of repetition here. His 1964 sculptures were fabricated plywood boxes, painted and screenprinted with commercial packaging imagery. Their exhibition arrangement recalled a warehouse.[^cube-warhol] Work had gone into making something whose appearance was already familiar. Our printed carton is an original design, but it borrows that tension between an ordinary package and an object given our attention.

Let one pass. At the end of the conveyor it falls onto the floor. Let more pass and the copies begin to pile up, keeping the angles at which they land. Neither edition gets a side of its own. They remain available to your hands, but the line keeps adding another task. The round ends when the room fills; the controls let you pause production or start again.

Look between the small cubes in the baskets and the growing pile on the floor. The arrangement records what you sorted and what you left.

<!-- @glove_box -->

And one cube you cannot touch. A sealed chamber with a single glove let into its side, the laboratory's vocabulary for *this work cannot be handled directly*. It is here so the others read as what they are: things you can move. The white cube of the gallery, the box the modernist container is named after, has a glove in its side and asks you not to.

<!-- @first_shadow -->

One triangle, casting a shadow, beside a line that casts none. That is the whole difference between a line and a surface, and the triangle room could only say it. A line has nothing to stop light. The smallest surface the engine accepts is enough.

<!-- @first_phosphor -->

An oscilloscope on a cart, a black shroud, and on the dark glass one green dot, breathing. It is the first point again, the one from the first room, and it is here in the room of the first solid because a chapter that began with *there was a point* should be able to see it from where it ends. Every cube in here is that dot, eight times over, with edges agreed between them.

<!-- @ -->

Read the cartons: **A WORLD / WITHOUT / COMPOSITION**. The supply pile and the stamped crate add **YET**.

*A world without composition yet.* There was already an arrangement around us. Between the table, the belt, the baskets and the floor, another has begun. We have borrowed its parts, and made a relation between them.

Take the crease with you: a small movement exposed a decision inside a familiar shape.

The boxes offered a made object we could use again. The next room offers a rule for making a family of objects: choose how many divisions, and the engine constructs the surface. We have followed a corner through a mesh. Now we can inspect what the engine chooses when we ask it for a sphere.

[^animatedcube-triangulation]: Godot Engine 4.6, [Using the ArrayMesh](https://docs.godotengine.org/en/4.6/tutorials/3d/procedural_geometry/arraymesh.html), rectangle example: four positions are connected by two triangle triples. This builder submits its patches through `SurfaceTool` in triangle mode. A flat convex quadrilateral admits either diagonal; moving a corner out of its plane can make that choice visible as a different crease.

[^animatedcube-boundary]: *Connectivity* names which vertices, edges and faces are incident; their positions place that structure in space. Compare the separate point and connectivity properties in Botsch, Sieger, Moeller and Fabri's [Surface Mesh manual](https://doc.cgal.org/latest/Surface_mesh/index.html), CGAL 6.2.1, “Connectivity” and “Properties.” Here the index lists preserve the combinatorial structure, but moving vertices may produce crossings or collapsed faces, so a valid geometric embedding is not guaranteed. The builder's patches also lack enclosing collision geometry; its handles have pickup colliders. See the [technical chapter](/book?map=Point_Animatedcube&section=technical).

[^animatedcube-counts]: Euler's [Elementa doctrinae solidorum](https://scholarlycommons.pacific.edu/euler-works/230/) (1758) investigates polyhedral counts. For the initial cube, `V - E + F = 8 - 12 + 6 = 2`. Splitting its squares adds six diagonals and six faces: `8 - 18 + 12 = 2` again. A proof for the sphere's triangulation appears in Heinz Hopf's [Selected Chapters of Geometry](https://pi.math.cornell.edu/~hatcher/Other/hopf-samelson.pdf), §I.3, from his 1940 lectures reconstructed and translated by Hans Samelson. The equality does not certify cube shape or a valid embedding. The instrument counts twelve patches, excluding reverse rendering copies.

[^cube-warhol]: The Andy Warhol Museum, [Brillo: Is It Art?](https://www.warhol.org/lessons/brillo-is-it-art/), on the fabrication and 1964 Stable Gallery exhibition. These were constructed sculptures carrying packaging imagery. The library’s AGAIN carton is a new design for this encounter.
