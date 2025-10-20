# Binary Space Partitioning (BSP)

A procedural generation algorithm that creates complex 3D space partitions using Binary Space Partitioning with gradient-based probability control. This algorithm recursively divides 3D space into smaller cells based on configurable probability gradients, creating organic and structured spatial divisions.

## Overview

The `BinarySpacePartitioning` class generates 3D space partitions by recursively dividing space using binary splits along different axes. The algorithm uses gradient-based probability functions to control where and how space is partitioned, creating complex hierarchical structures that can be used for procedural generation, spatial organization, and architectural design.

## Features

### BSP Tree Generation
- **Recursive Partitioning**: Divides space into binary tree structure
- **Depth Control**: Configurable maximum partition depth
- **Size Limits**: Minimum cell size constraints
- **Axis Selection**: Intelligent axis selection based on dimensions
- **Split Ratios**: Configurable split position ratios

### Gradient-Based Probability
- **Centered Gradient**: Gaussian falloff from center
- **Compact Gradient**: Sharper falloff for dense centers
- **Diagonal Gradient**: Diagonal-based probability patterns
- **Scattered Gradient**: Noise-based scattered patterns
- **Falloff Control**: Adjustable gradient steepness
- **Center Bias**: Control over center influence

### Visualization Options
- **Partition Display**: Wireframe visualization of all cells
- **Heatmap Generation**: 2D probability heatmap display
- **Color Coding**: Probability-based color mapping
- **Real-time Updates**: Dynamic regeneration support

## Parameters

### BSP Settings
- **Max Depth**: Maximum recursion depth for partitioning (default: 7)
- **Min Cell Size**: Minimum size before stopping partition (default: 0.5)
- **Space Size**: Overall 3D space dimensions (default: Vector3(10, 10, 10))

### Gradient Settings
- **Gradient Type**: Type of probability gradient (Centered, Compact, Diagonal, Scattered)
- **Gradient Falloff**: Steepness of gradient falloff (0.1-5.0, default: 1.5)
- **Center Bias**: Influence of center position on splits (0.0-1.0, default: 0.8)

### Visualization
- **Show Partitions**: Display wireframe partitions (default: true)
- **Show Heatmap**: Display probability heatmap (default: true)
- **Regenerate**: Trigger regeneration (default: false)

## Algorithm Details

### BSP Tree Structure
1. **Root Node**: Initial space bounds
2. **Recursive Partitioning**: Split nodes based on probability
3. **Axis Selection**: Choose split axis based on dimensions
4. **Split Calculation**: Determine split position with gradient influence
5. **Child Creation**: Create left and right child nodes
6. **Leaf Collection**: Gather all terminal nodes

### Probability Calculation
1. **Position Normalization**: Normalize position to space bounds
2. **Distance Calculation**: Calculate distance from center
3. **Gradient Application**: Apply selected gradient function
4. **Probability Scaling**: Scale based on falloff parameters

### Split Position Calculation
1. **Base Ratio**: Start with 0.5 (center split)
2. **Gradient Influence**: Apply probability-based variation
3. **Random Variation**: Add controlled randomness
4. **Clamping**: Ensure valid split ratios (0.3-0.7)

## Usage

### Basic Usage
```gdscript
# Create a BinarySpacePartitioning instance
var bsp = BinarySpacePartitioning.new()
add_child(bsp)

# Configure basic parameters
bsp.max_depth = 5
bsp.min_cell_size = 1.0
bsp.space_size = Vector3(20, 20, 20)

# Generate partitions
bsp.generate_bsp()
```

### Gradient Configuration
```gdscript
# Centered gradient (Gaussian falloff)
bsp.gradient_type = 0  # Centered
bsp.gradient_falloff = 2.0
bsp.center_bias = 0.9

# Compact gradient (sharper falloff)
bsp.gradient_type = 1  # Compact
bsp.gradient_falloff = 1.5

# Diagonal gradient
bsp.gradient_type = 2  # Diagonal
bsp.gradient_falloff = 1.0

# Scattered gradient (noise-based)
bsp.gradient_type = 3  # Scattered
bsp.gradient_falloff = 0.8
```

### Visualization Control
```gdscript
# Show only partitions
bsp.show_partitions = true
bsp.show_heatmap = false

# Show only heatmap
bsp.show_partitions = false
bsp.show_heatmap = true

# Regenerate with new parameters
bsp.regenerate = true
```

## Visual Characteristics

### Partition Patterns
- **Hierarchical Structure**: Tree-like organization of space
- **Gradient Influence**: Probability-based partition density
- **Organic Variation**: Natural-looking spatial divisions
- **Depth Variation**: Different cell sizes at different depths

### Heatmap Visualization
- **Color Gradient**: Purple to yellow probability mapping
- **2D Projection**: Top-down view of partition probabilities
- **Resolution Control**: Configurable heatmap resolution
- **Real-time Updates**: Dynamic heatmap regeneration

### Wireframe Display
- **Box Outlines**: 3D wireframe of all partition cells
- **Color Coding**: Probability-based cell coloring
- **Transparency**: Semi-transparent cell visualization
- **Depth Indication**: Visual depth representation

## Performance Considerations

### Complexity Factors
- **Depth Impact**: Exponential growth with depth
- **Space Size**: Larger spaces require more processing
- **Gradient Type**: Some gradients are more computationally expensive
- **Visualization**: Heatmap generation adds overhead

### Optimization Tips
- Use appropriate max_depth for your needs
- Disable unused visualizations
- Consider LOD for distant partitions
- Cache heatmap for static configurations

### Memory Usage
- Scales with number of leaf nodes
- Heatmap resolution affects memory
- Wireframe meshes consume GPU memory
- Tree structure uses minimal memory

## Use Cases

### Procedural Generation
- **Dungeon Generation**: Create room and corridor layouts
- **City Planning**: Organize urban districts
- **Terrain Generation**: Divide terrain into regions
- **Architectural Design**: Plan building layouts

### Game Development
- **Level Design**: Create complex level structures
- **AI Pathfinding**: Organize space for pathfinding
- **Resource Distribution**: Place resources in organized areas
- **Spawn Points**: Distribute spawn locations

### Scientific Applications
- **Spatial Analysis**: Organize data by location
- **Simulation**: Create structured simulation spaces
- **Visualization**: Display spatial relationships
- **Research**: Study spatial partitioning algorithms

## Technical Implementation

### Dependencies
- **Godot 4.x**: Requires Godot 4.0 or later
- **GDScript**: Written in Godot's scripting language
- **SurfaceTool**: Uses Godot's mesh generation tools
- **Math Functions**: Utilizes trigonometric and exponential functions

### Class Structure
- **BSPNode**: Internal class for tree nodes
- **Main Algorithm**: BinarySpacePartitioning class
- **Visualization**: Separate methods for different displays
- **Gradient Functions**: Modular probability calculations

### File Structure
- `BinarySpacePartitioning.gd`: Main algorithm implementation
- `BinarySpacePartitioning.tscn`: Scene file with visualization
- `README.md`: This documentation file

## Algorithm Variations

### Gradient Types
1. **Centered**: Gaussian falloff from center point
2. **Compact**: Sharper falloff for dense centers
3. **Diagonal**: Diagonal-based probability patterns
4. **Scattered**: Noise-based scattered patterns

### Split Strategies
- **Size-based**: Split along largest dimension
- **Weighted**: Weight by dimension size
- **Random**: Random axis selection
- **Gradient-influenced**: Probability-based axis selection

### Probability Functions
- **Exponential**: Smooth falloff functions
- **Linear**: Linear distance relationships
- **Noise-based**: Perlin noise patterns
- **Custom**: User-defined probability functions

## Future Enhancements

### Algorithm Improvements
- **3D Heatmaps**: Full 3D probability visualization
- **Custom Gradients**: User-defined gradient functions
- **Multi-threading**: Parallel partition generation
- **Incremental Updates**: Dynamic partition modification

### Visualization Enhancements
- **Interactive Controls**: Real-time parameter adjustment
- **Animation**: Animated partition generation
- **Export Options**: Save partition data
- **VR Support**: Virtual reality visualization

### Performance Optimizations
- **Spatial Indexing**: Faster neighbor finding
- **LOD System**: Level-of-detail for large spaces
- **Caching**: Cache expensive calculations
- **GPU Acceleration**: Use compute shaders

## Troubleshooting

### Common Issues
- **Empty Partitions**: Check min_cell_size and max_depth
- **Performance Issues**: Reduce depth or disable visualizations
- **Visual Artifacts**: Check gradient parameters
- **Memory Issues**: Reduce space_size or heatmap resolution

### Debug Tips
- Print partition statistics
- Visualize probability functions
- Check tree structure
- Monitor performance metrics

## License

This algorithm is part of the AdaResearch project and follows the same licensing terms as the main project.
