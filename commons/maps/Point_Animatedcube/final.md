# Cube Assembly from Primitives

We have been inside boxes since the first room. Now two wait together on a low table. Their corners occupy the same positions within each form. Across one front face, the amber diagonals run in opposite directions.

<!-- @paired_cube_diagonals -->

At first both faces are flat. Nothing needs to fold along either line. Holding the pink corner on A, we move it a little out of the face's plane. The corresponding corner on B follows by the same amount. The remaining corners stay fixed.

The surfaces no longer agree.

On A, one triangular patch can stay flat while its neighbour tilts. On B, the two patches meet along a diagonal that reaches the moving corner. The same changed positions have produced different surfaces. A choice that seemed incidental when the square was flat has become visible as a crease.[^animatedcube-triangulation]

The difference lives in two short lists. A uses:

```text
[4, 5, 7]   [5, 6, 7]
```

B uses:

```text
[4, 5, 6]   [4, 6, 7]
```

The numbers name corners. Each triple tells the renderer which three positions make a triangle. A's patches share the edge from five to seven; B's share four to six. The diagonal is a relation between entries, not another point hidden inside the square.

We can move around the table and look along each face. The colour difference between its patches helps locate the fold, but the surface itself has changed. Both forms retain eight corners and the same outer edge connections. Equal lengths, right angles and flat faces need not survive the movement.[^animatedcube-boundary]

RESTORE returns both sets of corners to their beginning. The disagreement disappears into two flat squares. Moving the same corner again brings it back. This is a small experiment: one displacement, two choices of triangulation, a consequence we can inspect from more than one side.

REPLAY reveals the corners, edges and patches in sequence around the current positions. It keeps a deformation we have made. Restoration and repetition therefore begin again in different senses. The source geometry already exists before the reveal; the animation stages when its pieces become visible.

FREE / ONE opens the remaining handles on A. B continues to follow its positions. This admits other forms, including crossings and collapsed triangles. The connections can stay valid as lists while the resulting object becomes difficult to call a solid. A retained recipe does not guarantee a good geometric embedding.

<!-- @cube_lines -->

The outline cube and the diagonal plate remain nearby as optional comparisons. With no filled faces, a few edges are enough for us to recognise the box. With the plate, we can inspect one triangle pair without the other sides obscuring it. These are different amounts of evidence for something familiar.

<!-- @cube_diagonal_plate -->

The paired experiment has made a corner movement consequential. Beyond the opening, the folding net offers another way for a flat arrangement to become a box. This time the square faces keep their shapes.

<!-- @polyhedron_nets_cube -->

Further on, six squares wait in the air. Follow the pink one as the net folds. Predict which faces will meet. The last flap closes. The cube shrinks, then drops to the floor.

It stays there for a moment, as though it needs to think. Above it, another net opens. The first cube remains. Each return leaves something behind; the floor begins to hold a collection.

Here each square stays rigid. The hinges turn. At the paired cubes, the same corner movement bent the front faces along different diagonals. Similar-looking movement can come from different operations. Knowing which data changes helps you predict what a form can do.

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
