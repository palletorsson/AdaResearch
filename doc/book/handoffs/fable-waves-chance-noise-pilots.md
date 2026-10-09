# Fable handoff: the Waves / Randomness / Noise pilots

**Astra review, 10 September:** source corrections are complete; runtime acceptance is pending. Read [the current review](astra-wcn-pilot-review-2026-09-10.md) first. The global authored-map exemption described below has been replaced by a three-map opt-in, the loose ends were addressed, and the capture commands were corrected. The remainder of this handoff records the original Fable delivery.

Status: **implemented — awaiting review.** Three rooms built and written, source-verified, nothing committed, runtime probes written and not run. Next model or session: start at "Pick up here".

## Outcome

The three pilots of `doc/research/waves-chance-noise/HANDOFF.md` exist as encounter + final together, on the recovered grid structure:

| room | the visitor's experiment | primary placement |
|---|---|---|
| WaveFunctions_Intro | release the pendulum; the rest ring lights at each centre crossing; the label reads the angle and the **signed** angular velocity and counts crossings — same place, two states | `control_pendulum:0:1.5:1#reference:plumb#evidence:trace` at (2,11) |
| Random_Definition | two grids from one seed match; REPLAY reconstructs; RANDOM re-seeds; **+1 DRAW** breaks the match with one extra draw and mends it on the next press | `seed_replay_demo:0:-0.5#comparison:replicas` at (3,12) |
| Noise_Perlin_Simplex | two fields, same seed / octaves / gain / size / ramp, bases read back from the generators on two readouts; one dial per side | `simplex_noise:0:1.1#seed:20260910#size:8#ramp:shared#panel:front` at (3,7); `perlin_noise:0:1.1#generator:perlin#seed:20260910#size:8#ramp:shared#panel:front` at (8,7) |

Batch handback in Astra's template: `ada_run/waves_chance_noise/2026-09-10-pilots-batch.md`; per-room `report.md` beside it; `field_notes.md` beside each final; archive and structure decisions in `doc/space/waves-chance-noise-pilots-2026-09-10/README.md`. The published guide was rebuilt and copied (35 maps, 0 primary/book mismatches).

## Pick up here

1. **Run the three probes, one at a time, when no Godot is running** (`tasklist | findstr Godot`). Commands are in the batch report under "To run when Godot is free". Each writes `probe_*.json` + `.png` under `ada_run/waves_chance_noise/<MAP>/` and exits non-zero on a failed check. Paste the JSON summaries into the three `report.md` "Invariant… observed" fields and flip the status lines.
2. **If a probe fails, read the failure line before touching the room.** The likeliest: a RackTemplates node name (`Param_0`, `Btn_2`, `InteractableAreaButton`) differing from what the artifact code assumes; a `_edit_records` row missing `tile_cell`; the noise panel colliding with the field's front row.
3. **Headset walk** — none done. The handoff's evidence taxonomy: say "emitted signal" for what the probes do, "tracked hand" only for what a person did.
4. **Decisions that are Palle's**, unchanged from the batch report:
   - the museum line at `commons/scenes/endless_museum.gd` ~10898 (authored exemption on the transplant's hand lookup) — six randomness halls with live bench stamps will re-layout from their maps on the next run;
   - Noise_Perlin_Simplex's floored basin and the removed 100 m `noise_terrain`;
   - the four names added to `CONFIG_PARAM_NAMES`;
   - what to commit. Every changed file that carried another session's uncommitted work still carries it; `before/` copies are in the archive.
5. **Then continue the plan's order**: Astra's review of these three → the remaining active halls in batches of two or three (Pendulum, Sine_Space, Effect_Sound, AirMusic, Synthesis_Lab; Entropy, Remove, Walk, Gaussian, Mushrooms, Game; Random_Noise_Types, Columns, One, Voxel, 6_Wall) → the sixteen extensions as standalone rooms, never silently added to the route.

## Files changed (baseline HEAD `aeddf7e2b`)

Code: `commons/artifacts/control_pendulum/control_pendulum.gd`, `algorithms/randomness/seed_replay/seed_replay_demo.gd`, `algorithms/randomness/perlinnoise/{PerlinNoise,NoiseVisualizer}.gd`, `algorithms/randomness/simplexnoise/{SimplexNoise,SimplexVisualizer}.gd`; shared: `commons/scenes/endless_museum.gd` (one line + comment), `commons/grid/GridInteractablesComponent.gd` (four names). New probes: `commons/testing/probe_wcn_{intro,random_definition,noise_pair}.gd`.

Rooms: for each of the three — `map_data.json`, `final.md`, `intent.md`, `blurb.md`, `summary.md`, `tutorial.md`, `technical.md`, `field_notes.md` (new); `critical.md` for Intro (appended) and Noise (rewritten, book-quoted sentence kept).

Data: `commons/data/book/{wavefunctions,randomness,noise}.json` (one line each); `commons/artifacts/registry/randomness.json` (`seed_replay_demo.dna.axes.comparison` re-derived, now includes `offset`); `commons/data/spine_artifact_order.json` was rewritten by `build_spine_artifact_order.py` run without a flag — derived, already dirty at baseline, corpus-wide diff.

Docs: `doc/research/waves-chance-noise/` rebuilt (audit, cards, index) and copied to the encyclopedia; `doc/space/waves-chance-noise-pilots-2026-09-10/`.

## What is verified and what is not

Verified from source: every changed script parses (gdtoolkit); the museum line parses in a stub; the three maps validate, are rectangular and pathfind (133/286, 218/286, 149/195 — the last was 1/89); `check_map_tokens` 0 unresolved; `final_tags --check` parity 0 disagreements; `cite_gate` holds every book citation into the rewritten files; every code excerpt in the three finals is found verbatim in its source; `/api/compose-docs` serves the new finals with `stale: []`.

Not verified: anything at runtime. Godot held the `user://` lock for the whole session (three to four instances), and the project forbids a second instance.

Known red that is not this work: `check_dna_declarations.py` exits 4 on four unrelated tokens; `final_tags --check` reports a stale tag in `Tutorial_Single`; `check_wave_platform_recovery.py` now trips on `WaveFunctions_Intro` because it asserts byte-equality with the recovery output — its owner should re-baseline after the pilot lands.

## Loose ends, small

- `reference` is not declared as a dna axis on `control_pendulum` — `apply_dna_block.py --token=control_pendulum` could not find the axes sub-object in `commons_artifacts.json`'s raw text.
- `noise_terrain` keeps a stale secondary role for Noise_Perlin_Simplex in `commons/data/artifact_roles.json` (the API omits unplaced tokens); its book line in `noise.json` is left for Astra.
- The `/api/find` content index is not live; use `/api/compose-docs?map=` to read a composed final.
- An adversarial review workflow was launched and stopped on Palle's instruction before any verdict returned; the rooms have had one reader.

## Start here (reading order for a fresh session)

`doc/research/waves-chance-noise/HANDOFF.md` → this file → `ada_run/waves_chance_noise/2026-09-10-pilots-batch.md` → the three `field_notes.md` → `python tools/forum.py read 260910-5zr9o`.
