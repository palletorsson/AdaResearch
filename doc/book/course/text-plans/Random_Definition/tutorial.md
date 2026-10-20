# Random Definition — one value, four consequences

## One table, one button · 16 October 2026

The installed shelf now has a small protruding tabletop extension with one upward-facing NEXT button. The earlier four floating controls are removed from the hall version. NEXT cycles the eight retained values; the standalone learner preview keeps its recording controls for the experiment loop. Seed binding, four assignments, placement and first 48-value pilot remain unchanged.


15 October 2026 · [Tutorial](../../../../../commons/maps/Random_Definition/tutorial.md) · [Runnable shelf](../../../studies/randomness-shelf/preview.tscn) · [Previous abacus plan](../../../iterations/2026-10-15-randomness-tutorial-shelf/before/tutorial-plan.md)

Palle asks to isolate a small part of the code for an introductory tutorial shelf. The agreed arrangement shows all four examples together: move a point along a line, scale a point, rotate a cube and change a sphere's colour. Each receives the same stored number. The central subject is what we direct randomness towards.

## Teaching sequence

1. Build or inspect the shelf's four simple objects. Inherit geometry, materials and transforms from earlier lessons.
2. Read the four assignments in `show_sample()`. One unit-interval value becomes an X coordinate, uniform scale, Y rotation and hue. Explain mapping, interpolation and hue inline.
3. Follow the local generator: seed 435, eight draws once, then read the retained array. NEXT changes the index; REPLAY returns to its beginning. No smoothing or automatic clock hides the assignment.
4. Predict the consequences of a known value. The same value is deliberately coupled across the objects; independent draws would be a separate experiment.
5. Keep a baseline; change only the X extent from 0.4 to 0.2. Compare the same sample numbers while the other assignments remain fixed. Keep the observation, including no gain.
6. Reopen the record, replay it, have another person reconstruct the shelf, and propose one further intervention justified by what happened.
7. Carry the generator, retained array and distinction between value and consequence to Entropy. That lesson makes a new categorical sample rather than importing shelf records.

## Scope and completed work

- [x] Install the four-assignment shelf in Random Definition, with shared-seed binding and a Tutorial-only writing-wall magnet (16 October).

- [x] Replace the introductory chapter with one complete **26-line script**, 770 prose words, and a concrete scene-assembly table.
- [x] Build an editable four-object scene and a desktop preview with NEXT, REPLAY, KEEP and LOAD. Reuse the museum's rectangular 3D buttons.
- [x] Keep notebook and control implementation separate from the introductory code. Saved records retain exact values, current index, X extent and mapping version, with observation/next-change fields.
- [x] Preserve the full abacus reconstruction as [an extension](../../../../../commons/maps/Random_Definition/abacus-reconstruction.md). Retarget its builder and verifier to that extension, so they cannot overwrite the small introduction.
- [x] Update Entropy's two incoming paragraphs to acknowledge the new shelf; its procedure and code are unchanged.
- [x] Verify the exact printed file in a fresh scene: **39 checks pass**, including all four mappings, controlled range change, replay, unique saves, exact load, material isolation and rejection of incompatible records.
- [x] Render and inspect the shelf. Correct nonuniform scaling of inherited button physics; the final render has no engine errors.

The **48-value seed bench remains the first research pilot**. The eight-value tutorial shelf is an introduction to assigning a sample, not a replacement or a new claim that the first pilot is complete. The room's abacus and final text remain current encounters; the shelf is now also registered and placed beside the colour-grid window at source cell (8, 13), facing 180 degrees. Its standalone seed is 435; the museum adapter follows explicit hall-seed changes. KEEP/LOAD retain exact values, sample and range, and LOAD recalls the saved seed across the hall. The introductory 26-line assignment script is unchanged.

## Remaining observations

The [sequence comparison and proposed progression](../../randomness-tutorial-progression.md) places this shelf first in eight cumulative core builds across the existing fourteen-map route. Its next proposed step retains the shelf values, classifies them into four categories, then counts and rearranges them in Entropy. That record transfer is not yet implemented; the current Entropy lesson still makes a new categorical sample. Entropy's [expanded research brief](../Random_Entropy/research-brief.md) makes this an entrance into conditional measures, spatial partitions and a statistical-physics bridge, not the full scope of that foundational hall. The six other maps remain application or advanced workshops in the proposal.

- [ ] Watch a learner make the four assignments and explain which part changes when a range changes. Correct the lesson where the source, stored value or destination becomes unclear.
- [ ] Collect an independent reconstruction and a physical VR interaction trial. Automated scene/record tests do not establish either.
- [ ] Use that observation to choose a next intervention: frequency, a new destination, or a different recording rule. Keep it to one changed condition.
- [ ] If the shelf becomes an installed artifact, register it, bind it to the hall seed, place it through the writing wall and check the generated room. Room/final order is not silently changed by this lesson revision.

[Source, builder and verification receipt](../../../iterations/2026-10-15-randomness-tutorial-shelf/README.md) are the current entry point. The [abacus experiment-loop evidence](../../../iterations/2026-10-15-abacus-experiment-loop/README.md) remains available for the advanced extension. Artifact correctness, experiment-cycle evidence and specified integration are separate from performance and headset experience. Both tutorial and final can propose and revise experiments; neither dictates what a learner must feel.
