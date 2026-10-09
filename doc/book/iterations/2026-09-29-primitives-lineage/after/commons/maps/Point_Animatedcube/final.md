# Cube Assembly from Primitives

You have been inside boxes since the first room. Now one of them lets you take hold of a corner. What must stay in place for it to remain a cube?

<!-- @cube_lines -->

Begin with the outline. Follow the three edges leaving one corner. Look through to the far side. You can recognise a cube before any faces have appeared, although nothing has yet closed the gaps between these lines.

The previous room gave us forms that could support a foot or interrupt a route. Here we return to their construction. What happens when the parts remain connected but their positions change?

<!-- @animatedcubebuilder -->

The builder may have finished before you arrive. Press **REPLAY** on its front instrument. Corners appear, then edges, then triangular patches. Press **PAUSE** at the moment you recognise the shape. How much did you need to see?

Only this assembly pauses. The folding net and the rest of the room continue. We have borrowed a little attention from a world already running.

The source has prepared the geometry before this presentation begins. The animation reveals pieces that were hidden. What looks like construction is also an arrangement of when we are allowed to see.

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

Further on, watch the net fold. Choose one square and follow it from the flat arrangement into the closed form. Before it folds again, predict which faces will meet.

Here each square stays rigid. The hinges turn. In the builder, you moved a corner and bent a square into two differently tilted triangles. Similar-looking movement can come from different operations. Knowing which data changes helps you predict what a form can do.

<!-- @ -->

Now look down at the floor, then along a wall. Find the box form again in the crates. The museum builds its floor slabs and wall blocks from scaled box meshes. The primitive on display has also been carrying us from room to room.

The initial cube pairs twelve triangle patches into six square faces.[^animatedcube-counts] The crates add geometry for planks and reinforcing strips. We can recognise the box across these different meshes.

You can move a corner on the instrument while the museum's boxes support and redirect your body. What we are learning to inspect is also the place from which we inspect it.

<!-- @prefab_box_library -->

A long shelf holds boxes. Brown cardboard, wooden crates, dark cargo cases, bright printed cartons. Four columns repeat four different models. In the last two, the crate and the printed carton return with changed colours, boards and words. The eye starts sorting before the hand reaches anything.

![The Cube hall’s shelf of cardboard boxes, wooden crates, cargo cases and printed cartons, with an empty table in front.](/book-review/doc/book/figures/Point_Animatedcube/prefab-library.png)

*The first four columns repeat their models. The last two let the same model differ.*

These are *prefabs*: reusable objects stored as scenes. A placed copy is an *instance*. The planks, straps and lettering arrive together, carrying decisions someone has already made. We can begin with a furnished object before knowing how to build each of its parts.

One carton says **AGAIN**. Take it down. Another says the same thing from the shelf. Moving your copy has left the others where they were.

There is pleasure in finding it again: a familiar shape, an interval kept, a difference small enough to search for. A crate can belong to the scenery of many games before it belongs to this room. Its familiarity travels with it.

Warhol's *Brillo Boxes* bring another kind of repetition here. His 1964 sculptures were fabricated plywood boxes, painted and screenprinted with commercial packaging imagery. Their exhibition arrangement recalled a warehouse.[^cube-warhol] Work had gone into making something whose appearance was already familiar. Our printed carton is an original design, but it borrows that tension between an ordinary package and an object given our attention.

The table is empty. Put two identical copies together. Add a different box. Turn its lettering away, or let **AGAIN** face **OTHER**. You have kept the supplied shape and changed its neighbours. The collection offers a vocabulary; it also makes some choices easier to imagine than others.

Look back at the gaps on the shelf. The arrangement records what you took.

<!-- @ -->

Read the cartons: **A WORLD / WITHOUT / COMPOSITION**. The supply pile and the stamped crate add **YET**.

*A world without composition yet.* There was already an arrangement around us. On the table, another has begun. We have borrowed its parts, and made a relation between them.

Take the crease with you: a small movement exposed a decision inside a familiar shape.

The boxes offered a made object we could use again. The next room offers a rule for making a family of objects: choose how many divisions, and the engine constructs the surface. We have followed a corner through a mesh. Now we can inspect what the engine chooses when we ask it for a sphere.

[^animatedcube-triangulation]: Godot Engine 4.6, [Using the ArrayMesh](https://docs.godotengine.org/en/4.6/tutorials/3d/procedural_geometry/arraymesh.html), rectangle example: four positions are connected by two triangle triples. This builder submits its patches through `SurfaceTool` in triangle mode. A flat convex quadrilateral admits either diagonal; moving a corner out of its plane can make that choice visible as a different crease.

[^animatedcube-boundary]: *Connectivity* names which vertices, edges and faces are incident; their positions place that structure in space. Compare the separate point and connectivity properties in Botsch, Sieger, Moeller and Fabri's [Surface Mesh manual](https://doc.cgal.org/latest/Surface_mesh/index.html), CGAL 6.2.1, “Connectivity” and “Properties.” Here the index lists preserve the combinatorial structure, but moving vertices may produce crossings or collapsed faces, so a valid geometric embedding is not guaranteed. The builder's patches also lack enclosing collision geometry; its handles have pickup colliders. See the [technical chapter](/book?map=Point_Animatedcube&section=technical).

[^animatedcube-counts]: Euler's [Elementa doctrinae solidorum](https://scholarlycommons.pacific.edu/euler-works/230/) (1758) investigates polyhedral counts. For the initial cube, `V - E + F = 8 - 12 + 6 = 2`. Splitting its squares adds six diagonals and six faces: `8 - 18 + 12 = 2` again. A proof for the sphere's triangulation appears in Heinz Hopf's [Selected Chapters of Geometry](https://pi.math.cornell.edu/~hatcher/Other/hopf-samelson.pdf), §I.3, from his 1940 lectures reconstructed and translated by Hans Samelson. The equality does not certify cube shape or a valid embedding. The instrument counts twelve patches, excluding reverse rendering copies.

[^cube-warhol]: The Andy Warhol Museum, [Brillo: Is It Art?](https://www.warhol.org/lessons/brillo-is-it-art/), on the fabrication and 1964 Stable Gallery exhibition. These were constructed sculptures carrying packaging imagery. The library’s AGAIN carton is a new design for this encounter.
