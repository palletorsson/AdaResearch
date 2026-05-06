# 3D Poisson Disk Sampling

A comprehensive procedural generation algorithm that creates well-distributed point sets in 3D space using Poisson Disk Sampling with Bridson's algorithm. This system includes both the core sampling functionality and practical applications for various procedural generation tasks.

## Overview

The `PoissonDiskSampling3D` class generates 3D point distributions that ensure no two points are closer than a specified minimum distance, creating natural-looking and well-distributed point sets. The algorithm uses Bridson's efficient Poisson Disk Sampling method with grid acceleration for optimal performance.

## Features

### Core Sampling Algorithm
- **Bridson's Algorithm**: Efficient Poisson Disk Sampling implementation
- **Grid Acceleration**: Fast neighbor checking using spatial grid
- **Multiple Distribution Types**: Uniform, Spherical, Cylindrical, and Layered
- **Configurable Boundaries**: Flexible boundary checking and constraints
- **Seed Control**: Reproducible results with seed values

### Visualization Options
- **Multiple Display Modes**: Points, Spheres, Cubes, Cylinders, or Custom
- **Radius Visualization**: Wireframe spheres showing minimum distance
- **Grid Visualization**: Optional bounding box display
- **Color Customization**: Configurable point colors and materials
- **Real-time Updates**: Dynamic regeneration and visualization

### Practical Applications
- **Forest Generation**: Natural tree placement with proper spacing
- **Particle Clouds**: Well-distributed particle systems
- **Star Fields**: Realistic star distribution in space
- **Cell Distribution**: Biological cell placement simulation

## Parameters

### Sampling Settings
- **Sample Region**: 3D region size for sampling (default: Vector3(10, 10, 10))
- **Min Distance**: Minimum distance between points (default: 1.0)
- **Max Attempts**: Maximum attempts per point generation (default: 30)
- **Seed Value**: Random seed for reproducible results (default: 0)

### Visualization
- **Display Mode**: Type of visualization (Points, Spheres, Cubes, Cylinders)
- **Point Size**: Size of visualized points (default: 0.2)
- **Point Color**: Color of sample points (default: Color(0.2, 0.8, 1.0))
- **Show Radius**: Display minimum distance spheres (default: false)
- **Show Grid**: Display bounding box (default: false)

### Advanced
- **Use Boundary**: Enable boundary checking (default: true)
- **Distribution Type**: Type of point distribution (Uniform, Spherical, Cylindrical, Layered)
- **Boundary Falloff**: Falloff factor for boundary effects (default: 0.5)

## Algorithm Details

### Bridson's Algorithm
1. **Grid Initialization**: Create spatial grid for efficient neighbor checking
2. **Initial Point**: Generate first point based on distribution type
3. **Active List**: Maintain list of points that can generate new neighbors
4. **Point Generation**: Generate new points in annulus around existing points
5. **Validation**: Check minimum distance constraint using grid
6. **Iteration**: Continue until no more valid points can be generated

### Distribution Types
1. **Uniform**: Random points within rectangular region
2. **Spherical**: Points within spherical boundary
3. **Cylindrical**: Points within cylindrical boundary
4. **Layered**: Points with density variation by height

### Grid Acceleration
- **Spatial Partitioning**: Divide space into grid cells
- **Neighbor Checking**: Only check nearby grid cells
- **Efficient Lookup**: O(1) grid cell access
- **Memory Optimization**: Minimal memory overhead

## Usage

### Basic Usage
```gdscript
# Create a PoissonDiskSampling3D instance
var sampler = PoissonDiskSampling3D.new()
add_child(sampler)

# Configure basic parameters
sampler.sample_region = Vector3(20, 20, 20)
sampler.min_distance = 2.0
sampler.max_attempts = 50

# Generate samples
sampler.generate_samples()
```

### Distribution Types
```gdscript
# Uniform distribution
sampler.distribution_type = 0
sampler.use_boundary = true

# Spherical distribution
sampler.distribution_type = 1
sampler.sample_region = Vector3(10, 10, 10)  # Cube becomes sphere

# Cylindrical distribution
sampler.distribution_type = 2
sampler.sample_region = Vector3(15, 5, 15)  # Height vs radius

# Layered distribution
sampler.distribution_type = 3
sampler.boundary_falloff = 0.8
```

### Visualization Control
```gdscript
# Configure visualization
sampler.display_mode = 1  # Spheres
sampler.point_size = 0.3
sampler.point_color = Color(1, 0.5, 0)
sampler.show_radius = true
sampler.show_grid = true

# Regenerate with new settings
sampler.regenerate = true
```

### Practical Applications
```gdscript
# Create applications instance
var applications = PoissonDiskSamplingApplications.new()
add_child(applications)

# Configure for forest generation
applications.application = 0  # Forest
applications.area_size = Vector3(50, 10, 50)
applications.min_separation = 3.0

# Generate forest
applications.apply_samples = true
```

## Visual Characteristics

### Point Distribution
- **Well-Distributed**: No clustering or gaps in distribution
- **Natural Variation**: Organic-looking point placement
- **Consistent Density**: Uniform density across the region
- **Boundary Respect**: Proper handling of region boundaries

### Visualization Options
- **Multiple Geometries**: Various point representations
- **Color Coding**: Customizable point colors
- **Radius Display**: Visual representation of minimum distance
- **Grid Overlay**: Optional bounding box visualization

### Performance
- **Efficient Generation**: Fast point generation with grid acceleration
- **Scalable**: Handles large point sets efficiently
- **Memory Optimized**: Minimal memory usage for grid storage
- **Real-time**: Suitable for interactive applications

## Performance Considerations

### Complexity Factors
- **Point Count**: Scales with region volume and minimum distance
- **Grid Resolution**: Affects neighbor checking efficiency
- **Max Attempts**: Higher values increase generation time
- **Distribution Type**: Some types are more computationally expensive

### Optimization Tips
- Use appropriate min_distance for your needs
- Adjust max_attempts based on desired density
- Choose distribution type based on application
- Consider LOD for distant point sets

### Memory Usage
- Scales with number of generated points
- Grid storage is minimal compared to point data
- Visualization meshes consume GPU memory
- Export data for external processing

## Use Cases

### Procedural Generation
- **Forest Generation**: Natural tree placement with proper spacing
- **City Planning**: Building and structure placement
- **Particle Systems**: Well-distributed particle effects
- **Terrain Features**: Rock and vegetation placement

### Game Development
- **Level Design**: Object placement in game levels
- **Spawn Points**: Enemy and item spawn locations
- **Environmental Effects**: Particle and effect placement
- **Architecture**: Procedural building generation

### Scientific Applications
- **Simulation**: Particle and agent placement
- **Visualization**: Data point distribution
- **Research**: Spatial distribution studies
- **Modeling**: Biological and physical systems

## Technical Implementation

### Dependencies
- **Godot 4.x**: Requires Godot 4.0 or later
- **GDScript**: Written in Godot's scripting language
- **SurfaceTool**: Uses Godot's mesh generation tools
- **Math Functions**: Utilizes trigonometric and geometric functions

### Class Structure
- **PoissonDiskSampling3D**: Core sampling algorithm
- **PoissonDiskSamplingApplications**: Practical applications
- **Grid System**: Spatial acceleration structure
- **Visualization**: Multiple display modes

### File Structure
- `PoissonDiskSampling3D.gd`: Core algorithm implementation
- `PoissonDiskSamplingApplications.gd`: Practical applications
- `PoissonDiskSampling3D.tscn`: Scene file with visualization
- `README.md`: This documentation file

## Algorithm Variations

### Distribution Modifications
- **Custom Boundaries**: User-defined boundary shapes
- **Density Functions**: Variable density across space
- **Multi-layer**: Different densities at different heights
- **Animated**: Time-varying distributions

### Performance Optimizations
- **Parallel Processing**: Multi-threaded generation
- **GPU Acceleration**: Compute shader implementation
- **Incremental Updates**: Dynamic point addition/removal
- **LOD System**: Level-of-detail for distant points

### Visualization Enhancements
- **Custom Meshes**: User-defined point representations
- **Animation**: Animated point generation
- **Particle Effects**: Particle-based visualization
- **VR Support**: Virtual reality visualization

## Future Enhancements

### Algorithm Improvements
- **Higher Dimensions**: 4D and higher sampling
- **Custom Metrics**: Non-Euclidean distance functions
- **Adaptive Density**: Dynamic density adjustment
- **Constraint Satisfaction**: Additional constraints beyond distance

### Visualization Enhancements
- **Interactive Controls**: Real-time parameter adjustment
- **Export Options**: Save point data in various formats
- **Animation**: Animated sampling process
- **VR Support**: Virtual reality interaction

### Performance Optimizations
- **GPU Implementation**: Compute shader acceleration
- **Parallel Processing**: Multi-threaded generation
- **Memory Pooling**: Reuse of point objects
- **Caching**: Cache expensive calculations

## Troubleshooting

### Common Issues
- **Empty Results**: Check min_distance and region size
- **Performance Issues**: Reduce max_attempts or region size
- **Visual Artifacts**: Check display mode and point size
- **Memory Issues**: Reduce region size or disable visualization

### Debug Tips
- Print point count and generation statistics
- Visualize grid structure for debugging
- Check boundary conditions
- Monitor performance metrics

## License

This algorithm is part of the AdaResearch project and follows the same licensing terms as the main project.
