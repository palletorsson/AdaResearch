## 2026-09-10 — the Intro pilot (doc/research/waves-chance-noise)

Ruling followed: the map is the placement authority; the recovered platforms (museum.wall_height 3, gate_depth_rows 0, perimeter 2→w, from doc/space/wave-platform-recovery-2026-09-10) are kept as recovered. No cell of the layers was moved; the cube collection is unchanged since 982ba8280 (2026-04-23) and was checked against the pre-museum map (a36f33c9): same 21 tokens at the same cells, structure differs only by the museum widening and the recovery's perimeter rule.

The one placement change is the token `control_pendulum:0:1.5:1` → `control_pendulum:0:1.5:1#reference:plumb#evidence:trace`. Both keys are word-valued, so the grid's numeric-shorthand rule cannot misread them.

Artifact: control_pendulum.gd gains `reference` (none|plumb), the `centre_crossed(direction, angular_velocity)` signal, a crossing count, and a label that prints the SIGNED angular velocity; the shipped label printed abs(ω). Defaults untouched: reference=none builds nothing new, so the other placements render as before. `reference` is not yet declared as a dna axis — apply_dna_block.py could not find the axes sub-object in commons_artifacts.json's raw text; noted for Astra.

Exactness: the final quotes `_physics_process` lines 268–274 (the integrator, resonance branch omitted and said so) and `_on_bob_dropped`'s two velocity lines, verbatim. The predicted θ(t) under evidence=trace is for START_ANGLE 0.3 rad, not the visitor's release; the final says so.

Rejected: a live θ(t) of the visitor's own release (a real instrument, but a new one — deferred); a second regime as a comparison (the card says change only that setting if added; not added).

Evidence: source checks pass (gdparse, pathfinder 133/286 OK, token gate, final_tags, cite_gate, excerpts verbatim). Runtime: commons/testing/probe_wcn_intro.gd written, NOT RUN — four Godot instances held the user:// lock all day. Headset: not walked.

Supporting texts: intent, blurb, summary, tutorial rewritten (they described a 2026-02 oscilloscope room that no longer exists); technical.md's invented control_pendulum script replaced with the real integrator; critical.md kept (its quoted sentence is a book citation) and given a closing section on the integrated pendulum versus the prescribed sine. Book line for control_pendulum rewritten.


## Astra source review - 2026-09-10

The release tangent now follows increasing angle, and world hand velocity is converted into the pendulum frame. The lifetime crossing counter is compared with a captured baseline in the probe. final.md distinguishes the fixed initial-condition prediction from a recording, retains pre-arrival crossings, and labels the reduced integration excerpt. The primary book note now addresses the gesture discarded on release rather than treating this integrated pendulum as a clock-indexed sine.

All three pilots explicitly set `museum.artifact_placement: "map"`. This replaces the broad authored-map exemption: other rooms keep their existing necklace placement behaviour. Recovered wave geometry is unchanged.

Status: source corrections complete; museum runtime probes and tracked-hand verification pending. See `doc/book/handoffs/astra-wcn-pilot-review-2026-09-10.md`. Earlier evidence in this file describes the Fable handback before these corrections.


## 2026-09-10 — first museum runs (Fable)

`probe_wcn_intro.gd`, rendered under the watchdog, five runs, the last headless with `--log-file`. Observed: the release path cannot be exercised from a SceneTree probe. `grab_sphere.gd` names `TextManager` and XR Tools' `pickable.gd` names `XRToolsUserSettings` at compile time; without the autoloads both fail to compile, the grab sphere instantiates as a bare RigidBody3D, `control_pendulum._create_grabbable_bob` aborts on `alter_freeze` (engine.log line 1370) and the bob never enters the tree. In the shipped game the autoloads exist and the bob is built; this is the known SceneTree-probe limit, now with its exact chain. The probe marks the release path NOT TESTABLE here and measures the rest: the reference, the readout, the swing from START_ANGLE with crossings of alternating direction and sign (nine in seven seconds), the swing envelope and both release positions clear of collision. `museum.sculpture_clear_rects` [[1,9,5,14]] keeps dealt plinths off the pendulum's swing. The release, the grip and the hand's velocity need the desktop lane (`--em-autostart`) or a headset.


## 2026-09-10, evening — the release, under project startup (Fable, after Astra's runtime review)

Run: `bash tools/run_wcn_probe.sh intro live` — Astra's revised probe (the missing bob a failed contract, skipped work recorded, `release_exercised` reported) ported to a Node by `tools/port_wcn_probes_live.py` and run as the project's main scene through `commons/testing/probe_live.tscn`, so TextManager, GameManager, XRToolsUserSettings and MapProgressionManager exist and XR Tools' `pickable.gd` and `grab_sphere.gd` compile. Result: 28 checks, 0 failures, `status: passed`, `skipped: []`, `release_exercised: true`, no script errors in the engine log (`probe_intro_live.json`, `probe_intro_live_engine.log`).

What the run established: the bob enters the tree at frame 0 under ControlPendulum (`bob_tree_events`), carrying the pickable's `picked_up` / `dropped` signals; the rest point is at 0.90 m; both release positions are reachable and clear; a hand moving toward increasing angle releases in that direction; the artifact answers `dropped` (not grabbed after release); the release angle comes from the bob's position (0.60 rad); five centre crossings in the observation window alternate in direction with angular velocities of opposite sign (−2.71, +2.40 rad/s); the readout prints a signed ω; a second release from the other side crosses the other way; the driven cube listens to this pendulum. Control path, stated in the JSON: `picked_up` / `dropped` emitted programmatically on the bob pickable — no tracked hand.

Actual desktop input, tried and recorded separately: the project's desktop rig stood at segment-local (2.5, 0, 13.0), aimed at the bob and right-clicked twice through the input pipeline (the rig's RMB carry). Its pointer reported nothing under the crosshair, the bob moved 0.02 m, `pendulum_grabbed` stayed false before and after. The desktop carry is a stand-in for a VR grab and never calls the pickable's `pick_up`, and the pointer's mask does not see the bob; on the desktop lane the pickup cannot be made through input in this project. So the release evidence is the emitted-signal lane under the real autoloads; the tracked-hand release is the headset lane and stays pending. Capture: `probe_intro_desktop_primary_live.png`, the installation from the rig's own camera at that spot (the rod, the bob, the reference ring and the θ(t) trace), beside the probe camera's `probe_intro_live.png`.


## 2026-09-11, 07:37 — refreshed under the current probe sources (Fable, Astra's W2 completion brief, item 1)

`bash tools/run_wcn_probe.sh intro live`, Godot free: 28 checks, 0 failures, `status: passed`. Why the rerun: after this room's 20:50 run the shared probe sources changed (the capture settle moved from the render server's `frame_post_draw` to a timer; the driver's pose log and the guard flag were added), so the evidence is regenerated from the sources that now stand; the results are the same as the second pass. Captures refreshed in place. Headset: pending.

**2026-09-12 — the visual pass (Astra's illustrated review: "the pale bob, rod and prediction nearly disappear against the bright floor; the counter is distant and small").** Under `reference:plumb` only: a dark matte slate (1.6 × 1.9 m) stands 0.30 m behind the swing plane, behind the trace plot too, so the bob, the rod, the rest ring and the prediction are read against it; the state label is a cased readout on a plate beside the pivot (x +0.78, out of the swing), font 24 at 1.1 mm per pixel. The hand target is untouched. Live: 31 checks / 0 failures; the capture from the approach shows the bob, its ring, the plot and the signs and count on one dark ground.
