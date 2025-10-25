# Crystal Random Walk

A procedural crystal generation system using random walk algorithms to create organic, branching crystal structures.

## Features

### 🎯 **Core Algorithm**
- **Triangular Prism Geometry**: Uses triangular prisms as building blocks for realistic crystal shapes
- **Random Walk Growth**: Recursive branching algorithm that creates organic crystal structures
- **Tapering Effect**: Prisms get smaller as they branch further from the center
- **Rotation Chaos**: Adds natural randomness to crystal orientation

### 🎨 **Visual Effects**
- **Color Gradients**: Smooth color transitions from start to end colors
- **Emission Lighting**: Glowing crystal effect with configurable intensity
- **MultiMesh Rendering**: Efficient rendering of thousands of prism instances
- **Real-time Regeneration**: Live parameter adjustment and crystal regeneration

### ⚙️ **Configurable Parameters**

#### Crystal Properties
- `steps`: Number of growth steps (5-100)
- `prism_length`: Length of each prism segment
- `prism_radius`: Radius of the triangular base
- `branch_probability`: Chance of creating a branch (0.0-1.0)
- `branch_decay`: How branch probability decreases with depth

#### Visual Effects
- `taper_amount`: Scale multiplier per step (0.5-1.0)
- `rotation_chaos`: Random rotation amount per step
- `color_start`: Starting color for the crystal
- `color_end`: Ending color for the crystal
- `emission_strength`: Glow intensity

#### Generation
- `auto_generate`: Generate crystal on ready
- `random_seed`: Seed for reproducible results

## Usage

### Basic Usage
```gdscript
# Create a crystal
var crystal = CrystalRandomWalk.new()
add_child(crystal)

# Configure parameters
crystal.steps = 30
crystal.branch_probability = 0.3
crystal.taper_amount = 0.92

# Generate the crystal
crystal.regenerate()
```

### Advanced Configuration
```gdscript
# Set up a complex crystal
crystal.steps = 50
crystal.prism_length = 0.8
crystal.prism_radius = 0.2
crystal.branch_probability = 0.25
crystal.branch_decay = 0.85
crystal.taper_amount = 0.95
crystal.rotation_chaos = 0.15

# Custom colors
crystal.color_start = Color(0.6, 0.9, 1.0)  # Light blue
crystal.color_end = Color(0.2, 0.4, 0.8)    # Dark blue
crystal.emission_strength = 0.6

# Generate with specific seed
crystal.set_seed(42)
```

## Algorithm Details

### Growth Pattern
The crystal grows using a recursive random walk:

1. **Start**: Begin with a single prism at the origin
2. **Branch Decision**: For each step, decide whether to branch
3. **Direction Selection**: Choose one of three 120°-spaced directions
4. **Transform Calculation**: Apply rotation chaos and tapering
5. **Recursion**: Continue growing both main path and branches

### Face Directions
The crystal can grow in three directions, 120° apart:
- Forward: `Vector3(0, 0, 1)`
- Right-back: `Vector3(0.866, 0, -0.5)`
- Left-back: `Vector3(-0.866, 0, -0.5)`

### Tapering
Each generation step applies a scale factor:
```gdscript
scale_factor = pow(taper_amount, depth)
```

This creates natural-looking crystals that get thinner toward the tips.

## Performance

- **MultiMesh Rendering**: Efficiently renders thousands of instances
- **Single Draw Call**: All prisms rendered in one draw call
- **Vertex Colors**: Uses vertex colors for per-instance coloring
- **Unshaded Material**: Optimized for crystal-like appearance

## Demo Scene

The `crystal_random_walk_demo.tscn` scene includes:
- Interactive UI controls for all parameters
- Real-time camera rotation
- Mouse wheel zoom
- Click to randomize parameters
- Live statistics display

## Integration

The CrystalRandomWalk class integrates well with:
- **VR Applications**: 3D crystal structures in virtual environments
- **Procedural Generation**: Random crystal formations
- **Educational Tools**: Visualizing growth algorithms
- **Art Installations**: Dynamic crystal sculptures

## Examples

### Simple Crystal
```gdscript
crystal.steps = 20
crystal.branch_probability = 0.2
crystal.taper_amount = 0.9
```

### Complex Branching Crystal
```gdscript
crystal.steps = 50
crystal.branch_probability = 0.4
crystal.branch_decay = 0.8
crystal.taper_amount = 0.95
crystal.rotation_chaos = 0.2
```

### Delicate Crystal
```gdscript
crystal.steps = 30
crystal.branch_probability = 0.1
crystal.taper_amount = 0.85
crystal.rotation_chaos = 0.05
```

## Technical Notes

- Uses `ArrayMesh` for efficient triangular prism generation
- Implements proper normal calculation for lighting
- Supports both deterministic (seeded) and random generation
- Memory efficient with single mesh + transforms array
- Compatible with Godot 4.x rendering pipeline









