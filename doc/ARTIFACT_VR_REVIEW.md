# Artifact VR Interaction Review

**Date:** 2026-02-03  
**Status:** Needs VR controls added

All artifacts currently use keyboard controls. They need VR-native interaction using `commons/interactables/` patterns.

---

## VR Interactable Patterns Available

| Component | Path | Use Case |
|-----------|------|----------|
| `slider_horizontal` | Horizontal value control | Parameters 0-1 |
| `slider_axis` | Vertical/any axis slider | Range values |
| `dial_smooth` | Rotary knob | Angles, continuous |
| `push_button` | Momentary button | Reset, trigger |
| `lever_smooth` | Toggle lever | On/off, modes |
| `wheel_smooth` | Rotation wheel | Scrolling, selection |

---

## Artifact Review

### 1. `boids_aquarium` ✓ Mostly OK

**Current:** Observe-only, no interaction needed  
**VR Status:** ✅ Works as-is (display artifact)

**Optional enhancements:**
- [ ] Add slider for `num_boids`
- [ ] Add slider for `separation_weight` / `cohesion_weight`
- [ ] Make whole artifact grabbable/moveable

---

### 2. `jelly_cube` ⚠️ Needs Grabbable

**Current:** SoftBody3D but not VR-grabbable  
**VR Status:** ⚠️ Needs XR pickup integration

**Required changes:**
- [ ] Add `XRToolsPickable` or collision layer 262144
- [ ] Connect to `godot-xr-tools` grab system
- [ ] Add poke response (apply_impulse on controller touch)

**Add to scene:**
```
InteractableHandle (for grabbing whole cube)
  └─ CollisionShape3D
```

---

### 3. `ca_rule_explorer` ⚠️ Needs VR Controls

**Current:** Keyboard (←→ rule, ↑↓ speed, R reset)  
**VR Status:** ⚠️ Not usable in VR

**Required changes:**
- [ ] Add `slider_horizontal` for rule (0-255)
- [ ] Add `slider_horizontal` for speed
- [ ] Add `push_button` for reset
- [ ] Add preset buttons (30, 90, 110)

**Control panel layout:**
```
┌─────────────────────────┐
│  RULE [====●====] 110   │  ← slider_horizontal
│  SPEED [==●======] 10   │  ← slider_horizontal
│  [30] [90] [110] [RESET]│  ← push_buttons
└─────────────────────────┘
```

---

### 4. `mandelbrot_dive` ⚠️ Needs VR Controls

**Current:** Keyboard (↑↓ zoom, WASD pan, 1-5 colors)  
**VR Status:** ⚠️ Not usable in VR

**Required changes:**
- [ ] Add `slider_horizontal` for zoom (logarithmic)
- [ ] Add `slider_plane` or joystick for pan (X/Y)
- [ ] Add `lever_smooth` for color scheme (1-5 positions)
- [ ] Add `push_button` for auto-dive toggle
- [ ] Add `push_button` for reset

---

### 5. `bifurcation_walkway` ✓ Works in VR

**Current:** Player position drives r parameter  
**VR Status:** ✅ Works as-is (walkable)

**Optional enhancements:**
- [ ] Add `slider_horizontal` at entrance for manual r control (testing)
- [ ] Add info panel that follows player

---

### 6. `turing_pattern_generator` ⚠️ Needs VR Controls

**Current:** Keyboard (1-6 presets, R reset, Space pause)  
**VR Status:** ⚠️ Not usable in VR

**Required changes:**
- [ ] Add `lever_smooth` with 6 positions for preset
- [ ] Add `slider_horizontal` for feed rate
- [ ] Add `slider_horizontal` for kill rate
- [ ] Add `push_button` for reset
- [ ] Add `push_button` for pause/play

---

### 7. `perlin_terrain_sculptor` ⚠️ Needs VR Controls

**Current:** Keyboard (↑↓ threshold, ←→ scale, R reset, N new seed)  
**VR Status:** ⚠️ Not usable in VR

**Required changes:**
- [ ] Add `slider_horizontal` for threshold (-1 to 1)
- [ ] Add `slider_horizontal` for noise scale
- [ ] Add `dial_smooth` for octaves (1-6)
- [ ] Add `push_button` for new seed
- [ ] Add `push_button` for reset

**VR Sculpting (future):**
- [ ] Controller trigger = add voxels at controller position
- [ ] Controller grip = remove voxels at controller position

---

### 8. `lsystem_editor` ⚠️ Needs VR Controls

**Current:** Keyboard (1-7 presets, ←→ generations, ↑↓ angle)  
**VR Status:** ⚠️ Not usable in VR

**Required changes:**
- [ ] Add `lever_smooth` with 7 positions for preset
- [ ] Add `slider_horizontal` for generations (1-12)
- [ ] Add `dial_smooth` for angle (5-90°)

---

### 9. `bias_visualizer` ⚠️ Needs VR Controls

**Current:** Keyboard (1-3 analogies, Space rotate)  
**VR Status:** ⚠️ Not usable in VR

**Required changes:**
- [ ] Add 3 `push_button` for analogy selection
- [ ] Add `lever_smooth` for rotation on/off
- [ ] Make word spheres grabbable (inspect word details)

---

## Implementation Priority

### Phase 1: Quick Fixes (observe-only artifacts)
1. `boids_aquarium` — add optional parameter sliders
2. `bifurcation_walkway` — already works

### Phase 2: Core Controls (parameter-driven artifacts)  
3. `ca_rule_explorer` — rule + speed sliders
4. `mandelbrot_dive` — zoom + pan + palette
5. `turing_pattern_generator` — presets + feed/kill

### Phase 3: Complex Interaction
6. `jelly_cube` — grabbable soft body
7. `perlin_terrain_sculptor` — threshold + VR sculpting
8. `lsystem_editor` — preset + generation + angle
9. `bias_visualizer` — analogy buttons + grabbable words

---

## Standard Control Panel Template

Each artifact should have a consistent control panel:

```gdscript
# Add to artifact scene:
var control_panel = preload("res://commons/interactables/artifact_control_panel.tscn").instantiate()
control_panel.position = Vector3(0, 0, -display_size/2 - 0.15)
add_child(control_panel)

# Connect signals
control_panel.get_node("Slider1").slider_moved.connect(_on_param1_changed)
control_panel.get_node("ResetButton").pressed.connect(_on_reset)
```

### Panel Layout Standard
- Width: ~0.4m
- Height: ~0.2m
- Sliders: 0.22m wide (matches slider_horizontal.tscn)
- Buttons: 0.04m diameter
- Spacing: 0.02m between elements
- Position: In front of artifact, angled toward user

---

## Files to Create

1. `commons/interactables/artifact_control_panel.tscn` — reusable panel base
2. Update each artifact to include control panel
3. Connect slider/button signals to artifact parameters

---

## Tracking

- [ ] Create `artifact_control_panel.tscn`
- [ ] Update `boids_aquarium`
- [ ] Update `jelly_cube` (add XRToolsPickable)
- [ ] Update `ca_rule_explorer`
- [ ] Update `mandelbrot_dive`
- [ ] Update `turing_pattern_generator`
- [ ] Update `perlin_terrain_sculptor`
- [ ] Update `lsystem_editor`
- [ ] Update `bias_visualizer`

---

*This review ensures all artifacts work in VR using standard interactable patterns.*
