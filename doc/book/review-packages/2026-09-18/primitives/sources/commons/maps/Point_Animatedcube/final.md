You have been inside boxes since the first room. Now one of them lets you take hold of a corner. What must stay in place for it to remain a cube?

<!-- @cube_lines -->

Begin with the outline. Follow the three edges leaving one corner. Look through to the far side. You can recognise a cube before any faces have appeared, although nothing has yet closed the gaps between these lines.

The previous room gave us forms that could support a foot or interrupt a route. Here we return to their construction. What happens when the parts remain connected but their positions change?

<!-- @animatedcubebuilder -->

The builder may have finished before you arrive. Press **REPLAY** on its side instrument. Corners appear, then edges, then triangular patches. Press **PAUSE** at the moment you recognise the shape. How much did you need to see?

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

Read the cartons: **A WORLD / WITHOUT / COMPOSITION**. The supply pile and the stamped crate add **YET**.

*A world without composition yet.* There is already an arrangement around us; the words cannot make it disappear. We can recognise what the museum is made from before we know how to compose another one.

The crates, glove box, shadow and glowing point offer more ways into that question. They can wait for a [return visit](/book?map=Point_Animatedcube&section=tutorial). For now, take the crease with you: a small movement exposed a decision inside a familiar shape.

The next room asks what an engine gives us when it supplies another familiar name: a sphere.

[^animatedcube-triangulation]: Godot Engine 4.6, [Using the ArrayMesh](https://docs.godotengine.org/en/4.6/tutorials/3d/procedural_geometry/arraymesh.html), rectangle example: four positions are connected by two triangle triples. This builder submits its patches through `SurfaceTool` in triangle mode. A flat convex quadrilateral admits either diagonal; moving a corner out of its plane can make that choice visible as a different crease.

[^animatedcube-boundary]: *Connectivity* names which vertices, edges and faces are incident; their positions place that structure in space. Compare the separate point and connectivity properties in Botsch, Sieger, Moeller and Fabri's [Surface Mesh manual](https://doc.cgal.org/latest/Surface_mesh/index.html), CGAL 6.2.1, “Connectivity” and “Properties.” Here the index lists preserve the combinatorial structure, but moving vertices may produce crossings or collapsed faces, so a valid geometric embedding is not guaranteed. The builder's patches also lack enclosing collision geometry; its handles have pickup colliders. See the [technical chapter](/book?map=Point_Animatedcube&section=technical).

[^animatedcube-counts]: Euler's [Elementa doctrinae solidorum](https://scholarlycommons.pacific.edu/euler-works/230/) (1758) investigates polyhedral counts. For the initial cube, `V - E + F = 8 - 12 + 6 = 2`. Splitting its squares adds six diagonals and six faces: `8 - 18 + 12 = 2` again. A proof for the sphere's triangulation appears in Heinz Hopf's [Selected Chapters of Geometry](https://pi.math.cornell.edu/~hatcher/Other/hopf-samelson.pdf), §I.3, from his 1940 lectures reconstructed and translated by Hans Samelson. The equality does not certify cube shape or a valid embedding. The instrument counts twelve patches, excluding reverse rendering copies.
