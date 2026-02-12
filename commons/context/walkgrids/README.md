# 🌊 Walkable Mathematical Spaces

*Every algorithm becomes a landscape. Every landscape teaches.*

---

## The System

`TopologyManager` orchestrates a library of **20 walkable mathematical surfaces**, each generated procedurally from a different algorithm. All extend `TopologySpace` — the base class that handles mesh generation, collision, and material.

Toggle spaces on/off in the Inspector. They line up along the X axis, `space_separation` apart. Add more at runtime with `add_space_at_runtime("key")`.

---

## The Spaces

### Core (5)

| Space | Algorithm | Character |
|-------|-----------|-----------|
| **SineSpace** | `sin(x) * cos(z)` | Smooth, metallic, predictable. The surveillance landscape. |
| **NoiseSpace** | FastNoiseLite fractal | Rough, organic, resistant. Where prediction fails. |
| **VoronoiSpace** | Nearest-point territories | Flat plateaus with sharp borders. Biological division. |
| **RandomSpace** | Pure `randf()` chaos | Animated mathematical anarchy. 4 animation modes. |
| **FractalSpace** | Diamond-square / midpoint | Recursive self-similarity. 3 algorithms. |

### Cellular & Emergent (3)

| Space | Algorithm | Character |
|-------|-----------|-----------|
| **WorleySpace** | Worley noise (cellular noise) | Cracked earth, cell walls. 5 distance combos × 4 metrics. |
| **CellularAutomataSpace** | Game of Life + 5 variants | Geological layers from emergent life. Cave, Maze, Diamoeba… |
| **ReactionDiffusionSpace** | Gray-Scott model | Turing patterns: spots, stripes, spirals, coral, worms. Live evolution. |

### Mathematical Structures (6)

| Space | Algorithm | Character |
|-------|-----------|-----------|
| **MandelbrotSpace** | Iteration count → height | Walk the boundary of decidability. 6 zoom presets. |
| **LSystemSpace** | L-system turtle → height | Branching grammars as ridges. Tree, Koch, dragon curve, Hilbert… |
| **WaveInterferenceSpace** | Superposition of sources | Constructive/destructive patterns. Double-slit, ripple tank. Animated. |
| **RidgedNoiseSpace** | Ridged multifractal | Mountain ranges, canyons, dragon spines. Terracing + erosion. |
| **SphericalHarmonicsSpace** | Y_l^m projected flat | Electron orbitals as terrain. Single, sum, superposition, hybrid. |
| **FlowFieldSpace** | Vector field potential → height | Vortices, sources/sinks, dipoles, saddle points. The landscape of forces. |

### Terrain & Simulation (2)

| Space | Algorithm | Character |
|-------|-----------|-----------|
| **DomainWarpSpace** | Noise-warped noise (Quilez) | Organic, fluid, lava-lamp terrain. Marble, wood grain, crystalline. |
| **ErosionSpace** | Hydraulic erosion simulation | 50K water droplets carving river valleys into noise terrain. |

### Topology & Non-Euclidean (3)

| Space | Algorithm | Character |
|-------|-----------|-----------|
| **MöbiusSpace** | Möbius strip → height field | Non-orientable topology. 3 projection modes. Variable twist. |
| **TorusSpace** | Torus parameterization | Gaussian curvature, Villarceau circles, flat torus. |
| **HyperbolicSpace** | Poincaré disk model | Negative curvature. Space compresses at the edge. Tiling overlay. |

### Meta (1)

| Space | Algorithm | Character |
|-------|-----------|-----------|
| **KnowledgeTerrainSpace** | Curriculum → terrain | QFEP phases as elevation. Concept markers. Spine paths. |

---

## Shared Assets

**`terrain_height_color.gdshader`** — Drop-in shader for any space. Colors terrain by elevation (valley→mid→peak gradient), with optional contour lines, slope shading, and fresnel rim.

```gdscript
# Apply the shader to any space:
var shader_mat = ShaderMaterial.new()
shader_mat.shader = load("res://commons/context/walkgrids/terrain_height_color.gdshader")
shader_mat.set_shader_parameter("color_low", Color(0.1, 0.05, 0.2))
shader_mat.set_shader_parameter("color_high", Color(1.0, 0.9, 0.7))
shader_mat.set_shader_parameter("show_contours", true)
$SomeSpace/StaticBody3D/MeshInstance3D.material_override = shader_mat
```

---

## Quick Start

```gdscript
# Enable in Inspector or code:
var tm = $TopologyManager
tm.create_mandelbrot_space = true
tm.create_erosion_space = true
tm.create_reaction_diffusion_space = true

# Navigate
tm.next_space()
var pos = tm.teleport_to_space_by_name("MandelbrotSpace")

# Runtime addition
tm.add_space_at_runtime("worley")
tm.add_space_at_runtime("spherical_harmonics")
tm.add_space_at_runtime("domain_warp")

# Get all active space names
print(tm.get_space_names())
```

## Extending

```gdscript
extends TopologySpace
class_name MySpace

func generate_space():
    var heights = []
    for z in range(resolution + 1):
        for x in range(resolution + 1):
            heights.append(your_algorithm(x, z) * height_scale)
    var mesh = create_mesh_from_heights(heights)
    mesh_instance.mesh = mesh
    create_collision_from_mesh(mesh)
```

Add to `TopologyManager.SPACE_REGISTRY` to make it toggle-able.

---

## File Inventory

```
walkgrids/
├── TopologySpace.gd              # Base class — mesh gen, collision, materials
├── TopologyManager.gd             # Orchestrator — registry, navigation, runtime API
├── terrain_height_color.gdshader  # Shared height-gradient shader
│
├── SineSpace.gd                   # ── Core ──
├── NoiseSpace.gd
├── VoronoiSpace.gd
├── RandomSpace.gd
├── FractalSpace.gd
│
├── WorleySpace.gd                 # ── Cellular & Emergent ──
├── CellularAutomataSpace.gd
├── ReactionDiffusionSpace.gd
│
├── MandelbrotSpace.gd             # ── Mathematical Structures ──
├── LSystemSpace.gd
├── WaveInterferenceSpace.gd
├── RidgedNoiseSpace.gd
├── SphericalHarmonicsSpace.gd
├── FlowFieldSpace.gd
│
├── DomainWarpSpace.gd             # ── Terrain & Simulation ──
├── ErosionSpace.gd
│
├── MobiusSpace.gd                 # ── Topology & Non-Euclidean ──
├── TorusSpace.gd
├── HyperbolicSpace.gd
│
├── KnowledgeTerrainSpace.gd       # ── Meta ──
│
└── *.tscn                         # Scene files for each space
```

---

## Presets & Variations

Most spaces have internal presets (enums in the Inspector):

- **ReactionDiffusion**: Spots, Stripes, Spirals, Coral, Holes, Worms
- **CellularAutomata**: Game of Life, HighLife, Day&Night, Diamoeba, Maze, Cave
- **Mandelbrot**: Full Set, Seahorse Valley, Elephant Valley, Spiral, Mini-Brot, Lightning
- **LSystem**: Tree, Koch Island, Dragon Curve, Sierpinski, Hilbert, River Delta
- **WaveInterference**: Circular, Plane, Double-Slit, Mixed, Ripple Tank
- **RidgedNoise**: Mountain Range, Canyon Network, Dragon Spine, Eroded Plateau, Alien Geology
- **DomainWarp**: Organic, Crystalline, Turbulent, Marble, Wood Grain
- **FlowField**: Vortex Array, Source/Sink, Dipole, Gradient Noise, Saddle Points, Electromagnetic
- **Worley**: F1, F2, F2−F1, F1+F2, F1×F2 × Euclidean/Manhattan/Chebyshev/Minkowski
- **Fractal**: Diamond-Square, Midpoint Displacement, Recursive Subdivision
- **SphericalHarmonics**: Single Y_l^m, Sum All Orders, Superposition, Orbital Hybrid
- **Möbius**: Height Map, Unrolled, Cylindrical
- **Torus**: Gaussian Curvature, Elevation, Meridian/Parallel Waves, Villarceau, Flat Torus
- **Hyperbolic**: Hyperbolic Distance, Gaussian Curvature, Geodesic Grid, Pseudosphere

**That's ~100+ distinct walkable terrains from 20 spaces.**
