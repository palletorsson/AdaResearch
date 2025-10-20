# Space Colonization Algorithm

A sophisticated procedural generation algorithm that creates organic growth structures using the Space Colonization Algorithm. This algorithm simulates natural growth patterns by having structures reach toward attraction points distributed in 3D space, creating realistic organic forms like veins, coral, lightning, roots, and neural networks.

## Overview

The `SpaceColonizationAlgorithm` class generates organic 3D structures by simulating growth toward attraction points. The algorithm creates branching structures that naturally fill space and colonize target areas, resulting in realistic organic patterns that can be used for various procedural generation applications.

## Features

### Core Algorithm
- **Space Colonization**: Structures grow toward attraction points
- **Attraction Point Distribution**: Multiple distribution types for different patterns
- **Growth Iteration**: Step-by-step growth simulation
- **Colonization Logic**: Points are "colonized" when structures reach them
- **Organic Branching**: Natural-looking branch growth patterns

### Distribution Types
- **Shell Distribution**: Points around cube surface with outward offset
- **Volume Distribution**: Points in shell volume around cube
- **Surface Distribution**: Points directly on cube faces
- **Corner Distribution**: Concentrated points at cube corners

### Growth Control
- **Segment Length**: Length of each growth segment
- **Influence Distance**: How far attraction points can influence growth
- **Kill Distance**: Distance at which points are colonized
- **Thickness Decay**: How branch thickness decreases over distance
- **Max Iterations**: Maximum number of growth iterations

### Origin Patterns
- **Single Origin**: One starting point
- **Multiple Origins**: Several starting points in a pattern
- **Ring Origin**: Starting points in a circular pattern
- **Base Platform**: Grid of starting points

### Visual Features
- **Real-time Growth**: Animated growth visualization
- **Attraction Point Display**: Visual representation of target points
- **Cube Guide**: Wireframe guide showing target shape
- **Branch Visualization**: Tapered cylinder branches
- **Color Gradients**: Depth-based color variation

## Parameters

### Target Shape
- **Cube Size**: Size of the target cube (default: Vector3(4, 4, 4))
- **Attraction Points Count**: Number of attraction points (default: 500)
- **Distribution Thickness**: Thickness of distribution shell (default: 2.0)
- **Distribution Type**: Type of point distribution (Shell, Volume, Surface, Corners)

### Growth Settings
- **Segment Length**: Length of each growth segment (default: 0.2)
- **Influence Distance**: Maximum influence distance (default: 2.0)
- **Kill Distance**: Colonization distance (default: 0.3)
- **Max Iterations**: Maximum growth iterations (default: 1000)
- **Branch Thickness**: Initial branch thickness (default: 0.15)
- **Thickness Decay**: Thickness reduction factor (default: 0.9)

### Starting Point
- **Growth Origin**: Starting position for growth (default: Vector3(0, -6, 0))
- **Origin Type**: Pattern of starting points (Single, Multiple, Ring, Base)

### Visual Settings
- **Show Attraction Points**: Display attraction points (default: true)
- **Show Cube Guide**: Display target cube wireframe (default: true)
- **Show Growth Animation**: Enable animated growth (default: false)
- **Branch Color**: Color of branches (default: Color(0.6, 0.4, 0.2))
- **Attraction Color**: Color of attraction points (default: Color(1, 0.3, 0.3, 0.5))

## Algorithm Details

### Space Colonization Process
1. **Attraction Point Generation**: Create points around target shape
2. **Initial Growth Nodes**: Create starting growth nodes
3. **Influence Calculation**: Find closest nodes for each attraction point
4. **Growth Direction**: Calculate growth direction based on influences
5. **Node Creation**: Create new nodes in growth direction
6. **Colonization**: Remove points that are too close to structures
7. **Iteration**: Repeat until no more growth is possible

### Growth Node System
- **Position**: 3D position of the node
- **Parent**: Parent node in the tree structure
- **Children**: Child nodes created from this node
- **Thickness**: Current thickness of the branch
- **Growth Direction**: Calculated direction for next growth
- **Influenced By**: Number of attraction points influencing this node

### Attraction Point Management
- **Active Points**: Points that can still influence growth
- **Colonized Points**: Points that have been reached by structures
- **Distance Checking**: Efficient distance calculations for influence
- **Point Removal**: Automatic removal of colonized points

## Usage

### Basic Usage
```gdscript
# Create a SpaceColonizationAlgorithm instance
var colonization = SpaceColonizationAlgorithm.new()
add_child(colonization)

# Configure basic parameters
colonization.cube_size = Vector3(6, 6, 6)
colonization.attraction_points_count = 800
colonization.distribution_type = 0  # Shell
colonization.segment_length = 0.25
colonization.influence_distance = 2.5

# Generate structure
colonization.generate_structure()
```

### Growth Animation
```gdscript
# Enable animated growth
colonization.show_growth_animation = true
colonization.toggle_animation = true

# Manual step-by-step growth
colonization.step_growth = true
```

### Different Patterns
```gdscript
# Vein-like pattern
colonization.distribution_type = 0  # Shell
colonization.distribution_thickness = 1.0
colonization.influence_distance = 1.5
colonization.segment_length = 0.15

# Coral-like pattern
colonization.distribution_type = 1  # Volume
colonization.distribution_thickness = 3.0
colonization.influence_distance = 2.5
colonization.segment_length = 0.25

# Lightning pattern
colonization.distribution_type = 2  # Surface
colonization.distribution_thickness = 0.5
colonization.influence_distance = 3.0
colonization.segment_length = 0.4
```

### Preset Patterns
```gdscript
# Create presets instance
var presets = SpaceColonizationPresets.new()
add_child(presets)

# Apply different presets
presets.pattern_preset = 0  # Veins
presets.pattern_preset = 1  # Coral
presets.pattern_preset = 2  # Lightning
presets.pattern_preset = 3  # Roots
presets.pattern_preset = 4  # Neural
```

## Visual Characteristics

### Organic Growth Patterns
- **Natural Branching**: Realistic branch growth patterns
- **Space Filling**: Structures naturally fill available space
- **Colonization**: Points are "colonized" as structures reach them
- **Organic Variation**: Natural variation in growth patterns

### Structural Features
- **Tapered Branches**: Thickness decreases with distance from origin
- **Hierarchical Structure**: Tree-like organization of growth nodes
- **Depth Variation**: Different characteristics at different depths
- **Color Gradients**: Visual depth indication through color

### Animation and Visualization
- **Real-time Growth**: Watch structures grow step by step
- **Attraction Visualization**: See target points and their influence
- **Guide Visualization**: Target shape wireframe display
- **Interactive Control**: Manual step-by-step growth control

## Performance Considerations

### Complexity Factors
- **Attraction Points**: More points increase computation
- **Max Iterations**: Higher values create more complex structures
- **Influence Distance**: Larger values increase neighbor checking
- **Animation**: Real-time animation adds processing overhead

### Optimization Tips
- Use appropriate attraction point count for your needs
- Adjust influence distance based on desired detail level
- Disable animation for static generation
- Consider LOD for distant structures

### Memory Usage
- Scales with number of growth nodes created
- Each node stores position, direction, and thickness
- Attraction points consume memory until colonized
- Visualization meshes consume GPU memory

## Use Cases

### Procedural Generation
- **Organic Structures**: Natural-looking growth patterns
- **Vein Systems**: Blood vessels, leaf veins, mineral veins
- **Coral Growth**: Underwater coral formations
- **Root Systems**: Plant root networks
- **Neural Networks**: Biological neural structures

### Game Development
- **Environment Assets**: Organic environmental features
- **Character Design**: Organic creature appendages
- **Weapon Design**: Natural staff and branch weapons
- **Architecture**: Organic building elements

### Scientific Applications
- **Biological Modeling**: Growth pattern simulation
- **Fractal Analysis**: Complex structure analysis
- **Network Studies**: Connection pattern research
- **Visualization**: Complex data representation

## Technical Implementation

### Dependencies
- **Godot 4.x**: Requires Godot 4.0 or later
- **GDScript**: Written in Godot's scripting language
- **SurfaceTool**: Uses Godot's mesh generation tools
- **Math Functions**: Utilizes geometric and trigonometric functions

### Class Structure
- **GrowthNode**: Internal class for growth nodes
- **SpaceColonizationAlgorithm**: Main algorithm implementation
- **SpaceColonizationPresets**: Preset pattern configurations
- **Visualization**: Separate methods for different display modes

### File Structure
- `SpaceColonizationAlgorithm.gd`: Main algorithm implementation
- `SpaceColonizationPresets.gd`: Preset pattern configurations
- `SpaceColonizationAlgorithm.tscn`: Scene file with visualization
- `README.md`: This documentation file

## Algorithm Variations

### Distribution Modifications
- **Custom Shapes**: Non-cubic target shapes
- **Dynamic Points**: Moving attraction points
- **Density Variation**: Variable point density
- **Multi-layer**: Different densities at different heights

### Growth Patterns
- **Species Variation**: Different growth patterns
- **Environmental Factors**: Growth based on conditions
- **Damage Response**: Growth after damage
- **Seasonal Changes**: Time-based growth patterns

### Visualization Options
- **Different Geometries**: Various branch shapes
- **Texture Mapping**: Detailed branch textures
- **Particle Effects**: Growth particles and effects
- **VR Support**: Virtual reality visualization

## Future Enhancements

### Algorithm Improvements
- **3D Shapes**: Support for various target shapes
- **Dynamic Growth**: Real-time growth modification
- **Multi-species**: Different growth types in same structure
- **Environmental Interaction**: Growth affected by environment

### Visual Enhancements
- **Advanced Materials**: PBR materials for branches
- **Particle Systems**: Growth particles and effects
- **Animation**: More complex growth animations
- **VR Support**: Virtual reality interaction

### Performance Optimizations
- **LOD System**: Level-of-detail for distant structures
- **Instancing**: Efficient rendering of multiple structures
- **Caching**: Cache generated meshes
- **GPU Acceleration**: Use compute shaders

## Troubleshooting

### Common Issues
- **Empty Structures**: Check attraction points and influence distance
- **Performance Issues**: Reduce attraction points or max iterations
- **Unrealistic Growth**: Adjust segment length and influence distance
- **Memory Issues**: Reduce max iterations or attraction points

### Debug Tips
- Print growth statistics and node counts
- Visualize attraction points and their influence
- Check growth direction calculations
- Monitor performance metrics

## License

This algorithm is part of the AdaResearch project and follows the same licensing terms as the main project.
