# Colour — a complete sequence for review

**Status: eight tutorial drafts, paired with the eight existing final.md reflections.** The final texts are preserved, not newly rewritten. The first three tutorials retain their tested programs; Rainbow through Walls are the newer batch. The full-sequence feedback led to small prose revisions in Colour and Rainbow and a clearer manual-first route through Paint. See FEEDBACK.md. No canonical tutorials, museum runtime, sequence order or acceptance flags were changed by this batch.

## Where we are

We are inside the existing **Endless Museum**. Its rooms, artifacts, player, camera, light and prepared XR Tools already exist. The learner encounters an installed artifact, then reconstructs one selected operation in a small script in their working museum copy. These are not eight replacement environments. The review studies have not been inserted into the live halls. The host and supplied helpers are declared in each lesson.

The tutorial track and the reflective track overlap. An artifact may belong to either, both, or neither. A tutorial need not reconstruct every object or interpretive thread in final.md.

## The learner arriving here

Assume the earlier route: game loop; PointBody and its pickup; local/world coordinates; lines; arrays and loops through Trace and Grid; triangles, meshes and primitives; configuration; whole-object translation, rotation and scale; addressed arrays. The early Array lessons are not all complete review drafts yet. This chapter uses those agreed prior concepts; it does not certify that the entire preceding book has been completed.

The continuous object is a lineage, not an automatic persistence mechanism. PointBody's exact class returns in Nails, Pillar and Paint. Recorded colour values move from Nails to Rainbow, then Pillar to Grid. Palette is introduced in Grid and reused unchanged in Walls. Every study declares whether it copies a value, creates an instance or receives an existing reference.

## Read as the ghost student

Imagine a future in which jobs have disappeared. Read as someone might still play chess after a machine can play better: for the pleasure of making a move, and with some melancholy about what has changed. This is an imagined position, not a prediction the book must prove. The code and its objects are real. Notice where the lesson gives you another capacity and where it merely asks you to trust the teacher. Keep a missing step visible rather than silently supplying it. The teacher is also learning what remains worth handing on.

## Questions for the reviewer

1. Can the learner identify what changes in each hall and which earlier capacity makes that change possible?
2. Does colour remain the subject, with programming serving it? Identify any lesson where infrastructure takes over.
3. Can the printed code and named supplied files reconstruct the selected operation? Flag every undeclared dependency or ambiguous coordinate frame.
4. Does the tutorial stay accountable to the actual museum artifact without pretending to rebuild every effect? Distinguish a declared reduction from a mistaken account.
5. Are there enough independent choices to demonstrate understanding beyond copying? Are their expected observations concrete?
6. Read each final.md beside its tutorial. Do they deepen one another without forcing every reflection into an exercise?

Please return comments by hall: **keep / change / missing**, a precise passage or code location, and the smallest useful revision. If you did not run code, label your assessment as a reading review.

## Decisions particularly worth testing with a reader

- **Rainbow:** its making lesson is optional; encountering celebration does not require completing a coding task.
- **Pillar:** the hand-height adapter is necessary to make a tall field reachable. Does separating it from the HSV function make the two frames legible?
- **Grid:** Palette is a small stateful class, not a new architecture. Does it help the reader distinguish address, instance index and palette index?
- **Paint:** this is the densest lesson. Its point, action, ray and surface are connected completely, and the supplied receiver is printed. Does the separation into one continuation and support files keep the focus readable? Its circular stamps omit the installed can's aerosol, wetness, stretching, runs and fading. The automatic caller is explicitly optional, after a completion check for manual painting; both callers still write one image.
- **Walls:** does the same persistent collider make the difference between a visible opening and a physical passage clear? RGB/HSV models and the interpolation bench remain reflective encounters outside this selected two-pane exercise.

## Evidence and limits

The new batch executes the exact fenced sources under Godot 4.6, including the supplied scripts. It checks all five baselines and 15 additional printed/choice variants. Assertions cover geometry and materials, moved reference frames, retained instance colours, palette ownership, ray hits and occlusion, persistent marks, and collisions through translucent/opaque modes. XR Tools pickup/action/drop is exercised with a synthetic controller.

Ten deliberate behavioural faults must fail specific assertions. Parser failures are not accepted as successful fault detection. Native checks use the real OpenGL renderer because the headless dummy renderer does not retain the MultiMesh colour state being tested. Fixed-camera rendering checks provide separate visual evidence.

Proof files are included and their source hashes are checked at collection time. The revised Colour prose and five-hall manuscripts have fresh checks; the unaffected Flashlight and Nails results are retained from their earlier runs. Tests establish selected implementation behaviour; they do not establish headset comfort, full museum integration, physical controller mapping, educational success, historical interpretation or the reader's emotional response.

The report distinguishes dated **museum captures** from new **isolated study renders**. It does not present the latter as screenshots of installed halls.

## Files

- `ALL_TUTORIALS.md`: all eight complete tutorial texts, in spine order.
- `ALL_FINAL.md`: all eight existing reflective texts, with local image links relocated for this package.
- Each hall folder: exact individual `tutorial.md`, `final.md`, runnable scripts and side-by-side HTML.
- `verification.json`, native/render reports and test runners: new-batch proof.
- `evidence/`: preserved proof and test sources from the first three lessons.
- `manifest.json`: source locations, hashes, collection status and image provenance.

To rerun the new checks from the AdaResearch checkout: `python -X utf8 doc/book/iterations/2026-10-06-colour-complete-drafts/run_checks.py`, then the neighbouring `run_render.py`. The runner uses the repository's XR Tools addon and a Godot 4.6 executable (`GODOT_EXE` may override the recorded local path). A fresh temporary project is created. The ZIP is a review collection, not a replacement for Day Zero or a complete museum distribution.

Across the collected evidence: **747 native assertions, 39 render checks, 25 deliberate faults rejected**. The new five-hall batch contributes 311, 14 and 10, respectively.
