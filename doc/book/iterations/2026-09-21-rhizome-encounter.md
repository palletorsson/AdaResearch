# Rhizome: seeing the whole, entering a relation

Author direction, 21 September 2026: the rhizome is visually and topologically strong. We want to see and experience its complexity. *A Thousand Plateaus* supplies a critical interlocutor. The difficulty of making this into an inhabitable map is productive artistic work.

This is a spatial brief and a short proposed passage, not a completed map or an applied manuscript revision.

## The encounter to build

Approach a branching volume large enough to enter. Several openings belong to the same visible structure. Passages separate, disappear behind others and meet again. Some cross at different heights without meeting. An outside glimpse helps the visitor form an expectation; going inside makes that knowledge partial. A return can reveal that two openings belong to the same circuit.

Keep its visual intricacy. Let light, differing chamber shapes and glimpses through openings help someone recognise where they have been. Do not simplify the network into a corridor with painted branches, or turn the encounter into a hunt for the correct exit. The museum still needs an onward route, but exploring a loop must have value of its own.

The first prototype needs actual junctions, alternative walkable routes and a return, together with at least one visible crossing that is not a junction. Build stable footing and body clearance into the passages. Upper branches can extend the visible structure without pretending every visible opening is already reachable. Start with walking; automatic flight or forced camera motion would change the question.

The small grower can remain nearby as a supporting comparison. Encounter the larger space first; the model then helps someone investigate what a connection rule does. These are currently different generators. Do not present the model as a live map of the cave until they really share data.

## What this can teach, and open

The line hall offered a line to walk. Here a line can divide and rejoin another. Making a route requires more than drawing its centre: width, slope, surface and collision determine whether this body can take it. A connection in a stored graph, a visible opening and a walkable passage are related constructions, not interchangeable facts.

This lets the critical question emerge through movement: **what relations can I enter, and what changes when I enter from somewhere else?** Beauty, curiosity, shelter and the pleasure of finding another way are material for the chapter. They need not be justified by an immediate failure.

Deleuze and Guattari's introduction connects the rhizome with heterogeneous relations, multiple entryways, modification and renewed growth after rupture (Massumi translation, 1987, pp. 7–15). A static network of tunnels offers a starting encounter with some of these concerns; it does not exhaust them. In a later experiment, opening a new passage could change the visitor's possibilities, making modification something experienced. That is future work, not a new control promised for the first prototype.

Keep one productive tension: a museum whose spine leads forward can contain a space explored by returns and sideways relations. Neither a loop nor the absence of a named root guarantees freedom. Equally, a generator's first instruction does not make rhizomatic experimentation impossible.

Source read: [*A Thousand Plateaus*, Introduction: Rhizome](https://studylib.net/doc/27308768/a-thousand-plateaus). [Publisher edition](https://www.upress.umn.edu/9780816614028/a-thousand-plateaus/).

## A small voice trial

Current opening of `commons/maps/SpeculativeComputation_Rhizome_Network/final.md`:

> Can local connections build a network without first choosing its centre?
>
> Watch for a new node and follow the segments it adds. Compare a crowded part of the structure with a sparse part. Predict which existing nodes are likely to receive the next connections, then check the new shoot against your prediction.

Proposed opening for the intended immersive encounter, pending construction and a reading decision:

> From outside, you can follow several passages with your eyes. One goes behind another. There seems to be a way through.
>
> Inside, the wall takes away that view. An opening offers two directions. Further on, another passage brings you back to a place you recognise, approached from a side you had not noticed.
>
> You have returned without retracing your steps. What looked like a branch has become another way through.

Let play determine whether this passage holds. The next paragraph can reveal the particular rule that made the return possible, with a small piece of useful code. It need not explain the whole theory before the reader has somewhere to stand.

## Existing material and first construction task

Source inspection found an existing base, not an empty brief:

- `algorithms/spacetopology/marchingcubes/scenes/rhizome_cave_demo.tscn` attaches `RhizomeCaveDemoController.gd`; the similarly named scene under `algorithms/marchingcubes/scenes/` is a stub.
- `RhizomeCaveGenerator.gd` grows from a central seed, carves connections and chambers into a voxel field, extracts a mesh and creates a collision shape. `RhizomeGrowthPattern.gd` includes branching and merging. None of this alone establishes a traversable loop in the placed museum artifact.
- The current hall retains the cave as secondary while promoting `rhizome_grower`. Its earlier tests covered the grower and selected surrounding walks, not inhabiting the cave.
- The old critical text has useful leads about orientation and underground relations. Recover those selectively. Do not restore its blanket claim that computation cannot implement a rhizome, or equate a smooth extracted mesh with Deleuze and Guattari's smooth space.

Next: stage and inspect a repeatable cave at body scale, then adapt its geometry and placement until a visitor can actually enter, choose and return. Capture the outside and the inside of that same construction. Verify the particular walking routes; assess whether the structure remains visually compelling. Only then revise the chapter around the experience that exists.

Preserve the current final.md, including the fixed-territory paragraph, until that comparison can be made. No map, artifact, role or manuscript was changed in this brief.
