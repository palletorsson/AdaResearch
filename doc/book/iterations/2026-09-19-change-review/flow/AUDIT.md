# Flow_Field — targeted reveal and source maintenance

2026-09-19. Assessment against `doc/book/REVIEW_PRINCIPLES.md` and the unchanged received review `doc/book/review-feedback/2026-09-18/change/01-review.md`.

## Scope and decision

**Targeted improvement; preserve the mature hall.** The manuscript already distinguishes a prescribed direction from a gradient, force, fluid model, or accumulated velocity. The loop, independent field clock, RESET/SEED distinction, and wrap seam make specific observable claims. The 2026-09-11 consolidation preserved all six Flow_Field artifacts. Current map and role data still identify one primary and five secondary works. There is no verified missing encounter here that requires a new artifact, promotion, move, or prose cut.

The source header, status string, and two lesson-only staging details changed: the redundant floating title is hidden, and the existing control panel is raised and tilted clear of the tabletop. `map_data.json`, `final.md`, `tutorial.md`, and the scene are byte-for-byte preserved in this pass. Executable-line comparison confirms that all painter calculations and trail rendering remain unchanged. Exact snapshots, diffs and hashes are in `before/`, `diffs/`, and `source-manifest.json`.

## Findings, evidence and repair

| Passage and purpose | Evidence and missing layer | Decision |
|---|---|---|
| `final.md`: “Follow one through a bend … Predict the next turn.” Then reveal arrows and compare directions. | **TEXT + SOURCE.** `shared_field_lesson.refresh()` printed `ARROWS = PARTICLE SAMPLER` even while the arrows were hidden. Reveal timing, not missing mathematical explanation. | Status now reports `ARROWS HIDDEN` or `ARROWS SHOWN`. It retains FIELD HELD/EVOLVING and the particle count. The shared-function explanation remains in its existing manuscript position. |
| The status needs to remain readable while the visitor observes the canvas. | **CAPTURE + SOURCE.** Actual museum images showed the legacy floating `FLOW FIELD` title overprinting the lesson status. | Hide the legacy title only when the lesson is constructed. The existing control panel still supplies the title. A runtime check confirms unconfigured painter instances retain their original title. |
| `final.md`: RESET and SEED distinguish new starting positions from a new field. | **CAPTURE + GEOMETRY + RUNTIME TEST.** Both labels and lower portions of their buttons were below the added lesson tabletop. Pointer-event logic passed despite that spatial obstruction. | In lesson mode only, raise the existing panel from local y=-0.05 to -0.015 and tilt x from -30° to -65°. Final images show both controls completely; their label quads clear the tabletop by 0.09169 world metres and interaction volumes are above it. Unconfigured painter controls retain their original placement. |
| `final.md`: scalar noise becomes angle, then cosine/sine unit direction; the construction is not a gradient. | **SOURCE.** `field_direction()` implements that operation. `_process()` changes position by direction × speed × delta. No velocity, mass, force accumulation or fluid solver exists in this painter. Header language claimed laminar/turbulent regimes and a λ-edge. | Header now describes the implemented operation and names river/eddy/storm as visual associations. Paint/crowd imagery remains. Research association is distinct from a calculated quantity. Registry corrections are owned by the parent Change pass. |
| `final.md`: a wrap line can suggest a crossing the update never made. | **SOURCE + RUNTIME TEST.** Trail arrays retain neighboring samples from opposite sides; `_update_trail_mesh()` connects them. Probe establishes an outward boundary sample and observes an approximately 0.599 m jump on a 0.6 m canvas. | Preserve the seam and trail history. Do not smooth, clip, clear, or interpolate the wrap away. |
| `final.md`: the next hall asks what changes when the body carries velocity. | **SOURCE, limited supporting-work inspection.** The already placed `noc_5_04_flow_field` has stored velocity, acceleration and limited steering force. | Preserve as secondary. It is a recovery candidate for a future explicit comparison, not evidence that this pass added or verified that learner exercise. |

## Recovery ecology inspected

| Artifact | Current placement / role | Available work |
|---|---|---|
| `flow_field_painter` | (5,5), y=1.05, scale 2.5; primary | Eighty particles; 24 revealed arrows; six controls; held/evolving field time. |
| `vector_field_visualizer` | (13,5); secondary | Independent vortex/source/sink/dipole vector glyph field. It does not steer the painter. |
| `vector_field_grid` | (5,11); secondary | Stream-function/linear field choices, with arrow tint and lattice sampling. |
| `particle_flow_swarm` | (13,11); secondary | Related stream-function motion; its optional trace is reconstructed backwards from heads, distinct from painter's stored history. |
| `noc_5_04_flow_field` | (5,17); secondary | Steering toward sampled desired velocity, with acceleration and force limitation. |
| `grand_zoetrope` | (13,17); secondary | Composite return to discrete poses, derivative, sand level/rate, and periodic return. |

Scope: current role/placement records, registry scene paths, relevant source portions, and `doc/space/change-two-halls-2026-09-11/README.md` plus placement ledger. This is not an exhaustive behavioral audit of all secondary works. They are retained as meaningful returns; none is treated as redundant merely because the painter is primary.

## Runtime verification

The dedicated `probe_flow.gd` executes production scene methods. ARROWS, FIELD TIME, RESET and SEED use `XRToolsPointerEvent` press/release. SCALE and SPEED are exercised through slider values and their connected signals, not a physical headset drag.

- Final artifact-only run: **32 checks, zero failures** (`final-headless/checks.json`).
- Earlier narrow status-only artifact checks: after **25/25** and snapshot replay **26/26**, retained in `runtime-headless-v2/` and `before-headless-v2/`.
- Final actual-museum runs: snapshot replay **47/47**, repaired **50/50**, both exit 0 (`before-runtime/checks.json`, `after-runtime/checks.json`). The after run includes added base-mode and button-volume checks; the before run includes a snapshot-compilation check.
- Assertions cover all 24 arrow directions, unit sampler output, one update displacement, independent clocks, reset/seed semantics, slider mapping, nonmatching opposite-edge directions, and retained/rendered wrap stroke.
- `verify.py` checks exact snapshot hashes, narrow file scope, preserved painter executable lines, and stable production-source hashes during runtime.

The first headless attempt had two probe-local GDScript type-inference errors. They were corrected with explicit `Vector2` types. The first snapshot replay tried to make a transient lesson script take over its production path; the painter's `preload()` could not resolve it and that attempt hit the launcher's 180-second timeout. The successful replay uses the baseline painter with its class declaration omitted and its lesson preload redirected to the exact saved baseline lesson file. It does not modify working-tree production source. Failed attempts are retained in `runtime-headless/` and `before-headless/`. The first museum probe incorrectly expected Tiling's simulation-grid branch; it was corrected to inspect Flow's ordinary authored transplant, without changing the hall. That failed probe is preserved in `before-runtime-attempt1/`.

Logs contain an existing unrecognized resource UID and certificate-store startup errors, unavailable renderer features, shader-cache write errors, and a slow decorative body build warning. The standalone final artifact run also reports lack of a WorldEnvironment and an ObjectDB exit-leak warning. These are recorded rather than described as a clean engine log. No `SCRIPT ERROR` appears in either final museum log, and all probe assertions pass.

## Paired actual-museum captures

All six authored artifacts are instantiated once in the actual `Flow_Field` museum segment. The primary painter retains global position `(5.5, 1.05, 5.5)` and scale `(2.5, 2.5, 2.5)`. Captures use the production desktop camera at y=1.65 m, XR off, Dummy audio, mobile/Vulkan, and 1600×1000 output. The launcher starts hidden and logs explicitly under this evidence directory.

| View | Original snapshot replay | Repaired lesson |
|---|---|---|
| Full standing view, arrows hidden | [Before](before-runtime/standing-hidden.png) | [After](after-runtime/standing-hidden.png) |
| Same standing view, arrows shown | [Before](before-runtime/standing-shown.png) | [After](after-runtime/standing-shown.png) |
| Closer arrow/trail comparison | [Before](before-runtime/near-arrows-trails.png) | [After](after-runtime/near-arrows-trails.png) |

**CAPTURE assessment:** the final hidden/shown status is legible without title overlap; the full standing view exposes SCALE, SPEED, RESET, SEED, ARROWS and FIELD TIME. The nearer view makes sampled arrows, curved trails and long wrap strokes visible together. It intentionally crops the lower control row to concentrate on the canvas. No screenshot processing or compositing was used.

`image-pairs.json` and `verification.json` confirm identical camera pose/FOV/viewport and byte-identical particle histories. Each canvas uses seed 43, random seed 43019, held time zero, 80 particles and 120 steps of 1/60 second, with original trail length 50, SCALE 3 and SPEED 0.1. Particle processing is frozen for the captures, so these images establish visible state, not motion perception. Museum background timers remain live.

The first successful captures, retained in `before-runtime-overlap-observed/` and `after-runtime-overlap-observed/`, exposed the label/control problems. An external concurrent edit changed `commons/scenes/em/em_detail.gd` between those exploratory runs and the final pair. This Flow task did not edit that file. Both final runs use the same `21add4ec18bd0e8fbfde9cd1c687577a0930bd67964aef41d7fdeb0278855482` shared-source hash and keep it stable during each run. The main museum hash is also equal and stable; the final pair is not mixed across shared museum versions.

## Limits and completion criterion

Desktop pointer events and geometry assertions do not establish headset reach, controller occlusion, comfort, readable text at headset resolution, or learner discovery. The field's arrow refresh uses a 0.1-second threshold; this establishes the nominal update schedule, not perceptible lag. Screenshot pairs cannot prove that a learner can track one particle through a bend or notice the edge-direction discontinuity while moving.

Keep `headset_tested=false` and `learner_verified=false`. The local pass is complete: the repaired status and existing controls are visible at a standing camera height, all supporting artifacts remain placed, and the unchanged arrow/trail computation is verified. Those perceptual questions remain explicitly for headset/learner observation.
