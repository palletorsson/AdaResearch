# Cave Generator

A 3D cellular automaton cave generator that uses iterative neighbor-counting rules to sculpt organic cave structures from a randomly seeded voxel grid. This artifact teaches the classic cellular automata approach to procedural terrain -- how local neighbor rules applied repeatedly can transform random noise into coherent, natural-looking cave systems.

## How It Works

1. A 3D grid of cells (default 40x40x40) is initialized with each cell randomly set to solid (1) or empty (0) based on `initial_fill_percentage`.
2. The simulation runs for a fixed number of `generations`. Each generation applies rules based on the **Moore neighborhood** (26 neighbors in 3D):
   - A **solid** cell stays solid if it has 4 or more solid neighbors; otherwise it becomes empty.
   - An **empty** cell becomes solid if it has 5 or more solid neighbors; otherwise it stays empty.
3. After all generations complete, surviving solid cells are rendered using a `MultiMeshInstance3D` with unit-sized box meshes placed at each occupied grid coordinate.

The birth/survival thresholds (B5/S4 in CA notation) produce smooth, rounded cavern shapes with natural-looking walls and openings.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `grid_size` | int | 40 | Number of cells along each axis (total cells = grid_size^3) |
| `initial_fill_percentage` | float | 0.45 | Probability each cell starts as solid |
| `generations` | int | 5 | Number of cellular automaton iterations |

## Features

- **Classic 3D cellular automata** -- demonstrates how simple local rules produce emergent macro-scale structure
- **MultiMesh rendering** -- all solid voxels rendered in a single draw call via MultiMeshInstance3D for efficient display
- **Tunable density** -- adjusting `initial_fill_percentage` controls cave openness, from sparse tunnels to dense rock with small pockets
- **Generation count control** -- more generations produce smoother, more rounded caves; fewer generations leave rougher, more chaotic terrain

## Files

- `CaveGenerator.gd` -- Core cellular automaton: grid initialization, neighbor counting, rule application, MultiMesh output
- `CaveGenerator.tscn` -- Scene file with MultiMeshInstance3D child node
