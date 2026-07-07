# Map prompt: Trans_Translation

*Auto-generated from `commons/maps/Trans_Translation/map_data.json`. Edit any line; re-generate via `tools/generate_from_prompt.py`.*

**Archetype**: `bridge`  *(promenade · pit · ziggurat · dungeon · cathedral · amphitheater · spiral · hub_spokes · atrium · crossroads · forum · bridge · tower · maze · stacks · cave · theater · quadrants · citadel · constellation · irregular)*
**Dimensions**: 7 wide × 24 deep × 10.0 tall
**Aspect ratio**: 3.43  *(>2 = corridor, ~1 = room)*
**Spawn**: row 22, col 6
**Teleporter**: row 22, col 5
**Structure**: void 33% · raised 2%

## Artifacts

| t | row | col | lane | name |
|---|---|---|---|---|
| 0.00 | 2 | 6 | right | `z_translation_cube` |
| 0.00 | 4 | 6 | right | `science_screen` |
| 1.00 | 0 | 0 | left | `player_trace` |
| 1.00 | 3 | 5 | right | `pick_up_cube` |
| 1.00 | 10 | 3 | spine | `dark_sphere` |
| 1.00 | 11 | 1 | left | `y_translation_cube` |
| 1.00 | 12 | 2 | spine_offset | `pick_up_cube` |
| 1.00 | 12 | 4 | spine_offset | `pick_up_cube` |
| 1.00 | 19 | 2 | spine_offset | `pick_up_cube` |
| 1.00 | 20 | 2 | spine_offset | `pick_up_cube` |
| 1.00 | 21 | 5 | right | `pickup_gate` |

## Pacing

- 11 artifacts along the walk
- median spacing between consecutive artifacts: t=0.00 (≈ 0 cells)
- tight rhythm — most rows have an artifact

## Notes

- Edit any value above. Lines that start with `**Field**:` are parsed by the generator.
- Artifact table positions can be given as `t=0.6 spine` or `row=12 col=5` — both work.
- Changing the archetype tag re-routes the placement engine to a different strategy.

---

```yaml
# Machine-readable section (the generator reads here first)
archetype: bridge
width: 7
depth: 24
spawn: [22, 6]
teleporter: [22, 5]
artifacts:
  - name: z_translation_cube
    row: 2
    col: 6
    t: 0.000
    lane: right
  - name: science_screen
    row: 4
    col: 6
    t: 0.000
    lane: right
  - name: player_trace
    row: 0
    col: 0
    t: 1.000
    lane: left
  - name: pick_up_cube
    row: 3
    col: 5
    t: 1.000
    lane: right
  - name: dark_sphere
    row: 10
    col: 3
    t: 1.000
    lane: spine
  - name: y_translation_cube
    row: 11
    col: 1
    t: 1.000
    lane: left
  - name: pick_up_cube
    row: 12
    col: 2
    t: 1.000
    lane: spine_offset
  - name: pick_up_cube
    row: 12
    col: 4
    t: 1.000
    lane: spine_offset
  - name: pick_up_cube
    row: 19
    col: 2
    t: 1.000
    lane: spine_offset
  - name: pick_up_cube
    row: 20
    col: 2
    t: 1.000
    lane: spine_offset
  - name: pickup_gate
    row: 21
    col: 5
    t: 1.000
    lane: right
```