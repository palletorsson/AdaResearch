# Handoff — Waves, Randomness and Noise, batch R2: Random_Walk (Fable 5.1, 2026-09-11)

Status: **implemented and run in both lanes on desktop — bare 106 / 0, live 112 / 0, both exit 0; the keypad and the wing through the push buttons' own signal path and the desktop rig's pointer; handback `ada_run/waves_chance_noise/2026-09-11-r2-walk-batch.md` — awaiting Astra's acceptance, a person at the case and a headset walk.** Nothing committed.

Read first: `doc/research/waves-chance-noise/maps/Random_Walk.md` (the card), the handback, the guide's `runtime-captures.html` (every hall's probe captures, by `tools/build_wcn_captures_page.py`), `ada_run/waves_chance_noise/Random_Walk/report.md`, `commons/maps/Random_Walk/field_notes.md` (the ruling, the floor recovery, the runtime findings, the rejected ideas).

## What was built

- The museum read this map's `0` arena as holes: a starry void with a one-cell strip of floor, the ring a metre up and unreachable, the grab-paper rack sealing the north door, the terrarium slid into the raised ring. The arena is `1` floor now (R5: the original layout recovered as a walkable room); the ring and `wall_height 3` are kept as the 10 September recovery left them.
- `random_walk_terrarium.gd`: an opt-in `stand:logbook` — a wing on the cabinet's flank with a housed six-line readout (rule and dimension, steps and simulation time, frame clock and catch-up cap, trail kept and who is followed, the named seed and RESET's policy, the glass rule), ONE / ALL / NEW SEED, a body round the case; a `seed` alias; a followed walker. The shipped default builds none of it. One shipped fault fixed: the keypad's RESET was connected as a zero-argument method to a one-argument signal and had never fired.
- Map: `random_walk_terrarium:90#stand:logbook` at (4,1) on the floor, facing the door strip; `random_walk_128:0:0:0.2` at (3,4) (unscaled it is a ten-metre carpet of cubes with colliders); the rack to (3,7); the lab room to (9,4) with its Gaussian annotation corrected; the pixel clouds on the ring cells; `artifact_placement: map`; one clear rect. Texts revised; final.md in the discovery voice with excerpts verified against the source; the handoff to Random_Gaussian.
- `commons/testing/probe_wcn_walk.gd` + live port; runner name `walk`.

## Pick up here

1. Astra: the room and its texts; the floor recovery (a half-metre change in the grid lane's pit); the logbook as an opt-in on a shared artifact; the book line (the draft's "explores space more honestly than any planned path").
2. A person: follow the red bead, predict, RESET and watch the walk repeat, NEW SEED, 2D against 3D against LEVY, read the plate at a step's distance.
3. Palle's calls: the pixel-cloud towers (one-metre cubes through the roof, as the artifact builds them everywhere); the lab room's `bool(String)` fault (`lab_room.gd:725`, four script errors per run, not this hall's); what to commit.
4. The next hall on the route: Random_Gaussian — many draws, one law, the shape they make.

## Files

Changed: `commons/artifacts/random_walk_terrarium/random_walk_terrarium.gd`, `commons/maps/Random_Walk/{map_data.json, final.md, blurb.md, intent.md, summary.md, critical.md, technical.md, tutorial.md}`, `tools/port_wcn_probes_live.py`, `tools/run_wcn_probe.sh`, `tools/check_wcn_w1_source_review.py`. New: `commons/maps/Random_Walk/field_notes.md`, `commons/testing/probe_wcn_walk.gd`, `commons/testing/probe_wcn_walk_live.gd`, `ada_run/waves_chance_noise/Random_Walk/report.md`, `ada_run/waves_chance_noise/2026-09-11-r2-walk-batch.md`, `doc/space/waves-chance-noise-r2-walk-2026-09-11/` (before-copies, hashes, README).
