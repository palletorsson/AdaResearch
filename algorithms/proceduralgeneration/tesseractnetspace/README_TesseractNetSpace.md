# TesseractNetSpace

A procedural generation algorithm that creates 3D spaces from tesseract nets in various configurations. This algorithm generates hollow 3D structures by arranging different types of tesseract nets in 3D space, creating complex architectural patterns.

## Overview

The `TesseractNetSpace` class generates 3D spaces by placing tesseract nets (unfolded 4D hypercubes) in a 3D grid. Each net consists of 8 cubes arranged in specific patterns, and multiple nets are arranged to create hollow architectural spaces.

## Features

### Net Types
- **Dali Cross**: Classic cross pattern with 1 center cube + 6 surrounding cubes + 1 extended cube
- **Linear Chain**: 8 cubes arranged in a straight line
- **Folded Chain**: 8 cubes in a zigzag/folded pattern
- **Double Cross**: Two perpendicular crosses intersecting

### Space Configuration
- **Space Size**: 3D grid dimensions (X, Y, Z) for net placement
- **Cube Size**: Size of individual cubes in each net
- **Spacing**: Gap between different nets
- **Hollow Center**: Creates empty space in the center of the structure

### Visual Effects
- **Color Variation**: Slight color variations between cubes
- **Emission**: Glowing effect on cubes
- **Wireframe**: Optional wireframe overlay on cubes
- **Rotation Variety**: Random rotations for visual interest
- **Offset Pattern**: Interlocking arrangement of nets

## Usage

### Basic Usage
```gdscript
# Create a TesseractNetSpace instance
var net_space = TesseractNetSpace.new()
add_child(net_space)

# Configure the space
net_space.net_type = TesseractNetSpace.NetType.DALI_CROSS
net_space.space_size = Vector3i(5, 3, 5)
net_space.cube_size = 1.0
net_space.spacing = 0.1
net_space.create_hollow_center = true

# Generate the space
net_space.generate_net_space()
```

### Configuration Options

#### Net Type Selection
```gdscript
# Available net types
net_space.net_type = TesseractNetSpace.NetType.DALI_CROSS      # Classic cross
net_space.net_type = TesseractNetSpace.NetType.LINEAR_CHAIN    # Linear chain
net_space.net_type = TesseractNetSpace.NetType.FOLDED_CHAIN    # Folded chain
net_space.net_type = TesseractNetSpace.NetType.DOUBLE_CROSS    # Double cross
```

#### Space Configuration
```gdscript
# Set 3D grid size
net_space.space_size = Vector3i(7, 4, 7)  # 7x4x7 grid of nets

# Set cube and spacing sizes
net_space.cube_size = 1.2
net_space.spacing = 0.15

# Enable/disable hollow center
net_space.create_hollow_center = true
```

#### Visual Customization
```gdscript
# Set base color
net_space.base_color = Color(0.8, 0.2, 0.2)

# Enable visual effects
net_space.color_variation = true
net_space.emission_strength = 0.4
net_space.show_wireframe = true

# Enable arrangement variety
net_space.rotation_variety = true
net_space.offset_pattern = true
```

## API Reference

### Properties

#### Space Configuration
- `net_type: NetType` - Type of tesseract net to use
- `space_size: Vector3i` - 3D grid dimensions for net placement
- `cube_size: float` - Size of individual cubes
- `spacing: float` - Gap between nets
- `create_hollow_center: bool` - Whether to create hollow center

#### Net Arrangement
- `rotation_variety: bool` - Enable random rotations
- `offset_pattern: bool` - Enable interlocking offset pattern

#### Visual
- `base_color: Color` - Base color for cubes
- `color_variation: bool` - Enable color variations
- `emission_strength: float` - Emission intensity
- `show_wireframe: bool` - Show wireframe overlay

### Methods

#### Generation
- `generate_net_space()` - Generate the complete net space
- `regenerate()` - Regenerate with current settings

#### Information
- `get_net_space_stats() -> Dictionary` - Get statistics about the generated space
- `get_net_bounds() -> Vector3` - Get bounding box size of selected net type

#### Net Creation
- `create_net_at_position(pos: Vector3, rotation_y: float, color: Color)` - Create net at position
- `create_dali_cross(parent: Node3D, color: Color)` - Create Dali cross net
- `create_linear_chain(parent: Node3D, color: Color)` - Create linear chain net
- `create_folded_chain(parent: Node3D, color: Color)` - Create folded chain net
- `create_double_cross(parent: Node3D, color: Color)` - Create double cross net

#### Cube Creation
- `create_cube(parent: Node3D, pos: Vector3, color: Color)` - Create single cube
- `create_cube_wireframe(pos: Vector3, color: Color) -> MeshInstance3D` - Create wireframe

## Demo Scenes

### Interactive Demo
- **File**: `tesseract_net_space_demo.tscn`
- **Controller**: `net_space_demo_controller.gd`
- **Features**: Full UI controls, camera movement, parameter adjustment

### Showcase
- **File**: `tesseract_net_space_showcase.tscn`
- **Features**: Animated camera, pre-configured settings, visual demonstration

## Controls (Demo)

### Mouse Controls
- **Mouse Wheel**: Zoom in/out
- **Middle Mouse Drag**: Rotate camera
- **Left Click**: Randomize parameters
- **Right Click**: Cycle through net types

### Keyboard Controls
- **R**: Regenerate current configuration
- **Space**: Randomize all parameters
- **1-4**: Switch between net types

## Technical Details

### Net Patterns

#### Dali Cross
- 8 cubes in cross formation
- Center cube with 6 face-attached cubes
- 1 extended cube for asymmetry

#### Linear Chain
- 8 cubes in straight line
- Evenly spaced along X-axis

#### Folded Chain
- 8 cubes in zigzag pattern
- Creates curved/3D path

#### Double Cross
- Two perpendicular crosses
- Intersecting at center cube

### Performance Considerations

- **Net Count**: Total nets = space_size.x × space_size.y × space_size.z
- **Cube Count**: Each net has 8 cubes
- **Total Cubes**: Net count × 8 (when hollow center is disabled)
- **Memory Usage**: Scales with total cube count

### Optimization Tips

- Use smaller `space_size` for better performance
- Disable `wireframe` for better performance
- Use `create_hollow_center = true` to reduce cube count
- Adjust `cube_size` and `spacing` for desired density

## Integration

### Adding to Existing Scenes
```gdscript
# Load the scene
var net_space_scene = preload("res://algorithms/proceduralgeneration/tesseractnetspace/tesseract_net_space.tscn")
var net_space = net_space_scene.instantiate()
add_child(net_space)

# Configure and generate
net_space.space_size = Vector3i(3, 2, 3)
net_space.generate_net_space()
```

### Custom Net Types
To add custom net types, extend the `NetType` enum and add corresponding creation methods:

```gdscript
enum NetType {
    DALI_CROSS,
    LINEAR_CHAIN,
    FOLDED_CHAIN,
    DOUBLE_CROSS,
    CUSTOM_NET  # Add your custom type
}

# Add creation method
func create_custom_net(parent: Node3D, color: Color):
    # Your custom net creation logic
    pass
```

## Examples

### Small Architectural Space
```gdscript
net_space.net_type = TesseractNetSpace.NetType.DALI_CROSS
net_space.space_size = Vector3i(3, 2, 3)
net_space.cube_size = 0.8
net_space.spacing = 0.2
net_space.create_hollow_center = true
net_space.generate_net_space()
```

### Large Open Structure
```gdscript
net_space.net_type = TesseractNetSpace.NetType.LINEAR_CHAIN
net_space.space_size = Vector3i(10, 1, 10)
net_space.cube_size = 1.5
net_space.spacing = 0.1
net_space.create_hollow_center = false
net_space.generate_net_space()
```

### Artistic Installation
```gdscript
net_space.net_type = TesseractNetSpace.NetType.FOLDED_CHAIN
net_space.space_size = Vector3i(5, 5, 5)
net_space.cube_size = 0.6
net_space.spacing = 0.3
net_space.rotation_variety = true
net_space.offset_pattern = true
net_space.color_variation = true
net_space.generate_net_space()
```

## File Structure

```
algorithms/proceduralgeneration/tesseractnetspace/
├── tesseract_net_space.gd              # Main algorithm class
├── tesseract_net_space.tscn            # Basic scene
├── tesseract_net_space_demo.tscn       # Interactive demo
├── net_space_demo_controller.gd        # Demo controller
├── tesseract_net_space_showcase.tscn   # Showcase scene
└── README_TesseractNetSpace.md         # This documentation
```

## Dependencies

- Godot 4.x
- No external dependencies required

## License

Part of the AdaResearch project. See main project license for details.

