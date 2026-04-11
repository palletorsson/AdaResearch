# WFC 3D

A procedural generation artifact that implements the Wave Function Collapse (WFC) algorithm in three dimensions to generate terrain with grass, dirt, stone, water, sand, and slopes. The solver uses socket-based adjacency constraints to ensure valid tile placement across a 3D grid.

## Concept Taught

**Wave Function Collapse and constraint propagation** -- how a grid of undecided cells can be iteratively resolved by collapsing the cell with the lowest entropy (fewest remaining options), then propagating the constraints to neighbors. This teaches constraint satisfaction, entropy-based selection, backtracking-free generation, and how local rules produce globally coherent structures. The 3D extension adds vertical adjacency (gravity, stacking) to the standard 2D algorithm.

## How It Works

### Tile Definitions (`wfc_3d_tiles.gd`)

An `@tool` EditorScript that generates a `prototypes_3d.tscn` scene containing tile prototypes. Each tile is a `Node3D` with two metadata fields:
- **sockets**: A dictionary mapping each face (`px`, `nx`, `py`, `ny`, `pz`, `nz`) to a socket label. Two tiles can be adjacent if their touching faces share the same socket label.
- **weight**: A float controlling how likely the tile is to be selected during collapse.

Tile types:
| Tile | Socket Faces | Weight | Description |
|------|-------------|--------|-------------|
| Air | all "rough" | 10.0 | Empty space |
| Air_Water | ny="water_top", rest "rough" | 10.0 | Air above water surface |
| Grass | all "rough" | 5.0 | Green ground block |
| Dirt | all "rough" | 2.0 | Brown earth block |
| Water | py="water_top", rest "rough" | 5.0 | Transparent blue water |
| Sand | all "rough" | 3.0 | Shore material |
| Stone | all "rough" | 4.0 | Gray cliff block |
| Grass_Cliff | all "rough" | 1.0 | Grass-covered cliff |
| Slope_N/S/E/W | all "rough" | 0.5 | Directional ramp prisms |

### Solver (`wfc_solver_3d.gd`)

1. **Initialization**: A 3D grid (default 20x10x20) is created. Every cell starts with all tile prototypes as possibilities.

2. **Base Terrain**: `FastNoiseLite` generates a 2D heightmap. The heightmap is smoothed so no two adjacent columns differ by more than 1 in height. Blocks are placed deterministically: water at height 0, sand near water, grass on plains, stone on peaks. Slopes are placed where adjacent columns differ by exactly 1 in height.

3. **Constraint Propagation**: Starting from pre-collapsed base terrain cells, `_propagate()` uses a stack-based algorithm. For each collapsed cell, it checks all 6 neighbors and removes any tile option whose socket does not match any of the current cell's possible sockets on the shared face. Changed neighbors are pushed onto the stack for further propagation.

4. **Collapse Loop**: The cell with minimum entropy (fewest remaining options, plus noise for randomness) is selected. A tile is chosen via weighted random selection. The cell is collapsed, its tile is spawned, and constraints propagate. This repeats until all cells are resolved or a contradiction occurs.

5. **Animated Mode**: When `animate_generation` is enabled, the solver performs `steps_per_frame` collapse steps per frame, allowing the generation to be visualized in real time.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `grid_size` | Vector3i | (20, 10, 20) | Dimensions of the 3D grid (X, Y, Z) |
| `tile_size` | float | 2.0 | World-space width/depth of each tile |
| `tile_height` | float | 1.0 | World-space height of each tile |
| `prototypes_path` | String | `res://.../prototypes_3d.tscn` | Path to the tile prototypes scene |
| `animate_generation` | bool | true | Visualize generation in real time |
| `steps_per_frame` | int | 5 | Collapse steps per frame when animating |

## Features

- Full 3D Wave Function Collapse with 6-direction socket matching
- Noise-based heightmap with automatic smoothing for walkability
- Weighted random tile selection during collapse
- Stack-based arc-consistency constraint propagation
- Animated real-time generation mode
- Biome-aware base terrain (water, sand, grass, stone, slopes)
- Directional slopes (N/S/E/W) placed at height transitions
- Water surface adapter tiles (Air_Water) for correct water-air boundaries
- CSG-based tile geometry with collision enabled
- Editor-time tile generation via `@tool` script

## Files

| File | Description |
|------|-------------|
| `wfc_3d_tiles.gd` | EditorScript that generates tile prototypes with socket metadata |
| `wfc_solver_3d.gd` | 3D WFC solver with heightmap seeding, propagation, and animated collapse |
