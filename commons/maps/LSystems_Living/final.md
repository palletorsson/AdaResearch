# What counts as a change?

<!-- @genetic_tree_sculptor -->

The tree waits above a low plinth. Beside it is a place for another tree. Press HOLD. Now there are two: the design we can change and a witness that will stay where we left it.

In Competition, the same grammar met different conditions. Here we reach further back, towards the numbers from which a grammar is made. The desk begins with Depth selected. Its value is 4.000. Press MORE once. The number changes. Look at the branches.

Try again. And again. By 4.800, the number has moved four times, but the tree still agrees with its witness. Is the control doing anything?

One more press reaches 5.000. Another generation of branching appears.

The control has been changing a value called segments in the DNA resource. DNA here means a collection of parameters used to construct a body. It is a name for this data structure; the name does not establish that the specimen is alive. The tree generator reads that value through this line:

```gdscript
var generations: int = clampi(roundi(dna.segments * 0.5), 2, 5)
```

First halve the raw number. Then round it to a whole number. Finally keep the result between two and five. At 4.800, the intermediate value is 2.400; it rounds to two. At 5.000, it is 2.500; it rounds to three. The number we moved and the instruction the generator received are different records.

We have encountered this gap before. A trace records a hand at particular moments; the record cannot contain every position between them. Here a continuous control is translated into whole rewriting generations. Several distinct settings produce the same instruction. That is useful: a generation must be a count. It is also a place to look when a desired difference disappears.

The tree still starts with F. At each rewrite, F becomes a short stem S followed by bracketed branches. The Forks gene supplies their count and Arrange supplies their turns. S, in turn, becomes FF. The turtle then reads the completed sentence, advancing, turning, saving a state at an opening bracket and returning at its closing partner. The earlier grammar lessons are inside this instrument.

Use GENE to pass through Forks and reach Angle. A small increase now changes the directions of the branches without adding a rewriting generation. Two controls move smoothly under the hand, yet one crosses a counting threshold while the other changes geometry. A control's appearance cannot tell us what kind of change it offers.

Press PLANT. A copy appears on the floor pad beyond the two plinths. Change the editing tree again. The placed one keeps its form. HOLD keeps its own witness too. RESET restores the opening design and leaves these copies for comparison.

This steadiness had to be written. The export used to point at the same editable DNA resource. Moving a slider could therefore change the data that a later consumer would receive. Now the export begins by making a copy:

```gdscript
var snapshot := _dna.duplicate(true) as CritterDNA
Engine.set_meta("sculptor_tree_dna", snapshot)
```

The hall also copies the displayed geometry onto its planting pad. A later PLANT replaces that local specimen. The older branching catalyst has a different use for the exported DNA: it may mutate and rescale a copy when producing a temporary tree. Placing a specimen here does not recruit it into Competition's soil or teach the floor to grow.

The original eight sliders remain on the side rack, including RANDOM. They offer more ways into the same resource. Eight controls are still only a selection from the parameters and rules that make the body. They cannot ask for a new alphabet, a branch joined back to an earlier branch, or a different relation to the ground. Those changes require another part of the program.

Push Depth and Forks towards their upper limits and read the command count. The sentence can request more branches than this preview will draw. At its current detail level, the interpreter stops after two hundred F or S drawing commands; very short segments may produce no mesh at all. The display names that budget. What looks like a finished crown may be the point where drawing was stopped.

There is pleasure in finding a body among these variations. There is another kind of curiosity when the variation we want has no control. Stay with that desire long enough to name what is missing: another connection, another rule, another way of occupying the room. Then we have somewhere specific to continue writing.

<!-- @ -->

The older tree, coral and paper studies remain beyond the workbench, among the authored platforms. Each makes form through its own procedure. Next, two diagonal marks will invite us to see paths in a textile. We carry the distinction between the instructions that made a surface and the possibilities we read in it.
