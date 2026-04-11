# WFC Tile Mosaic

Generates a floor mosaic using Wave Function Collapse, a constraint-satisfaction algorithm that produces globally coherent tile patterns from local adjacency rules. Teaches how constraint propagation and backtracking can generate complex, non-repetitive arrangements from simple rules.

## How It Works

The grid starts with every cell in superposition -- holding all six possible tile types (Ground, Water, Sand, Grass, Stone, Path). The solver repeatedly selects the cell with the lowest entropy (fewest remaining options), collapses it to a random valid tile, then propagates adjacency constraints to neighboring cells, removing incompatible options. If a contradiction occurs (a cell with zero possibilities), the solver backtracks by restoring a previous state and excluding the failed choice. The final collapsed grid is rendered to an Image texture with 2x2 micro-patterns per tile for visual detail, then applied to a floor-facing QuadMesh.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `mosaic_world_size` | Vector2 | (0.8, 0.8) |
| `grid_size` | int | 16 |
| `pixel_scale` | int | 4 |

## Features

- Full WFC solver with constraint propagation and backtracking
- Six tile types with defined adjacency rules (e.g., Water can only neighbor Water or Sand)
- 2x2 pixel micro-patterns per tile for subtle visual variation
- Deterministic seeding based on world position and instance ID
- Automatic fallback to a checkerboard pattern if solving fails after 10 attempts
- Subtle grid lines between tiles for readability
- Nearest-neighbor texture filtering for a crisp pixel-art look

## Files

- `wfc_tile_mosaic.gd` -- Main script
- `wfc_tile_mosaic.tscn` -- Scene file
