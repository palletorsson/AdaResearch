# Optimized Three-Layer Noise Terrain System

## Overview

This optimized terrain generation system creates realistic procedural 3D terrain specifically designed for human movement and navigation. It combines three layers of noise to generate natural-looking landscapes with walkable surfaces, performance optimizations, and realistic terrain features.

## Key Features

### 🏔️ Three-Layer Noise System
- **Low Frequency (Base Terrain)**: Creates large-scale features like hills, valleys, and mountain ranges
- **Medium Frequency (Mid-scale Features)**: Adds ridges, slopes, and medium-sized formations
- **High Frequency (Surface Detail)**: Provides fine surface texture and rocky details

### 🚶 Human Movement Optimization
- **Walkable Surface Detection**: Automatically identifies surfaces suitable for human movement
- **Slope Analysis**: Configurable maximum walkable slope (default: 30°)
- **Collision Optimization**: Separate collision meshes for walkable and non-walkable areas
- **Pathfinding Support**: Built-in functions for terrain height and slope queries

### ⚡ Performance Optimizations
- **Level of Detail (LOD)**: Automatic mesh simplification based on distance
- **Chunked Processing**: Efficient memory management for large terrains
- **Collision Caching**: Optimized collision generation for walkable surfaces
- **Pre-allocated Arrays**: Reduced memory allocation during generation

### 🌍 Realistic Terrain Features
- **Erosion Simulation**: Natural weathering effects on steep terrain
- **Height-based Coloring**: Automatic terrain coloring based on elevation
- **Natural Feature Scaling**: Configurable scale for terrain features
- **Smooth Transitions**: Gradual blending between different terrain types

## Usage

### Basic Setup
```gdscript
# Add the NoiseLayers node to your scene
var terrain = preload("res://algorithms/randomness/noiselayers/noiselayers.gd").new()
add_child(terrain)

# Configure terrain parameters
terrain.terrain_size = 100
terrain.terrain_scale = 2.0
terrain.height_scale = 15.0

# Enable optimizations
terrain.enable_lod = true
terrain.enable_collision_optimization = true
terrain.enable_erosion_simulation = true
```

### Human Movement Integration
```gdscript
# Check if a position is walkable
if terrain.is_position_walkable(player_position):
    # Player can move here
    pass

# Get terrain height at specific position
var height = terrain.get_terrain_height_at_position(world_x, world_z)

# Get terrain slope for movement calculations
var slope = terrain.get_terrain_slope_at_position(world_x, world_z)

# Set player position for LOD updates
terrain.set_player_position(player_position)
```

### LOD System
```gdscript
# Get current LOD information
var lod_info = terrain.get_current_lod_info()
print("Current LOD: %d, Resolution: %d, Vertices: %d" % [
    lod_info.level, 
    lod_info.resolution, 
    lod_info.vertex_count
])

# Manually switch LOD level
terrain.switch_to_lod(2)  # Switch to LOD level 2
```

## Configuration Parameters

### Terrain Size
- `terrain_size`: Grid resolution (default: 100x100)
- `terrain_scale`: World scale multiplier (default: 1.0)
- `height_scale`: Height amplification (default: 10.0)

### Noise Layer Settings
- `low_freq_scale`: Base terrain frequency (default: 0.015)
- `low_freq_amplitude`: Base terrain amplitude (default: 12.0)
- `low_freq_octaves`: Base terrain octaves (default: 6)
- `med_freq_scale`: Mid-scale frequency (default: 0.04)
- `med_freq_amplitude`: Mid-scale amplitude (default: 6.0)
- `med_freq_octaves`: Mid-scale octaves (default: 4)
- `high_freq_scale`: Surface detail frequency (default: 0.08)
- `high_freq_amplitude`: Surface detail amplitude (default: 1.5)
- `high_freq_octaves`: Surface detail octaves (default: 3)

### Walkable Surface Settings
- `max_walkable_slope`: Maximum walkable slope in degrees (default: 30.0)
- `walkable_surface_threshold`: Minimum surface area for walkability (default: 0.7)
- `slope_smoothing`: Smoothing factor for walkable areas (default: 0.8)

### Performance Settings
- `enable_lod`: Enable Level of Detail system (default: true)
- `lod_distance_threshold`: Distance to switch to low LOD (default: 50.0)
- `chunk_size`: Size of terrain chunks for LOD (default: 32)
- `enable_collision_optimization`: Optimize collision generation (default: true)

### Terrain Quality
- `enable_erosion_simulation`: Simulate natural erosion (default: true)
- `erosion_strength`: Strength of erosion effect (default: 0.3)
- `natural_feature_scale`: Scale of natural features (default: 1.0)

## API Reference

### Core Functions
- `generate_terrain()`: Generate the terrain mesh
- `regenerate_terrain()`: Regenerate terrain with current settings
- `setup_collision()`: Setup optimized collision shapes

### Movement Functions
- `is_position_walkable(position: Vector3) -> bool`: Check if position is walkable
- `get_terrain_height_at_position(x: float, z: float) -> float`: Get height at position
- `get_terrain_slope_at_position(x: float, z: float) -> float`: Get slope at position
- `get_walkable_surfaces() -> Array`: Get walkable surface information

### LOD Functions
- `set_player_position(position: Vector3)`: Set player position for LOD
- `switch_to_lod(level: int)`: Manually switch LOD level
- `get_current_lod_info() -> Dictionary`: Get current LOD information

### Debug Functions
- `debug_terrain_info()`: Print terrain configuration
- `debug_show_walkable_areas()`: Show walkable area information

## Performance Tips

1. **Use LOD System**: Enable LOD for better performance with large terrains
2. **Optimize Collision**: Use collision optimization for better physics performance
3. **Adjust Resolution**: Lower terrain_size for better performance on weaker hardware
4. **Disable Erosion**: Turn off erosion simulation for faster generation
5. **Chunk Management**: Use appropriate chunk sizes for your use case

## Integration with Pathfinding

The terrain system provides several functions that integrate well with pathfinding systems:

```gdscript
# Example pathfinding integration
func find_path(start: Vector3, end: Vector3) -> Array:
    var path = []
    var current = start
    
    while current.distance_to(end) > 1.0:
        # Check if current position is walkable
        if not terrain.is_position_walkable(current):
            # Find alternative path
            current = find_nearest_walkable(current)
        
        # Get terrain slope for movement cost
        var slope = terrain.get_terrain_slope_at_position(current.x, current.z)
        var movement_cost = 1.0 + (slope / 30.0)  # Higher cost for steeper terrain
        
        # Continue pathfinding...
        current = get_next_path_point(current, end, movement_cost)
        path.append(current)
    
    return path
```

## Troubleshooting

### Common Issues
1. **Terrain too spiky**: Reduce `high_freq_amplitude` or increase `high_freq_octaves`
2. **Terrain too smooth**: Increase `high_freq_amplitude` or add more octaves
3. **Performance issues**: Enable LOD system and reduce `terrain_size`
4. **Collision problems**: Check `max_walkable_slope` and `slope_smoothing` settings

### Debug Commands
```gdscript
# Print terrain information
terrain.debug_terrain_info()

# Show walkable areas
terrain.debug_show_walkable_areas()

# Check LOD status
var lod_info = terrain.get_current_lod_info()
print("LOD Level: %d" % lod_info.level)
```

## Future Enhancements

- **Water Simulation**: Add rivers, lakes, and water bodies
- **Vegetation Placement**: Automatic tree and grass placement
- **Weather Effects**: Dynamic terrain changes based on weather
- **Multi-threading**: Parallel terrain generation for better performance
- **GPU Acceleration**: Use compute shaders for noise generation

## License

This terrain system is part of the AdaResearch project and follows the same licensing terms.
