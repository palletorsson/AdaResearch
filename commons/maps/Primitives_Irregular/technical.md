# Primitives_Irregular: Technical Implementation

## RockFactory System

### Basic Usage
```gdscript
# Instantiate the RockFactory
var rock_factory = preload("res://commons/primitives/rockfactory/RockFactory.tscn").instantiate()
add_child(rock_factory)

# Configure parameters
rock_factory.number_of_rocks = 30
rock_factory.enable_gravity = true
rock_factory.spawn_mode = RockFactory.SpawnMode.BOX
rock_factory.spawn_area = Vector3(3, 2, 3)
rock_factory.container_height = 3.5  # Spawn above container

# Generate rocks
rock_factory.generate_rocks()
```

### Spawn Modes
```gdscript
enum SpawnMode {
    BOX,        # Random positions in rectangular volume
    PILE,       # Heap on ground surface
    GRID,       # Regular grid with randomness
    RING,       # Circular arrangement
    CLUSTER     # Tight cluster at center
}
```

### Physics Configuration
```gdscript
# Enable gravity and dynamic physics
rock_factory.enable_gravity = true
rock_factory.make_rocks_static = false

# Configure physical properties
rock_factory.rock_mass = 0.8        # Lower = lighter rocks
rock_factory.rock_friction = 0.8    # Higher = less sliding
rock_factory.rock_bounce = 0.05     # Lower = less bouncy (0-1)
```

### Rock Generation Parameters
```gdscript
# Size variation
rock_factory.rock_size_min = 0.12
rock_factory.rock_size_max = 0.25

# Shape complexity
rock_factory.deformation_min = 3.5   # How much noise deformation
rock_factory.deformation_max = 6.5
rock_factory.roughness_min = 2.0     # Surface detail level
rock_factory.roughness_max = 3.5
rock_factory.subdivisions = 1        # Mesh detail (0-4)
```

### Visual Styling
```gdscript
# Uniform color with variation
rock_factory.base_color = Color(0.6, 0.6, 0.65)
rock_factory.color_variation = 0.15

# Or use pride colors
rock_factory.use_pride_colors = true  # Rainbow rocks!
```

## Packing Analysis

The RockFactory includes a gap analysis function:

```gdscript
var analysis = rock_factory.get_gap_analysis()
print("Total volume: ", analysis.total_volume)
print("Rock volume: ", analysis.rock_volume)
print("Gap volume: ", analysis.gap_volume)
print("Packing efficiency: ", analysis.packing_efficiency, "%")
print("Gaps percentage: ", analysis.gaps_percentage, "%")
```

### Theoretical Packing Limits

- **Cubes (regular grid)**: 100% packing efficiency (no gaps)
- **Spheres (random packing)**: ~64% packing efficiency
- **Spheres (optimal packing)**: ~74% (Kepler conjecture, proved 1998)
- **Irregular rocks**: Typically 50-65% depending on shape variation

## Container Structure in Grid

The container is defined in the structure layer:

```json
"structure": [
    ["1", "1", "3", "3", "3", "3", "3", "1", "1"],  // Row 3: Top wall
    ["1", "1", "3", "1", "1", "1", "3", "1", "1"],  // Row 4: Side walls
    ["1", "1", "3", "1", "1", "1", "3", "1", "1"],  // Row 5: Side walls
    ["1", "1", "3", "1", "1", "1", "3", "1", "1"],  // Row 6: Side walls
    ["1", "1", "3", "3", "1", "3", "3", "1", "1"]   // Row 7: Bottom (gap at col 4)
]
```

- `"1"` = single cube (height 1)
- `"3"` = stacked cubes (height 3)
- Container interior: columns 3-5, rows 4-6
- Interior volume: 3×3×2 = 18 cubic units

## Physics Considerations

### RigidBody3D Conversion
The RockFactory converts static collision shapes to dynamic RigidBodies:

```gdscript
# Wait for rock generation
await get_tree().process_frame

# Find static body
var static_body = rock.find_child("ProceduralRockCollision", true, false)

# Create rigid body with physics material
var rigid_body = RigidBody3D.new()
rigid_body.mass = rock_mass
rigid_body.physics_material_override = PhysicsMaterial.new()
rigid_body.physics_material_override.friction = rock_friction
rigid_body.physics_material_override.bounce = rock_bounce

# Move collision shape
var collision_shape = static_body.get_child(0)
static_body.remove_child(collision_shape)
rigid_body.add_child(collision_shape)
```

### Performance Notes
- Each rock generates a unique mesh (CPU cost at spawn time)
- Physics simulation runs per-frame (30 rocks = manageable)
- For 100+ rocks, consider using simplified collision shapes
- Subdivision level 1-2 recommended for VR performance

## Map Configuration String

In map_data.json:
```json
"rockfactory_gravity:0:3.5"
```

Where:
- `rockfactory_gravity` = artifact name
- `0` = rotation (degrees)
- `3.5` = y-offset (height above grid floor)

Or with full configuration:
```json
"rockfactory#enable_gravity:true#number_of_rocks:40#spawn_mode:0"
```
