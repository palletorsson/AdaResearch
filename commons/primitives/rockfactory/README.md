# RockFactory - Procedural Irregular Form Generator

## Overview

RockFactory generates collections of procedural rocks with realistic physics to demonstrate packing inefficiency, gaps, and the behavior of irregular forms in constrained spaces.

## Purpose

Traditional primitives (cubes, spheres) have perfect symmetry and predictable packing. RockFactory creates **irreducible variation** — each rock is unique, demonstrating:

- **Sphere packing problem** - Even optimal sphere packing leaves ~26% gaps
- **Natural settling** - How irregular objects find equilibrium under gravity
- **Remainder spaces** - Gaps that resist optimization
- **Procedural variation** - Algorithmic generation of difference

## Features

### 5 Spawn Modes
- **BOX** - Random positions within rectangular volume
- **PILE** - Heap on ground surface
- **GRID** - Regular grid with slight randomness
- **RING** - Circular arrangement
- **CLUSTER** - Tight cluster at center

### Physics Options
- **Static** - Fixed in place (default)
- **Dynamic** - Falls under gravity, settles naturally
- Configurable mass, friction, and bounce

### Visual Customization
- Size variation range
- Shape deformation amount
- Surface roughness
- Color schemes (grayscale, pride colors, custom)
- Mesh detail level (subdivisions)

## Usage in Maps

### Basic (Static Rocks)
```json
"rockfactory"
```

### With Gravity
```json
"rockfactory_gravity:0:3.5"
```
- Spawns at height 3.5
- Rocks fall and settle

### Custom Configuration
```json
"rockfactory#number_of_rocks:50#use_pride_colors:true#spawn_mode:3"
```

## GDScript API

### Basic Setup
```gdscript
var factory = RockFactory.new()
add_child(factory)
factory.number_of_rocks = 30
factory.enable_gravity = true
factory.generate_rocks()
```

### Runtime Control
```gdscript
# Change spawn pattern
factory.set_spawn_mode(RockFactory.SpawnMode.PILE)

# Adjust count
factory.set_rock_count(50)

# Toggle colors
factory.set_color_scheme(true)  # Enable pride colors

# Regenerate with new settings
factory.regenerate()

# Clean up
factory.clear_rocks()
```

### Gap Analysis
```gdscript
var analysis = factory.get_gap_analysis()
print("Packing efficiency: %.1f%%" % analysis.packing_efficiency)
print("Gap volume: %.2f cubic units" % analysis.gap_volume)
```

## Parameters

### Generation
- `number_of_rocks` (int, default: 20) - How many rocks to generate
- `generation_seed` (int, default: 0) - Random seed (0 = random)
- `auto_generate` (bool, default: true) - Generate on ready

### Spawn Area
- `spawn_mode` (SpawnMode, default: BOX)
- `spawn_area` (Vector3, default: Vector3(2, 1, 2)) - Volume dimensions
- `container_height` (float, default: 0.5) - Starting Y position

### Rock Properties
- `rock_size_min` (float, default: 0.15) - Minimum base radius
- `rock_size_max` (float, default: 0.35) - Maximum base radius
- `deformation_min` (float, default: 3.0) - Min shape deformation
- `deformation_max` (float, default: 7.0) - Max shape deformation
- `roughness_min` (float, default: 2.0) - Min surface roughness
- `roughness_max` (float, default: 4.0) - Max surface roughness
- `subdivisions` (int, default: 2) - Mesh detail (0-4)

### Visual Style
- `base_color` (Color, default: gray) - Base rock color
- `color_variation` (float, default: 0.1) - Color randomness
- `use_pride_colors` (bool, default: false) - Rainbow colors

### Physics
- `create_collisions` (bool, default: true) - Add collision shapes
- `make_rocks_static` (bool, default: true) - Static vs dynamic
- `enable_gravity` (bool, default: false) - Apply gravity
- `rock_mass` (float, default: 1.0) - Mass for dynamic rocks
- `rock_friction` (float, default: 0.8) - Surface friction
- `rock_bounce` (float, default: 0.1) - Bounciness (0-1)

## Implementation Notes

### Rock Generation Process
1. Load ProceduralRock scene template
2. For each rock:
   - Set unique random seed
   - Randomize size, deformation, roughness
   - Assign color (solid or pride)
   - Calculate spawn position based on mode
   - Generate mesh via ProceduralRock
   - Create collision shape
   - If gravity: convert to RigidBody3D

### Physics Conversion
Static rocks use `StaticBody3D` with collision shapes.
Dynamic rocks replace StaticBody3D with `RigidBody3D`:
```gdscript
# Wait for rock mesh generation
await get_tree().process_frame

# Move collision shape from StaticBody to RigidBody
var rigid_body = RigidBody3D.new()
rigid_body.mass = rock_mass
rigid_body.physics_material_override = PhysicsMaterial.new()
rigid_body.physics_material_override.friction = rock_friction
# ... transfer collision shape
```

### Performance
- Each rock generates unique mesh (CPU cost at spawn)
- 20-40 rocks: Good for VR
- 100+ rocks: Consider lower subdivision levels
- Dynamic physics: Godot handles 30-50 rocks easily

## Pedagogical Applications

### Primitives Sequence
- Demonstrates **irregular forms** vs regular primitives
- Shows **packing inefficiency** visually
- Embodies **remainder** as unavoidable property

### Randomness Sequence
- Procedural generation from noise
- Unique instances from shared algorithm
- Deterministic randomness (seeded)

### Physics Sequence
- Gravity and settling dynamics
- Collision response with irregular shapes
- Natural equilibrium states

## Mathematical Context

### Sphere Packing
- Random sphere packing: ~64% density
- Optimal sphere packing (Kepler): ~74% density
- Irregular rocks: typically 50-65% density

The **gap percentage** from `get_gap_analysis()` demonstrates this mathematically.

### Procedural Noise
Each rock uses:
- **FastNoiseLite** (Simplex noise)
- Applied as radial deformation to icosphere
- Result: organic, irregular surface

## Queer Theory Connection

RockFactory generates **irreducible difference**. Unlike industrial manufacturing (minimize variation, maximize interchangeability), this system **celebrates deviation**.

Each rock:
- Has unique shape (won't stack uniformly)
- Creates unique gaps (resists grid logic)
- Refuses standardization (no two identical)

The **gap** is not error — it's the **signature of individuality**.

## Files

- `RockFactory.gd` - Main factory script
- `RockFactory.tscn` - Static rocks variant
- `RockFactoryGravity.tscn` - Pre-configured with gravity
- `README.md` - This documentation

## Dependencies

- [ProceduralRock](../proceduralrock/) - Individual rock generator
- Godot Physics Engine - For dynamic rocks
- FastNoiseLite - For shape deformation

## Example Maps

- [Primitives_Irregular](../../maps/Primitives_Irregular/) - Rocks filling container
- Demonstrates gaps, packing, and natural settling

## See Also

- [proceduralrock](../proceduralrock/) - Single rock primitive
- [roughrock](../roughrock/) - Alternative irregular polyhedron
- [CubeSpawner](../cubes/CubeSpawner.gd) - Similar factory pattern for cubes
