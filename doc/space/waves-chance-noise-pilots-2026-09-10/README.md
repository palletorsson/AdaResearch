# Waves / Randomness / Noise — the three pilots

10 September 2026. Fable 5.1, executing `doc/research/waves-chance-noise/HANDOFF.md` on Palle's instruction ("Start with the three pilots… preserving the recovered grid structure"). Status: **implemented — awaiting review**. Batch report: `ada_run/waves_chance_noise/2026-09-10-pilots-batch.md`.

## What is archived here

- `before/` — the exact working files before this pass, including other sessions' uncommitted work: the three maps and finals, the seven scripts, the museum and grid files, the three book chapters. Baseline HEAD `aeddf7e2b`, 1677 dirty paths at 13:11 (`ada_run/waves_chance_noise/_baseline/`).
- `pre-museum/` — the three maps at `a36f33c996004abcdc67ea2a0ac3fce72eba42fd`, the parent of the first endless-museum commit, for the structure comparison the handoff asks for.

## Structure decisions, one per room

| room | pre-museum | current before | decision |
|---|---|---|---|
| WaveFunctions_Intro | 9×22, interior 2s | recovered 2026-09-10 (wall_height 3, perimeter w) | **kept as recovered.** No layer cell moved. |
| Random_Definition | 5×20, raised 2-platforms at x=0/4, z=13–17 | 13×22, same 2s at x=1/5, z=14–18, `museum: None` → walls | **the wave recovery's contract applied**: `museum.wall_height: 3, gate_depth_rows: 0`. No layer cell moved. |
| Noise_Perlin_Simplex | 12×13 all void; the 100 m terrain was the floor | 13×15 basin + rim + 3 piers; pathfinder 1/89 reachable | **floored** (interior `1`, piers removed); `noise_terrain` removed from the hall; walk 149/195. |

## Shared infrastructure, two lines

- `commons/scenes/endless_museum.gd` (~10898): the transplant's necklace-hand lookup gets the authored exemption line 8204 already has. Map-authored halls build from their maps; Random_Definition was live-claimed by a 15-bead 2026-08-21 stamp.
- `commons/grid/GridInteractablesComponent.gd` CONFIG_PARAM_NAMES: `seed`, `octaves`, `offset`, `contrast_seed` are values, not rotation shorthand (`octaves` was already documented as a placement and was being misread).

Both files also carry the wave-recovery session's uncommitted work; nothing here is committed.
