# Troubleshooting: No Geometry Visible

## Quick Diagnostic Steps

### Step 1: Run Diagnostic Test Scene

1. **Open** `diagnostic_test.tscn` in Godot
2. **Press F6** to run the scene
3. **Check console output** - should see:
   ```
   === DIAGNOSTIC TEST ===
   Creating primitives directly...
   1. Creating simple box...
      Box created - Children: 1
      - Child 0: MeshInstance3D
   ```

**Expected result:** You should see:
- A bright RED box on the left
- A bright GREEN cylinder in the center
- A green GROUND PLANE

**If you see nothing:**
- Camera might not be positioned correctly
- Viewport/display issue in Godot
- Graphics driver problem

---

### Step 2: Check Console Output

Run `learn_world_stacked.tscn` and watch console:

**You should see:**
```
BuildEnv: Environment setup complete (ground: 20.0x20.0)
BuildEnv: Ready! Waiting for step() calls...

=== BuildEnv Visual Test ===
Press SPACE to place random pieces
...

Placing initial pieces for visualization...
BuildEnv: Placed cube_small (ID:0) at (-2.0, 0.3, 0.0) - Total bodies: 1
BuildEnv: Placed cube_small (ID:0) at (0.0, 0.3, 0.0) - Total bodies: 2
...
✓ Initial demo structure placed
```

**If you DON'T see "Placed cube_small" messages:**
- TestBuildEnv script not running
- BuildEnv node path wrong
- Script errors preventing execution

---

### Step 3: Verify Scene Structure

**In learn_world_stacked.tscn, you should have:**

```
LearnWorldStacked (Node3D) [TestBuildEnv.gd]
├─ BuildEnv (Node3D) [LearnWorldStacked.gd]
│  └─ (dynamic children created at runtime)
├─ Camera3D
├─ DirectionalLight3D
└─ WorldEnvironment
```

**Runtime structure (after pieces placed):**
```
BuildEnv
├─ StaticBody3D (ground plane)
│  ├─ CollisionShape3D
│  └─ MeshInstance3D ← GROUND VISUAL
├─ RigidBody3D (piece 1)
│  ├─ CollisionShape3D
│  └─ MeshInstance3D ← PIECE VISUAL
├─ RigidBody3D (piece 2)
│  ├─ CollisionShape3D
│  └─ MeshInstance3D ← PIECE VISUAL
...
```

---

## Common Issues & Fixes

### Issue 1: "No geometry at all"

**Symptoms:** Completely blank viewport, sky/background visible

**Possible causes:**

1. **Camera not looking at origin**
   - **Fix:** Select Camera3D, check position is `(8, 6, 8)`
   - Click "Preview" button in 3D viewport to see camera view
   - Manually position camera to look at `(0, 0, 0)`

2. **No lighting**
   - **Fix:** Add DirectionalLight3D if missing
   - Set light energy to 1.5
   - Enable shadows

3. **Scripts not running**
   - **Fix:** Check Output tab for errors
   - Verify script paths are correct
   - Re-save scene

4. **Godot rendering issue**
   - **Fix:** Try different renderer (Forward+ vs Mobile vs Compatibility)
   - Project Settings → Rendering → Renderer

---

### Issue 2: "Console shows pieces placed but nothing visible"

**Symptoms:** Console says "Placed cube_small at..." but viewport empty

**Possible causes:**

1. **Meshes not being added to scene tree**
   - **Debug:** Add this to LearnWorldStacked.gd:
   ```gdscript
   # After line 408 (after bodies.append)
   print("   Mesh children: %d" % rb.get_child_count())
   for child in rb.get_children():
       print("   - %s" % child.get_class())
   ```
   - **Expected output:** Should show both CollisionShape3D and MeshInstance3D

2. **Materials not rendering**
   - **Fix:** Change to unshaded materials for testing
   - In _create_material(), add:
   ```gdscript
   material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
   ```

3. **Pieces spawning outside camera view**
   - **Fix:** Check position values in console output
   - Try setting camera further back: `(15, 10, 15)`

---

### Issue 3: "Ground plane visible but no pieces"

**Symptoms:** Green ground plane shows up, but placed pieces don't appear

**Possible causes:**

1. **Pieces falling through ground**
   - **Fix:** Check collision layers/masks
   - Ground should be on layer 1
   - RigidBody3D should collide with layer 1

2. **Physics simulation disabled**
   - **Fix:** Project Settings → Physics → 3D
   - Verify physics is enabled

3. **Y position calculation wrong**
   - **Debug:** Check `_top_height_at()` return value
   - Add debug: `print("y_top = %.2f" % y_top)` before placing

---

### Issue 4: "Only some primitives visible"

**Symptoms:** Some primitive types show, others don't

**Possible causes:**

1. **Mesh creation error for specific type**
   - **Fix:** Check console for errors when placing that type
   - Test each primitive individually:
   ```gdscript
   env.step({"primitive_id": 2, "x": 0, "z": 0, "yaw_bin": 0})  # Test pyramid
   ```

2. **Array mesh errors (pyramid, wedge)**
   - **Fix:** Verify vertex winding order
   - Check indices array is valid

---

## Manual Verification Tests

### Test A: Create Single Box Manually

Add to TestBuildEnv._ready():

```gdscript
# Manual mesh test
var test_body = RigidBody3D.new()
test_body.position = Vector3(0, 3, 0)

var mesh_inst = MeshInstance3D.new()
var box = BoxMesh.new()
box.size = Vector3(1, 1, 1)
mesh_inst.mesh = box

var mat = StandardMaterial3D.new()
mat.albedo_color = Color(1, 0, 0)  # RED
mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
mesh_inst.material_override = mat

test_body.add_child(mesh_inst)
add_child(test_body)

print("Manual test box created at (0, 3, 0)")
```

**If this works but BuildEnv doesn't:**
- Issue is in BuildEnv primitive factories
- Check _make_box() vs manual code above

---

### Test B: Check Scene Tree at Runtime

In TestBuildEnv, add:

```gdscript
func _on_debug_tree():
    print("\n=== SCENE TREE ===")
    _print_tree(env, 0)

func _print_tree(node: Node, depth: int):
    var indent = "  ".repeat(depth)
    print("%s%s (%s)" % [indent, node.name, node.get_class()])

    if node is MeshInstance3D:
        var mi = node as MeshInstance3D
        print("%s  └─ Mesh: %s" % [indent, mi.mesh])

    for child in node.get_children():
        _print_tree(child, depth + 1)
```

Call with `_on_debug_tree()` after placing pieces.

**Expected output:**
```
BuildEnv (Node3D)
  StaticBody3D (ground)
    CollisionShape3D
    MeshInstance3D
      └─ Mesh: <BoxMesh>
  RigidBody3D
    CollisionShape3D
    MeshInstance3D
      └─ Mesh: <BoxMesh>
```

---

## Godot Version Issues

### Godot 4.0 - 4.2
- Some mesh APIs changed
- Try using older BoxMesh creation syntax

### Godot 4.3+
- StandardMaterial3D shading modes changed
- Use compatibility renderer if Forward+ has issues

---

## Still Not Working?

### Last Resort Checks:

1. **Create completely new scene from scratch**
   - New Scene → 3D Scene
   - Add Camera3D manually
   - Add DirectionalLight3D manually
   - Add BuildEnv node manually
   - Save and run

2. **Check project settings**
   - Display → Window → Size → Width/Height valid
   - Rendering → Viewport → Transparent Background OFF
   - Rendering → Anti-Aliasing → MSAA 3D ON

3. **Graphics driver issue**
   - Update GPU drivers
   - Try running Godot on different hardware
   - Use compatibility renderer: Rendering → Renderer → Compatibility

4. **Reinstall Godot**
   - Download fresh Godot 4.3 or 4.4
   - Import project again

---

## Success Checklist

When working correctly, you should see:

- ✅ Dark green ground plane (20x20 units)
- ✅ Tan cubes at (-2, 0, 0), (0, 0, 0), (2, 0, 0)
- ✅ Gray pillars standing on cubes
- ✅ Brown beams connecting pillars
- ✅ Gold pyramid on top
- ✅ Console shows placement messages
- ✅ No errors in Output tab
- ✅ Physics simulation running (pieces settle)

---

## Report Issue

If none of these fixes work, please report:

1. **Godot version:** (Help → About)
2. **Operating system:**
3. **Console output:** (full text)
4. **Diagnostic test result:** (does it show geometry?)
5. **Scene tree screenshot:** (from running scene)
6. **Any error messages:**

This helps identify if it's a Godot version issue, platform-specific bug, or code problem.
