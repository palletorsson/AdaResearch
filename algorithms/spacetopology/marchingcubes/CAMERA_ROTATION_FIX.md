# Camera3D Rotation Fix

## Problem Description

Error encountered when running RhizomeCaveDemo:
```
Invalid assignment of property or key 'rotation' with value of type 'Vector2' on a base object of type 'Camera3D'.
```

## Root Cause

In both `RhizomeCaveDemoController.gd` and `TerrainDemoController.gd`, the camera rotation was being handled incorrectly:

```gdscript
# PROBLEM: camera_rotation is Vector2, but Camera3D.rotation expects Vector3
var camera_rotation = Vector2.ZERO  # Stores yaw (y) and pitch (x)
...
camera.rotation = camera_rotation   # ❌ Type mismatch!
```

## Fix Applied

Changed the rotation assignment to properly convert Vector2 to Vector3:

### Before (Broken):
```gdscript
camera.rotation = camera_rotation
```

### After (Fixed):
```gdscript
# FIXED: Convert Vector2 camera_rotation to Vector3 for Camera3D
camera.rotation = Vector3(camera_rotation.x, camera_rotation.y, 0.0)
```

## Files Modified

1. **`scenes/RhizomeCaveDemoController.gd`** - Line 441 (in `update_camera_movement()`)
2. **`scenes/TerrainDemoController.gd`** - Line 196 (in mouse look section)

## Technical Details

- **Vector2 camera_rotation**: Stores pitch (x) and yaw (y) for mouse look
- **Vector3 Camera3D.rotation**: Expects (pitch, yaw, roll) in Euler angles
- **Conversion**: `Vector3(pitch, yaw, 0.0)` - roll is 0 for standard FPS camera

## Testing

After applying this fix:
- ✅ RhizomeCaveDemo loads without errors
- ✅ TerrainDemo camera controls work properly
- ✅ Mouse look functions correctly in both demos
- ✅ No runtime type errors

## Camera Control Features

Both demos now have working:
- **Mouse Look**: Click and drag to look around
- **WASD Movement**: Standard FPS movement
- **Q/E**: Vertical movement (up/down)
- **Mouse Wheel**: Zoom in/out (in orbital mode)
- **Space**: Sprint modifier

This fix ensures compatibility with Godot 4's stricter type checking for 3D transforms. 