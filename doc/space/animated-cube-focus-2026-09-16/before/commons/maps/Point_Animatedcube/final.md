You have been inside boxes since the first room. What makes one of them a cube, and what remains when you move one corner until it no longer deserves that name?

<!-- @cube_lines -->

Begin with the outline. Pick one corner to follow and count the edges leaving it. Trace the outline around one face, then look through to the corresponding corners on the far side. Predict what would have to be added to close it.

<!-- @polyhedron_nets_cube -->

Watch the flat net fold. Choose one square and follow it all the way into the enclosure and back out as the loop repeats. Before the next fold, predict which squares will become neighbours.

Six squares, cut into a connected sheet, can hinge into the boundary of a cube. The net does not fill a volume with material; it shows how faces can meet around one. Cutting along other edges can produce other valid nets. The closed cube does not preserve the history of which cuts you chose.

<!-- @animatedcubebuilder -->

The builder may have finished before you arrive. Its first assembly began on its own clock. Find **REPLAY** on the side instrument and watch the layers return: corners, edges, then triangular patches. Press **PAUSE** when something becomes recognisable. How much had appeared when you first saw a cube?

Only this assembly pauses. The room continues around it. The instrument gives us a little time to attend to something we could otherwise have missed.

Resume the assembly. When it completes, its numbered corner handles become available. Choose `v6` or another corner you can reach. Predict which edges will follow and which triangular patches will tilt, then move it slightly. Leave the other corners in place. Keep the second builder unchanged as a reference before making a larger deformation.

The side display counts the visible layers. Its corner-shift reading measures the largest distance from an initial corner position, in the artifact's local coordinates. That number can tell you that a point moved. It cannot decide whether the result is interesting, useful, or still a cube.

The initial cube has eight vertices, twelve edges and six square faces. Each square is divided into two triangles, making twelve surface patches. This artifact also draws reverse copies to show their backs; the instrument counts patches, not those extra rendering triangles. Counting the geometric squares gives `8 - 12 + 6 = 2`. Counting the triangulation introduces six face diagonals as additional edges and gives `8 - 18 + 12 = 2`.

The builder reads new handle positions against the same lists of connected vertices:

```gdscript
vertices[i] = handle_nodes[i].position / cube_size
```

The positions change; the connection lists remain. That keeps a pattern of neighbours while you move the points. It does not keep every edge equal, every angle right or every pair of triangles coplanar.

If a formerly flat face acquires a crease, locate its diagonal before pressing **DIAGONALS**. The yellow lines reveal the six connections added when the squares became triangle pairs. They are derived from the same triangle list as the surfaces.

One front face uses these two triples:

```gdscript
[4, 5, 7]
[5, 6, 7]
```

Find the pair that appears in both: `5` and `7`. That is the shared diagonal. Move `v6` and the second triangle changes while the first can stay where it was. The seam was already there. Your hand made its consequence visible.

Release the corner and press **REPLAY** again. The builder now assembles your changed form. Replay returns to the beginning of a presentation; **RESTORE CUBE** returns the eight corner positions to their initial values. These are different returns.

<!-- @ -->

## What stays the same?

Choose a modest deformation and name one property that survived and one that did not. “It is still a cube” is a stronger statement than “the connection list is unchanged.” Try to say which you mean.

A sufficiently free deformation can make triangles collapse or cross. At that point a list with the old counts is not proof of a valid enclosure. The tool follows the vertices; a validator would have to ask additional questions about the resulting geometry.

The other builder can remain your reference. Use the changed one to make something whose purpose you choose: a bent shelter, an awkward opening, a form valued for the silhouette it casts. Give it a name based on that purpose, then separately state which geometric properties changed. Leaving the category of “cube” need not end the experiment.

<!-- @ -->

## Given time

The folding net changed the angles between faces. The builder changed which pieces were visible. Your hand changed vertex positions. All three can look like a cube “moving”, although they act on different data.

The folding net animates a named property:

```gdscript
tween.tween_property(self, "fold_progress", 1.0, fold_duration)
```

This line is part of its actual folding sequence. The property then determines hinge angles; it does not move every corner independently. The builder instead reveals prepared pieces in timed steps. Specifying what changes matters as much as specifying how long it takes.

You met interpolation from the other side in the trace room. There the renderer connected retained samples of a movement. Here a target and a timing rule can generate intermediate states. A convincing between still needs an account of how it was made.

<!-- @ -->

## Further comparisons: a world without composition yet

A crate makes the box familiar again: a thing to ship, stack, open or hide behind. Compare its edges with the builder's. A detailed crate can use many more triangles than a bare cube; its resemblance to a box is not an invoice for exactly twelve.

Read the words on the cartons: **A WORLD / WITHOUT / COMPOSITION**.

The supply pile adds **WITHOUT COMPOSITION / YET**. The *yet* makes a promise about what the curriculum will ask next.

These objects have already been arranged. Their words cannot erase that arrangement. What remains to learn is how to choose and examine it: what should be next to what, what deserves attention, and whose movement a collection invites. Knowing the parts does not settle those questions.

Look at the stack as an arrangement rather than as several examples of the same primitive. Which piece seems accessible, protected or forgotten? Those readings come from relations between bodies and a visitor.

The sealed chamber puts a glove between an imagined worker and the contents. Compare the permission it suggests with the exposed vertex handles. A box can frame an encounter with work as well as enclose a space.

Compare the small triangle and line in the shadow display. Look for the shadow, then for the object that produces it. What a rendered mark can occlude depends on its geometry, material and light settings. A line drawn as a thin body is different from an ideal dimensionless line.

On the dark glass, a green dot. The point is here again, now encountered through an instrument and its glow. After learning a solid, you can still return to a single location and ask what was added to make it visible.

<!-- @ -->

Leave the room able to distinguish moving a whole object, deforming its vertices, folding its faces and revealing its layers. Predict one invariant before choosing an operation, then check it on the available example.

The next room puts the familiar names under pressure. When an engine offers a sphere, how much geometry has it spent to make that name seem obvious?
