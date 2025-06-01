# Tile Effect Cleanup System

## Overview

The TileEffectManager now includes an automatic cleanup system that removes effect cubes after effects complete, preventing them from blocking level cubes.

## Automatic Cleanup Features

### Configuration Options

The cleanup system can be configured through export variables in TileEffectManager:

```gdscript
@export var auto_cleanup_on_complete: bool = true  # Enable automatic cleanup
@export var effect_duration: float = 10.0         # Max duration for timed effects
@export var cleanup_delay: float = 2.0            # Delay before cleanup after effect completes
```

### How It Works

1. **Effect Tracking**: Each effect tracks its start time and completion status
2. **Automatic Scheduling**: When effects start, cleanup is automatically scheduled
3. **Completion Detection**: System detects when effects finish naturally
4. **Cleanup Queue**: Scheduled cleanups are processed in the background
5. **Mesh Removal**: Effect cubes fade out and are removed from the scene

## Effect Types and Cleanup

### Reveal Effect
- **Completion**: When reveal radius reaches maximum distance
- **Cleanup Time**: `(max_reveal_radius / reveal_speed) + cleanup_delay`
- **Behavior**: Tiles fade out and mesh instances are removed

### Disco Effect
- **Completion**: After `effect_duration` seconds
- **Cleanup Time**: `effect_duration + cleanup_delay`
- **Behavior**: All disco tiles are cleaned up simultaneously

### Manual Stop
- **Trigger**: When `stop_all_effects()` is called
- **Cleanup Time**: Immediate (if auto_cleanup_on_complete is true)
- **Behavior**: All active effects are cleaned up instantly

## Usage Examples

### Basic Usage (Default Settings)
```gdscript
# Effects will automatically clean up after completion
tile_effect_manager.start_reveal_effect(Vector3i(5, 0, 5))
# Cleanup happens automatically after reveal completes + 2 second delay
```

### Custom Configuration
```gdscript
# Configure cleanup settings
tile_effect_manager.set_auto_cleanup(true)
tile_effect_manager.set_cleanup_delay(5.0)  # 5 second delay before cleanup
tile_effect_manager.effect_duration = 15.0  # Disco runs for 15 seconds

# Start effects
tile_effect_manager.start_disco_effect()
# Will automatically clean up after 15 + 5 = 20 seconds
```

### Manual Cleanup
```gdscript
# Force immediate cleanup of all effects
tile_effect_manager.force_cleanup_all()

# Clean up specific effect types
tile_effect_manager.cleanup_reveal_tiles()
tile_effect_manager.cleanup_disco_tiles()

# Disable automatic cleanup
tile_effect_manager.set_auto_cleanup(false)
```

## Monitoring Cleanup Status

### Get Current Status
```gdscript
var status = tile_effect_manager.get_cleanup_status()
print("Auto cleanup: ", status.auto_cleanup_enabled)
print("Cleanup delay: ", status.cleanup_delay)
print("Pending cleanups: ", status.pending_cleanups)
print("Reveal completed: ", status.reveal_completed)
print("Disco active: ", status.disco_active)
```

### Listen to Cleanup Events
```gdscript
# Connect to cleanup signals
tile_effect_manager.effect_completed.connect(_on_effect_completed)
tile_effect_manager.tiles_cleaned_up.connect(_on_tiles_cleaned_up)

func _on_effect_completed(effect_type: String):
    print("Effect completed: ", effect_type)

func _on_tiles_cleaned_up(count: int):
    print("Cleaned up ", count, " effect tiles")
```

## Configuration in JSON Maps

You can configure cleanup behavior in your map's JSON settings:

```json
{
  "settings": {
    "enable_tile_effects": true,
    "tile_effect_auto_cleanup": true,
    "tile_effect_cleanup_delay": 3.0,
    "tile_effect_duration": 12.0
  }
}
```

## Technical Details

### Cleanup Process
1. **Detection**: Effect completion is detected through radius checking (reveal) or time limits (disco)
2. **Scheduling**: Cleanup is scheduled using `Time.get_time_dict_from_system()` for timing
3. **Fade Out**: Effect tiles fade their alpha to 0.0 over 0.5 seconds
4. **Removal**: MeshInstance3D nodes are `queue_free()`d after fade completes
5. **Reset**: Tile data is reset to clean state

### Performance Considerations
- Cleanup queue is processed every frame but only when not empty
- Mesh removal uses tweens for smooth fade-out
- Effect tiles are completely removed from memory after cleanup
- No performance impact when no effects are active

### Collision Prevention
- Effect cubes are positioned slightly below grid level (`y -= 0.45`)
- Effect cubes use smaller size (`tile_size * 0.95`) to avoid exact overlap
- Automatic cleanup ensures temporary effect cubes don't permanently block level geometry

## Best Practices

1. **Use Default Settings**: The default cleanup configuration works well for most use cases
2. **Monitor Performance**: For maps with many simultaneous effects, consider shorter durations
3. **Test Timing**: Adjust `cleanup_delay` based on your effect's visual requirements
4. **Handle Edge Cases**: Connect to cleanup signals if you need to synchronize with effect completion
5. **Disable When Needed**: Disable auto-cleanup for persistent visual effects that should remain visible

## Troubleshooting

### Effects Not Cleaning Up
- Check `auto_cleanup_on_complete` is `true`
- Verify effects are completing naturally (not interrupted)
- Monitor cleanup queue with `get_cleanup_status()`

### Performance Issues
- Reduce `effect_duration` for faster cleanup
- Lower `cleanup_delay` to clean up sooner
- Use `force_cleanup_all()` if needed

### Visual Glitches
- Increase `cleanup_delay` for smoother transitions
- Check that fade-out duration (0.5s) is appropriate
- Ensure effect cube positioning doesn't conflict with level geometry 