# 🔧 Compute Shader Debugging Guide

## Current Issue
The GPU marching cubes generation is producing broken triangle geometry instead of smooth caves.

## Safe Testing Setup

### 1. **Fallback Cave (Always Works)**
In the scene, set:
```
use_fallback_cave = true
```
This gives you a smooth, double-sided rainbow tunnel.

### 2. **Compute Shader Testing**
To test the GPU marching cubes:
```
use_fallback_cave = false
noise_scale = 2.0  # Keep this low
iso_level = 1.0    # Try different values between 0.5-1.5
```

## Potential Issues with Compute Shader

### 1. **Noise Scale**
- **Problem**: `noise_scale = 20.0` creates chaotic, broken geometry
- **Fix**: Use `noise_scale = 2.0` for smoother caves
- **Test values**: Try 1.0, 2.0, 3.0, 5.0

### 2. **ISO Level**
- **Problem**: Wrong threshold creates disconnected triangles
- **Current**: `iso_level = 1.11`
- **Test values**: Try 0.5, 1.0, 1.5

### 3. **Noise Offset**
- **Current**: `Vector3(152.543, -150, 100)`
- **Alternative**: Try `Vector3(0, 0, 0)` for centered generation

## Debug Console Output

When compute shader works correctly, you should see:
```
TerrainGenerator: Compute shader generated 1234 triangles
✅ Cave mesh created successfully with 3702 vertices!
```

When it fails:
```
TerrainGenerator: Compute shader generated 0 triangles
❌ No vertices generated - creating fallback cube
```

## Quick Fixes to Try

1. **Reset to basic parameters**:
   ```
   noise_scale = 1.0
   iso_level = 1.0
   noise_offset = Vector3.ZERO
   ```

2. **Check compute shader compilation**:
   - Look for SPIRV compilation errors in console
   - Ensure MarchingCubes.glsl exists and is valid

3. **Test different resolutions**:
   - Current: `resolution = 8` (8x8x8 grid)
   - The lower the resolution, the chunkier but more stable the output

## Recommendation

Keep `use_fallback_cave = true` for now since it provides a beautiful, working cave experience. The compute shader debugging can be done separately without affecting the VR experience.
