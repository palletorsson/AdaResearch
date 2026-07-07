# Map prompt: Point_Triangle

*Auto-generated from `commons/maps/Point_Triangle/map_data.json`. Edit any line; re-generate via `tools/generate_from_prompt.py`.*

**Archetype**: `irregular`  *(promenade · pit · ziggurat · dungeon · cathedral · amphitheater · spiral · hub_spokes · atrium · crossroads · forum · bridge · tower · maze · stacks · cave · theater · quadrants · citadel · constellation · irregular)*
**Dimensions**: 7 wide × 9 deep × 3 tall
**Aspect ratio**: 1.29  *(>2 = corridor, ~1 = room)*
**Spawn**: row 0, col 0
**Teleporter**: row 7, col 3
**Structure**: void 17% · floor 19%

## Artifacts

| t | row | col | lane | name |
|---|---|---|---|---|
| 0.00 | 0 | 0 | left | `dark_sphere` |
| 0.52 | 3 | 3 | spine | `triangle_line_puzzle` |
| 0.74 | 4 | 5 | right | `parasol_triangle` |
| 0.76 | 5 | 3 | spine | `cube_scene` |
| 0.88 | 6 | 3 | spine | `triangle` |
| 1.00 | 7 | 3 | spine | `triangleprofiles` |
| 1.00 | 7 | 5 | right | `science_screen` |

## Pacing

- 7 artifacts along the walk
- median spacing between consecutive artifacts: t=0.12 (≈ 1 cells)
- Mario-like pacing — encounter every few cells

## Notes

- Edit any value above. Lines that start with `**Field**:` are parsed by the generator.
- Artifact table positions can be given as `t=0.6 spine` or `row=12 col=5` — both work.
- Changing the archetype tag re-routes the placement engine to a different strategy.

---

```yaml
# Machine-readable section (the generator reads here first)
archetype: irregular
width: 7
depth: 9
spawn: [0, 0]
teleporter: [7, 3]
artifacts:
  - name: dark_sphere
    row: 0
    col: 0
    t: 0.000
    lane: left
  - name: triangle_line_puzzle
    row: 3
    col: 3
    t: 0.517
    lane: spine
  - name: parasol_triangle
    row: 4
    col: 5
    t: 0.741
    lane: right
  - name: cube_scene
    row: 5
    col: 3
    t: 0.759
    lane: spine
  - name: triangle
    row: 6
    col: 3
    t: 0.879
    lane: spine
  - name: triangleprofiles
    row: 7
    col: 3
    t: 1.000
    lane: spine
  - name: science_screen
    row: 7
    col: 5
    t: 1.000
    lane: right
```