# Relaxation — make the budget touchable

This is a **targeted encounter repair**. Preserve the hall’s live cloth → frozen lattice → frozen vessel progression and its fossil-of-forces argument. The existing ecology already supplies the argument; no artifact was removed or newly invented, and no artifact placement was changed.

## Decisions and evidence

| Review claim / passage | Local evidence | Decision |
|---|---|---|
| The pass dial promises a control but is decorative | Baseline script creates a cylinder and sine-driven notch; no input. Actual museum screenshot confirms the visual. | Replace it **only in this hall** with the existing XR push-button idiom: PASSES, RESET, WIND. Keep legacy placements unchanged. |
| The cloth relaxes while watched | Baseline source takes one fixed solver step per rendered frame and adds a sinusoidal lateral acceleration plus cosmetic sway. | The comparison uses fixed solver updates driven from physics time. Initially WIND ON retains the driven cloth; WIND OFF removes lateral drive while gravity continues. The comparison frame does not cosmetically sway. |
| Increasing 1→4 passes worsens the worst spring | Direct Godot measurements at 60, 420, 2400 steps under matched undriven conditions consistently improve the worst spring too. The signed mean reproduces the earlier source comments. | Correct this precise claim. Keep the critical argument by comparing an apparently small average with a much larger local discrepancy. |
| Bench shares authored spawn cell and must be overhead | Actual museum roots: bench(2.5,0,2.5), player(7.5,0.000683,1.5),5.099m horizontal separation; player capsule query clear. | Reject placement repair for the current museum. Update the obsolete overhead prose. Do not move a correctly placed bench to repair a JSON-only inference. |
| The vessel carries the fossil argument but is secondary | All four authored objects load. Roles list cloth/lattice primary, vessel/screen secondary. | Recommend vessel promotion, cloth→lattice→vessel; root owns roles. Keep screen supporting. |
| No velocity / no design / stopping when close enough | Temporary `vel` is derived from current/previous positions. Lattice uses authored connectivity and80 solver steps; vessel uses authored sphere/pins/initial expansion and200 steps. Neither implements a convergence stopping test. | Narrow factual corrections; preserve the distinction between authored conditions and a final shape not hand-positioned vertex by vertex. |

## Implemented scope

`commons/artifacts/verlet_workbench/verlet_workbench.gd` adds opt-in `comparison`. The existing numeric `constraint_passes` contract still wins, and legacy ambient/default/capture fixtures remain available. The new control panel replaces the decorative dial in comparison mode. The final control bay sits beside the cloth, leaving its lowest edge visible. The cloth, solver, stiffness, pins, particle/spring topology and frozen specimens are unchanged.

`commons/maps/FormFinding_Relaxation/map_data.json` changes exactly one token to `verlet_workbench:90#comparison:true`. Geometry, artifact count, cells, utility layers and ordering remain unchanged.

PASSES cycles1/4/8/12. RESET repeats the selected condition. WIND toggles drive. Every control starts from the same deterministic grid, executes the same60 setup steps, resets the model clock, and retains the chosen pass count/wind state. The panel exposes integration count, drop below the pins, mean absolute relative spring error, and the maximum absolute relative error. This is a continuously running comparison, not a promise of a convergence detector or a held420-step snapshot. The finite measurements below come from a separate direct-source probe.

The controls sit at 0.97m local height; captions and a compact fixed panel sit beside/below the cloth rather than across it. The comparison is bounded to 80 particles and 392 springs at defaults, matching the original cloth.

## Reproduced measurement

All measurements use the actual Godot `soft_body_sim.gd` and `soft_body_shapes.gd`,10×8 points,392 springs, two pinned corners, stiffness .75, damping .99, gravity(0,-3,0), fixed step .0166667, no gust. `measures/measurement.json` records60,420,2400-step results.

| Passes | Drop after420steps | Mean signed error | Mean absolute error | Worst absolute error |
|---|---:|---:|---:|---:|
|1|.640610m|.700740%|1.408941%|34.276115%|
|4|.607081m|.167673%|.359177%|8.935516%|
|8|.600920m|.080166%|.175530%|4.335572%|
|12|.598828m|.051260%|.113611%|2.786429%|

Relative error is `(current_length-rest_length)/rest_length`; absolute statistics use its magnitude. These statistics are not elastic energy, entropy, fabric stress or a physical unit. Signed averages allow positive and negative errors to cancel. The 8-to-12-pass drop difference is only about 2.1mm; the panel makes the distinction available, but perceptual salience in a headset remains untested. “Equilibrium” and an exact inverse-pass law would overstate these finite numerical runs.

The source comments already preserve relevant earlier measurements, including420-step settling and the dominance of gust over pass-count displacement. Searches of `doc/research`, `doc/reports`, `tools`, and `commons/testing` did not recover an independent original worst-spring record. This absence was not itself treated as disproof: the matched source experiment supplies the correction.

## Proposed narrow writing revisions (root-owned)

- Say **no separately stored velocity state**. Retain the two-position account and code.
- Say the cloth starts with60 steps and continues at fixed simulation steps, with a gust initially on. Distinguish this continuously driven result from the two frozen results.
- Replace the fake-dial paragraph with PASSES/RESET/WIND instructions grounded in their actual behavior. WIND OFF lets the visitor compare budgets without a moving external drive.
- Retain the force of “relaxation improves the total...” as a question about summaries and local costs, but remove the unsupported specific worsening. At 4 passes / 420 steps the mean absolute error is.359% while the worst is8.936%.
- Qualify “half the error”: each unpinned endpoint moves by half the discrepancy multiplied by stiffness. Two free endpoints and a pinned/free pair differ.
- Remove overhead/spawn language for the mass-spring bench; its frozen mesh is displayed on a bench and rocks as a whole. Its vertices do not continue settling.
- Distinguish selected finite 80/200-step budgets from stopping automatically “close enough.”
- Keep the vessel/fossil argument. Authored initial expansion is not ongoing simulated pressure, and authored pins/rest lengths/parameters are real design decisions. The final vertex positions are generated.
- Keep future parameter changes explicitly source/configuration changes; the vessel still has no live controls or containment collider. Do not infer bottle-vs-bowl from clock alone without a separate parameter sweep.

## Verification and limits

`control-final-v3/controls-checks.json`:26/26 isolated source/runtime checks, including actual XR pointer-event dispatch, all pass values, repeatable reset, wind effect, mean/worst statistics,30vs60Hz stepping, render-update independence, grid attachment preservation, repeated-config no-op, and legacy numeric-config behavior. Frozen-source equivalence also verifies legacy positions/sway and the gust phase across reconfiguration. A pre-tree configuration test reproduces the discovered duplicate-build bug before the repair, and now verifies one build after tree entry. No headset was used.

`before/museum-checks.json`: all four authored objects were verified individually. One initial diagnostic assertion incorrectly demanded exactly four metadata-bearing nodes, ignoring standard museum dressing; its failure is preserved. Corrected probes check the four authored IDs and separately record the full metadata list.

`after-headless/museum-checks.json`:11/11 actual museum checks pass, including map-token opt-in and three unobstructed standing approaches. Support-post cosmetic geometry was added after that run; the accepted final capture rechecks final source stability and all standing approaches.

Prior measurement, manuscript, source, roles and core snapshots are in `before-source/` with `before-sha256.json`. Registry/roles/core/manuscript edits are outside this agent’s ownership; root may integrate those separately.

Limitations: no embodied comfort, hand reach, controller targeting quality, Quest frame rate, learner understanding or collision against deformed cloth has been tested. The cloth remains a visual surface, and the specimen benches keep their existing collision behavior. Hidden Godot runs use XR off and Dummy audio. Existing startup UID/certificate messages and teardown resource warnings must be kept separate from script errors and failed assertions.


## Runtime lifecycle defect found by image review

The first after images in `paired-after/` are **diagnostic, not accepted**. The museum applies the map configuration before tree entry. `apply_grid_config()` therefore built the new comparison panel, and the old unconditional `_ready()` built another one over it. One cloth and one readout remained frozen under the moving ones: numerical state checks alone missed the overprint.

`duplicate-reproduction/controls-checks.json` records the failing pre-tree lifecycle assertion. The production `_ready()` now checks the owned build/signature before building. `control-final-v3/controls-checks.json` passes all 26 checks, including legacy equivalence and this lifecycle. A final actual-museum probe also checks that exactly one live readout and one cloth ArrayMesh exist.

The fixed readout is larger, and its title has moved onto the console fascia so the neighboring bench's floating title does not overprint this control's invitation. Earlier diagnostic images are retained to make the correction traceable.


Registry integration belongs to root: `commons/artifacts/registry/soft_bodies.json` still calls the bench a dial and the vessel walkable. Update the present-tense descriptions; preserve the dated DNA promotion record as historical provenance rather than silently rewriting its original experiment.


## Accepted final visual evidence

- Before: `paired-before/workbench.png` (frozen script replay in the actual museum,13/13 checks).
- After: `final-visible-after/workbench.png` (final authored source and map,25/25 checks).
- Same-camera studies: `final-visible-after/passes-1.png` and `passes-4.png`, both WIND OFF and420total steps. Their displayed values exactly reproduce the independent source measurements.
- Hall context: `paired-before/hall.png` and `final-visible-after/hall.png`.

All accepted runs return0, with source hashes unchanged within each run. Camera transforms are byte-identical across the primary pair. The museum's camera guard timers were stopped, and current-camera identity was asserted both before and after frame draw. The first baseline briefly overlapped another agent's render after a crossed handoff; no timing or performance claim is made. Background procedural dressing and phases differ between independent runs.

Visual review also caught the first console covering the cloth's lowest edge. The final three buttons are grouped below the side readout, at0.97m, with five checked standing approach positions. This makes the observed drop visible and the button caps fully exposed. `final-after/` remains a diagnostic stage; use only `final-visible-after/` for the delivered current image.

Six integrity checks verify the accepted production hashes, one-token map change, matched camera, passing museum result and exact frozen replay adaptation. `MANIFEST.json` identifies accepted files and hashes. All evidence preserves the older diagnostic failures rather than silently replacing them.

No manuscript, registry, role, sequence, shared engine or other hall was edited by this agent. Root owns those integrations. This targeted pass is complete; follow-up in a headset concerns legibility, reach, perceptual differences and comfort rather than source correctness alone.
