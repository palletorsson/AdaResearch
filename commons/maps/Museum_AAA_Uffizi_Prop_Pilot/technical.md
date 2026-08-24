# Prop Placement Technical Contract

The compiler models every principal wall with orientation-independent `u` and `v`: `u` runs horizontally along the wall and maps to world x or z; `v` always maps to world y from floor to ceiling. The reusable prop catalogue and semantic rules live in `commons/data/museum_prop_placement_rules.json`.

Hard gates run in this order: wall bounds, artifact/environment ownership, requested wall band, central feature-field protection, artifact wall-claim overlap, interactive reach height, semantic-anchor distance, grounding, and prop-to-prop overlap. Life safety is allowed at entrance side rails even when the artifact protects the central field. Accepted placements compile to `commons/data/curated_walls/clusters/*.json`; rejected placements remain evidence in map metadata and never become runtime tokens.

Cluster anchors sit on x=16, the existing one-metre display band. Wall pieces use exact local metre offsets and the `wall` flag, so the runtime resolver preserves their height and does not auto-ground them. The x=17..19 public spine remains empty.

```powershell
python toolsuild_uffizi_prop_placement_pilot.py
python tools\map_pathfinder.py check Museum_AAA_Uffizi_Prop_Pilot
```
