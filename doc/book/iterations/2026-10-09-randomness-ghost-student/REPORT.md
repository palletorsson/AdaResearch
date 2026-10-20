# Randomness: the ghost student changes the rule

The fourteen lessons hold together under reconstruction and changed inputs. All **420 baseline checks and 60 transfer checks pass** in Godot 4.6. Six deliberately broken variants are rejected. I would keep the current teaching order and text.

This was an **author-informed ghost-student run**. I already know the project and helped write the lessons. It tests whether the supplied programs initialize and whether specific predictions survive independent edits. It cannot establish how easily an unfamiliar student will find those edits, how the full chapter feels in one sitting, or how comfortable the interactions are in a headset.

## What I changed

The two recorded entrance problems were real. Random Space's spawn was at the boundary; Random Game's legacy start conflicted with the entrance. I gave both explicit museum arrival positions near their first exhibits. The local entrance checks load the actual halls, verify supported arrival without fallback, supply the existing scanner's access action, and check a supported route into the room. Their receipts and native captures are below. No artifact was removed.

The canonical `tutorial.md` and `final.md` files remain unchanged in this pass. The previous revision already made Entropy count-first, distinguished the middle lessons, clarified the late transitions and supplied complete inherited code. The new tests found no reason to rewrite that material. The museum algorithms and fourteen-hall order remain intact; Biome Cage stays an encounter and the closing Ladder remains deferred.

## What the student carried forward

The cube, point, arrays, transforms and individual materials come from earlier sequences. The prepared museum supplies the player, environment and XR Tools. Each lesson supplies its complete small reconstruction, including the inherited source files it needs. The ghost student does not rebuild the museum or substitute the production artifact for missing lesson code.

I extracted **31 printed files**, made a separate edited copy for each hall, and recorded the predictions before running them. These are fresh reconstructions of the printed examples and exercises in transferring their operations. They are not fourteen independently invented programs and do not carry a single live node through every hall.

The useful progression is:

**sample a value → retain and inspect a record → accumulate changes → let retained information influence a later choice → change what the player can know about a scheduled event.**

The middle has distinct jobs: Cubes changes continuation; Rotate compares assignment with accumulation; Walk separates current position from a trail; Gaussian changes the grouping of retained values; Mushrooms changes their expression on bodies. The later field and timing studies reuse those distinctions.

## What the reflective track adds

The programs can check that a candidate was ineligible, a record survived sorting, or a warning changed without moving a deadline. The reflections ask what those operations mean for the body encountering them. Equal selection within a set does not decide its membership. A frequency does not establish a desirable body. A stored deadline is not the same as adequate notice.

Those are different kinds of claims. Passing an assertion does not validate an artistic or political interpretation. My reading is that the two tracks now meet at specific operations without having to repeat one another. The full reflections belong to the book; they need not become compulsory wall reading before the visitor can act.

## What failed in the test process

The first new checker had a GDScript type-inference error. I fixed the checker and retained the failed run. This was not an error in a printed lesson.

More usefully, my first Pheromone test filled the field with the same large value everywhere. A faulty program that still consulted scent could pass: adding the same amount everywhere need not change the strongest neighbour. I replaced that condition with a strongly uneven field. The legitimate zero-guidance program still passed; the faulty guided program then failed. The original insufficient test and its receipt remain in `attempts/`.

The entrance tests also needed the actual museum conditions. Map coordinates include a four-metre vestibule offset; a clear geometric point alone does not establish a useful arrival. The first route test also left the access gate closed because it had paused the museum update loop. The final test supplies the existing access action and lets the real gate complete its opening before checking the route. The diagnostic raycasts also needed the observer parked outside the probe area so that they measured the floor rather than the avatar. Production collision and the gate operation remain intact.

These corrections matter: a successful test only supports the distinction its inputs can expose.

## Decisions after the external review

- **Keep fourteen halls.** The edited programs demonstrated distinct operations. Reading fatigue still needs an unfamiliar reader; these tests do not settle it.
- **Keep Entropy early and count-first.** The student explanation is that sorting changes neighbours while retaining symbol counts and their entropy. Deriving the formula can remain a second reading.
- **Keep PRINT's counts variable.** Its threshold yields an expected count, not an exact quota. The review's fixed-count description belongs to a different comparison in the room.
- **Keep the Noise boundary explicit.** Randomness has introduced neighbouring samples and layered fields. The following Noise sequence should deepen domains, spatial and temporal correlation, and field transformations. This run does not certify or rewrite that next sequence.
- **Keep the museum larger than the tutorial.** One selected operation carries each lesson; other artifacts can contribute to reflection or exploration.

## Evidence and limits

The 480 checks cover fourteen baseline and fourteen changed-program runs. The 60 transfer checks include fourteen initialization checks. The six mutation runs deliberately fail assertions; they are evidence that the checks reject these six faults, not a claim to detect every possible error.

The two entrance runs are additional native museum integration checks. They test local arrivals and supported routes with supplied access actions. They are not a continuous end-to-end walk through all fourteen halls or a physical VR session. Random Space still logs a separate unsupported exit doorway. That remains an integration issue; repairing the arrival does not establish a complete through-route. Old missing-UID, Jolt solver-bias and environment warnings remain visible in the retained logs; no script or parse error remains in the successful learner runs.

The packet includes the full reviewed tutorial and reflection, exact learner files, changed versions, predictions, receipts, failed attempts, entrance changes and reproduction tools. The earlier review edition stays available as a historical snapshot.

[Student notebook](student-notes.md) · [Predictions](predictions.json) · [All lesson results](tests.json) · [Rejected faults](mutations.json) · [External review](EXTERNAL-REVIEW.md) · [Download the packet](randomness-ghost-review.zip)


## Follow-up: passage repaired

The exit issue recorded above is resolved in the [native passage repair](../2026-10-09-random-space-exit/index.html): 49 desktop and 50 XR-body checks pass. The earlier report and its ZIP preserve their original test scope.
