# Quick Start Guide - BuildEnv Geometry Test

## 🎯 Goal

Get visible geometry showing in the BuildEnv RL environment.

---

## ⚡ Method 1: Diagnostic Test (Simplest)

**This tests basic mesh rendering with minimal complexity.**

### Steps:

1. **Open Godot** and load your project
2. **Navigate to:** `algorithms/machinelearning/stacked/`
3. **Double-click:** `diagnostic_test.tscn`
4. **Press F6** (or click Run Current Scene)

### Expected Result:

You should see:
- 🔴 **Red box** on the left
- 🟢 **Green cylinder** in the middle
- 🟢 **Green ground plane** beneath

### What This Tests:

- ✅ Basic mesh creation (BoxMesh, CylinderMesh)
- ✅ Material rendering
- ✅ Camera positioning
- ✅ Scene setup

### If You See Nothing:

📄 Open `TROUBLESHOOTING.md` → "Issue 1: No geometry at all"

---

## 🏗️ Method 2: Full BuildEnv Test

**This tests the complete RL environment with physics.**

### Steps:

1. **Navigate to:** `algorithms/machinelearning/stacked/`
2. **Double-click:** `learn_world_stacked.tscn`
3. **Press F6** to run

### Expected Result:

**Automatically on startup:**
- 🟫 3 tan cubes appear at ground level
- ⚫ 3 gray pillars stack on top
- 🟫 2 brown beams connect the pillars
- 🟡 1 gold pyramid caps the structure
- 🟩 Green ground plane beneath everything

**Console output:**
```
BuildEnv: Environment setup complete (ground: 20.0x20.0)
BuildEnv: Ready! Waiting for step() calls...

=== BuildEnv Visual Test ===
Press SPACE to place random pieces
Press R to reset environment
Press T to run automated test
Press D to toggle auto-demo

Placing initial pieces for visualization...
BuildEnv: Placed cube_small (ID:0) at (-2.0, 0.3, 0.0) - Total bodies: 1
BuildEnv: Placed cube_small (ID:0) at (0.0, 0.3, 0.0) - Total bodies: 2
...
✓ Initial demo structure placed
✓ You should now see: ground + cubes + pillars + beams + pyramid
```

### Interactive Controls:

- `SPACE` - Place random primitive
- `R` - Reset environment
- `T` - Auto-place all 8 primitive types
- `D` - Toggle continuous auto-demo

### What This Tests:

- ✅ BuildEnv initialization
- ✅ Ground plane creation
- ✅ All 8 primitive types
- ✅ Physics simulation
- ✅ Material colors
- ✅ Placement system
- ✅ Grammar discovery system

---

## 🔍 What You Should See

### Primitive Visual Guide:

| ID | Type | Color | Shape |
|----|------|-------|-------|
| 0 | Small Cube | Tan | 0.5x0.25x0.5 box |
| 1 | Long Beam | Dark Brown | 1.5x0.15x0.15 beam |
| 2 | Pyramid | Gold | Square pyramid |
| 3 | Pillar | Gray/Stone | Tall cylinder |
| 4 | Short Beam | Med Brown | 0.8x0.12x0.12 beam |
| 5 | Wedge | Red-Brown | Triangular ramp |
| 6 | Plate | Light Tan | 1.0x0.1x1.0 flat |
| 7 | Arch | White/Limestone | Capsule |

### Initial Demo Structure:

```
        🟡 (pyramid)
    ══════╬══════
    ║     ║     ║  (beams)
    ║     ║     ║
   ⚫    ⚫    ⚫  (pillars)
   🟫    🟫    🟫  (cubes)
  ═════════════════
      🟩🟩🟩🟩🟩  (ground)
```

---

## 📊 Console Messages Explained

### Good Messages (Expected):

```
✅ BuildEnv: Environment setup complete
✅ BuildEnv: Ready! Waiting for step() calls...
✅ BuildEnv: Placed cube_small (ID:0) at ...
✅ Initial demo structure placed
```

### Bad Messages (Problems):

```
❌ Error: Can't find BuildEnv node
   → Fix: Check scene tree structure

❌ Parser Error: ...
   → Fix: Syntax error in script, check Output tab

❌ Invalid call to step()
   → Fix: BuildEnv not initialized properly
```

---

## 🎥 Camera Tips

If you see blank screen but console shows pieces placed:

1. **Select Camera3D** in scene tree
2. **Check position:** Should be around `(8, 6, 8)`
3. **Use Preview mode:**
   - Click Camera3D
   - Click "Preview" button in 3D viewport toolbar
   - See exactly what camera sees

4. **Manual camera control:**
   - Middle mouse drag to pan
   - Scroll to zoom
   - Right mouse drag to rotate view

---

## 🐛 Quick Troubleshooting

### Nothing visible at all
→ Run `diagnostic_test.tscn` first
→ Check camera position
→ Add DirectionalLight3D

### Console shows errors
→ Check Output tab for details
→ Verify script paths are correct

### Pieces place but don't show
→ Check material shading mode
→ Try unshaded materials
→ Verify mesh children exist (see TROUBLESHOOTING.md)

### Pieces fall through ground
→ Check collision layers
→ Verify physics enabled

---

## 📁 File Reference

| File | Purpose | When to Use |
|------|---------|-------------|
| `diagnostic_test.tscn` | Simple mesh test | Start here if nothing visible |
| `learn_world_stacked.tscn` | Full RL environment | Main test scene |
| `LearnWorldStacked.gd` | BuildEnv script | Edit primitives, rewards |
| `TestBuildEnv.gd` | Interactive test controller | Modify controls |
| `DiagnosticTest.gd` | Simple diagnostic | Debug mesh issues |
| `TROUBLESHOOTING.md` | Detailed fixes | When problems occur |
| `README.md` | Full documentation | Learning about system |

---

## ✅ Success Checklist

Run `learn_world_stacked.tscn` and verify:

- [ ] Console shows "Environment setup complete"
- [ ] Console shows "Placed cube_small" messages
- [ ] Green ground plane visible
- [ ] Tan cubes visible at ground level
- [ ] Gray pillars visible stacked on cubes
- [ ] Brown beams visible connecting pillars
- [ ] Gold pyramid visible on top
- [ ] Pressing SPACE places new random pieces
- [ ] Pieces fall and settle with physics
- [ ] No errors in Output tab

**All checked?** 🎉 **System working!** Proceed to README.md for RL training.

**Some unchecked?** 📄 See TROUBLESHOOTING.md for specific issue.

---

## 💡 Tips

- **Run diagnostic first** - Fastest way to verify setup
- **Watch console output** - Shows exactly what's happening
- **Use SPACE key** - Easy way to add more geometry
- **Try auto-demo (D key)** - Continuous piece placement
- **Check scene tree at runtime** - See nodes being created
- **F5 vs F6** - F6 runs current scene (faster for testing)

---

## 🆘 Still Not Working?

1. Read `TROUBLESHOOTING.md`
2. Check Godot version (4.3+ recommended)
3. Update graphics drivers
4. Try different renderer (Project Settings → Rendering)
5. Report issue with:
   - Godot version
   - OS
   - Console output
   - Screenshot of scene tree

---

**Version:** 2.0
**Last Updated:** 2025-01-30
**Godot Version:** 4.3+
