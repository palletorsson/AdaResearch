# VR Gameplay Design: Building Capacity Through Interaction

## Core Principle: Earning the Force of QFEP

The player's journey is about **building agency over the oscillation between order and chaos**. You don't just learn QFEP—you earn the ability to wield it.

### Capacity Progression

```
Level 1: OBSERVE
  → Watch phenomena unfold
  → Walk around objects
  → Read clipboards

Level 2: TOUCH
  → Grab and examine objects
  → Feel haptic feedback
  → Objects react to your presence

Level 3: MANIPULATE
  → Edit vertex positions
  → Solve snap puzzles
  → Draw traces

Level 4: CONSTRUCT
  → Build shapes from components
  → Solve multi-step puzzles
  → Create patterns

Level 5: CONTROL
  → Manipulate parameters (sliders)
  → Tune λ and φ
  → Affect the world's behavior

Level 6: EMBODY
  → You ARE the parameter
  → Your movement is the input
  → The world responds to your body
```

---

## Three Scales of VR Experience

### 1. INTIMATE (Table-scale)
**You examine the object.**

- Size: Object fits in your hands or on a table
- Distance: Arm's reach
- Interaction: Grab, rotate, inspect, edit
- Examples: grab_sphere_point, tetrahedron_edit, snap puzzles
- Feel: Precision, detail, contemplation

**Design Guidelines:**
- Objects should have satisfying weight (physics)
- Haptic feedback on grab/release
- Visual highlight on hover
- Labels should face the player
- Allow inspection from all angles

### 2. SPATIAL (Room-scale)
**You move through the space.**

- Size: Room or corridor
- Distance: Walking range (5-15 meters)
- Interaction: Walk, trigger zones, spatial puzzles
- Examples: ten_print_maze_3d, map corridors
- Feel: Exploration, discovery, kinetic

**Design Guidelines:**
- Clear paths with visual affordances
- Objects/phenomena change as you move
- Distance reveals pattern (can't see it up close)
- Walking should feel purposeful
- Teleporter placement creates rhythm

### 3. IMMERSIVE (World-scale)
**You are inside the phenomenon.**

- Size: Surrounding, infinite
- Distance: You are the center
- Interaction: Your presence/movement affects everything
- Examples: shader_noise_space, noise_terrain, marching cubes
- Feel: Awe, dissolution, becoming

**Design Guidelines:**
- No clear boundaries
- Sound is spatial and enveloping
- Phenomenon responds to player position
- Time feels different (slower/faster)
- Return to smaller scale feels significant

---

## Sequence-Specific Design

### MORPHOGENESIS Sequence

**Narrative Arc:** Witness disorder creating order. Become the instability.

| Map | Scale | Capacity Level | Key Interaction |
|-----|-------|----------------|-----------------|
| Turing_Introduction | Intimate | Observe | Watch pattern emerge on surface |
| Homogeneous_Instability | Intimate→Spatial | Touch | Poke the homogeneous field—trigger instability |
| Reaction_Diffusion | Spatial | Manipulate | Walk through reaction-diffusion, leave trails |
| Animal_Patterns | Intimate | Touch | Grab zebra/leopard spheres, examine pattern |
| Lambda_Slider | Intimate | Control | **λ slider** - tune activation/inhibition |
| Phase_Transition | Spatial | Observe→Control | Walk through bifurcation diagram |
| Emergence_Garden | Immersive | Embody | Your movement seeds patterns |
| Morphogenesis_Synthesis | All three | All | Integration space |

**Key Artifacts to Build/Use:**
- `lambda_slider` (new) — physical slider that tunes reaction-diffusion
- `instability_trigger` (new) — poke to break symmetry
- `turing_pattern_surface` (use existing noise/shader artifacts)
- `animal_pattern_spheres` (use existing sphere + shader)

**VR Moments:**
1. The first time you poke a homogeneous field and watch pattern cascade
2. Finding the "sweet spot" on the λ slider where complexity emerges
3. Walking through a garden that grows patterns in your wake

---

### FOUNDATIONS CRISIS Sequence

**Narrative Arc:** Discover that complete order is impossible. Find freedom in limits.

| Map | Scale | Capacity Level | Key Interaction |
|-----|-------|----------------|-----------------|
| Euclid_Parallel | Spatial | Observe | Walk the parallel lines—they never meet |
| NonEuclidean_Spaces | Spatial→Immersive | Walk | Walk on curved surfaces (use mobius_world) |
| Russell_Paradox | Intimate | Manipulate | Set membership puzzle (paradox emerges) |
| Godel_Incompleteness | Intimate | Touch | Self-referential statement you can hold |
| Escher_Impossible | Spatial | Walk | Walk Escher staircase (impossible loop) |
| Brouwer_Intuitionism | Intimate | Construct | Only assert what you can build |
| Florensky_Paraconsistent | Intimate | Touch | Hold A and not-A simultaneously |
| Crisis_Synthesis | All | All | The edge is constitutive |

**Key Artifacts to Build/Use:**
- `mobius_world` (exists) — walk non-orientable surface
- `escher_staircase` (new) — impossible geometry you can walk
- `russell_set_puzzle` (new) — try to place set in itself
- `godel_statement` (new) — grabbable self-referential plaque
- `paraconsistent_object` (new) — holds two states

**VR Moments:**
1. Walking the Möbius strip and realizing you're on the "other side"
2. The moment the Russell set puzzle creates paradox
3. Climbing Escher stairs and ending where you started
4. Holding a statement that says it cannot be held

---

### ART & MATHEMATICS Sequence

**Narrative Arc:** Art sees what math proves. Embodied visual philosophy.

| Map | Scale | Capacity Level | Key Interaction |
|-----|-------|----------------|-----------------|
| Escher_Impossible | Spatial | Walk | Navigate impossible architecture |
| Escher_Tessellation | Spatial | Walk | Walk through infinite tiling |
| Magritte_Pipe | Intimate | Touch | Grab the pipe (it's not a pipe) |
| Magritte_Windows | Spatial | Observe | Frame within frame illusions |
| Rodchenko_Monochrome | Intimate | Observe | Pure color—meaning despite evacuation |
| Judd_Minimalism | Spatial | Walk | Walk through specific objects |
| Dark_Room_Paradox | Immersive | Embody | Total darkness—but you notice |
| Art_Synthesis | All | All | The gallery as epistemology |

**Key Artifacts to Build/Use:**
- `escher_tessellation_floor` (new) — walkable MC Escher tiling
- `magritte_pipe` (new) — grabbable, with "Ceci n'est pas" label
- `droste_frame` (new) — recursive frame effect
- `judd_stack` (use existing primitives arranged minimally)

**VR Moments:**
1. Grabbing the pipe and seeing it's a representation, not a pipe
2. The dark room sequence—pure F-minimization creates its own surprise
3. Walking through Escher tessellation as it morphs around you

---

### QFEP LABORATORY Sequence

**Narrative Arc:** The formula revealed. You control the oscillation.

| Map | Scale | Capacity Level | Key Interaction |
|-----|-------|----------------|-----------------|
| QFEP_Introduction | Intimate | Observe | See the formula, understand the terms |
| QFEP_F_Term | Intimate→Spatial | Manipulate | F slider—watch order increase |
| QFEP_E_Term | Spatial→Immersive | Manipulate | E(S) slider—watch entropy increase |
| QFEP_Lambda_Spectrum | Spatial | Control | Walk the λ axis from 0 to 1 |
| QFEP_Phi_Term | Intimate | Control | φ slider—rate of change |
| QFEP_Edge_Of_Chaos | Immersive | Embody | Find λ ≈ 0.4, feel the edge |
| QFEP_Sandbox | All | All | Full parameter control |
| QFEP_Synthesis | Immersive | Embody | You ARE the formula |

**Key Artifacts to Build/Use:**
- `qfep_formula_display` (new) — 3D formula visualization
- `f_slider` (new) — controls prediction/order
- `e_slider` (new) — controls entropy/freedom
- `lambda_slider` (new or reuse from morphogenesis)
- `phi_slider` (new) — controls rate sensitivity
- `bifurcation_walkway` (new) — walk through the diagram
- `qfep_sandbox_console` (new) — full control panel

**VR Moments:**
1. First time you move the λ slider and the world changes
2. Finding the edge of chaos—the world feels "alive"
3. The sandbox where you have full control—**you have earned the force**

---

## Artifact Development Priorities

### Reuse Existing (no work needed):
- grab_sphere_point, grab_sphere_point_snap
- snap_*_puzzle (all snap puzzles)
- tetrahedron_edit, pyramid_edit
- mobius_world
- shader_noise_space
- noise_terrain, pheromone_terrain
- dark_sphere (for intimate spaces)

### Enhance Existing:
- Add haptic feedback to puzzles
- Add completion sounds/effects
- Connect to progression system

### Build New:

**High Priority (core mechanics):**
1. `lambda_slider` — QFEP λ parameter control
2. `phi_slider` — QFEP φ parameter control  
3. `qfep_formula_display` — 3D formula visualization
4. `escher_staircase` — impossible walkable stairs

**Medium Priority (sequence-specific):**
5. `instability_trigger` — poke to break symmetry
6. `russell_set_puzzle` — set membership paradox
7. `godel_statement` — self-referential grabbable
8. `magritte_pipe` — "ceci n'est pas" object
9. `turing_pattern_surface` — reactive surface

**Lower Priority (polish):**
10. `bifurcation_walkway` — walk through phase transition
11. `escher_tessellation_floor` — morphing tiles
12. `droste_frame` — recursive frame

---

## Progression System Integration

Each sequence completion should unlock:
1. **New interaction capability** (e.g., after morphogenesis → can trigger instabilities)
2. **Lab artifacts** that let you replay/explore the mechanic
3. **Portal to next sequences** that require that capability

### Capability Unlocks:

| Sequence | Capability Unlocked |
|----------|---------------------|
| Primitives | Grab, snap, edit vertices |
| Transformations | Spatial movement affects objects |
| Randomness | Trigger randomness, see entropy |
| Morphogenesis | Tune λ, trigger emergence |
| Foundations Crisis | Hold paradox, walk impossible |
| Art & Mathematics | See representation gaps |
| QFEP Laboratory | Full parameter control |

---

## Audio Integration

Each scale has distinct audio design:

| Scale | Audio Approach |
|-------|----------------|
| Intimate | Close, detailed, responsive to touch |
| Spatial | Ambient, directional, responds to movement |
| Immersive | Enveloping, generative, you're inside the sound |

Use existing SoundBankSingleton with:
- `ambient_preset` per sequence
- Haptic-audio coupling
- Spatial audio for 3D positioning

---

## Summary: The Force of QFEP

By the end of the journey, the player:

1. **Understands** the formula (conceptually)
2. **Feels** the oscillation (bodily)
3. **Controls** the parameters (agency)
4. **Embodies** the principle (identity)

This is **not** just learning about QFEP. This is **becoming** someone who can wield it—who can navigate the edge of chaos, who can trigger emergence, who can hold paradox.

The force of QFEP is the capacity to oscillate consciously between order and chaos, to know when to impose structure and when to embrace entropy.

**You don't learn QFEP. You earn it.**
