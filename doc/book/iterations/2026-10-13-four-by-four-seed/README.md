# Four by four, with room to read

13 October 2026. Random Definition's installed Seed Replay starts with two 4 × 4 grids. The wall panels keep their 1.225m width and height, so the cells are larger. MATRIX still selects 2 × 2 through 16 × 16; a saved visit keeps the visitor's chosen size.

The map token and museum plan specify `side:4`. Other placements keep their existing defaults. The printed lesson and its support file now start at four too. Sixteen cells take 48 RGB draws; discarding one first takes 49. The reflective text's count agrees.

The current illustrated reading and PDF use the new grid photographs. The earlier eight-by-eight reports and captures remain historical records.

## Validation

- Native museum: 20/20 checks, including installed defaults, the two actual meshes, independent RGB grouping, replay, physical slider movement, saved state and retained panel footprint.
- Printed code extracted from tutorial.md: 36 checks; grayscale and swapped-channel variations: 37 each.
- Both deliberate faults rejected: resetting inside the cell loop, and discarding after assignment.
- These are runtime checks, not a physical headset or independent learner study.

```powershell
python tools/run_encounter_probe.py Random_Definition --sequence randomness --render --no-bridges --probe doc/book/iterations/2026-10-13-four-by-four-seed/museum_probe.gd --output-tag four-by-four-20261013
python tools/test_random_definition_lesson.py --output doc/book/iterations/2026-10-13-four-by-four-seed/student
```

[Illustrated reading](../2026-10-13-random-definition-in-the-museum/index.html) · [Writing-system blog](http://localhost:3003/blog/2026-10-13-a-room-of-connections-a-line-of-text)
