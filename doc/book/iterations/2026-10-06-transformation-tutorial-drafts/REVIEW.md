# Transformation review handoff

204 native checks passed; 12 deliberate faults rejected; 19 exercise variants executed. The feedback pass changed prose only; printed code still matches that native run.

Read [all seven tutorials](ALL_TUTORIALS.md) with the [revised reflections](ALL_FINAL.md), or use the [facing texts](paired.html). See [changes](CHANGES.md). Both tracks are review drafts. Canonical tutorial.md, final.md and museum code are preserved.

## What the author has asked us to preserve

- Existing Endless Museum, existing encounters. Select what to teach; do not reconstruct every artifact.
- Transformation is the subject. Programming gives access to movement, turning, size, space and response.
- One familiar whole BoxMesh; no face-list machinery in this sequence. Black, white and grey.
- Pre accumulates rise, turning and pulsing, then explains walk-over collection. Pickup here means overlap, not grabbing.
- One complete small program per hall, printed once. No hidden lesson nodes, no unexplained scene references.
- Name what was kept, removed and added. Final reflection has another job.
- Test exact printed code and exact exercise edits; do not infer understanding from a pass.

## Questions for the independent reader

1. Can you follow the spatial purpose of each lesson before reading its code?
2. Does each new operation have enough explanation to reconstruct and vary it? Where is there too much?
3. Does the sequence reuse earned understanding without pretending different runtime objects are literally the same instance?
4. Does Pre make the steady returning fraction understandable while keeping transformation central?
5. Are the boundaries clear between the crossing models, the physically solid final door and the installed exhibits?
6. Does the complete code stay readable without repeated setup explanations?

Reply per hall: KEEP / CHANGE / MISSING, with the exact passage and the smallest useful correction. Do not expand into a general programming syllabus. Do not treat every illustrated artifact as a required exercise.

## Verification scope

Native Godot executes code extracted from each printed tutorial plus tested source edits. Tests compare transforms and geometry, timing, reference frames and real physics overlap with synthetic bodies on the declared desktop/XR layers. Capsule movement tests check closed-door obstruction, open-door passage and the fixed frame; native shape queries check that shrinking the collision removes the expected barrier. The harness supplies the declared room context and simulated player; it does not construct missing lesson objects. No new in-headset trial, human learner study or verification of the full museum’s rider system is claimed.

[Machine-readable evidence](verification.json) · [Focus contracts](contracts.json)
