# Unified Landscape Cave Generator

This implementation provides a single, comprehensive marching cubes system that generates both landscapes and cave systems in a unified approach, inspired by Unity's mesh generation patterns but optimized for GDScript.

## Features

### Core Capabilities
- **Unified Generation**: Single algorithm generates both terrain surfaces and cave systems
- **Chunk-Based System**: Efficient memory management with LOD support
- **Real-time Collision**: Automatic collision shape generation
- **Interactive Parameters**: Real-time parameter adjustment with UI controls
- **Seamless Boundaries**: Proper chunk boundary handling prevents holes

### Landscape Generation
- **Multi-octave Noise**: Layered terrain with configurable height variation
- **Smooth Surfaces**: Proper normal calculation and surface interpolation
- **Material Support**: Customizable terrain materials with variety

### Cave System
- **3D Cave Networks**: Full 3D cave systems with multiple chambers
- **Vertical Control**: Configurable cave height ranges
- **Organic Shapes**: Multiple noise layers for natural cave formations
- **Integration**: Caves carve through terrain naturally

## Usage

### Basic Setup
1. Add `LandscapeCaveGenerator` node to your scene
2. Configure parameters in the inspector
3. Set `auto_update_in_game = true` or call `generate_world()` manually

### Key Parameters

#### World Configuration
- `num_chunks`: Grid size for fixed worlds (Vector3i)
- `bounds_size`: Size of each chunk in world units
- `num_points_per_axis`: Voxel resolution per chunk (higher = more detailed)

#### Terrain Parameters
- `terrain_height`: Maximum height variation
- `terrain_noise_frequency`: Base frequency for terrain noise
- `terrain_octaves`: Number of noise layers for detail

#### Cave Parameters
- `cave_density`: How much of the terrain becomes caves (0.0-1.0)
- `cave_noise_frequency`: Base frequency for cave generation
- `cave_min_height`/`cave_max_height`: Vertical range for caves
- `cave_vertical_bias`: Preference for horizontal vs vertical caves

### Interactive Controls
- **R Key**: Regenerate world with new random seed
- **UI Sliders**: Real-time parameter adjustment
- **Camera**: WASD movement, mouse look

## Technical Implementation

### Architecture
```
LandscapeCaveGenerator (Main Node)
├── Noise Generators (Terrain + Cave)
├── Chunk Management System
├── Marching Cubes Implementation
├── Density Field Calculation
└── Mesh & Collision Generation
```

### Density Field Calculation
The core innovation is the unified density field that combines:
1. **Terrain Surface**: Distance-based density from noise-generated height
2. **Cave System**: Subtractive density that carves cave spaces
3. **Smooth Blending**: Proper transitions between materials

### Marching Cubes Algorithm
- **Complete Lookup Tables**: 256 cube configurations with proper triangulation
- **Edge Interpolation**: Smooth surface generation with iso-level interpolation
- **Chunk Boundaries**: Seamless generation across chunk borders

### Performance Optimizations
- **Async Generation**: Non-blocking world generation with frame yields
- **Chunk Recycling**: Memory-efficient chunk reuse for infinite worlds
- **LOD Support**: Distance-based chunk management
- **Collision Caching**: Efficient collision shape generation

## Comparison with Unity Reference

### Similarities
- **Chunk-based approach**: Both use spatial partitioning for efficiency
- **Density field generation**: Similar approach to 3D scalar field creation
- **Marching cubes core**: Same fundamental algorithm
- **Parameter flexibility**: Real-time parameter adjustment

### GDScript Advantages
- **Built-in async/await**: Cleaner non-blocking generation
- **Integrated scene system**: Direct node hierarchy management
- **Signal system**: Elegant event-driven architecture
- **FastNoiseLite integration**: High-quality noise generation

### Key Differences
- **Unified approach**: Single generator handles both terrain and caves
- **Simplified API**: More straightforward parameter management
- **VR-ready**: Designed for spatial computing applications

## Advanced Usage

### Custom Materials
```gdscript
# Set custom terrain material
var material = StandardMaterial3D.new()
material.albedo_color = Color.GREEN
generator.terrain_material = material
```

### Parameter Animation
```gdscript
# Animate cave density over time
func _process(delta):
    generator.cave_density = 0.3 + sin(Time.get_time()) * 0.2
```

### Infinite Worlds
```gdscript
# Set up infinite world generation
generator.fixed_map_size = false
generator.viewer = $Player  # Reference to player node
generator.viewer_distance = 100.0
```

### Performance Tuning
```gdscript
# High detail
generator.num_points_per_axis = 32
generator.bounds_size = 20.0

# Performance mode
generator.num_points_per_axis = 16
generator.bounds_size = 40.0
```

## Scene Files

### Demo Scene: `landscape_cave_demo.tscn`
Complete demonstration with:
- Pre-configured generator
- Interactive UI controls
- Proper lighting and environment
- Example parameter settings

### Test Scenes
- `test_terrain_only.tscn`: Terrain generation only
- `test_caves_only.tscn`: Cave system only
- `test_performance.tscn`: Performance benchmarking

## Integration Guide

### Adding to Existing Projects
1. Copy the core files:
   - `LandscapeCaveGenerator.gd`
   - `MarchingCubesLookupTables.gd`
2. Add generator node to your scene
3. Configure parameters for your world size
4. Optionally add UI controls for parameter adjustment

### VR Integration
The system is designed for VR applications:
- Efficient collision generation for teleportation
- Chunk-based LOD for performance
- Spatial audio considerations in cave systems

### Multiplayer Considerations
- Deterministic generation with seed control
- Chunk-based networking for shared worlds
- Parameter synchronization for real-time collaboration

## Troubleshooting

### Common Issues

**No geometry generated**
- Check that iso_level is appropriate (0.5 typically works)
- Ensure terrain_height and cave_density create crossing surfaces
- Verify chunk bounds contain the expected density variations

**Performance issues**
- Reduce num_points_per_axis for better performance
- Increase bounds_size to reduce chunk count
- Use fixed_map_size for smaller worlds

**Holes in mesh**
- Check chunk boundary handling
- Ensure proper density field continuity
- Verify marching cubes table completeness

**Cave systems not appearing**
- Adjust cave_min_height and cave_max_height ranges
- Increase cave_density parameter
- Check cave_noise_frequency for appropriate scale

### Debug Tools
- Enable `show_wireframe` to visualize mesh structure
- Use `show_bounds_gizmo` to see chunk boundaries
- Check console for generation statistics

## Future Enhancements

### Planned Features
- **Texture splatting**: Multi-texture terrain materials
- **Cave decorations**: Stalactites, stalagmites, formations
- **Water systems**: Underground lakes and streams
- **Lighting integration**: Dynamic cave lighting
- **Biome support**: Different terrain/cave types

### Performance Improvements
- **GPU compute shaders**: Hardware-accelerated generation
- **Mesh simplification**: LOD-based geometry reduction
- **Streaming**: Background chunk generation

This implementation represents a significant advancement in procedural world generation for Godot, combining the power of marching cubes with modern spatial computing requirements.
