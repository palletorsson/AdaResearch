# Handoff — Waves, Randomness and Noise, batch R1b: Random_Remove (Fable 5.1, 2026-09-11)

Status: **implemented on the existing bench and run in both lanes on desktop — bare 72 / 0, live 77 / 0, both exit 0, no script errors, nine views, the panel through the push button's own signal path and the desktop rig's pointer; handback `ada_run/waves_chance_noise/2026-09-11-r1b-remove-batch.md` — awaiting Astra's acceptance, a person at the bench and a headset walk.** Nothing committed.

Read first: `doc/research/waves-chance-noise/maps/Random_Remove.md` (the card), the handback, `ada_run/waves_chance_noise/Random_Remove/report.md`, `commons/maps/Random_Remove/field_notes.md` (the ruling, the runtime findings, the rejected ideas).

## What was built

- The bench was another hand's, uncommitted since 8 September (`RemoveRandom.gd` modified, `remove_random_fixture.gd` untracked, `#local_grid:true` on the token): kept and extended. `RemoveRandom.gd`: `replay_on_reset` (opt-in), `run_seed`, `removal_log`, `initial_eligible`, `new_seed()`, the state. The fixture: replay on, five-digit seeds named on the status, a NEW SEED button, the exhausted set announced.
- Map: `remove_random:90#local_grid:true` at (6,7) as it was; `artifact_placement: map`; one clear rect. Texts revised and reconciled; final.md in the discovery voice with excerpts verified against the source; the handoff to Random_Walk (the off-route 10 PRINT room is not required).
- `commons/testing/probe_wcn_remove.gd` + live port; runner name `remove`.

## Pick up here

1. Astra: the room and its texts; the replay as an opt-in on a shared script (the shipped placements keep their stream); the book line (the old draft's "demolition algorithm").
2. A person: count the amber, REMOVE ONE sixteen times, RESET and watch the order repeat, NEW SEED, then ROW under the same seed.
3. Palle's calls: the dark sphere's body beside the bench; what to commit (and the 8 September hand's uncommitted bench).
4. The next hall on the route: Random_Walk — a walker whose reachable places are decided one draw at a time.

## Files

Changed: `algorithms/randomness/RemoveRandom.gd`, `algorithms/randomness/remove_random_fixture.gd`, `commons/maps/Random_Remove/{map_data.json, final.md, blurb.md, intent.md, summary.md, critical.md, technical.md, tutorial.md}`, `tools/port_wcn_probes_live.py`, `tools/run_wcn_probe.sh`, `tools/check_wcn_w1_source_review.py`. New: `commons/maps/Random_Remove/field_notes.md`, `commons/testing/probe_wcn_remove.gd`, `commons/testing/probe_wcn_remove_live.gd`, `ada_run/waves_chance_noise/Random_Remove/report.md`, `ada_run/waves_chance_noise/2026-09-11-r1b-remove-batch.md`, `doc/space/waves-chance-noise-r1-remove-2026-09-11/` (before-copies, hashes, README).
