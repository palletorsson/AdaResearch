# Primitives — review decisions and source checks

Initial intake recorded 2026-09-18; implementation and verification added in the dated passes below. The original reviews remain in 01-text-only.md and 02-with-sources.md. These notes distinguish the author's instructions, recommendations, applied changes and their evidence. They are not an approval of every proposed change.

## Author instruction

Preserve the rabbit, folding past, unanswered questions and deliberate poetic returns. The author explicitly agreed to protect these. Tightening repeated explanation can be considered passage by passage; there is no general mandate to shorten the sequence.

## Checked findings and proposed actions

| Finding | Evidence checked | Decision / next action | State |
|---|---|---|---|
| One WORLD readout; no separate LOCAL numeric card in Point One | Fresh actual-museum assembly and image now show paired WORLD/LOCAL cards on point_one_main, 1.728 × 1.44 m each, 0.272 m gap | Added LOCAL, staged the pair, fixed duplicated readout builds, and adapted only adjoining text. Existing critical argument preserved. | Implemented and automated/render checked 2026-09-19; headset check pending |
| Snap target can be stale at release | Reproduced with production snap points, SnapConnectionManager and XRTools pickup/release methods; 11 of 26 behavioral checks failed before the fix | Refresh nearby targets at release. All 26 checks now pass, including entering/leaving range, switching targets and manager scoping. | Repaired and headless-tested 2026-09-19; physical controls/full-hall checks pending |
| L comparison requires exact geometry while changing the first index | Current production scene now supports SHIFT START; actual emitted mesh and pointer tests keep six corners fixed while the B fan overspills the notch | Added optional SHIFT START to the last completed loop, preserving manual drawing and earlier loops. Updated only the affected instructions, counts and implementation references. | Implemented 2026-09-19; 60 Godot checks and isolated renders pass; full-hall/headset observation pending |
| STOP/arrow returns at architectural scale | 12 concrete_barrier and 5 street_sign placements; current prose already explains the architectural return and recalls WALK THIS LINE | Retain the encounter and existing transition; no additional paragraph needed for this review item. | Preservation decision, 2026-09-19 |
| v6 participates in five triangles over three faces | animatedcubebuilder.gd triangle list: top [2,3,6], [3,7,6]; front [5,6,7]; right [5,1,6], [1,2,6] | Consider a short invitation to inspect neighbouring faces after the local crease. | Source checked; prose proposal |
| Trihedron identity metadata is stale | Three open rendered faces, convex collision hull, unassigned alternate material in shipped scene | Corrected eight identity comment lines; executable code and accurate manuscript preserved. | Metadata repaired 2026-09-19 |
| Legacy triangle slogans are still present | Point_Triangle_Context placement says everything triangle; primitives sequence objective says GPU atomic unit | Review the slogans alongside the precise manuscript. No automatic global replacement. | Source checked; wording decision pending |
| Pyramid detector attends to connectivity rather than squareness | snap_connection_manager.gd::_detect_square_pyramids checks four-cycle and connected apex without measuring sides/angles | Preserve the manuscript's detector critique. | Source checked; preservation recommended |
| Museum order adds Biome_Ladder_Primitives after the declared ten halls | doc/COMBINATORY_BIOME.md explicitly documents the last primitives pearl; current plan has ten cumulative seed-7 stages | Keep the intentional museum recap. Later distinguish coda from chapter in metadata/navigation instead of deleting it or inventing an equal-weight chapter. | Intent resolved; presentation task remains |

The checked live map/scripts for Point One, snap_point, trihedron, draw_triangle_faces and animatedcubebuilder matched the package snapshots at review time. This does not certify all findings in the external review. No headset behavior was tested in this pass. No manuscript, artifact, map or curriculum changes were applied as part of collecting this feedback.

## Before implementing

Record the chosen change, its source version and what would count as success. Keep editorial decisions, code checks and learner/headset observations distinguishable. When a recommendation is completed or declined, update this file with the result rather than rewriting the original review.

## First implementation pass — 2026-09-19

**Scope: targeted improvement.** The opening sequence already has developed writing and encounters. This pass repairs a confirmed interaction fault in the shared snap-point component; it does not reopen the manuscript or change primary roles. The line demo and other users of this component inherit the repair without separate map changes.

The release previously reused the last detected target. In drop-only mode, holding the point prevented detection from updating. A release could miss a newly approached point or connect to one the visitor had moved away from. The new release-time detection uses the existing distance and manager filters. It creates the connection at the current endpoints; it does not teleport the held point or alter the shape-detection rules discussed in the book.

Before editing, `snap_point.gd` had SHA-256 `706711cff87fc9ebcfbf106feb59af538d86098af27a362631ab35bccc4d9ad6`. After the repair: `d7bdbaadc24eb31e2795875545ec26d0514e9595e76d83560ccb73be909da6c4`.

- **Reproduction:** production scene and pickup/release methods, synthetic hand, 26 assertions; 11 failed before the code change. [Original result](../../../../../ada_run/test-results/museum/20260919T101850Z-a821d9d0/snap-point-release-runtime.json).
- **Verification:** `python -X utf8 tests/museum/run.py --timeout 45`. All three cases pass: Point One 12 Godot checks, Point Lines 18, snap release 26, plus 7 Python checks (the 2 Point Lines authored checks run again for snap release). [Complete report](../../../../../ada_run/test-results/museum/20260919T102124Z-fbff0099/report.md).
- **Test maintenance:** the Point Lines test still addressed the former basin row and the former primary group. Current placement puts the stripe at `(9,7)` over basin cells `(6..13,7)`, and pairs it with the trace in `body-and-record`. Tests now resolve the marking placement and declared group while retaining the eight-cell support and adjacent encounter-order requirements. Border-void exclusion uses a deliberate border-connected fixture. No map/role data was changed to satisfy the tests.
- **Limits:** no physical desktop/VR controller input, haptics, full-hall barrier effect, visual composition or headset comfort was tested. The suite records these as not run. Known project startup UID/certificate notices remain visible in the report.

This bounded repair is complete at the automated implementation level. The next candidate is the Point One local/world comparison: inspect whether the existing graphical frame and world card make the distinction legible before choosing an additional local card. Its existing 12 runtime checks pass; an extra card remains a staging proposal, not a proven need to rewrite the text.

## Parallel review and second implementation pass — 2026-09-19

The proposed Point One comparison was subsequently implemented after three parallel audits. [Findings, decisions and image](../../../iterations/2026-09-19-primitives-review/SUMMARY.md).

The actual assembled hall confirmed both cards present with correct binding and no placement slides/refusals. It also revealed duplicate display nodes and stale dashes over live values. The display lifecycle was repaired and regression-tested. A farther viewpoint was obscured by the noncolliding target arrow despite clear physics rays; the nearer empty-floor approach gives a readable view. These are measured/runtime findings, not inferences from the review bundle.

The current automated suite passes **63 Godot assertions** across three cases; the fresh render confirms the paired cards. Headset experience remains untested. Later halls received preservation decisions and specific observation tasks rather than uniform editorial pressure. Triangle's manual experiment remains valid; optional SHIFT START is the next proposed apparatus improvement. No secondary artifacts were removed or automatically promoted, and no sequence membership changed.

## Triangle implementation pass — 2026-09-19

The proposed SHIFT START improvement is now implemented in `draw_triangle_faces`, which is already a primary in the triangle hall. The control cyclically advances the latest completed loop's first index and replaces only its fan. It keeps the same corners, boundary, material, mesh instance and triangle count. NEW OUTLINE and manual retracing remain available; the updated manuscript distinguishes replacement from accumulation.

Three agents handled the implementation, narrow prose alignment and actual-scene captures; the main agent independently verified behavior. The complete suite now passes **123 Godot assertions and 9 authored Python checks**. Triangle's 60 runtime checks cover geometry, guards, state, earlier loops, markers, reset/redraw and the shared boundary-puzzle panel. The rendered comparison is an isolated production scene, not a museum/headset trial. The first supplied drawing crossed its panel; clearer probe staging was chosen without changing the map. Headset drawing and spatial reach remain open observations.

[Findings, images, decisions and scope](../../../iterations/2026-09-19-triangle-shift-start/SUMMARY.md). The review hierarchy is working here: strengthen the encounter, then make a small text alignment. No broad manuscript cut, primary quota, new map or removal of secondary work was required.
