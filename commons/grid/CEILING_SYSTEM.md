# Grid Ceiling System

Procedural suspended ceiling generator with acoustic tiles and integrated fluorescent lighting.

## Overview

The `GridCeilingComponent` creates institutional-style drop ceilings with:
- Square acoustic tile panels (50×50cm)
- Exposed metal T-grid structure
- Integrated recessed fluorescent/LED light panels
- Evenly diffused, institutional lighting atmosphere
- Subtle flickering effects on select lights for realism

## Architecture

**Type**: Suspended (drop) ceiling system
**Structure**: Exposed metal T-grid holding panels in place
**Modules**: Square/rectangular panels (acoustic tiles)
**Lighting**: Recessed fluorescent/LED troffers flush with ceiling grid
**Materials**:
- Mineral fiber acoustic tiles
- Light gray metal T-grid
- Emissive light panels with OmniLight3D sources

## Usage

### Map Data Configuration

Add ceiling configuration to your map's `settings` section:

```json
{
  "settings": {
    "ceiling": {
      "height": 4.0,
      "tile_size": 0.5,
      "light_spacing": 2,
      "light_intensity": 1.5,
      "preset": "laboratory"
    }
  }
}
```

### Configuration Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `height` | float | 4.0 | Height of ceiling from floor (meters) |
| `tile_size` | float | 0.5 | Size of each tile (0.5 = 50cm) |
| `light_spacing` | int | 2 | Place light panel every N tiles |
| `light_intensity` | float | 1.5 | Brightness of light panels |
| `preset` | string | "" | Quick preset configurations |

### Preset Configurations

**institutional** (default)
- Height: 4.0m
- Light spacing: Every 2 tiles
- Light intensity: 1.5

**laboratory**
- Height: 4.5m
- Light spacing: Every tile
- Light intensity: 2.0 (brighter)

**office**
- Height: 3.5m
- Light spacing: Every 2 tiles
- Light intensity: 1.2 (softer)

**warehouse**
- Height: 6.0m
- Light spacing: Every 3 tiles
- Light intensity: 1.8

## Components

### Acoustic Tiles
- **Material**: Off-white matte finish (Color: 0.92, 0.92, 0.90)
- **Surface**: Non-reflective, sound-absorbing aesthetic
- **Slight random variation** in scale for realism (0.998-1.002)

### T-Grid Structure
- **Material**: Light gray metal (Color: 0.7, 0.7, 0.7)
- **Finish**: Semi-metallic with moderate roughness
- **Thickness**: 2cm beams creating grid pattern

### Light Panels
- **Emissive material** with cool fluorescent color (0.95, 0.95, 1.0)
- **OmniLight3D** positioned below each panel
- **Soft falloff** for diffused lighting effect
- **10% of lights** have subtle flicker effect (3-8 second intervals)

## API

### GridCeilingComponent Methods

```gdscript
# Generate ceiling for current map
ceiling_component.generate_ceiling(config: Dictionary)

# Clear all ceiling elements
ceiling_component.clear_ceiling()

# Dynamically adjust lighting
ceiling_component.set_light_intensity(1.8)
ceiling_component.set_light_color(Color(1.0, 0.95, 0.9))

# Get ceiling info
var info = ceiling_component.get_ceiling_info()
# Returns: { height, tile_size, tile_count, light_count, light_spacing }
```

### GridSystem Integration

```gdscript
# Access ceiling component
var ceiling = grid_system.get_ceiling_component()

# Check ceiling status in map info
var map_info = grid_system.get_current_map_info()
print(map_info.objects.ceiling_tiles)  # Tile count
print(map_info.objects.ceiling_lights)  # Light count
```

## Visual Design

The ceiling system creates:
- **Geometry of repetition** that flattens spatial sense
- **Institutional atmosphere** through uniform lighting
- **Suspended reality** with visible drop structure
- **Liminal aesthetic** through endless grid pattern

## Performance Notes

- Ceiling generates **after** structure, utilities, and interactables
- Each light panel contains 1 OmniLight3D (consider for performance)
- For large spaces (>100 tiles), consider:
  - Increasing `light_spacing` to reduce light count
  - Using lower `light_intensity` with more spacing
  - Baking lighting for static scenes

## Examples

### Minimal Ceiling
```json
"ceiling": {
  "preset": "office"
}
```

### Custom High-Intensity Lab
```json
"ceiling": {
  "height": 5.0,
  "tile_size": 0.6,
  "light_spacing": 1,
  "light_intensity": 2.2
}
```

### Warehouse Storage
```json
"ceiling": {
  "height": 8.0,
  "light_spacing": 4,
  "light_intensity": 1.6,
  "preset": "warehouse"
}
```

## Signals

```gdscript
signal ceiling_generation_complete(tile_count: int, light_count: int)
```

Emitted when ceiling generation finishes, allowing other systems to respond.

## Future Enhancements

Potential additions:
- Damaged/missing tile variations
- Exposed wiring/ductwork option
- Color-tinted lighting modes
- Dynamic shadows from tiles
- Ventilation grate tiles
- Sagging ceiling sections
- Emergency lighting mode
