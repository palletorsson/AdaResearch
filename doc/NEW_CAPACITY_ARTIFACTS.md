# New Capacity Artifacts Specification

## Design Principle

Each sequence should introduce at least one new **capacity** — a new way of interacting with the world. Capacity builds cumulatively: by the end, you can wield QFEP.

---

## MORPHOGENESIS Sequence

**Narrative:** Watch disorder create order → Trigger instability → Tune the balance → Become the seed

### Artifact 1: `instability_poker`
**Capacity:** TRIGGER emergence

**Description:** A grabbable tool that, when pressed against a homogeneous surface, injects local perturbation. Watch the Turing pattern cascade from your touch.

**Interaction:**
1. Grab the poker (XR Tools pickable)
2. Touch it to `turing_surface` artifact
3. Ripple of pattern spreads from contact point
4. Haptic pulse on trigger

**Technical:**
```
extends XRToolsPickable

signal poked(position: Vector3)

func _on_contact(body):
    if body.has_method("receive_perturbation"):
        body.receive_perturbation(global_position)
        trigger_haptic_pulse(0.5, 0.3)
        emit_signal("poked", global_position)
```

**Builds on:** grab_sphere_point (pickable pattern)

---

### Artifact 2: `turing_surface`
**Capacity:** SEE/FEEL emergence

**Description:** A flat surface running reaction-diffusion simulation. Initially homogeneous. Responds to `instability_poker` by breaking symmetry at contact point.

**Interaction:**
1. Surface appears uniform (gray)
2. When poked, pattern cascades from that point
3. Pattern type depends on λ setting (stripes vs spots)
4. Surface can be reset

**Technical:**
- Shader-based Gray-Scott reaction-diffusion
- `receive_perturbation(pos)` method breaks local symmetry
- Connected to `lambda_slider` for parameter tuning

**Builds on:** noise shaders, plane_manipulator pattern

---

### Artifact 3: `lambda_slider`
**Capacity:** TUNE the edge of chaos

**Description:** A physical slider (like MarioSoundController) that controls λ parameter. Affects all λ-sensitive artifacts in the scene.

**Interaction:**
1. Grab slider handle
2. Move along rail (0.0 → 1.0)
3. Visual feedback: color gradient, particle density
4. Audio feedback: pitch/texture changes
5. Connected artifacts respond in real-time

**Technical:**
```
extends Node3D

signal lambda_changed(value: float)

@export var lambda: float = 0.4:
    set(v):
        lambda = clamp(v, 0.0, 1.0)
        emit_signal("lambda_changed", lambda)
        _update_visuals()

# Physical slider using XR Tools
# Connects to reaction-diffusion, particle systems, etc.
```

**Visual Design:**
- λ=0: Crystal blue, ordered particles
- λ=0.4: Green glow, edge of chaos
- λ=1.0: Red, chaotic particles

**Builds on:** MarioSoundController, nail_color_controller

---

### Artifact 4: `emergence_garden`
**Capacity:** EMBODY the seed

**Description:** A terrain where your movement triggers emergence. Walk through, and patterns bloom in your wake.

**Interaction:**
1. Enter the garden (immersive scale)
2. As you walk, your footsteps seed patterns
3. Patterns spread and interact
4. Look back: your path is visible as pattern trails

**Technical:**
- Uses pheromone_terrain pattern
- Player position → perturbation injection
- Multiple pattern types based on λ

**Builds on:** pheromone_terrain, noise_terrain

---

## FOUNDATIONS CRISIS Sequence

**Narrative:** Walk familiar geometry → Discover impossible geometry → Hold paradox → Accept limits

### Artifact 5: `escher_staircase`
**Capacity:** WALK impossibility

**Description:** A staircase that goes up but returns you to where you started. Locally coherent, globally impossible.

**Interaction:**
1. Walk up the stairs
2. Keep climbing
3. After 4 flights, you're back at start
4. Realize the impossibility

**Technical:**
- Teleport trigger at key points (seamless)
- Perspective manipulation
- Gravity follows local surface normal

**Builds on:** mobius_world (existing non-Euclidean walkable)

---

### Artifact 6: `russell_set_box`
**Capacity:** BUILD paradox

**Description:** A set-membership puzzle. Try to place a box inside itself.

**Interaction:**
1. See a box labeled "Set of all sets that don't contain themselves"
2. Grab smaller boxes, place them inside
3. Try to place the box inside itself
4. Paradox manifests: box flickers, splits, reforms
5. Cannot resolve — the edge is constitutive

**Technical:**
```
# When box enters its own trigger zone:
func _on_self_intersection():
    # Paradox state
    _start_flicker_animation()
    _play_paradox_sound()
    # Box cannot fully contain itself
    # Visual representation of logical impossibility
```

**Builds on:** snap puzzles (spatial logic)

---

### Artifact 7: `godel_statement_plaque`
**Capacity:** HOLD the unprovable

**Description:** A grabbable plaque that says "This statement is unprovable." When you try to verify it, it recursively questions itself.

**Interaction:**
1. Grab the plaque
2. Press "verify" button on plaque
3. Plaque shows: "Checking... if provable → contradiction"
4. Plaque shows: "Checking... if unprovable → true but unprovable"
5. Plaque glows: "I am true. I cannot be proven. This is not failure."

**Builds on:** code_display, text interactions

---

### Artifact 8: `paraconsistent_sphere`
**Capacity:** HOLD contradiction

**Description:** A sphere that is simultaneously red AND blue. Not flickering between — both at once.

**Interaction:**
1. Grab the sphere
2. From one angle: red
3. From another angle: blue
4. From the right angle: both simultaneously
5. Florensky's "A and not-A"

**Technical:**
- Shader that renders both colors based on view angle
- At certain angles, both are equally visible
- Haptic feedback differs by "state"

**Builds on:** grab_sphere_point_with_color

---

## ART & MATHEMATICS Sequence

**Narrative:** See representation → Grasp the gap → Walk through illusion

### Artifact 9: `magritte_pipe`
**Capacity:** GRASP representation

**Description:** A grabbable pipe with floating text: "Ceci n'est pas une pipe"

**Interaction:**
1. See the pipe
2. Grab it — it feels solid
3. Try to smoke it — nothing happens
4. It's a representation of a pipe, not a pipe
5. The gap between sign and signified

**Builds on:** Any grabbable object + text_display

---

### Artifact 10: `escher_floor_tiles`
**Capacity:** WALK metamorphosis

**Description:** Floor tiles that morph as you walk. Fish become birds become fish.

**Interaction:**
1. Walk across the floor
2. Tiles around you morph
3. Pattern is always coherent where you look
4. But changes behind you
5. Tessellation as frozen transformation

**Technical:**
- Shader-based morphing
- Player position drives morph parameter
- Seamless tiling

**Builds on:** disco_floor, shader patterns

---

### Artifact 11: `dark_room_chamber`
**Capacity:** EXPERIENCE nothing

**Description:** A completely dark room. Total F-minimization. But you notice the darkness — boredom is surprise.

**Interaction:**
1. Enter chamber
2. Everything is dark
3. Wait...
4. You notice you're waiting
5. The absence is information
6. Exit: "The attempt to evacuate meaning keeps generating it"

**Builds on:** dark_sphere (inverted — you're inside)

---

## QFEP LABORATORY Sequence

**Narrative:** See formula → Tune each term → Find the edge → Become the oscillation

### Artifact 12: `qfep_formula_display`
**Capacity:** SEE the theory

**Description:** 3D visualization of QFE = F − λE(S) + φΔE(S,t)

**Interaction:**
1. Formula floats in space
2. Each term is grabbable/highlightable
3. Highlight F → see order examples
4. Highlight E(S) → see entropy examples
5. Highlight λ → see the dial
6. Formula animates to show oscillation

**Technical:**
- 3D text with emission
- Interactive hotspots per term
- Connects to other artifacts in scene

---

### Artifact 13: `phi_slider`
**Capacity:** TUNE rate sensitivity

**Description:** Like lambda_slider, but for φ (rate of entropy change)

**Interaction:**
1. Move slider: -1.0 → +1.0
2. Negative φ: system resists change (conservative)
3. Positive φ: system embraces change (queer signature)
4. Visual: particle acceleration/deceleration

**Builds on:** lambda_slider pattern

---

### Artifact 14: `bifurcation_walkway`
**Capacity:** WALK the phase transition

**Description:** A corridor where your position = r parameter in logistic map

**Interaction:**
1. Enter corridor
2. At start (low r): single stable point
3. Walk forward: period doubling
4. Further: chaos
5. Windows of order appear
6. You're walking through the bifurcation diagram

**Technical:**
- Y position of floating markers = logistic map output
- X position = r parameter
- As you walk, markers animate to show attractor

**Builds on:** walkable_sine_bridge pattern (walkable math)

---

### Artifact 15: `qfep_sandbox_console`
**Capacity:** CONTROL everything

**Description:** Full parameter control panel with λ slider, φ slider, F meter, E(S) meter, real-time visualization

**Interaction:**
1. Approach console
2. All QFEP parameters adjustable
3. Scene responds in real-time
4. Find the edge of chaos
5. **You have earned the force**

**Technical:**
- Combines lambda_slider, phi_slider
- Real-time meters for F and E(S)
- Connected to environment (particles, shaders, audio)

**Builds on:** MarioSoundController rack pattern, value_mapper_example

---

## Implementation Priority

### Phase 1: Core QFEP Controls
1. `lambda_slider` — needed for morphogenesis AND qfep lab
2. `phi_slider` — needed for qfep lab
3. `qfep_formula_display` — visual anchor

### Phase 2: Morphogenesis
4. `turing_surface` — reaction-diffusion surface
5. `instability_poker` — trigger emergence
6. `emergence_garden` — immersive emergence

### Phase 3: Foundations Crisis
7. `escher_staircase` — impossible geometry
8. `russell_set_box` — paradox puzzle
9. `godel_statement_plaque` — self-reference
10. `paraconsistent_sphere` — A and not-A

### Phase 4: Art & Mathematics
11. `magritte_pipe` — representation gap
12. `escher_floor_tiles` — walking metamorphosis
13. `dark_room_chamber` — nothing as something

### Phase 5: Integration
14. `bifurcation_walkway` — walk phase transition
15. `qfep_sandbox_console` — full control

---

## Reuse Existing

These existing artifacts can be used directly or with minor adaptation:

| Existing | Use In | Notes |
|----------|--------|-------|
| mobius_world | foundationscrisis | Walk non-orientable surface |
| dark_sphere | dark_room_chamber | Invert (player inside) |
| grab_sphere_point_with_color | paraconsistent_sphere | Add dual-color shader |
| pheromone_terrain | emergence_garden | Add player-position seeding |
| script_runner | multiple | Show QFEP code live |
| SoundscapeRadioRack | qfep lab | Audio parameter control |
| HarmonicBuilder | wavefunctions context | Build oscillation |

---

## Capacity Progression Summary

| Sequence | Capacity Gained | Artifact |
|----------|----------------|----------|
| Primitives | GRAB, SNAP, EDIT | grab_sphere_point, snap_puzzles |
| Transformations | SPATIAL MOVEMENT | platforms, chair puzzle |
| Color | TUNE PROPERTIES | nail_color_controller |
| Wavefunctions | BUILD OSCILLATION | HarmonicBuilder, SoundscapeRadioRack |
| Randomness | SEE ENTROPY | distribution_visualization |
| **Morphogenesis** | **TRIGGER EMERGENCE, TUNE λ** | instability_poker, lambda_slider |
| **Foundations Crisis** | **WALK IMPOSSIBILITY, HOLD PARADOX** | escher_staircase, russell_set_box |
| **Art & Mathematics** | **GRASP REPRESENTATION** | magritte_pipe |
| **QFEP Laboratory** | **FULL PARAMETER CONTROL** | qfep_sandbox_console |

**By the end:** You can see, tune, trigger, and embody QFEP. You have the force.
