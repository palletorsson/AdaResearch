# Waves, Randomness and Noise — batch R1 archive: Random_Entropy (2026-09-11)

Fable 5.1, on Palle's word to "continue with the next hall in the same way" after the Synthesis Lab. One hall: **Random_Entropy**, the route's second Randomness hall (Random_Definition, the pilot, is done).

## What is here

- `before/` — byte copies taken before the first edit: `shannon_entropy_meter.gd`, `.tscn` and `README.md` (the scene and the README unchanged in the end), the map (the working tree's, and the hand layout from 90d48b730 as `map_data.90d48b730.hand-layout.json`), and the three texts the folder had (blurb, final, tutorial).
- `before_sha256.txt` / `after_sha256.txt` — hashes before and after; the after list adds the four new texts, the field notes, the two probes, the three tools, the report, the handback and the handoff.
- `.gdignore` — so the archived script never competes with the live one for its class name.

## Structure

No structure or utility cell was moved. Added under `map_info.museum` (the map had no museum block): `sculpture_clear_rects` [[4,4,7,9],[7,0,9,11]] and `artifact_placement: "map"`.

## Placement

`shannon_entropy_meter` at (5,6) → `shannon_entropy_meter:90#stand:ledger#disclosure:ledger` at (5,6): turned to face the corridor. Nothing else moved.

## The artifact

`shannon_entropy_meter.gd` gained an opt-in `stand` axis (`ledger`); `none` builds and shows what it did (nine functions byte-identical); the measurement is split into the draw (`_run_measurement`) and the measuring of a sequence (`_measure`), the shipped lines in the shipped order. **One repair to shipped behaviour, for Astra:** a `_built` guard stops the panel being built twice when the museum applies a token's config before `_ready` (every tokened museum placement of the meter changes: one panel instead of two stacked).

## Reversal

Copy the `before/` files back over their originals (the `.gd`, the map, blurb, final, tutorial); delete `intent.md`, `summary.md`, `technical.md`, `field_notes.md`, the two probes, the report, the R1 batch file and the handoff; remove the `entropy` line from `tools/run_wcn_probe.sh`, `entropy` from `tools/port_wcn_probes_live.py` and the Random_Entropy row from `tools/check_wcn_w1_source_review.py`.

## Runtime

Both lanes ran on 2026-09-11, 13:19–13:30, in the gaps between another session's museum autopilot runs (the runner refused beside each; nothing terminated): bare 89 / 0, live 96 / 0 at the third pair, both exit 0 (the batch handback's "exit 127" line was wrong for R1 — it was W3/W4's — and is corrected in the follow-up).

## Follow-up (2026-09-11, afternoon)

Astra reviewed the batch (partial acceptance) and set three corrections; a fourth fault was found in the follow-up captures. The meter, the hall probe and its port, a new build-once probe (`commons/testing/probe_wcn_entropy_buildonce.gd`), the runner (`entropy_once`), the final, tutorial, technical and field notes changed again; `after_sha256.txt` is regenerated over the follow-up state. Handback: `ada_run/waves_chance_noise/2026-09-11-r1-entropy-followup.md`. Runs: bare 132 / 0, live 139 / 0, build-once 15 / 0, all exit 0. The accepted-partial logs are retained in `ada_run/waves_chance_noise/Random_Entropy/history/2026-09-11-1328-r1-accepted-partial/`.
