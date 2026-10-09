# Transformation — assessment of source-aware feedback

Received 2026-09-18. Original: [01-with-sources.md](01-with-sources.md). The report is useful editorial/source evidence, with an important evidence-package limitation. Suggestions remain proposals; saving this review does not apply them.

## What the review contributes

The sequence reading is useful: Pre names operations; Introduction makes passage; Translation and Rotation distinguish constraints and axes; Scale changes the body/surroundings relation; Body uses the visitor as input; Pit reverses and recomposes the operations. Repeated operations can acquire a different consequence as the relation changes.

The maintenance findings below were checked against the frozen source. The carousel, scale entry point, drink-me room, grower, array trial and array generator also matched the current working copy during this pass. No project code was executed.

| Finding | Assessment | Next action / state |
|---|---|---|
| Missing tc/sc/rc sources | Confirmed package gap: the ZIP does not include the central UtilityRegistry/GridUtilities/transport/scale/rotation implementation. A rotation_rider_deck helper is included, so not every rider helper is absent. | Improve source packaging with utility dispatch, relevant implementations and their dependencies. Do not infer a runtime failure from missing evidence. |
| Carousel comments say profile is appearance-only | Confirmed: gallery:clean changes collider radius to _vis_radii, while general comments still describe unchanged collision. | Clarify default versus clean-gallery branches. Maintenance proposed, not applied. |
| Scale identity describes legacy 100x/timer | Confirmed: drink_me branches to the fourfold room, skipping the legacy _ready path; the new room applies FACTOR=4 and relocation. | Document both modes, preserving valid default behavior. Maintenance proposed, not applied. |
| Grower identity describes pit/death | Confirmed older lineage description; Trans_Pit stages a level-floor study with floor anchoring. | Describe the map-specific use without implying anchor=floor alone guarantees safe bypasses. Maintenance proposed, not applied. |
| Rotation body-width outcome is not proved by source alone | Correct evidence boundary, but prior runtime reports exist locally and were omitted from the package. See evidence below. | Supply prior evidence before weakening a measured observation into a hypothetical. Check scope/freshness; learner/headset verification remains separate. |
| Rotation footnote uses localhost | Confirmed in the frozen final.md. | Replace with a durable published or repository target before distributing outside the local research build. |
| Biome_Ladder_Transformation appears only in museum order | Confirmed in package state. | Investigate intended transition/coda role; do not silently add/remove a book chapter. |

## Existing runtime evidence omitted from the review package

`doc/space/transformation-experiments-2026-09-16/rotation-body-comparison-checks.json` records 40 checks, no failures. For the gradient Z band:

- NARROW, width 0.44 m: BLOCKED, forward travel about 4.662 m, lateral displacement about 0.044 m.
- WIDE, width 1.20 m: ARRIVED, forward travel about 14.017 m, lateral displacement about 1.155 m.

Its explicit limits are source-grid collision rather than player headset traversal, constant forward input with collision sliding, and outcomes dependent on body/movement settings rather than universal route impossibility.

`doc/space/transformation-experiments-2026-09-16/experiment-notes.md` also records a rendered actual-museum run reproducing the qualitative result. This is existing evidence, not a fresh run performed during this feedback assessment.

`doc/space/transformation-alignment-2026-09-17/rotation/verification.json` records inspected runtime-source hashes. `checked-source-hashes.json` compares the two relevant scripts with that record and the frozen package. A matching source hash alone does not establish that every environmental/test condition is unchanged.

Copies of the earlier reports are in evidence/. They are supplementary evidence found locally, not materials the online reviewer originally received.

## Editorial judgment

Preserve the distinction between an operation and what it permits in a particular arrangement. Keep the airlock as the constructive response after the critical passage. Do not turn every concrete observation into a generic conditional merely because a source-only reader lacks its runtime report.

This is strong sequence/source feedback. It does not establish novice comprehension, felt access or that every paragraph has the desired poetic rhythm. Those remain separate reading and learner questions. No editorial cut or implementation change is authorized merely by a recommendation appearing in this external review.

## Local implementation and runtime follow-up — 19 September

The preceding sections record the original source-only assessment. The author's subsequent instruction to continue authorized this local follow-up. See the [complete seven-hall decisions](../../../iterations/2026-09-19-transformation-review/SUMMARY.md) and the three linked audits for evidence boundaries.

- **Preserve all seven final chapters and their map configurations.** The current encounters support the progression; no uniform rewrite or primary-artifact quota is warranted.
- **Utility packaging repaired.** Active grid utilities now have a separate index, scene implementations and placement context in fresh exports. The old ZIP's omission did not demonstrate missing mechanisms.
- **Misleading source comments corrected.** Carousel clean-gallery collision, ScaleMe's legacy/default versus drink-me mode, and the grower's map-specific use are distinguished. Evidence proves executable lines are unchanged.
- **Pickup metadata corrected.** The registry now describes contact collection, configurable motion and retained demonstration mode. It no longer promises unsupported grab/carry/drop behavior. All other 172 entries and the scene reference are unchanged.
- **Archive import fault repaired.** Frozen source copies had occupied 239 Godot global-class cache entries. Ignore files now exclude review packages from import; verified matching live paths replaced those cached archival paths. Initial failing logs are preserved. Rotation and Pit probes then loaded and passed.
- **Fresh bounded evidence:** Rotation body comparison 40/40; compact Rotation 33/33; actual-museum Scale 40/40; Pit 14/14; focused airlock 25/25. These do not substitute for a headset walk or learner reading.
- **Translation remains a qualified result:** 85 checks with 17 failed assertions. Thirteen use the wrong position measure for animated pickups; four combine a short ramp walk with a flat-floor endpoint expectation. The individually measured first landing stays supported. Update the probe and check the other joins before claiming a complete route pass; do not cut the supported transport account or delete ramps on this evidence.
- **Coda resolved:** `Biome_Ladder_Transformation` is an intentional museum transition, documented in `doc/COMBINATORY_BIOME.md`. Retain the seven declared book halls.
- **Remaining bounded work:** Translation's continuous outbound/return route, obsolete Pit supplements, Scale's ambient crab interruption, and the localhost zoetrope footnote for external distribution. These have different stakes and do not require equal editorial pressure.

A [new reading brief](../../../review-packages/2026-09-19/transformation/review.md) and [new source ZIP](../../../review-packages/2026-09-19/transformation-review.zip) capture this improved evidence. The original reviewer responses, package and input hashes remain unchanged.
