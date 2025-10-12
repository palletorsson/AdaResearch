# Wave Function Collapse (WFC) for Godot 3D

A complete implementation of the Wave Function Collapse algorithm for procedural 3D level generation in Godot.

## Overview

Wave Function Collapse is a constraint-based procedural generation algorithm that creates complex, interconnected patterns by:
1. Starting with all possible tiles at each position
2. Iteratively selecting positions with the least possibilities (lowest entropy)
3. Collapsing them to a single tile choice
4. Propagating constraints to neighbors
5. Repeating until complete

## Files

- **wfc_tile.gd** - Tile definition with adjacency rules
- **wfc_solver.gd** - Core WFC algorithm implementation
- **wfc_tile_3d.gd** - 3D visual representation of tiles
- **wfc_grid_3d.gd** - Grid manager that orchestrates generation
- **wfc_test.tscn** - Basic test scene with default tileset
- **example_custom_tileset.gd** - Advanced example with corridor generation

## Quick Start

1. Open `wfc_test.tscn` in Godot
2. Press F5 to run
3. Press SPACE to generate a grid
4. Use arrow keys to rotate camera

### Controls

- **SPACE** - Generate new grid
- **R** - Regenerate
- **A** - Toggle animation
- **Arrow Keys** - Rotate/zoom camera

## Creating Custom Tilesets

### Basic Tile Setup

```gdscript
# Create a new tile type
var my_tile = WFCTile.new("my_tile", 1.0)  # id, weight
my_tile.color = Color(1, 0, 0)  # red

# Define which tiles can be neighbors
my_tile.set_compatible(Vector3.RIGHT, ["my_tile", "other_tile"])
my_tile.set_compatible(Vector3.LEFT, ["my_tile", "other_tile"])
# ... set for all 6 directions

# Add to grid
wfc_grid.add_tile_type(my_tile)
```

### Directions

The 6 directions for adjacency rules:
- `Vector3.RIGHT` - +X direction
- `Vector3.LEFT` - -X direction
- `Vector3.UP` - +Y direction
- `Vector3.DOWN` - -Y direction
- `Vector3(0, 0, 1)` - +Z direction (forward)
- `Vector3(0, 0, -1)` - -Z direction (back)

### Tile Properties

- **tile_id** - Unique identifier
- **weight** - Probability weight (higher = more likely)
- **color** - Display color
- **mesh_scene** - Optional custom mesh scene path
- **compatible_neighbors** - Adjacency rules for each direction

## Examples

### Simple Ground/Wall Tileset

See `wfc_grid_3d.gd::setup_default_tiles()` for a basic 3-tile system:
- Empty (air)
- Ground (floor)
- Wall (obstacles)

### Corridor Generation

See `example_custom_tileset.gd` for a more complex tileset with:
- Straight corridors (X and Z directions)
- Corner pieces (4 variations)
- Junctions (4-way intersections)
- Walls and empty spaces

## Parameters

### WFCGrid3D Exports

- **grid_width/height/depth** - Grid dimensions
- **tile_size** - Size of each tile in world units
- **auto_generate** - Generate on ready
- **generation_seed** - Random seed (0 = random)
- **animate_generation** - Show tiles appearing one by one
- **animation_speed** - Delay between tiles when animating

## Algorithm Details

### Wave Function Collapse Process

1. **Initialization** - Every grid position starts with all possible tiles
2. **Observation** - Find position with lowest entropy (fewest possibilities)
3. **Collapse** - Select one tile randomly (weighted by tile.weight)
4. **Propagation** - Update neighbor possibilities based on adjacency rules
5. **Repeat** - Continue until all positions collapsed or contradiction occurs

### Contradiction Handling

If no valid tile can be placed (contradiction), the algorithm:
- Prints a warning
- Restarts from scratch
- Tries again (up to a maximum iteration limit)

## Advanced Usage

### Custom Mesh Tiles

```gdscript
var tile = WFCTile.new("fancy_tile", 1.0)
tile.mesh_scene = "res://models/my_tile.tscn"
tile.set_compatible(...)
wfc_grid.add_tile_type(tile)
```

### Connecting to Signals

```gdscript
wfc_grid.connect("generation_started", self, "_on_generation_started")
wfc_grid.connect("generation_complete", self, "_on_generation_complete")
wfc_grid.connect("tile_placed", self, "_on_tile_placed")
```

### Accessing Generated Tiles

```gdscript
# Get tile at position
var tile_node = wfc_grid.get_tile_at(Vector3(5, 0, 5))

# Get all collapsed tiles
var collapsed_grid = wfc_grid.solver.get_collapsed_grid()
for pos in collapsed_grid:
    print("Position: ", pos, " -> Tile: ", collapsed_grid[pos])
```

## Tips for Good Tilesets

1. **Symmetry** - Make sure adjacency rules are symmetric (if A can be next to B, B should allow A)
2. **Weights** - Use higher weights for common tiles, lower for special features
3. **Escape Tiles** - Include tiles that are compatible with everything (like "empty") to prevent contradictions
4. **Test Small** - Start with small grids (5x1x5) to test tileset rules
5. **Visualize** - Use different colors to easily distinguish tile types

## Performance Notes

- Generation time grows with grid size (O(n³) where n is average dimension)
- More tile types = more constraint checking
- Animation slows generation but helps debugging
- Contradictions cause restarts (can be slow on large grids)

## Troubleshooting

**Generation fails/hangs:**
- Check adjacency rules are symmetric
- Add more "flexible" tiles that connect to many types
- Reduce grid size for testing
- Check for isolated tile types with no valid neighbors

**Unexpected patterns:**
- Review tile weights (high weights dominate)
- Check all 6 directions are set for each tile
- Verify bidirectional compatibility

**Performance issues:**
- Reduce grid size
- Simplify tileset
- Disable animation
- Use fewer tile types

## References

- Based on the WFC algorithm from [Brackey's Rogue-like Tutorial](http://bfnightly.bracketproductions.com/rustbook/chapter_33.html)
- Original WFC by Maxim Gumin: https://github.com/mxgmn/WaveFunctionCollapse
