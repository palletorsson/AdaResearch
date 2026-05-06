# Gyroid Cheese VR - Deleuzian Rhizome Space

A walkable VR scene featuring the **gyroid**, a triply periodic minimal surface that creates an infinite maze of interconnected tunnels. This mathematical structure embodies Gilles Deleuze's concept of the **rhizome**: a non-hierarchical network of connections where every point connects to every other, with no center or privileged direction.

## Mathematical Structure

### The Gyroid Surface

The gyroid is defined by the implicit equation:

```
sin(x)cos(y) + sin(y)cos(z) + sin(z)cos(x) = 0
```

**Discovered**: Alan Schoen (NASA, 1970) while researching minimal surfaces
**Property**: Triply periodic minimal surface (TPMS)
**Symmetry**: Cubic symmetry group I4₁32 (gyroid group)

### Key Properties

#### 1. **Triply Periodic**
The surface repeats infinitely in three orthogonal directions, creating an unbounded structure.

#### 2. **Minimal Surface**
At every point, the mean curvature is zero — the surface locally minimizes area. This is the same property that soap films have.

#### 3. **Two Labyrinths**
The gyroid divides 3D space into two distinct, intertwined labyrinthine networks that never intersect. Each is a multiply connected volume.

#### 4. **Constant Mean Curvature**
While the Gaussian curvature varies, the *mean* curvature H = 0 everywhere, making it a physical equilibrium configuration.

#### 5. **No Straight Lines**
Every path curves, yet the structure has perfect long-range order.

### Why "Cheese"?

The gyroid creates a solid perforated by continuous channels — like Swiss cheese, but with mathematical perfection. The "holes" aren't discrete voids but continuous tunnels that wrap around each other infinitely.

## Philosophical Connection: The Rhizome

### Deleuze & Guattari's Rhizome Principles

From *A Thousand Plateaus* (1980), the rhizome has six defining characteristics, all embodied by the gyroid:

#### 1-2. **Connection and Heterogeneity**
> "Any point of a rhizome can be connected to anything other, and must be."

The gyroid has no dead ends. Every tunnel connects to every other through multiple paths. There's no single "correct" route.

#### 3. **Multiplicity**
> "A multiplicity has neither subject nor object, only determinations, magnitudes, and dimensions."

The gyroid isn't composed of discrete "tubes" — it's a continuous manifold. The distinction between "solid" and "void" is arbitrary (depends on which side of the threshold you choose).

#### 4. **Asignifying Rupture**
> "A rhizome may be broken, shattered at a given spot, but it will start up again on one of its old lines, or on new lines."

Cut or modify the gyroid anywhere, and the topology remains: an interconnected labyrinth. There are no privileged nodes.

#### 5-6. **Cartography and Decalcomania**
> "A rhizome is not amenable to any structural or generative model... it is a map and not a tracing."

The gyroid has no hierarchical structure. It's pure multiplicity without a tree-like organization.

### The Anti-Tree

Deleuze contrasts the **rhizome** (network, web, multiplicity) with the **arborescent** (tree, hierarchy, unity):

| Tree | Rhizome (Gyroid) |
|------|------------------|
| Root and branches | No center, all points equivalent |
| Vertical hierarchy | Horizontal connections |
| Binary divisions | Multiple entrances |
| Traceable lineage | Map without origin |
| One path up, one down | Infinite paths everywhere |

The gyroid is the mathematical embodiment of rhizomatic space.

## Implementation Details

### Rendering: Ray Marching

The visual uses a **ray-marching shader** that traces rays through the implicit surface:

1. **Cast ray** from camera through each pixel
2. **March along ray** in small steps
3. **Evaluate field** function: `f(x,y,z) = gyroid(x,y,z) + noise(x,y,z)`
4. **Check distance** to threshold isosurface
5. **If hit**: Compute normal, apply lighting
6. **If miss**: Continue marching or show background

This technique allows rendering complex implicit surfaces that would be impossible to mesh efficiently.

#### Advantages
- Infinitely smooth surface
- No polygon count limitations
- Easy to animate (just change the field function)
- Mathematically exact representation

#### Disadvantages
- GPU-intensive (96 steps per pixel)
- No native depth buffer integration
- Requires depth_test_disable workaround

### Collision: Sphere Scaffold

Physical collisions use a **sparse grid of sphere colliders**:

1. **Sample the volume** on a coarse 3D grid (default: 26×18×26)
2. **Evaluate field** at each grid point
3. **Place sphere collider** if `|f - threshold| < band`
4. **Attach to StaticBody3D**

This creates a "scaffolding" that approximates the surface with ~800-1200 spheres.

#### Why Spheres?
- Fast collision detection
- Good approximation for curved surfaces
- Lightweight (no mesh processing)
- Easy to generate at runtime

#### Alternative: Marching Cubes
For higher fidelity, you could use marching cubes to generate a triangle mesh and create a single ConcavePolygonShape3D. This would be more accurate but slower to generate.

## Parameters

### Field Properties

#### `field_scale` (default: 1.0)
World scale multiplier for the entire structure.
- Affects the physical size of the gyroid pattern
- Usually left at 1.0 unless coordinating with other scales

#### `frequency` (default: 1.2)
Spatial frequency of the gyroid in radians per unit.
- **Higher**: More, smaller tunnels (dense cheese)
- **Lower**: Fewer, larger tunnels (open cheese)

#### `threshold` (default: 0.0)
Isosurface level to render.
- **Positive**: Shift toward one labyrinth
- **Negative**: Shift toward the other labyrinth
- **Zero**: Balanced, classic gyroid

#### `thickness` (default: 0.12)
Visual thickness of the surface shell.
- Controls how "thick" the walls appear
- Purely visual (doesn't affect collisions)

#### `noise_amp` (default: 0.25)
Amplitude of organic noise perturbation.
- **Zero**: Perfect mathematical gyroid
- **Higher**: More organic, irregular tunnels

#### `noise_freq` (default: 0.7)
Frequency of noise variation.
- Affects the "scale" of organic deformations

### Animation

#### `animate_phase` (default: true)
Enable time-based animation.
- Creates a subtle "breathing" effect
- Phase cycles through the noise function

#### `phase_speed` (default: 0.25)
Speed of animation in radians per second.

### Collision Grid

#### `collider_grid` (default: 26×18×26)
Resolution of the collision sampling grid.
- **Higher**: More accurate collisions, slower generation
- **Lower**: Faster generation, coarser collisions

#### `collider_iso_band` (default: 0.15)
How close to the isosurface to place colliders.
- Controls thickness of collision shell

#### `collider_radius` (default: 0.22)
Size of each collision sphere.
- Larger = smoother collisions, more blocked paths
- Smaller = more gaps, tighter paths

#### `max_colliders` (default: 1200)
Safety limit on collision sphere count.

### Visual Style

#### `base_color` (default: pale cyan)
Main color of the cheese surface.

#### `rim_color` (default: bright cyan)
Color for rim/edge lighting.

#### `hole_color` (default: dark blue-gray)
Background color seen through tunnels.

## Usage

### Basic Setup

1. **Open scene**: `res://algorithms/spacetopology/gyroid_cheese/gyroid_cheese_vr.tscn`
2. **Run**: F6 or VR preview
3. **Wait**: Collision generation takes 2-10 seconds
4. **Explore**: Walk through the tunnels

### Desktop Controls
- **WASD**: Move horizontally
- **Mouse**: Look around
- **Space/Ctrl**: Move up/down
- **Shift**: Sprint

### VR Setup

Replace the placeholder `Camera3D` with your XR rig:

```gdscript
# In the scene, replace Camera3D with:
var xr_origin = XROrigin3D.new()
var xr_camera = XRCamera3D.new()
var xr_left = XRController3D.new()
var xr_right = XRController3D.new()

# Add locomotion from godot-xr-tools
```

The `ColliderScaffold` is a `StaticBody3D`, so standard `CharacterBody3D` movement will work automatically.

### Tweaking in Real-Time

In the **Inspector**, you can adjust:
- **frequency**: Watch tunnels multiply or expand
- **threshold**: Shift between the two labyrinths
- **noise_amp**: Add organic irregularity
- **animate_phase**: Toggle breathing effect

To **rebuild collisions**, toggle `rebuild_colliders` in the inspector.

## Applications

### Scientific Visualization

#### Materials Science
- **Nanomaterials**: Block copolymers self-assemble into gyroid structures
- **Photonic crystals**: Gyroid structures have photonic bandgaps
- **Metamaterials**: Negative refractive index materials

#### Biology
- **Butterfly wings**: Some butterfly wing scales have gyroid structure
- **Cell membranes**: Cubic membrane structures in cells
- **Biomimetics**: Lightweight structural materials

#### Chemistry
- **Zeolites**: Porous crystals with gyroid-like channels
- **Surfactant mesophases**: Liquid crystal structures

### Art & Philosophy

#### Architecture
- Exploring non-Euclidean space perception
- Continuous interior/exterior ambiguity
- Pavilions and installations (see Zaha Hadid's work)

#### Game Design
- Maze generation without dead ends
- 3D racing tracks with no preferred direction
- Exploration-focused environments

#### VR Education
- Teaching minimal surfaces
- Demonstrating topological concepts
- Embodied mathematics

### Performance Art
- Navigating Deleuzian space
- Movement scores without choreography
- Participatory installations

## Mathematical Extensions

### Other Triply Periodic Minimal Surfaces

The gyroid is one of many TPMS. You could extend this scene to support:

#### **Schwarz P Surface**
```
cos(x) + cos(y) + cos(z) = 0
```
More cubic symmetry, smaller tunnels.

#### **Schwarz D Surface**
```
sin(x)sin(y)sin(z) + sin(x)cos(y)cos(z) + cos(x)sin(y)cos(z) + cos(x)cos(y)sin(z) = 0
```
Diamond structure, tetrahedral symmetry.

#### **Neovius Surface**
```
3(cos(x) + cos(y) + cos(z)) + 4cos(x)cos(y)cos(z) = 0
```
Similar to gyroid but with different symmetry.

### Level Set Animation

Animate the **threshold** parameter to morph between the two labyrinths:

```gdscript
func _process(delta):
    threshold = sin(time * 0.5) * 0.5
```

This creates a "phase transition" where solid becomes void and vice versa.

### Multi-Scale Composition

Layer multiple frequencies:

```gdscript
func _field_value(p: Vector3) -> float:
    var g1 = gyroid(p, 1.0)
    var g2 = gyroid(p, 2.5) * 0.3
    var g3 = gyroid(p, 5.0) * 0.1
    return g1 + g2 + g3
```

Creates a fractal-like self-similar structure.

## Performance Notes

### Ray Marching Cost

The shader performs **96 steps per pixel** at full resolution. On lower-end hardware:

- Reduce render resolution
- Lower `box_size` to shrink visible volume
- Reduce step count in shader (change `for(int i=0; i<96; i++)` to 64 or 48)

### Collision Generation

Building 1200 colliders takes 2-10 seconds depending on hardware. To optimize:

- Lower `collider_grid` resolution
- Reduce `max_colliders`
- Use async generation (call `_build_colliders()` from a thread)
- Cache the result as a scene resource

### Runtime Switching

For dynamic parameter changes, rebuild collisions manually:

```gdscript
func change_frequency(new_freq: float):
    frequency = new_freq
    await get_tree().create_timer(0.1).timeout  # Let shader update
    rebuild_colliders_now()
```

## Poetic Dimensions

### The Space of Flight

In *A Thousand Plateaus*, Deleuze writes of **"lines of flight"** — trajectories that escape stratification and open new becomings. The gyroid's tunnels are literal lines of flight: you can always escape, always find another path, always deterritorialize.

### Absence as Structure

The gyroid inverts the typical solid/void distinction:
- The "cheese" is defined by its holes
- The holes are as structural as the solid
- Neither is primary — they're complementary labyrinths

This echoes Deleuze's concept of **"lack as productive"**: absence isn't emptiness but generative potential.

### Immanent Geometry

Unlike a transcendent, imposed structure, the gyroid **emerges** from a simple local rule (minimal curvature). Order without organizer, pattern without plan — pure **immanence**.

## References

### Mathematical

- Schoen, A.H. "Infinite Periodic Minimal Surfaces Without Self-Intersections." NASA Technical Note D-5541 (1970)
- Hyde, S.T. et al. "The Language of Shape." Elsevier (1997)
- Karcher, H. "The Triply Periodic Minimal Surfaces of Alan Schoen and Their Constant Mean Curvature Companions." Manuscripta Mathematica 64.3 (1989)

### Philosophical

- Deleuze, G. & Guattari, F. "A Thousand Plateaus: Capitalism and Schizophrenia." University of Minnesota Press (1987)
- Deleuze, G. "Difference and Repetition." Columbia University Press (1994)
- Massumi, B. "A User's Guide to Capitalism and Schizophrenia." MIT Press (1992)

### Scientific Applications

- Michielsen, K. & Stavenga, D.G. "Gyroid Cuticular Structures in Butterfly Wing Scales." Journal of the Royal Society Interface 5 (2008)
- Schröder-Turk, G.E. et al. "Bicontinuous Geometries and Molecular Self-Assembly." Faraday Discussions 161 (2013)
- Dolan, J.A. et al. "Gyroid Optical Metamaterials." Advanced Optical Materials 3.1 (2015)

### Art & Architecture

- Otto, Frei. "Occupying and Connecting: Thoughts on Territories and Spheres of Influence with Particular Reference to Human Settlement." Edition Axel Menges (2009)
- Sabin, J.E. "Seeding the Chaosmosis: Topology, Emergence, and Architectural Morphogenesis." Ph.D. Thesis, University of Pennsylvania (2012)

## Files

- `gyroid_cheese_vr.tscn`: Main VR scene
- `gyroid_cheese_vr.gd`: Gyroid field evaluation, ray marching shader, collision generation
- `README.md`: This file

## Future Enhancements

1. **Marching Cubes Collision**: Replace sphere scaffold with high-fidelity mesh
2. **Interactive Sculpting**: VR controllers modify frequency/threshold in real-time
3. **Pathfinding AI**: Agent that navigates the rhizome
4. **Dual Labyrinth Visualization**: Color-code the two distinct tunnel networks
5. **Acoustic Simulation**: Ray-traced sound propagation through tunnels
6. **Growth Animation**: Watch the gyroid emerge from nothing via level-set evolution

---

*"A rhizome has no beginning or end; it is always in the middle, between things, interbeing, intermezzo."*
— Gilles Deleuze & Félix Guattari

*"The gyroid doesn't represent the rhizome — it is a rhizome."*
— This README

*Walk without destination. Every path is equivalent. Holes are not absence but breath.*
