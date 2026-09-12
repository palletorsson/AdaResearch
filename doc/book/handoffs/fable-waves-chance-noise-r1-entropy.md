# Handoff — Waves, Randomness and Noise, batch R1: Random_Entropy (Fable 5.1, 2026-09-11)

**Astra review, 11 September:** partial acceptance. [Review and corrections](astra-r1-entropy-review-2026-09-11.md); [current follow-up](fable-r1-entropy-followup.md). The saved R1 logs exit 0; the exit-127 account below is corrected by the review.

Status (after the follow-up, `ada_run/waves_chance_noise/2026-09-11-r1-entropy-followup.md`): **the three corrections made and run — bare 132 / 0, live 139 / 0, the build-once probe 15 / 0, all exit 0, no script errors, eight views, the panel through its own signal and the desktop rig's pointer; handback `ada_run/waves_chance_noise/2026-09-11-r1-entropy-batch.md` — awaiting Astra's acceptance, a person at the desk and a headset walk.** Nothing committed.

Read first: `doc/research/waves-chance-noise/maps/Random_Entropy.md` (the card), the handback, `ada_run/waves_chance_noise/Random_Entropy/report.md`, `commons/maps/Random_Entropy/field_notes.md` (the ruling, the map decisions, the runtime findings, the rejected ideas).

## What was built

- `shannon_entropy_meter.gd`: a `stand` axis (`ledger`): the panel lifted 1.40 m onto a post over a 2.30 × 0.45 m desk with a collider; every draw as a coloured tile on the desk with a pale bar before the first forty; SORT (a stable sort of a copy, the counts and H untouched, the moved tiles counted), CONTRAST (a second fixed sample, same alphabet and N, p ∝ 2⁻ᵏ, its own seed), DISCLOSE (the meter's own ladder, the staging kept through the rebuild); a five-line readout on the desk's front; `measure()` and the state API. `none` builds and shows what it did; the measurement is split into the draw and the measuring of a sequence, the shipped lines in the shipped order.
- Map: `shannon_entropy_meter:90#stand:ledger#disclosure:ledger` at (5,6), facing the corridor; `artifact_placement: map`; rects over the desk's approach and the door route. Texts revised and completed; final.md in the discovery voice with excerpts verified against the source.
- `commons/testing/probe_wcn_entropy.gd` + live port; runner name `entropy`.

## Pick up here

1. Astra: the room and its texts; the measurement split in a shipped artifact — identical output by construction; the `_built` guard — a repair that stops the meter building its panel twice when the museum configures it before `_ready` (no other placement carries a config token, so none other is changed by it; the standalone build-once probe covers the shipped orders).
2. A person: read the tiles and the bars, SORT, read the plate, CONTRAST, DISCLOSE twice; the strip and the panel's labels at their own distance.
3. Palle's calls: the ledger staging and its front-face plates; the gauge turned to the corridor; what to commit.
4. The next hall on the route: Random_Remove (the eligible set made spatial), then Random_Walk, Random_Gaussian, Random_Mushrooms, Random_Game; then the Noise halls to Noise_Perlin_Simplex (the pilot).

## Files

Changed: `commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.gd`, `commons/maps/Random_Entropy/{map_data.json, final.md, blurb.md, tutorial.md}`, `tools/port_wcn_probes_live.py`, `tools/run_wcn_probe.sh`, `tools/check_wcn_w1_source_review.py`. New: `commons/maps/Random_Entropy/{intent.md, summary.md, technical.md, field_notes.md}`, `commons/testing/probe_wcn_entropy.gd`, `commons/testing/probe_wcn_entropy_live.gd`, `ada_run/waves_chance_noise/Random_Entropy/report.md`, `ada_run/waves_chance_noise/2026-09-11-r1-entropy-batch.md`, `doc/space/waves-chance-noise-r1-entropy-2026-09-11/` (before-copies, hashes, README).
