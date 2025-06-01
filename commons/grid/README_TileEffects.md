# Tile Effect System

A comprehensive tile-based visual effect system for Godot VR projects that provides gradual map revelation, disco effects, and other dynamic tile animations.

## Overview

The tile effect system consists of several components:

- **TileEffectManager.gd** - Core tile effect management and rendering
- **GridSystem.gd** - Integration with existing grid system  
- **TileEffectController.gd** - User-friendly controller for testing and interaction
- **TileEffectExample.gd** - Example scripts and patterns

## Features

### ✨ Effects Available

1. **Gradual Reveal** - Tiles appear in expanding circles from a center point
2. **Disco Tiles** - Colorful wave patterns with cycling colors
3. **Instant Show/Hide** - Toggle all tiles on/off
4. **Custom Patterns** - Programmable reveal sequences

### 🎮 Grid as Arrays

The system represents the grid as a 3D array structure:
```gdscript
grid[x][y][z] = tile_data
```

Where each tile contains:
- Position (Vector3i)
- Reveal state (bool)
- Effect type (enum)
- Color information
- Visual mesh and material

## Quick Start

### 1. Enable in Existing Scene

Add to your grid-based scene:

```gdscript
# In your GridSystem configuration
enable_tile_effects = true
auto_reveal_on_entry = true
```

### 2. Basic Usage

```gdscript
# Get reference to grid system
var grid_system = get_node("multiLayerGrid")

# Start reveal effect from center
grid_system.start_tile_reveal()

# Start disco effect
grid_system.start_disco_tiles()

# Show all tiles instantly
grid_system.reveal_all_tiles()

# Hide all tiles
grid_system.hide_all_tiles()
```

### 3. Advanced Patterns

```gdscript
# Reveal from specific position
grid_system.start_tile_reveal(Vector3i(5, 0, 5))

# Get grid data as arrays
var grid_array = grid_system.get_tile_grid_as_array()
print("Grid structure: ", grid_array)

# Get grid description
var description = grid_system.get_tile_grid_description()
print(description)
```

## Controls

### Keyboard Controls (when TileEffectController is active)

- **R** - Start reveal effect
- **D** - Start disco effect  
- **S** - Stop all effects
- **A** - Show all tiles
- **H** - Hide all tiles

### Number Key Examples (with TileEffectExample)

- **1** - Center reveal
- **2** - Corner reveal
- **3** - Disco effect
- **4** - Progressive reveal pattern
- **5** - Show all
- **6** - Hide all
- **0** - Stop effects

## Grid Array Structure

The grid is structured as a 3D array accessible through:

```gdscript
# Get full grid data
var grid_data = grid_system.get_tile_grid_as_array()

# Structure: grid_data[x][y][z] = {
#   "position": Vector3i,
#   "is_revealed": bool,
#   "effect_type": int,
#   "color": Color
# }

# Example: Access tile at position (2, 0, 3)
var tile_info = grid_data[2][0][3]
print("Tile revealed: ", tile_info.is_revealed)
```

## Configuration Options

### TileEffectManager Properties

```gdscript
@export var tile_size: float = 1.0        # Size of each tile
@export var reveal_speed: float = 2.0     # Speed of reveal animation
@export var disco_speed: float = 3.0      # Speed of disco effects
@export var disco_intensity: float = 1.0  # Intensity of disco colors
```

### GridSystem Properties

```gdscript
@export var enable_tile_effects: bool = true      # Enable the tile system
@export var auto_reveal_on_entry: bool = true     # Auto-reveal on map load
```

### TileEffectController Properties

```gdscript
@export var reveal_on_start: bool = false         # Start with reveal effect
@export var disco_on_start: bool = false          # Start with disco effect
@export var enable_keyboard_controls: bool = true # Enable keyboard input
@export var show_debug_info: bool = false         # Show debug overlay
```

## Integration with Existing Maps

### Method 1: Automatic Integration

The system automatically integrates with existing `GridSystem1` instances:

1. Set `enable_tile_effects = true` in your grid system
2. Add a `TileEffectController` node to your scene
3. Set the `grid_system_path` to point to your grid system

### Method 2: Manual Integration

```gdscript
# In your existing script
var tile_effect_manager = TileEffectManager.new()
add_child(tile_effect_manager)
tile_effect_manager.initialize(your_grid_system)

# Control effects
tile_effect_manager.start_reveal_effect(Vector3i(5, 0, 5))
tile_effect_manager.start_disco_effect()
```

## Creating Custom Effects

### Define New Effect Types

```gdscript
# In TileEffectManager.gd, add to EffectType enum:
enum EffectType {
    NONE,
    REVEAL,
    DISCO,
    FADE_IN,
    FADE_OUT,
    PULSE,
    WAVE,
    YOUR_CUSTOM_EFFECT  # Add here
}
```

### Implement Effect Logic

```gdscript
# Add to _update_tile_material() method:
EffectType.YOUR_CUSTOM_EFFECT:
    # Your custom effect logic here
    if tile.is_revealed:
        # Update tile appearance
        tile.material.set_shader_parameter("alpha", your_alpha_value)
        tile.material.set_shader_parameter("base_color", your_color)
```

## Performance Considerations

- **Tile Count**: System handles grids up to ~50x50 efficiently
- **Effect Updates**: Uses delta-time based updates for smooth animation
- **Memory Usage**: Each tile stores minimal data (position, state, material reference)
- **Rendering**: Uses instanced materials for efficient GPU usage

## Troubleshooting

### Tiles Not Appearing

1. Check `enable_tile_effects = true` in GridSystem
2. Verify grid dimensions are set correctly
3. Ensure materials are created properly

### Performance Issues

1. Reduce grid size for large grids
2. Adjust `reveal_speed` and `disco_speed` values
3. Disable debug info display

### No Keyboard Response

1. Verify `enable_keyboard_controls = true` in TileEffectController
2. Check that TileEffectController is in the scene tree
3. Ensure `grid_system_path` is correctly set

## Example Scene Setup

```
Main Scene
├── GridSystem (multiLayerGrid)
│   ├── enable_tile_effects = true
│   └── auto_reveal_on_entry = true
├── TileEffectController
│   ├── grid_system_path = "../multiLayerGrid" 
│   ├── show_debug_info = true
│   └── enable_keyboard_controls = true
└── (other scene components)
```

## API Reference

### GridSystem1 Methods

```gdscript
start_tile_reveal(center_position: Vector3i = Vector3i(-1, -1, -1))
start_disco_tiles()
stop_tile_effects()
reveal_all_tiles()
hide_all_tiles()
get_tile_grid_description() -> String
get_tile_grid_as_array() -> Array
```

### TileEffectManager Methods

```gdscript
initialize(grid_ref: GridSystem1)
start_reveal_effect(center_pos: Vector3i)
start_disco_effect()
stop_all_effects()
reveal_all_tiles()
hide_all_tiles()
get_tile_at(pos: Vector3i) -> TileData
get_grid_as_array() -> Array
describe_grid() -> String
```

### TileEffectController Methods

```gdscript
start_reveal_effect(center_pos: Vector3i = Vector3i(-1, -1, -1))
start_disco_effect()
stop_all_effects()
reveal_all_tiles()
hide_all_tiles()
set_grid_system(new_grid_system: GridSystem1)
get_grid_array() -> Array
describe_grid() -> String
```

## License

This tile effect system is part of the godot-xr-tools-ada project and follows the same licensing terms. 