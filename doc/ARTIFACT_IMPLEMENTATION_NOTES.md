# Artifact Implementation Notes

Detailed technical answers to implementation questions for priority artifacts.

---

## 1. bias_visualizer

**Question:** How do we make this, what dataset, critical view on data?

### Concept
Visualize how ML systems see differently than humans — the "coded gaze" (Joy Buolamwini). Not about training our own model, but **showing the bias embedded in existing systems**.

### Dataset Options (Public, Well-Documented Bias)

| Dataset | Bias Documented | Source |
|---------|-----------------|--------|
| **UTKFace** | Age/gender/ethnicity skew | Public, academic |
| **CelebA** | Western beauty bias | Public |
| **ImageNet-A** | Class imbalance, cultural bias | Public |
| **COMPAS recidivism** | Racial bias in predictions | ProPublica analysis |
| **Word2Vec embeddings** | Gender stereotypes (man:doctor :: woman:nurse) | Google News corpus |

### Recommended: Word Embedding Bias Demo
Easiest to implement, most visceral:

```gdscript
# Show word relationships that reveal bias
# man - woman + queen = king (expected)
# man - woman + doctor = nurse (bias!)

var embeddings = {
    "man": Vector3(0.8, 0.2, 0.5),
    "woman": Vector3(0.2, 0.8, 0.5),
    "doctor": Vector3(0.7, 0.3, 0.9),
    "nurse": Vector3(0.3, 0.7, 0.8),
    # ... precomputed from actual Word2Vec
}
```

### Visual Design
- 3D word cloud where words are positioned by embedding
- Lines connect related words
- Slider: "Debias strength" shows how relationships change
- Panel: Shows the analogy arithmetic

### Critical Layer
- Quote Buolamwini: "Who is included in the training data?"
- Reference Safiya Noble: Search results for "professional hairstyles"
- The bias isn't a bug, it's the training data

### Implementation Path
1. Precompute 50-100 word embeddings (download GloVe, extract subset)
2. Store as JSON resource
3. 3D visualization with grabbable word spheres
4. Analogy solver: user drags words, sees result

**Files to create:**
- `res://commons/artifacts/bias_visualizer/bias_visualizer.tscn`
- `res://commons/artifacts/bias_visualizer/word_embeddings.json`
- `res://commons/artifacts/bias_visualizer/bias_visualizer.gd`

---

## 2. boids_aquarium

**Question:** Make a 1m cube version based on existing.

### Existing Code
`algorithms/emergentsystems/boidflocking/boid_manager.gd` — already has:
- Boid spawning
- VR controller interaction
- Separation/alignment/cohesion

### Changes for 1m Cube Artifact

```gdscript
# boids_aquarium.gd
extends Node3D

@export var cube_size: float = 1.0  # 1 meter
@export var num_boids: int = 30     # Fewer for artifact scale
@export var boid_scale: float = 0.02  # Tiny fish

# Boundary enforcement
func _enforce_boundaries(boid: Node3D):
    var half = cube_size / 2.0
    var pos = boid.position
    
    # Soft boundary - steer away from edges
    var margin = 0.1
    var turn_force = Vector3.ZERO
    
    if pos.x > half - margin: turn_force.x = -1
    if pos.x < -half + margin: turn_force.x = 1
    # ... same for y, z
    
    return turn_force * boundary_strength
```

### Visual Design
- Glass cube (transparent material, subtle edges)
- Small fish/arrow meshes for boids
- Soft blue lighting inside
- Base pedestal (museum artifact style)

### Implementation
1. Copy `boid_manager.gd` → `boids_aquarium.gd`
2. Add boundary enforcement
3. Scale down (1m cube, small boids)
4. Add glass enclosure mesh
5. Make grabbable (whole artifact moves)

**Time estimate:** 2-3 hours (mostly adaptation)

---

## 3. turing_pattern_generator

**Question:** Performance issues, color options?

### Current State
`commons/interfaces/qfep/turing_pattern.gd` — uses shader-based fake Turing patterns (fbm noise, not real reaction-diffusion).

### Performance Problem
True Gray-Scott reaction-diffusion requires:
- Per-pixel convolution (Laplacian)
- Two chemical concentrations (U, V)
- Many iterations per frame

### Solutions

#### Option A: Shader-Only (Current, Fast but Fake)
Keep current approach but add color gradient:

```glsl
// Add color gradient uniform
uniform sampler2D color_gradient : source_color;

void fragment() {
    float pattern = turing(UV, time);
    vec3 col = texture(color_gradient, vec2(pattern, 0.5)).rgb;
    ALBEDO = col;
}
```

#### Option B: Compute Shader (Real, Performant)
Use Godot 4's compute shaders:

```gdscript
# Run reaction-diffusion on GPU
var rd = RenderingServer.create_local_rendering_device()
var shader_file = load("res://shaders/gray_scott_compute.glsl")
# ... dispatch compute shader, read back texture
```

#### Option C: Lower Resolution + Upscale (Compromise)
- Run at 32x32 or 64x64
- Use bilinear upscaling to display
- Still visible patterns, much faster

### Color Implementation
Reaction-diffusion produces values 0-1. Map to gradient:

```gdscript
@export var color_gradient: Gradient

# In shader or on CPU:
# pattern_value → gradient.sample(pattern_value)
```

**Predefined palettes:**
- Leopard: yellow → brown → black
- Zebra: white → black
- Coral: pink → purple → blue
- Alien: green → cyan → magenta

### Recommendation
Option C (low-res + upscale) with color gradients. Real patterns, acceptable performance.

**Time estimate:** 4-6 hours

---

## 4. ca_rule_explorer

**Question:** 1x1m horizontal board, interactive.

### Existing Implementations
- `algorithms/cellularautomata/cellular_automata_1d/` — Wolfram 1D
- `algorithms/cellularautomata/rule_30_110/` — Specific rules

### Design: 1x1m Horizontal Board

```
     [Rule Display: 110]
    ┌─────────────────────┐
    │░▓░░▓▓░▓░░▓▓▓░░▓░▓░░│  ← Current row (newest)
    │▓░▓░░▓░▓▓░░▓░▓▓░░▓▓░│
    │░░▓▓░░▓░░▓▓░░▓░░▓░░▓│
    │▓░░▓▓░░▓░░▓▓░░▓░░▓░░│
    │  ...50 rows...      │  ← History scrolls down
    └─────────────────────┘
        [Rule Slider 0-255]
        [Speed Slider]
        [Reset Button]
```

### Implementation

```gdscript
# ca_rule_explorer.gd
extends Node3D

@export var board_size: float = 1.0
@export var cells_x: int = 64
@export var rows_visible: int = 50
@export var rule: int = 110

var grid: Array[Array] = []
var cell_meshes: Array[MeshInstance3D] = []
var current_row: Array[bool] = []

func _apply_rule(left: bool, center: bool, right: bool) -> bool:
    # Wolfram rule encoding
    var index = (int(left) << 2) | (int(center) << 1) | int(right)
    return (rule >> index) & 1 == 1

func _advance():
    var new_row: Array[bool] = []
    for i in range(cells_x):
        var left = current_row[(i - 1 + cells_x) % cells_x]
        var center = current_row[i]
        var right = current_row[(i + 1) % cells_x]
        new_row.append(_apply_rule(left, center, right))
    
    grid.push_front(new_row)
    if grid.size() > rows_visible:
        grid.pop_back()
    current_row = new_row
    _update_display()
```

### Controls (VR Sliders)
- **Rule slider:** 0-255 with label showing current rule
- **Speed slider:** Generations per second
- **Reset button:** Randomize or single-cell start

### Visual
- Use MultiMesh for performance (64 × 50 = 3200 cells)
- Black/white cubes or colored gradient based on age
- Table-height pedestal

**Time estimate:** 3-4 hours

---

## 5. lsystem_editor

**Question:** Taxonomy editor implementation?

### Current State
`utils/lsystem.gd` — LSystem class with presets (Koch, Sierpinski, Dragon, Plant)

### Concept: Visual Grammar Editor

```
┌─────────────────────────────────────┐
│  L-SYSTEM EDITOR                    │
├─────────────────────────────────────┤
│  AXIOM: [F]                         │
│                                     │
│  RULES:                             │
│  F → [F+F] [F-F] [F]               │
│  + → +                              │
│  - → -                              │
│                                     │
│  [Add Rule] [Delete] [Preset ▼]    │
├─────────────────────────────────────┤
│  PARAMETERS:                        │
│  Angle: [25°]  Length: [0.1m]      │
│  Generations: [4]                   │
│                                     │
│  [Generate] [Animate]               │
└─────────────────────────────────────┘
```

### Implementation Architecture

```gdscript
# lsystem_editor.gd
extends Node3D

signal grammar_changed(axiom: String, rules: Dictionary)
signal preview_requested(generations: int)

@export var axiom: String = "F"
@export var rules: Dictionary = {"F": "F[+F]F[-F]F"}
@export var angle: float = 25.0
@export var length: float = 0.1
@export var generations: int = 3

# UI Components
var axiom_input: LineEdit3D  # Custom 3D text input
var rule_list: VBoxContainer3D
var preview_mesh: ImmediateMesh

# Presets from taxonomy
const PRESETS = {
    "Koch Curve": {"axiom": "F", "rules": {"F": "F+F-F-F+F"}, "angle": 90},
    "Sierpinski": {"axiom": "F-G-G", "rules": {"F": "F-G+F+G-F", "G": "GG"}, "angle": 120},
    "Dragon Curve": {"axiom": "FX", "rules": {"X": "X+YF+", "Y": "-FX-Y"}, "angle": 90},
    "Plant": {"axiom": "X", "rules": {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"}, "angle": 25},
    "Bush": {"axiom": "F", "rules": {"F": "FF+[+F-F-F]-[-F+F+F]"}, "angle": 22.5},
    "Fern": {"axiom": "X", "rules": {"X": "F-[[X]+X]+F[+FX]-X", "F": "FF"}, "angle": 25},
}

func _load_preset(preset_name: String):
    var preset = PRESETS[preset_name]
    axiom = preset.axiom
    rules = preset.rules
    angle = preset.angle
    _update_ui()
    _regenerate()
```

### Taxonomy Integration
Connect to existing sequence data:

```gdscript
# Load L-system examples from curriculum
var lsystems_sequence = load("res://commons/maps/sequences/lsystems.json")
# Extract grammar definitions from each map
```

### Visual Output
- ImmediateMesh for turtle graphics
- Or: spawn actual 3D primitives (cylinders for stems, leaves)
- Live preview updates as rules change

**Time estimate:** 6-8 hours (complex UI)

---

## 6. jelly_cube

**Question:** Look into SoftBody3D, make more examples.

### Godot SoftBody3D Basics

```gdscript
# jelly_cube.gd
extends SoftBody3D

@export var jiggle_factor: float = 0.5
@export var pressure: float = 1.0

func _ready():
    # SoftBody3D settings
    simulation_precision = 5
    damping_coefficient = 0.01
    pressure_coefficient = pressure
    
    # Enable VR grabbing
    collision_layer = 262144  # Grabbable layer
```

### Existing Implementations
- `algorithms/softbodies/rounded_softbody.gd`
- `algorithms/physicssimulation/softbody3d/`

### New Examples to Create

| Example | Description |
|---------|-------------|
| `jelly_cube` | Basic grabbable jelly |
| `cloth_flag` | Cloth pinned at top |
| `bouncy_ball` | High pressure sphere |
| `water_balloon` | Thin membrane, high pressure |
| `slime_puddle` | Low pressure, spreads |

### Implementation

```gdscript
# For each: configure SoftBody3D parameters
static func create_jelly_cube() -> SoftBody3D:
    var body = SoftBody3D.new()
    body.simulation_precision = 10
    body.damping_coefficient = 0.02
    body.linear_stiffness = 0.5
    body.pressure_coefficient = 1.0
    
    # Add mesh
    var mesh = BoxMesh.new()
    mesh.size = Vector3(0.3, 0.3, 0.3)
    mesh.subdivide_depth = 4
    mesh.subdivide_height = 4
    mesh.subdivide_width = 4
    body.mesh = mesh
    
    return body
```

### Key Parameters for "Queer Morphology"
- **Low stiffness + high pressure:** Blobby, organic
- **High damping:** Slow, viscous movement
- **Subdivision:** More = smoother deformation

**Time estimate:** 3-4 hours (multiple variants)

---

## 7. perlin_terrain_sculptor

**Question:** Voxel sculpture with noise.

### Concept
Carve/add voxels using noise as the brush. Like sculpting but the tool is Perlin noise.

### Implementation Architecture

```gdscript
# perlin_terrain_sculptor.gd
extends Node3D

@export var grid_size: int = 32  # 32³ voxels
@export var voxel_size: float = 0.03  # ~1m total

var voxels: Array[bool] = []  # Occupancy grid
var multimesh: MultiMesh

# Noise parameters (controllable by sliders)
@export var noise_scale: float = 4.0
@export var noise_octaves: int = 3
@export var noise_threshold: float = 0.5

var noise: FastNoiseLite

func _ready():
    noise = FastNoiseLite.new()
    noise.noise_type = FastNoiseLite.TYPE_PERLIN
    
func sculpt_add(center: Vector3, radius: float):
    # Add voxels where noise > threshold
    for x in range(-radius, radius):
        for y in range(-radius, radius):
            for z in range(-radius, radius):
                var world_pos = center + Vector3(x, y, z) * voxel_size
                var noise_val = noise.get_noise_3d(
                    world_pos.x * noise_scale,
                    world_pos.y * noise_scale,
                    world_pos.z * noise_scale
                )
                if noise_val > noise_threshold:
                    _set_voxel(x, y, z, true)

func sculpt_remove(center: Vector3, radius: float):
    # Inverse - remove where noise > threshold
    # ...
```

### Controls
- Trigger: Add voxels
- Grip: Remove voxels
- Sliders: Scale, octaves, threshold
- Wand follows controller

### Visual
- MultiMesh cubes
- Or: Marching cubes for smooth surface
- Color by height/depth

**Time estimate:** 6-8 hours

---

## 8. mandelbrot_dive

**Question:** Performance, lower resolution, 1x1 cube table.

### Current State
`algorithms/fractals/mandelbrot_set/MandelbrotSet.gd`:
- Resolution 100 × 100 = 10,000 cubes
- Uses MultiMesh (good)
- Full computation on CPU (slow)

### Performance Optimizations

#### Option A: Lower Resolution
```gdscript
@export var resolution := 50  # Down from 100
# 50² = 2500 cubes (4x faster)
```

#### Option B: Shader-Based (GPU)
Move computation to fragment shader:

```glsl
shader_type spatial;

uniform vec2 center = vec2(-0.5, 0.0);
uniform float zoom = 1.0;
uniform int max_iter = 100;

void fragment() {
    vec2 c = center + (UV - 0.5) * 4.0 / zoom;
    vec2 z = vec2(0.0);
    int iter = 0;
    
    for (int i = 0; i < max_iter; i++) {
        if (dot(z, z) > 4.0) break;
        z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;
        iter++;
    }
    
    float t = float(iter) / float(max_iter);
    ALBEDO = mix(vec3(0.0), vec3(0.5, 0.8, 1.0), t);
}
```

#### Option C: 1x1 Cube Table Design
Not a wall, but a table-top display:

```
      ┌─────────────────┐
      │  MANDELBROT     │  ← Flat quad with shader
      │  [zoom control] │
      └─────────────────┘
            ║
       ┌────╨────┐
       │ pedestal │
       └─────────┘
```

### Recommended: Shader + Low-Res Height

```gdscript
# mandelbrot_dive.gd
extends Node3D

@export var table_size: float = 1.0
@export var height_resolution: int = 50  # For 3D bumps
@export var visual_resolution: int = 512  # Shader texture

# 3D surface at low res (50x50 vertices)
# Shader renders high-res Mandelbrot on top
```

### Interaction
- Pinch to zoom
- Drag to pan center
- Slider for max iterations
- Reset button

**Time estimate:** 4-5 hours

---

## 9. bifurcation_walkway

**Question:** Walkable phase transition.

### Concept
A corridor where your **X position = r parameter** in the logistic map.

```
r=2.5          r=3.0          r=3.5          r=4.0
  │              │              │              │
  ○              ○              ○○             ░░░░
Stable         2-cycle       4-cycle         Chaos

Player walks left to right, sees:
- Stable fixed point
- Period doubling
- Windows of order
- Chaos
```

### Implementation

```gdscript
# bifurcation_walkway.gd
extends Node3D

@export var walkway_length: float = 10.0  # meters
@export var r_min: float = 2.5
@export var r_max: float = 4.0
@export var iterations: int = 100
@export var display_points: int = 50

var player: Node3D
var point_meshes: Array[MeshInstance3D] = []

func _process(_delta):
    if not player:
        return
    
    # Map player X position to r value
    var t = clamp((player.global_position.x - global_position.x) / walkway_length, 0, 1)
    var r = lerp(r_min, r_max, t)
    
    # Calculate logistic map attractor
    var x = 0.5
    var attractor_points: Array[float] = []
    
    # Iterate to attractor
    for i in range(iterations):
        x = r * x * (1 - x)
    
    # Collect attractor values
    for i in range(display_points):
        x = r * x * (1 - x)
        attractor_points.append(x)
    
    # Display as vertical points
    _update_display(attractor_points, r)

func _update_display(points: Array[float], r: float):
    # Show points floating in front of player
    for i in range(points.size()):
        var y = points[i] * 2.0  # Scale to visible height
        # Position point mesh
```

### Visual Design
- Floor with r-value markings
- Floating spheres showing attractor(s)
- At r≈3.57: visible chaos onset
- Color transitions: blue (order) → green (edge) → red (chaos)

### QFEP Connection
- This IS the lambda parameter made physical
- λ≈0.4 is the edge of chaos (r≈3.57)

**Time estimate:** 4-5 hours

---

## 10. queer_morphology_specimen

**Question:** Final developed lab object, continued.

### Concept
The synthesis artifact — combines:
- Soft body physics (deformable matter)
- Fluid simulation (flowing form)
- QFEP responsiveness (reacts to λ, φ)
- Biological aesthetics (specimen jar)

### Design

```
       ┌──────────────────┐
       │   SPECIMEN JAR   │
       │  ┌────────────┐  │
       │  │   ~~~~     │  │  ← Fluid inside
       │  │  ~BLOB~    │  │  ← Morphing soft body
       │  │   ~~~~     │  │
       │  └────────────┘  │
       │                  │
       │  λ: 0.4  φ: 0.3  │  ← Responsive to QFEP
       └──────────────────┘
```

### Implementation Layers

1. **Glass Jar** — Static mesh, transparent
2. **Fluid** — Particle simulation or shader
3. **Specimen** — SoftBody3D with dynamic mesh
4. **QFEP Response** — Parameters change behavior

```gdscript
# queer_morphology_specimen.gd
extends Node3D

@export var base_stiffness: float = 0.5
@export var base_pressure: float = 1.0

var soft_body: SoftBody3D
var fluid_shader: ShaderMaterial

func _on_lambda_changed(lambda: float):
    # Low lambda: rigid, crystalline
    # High lambda: fluid, dissolving
    soft_body.linear_stiffness = lerp(0.9, 0.1, lambda)
    soft_body.pressure_coefficient = lerp(0.5, 2.0, lambda)

func _on_phi_changed(phi: float):
    # Negative phi: resists change
    # Positive phi: embraces transformation
    soft_body.damping_coefficient = lerp(0.5, 0.01, (phi + 1) / 2)
    # Also affects color/shader
```

### Aesthetic References
- Specimen jars in natural history museums
- Damien Hirst formaldehyde works
- Biological strangeness (deep sea creatures)

### This is the grant thesis embodied:
- "Queer morphology" — form that refuses fixed categories
- φ > 0 — valuing becoming over being
- Edge of chaos — where life exists

**Time estimate:** 8-12 hours (complex, synthesis of techniques)

---

## Summary: Implementation Order

| # | Artifact | Complexity | Hours |
|---|----------|------------|-------|
| 1 | boids_aquarium | Low | 2-3 |
| 2 | ca_rule_explorer | Medium | 3-4 |
| 3 | jelly_cube | Low | 3-4 |
| 4 | mandelbrot_dive | Medium | 4-5 |
| 5 | bifurcation_walkway | Medium | 4-5 |
| 6 | perlin_terrain_sculptor | Medium-High | 6-8 |
| 7 | turing_pattern_generator | Medium | 4-6 |
| 8 | bias_visualizer | Medium-High | 5-7 |
| 9 | lsystem_editor | High | 6-8 |
| 10 | queer_morphology_specimen | High | 8-12 |

**Total: ~50-65 hours** for all 10 priority artifacts

---

## Quick Wins First

Start with adaptations of existing code:
1. **boids_aquarium** — adapt boid_manager.gd
2. **jelly_cube** — adapt existing soft body
3. **ca_rule_explorer** — adapt cellular_automata_1d

Then new implementations:
4. **mandelbrot_dive**
5. **bifurcation_walkway**

Then complex:
6. **lsystem_editor**
7. **bias_visualizer**
8. **queer_morphology_specimen**
