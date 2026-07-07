# Map prompt: Random_Definition

*Auto-generated from `commons/maps/Random_Definition/map_data.json`. Edit any line; re-generate via `tools/generate_from_prompt.py`.*

**Archetype**: `promenade`  *(promenade · pit · ziggurat · dungeon · cathedral · amphitheater · spiral · hub_spokes · atrium · crossroads · forum · bridge · tower · maze · stacks · cave · theater · quadrants · citadel · constellation · irregular)*
**Dimensions**: 5 wide × 30 deep × 3 tall
**Aspect ratio**: 6.00  *(>2 = corridor, ~1 = room)*
**Spawn**: row 0, col 0
**Teleporter**: row 16, col 2
**Structure**: floor 8%

## Artifacts

| t | row | col | lane | name |
|---|---|---|---|---|
| 0.12 | 2 | 0 | left | `slot_machine` |
| 0.15 | 2 | 4 | right | `prng_crank_machine` |
| 0.32 | 5 | 2 | spine | `entropy_axiom` |
| 0.52 | 8 | 4 | right | `science_screen` |
| 0.57 | 9 | 2 | spine | `entropy_jar` |
| 0.63 | 10 | 2 | spine | `random_butterflies` |
| 0.69 | 11 | 2 | spine | `seed_replay_demo` |
| 0.75 | 12 | 2 | spine | `dark_sphere` |
| 0.83 | 13 | 4 | right | `clipboard` |
| 0.92 | 15 | 0 | left | `digital_materiality_glitch` |
| 0.95 | 15 | 4 | right | `trng_vs_prng` |
| 1.00 | 19 | 2 | spine | `random_number_book_page_1955` |

## Pacing

- 12 artifacts along the walk
- median spacing between consecutive artifacts: t=0.06 (≈ 1 cells)
- tight rhythm — most rows have an artifact

## Notes

- Edit any value above. Lines that start with `**Field**:` are parsed by the generator.
- Artifact table positions can be given as `t=0.6 spine` or `row=12 col=5` — both work.
- Changing the archetype tag re-routes the placement engine to a different strategy.

---

```yaml
# Machine-readable section (the generator reads here first)
archetype: promenade
width: 5
depth: 30
spawn: [0, 0]
teleporter: [16, 2]
structure: |
  11111
  11111
  11111
  11111
  11111
  11111
  11111
  11111
  11111
  11111
  11111
  11111
  11111
  11112
  21112
  21112
  21012
  21111
  11111
  11111
utilities:
  - row: 0
    col: 4
    token: "an:-90"
  - row: 19
    col: 0
    token: "sr:18:19:10"
artifacts:
  - name: slot_machine
    row: 2
    col: 0
    t: 0.123
    lane: left
  - name: prng_crank_machine
    row: 2
    col: 4
    t: 0.154
    lane: right
  - name: entropy_axiom
    row: 5
    col: 2
    t: 0.323
    lane: spine
  - name: science_screen
    row: 8
    col: 4
    t: 0.523
    lane: right
  - name: entropy_jar
    row: 9
    col: 2
    t: 0.569
    lane: spine
  - name: random_butterflies
    row: 10
    col: 2
    t: 0.631
    lane: spine
  - name: seed_replay_demo
    row: 11
    col: 2
    t: 0.692
    lane: spine
  - name: dark_sphere
    row: 12
    col: 2
    t: 0.754
    lane: spine
  - name: clipboard
    row: 13
    col: 4
    t: 0.831
    lane: right
  - name: digital_materiality_glitch
    row: 15
    col: 0
    t: 0.923
    lane: left
  - name: trng_vs_prng
    row: 15
    col: 4
    t: 0.954
    lane: right
  - name: random_number_book_page_1955
    row: 19
    col: 2
    t: 1.000
    lane: spine
```