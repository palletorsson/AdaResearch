# Substrate State Baseline — 2026-04-27

> A snapshot of where the substrate is at the end of the spine-substrate
> work day, so future sessions resume from a known anchor and the artifact-
> auto-research pivot has a stable referent.

## Channels live

Six channels operational, three scoped:

| # | Channel | File | Status | Expressions registered |
|---|---|---|---|---|
| 1 | color | `commons/grid/mutators/grid_color_mutator.gd` | ✅ shipped | 5 palettes + 4 gradients + sphere_reflection (10 total) |
| 2 | visibility | `commons/grid/mutators/grid_visibility_mutator.gd` | ✅ shipped + 5 floor-plan modes | rule_30 / sierpinski / checkerboard / rings (4) + menger_sponge / sphere_shell / bfs_frontier_t1..t8 (10) = 14 |
| 3 | transform | `commons/grid/mutators/grid_transform_mutator.gd` | ✅ shipped | rotate_by_row / rotate_by_distance / lift_by_row / scale_pulse / force_field (5) |
| 4 | glyph (subdivision) | `commons/grid/mutators/grid_glyph_mutator.gd` | ✅ shipped | subdivide_uniform / subdivide_by_attention / subdivide_by_pattern_edge (3) |
| 5 | part (role-tagging) | `commons/grid/mutators/grid_part_mutator.gd` | ✅ shipped | flower_grammar / insect_grammar / bird_grammar (3) |
| 6 | floor-plan modes | inside visibility mutator | ✅ shipped | DISABLED / SPAWN_LARGEST / AUTO_STITCH / ALGORITHM_PATH / PATH_GUARANTEE (5) |
| 7 | mechanism | — | ❌ scoped | (10 algorithms queued in catalogue) |
| 8 | particle | — | ❌ scoped | (8 queued) |
| 9 | body (avatar substrate) | — | ❌ scoped | (8 queued — wearables) |

**Total expressions: 35 across 5 channels.** Documented in `doc/ALGORITHM_CATALOGUE.md`
(80 algorithms total, 45 still aspirational).

## Maps that host substrate runners

Two intentional placements after the over-broad-deployment correction:

| Map | Sequence | Runner type | Channels enabled |
|---|---|---|---|
| `CA_Introduction` | `cellularautomata` | `grid_substrate_runner` (defaults) | visibility (rule_30/sierpinski/checkerboard/rings) + floor-plan PATH_GUARANTEE |
| `Fold_Theatre` | `qfeplaboratory` | `FoldTheatreRunner` (subclass) | visibility (rule_30/sierpinski/menger_sponge) + glyph + part (flower_grammar) + color-by-role + floor-plan PATH_GUARANTEE |

The remaining 11 substrate placements have been retracted per
`doc/SUBSTRATE_DEPLOYMENT_POLICY.md`. Eight sequences are blocked on
authoring sequence-specific expression vocabularies before they can be
re-deployed.

## Tools shipped

| Tool | Purpose |
|---|---|
| `tools/make_mutator_movie.py` | Stitch substrate-test captures (synthetic 16² / 12×8×12 scenes) into mp4 |
| `tools/make_substrate_cycle_movie.py` | Stitch real-map cycle captures into mp4 with title cards + labels |
| `tools/place_substrate_runner.py` | Idempotent batch placer for substrate runners |
| `tools/remove_substrate_runner.py` | Reverse of the above |
| `commons/testing/capture_mutator_cycle.gd` | Synthetic-scene capture across all channels and combos |
| `commons/testing/capture_map_substrate_cycle.gd` | Real-map capture across each visibility pattern, with walkability validation |
| `commons/testing/capture_glyph_test.gd` | Smoke test for the glyph channel |
| `commons/testing/capture_part_test.gd` | Smoke test for the part channel |

## Documents

| Doc | Role |
|---|---|
| `doc/EDGES_OF_ALGORITHM.md` | The 13 edges (formal A–F + critical G–M) the late spine teaches |
| `doc/EDGES_OF_ALGORITHM_VISUAL_SEEDS.md` | ~70 cousin works moodboarded per edge |
| `doc/ALGORITHM_CATALOGUE.md` | 80 algorithms × 13 families × channels × cost × sequence-affinity |
| `doc/SUBSTRATE_DEPLOYMENT_POLICY.md` | When and how to deploy substrate runners |
| `doc/SUBSTRATE_STATE_BASELINE.md` | This document |

## Reference videos

In the encyclopedia at `ada_encyclopedia/public/blog/`:

- `mutator-tour.mp4` — substrate's 2D test scene, 5 channels (~30s)
- `mutator-tour-3d.mp4` — substrate's 3D test scene, all expressions (~60s)
- `substrate-cycle-ca-introduction.mp4` — `CA_Introduction` cycling 4 visibility patterns
- `fold-theatre-first-cycle.mp4` — `Fold_Theatre` cycling 3 F-edge foldings with flower-anatomy painting

## What's broken / open

| Item | Severity | Notes |
|---|---|---|
| `GT_Foundations` PATH_GUARANTEE returns BROKEN | low | adjacent endpoints; PATH_GUARANTEE BFS edge case for short distances |
| `SearchPathfinding_Intro` PATH_GUARANTEE returns BROKEN | low | same edge case |
| 8 sequences without sequence-specific visibility vocabulary | medium | blocks re-deployment; new expression files needed (~1 session each) |
| SpecimenLabel artifact not built | medium | needed to make the F-edge legible to the player (name the foldings) |
| Mechanism / particle / body channels scoped only | medium | 26 algorithms in catalogue queued |
| Recipe language not implemented | low | FoldTheatreRunner-as-subclass works; recipe language is polish |
| Vision-critique loop step not built | medium | the auto-research loop's last hole; ~150 lines of Python |

## Resume here

A future session can pick up by running:

```powershell
# 1. Get baseline state
cat doc/SUBSTRATE_STATE_BASELINE.md
cat doc/SUBSTRATE_DEPLOYMENT_POLICY.md

# 2. Reproduce both canonical maps' captures
& "C:/.../godot.exe" --path . --xr-mode off --no-window `
  --script res://commons/testing/capture_map_substrate_cycle.gd `
  -- --target=CA_Introduction --out=user://baseline/CA_Introduction
& "C:/.../godot.exe" --path . --xr-mode off --no-window `
  --script res://commons/testing/capture_map_substrate_cycle.gd `
  -- --target=Fold_Theatre --out=user://baseline/Fold_Theatre

# 3. Compare against the videos in ada_encyclopedia/public/blog/
```

If the captures match the videos, the substrate is in baseline state.
Continue from there.

## Open arc

The next-substrate moves (in priority order):

1. **SpecimenLabel artifact** — names the foldings; closes F-edge teaching claim
2. **One sequence vocabulary** — pick `fractals`, write 2–3 missing expressions,
   subclass a runner, place on chamber, capture. Proves the per-sequence-vocabulary
   pattern with a concrete second example.
3. **Fix the 2 PATH_GUARANTEE outliers** — small BFS edge-case
4. **Mechanism channel** — the substrate's first machine

But the bigger pivot is **artifact auto-research**, which is a different
methodology applied at the artifact scale. See companion doc (forthcoming):
`doc/ARTIFACT_AUTO_RESEARCH.md`.

*Baseline locked 2026-04-27. Companion to all four substrate docs above.*
