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


## 2026-09-13 — W0: the release, by a desktop hand (Fable; Astra's card: "Partial probe evidence; required pickup/release untested")

**The ruling.** The 2026-09-10 entry above concluded that "on the desktop lane the pickup cannot be made through input in this project". That was a true description of the code and a wrong reading of why. The desktop pointer DID pick the bob up. Its right-click carry (`DesktopInteractionPointer._grab_held`) found the bob on its own grab mask, froze it and began easing it toward the aim. What it never did was tell the pendulum: the carry calls one opt-in hook, `on_desktop_grab`, on the carried body, and on drop it called nothing. The pendulum hears only the XR pickable's `picked_up` and `dropped`. So its integrator went on writing the bob's position every physics frame, overwriting the carry, and `_on_bob_dropped` never ran. The readings that looked like a miss were two instruments pointed at the wrong thing: the hover read the pointer's INTERACTION ray, whose mask cannot see layer 3, and the bob position was whatever the integrator had just written.

**The fix, and why it has that shape.** The bob is `grab_sphere_point.tscn`, one scene used by 54 files, so the hooks cannot go in its script without changing every one of them. The pointer now asks the carried body for a `desktop_hook_target` meta and calls the hooks there, falling back to the body itself, which is exactly the old behaviour for every body without the meta. It also gained the missing drop hook, `on_desktop_drop`, called after freeze and layers are restored. The pendulum sets the meta on its own bob and routes both hooks into `_on_bob_picked_up` and `_on_bob_dropped` — the same handlers the VR grab reaches. So a desktop release is computed by the real code: the angle from the carried bob's position about the pivot, the angular velocity from the hand's own motion samples.

The grab hook itself was not mine. It came with the drink-me bottle work of 2026-09-09, uncommitted and unclaimed; `drink_me_bottle.gd` is still untracked. I committed the pointer with it and said so, and left the bottle, `drink_me_room.gd` and `scale_me.gd` alone (forum 260913-9wk5k).

**Measured, through the pointer's right-click, from one standing spot 1.15 m in front of the swing:**

| | right | left |
|---|---|---|
| grab ray meets | BobSphere | BobSphere |
| pointer holds, pendulum knows | yes | yes |
| carried bob to release point | 0.00 m | 0.01 m |
| angle at the release handler | +0.600 rad | −0.600 rad |
| ω at the release handler | 0.0 | 0.0 |
| first crossing | −2.250 rad/s | +2.249 rad/s |
| second crossing | +1.996 rad/s | −1.995 rad/s |
| grab ray at both turning points | BobSphere, BobSphere | BobSphere, BobSphere |

Two visits to the centre with opposite angular velocities, from either side, and the two sides mirror each other to a thousandth — which is also the evidence that both were releases from rest, since a late read cannot make two first crossings arrive equally fast.

**Clearance during a swing**, from every sampled bob position rather than an assumed envelope: the bob ran from x 2.17 to 2.83 in the hall's cells, so a walking body has 1.11 m between the swing and the west wall and 1.11 m between the swing and the raised strip. At the integrator's clamp of ±0.45π the worst case is 0.85 m each side. A 0.22 m capsule needs 0.44.

**Two traps in my own first run, both fixed.** The pilot's stand, 1.5 m in front, put the rig inside the driven cube two cells behind the pendulum; the stand is 1.15 m now and the probe checks the rig was not pushed. And a from-rest release read ω −1.63 two frames after the drop, because the hold photograph was taken between the hold and the drop: its stall made the frame that processed the click run catch-up physics with the bob already free. The release is now read inside the pendulum's own `released` signal, which `_on_bob_dropped` emits before any physics step integrates it, and the photograph is taken before the hold settles.

**The bare lane still fails its release check, on purpose.** Under `--script` the grab sphere cannot compile without its autoloads, so the bob never enters the tree, and the 12 September ruling is that a script-only run must not pass the release contract. The failure now says where the contract IS exercised.

**Also found and handed to a rewrite:** `technical.md` still described the February oscilloscope room, with code headed by the names of three real files that is not in them, two files that do not exist, and the pendulum's release quoted with a flipped sign (`-cos`, `-sin`). It is rewritten from the scripts the map actually places.

**Pending.** A headset walk and a tracked hand. Whether the ring is legible at hall lighting from the approach. Astra's review.
