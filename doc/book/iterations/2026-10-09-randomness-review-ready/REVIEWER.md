# Randomness — review brief

Please read `tutorial.md` and `final.md` as two tracks through the same fourteen museum halls. `tutorial.html` and `final.html` are formatted versions; `parallel.html` places them beside each other. Start with the texts before reading our change report, so our assessment does not determine yours.

## Where this chapter sits

This is part of **Endless Museum**, a working Godot 4.6 desktop/VR world and a book written alongside it. The student arrives in an existing museum, encounters an artifact, and reconstructs one selected operation beside it. The project already supplies the player, XR Tools, camera, light and floor. The examples create their own lesson geometry and retain references to it. They do not require undisclosed scene children.

Day Zero establishes the environment and how to run a script. Earlier chapters introduce points, local/world coordinates, pickup, lines and traces, meshes and primitives, transformations, arrays, colour, repeated patterns, movement and forces. The immediately preceding Wavefunctions sequence develops time, phase, spatial functions, retained scores and weighted sums. Randomness should use that capacity rather than teach the whole course again. Noise follows this chapter.

The sphere/PointBody and cube are familiar constructions. PointBody sometimes becomes the subject, as in Walk; elsewhere it supplies the hand control. The lineage does not imply a single saved node or dataset travelling through all fourteen rooms. Distinguish reuse of a construction from actual transfer of a record.

## The two texts have different jobs

- **tutorial.md:** context, the focused operation, all required code, explanation, a change the student can make and a result they can check. Previously learned dependencies remain printed and available in `learner/`; the HTML folds some of them to keep attention on the new operation.
- **final.md:** the encounter and its critical or poetic implications. Several artifacts may matter here even though only one carries the tutorial. Detailed operating qualifications are kept in notes where they would interrupt the reading.
- Some museum artifacts belong to neither text. The museum is a larger field of investigation than either reading track.

The route keeps fourteen teaching halls. Biome Cage remains an unnumbered encounter after Mushrooms. The closing Biome Ladder is deferred. Random Game leads directly to Noise Types.

## Read as the ghost student

Imagine a future student choosing to learn these operations even when a machine can generate the result. Prior knowledge is the curriculum above; it is not omniscience. For each lesson, ask what you can now build, change and explain. Do not silently repair a missing dependency or use later knowledge to make an unclear instruction work. Report the point where the text needs something it has not supplied.

Please assess:

1. Is the new operation distinct from the surrounding museum content? Can you identify the few functions that carry it?
2. Does it use something learned earlier and add a capability worth carrying onward?
3. Can its complete printed files reconstruct the promised operation in the prepared project? Identify any missing initialization, dependency or ambiguous edit.
4. Do the prediction and independent change reveal understanding, or only successful copying?
5. Does the reflection develop what the encounter makes possible without becoming an operating manual? Where does precision strengthen the writing, and where does it interrupt it?
6. Do the late transitions—spatial relationship, estimation, feedback, field composition, timed consequence—remain legible? Name an actual prerequisite problem if you recommend reordering.

Use hall names and quote a short passage for each finding. Separate **blocking errors**, **learning/progression issues**, **editorial suggestions** and **questions requiring a visit to the museum**. Preserve passages that work. Do not invent a defect merely to fill a category.

## What the evidence establishes

The `learner/` directory contains freshly extracted complete files, one folder per lesson. Fourteen baseline programs were run through the existing native Godot assertion probes after this editorial pass: **420 checks passed**. The current GDScript blocks match their pre-edit versions. Reports and logs are in `tests/`, with an overview in `tests.json`; the probe sources are included for inspection.

These probes supply actions and check state, geometry, replay and selected invariants. They do not simulate an unfamiliar person's comprehension. Earlier hall reviews contain additional variations, deliberate faulty programs and native museum captures. They have not all been rerun in this pacing pass. The artifact algorithms and museum layout have not been changed here.

This ZIP is a reading and code-review packet, not a standalone Godot project. Running its scripts requires the prepared Endless Museum project and installed XR Tools. Fresh headset traversal and Quest performance were not tested. Existing entrance issues in Random Space and Random Game remain recorded in earlier hall reviews. If you have only this packet, distinguish conclusions from reading from conclusions that would require execution or embodied use.
