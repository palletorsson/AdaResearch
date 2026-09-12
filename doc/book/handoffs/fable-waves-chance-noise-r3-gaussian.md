# Handoff — Waves, Randomness and Noise, batch R3: Random_Gaussian (Fable 5.1, 2026-09-11)

Status: **implemented and run in both lanes on desktop — bare 101 / 0, live 107 / 0, both exit 0 (the verification pair of 12 September); the keypad and the stand panel through the push buttons' own signal path and the desktop rig's pointer; handback `ada_run/waves_chance_noise/2026-09-11-r3-gaussian-batch.md` — awaiting Astra's acceptance, a person at the cabinet and a headset walk.** Nothing committed.

Read first: `doc/research/waves-chance-noise/maps/Random_Gaussian.md` (the card), the handback, the guide's `runtime-captures.html` (every hall's probe captures, by `tools/build_wcn_captures_page.py`), `ada_run/waves_chance_noise/Random_Gaussian/report.md`, `commons/maps/Random_Gaussian/field_notes.md` (the ruling, the floor recovery, the runtime findings, the rejected ideas).

## What was built

- The museum read this map's south `0` half as holes: a void with a one-cell strip, the bell terrain over everything, the primary's keypad under the floor. The south half is `1` floor now (R5); the recovery's platforms and `wall_height 3` are kept; the wedge that bridged the vanished step is gone.
- `distribution_sampler.gd`: an opt-in `stand:cabinet` — a cabinet lifting the histogram to standing height, the keypad and a second panel (BATCH · PAUSE / NEW SEED · BINS) on a shoulder, a housed six-line readout (law and transform; landed, in flight, cap; clipped and edge-bin counts; bins, mean, deviation; the seed and CLEAR's policy; the cadence), ghost frames at the expected count per bin at the present N with the folded mass in the edge bins, a named seed. On every path: landed values kept, draws and folds counted; nothing returned changes.
- Map: `distribution_sampler:180#stand:cabinet` at (11,19); the bell terrain to (3,17) at a third; the Galton board at one and a half times bench scale; gaussian_random to (10,15); `artifact_placement: map`; one rect. Texts revised; final.md in the discovery voice with excerpts verified; the handoff to Random_Mushrooms.
- `commons/testing/probe_wcn_gaussian.gd` + live port; runner name `gauss`. `tools/build_wcn_captures_page.py` builds the guide's captures page for every hall.

## Pick up here

1. Astra: the room and its texts; the ghosts as the second use of the expected-count pattern. (12 September: the floor accepted, the sampler made the pearl's hero, the teleporter's void floored in the museum by `museum.floor_cells`.)
2. A person: PAUSE, CLEAR, twelve beads, BATCH three times, UNIFORM, EXPON, BINS round the cycle, CLEAR twice.
3. Palle's calls: the mound's and the board's scales.
4. The next hall on the route: Random_Mushrooms — which parts of a population were allowed to vary.

## Files

Changed: `commons/artifacts/distribution_sampler/distribution_sampler.gd`, `commons/maps/Random_Gaussian/{map_data.json, final.md, blurb.md, intent.md, summary.md, critical.md, technical.md, tutorial.md}`, `tools/port_wcn_probes_live.py`, `tools/run_wcn_probe.sh`, `tools/check_wcn_w1_source_review.py`. New: `commons/maps/Random_Gaussian/field_notes.md`, `commons/testing/probe_wcn_gaussian.gd`, `commons/testing/probe_wcn_gaussian_live.gd`, `tools/build_wcn_captures_page.py`, `doc/research/waves-chance-noise/runtime-captures.html` (+ `images/*.jpg`), `ada_run/waves_chance_noise/Random_Gaussian/report.md`, `ada_run/waves_chance_noise/2026-09-11-r3-gaussian-batch.md`, `doc/space/waves-chance-noise-r3-gaussian-2026-09-11/` (before-copies, hashes, README).
