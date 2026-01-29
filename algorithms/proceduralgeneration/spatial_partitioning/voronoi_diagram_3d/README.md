# 3D Voronoi Diagram System

A comprehensive 3D Voronoi Diagram implementation for procedural generation, featuring multiple structure types, seed distribution methods, and practical applications for caves, buildings, and organic structures.

## Overview

The `VoronoiDiagram3D` class generates complex 3D cellular structures using Voronoi diagrams, where space is divided into regions based on proximity to seed points. This creates natural-looking cellular patterns that can be used for various procedural generation applications.

## Features

### Core Algorithm
- **3D Voronoi Generation**: Complete 3D Voronoi diagram implementation
- **Multiple Seed Distributions**: Random, Grid, Poisson, Spherical, and Layered patterns
- **Lloyd's Relaxation**: Iterative optimization for more uniform cell sizes
- **Adaptive Resolution**: Dynamic resolution based on complexity
- **Convex Hull Generation**: Simplified convex hull for cell geometry

### Structure Types
- **Cells**: Solid Voronoi cells with optional hollow interiors
- **Honeycomb**: Cell walls only, creating honeycomb-like structures
- **Crystal**: Sharp, geometric faceted crystal structures
- **Foam**: Rounded, bubble-like organic cells
- **Organic**: Irregular, natural-looking structures with noise
- **Architectural**: Building-like structured forms with pillars

### Visualization Options
- **Multiple Display Modes**: Solid, Wireframe, Points, Dual, Mixed
- **Color Coding**: Distance-based or custom color schemes
- **Seed Visualization**: Optional display of seed points
- **Real-time Generation**: Live updates in the Godot editor

### Advanced Features
- **Jitter Control**: Add randomness to grid distributions
- **Noise Influence**: Organic deformation of cell boundaries
- **Export Functionality**: Export cell data for analysis
- **Performance Optimization**: Efficient grid-based neighbor finding

## Parameters

### Voronoi Settings
- **Region Size**: 3D bounding box for the Voronoi diagram (default: Vector3(10, 10, 10))
- **Number of Seeds**: Total number of seed points (default: 20)
- **Seed Value**: Random seed for reproducible results (default: 0)
- **Seed Distribution**: Method for distributing seeds (Random, Grid, Poisson, Spherical, Layered)

### Structure Type
- **Structure Type**: Type of generated structure (Cells, Honeycomb, Crystal, Foam, Organic, Architectural)
- **Cell Wall Thickness**: Thickness of cell boundaries (default: 0.1)
- **Hollow Cells**: Whether to create hollow or solid cells (default: true)

### Visualization
- **Display Mode**: How to render the structure (Solid, Wireframe, Points, Dual, Mixed)
- **Show Seeds**: Display seed points as spheres (default: true)
- **Color by Distance**: Use distance-based coloring (default: true)
- **Base Color**: Default color for cells (default: Color(0.7, 0.7, 0.9))

### Resolution
- **Resolution**: Grid resolution for cell generation (8-64, default: 24)
- **Adaptive Resolution**: Automatically adjust resolution based on complexity (default: false)

### Advanced
- **Jitter Amount**: Random offset for grid distributions (default: 0.0)
- **Relaxation Iterations**: Number of Lloyd's relaxation iterations (default: 0)
- **Noise Influence**: Amount of noise applied to organic structures (default: 0.0)

## Algorithm Details

### Voronoi Cell Generation
1. **Seed Generation**: Create seed points using selected distribution method
2. **Grid Sampling**: Sample 3D grid to find cell boundaries
3. **Boundary Detection**: Identify points near cell boundaries
4. **Convex Hull**: Generate simplified convex hull for each cell
5. **Property Calculation**: Calculate cell volume, center, and color

### Seed Distribution Methods

#### Random Distribution
- Points randomly placed within the region
- Uniform probability distribution
- Good for organic, irregular patterns

#### Grid Distribution
- Points placed on regular 3D grid
- Optional jitter for variation
- Good for structured, regular patterns

#### Poisson Disk Sampling
- Points placed with minimum distance constraint
- More natural distribution than random
- Good for avoiding clustering

#### Spherical Distribution
- Points distributed in spherical volume
- Concentrated near center
- Good for radial patterns

#### Layered Distribution
- Points distributed in horizontal layers
- Good for architectural applications
- Supports multi-story structures

### Structure Generation

#### Cell Structure
- **Solid Cells**: Complete 3D meshes for each cell
- **Hollow Cells**: Only cell boundaries, no interior
- **Material Properties**: Configurable materials and colors

#### Honeycomb Structure
- **Wall Generation**: Only cell boundaries drawn
- **Neighbor Detection**: Walls between adjacent cells
- **Thickness Control**: Configurable wall thickness

#### Crystal Structure
- **Sharp Geometry**: Elongated, faceted shapes
- **Apex Generation**: Sharp points extending upward
- **Transparent Materials**: Glass-like appearance

#### Foam Structure
- **Bubble-like Cells**: Spherical approximations
- **Volume-based Sizing**: Cell size based on volume
- **Organic Materials**: Soft, rounded appearance

#### Organic Structure
- **Noise Deformation**: Perlin noise applied to vertices
- **Irregular Shapes**: Natural, non-geometric forms
- **Varied Materials**: Earthy, natural colors

#### Architectural Structure
- **Building-like Forms**: Structured, architectural appearance
- **Pillar Generation**: Lower cells become support pillars
- **Multi-story Support**: Layered distribution support

## Usage

### Basic Usage
```gdscript
# Create a VoronoiDiagram3D instance
var voronoi = VoronoiDiagram3D.new()
add_child(voronoi)

# Configure basic parameters
voronoi.region_size = Vector3(15, 15, 15)
voronoi.num_seeds = 30
voronoi.structure_type = 0  # Cells
voronoi.seed_distribution = 0  # Random

# Generate structure
voronoi.generate_voronoi_structure()
```

### Different Structure Types
```gdscript
# Crystal structure
voronoi.structure_type = 2  # Crystal
voronoi.seed_distribution = 0  # Random
voronoi.region_size = Vector3(8, 8, 8)

# Organic structure
voronoi.structure_type = 4  # Organic
voronoi.noise_influence = 0.3
voronoi.seed_distribution = 2  # Poisson

# Architectural structure
voronoi.structure_type = 5  # Architectural
voronoi.seed_distribution = 4  # Layered
voronoi.region_size = Vector3(20, 12, 20)
```

### Advanced Configuration
```gdscript
# High-resolution with relaxation
voronoi.resolution = 32
voronoi.relaxation_iterations = 3
voronoi.adaptive_resolution = true

# Organic with noise
voronoi.structure_type = 4  # Organic
voronoi.noise_influence = 0.5
voronoi.jitter_amount = 0.2

# Custom colors
voronoi.color_by_distance = false
voronoi.base_color = Color(0.8, 0.6, 0.4)
```

## Applications

### Cave Systems
- **Chamber Generation**: Voronoi cells as cave chambers
- **Tunnel Connections**: Walls between cells as tunnels
- **Organic Appearance**: Noise-based deformation
- **Configurable Density**: Control number of chambers

### Building Interiors
- **Room Generation**: Cells as individual rooms
- **Layered Distribution**: Multi-story buildings
- **Architectural Elements**: Pillars and structural support
- **Wall Thickness**: Configurable room boundaries

### Fractured Objects
- **Shattered Geometry**: Crystal structure for fractures
- **Random Distribution**: Irregular fracture patterns
- **Sharp Edges**: Geometric fracture lines
- **Transparent Materials**: Glass-like appearance

### Coral Reefs
- **Foam Structure**: Bubble-like organic forms
- **Spherical Distribution**: Natural growth patterns
- **Organic Materials**: Soft, rounded appearance
- **Varied Sizing**: Different cell sizes

### Rock Formations
- **Organic Structure**: Natural, irregular shapes
- **Noise Deformation**: Realistic surface variation
- **Relaxation**: More uniform cell sizes
- **Earthy Materials**: Natural rock colors

## Performance Considerations

### Complexity Factors
- **Resolution**: Higher resolution increases computation time
- **Number of Seeds**: More seeds create more complex structures
- **Relaxation Iterations**: Lloyd's relaxation adds computation
- **Structure Type**: Some types are more expensive to generate

### Optimization Tips
- Use appropriate resolution for your needs
- Limit relaxation iterations for real-time generation
- Consider structure type complexity
- Use adaptive resolution for dynamic complexity

### Memory Usage
- Scales with resolution and number of seeds
- Each cell stores vertices, faces, and properties
- Visualization meshes consume GPU memory
- Export data can be large for complex structures

## Technical Implementation

### Dependencies
- **Godot 4.x**: Requires Godot 4.0 or later
- **GDScript**: Written in Godot's scripting language
- **SurfaceTool**: Uses Godot's mesh generation tools
- **Math Functions**: Geometric and trigonometric calculations

### Class Structure
- **VoronoiCell**: Internal class for individual cells
- **VoronoiDiagram3D**: Main algorithm implementation
- **VoronoiApplications**: Practical application examples
- **Visualization**: Separate methods for different display modes

### File Structure
- `VoronoiDiagram3D.gd`: Main algorithm implementation
- `VoronoiApplications.gd`: Practical application examples
- `VoronoiDiagram3D.tscn`: Scene file with visualization
- `README.md`: This documentation file

## Customization

### Adding New Structure Types
1. Add new enum value to `structure_type`
2. Implement new build function (e.g., `build_new_type()`)
3. Add case to `build_structure()` switch statement
4. Create appropriate mesh generation function

### Custom Seed Distributions
1. Add new enum value to `seed_distribution`
2. Implement new distribution function
3. Add case to `generate_seeds()` switch statement
4. Consider performance implications

### Material Customization
- Modify material properties in mesh creation functions
- Add texture support for different structure types
- Implement dynamic material generation
- Consider PBR materials for realistic rendering

## Troubleshooting

### Common Issues
- **Empty Cells**: Check seed distribution and region size
- **Performance Issues**: Reduce resolution or number of seeds
- **Incorrect Geometry**: Verify boundary detection logic
- **Memory Issues**: Reduce resolution or limit cell count

### Debug Tips
- Enable seed visualization to verify distribution
- Print cell data to check generation
- Use wireframe mode to inspect geometry
- Monitor performance metrics

## Future Enhancements

### Algorithm Improvements
- **3D Delaunay Triangulation**: More accurate cell boundaries
- **Multi-scale Voronoi**: Different cell sizes in same structure
- **Dynamic Generation**: Real-time structure modification
- **GPU Acceleration**: Compute shader implementation

### Visual Enhancements
- **Advanced Materials**: PBR materials with textures
- **Particle Effects**: Growth and generation effects
- **Animation**: Animated structure generation
- **VR Support**: Virtual reality interaction

### Performance Optimizations
- **LOD System**: Level-of-detail for distant structures
- **Instancing**: Efficient rendering of multiple structures
- **Caching**: Cache generated meshes
- **Parallel Processing**: Multi-threaded generation

## License

This algorithm is part of the AdaResearch project and follows the same licensing terms as the main project.
