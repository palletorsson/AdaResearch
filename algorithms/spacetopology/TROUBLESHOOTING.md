# Troubleshooting Gyroid Scenes

## Issue: Nothing Visible in Gyroid/Entropy Scenes

If you don't see the gyroid structure, try these steps:

### Step 1: Test Basic Setup

Run the simple test scene first:
```
res://algorithms/spacetopology/gyroid_cheese/gyroid_test_simple.tscn
```

**Expected**: You should see a light blue semi-transparent box with a label.

**If this works**: The problem is with the ray marching shader.
**If this doesn't work**: There's a more basic issue with your Godot setup.

### Step 2: Check Console Output

When running `gyroid_cheese_vr.tscn` or `entropy_morphogenesis_vr.tscn`, check the console for:

```
=== GYROID CHEESE VR INITIALIZING ===
✓ Noise setup
✓ Mesh setup
✓ Shader setup
✓ Box size applied: (8, 8, 8)
Building gyroid colliders...
Built X colliders in Y ms
=== INITIALIZATION COMPLETE ===
```

**Look for**:
- Any error messages (red text)
- Shader compilation errors
- Missing node warnings

### Step 3: Enable Collision Debug

1. Open the scene in Godot editor
2. Select the root node (GyroidCheeseVR or EntropyMorphogenesisVR)
3. In Inspector, find "Volume / collider box" or "Volume / Colliders"
4. Enable **`show_collider_debug`**
5. Run the scene

**Expected**: Red semi-transparent spheres where collisions are placed.

**If you see red spheres**: Collision is working, issue is visual shader.
**If you don't see red spheres**: Collisions aren't being generated.

### Step 4: Check Camera Position

The camera should be at:
- Position: (0, 1.7, 6)
- Looking at: (0, 0, 0) - the center of the gyroid

In the running scene, try:
- Moving the camera (WASD)
- Looking around (mouse)
- Getting closer/farther

### Step 5: Shader Parameters

The ray marching shader might need adjustment. In Inspector, try:

For **Gyroid Cheese**:
```
frequency: 1.2 → 0.8 (larger features)
thickness: 0.12 → 0.20 (thicker walls)
noise_amp: 0.25 → 0.1 (less noise)
```

For **Entropy Morphogenesis**:
```
S_target: 0.65 → 0.3 (lower entropy = simpler)
auto_animate_S: true → false (freeze it)
base_frequency: 0.9 → 0.7 (larger features)
```

### Common Issues

#### Issue: "Invalid render mode: depth_test_disable"
**Fixed** in latest version. If you see this:
- Make sure you're using the updated shader code
- The render mode should be `render_mode unshaded, cull_back;`

#### Issue: Shader compiles but nothing visible
The ray marching might not be finding the surface. Try:
- Reducing `box_size` to (4, 4, 4)
- Increasing `thickness` to 0.3
- Setting `threshold` to exactly 0.0

#### Issue: Black screen
- Check WorldEnvironment has ambient light
- Check DirectionalLight3D is present and enabled
- Verify camera isn't inside a solid collision

#### Issue: Very slow / stuttering
- Reduce `collider_grid` to (8, 8, 8)
- Reduce `max_colliders` to 100
- Set `allow_runtime_rebuild` to false (entropy scene)

### Debug Shader

If the main shader isn't working, you can temporarily use this simple test shader:

```gdscript
# Add this to _setup_shader() after creating _mat
var test_shader := Shader.new()
test_shader.code = """
shader_type spatial;
render_mode unshaded;

void fragment() {
	// Simple distance-based color
	float dist = length(VERTEX);
	vec3 col = vec3(0.3, 0.7, 1.0) * (1.0 - dist * 0.1);
	ALBEDO = col;
	ALPHA = 0.8;
}
"""
_mat.shader = test_shader
```

This will show a simple colored box - if this works, the issue is with the ray marching code.

### Still Not Working?

Please provide:
1. Godot version (should be 4.3+)
2. Console output (copy/paste all messages)
3. GPU/graphics card info
4. Does the simple test scene work?
5. Screenshot of what you see (even if blank)

The ray marching shader is GPU-intensive and might not work on very old hardware or without proper OpenGL/Vulkan support.

## Performance Tips

Once it's working, if performance is poor:

**For Testing**:
- `box_size`: (4, 4, 4) - very fast
- `collider_grid`: (8, 8, 8)
- `max_colliders`: 50

**For Playable**:
- `box_size`: (8, 8, 8) - current default
- `collider_grid`: (12, 10, 12)
- `max_colliders`: 200

**For Exhibition**:
- `box_size`: (12, 12, 12)
- `collider_grid`: (16, 14, 16)
- `max_colliders`: 400

Ray marching steps can be reduced in the shader:
- Find `for(int i=0; i<100; i++)`
- Change to `for(int i=0; i<64; i++)` for faster rendering
