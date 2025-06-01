# Tile Effect Triggers - JSON Configuration System

A modular system for triggering tile effects through interactive elements placed on tiles, configured entirely through JSON map data.

## Overview

The Tile Effect Trigger system allows you to place interactive trigger tiles in your maps that activate various tile effects when players step on them, grab them, or click them. All configuration is done through JSON, making it easy to create and modify effect triggers without code changes.

## Key Features

### ✨ Trigger Types Available

- **step_on** - Activate when player walks onto the tile (default)
- **grab** - Activate when player grabs the trigger (VR)
- **click** - Activate when player clicks/points at the trigger

### 🎨 Effect Types Available

- **disco** - Colorful disco effect across all tiles
- **reveal** - Gradually reveal tiles from trigger position outward
- **wave** - Wave effect expanding from trigger position
- **pulse** - Pulsing effect that shows and hides tiles
- **show_all** - Instantly show all tiles
- **hide_all** - Hide all tiles
- **stop** - Stop all current tile effects
- **custom** - Custom effects (extensible)

### 🎯 Visual Feedback

- Color-coded trigger tiles based on effect type
- Animated glow indicators
- Visual feedback when triggered
- Debug information overlay

## Quick Start

### 1. Basic Usage in JSON Map

Add tile effect triggers to your map's `interactables` layer:

```json
{
  "layers": {
    "interactables": [
      [" ", " ", " ", " ", " "],
      [" ", "trigger:disco", " ", "trigger:reveal", " "],
      [" ", " ", " ", " ", " "],
      [" ", "trigger:wave", " ", "trigger:pulse", " "],
      [" ", " ", " ", " ", " "]
    ]
  }
}
```

### 2. Define Trigger Effects

Configure the triggers in `tile_effect_definitions`:

```json
{
  "tile_effect_definitions": {
    "disco": {
      "description": "Colorful disco ball effect",
      "effect_type": "disco",
      "trigger_method": "step_on",
      "color": [1.0, 0.0, 1.0],
      "glow_intensity": 1.5
    },
    "reveal": {
      "description": "Gradually reveal tiles outward",
      "effect_type": "reveal",
      "trigger_method": "step_on",
      "effect_radius": 8,
      "color": [0.0, 1.0, 0.0]
    }
  }
}
```

### 3. Enable in Grid System

Make sure tile effects are enabled in your map settings:

```json
{
  "settings": {
    "enable_tile_effects": true,
    "auto_reveal_on_entry": false
  }
}
```

## Complete JSON Configuration

### Interactables Layer Format

Use the `trigger:` prefix followed by the effect name:

```json
"interactables": [
  ["trigger:disco", "trigger:reveal", "trigger:wave"],
  ["trigger:pulse", "trigger:show_all", "trigger:hide_all"],
  ["trigger:stop", "trigger:custom_effect", " "]
]
```

### Tile Effect Definitions

Full configuration options for each trigger:

```json
"tile_effect_definitions": {
  "effect_name": {
    "description": "Human readable description",
    "effect_type": "disco|reveal|wave|pulse|show_all|hide_all|stop|custom",
    "trigger_method": "step_on|grab|click",
    "effect_radius": 5,
    "effect_center": [4, 0, 4],
    "one_time_trigger": false,
    "trigger_delay": 0.0,
    "color": [1.0, 0.0, 1.0],
    "glow_intensity": 1.0,
    "audio_effect": "sound_file_path",
    "pattern": "circle|spiral|square",
    "speed": 1.5,
    "colors": [[1,0,0], [0,1,0], [0,0,1]]
  }
}
```

### Configuration Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `description` | String | "" | Human-readable description |
| `effect_type` | String | "disco" | Type of effect to trigger |
| `trigger_method` | String | "step_on" | How the trigger is activated |
| `effect_radius` | Integer | 5 | Radius for area effects |
| `effect_center` | Array | auto | Override center position [x,y,z] |
| `one_time_trigger` | Boolean | false | Trigger only once |
| `trigger_delay` | Float | 0.0 | Delay before effect starts |
| `color` | Array | [1,0,1] | RGB color of trigger tile |
| `glow_intensity` | Float | 1.0 | Intensity of glow effect |
| `audio_effect` | String | "" | Path to audio file |
| `pattern` | String | "circle" | Pattern for custom effects |
| `speed` | Float | 1.0 | Speed of animated effects |
| `colors` | Array | [] | Array of colors for custom effects |

## Example Maps

### Simple Demo Map

```json
{
  "map_info": {
    "name": "TileEffects_Demo",
    "description": "Step on colored tiles to trigger effects"
  },
  "layers": {
    "structure": [
      ["1", "1", "1", "1", "1"],
      ["1", " ", " ", " ", "1"],
      ["1", " ", "2", " ", "1"],
      ["1", " ", " ", " ", "1"],
      ["1", "1", "1", "1", "1"]
    ],
    "interactables": [
      [" ", " ", " ", " ", " "],
      [" ", "trigger:disco", " ", "trigger:reveal", " "],
      [" ", " ", " ", " ", " "],
      [" ", "trigger:stop", " ", "trigger:reset", " "],
      [" ", " ", " ", " ", " "]
    ]
  },
  "tile_effect_definitions": {
    "disco": {
      "description": "Disco ball effect",
      "effect_type": "disco",
      "color": [1.0, 0.0, 1.0],
      "glow_intensity": 2.0
    },
    "reveal": {
      "description": "Reveal tiles from here",
      "effect_type": "reveal",
      "effect_radius": 6,
      "color": [0.0, 1.0, 0.0]
    },
    "stop": {
      "description": "Stop all effects",
      "effect_type": "stop",
      "color": [1.0, 0.2, 0.2]
    },
    "reset": {
      "description": "Hide all tiles to reset",
      "effect_type": "hide_all",
      "color": [0.5, 0.5, 0.5]
    }
  }
}
```

### Advanced Configuration

```json
"tile_effect_definitions": {
  "wave_effect": {
    "description": "Wave expanding from center",
    "effect_type": "wave",
    "trigger_method": "step_on",
    "effect_radius": 8,
    "effect_center": [5, 0, 5],
    "trigger_delay": 0.5,
    "color": [0.0, 0.5, 1.0],
    "glow_intensity": 1.5,
    "pattern": "circle",
    "speed": 2.0
  },
  "one_time_reveal": {
    "description": "One-time reveal effect",
    "effect_type": "reveal",
    "one_time_trigger": true,
    "effect_radius": 10,
    "color": [1.0, 1.0, 0.0],
    "glow_intensity": 3.0
  },
  "grab_disco": {
    "description": "Grab to activate disco",
    "effect_type": "disco",
    "trigger_method": "grab",
    "color": [1.0, 0.5, 0.0]
  }
}
```

## Implementation Details

### System Components

1. **TileEffectTrigger.gd** - Individual trigger behavior
2. **GridInteractableHandler.gd** - Detects and places triggers from JSON
3. **TileEffectController.gd** - Manages all triggers and provides debug info
4. **JSON Map Format** - Configuration in map_data.json files

### Trigger Detection

The system automatically detects `trigger:` prefixed entries in the interactables layer:

```
"trigger:disco" → Creates TileEffectTrigger with effect_type="disco"
"trigger:reveal" → Creates TileEffectTrigger with effect_type="reveal"
```

### Visual Appearance

- Triggers appear as colored tiles slightly above the grid surface
- Color is based on the `color` parameter in the definition
- Glow effect indicates trigger state (active/inactive)
- Animated indicator shows trigger is ready

### Placement Logic

1. Triggers are placed on top of existing structures
2. If utilities exist at the position, triggers go above them
3. Position is calculated using grid-to-world conversion
4. Collision detection handles step-on triggers

## Advanced Usage

### Custom Effects

Create custom effects by extending the TileEffectTrigger:

```json
"custom_spiral": {
  "description": "Spiral reveal pattern",
  "effect_type": "custom",
  "pattern": "spiral",
  "speed": 1.5,
  "colors": [[1,0,0], [0,1,0], [0,0,1]],
  "effect_radius": 8
}
```

### Programmatic Control

Access triggers programmatically:

```gdscript
# Get all triggers
var triggers = tile_effect_controller.get_active_triggers()

# Get triggers by effect type
var disco_triggers = tile_effect_controller.get_trigger_by_effect_type("disco")

# Activate all triggers of a type
tile_effect_controller.activate_all_triggers_of_type("reveal")

# Reset all triggers
tile_effect_controller.reset_all_triggers()
```

### Debug Information

Enable debug overlay to see trigger information:

```gdscript
# In TileEffectController
show_debug_info = true
show_trigger_info = true
```

Shows:
- Total trigger count
- Active/inactive status
- Effect types and positions
- Manual control instructions

## Best Practices

### Map Design

1. **Clear Visual Distinction** - Use different colors for different effect types
2. **Logical Placement** - Place triggers where they make sense spatially
3. **Reset Options** - Always provide a way to reset/stop effects
4. **Progressive Complexity** - Start simple, add more complex triggers gradually

### Effect Configuration

1. **Balanced Timing** - Don't make delays too long or short
2. **Appropriate Radius** - Match effect radius to map size
3. **Color Coding** - Use consistent color schemes
4. **Audio Feedback** - Add audio for better user experience

### Performance

1. **Limit Trigger Count** - Too many triggers can impact performance
2. **Reasonable Effects** - Large radius effects on big maps can be slow
3. **One-Time Triggers** - Use for expensive effects that should only happen once

## Troubleshooting

### Triggers Not Appearing

1. Check JSON syntax is valid
2. Verify `trigger:` prefix is used correctly
3. Ensure `tile_effect_definitions` section exists
4. Confirm `enable_tile_effects = true` in grid system

### Effects Not Working

1. Check trigger placement (not overlapping with walls)
2. Verify effect type is spelled correctly
3. Ensure TileEffectManager is initialized
4. Check console for error messages

### Debug Issues

1. Enable debug overlay: `show_debug_info = true`
2. Check trigger detection: `show_trigger_info = true`
3. Monitor console output for trigger activation messages
4. Use manual controls (R, D, S, A, H keys) to test basic functionality

## Migration from Manual Setup

To convert existing manual tile effect setups to JSON:

1. Identify current trigger positions
2. Create `tile_effect_definitions` for each trigger type
3. Add `trigger:` entries to interactables layer
4. Remove manual trigger placement code
5. Test and adjust configurations

## Example Complete Map

See `adaresearch/Common/Data/Maps/TileEffects_Demo/map_data.json` for a complete working example with multiple trigger types and configurations. 