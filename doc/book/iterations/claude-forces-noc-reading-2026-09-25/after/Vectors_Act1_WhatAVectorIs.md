# The same difference, somewhere else

<!-- @VectorBasics -->

Two pins hold a small arrow between them. On the wall, two larger yellow arrows show it from different directions: one from the side, one from above. Move the tip. The wall answers.

Now **SHIFT** moves both pins sideways together. The small arrow has gone somewhere. The two wall arrows stay where they were.

We can see the movement and the lack of change at once. The wall has been asked for the difference between the pins. Both addresses have changed by the same amount, so their difference has not.

The point rooms gave us addresses; transformation let us move them. The particles in the last room followed directions. Here we can carry a relation from one place to another. *This far, this way* can begin somewhere else.[^stick-chart]

**PARTS** brings out the coloured component legs and their numbers. The calculation is short:

```gdscript
var displacement = end.global_position - start.global_position
```

The subtraction gives the displacement from the beginning to the end. It does not retain either address on its own. Many pairs of points can make this same arrow.

With **SHORT** and **LONG**, the gap changes from a quarter metre to one metre. Its direction stays. The wall pictures grow, although their display scale differs from the arrow in our hands. What they share is the measured displacement.

One wall view keeps X and Y, leaving out depth along Z. The other keeps X and Z, leaving out height along Y. Move the tip in a direction that disappears from one view and watch it arrive in the other. A movement can be missing from a picture while still taking place in the room.

These are world axes. Turning the bench changes its relation to them; it does not turn the world's frame with it. The arrow has a direction within an arrangement we inherited when we entered.

**ZERO** brings the pins together. There is no longer a direction from one to the other. SHORT or LONG can separate them again, but now the control has to supply a direction: it chooses the normalised diagonal (1,1,1). There was no little arrow hidden inside zero, waiting to be enlarged.

<!-- @ -->

The coordinate frame, route courier and length lantern remain nearby. A courier has to begin somewhere, even when its instruction is only *this far, this way*. Later, the point where a force is applied will matter too. The freedom to move a displacement arrow does not make every use of a vector independent of place.

<!-- @vector_normalize_demo -->

At the next diagram, a sphere gives the companion arrow a reference for unit length. Lengthen the input: its companion keeps its length. Change the direction: both turn.

A long arrow becomes shorter here. A short one becomes longer. Both have one unit of length, with their different directions intact.

This is normalisation. A nonzero vector is divided by its own magnitude:

```gdscript
var magnitude = v.length()
var unit = v / magnitude if magnitude > 0.001 else Vector3.ZERO
```

The sphere and rings make that common length visible at the scale of the diagram. They do not tell us how far a body should travel. A unit direction could guide a short step or a long journey; we would have to supply the distance separately.

Near zero, the companion has no length to draw. The code treats any input length at or below 0.001 as too small to supply a direction and returns zero instead. That small neighbourhood belongs to the implementation. Mathematics leaves only the exact zero vector without a direction.

<!-- @ -->

At the first bench, the same difference could begin elsewhere. At the second, different lengths could share a direction. These are two ways of finding something in common without making the inputs identical.

In the next room, two displacements meet. The question becomes where they can take us together.

[^stick-chart]: Before the arrow there was the frond. The navigators of the Marshall Islands tied the directions of ocean swells and the positions of islands into lattices of coconut-frond midribs and shells, the mattang, meddo and rebbelib stick charts: an instrument of *this far, this way*, memorised before a voyage and left ashore. *Nature of Code* opens its chapter on vectors with one.
