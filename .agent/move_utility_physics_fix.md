# Player Movement Utility (`m:`) - Physics Synchronization Fix

## Problem Summary

The `m:x:y:z:delay` utility was not working reliably due to a **race condition** between the utility's position-setting code and the XR-Tools PlayerBody's continuous physics processing.

## How It Works

The `m:` utility **automatically moves the player** to a specified position after a delay. It does NOT require the player to walk into a trigger area - it's purely timer-based.

### Syntax
```
m:x:y:z        // Move to (x,y,z) after 0.5 seconds (default)
m:x:y:z:delay  // Move to (x,y,z) after 'delay' seconds
```

### Example
```json
"m:5:2:8:1.5"  // Moves player to position (5, 2, 8) after 1.5 seconds
```


## Root Cause

The `XRToolsPlayerBody` class runs a `_physics_process()` method **every frame** (60+ times per second) that:
1. Updates player position based on velocity
2. Applies gravity
3. Processes movement providers
4. Updates the XROrigin3D position

When the move utility tried to set the player's position, the very next physics frame would:
- Read the player's velocity (which might still be non-zero)
- Apply that velocity to move the player away from the target position
- Override the position we just set

## The Solution

The fix involves **synchronizing with the physics frame timing**:

### Before (Broken):
```gdscript
func _execute_move():
    _reset_velocity(player_node)  # Reset velocity
    player_root.global_position = move_target  # Set position
    # ❌ Physics frame runs immediately and can override this!
```

### After (Fixed):
```gdscript
func _execute_move():
    # 1. Reset velocity FIRST
    _reset_velocity(player_node)
    
    # 2. Wait for physics frame to process the velocity reset
    await get_tree().physics_frame
    
    # 3. THEN set the position (velocity is now zero)
    player_root.global_position = move_target
    
    # 4. Reset velocity AGAIN (in case physics added any)
    _reset_velocity(player_node)
    
    # 5. Wait for physics frame to ensure position sticks
    await get_tree().physics_frame
```

## Why This Works

1. **First velocity reset**: Clears any existing momentum
2. **First physics wait**: Lets the physics engine process with zero velocity
3. **Position change**: Now safe to move player (no velocity to override it)
4. **Second velocity reset**: Clears any velocity the physics engine might have added during the position change
5. **Second physics wait**: Ensures the next physics frame runs with zero velocity and the new position

## Files Modified

### 1. `MovePlayerController.gd`
- Fixed `_execute_move()` method
- Now properly synchronizes with physics frames
- Prevents physics from overriding the move command

### 2. `ResetTeleporter.gd`
- Applied the same fix to the reset teleporter
- Ensures player respawns work reliably
- Prevents "bouncing" or "sliding" after respawn

## Testing

To test the fix:
1. Place a move utility in your map: `"m:5:2:8:1.5"`
2. Walk into the trigger area
3. Player should smoothly teleport to position (5, 2, 8) after 1.5 seconds
4. Player should stay at that position (no sliding or drifting)

## Technical Details

### Physics Frame Timing
- Godot's physics runs at a fixed timestep (default: 60 Hz)
- `await get_tree().physics_frame` waits for the next physics update
- This ensures our changes happen in the correct order relative to physics

### Velocity Reset
The `_reset_velocity()` method clears:
- `velocity` (CharacterBody3D velocity)
- `linear_velocity` (RigidBody3D velocity)
- `angular_velocity` (rotation velocity)

It resets velocity on both:
- The player body (CharacterBody3D)
- The player root (XROrigin3D)

## Related Systems

This same pattern should be used anywhere you need to:
- Teleport the player
- Reset player position
- Force player movement
- Override physics-based movement

## Future Improvements

Consider adding to `XRToolsPlayerBody`:
- A `teleport_safe()` method that handles this synchronization internally
- A flag to temporarily disable physics processing during teleports
- Events that fire before/after physics updates for better synchronization
