# Room Grammar

A procedural floor plan generator using Binary Space Partitioning (BSP) to recursively subdivide a rectangle into rooms. Teaches shape grammars and algorithmic architectural layout generation.

## How It Works

Starting from a root rectangle, the algorithm recursively splits it into two sub-rectangles at each level. The split direction favors the longer axis for more natural proportions, with random choice for nearly square regions. Splitting continues until the configured depth is reached or the resulting rooms would be too small. After partitioning, rooms are filled with colors proportional to their area, wall outlines are drawn, and door gaps are carved between adjacent rooms by detecting shared wall segments. The final image is rendered as a texture on a floor-facing quad.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `quad_size` | Vector2 | `Vector2(0.8, 0.8)` |
| `seed_value` | int | `73` |
| `split_depth` | int | `5` |
| `min_room_size` | int | `12` |

## Features

- Recursive BSP partitioning with configurable depth and minimum room size
- Automatic door placement between adjacent rooms via shared-wall detection
- Area-proportional room coloring (larger rooms lighter, smaller rooms darker)
- Seeded random number generator for reproducible layouts
- Procedural 128x128 pixel image rendered to a floor quad
- Configurable via `apply_grid_config` (seed, split depth, min room size)

## Files

- `room_grammar.gd` -- Main script
- `room_grammar.tscn` -- Scene file
