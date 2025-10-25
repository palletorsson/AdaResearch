# SixteenCellNetSpace

A procedural generation algorithm that creates 3D spaces from 16-cell nets (4D polytopes) using tetrahedra in various arrangements. This algorithm generates hollow 3D structures by arranging different types of 16-cell nets in 3D space, creating complex geometric patterns with tetrahedral symmetry.

## Overview

The `SixteenCellNetSpace` class generates 3D spaces by placing 16-cell nets (unfolded 4D polytopes) in a 3D grid. Each net consists of 16 tetrahedra arranged in specific patterns, and multiple nets are arranged to create hollow architectural spaces with unique geometric properties.

## Features

### Net Patterns
- **Octahedral Core**: 16 tetrahedra around an octahedral core with face-centered arrangement
- **Double Pyramid**: Two square pyramids base-to-base with middle ring arrangement
- **Tetrahedral Star**: Star-like arrangement with tetrahedral symmetry in 4 main directions
- **Compact Cluster**: Dense close-packed arrangement for maximum density

### Space Configuration
- **Space Size**: 3D grid dimensions (X, Y, Z) for net placement
- **Tetrahedron Size**: Size of individual tetrahedra in each net
- **Spacing**: Gap between different nets
- **Hollow Center**: Creates empty space in the center of the structure
- **Hollow Radius**: Controls the size of the hollow center

### Arrangement Options
- **Rotation Variety**: Random rotations for visual interest
- **Offset Pattern**: Interlocking arrangement of nets
- **Spiral Arrangement**: Creates spiral hollow tunnels

### Visual Effects
- **Rainbow Gradient**: Color variation based on position
- **Emission**: Glowing effect on tetrahedra
- **Edge Display**: Optional wireframe edges on tetrahedra
- **Transparency**: Semi-transparent tetrahedra for layered effects

## Usage

### Basic Usage
```gdscript
# Create a SixteenCellNetSpace instance
var net_space = SixteenCellNetSpace.new()
add_child(net_space)

# Configure the space
net_space.net_pattern = SixteenCellNetSpace.NetPattern.OCTAHEDRAL_CORE
net_space.space_size = Vector3i(5, 3, 5)
net_space.tetrahedron_size = 0.8
net_space.spacing = 0.2
net_space.create_hollow_center = true

# Generate the space
net_space.generate_16cell_space()
```

### Configuration Options

#### Net Pattern Selection
```gdscript
# Available net patterns
net_space.net_pattern = SixteenCellNetSpace.NetPattern.OCTAHEDRAL_CORE    # Octahedral core
net_space.net_pattern = SixteenCellNetSpace.NetPattern.DOUBLE_PYRAMID     # Double pyramid
net_space.net_pattern = SixteenCellNetSpace.NetPattern.TETRAHEDRAL_STAR   # Tetrahedral star
net_space.net_pattern = SixteenCellNetSpace.NetPattern.COMPACT_CLUSTER    # Compact cluster
```

#### Space Configuration
```gdscript
# Set 3D grid size
net_space.space_size = Vector3i(6, 4, 6)  # 6x4x6 grid of nets

# Set tetrahedron and spacing sizes
net_space.tetrahedron_size = 0.7
net_space.spacing = 0.25

# Enable/disable hollow center
net_space.create_hollow_center = true
net_space.hollow_radius = 2.5
```

#### Arrangement Options
```gdscript
# Enable arrangement variety
net_space.rotation_variety = true
net_space.offset_pattern = true
net_space.spiral_arrangement = false
```

#### Visual Customization
```gdscript
# Set base color
net_space.base_color = Color(0.2, 0.8, 0.9)

# Enable visual effects
net_space.use_rainbow_gradient = true
net_space.emission_strength = 0.6
net_space.show_edges = true
net_space.transparency = 0.2
```

## API Reference

### Properties

#### Space Configuration
- `net_pattern: NetPattern` - Type of 16-cell net pattern to use
- `space_size: Vector3i` - 3D grid dimensions for net placement
- `tetrahedron_size: float` - Size of individual tetrahedra
- `spacing: float` - Gap between nets
- `create_hollow_center: bool` - Whether to create hollow center
- `hollow_radius: float` - Radius of hollow center

#### Arrangement
- `rotation_variety: bool` - Enable random rotations
- `offset_pattern: bool` - Enable interlocking offset pattern
- `spiral_arrangement: bool` - Enable spiral hollow tunnels

#### Visual
- `base_color: Color` - Base color for tetrahedra
- `use_rainbow_gradient: bool` - Enable rainbow color gradient
- `emission_strength: float` - Emission intensity
- `show_edges: bool` - Show wireframe edges
- `transparency: float` - Transparency level (0.0 = opaque, 1.0 = fully transparent)

### Methods

#### Generation
- `generate_16cell_space()` - Generate the complete 16-cell space
- `regenerate()` - Regenerate with current settings

#### Information
- `get_16cell_space_stats() -> Dictionary` - Get statistics about the generated space
- `get_net_bounds() -> Vector3` - Get bounding box size of selected net pattern

#### Net Creation
- `create_16cell_net(pos: Vector3, rotation: Vector3, color: Color)` - Create net at position
- `create_octahedral_core_net(parent: Node3D, color: Color)` - Create octahedral core net
- `create_double_pyramid_net(parent: Node3D, color: Color)` - Create double pyramid net
- `create_tetrahedral_star_net(parent: Node3D, color: Color)` - Create tetrahedral star net
- `create_compact_cluster_net(parent: Node3D, color: Color)` - Create compact cluster net

#### Tetrahedron Creation
- `create_tetrahedron(parent: Node3D, pos: Vector3, rot: Vector3, color: Color)` - Create single tetrahedron
- `create_tetrahedron_edges(verts: Array, color: Color) -> MeshInstance3D` - Create wireframe edges

## Demo Scenes

### Interactive Demo
- **File**: `sixteen_cell_net_space_demo.tscn`
- **Controller**: `sixteen_cell_demo_controller.gd`
- **Features**: Full UI controls, camera movement, parameter adjustment

### Showcase
- **File**: `sixteen_cell_net_space_showcase.tscn`
- **Features**: Animated camera, pre-configured settings, visual demonstration

## Controls (Demo)

### Mouse Controls
- **Mouse Wheel**: Zoom in/out
- **Middle Mouse Drag**: Rotate camera
- **Left Click**: Randomize parameters
- **Right Click**: Cycle through net patterns

### Keyboard Controls
- **R**: Regenerate current configuration
- **Space**: Randomize all parameters
- **1-4**: Switch between net patterns

## Technical Details

### Net Patterns

#### Octahedral Core
- 16 tetrahedra arranged around octahedral vertices
- Face-centered arrangement with additional tetrahedra
- Symmetric distribution around central octahedron

#### Double Pyramid
- Bottom pyramid: 4 tetrahedra
- Middle ring: 8 tetrahedra
- Top pyramid: 4 tetrahedra
- Creates vertical symmetry

#### Tetrahedral Star
- 4 main directions based on tetrahedral vertices
- 4 tetrahedra along each direction
- Star-like radial arrangement

#### Compact Cluster
- Dense close-packed arrangement
- 8 base positions + 8 additional positions
- Maximum density configuration

### Tetrahedron Geometry
- Regular tetrahedra with proper face normals
- Configurable size and transparency
- Optional wireframe edges
- Two-sided rendering for transparency

### Performance Considerations

- **Net Count**: Total nets = space_size.x × space_size.y × space_size.z
- **Tetrahedron Count**: Each net has 16 tetrahedra
- **Total Tetrahedra**: Net count × 16 (when hollow center is disabled)
- **Memory Usage**: Scales with total tetrahedron count

### Optimization Tips

- Use smaller `space_size` for better performance
- Disable `show_edges` for better performance
- Use `create_hollow_center = true` to reduce tetrahedron count
- Adjust `tetrahedron_size` and `spacing` for desired density
- Use `transparency` sparingly as it affects rendering performance

## Integration

### Adding to Existing Scenes
```gdscript
# Load the scene
var net_space_scene = preload("res://algorithms/proceduralgeneration/sixteencellnetspace/sixteen_cell_net_space.tscn")
var net_space = net_space_scene.instantiate()
add_child(net_space)

# Configure and generate
net_space.space_size = Vector3i(4, 3, 4)
net_space.generate_16cell_space()
```

### Custom Net Patterns
To add custom net patterns, extend the `NetPattern` enum and add corresponding creation methods:

```gdscript
enum NetPattern {
    OCTAHEDRAL_CORE,
    DOUBLE_PYRAMID,
    TETRAHEDRAL_STAR,
    COMPACT_CLUSTER,
    CUSTOM_PATTERN  # Add your custom pattern
}

# Add creation method
func create_custom_pattern_net(parent: Node3D, color: Color):
    # Your custom net creation logic
    pass
```

## Examples

### Small Geometric Space
```gdscript
net_space.net_pattern = SixteenCellNetSpace.NetPattern.OCTAHEDRAL_CORE
net_space.space_size = Vector3i(3, 2, 3)
net_space.tetrahedron_size = 0.6
net_space.spacing = 0.3
net_space.create_hollow_center = true
net_space.generate_16cell_space()
```

### Large Transparent Structure
```gdscript
net_space.net_pattern = SixteenCellNetSpace.NetPattern.TETRAHEDRAL_STAR
net_space.space_size = Vector3i(8, 6, 8)
net_space.tetrahedron_size = 0.5
net_space.spacing = 0.15
net_space.transparency = 0.4
net_space.use_rainbow_gradient = true
net_space.generate_16cell_space()
```

### Spiral Tunnel
```gdscript
net_space.net_pattern = SixteenCellNetSpace.NetPattern.COMPACT_CLUSTER
net_space.space_size = Vector3i(10, 8, 10)
net_space.tetrahedron_size = 0.4
net_space.spacing = 0.1
net_space.spiral_arrangement = true
net_space.hollow_radius = 3.0
net_space.generate_16cell_space()
```

### Artistic Installation
```gdscript
net_space.net_pattern = SixteenCellNetSpace.NetPattern.DOUBLE_PYRAMID
net_space.space_size = Vector3i(5, 5, 5)
net_space.tetrahedron_size = 0.8
net_space.spacing = 0.2
net_space.rotation_variety = true
net_space.offset_pattern = true
net_space.use_rainbow_gradient = true
net_space.emission_strength = 0.8
net_space.generate_16cell_space()
```

## File Structure

```
algorithms/proceduralgeneration/sixteencellnetspace/
├── sixteen_cell_net_space.gd              # Main algorithm class
├── sixteen_cell_net_space.tscn            # Basic scene
├── sixteen_cell_net_space_demo.tscn       # Interactive demo
├── sixteen_cell_demo_controller.gd        # Demo controller
├── sixteen_cell_net_space_showcase.tscn   # Showcase scene
└── README_SixteenCellNetSpace.md          # This documentation
```

## Dependencies

- Godot 4.x
- No external dependencies required

## Mathematical Background

The 16-cell (also known as hexadecachoron) is a 4D regular polytope with 16 tetrahedral cells. When "unfolded" into 3D space, it creates various net patterns that can be used to construct 3D architectural spaces. The algorithm explores different ways of arranging these tetrahedra to create visually interesting and mathematically meaningful structures.

## License

Part of the AdaResearch project. See main project license for details.









