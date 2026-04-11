# WFC 3D Generator

A 3D implementation of the Wave Function Collapse (WFC) algorithm for procedural dungeon and space generation. This artifact teaches how WFC works -- starting from maximum uncertainty (all tiles possible everywhere) and iteratively collapsing cells to definite states while propagating adjacency constraints, producing complex, globally-consistent structures from purely local rules.

## How It Works

The project contains two implementations:

### SimpleWFC3DGenerator

A straightforward WFC with 5 tile types (Empty, Floor, Wall, Door, Pillar):

1. **Grid initialization**: A 3D grid of cells is created, each starting with all tile types as possibilities.
2. **Boundary constraints**: Ground level is restricted to Floor/Wall/Pillar; top level to Empty/Pillar; outer edges to Wall/Door.
3. **Entropy collapse**: The cell with the fewest remaining possibilities (lowest entropy) is chosen. Among ties, one is picked randomly.
4. **Weighted selection**: Each tile type has a weight (Floor=3.0, Wall=2.5, etc.) that biases the random choice.
5. **Constraint propagation**: After collapsing a cell, its neighbors' possibilities are filtered by adjacency rules. For example, a Floor tile's North neighbor must be Floor, Wall, Door, or Pillar.
6. **Post-processing**: If fewer than 3 doors exist, some walls adjacent to floor areas are converted to doors for connectivity.

### AdvancedWFCGenerator (WFC3DGenerator.gd)

A socket-based WFC with richer tile types:

1. **Socket system**: Each tile face has a socket type (FLOOR_OPEN, WALL_SOLID, DOOR_FRAME, etc.). Two tiles can be neighbors only if their facing sockets are compatible.
2. **Rotation support**: Tiles marked `can_rotate` are randomly rotated in 90-degree increments. Socket lookup accounts for rotation.
3. **Themed tiles**: Includes standard architectural tiles plus themed tiles (Rainbow Dance Floor, Pride Flag Wall, Community Circle, Glitter Fountain, Love Archway, Safe Space).
4. **Fallback handling**: If constraint propagation eliminates all possibilities for a cell, it falls back to the Empty tile.
5. **Mesh generation**: Each collapsed tile gets a mesh -- BoxMesh for floors/walls, CylinderMesh for fountains/circles, with collision shapes for walkable surfaces.

Both implementations use the core WFC loop: find lowest entropy, collapse, propagate, repeat.

## Parameters

### SimpleWFC3DGenerator

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `width` | int | 10 | Grid width |
| `height` | int | 6 | Grid height (vertical layers) |
| `depth` | int | 10 | Grid depth |
| `cell_size` | float | 4.0 | World-space size of each cell |

### AdvancedWFCGenerator

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `grid_dimensions` | Vector3i | (8,2,8) | 3D grid dimensions |
| `tile_size` | float | 4.0 | World-space size of each tile |
| `generate` | bool | false | Trigger generation (tool script) |
| `clear_all` | bool | false | Trigger clearing |
| `seed_value` | int | 0 | Random seed (0 = random) |
| `room_density` | float | 0.3 | Density hint for room placement |
| `corridor_density` | float | 0.4 | Density hint for corridor placement |

## Features

- **Wave Function Collapse** -- the core algorithm: entropy-based cell selection, weighted collapse, constraint propagation
- **Socket-based adjacency** -- typed socket connections (FLOOR_OPEN, WALL_SOLID, etc.) for precise tile compatibility
- **Rotation-aware constraints** -- horizontal socket lookup rotated to match tile orientation
- **Tool script support** -- AdvancedWFCGenerator runs in the Godot editor via `@tool` for design-time previewing
- **Collision generation** -- walkable tile types get `StaticBody3D` collision shapes
- **Boundary constraints** -- ground floors, top ceilings, and outer walls are pre-constrained for structural coherence
- **Post-processing** -- door insertion ensures room connectivity when WFC under-generates doors
- **Progress logging** -- percentage-based progress output during generation

## Files

- `WFC3DGenerator.gd` -- Advanced socket-based WFC with themed tiles, rotation support, tool script mode
- `SimpleWFC3DGenerator.gd` -- Simplified rule-based WFC with 5 tile types, boundary constraints, post-processing
- `WFC3DGenerator.tscn` -- Scene file
