# Ghost student — fresh run after revision

9 October 2026 · Nine lessons rerun in Godot · Existing Endless Museum project

**263 of 263 lesson checks passed again, plus 21 of 21 checks in the repeated museum composition.** All nine lesson processes were started afresh. No cached results were used. The printed code and museum behaviour needed no repair.

This is an author-operated rehearsal with prior context. It checks reconstruction, declared interactions and specific variations. It is not a blind independent reader, a continuous walk through all portals, or a physical-headset assessment.

## Following the revised instructions

The student starts inside the prepared museum with its player, camera, lighting, XRTools and Jolt. Every lesson now identifies its carried files, new work and supplied components. We extracted all 28 printed scripts, checked the dependencies and ran each lesson's complete known assertion set. A zero exit code alone was not accepted: logs were checked for script/parse errors and each expected assertion had to be present and pass.

|Hall|New operation named in the tutorial|Fresh checks|
|---|---|---:|
|1. Deformation|Pin a reference vertex; compare stiffness, damping and pressure in `yielding_cube.gd` and its host.|28 passed|
|2. Cloth|Build `hanging_sheet.gd`; select a row, two corners or no pins. The host makes those choices visible.|27 passed|
|3. Carusell|In `study.gd`, move the two attachments with a turning bar; let the sheet respond.|29 passed|
|4. Pressure|Build `pressure_panel.gd`; drive its pressure from a sine wave in `study.gd`.|32 passed|
|5. Contact|In `study.gd`, compare matched falls and retain a timed height reading.|30 passed|
|6. Sampling|In `study.gd`, copy positions and face indices while their source continues.|27 passed|
|7. Affect|In `study.gd`, compare one turn or colour change while keeping geometry fixed.|25 passed|
|8. Reaction–diffusion|Expose local reaction, supply and removal in `field.gd`; compare both cases with `reaction.gd`.|33 passed|
|9. Morphogenesis|In `recipe.gd`, separate frequency, noise and cut; preview, then commit.|32 passed|

The exercises also executed their stated independent edits. These included changing cloth subdivisions without supplying new pin indices, changing pressure amplitude while retaining the response settings, capturing a later surface, altering a reaction rate, and separating a threshold edit from the field's other parameters. Deliberately faulty variants were exercised where the existing lesson probes provide them.

Five source-continuity checks passed: the same PointBody across nine halls; sheet from Cloth to Carusell; panel from Pressure to Contact; vessel and solver from Sampling to Affect. Each host creates its own instances. Matching source files does not demonstrate cross-hall inventory persistence.

## Does the reading follow the construction?

The first five lessons keep the simulated body's conditions visible: a chosen attachment, a moved support, a pressure drive, a matched fall. Sampling explicitly changes from Jolt to the supplied vessel solver so the learner can read its positions. Affect reconstructs the known step-40 specimen; it does not load an arbitrary previous capture. Reaction returns to the earlier CA field. Morphogenesis starts a different spatial field with no simulation clock.

Those changes of model are now declared in the prose. The final texts carry the question of persistence across them: physical relations, a record, continuing exchange, and a reconstructible rule. This is an editorial judgment checked against the implementation. The engine assertions cannot establish whether that argument convinces a future reader.

## Repeat a composition, leave its fold open

The optional Cloth exercise was run again in the real museum. A holds two upper corners; B holds three distinct reference positions. Both use the same sheet, connectivity and material settings. After 120 awaited physics callbacks, B's released corner had moved **0.805 metres**; its held points drifted at most **0.00000478 metres**. The earlier run recorded 0.813 metres of corner movement. The assertion concerns a free corner moving and selected points staying, not an exact repeated fold or distance.

The inherited point's synthetic XRTools grip, trigger, rebuild and release passed again, as did actual keyboard dispatch, transformed reference selection and the explicit completion check. All **21 checks passed**. The temporary study adds no permanent museum artifact.

## What changed this time

No student code or chapter repair was needed. The test runner now preserves this fresh run separately and checks that a passing receipt contains every known lesson assertion. The earlier receipts and the rejected checker attempt remain available. The blog is updated from this run's evidence.

The remaining questions need another kind of test: an unfamiliar reader rebuilding a lesson without prior context, a complete controller-only session, and comfort and performance in the headset. None is implied by these passes.

## Evidence

- [Nine fresh lesson receipts and text hashes](ghost-checks.json)
- [Plan and composition predictions](RERUN-PLAN.md)
- [Fresh composition checks](composition/evidence/report.json)
- [Complete composition host](composition/student/study.gd)
- [Earlier composition, including the rejected first checker](../extensions/three-attachments/index.html)
