## 2026-09-10 — the Intro pilot (doc/research/waves-chance-noise)

Ruling followed: the map is the placement authority; the recovered platforms (museum.wall_height 3, gate_depth_rows 0, perimeter 2→w, from doc/space/wave-platform-recovery-2026-09-10) are kept as recovered. No cell of the layers was moved; the cube collection is unchanged since 982ba8280 (2026-04-23) and was checked against the pre-museum map (a36f33c9): same 21 tokens at the same cells, structure differs only by the museum widening and the recovery's perimeter rule.

The one placement change is the token `control_pendulum:0:1.5:1` → `control_pendulum:0:1.5:1#reference:plumb#evidence:trace`. Both keys are word-valued, so the grid's numeric-shorthand rule cannot misread them.

Artifact: control_pendulum.gd gains `reference` (none|plumb), the `centre_crossed(direction, angular_velocity)` signal, a crossing count, and a label that prints the SIGNED angular velocity; the shipped label printed abs(ω). Defaults untouched: reference=none builds nothing new, so the other placements render as before. `reference` is not yet declared as a dna axis — apply_dna_block.py could not find the axes sub-object in commons_artifacts.json's raw text; noted for Astra.

Exactness: the final quotes `_physics_process` lines 268–274 (the integrator, resonance branch omitted and said so) and `_on_bob_dropped`'s two velocity lines, verbatim. The predicted θ(t) under evidence=trace is for START_ANGLE 0.3 rad, not the visitor's release; the final says so.

Rejected: a live θ(t) of the visitor's own release (a real instrument, but a new one — deferred); a second regime as a comparison (the card says change only that setting if added; not added).

Evidence: source checks pass (gdparse, pathfinder 133/286 OK, token gate, final_tags, cite_gate, excerpts verbatim). Runtime: commons/testing/probe_wcn_intro.gd written, NOT RUN — four Godot instances held the user:// lock all day. Headset: not walked.

Supporting texts: intent, blurb, summary, tutorial rewritten (they described a 2026-02 oscilloscope room that no longer exists); technical.md's invented control_pendulum script replaced with the real integrator; critical.md kept (its quoted sentence is a book citation) and given a closing section on the integrated pendulum versus the prescribed sine. Book line for control_pendulum rewritten.
