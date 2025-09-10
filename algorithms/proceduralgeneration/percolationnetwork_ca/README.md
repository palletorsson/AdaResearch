# Percolation Network CA with Collision Boxes

This implementation creates a 3D percolation network with individual collision boxes for each cube, creating pathways that can be navigated.

## Key Features

### ✅ **Smart Collision System**
- **White cubes**: Solid collision boxes for walls and barriers
- **Pink cubes**: Very transparent (20% opacity), non-colliding visual indicators
- Only occupied sites have collision - flowing/connected sites are visual only

### ✅ **No Gutter**
- Cubes are positioned with `CUBE_SIZE` spacing (no gaps)
- Cubes touch each other creating solid walls
- Clean, seamless appearance

### ✅ **Pathways Between Cubes**
- Lower percolation threshold (0.4 instead of 0.593)
- Creates more open spaces and pathways
- Allows navigation through the structure

### ✅ **Dynamic Visualization**
- Cubes are created/removed as percolation spreads
- Real-time material updates (white solid / pink transparent)
- Efficient collision management - only where needed

## How It Works

### Grid System
- **Grid Size**: 20×20×20 (configurable)
- **Cube Size**: 0.5 units (no gaps between cubes)
- **Percolation Threshold**: 0.4 (creates pathways)

### States
- **EMPTY (0)**: No cube, open space
- **OCCUPIED (1)**: White cube with collision (solid walls)
- **FLOWING (2)**: Pink very transparent cube (20% opacity, no collision)
- **CONNECTED (3)**: Pink very transparent cube (20% opacity, no collision)
- **SOURCE (4)**: Pink very transparent cube (20% opacity, no collision)

### Collision System
- **White cubes (OCCUPIED)**: `StaticBody3D` with `CollisionShape3D` for solid walls
- **Pink cubes (FLOWING/CONNECTED/SOURCE)**: `Node3D` with `MeshInstance3D` only (no collision)
- Individual material assignment with transparency
- Unique naming: `Cube_x_y_z`

## Usage

### Basic Usage
1. Open `percolationnetwork_ca.tscn`
2. Run the scene
3. Watch the percolation simulation create pathways

### Testing Collisions
1. Open `test_collision.tscn`
2. Run the scene
3. Use the player capsule to test collision with cubes

### Integration
```gdscript
# Get cube information
var cube = percolation_network.get_cube_at_position(world_position)

# Get collision body (only for white cubes)
var collision_body = percolation_network.get_collision_body_at_position(world_position)

# Get statistics
var stats = percolation_network.get_percolation_stats()
print("Total cubes: ", stats.total_cubes)
print("Colliding cubes: ", stats.colliding_cubes)
print("Pink cubes: ", stats.pink_cubes)
```

## Customization

### Adjusting Pathways
```gdscript
const PERCOLATION_THRESHOLD = 0.4  # Lower = more pathways
```

### Changing Cube Size
```gdscript
const CUBE_SIZE = 0.5  # Larger = bigger cubes, same spacing
```

### Grid Size
```gdscript
const GRID_SIZE = 20  # 20×20×20 grid
```

## Performance Notes

- **Collision Boxes**: Each cube has individual collision
- **Dynamic Updates**: Cubes are created/removed as needed
- **Memory**: More memory usage than single mesh approach
- **Physics**: Full physics interaction support

## Debug Information

The system provides several debug methods:
- `get_percolation_stats()` - Overall statistics including cube counts
- `count_total_cubes()` - Number of all active cubes
- `count_colliding_cubes()` - Number of white cubes with collision
- `get_cube_at_position(world_pos)` - Get cube node at world position
- `get_collision_body_at_position(world_pos)` - Get collision body (white cubes only)
- `world_to_grid_position(world_pos)` - Convert world to grid coordinates

## Example Output

```
Starting percolation simulation...
Grid size: 20³
Occupied sites: 3200
PERCOLATION ACHIEVED! Flow connected from top to bottom.
Iterations required: 45
Connected sites: 1250
Total cubes: 4500
Colliding cubes: 3200
Pink cubes: 1300
```

## Technical Details

### Smart Collision System
```gdscript
func create_single_cube_collision(x: int, y: int, z: int, state: CellState):
    var cube_node = Node3D.new()
    
    # Only add collision for white cubes (occupied state)
    if state == CellState.OCCUPIED:
        var static_body = StaticBody3D.new()
        var collision_shape = CollisionShape3D.new()
        var box_shape = BoxShape3D.new()
        box_shape.size = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)
        # ... collision setup
    
    # All cubes get visual mesh
    var mesh_instance = MeshInstance3D.new()
    # ... mesh setup with appropriate material
```

### Dynamic Updates
- Cubes are created when cells become occupied
- Cubes are removed when cells become empty
- Materials are updated based on flow state
- Collision shapes are added/removed based on state changes
- Pink cubes are purely visual indicators

This implementation provides a solid foundation for 3D navigation systems, physics simulations, and interactive percolation networks with smart collision management.
