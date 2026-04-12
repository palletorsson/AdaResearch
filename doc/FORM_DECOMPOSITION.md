# Form Decomposition — The Non-Destructive Pipeline

> How to reverse-engineer any form in the world and rebuild it from parameters.

## The Hierarchy of Form Creation

Every designed object — a chair, a tree, a crystal, a building, a face — was made by a sequence of operations. The sequence is the design. If you can identify the sequence, you can reproduce the form, vary it, evolve it, and understand it.

The 22 form-creation techniques in Ada Research are not 22 independent systems. They are instances of **5 fundamental stages** that compose into pipelines:

```
1. FIELD       — define a value everywhere in space
2. SKELETON    — define a path/graph/tree through space
3. SURFACE     — extract or sweep a boundary
4. MODIFY      — deform, displace, subdivide the boundary
5. POPULATE    — duplicate, scatter, array the result
```

Every form in the world is some combination of these 5 stages. A tree is: skeleton (L-system) → surface (tube sweep) → modify (noise) → populate (leaf scatter). A crystal is: field (lattice function) → surface (isosurface extraction). A building is: skeleton (floor plan graph) → surface (wall extrusion) → modify (boolean window cuts) → populate (column array).

## The 5 Stages in Detail

### Stage 1: FIELD
Define a scalar or vector value at every point in space.

| Technique | What it defines | Key parameter |
|-----------|----------------|---------------|
| Noise (Perlin, Simplex) | Density/height at every point | frequency, octaves, seed |
| SDF primitives | Distance to nearest surface | shape type, dimensions |
| SDF booleans | Combined distance (union/subtract/intersect) | operation, blend factor k |
| Reaction-diffusion | Chemical concentration over time | feed rate f, kill rate k |
| Cellular automaton | Cell state (alive/dead) per voxel | birth/survival rules |
| Metaball field | Sum of inverse-square influences | center positions, radii |
| Gyroid / TPMS | Triply-periodic minimal surface | frequency, phase |

**Output:** A function f(x,y,z) → float. Not a mesh. A field.

### Stage 2: SKELETON
Define a 1D structure (path, tree, graph) through space.

| Technique | What it defines | Key parameter |
|-----------|----------------|---------------|
| Spine (linear) | Ordered points along a line | point count, curvature |
| L-system | Branching string → turtle path | axiom, rules, angle, iterations |
| Space colonization | Growth toward attractors | influence distance, kill distance |
| DLA | Diffusion-limited path growth | stickiness, walker count |
| Voronoi edges | Cell boundary network | seed points |
| Curve3D | Bézier or catmull-rom spline | control points |
| Graph (adjacency) | Node-edge network | degree, topology |

**Output:** A set of connected positions with optional radii. Not a mesh. A skeleton.

### Stage 3: SURFACE
Extract or create a 2D boundary from a field or skeleton.

| Technique | Input | What it creates | Key parameter |
|-----------|-------|----------------|---------------|
| Marching cubes | Field → mesh | Triangulated isosurface | threshold |
| Tube sweep | Skeleton → mesh | Circular cross-section along path | radius, sides |
| Revolution | Profile curve → mesh | Axially symmetric surface | profile points, segments |
| Bézier sweep | Skeleton + profile → mesh | Arbitrary cross-section along curve | cross-section shape |
| Extrude | Face → mesh | Push face outward, create walls | distance, scale |
| Inset | Face → mesh | Shrink face inward, create border | amount |
| CSG boolean | Mesh + mesh → mesh | Union/subtract/intersect solids | operation type |
| Parametric | u,v equations → mesh | Mathematical surface | equation, u/v range |
| Convex hull | Point cloud → mesh | Wrapping surface | point set |

**Output:** A triangle mesh. The first actual geometry.

### Stage 4: MODIFY
Deform, refine, or reshape an existing mesh.

| Technique | What it does | Key parameter |
|-----------|-------------|---------------|
| Taper | Scale cross-section along axis | taper function |
| Twist | Rotate around axis by position | degrees |
| Bend | Curve around pivot | angle, pivot |
| Noise displace | Push vertices by noise along normals | strength, frequency |
| Wave | Sinusoidal displacement | frequency, amplitude |
| Inflate/deflate | Push all vertices along normals | amount |
| Spherize | Pull toward sphere | factor 0-1 |
| Subdivide | Add vertices, smooth | iterations |
| Physics sim | Gravity, springs, collision | stiffness, damping |
| Melt | Progressive softening | rate, gravity |
| Fold | Hinge/spring deformation | fold_amount, tension |

**Output:** A modified mesh. Same topology (usually), different shape.

### Stage 5: POPULATE
Duplicate, scatter, or array the result.

| Technique | What it does | Key parameter |
|-----------|-------------|---------------|
| Radial array | Copy N times around axis | count, radius |
| Grid array | Copy on 2D/3D grid | spacing, dimensions |
| Along-path | Copy at intervals along curve | spacing, curve |
| Surface scatter | Place randomly on surface | density, normal alignment |
| MultiMesh | GPU-instanced copies | instance count, transforms |
| Phyllotaxis | Golden-angle spiral placement | divergence angle |
| Symmetry | Mirror across planes/axes | symmetry order |

**Output:** Many instances of the mesh. An ecosystem, a pattern, a colony.

## The Non-Destructive Principle

The pipeline is non-destructive because **each stage stores its parameters, not its output**. Change a parameter at any stage and everything downstream regenerates.

```
Pipeline = [
  { stage: "field", type: "noise", params: { frequency: 0.5, octaves: 3, seed: 42 } },
  { stage: "surface", type: "marching_cubes", params: { threshold: 0.0, resolution: 32 } },
  { stage: "modify", type: "noise_displace", params: { strength: 0.1 } },
  { stage: "modify", type: "twist", params: { degrees: 45 } },
  { stage: "populate", type: "radial_array", params: { count: 6, radius: 2.0 } },
]
```

Change `frequency` from 0.5 to 0.8 → the entire form changes. The pipeline replays from that stage forward.

## Reverse-Engineering Any Form

To reverse-engineer a form, identify which stages produced it:

| Object | Field | Skeleton | Surface | Modify | Populate |
|--------|-------|----------|---------|--------|----------|
| Tree | — | L-system | Tube sweep | Noise bark | Leaf scatter |
| Crystal | Lattice SDF | — | Marching cubes | — | Cluster array |
| Building | — | Floor plan graph | Wall extrude | Boolean windows | Column array |
| Coral | — | Space colonization | Tube sweep | Noise texture | — |
| Mountain | Perlin noise | — | Heightmap mesh | Erosion sim | Rock scatter |
| Flower | — | Stem spine | Petal Bézier sweep | Taper + twist | Radial array |
| Vase | — | Profile curve | Revolution | — | — |
| Cloud | 3D Perlin | — | Isosurface | Advection | — |
| Face | — | — | Parametric | Noise detail | Symmetry mirror |
| Fabric | — | — | Plane mesh | Cloth physics | — |
| Maze | CA rules | — | Wall extrude | — | — |
| DNA helix | — | Double spiral | Tube sweep | — | Atom scatter |
| Snowflake | — | DLA growth | — | — | Hexagonal symmetry |
| Foam | Voronoi cells | — | Cell walls | Inflate | — |

## The Editor Architecture

Each stage gets its own editor panel. The panels compose vertically:

```
┌─────────────────────────────────────────────────────┐
│  FIELD         [noise ▼]  freq=0.5  oct=3  seed=42  │
├─────────────────────────────────────────────────────┤
│  SKELETON      [spine ▼]  points=6  curve=0.3       │
├─────────────────────────────────────────────────────┤
│  SURFACE       [sweep ▼]  radius=0.1  sides=8       │
├─────────────────────────────────────────────────────┤
│  MODIFY    [+ Add Modifier]                          │
│    ├── taper    amount=0.5                           │
│    ├── twist    degrees=90                           │
│    └── noise    strength=0.05  freq=1.0              │
├─────────────────────────────────────────────────────┤
│  POPULATE  [radial ▼]  count=6  radius=2.0           │
├─────────────────────────────────────────────────────┤
│         [3D PREVIEW VIEWPORT]                        │
└─────────────────────────────────────────────────────┘
```

Any stage can be bypassed (set to "none"). The pipeline rebuilds from the first changed stage downward. This is how Blender's modifier stack, Houdini's node graph, and Substance Designer all work — but ours is built from the actual algorithms in the project.

## QFEP Connection

The 5 stages map onto the QFEP framework:

- **Field** = E(S) — entropy, the raw material of possibility
- **Skeleton** = F — the ordering principle, the structure that selects
- **Surface** = the Markov blanket — the boundary between inside and outside
- **Modify** = φΔE — the rate of change, transformation over time
- **Populate** = λ — the edge parameter, how much the pattern repeats vs varies

## What the Editors Teach

Each editor we already built maps to one or more stages:

| Editor | Primary Stage | What it reveals |
|--------|--------------|-----------------|
| Parametric Surfaces | Surface (parametric) | How equations become boundaries |
| Mesh Grammar | Surface (extrude/inset) + Modify | How operations compose iteratively |
| Procedural Columns | Skeleton (profile) + Surface (revolution) | How profiles become solids via rotation |
| Mesh Modifier | Modify (all types) | How deformations compose non-commutatively |
| Pipeline | All 5 stages | How the full pipeline composes |
| Glass Tubes | Skeleton (curve) + Surface (sweep) | How Frenet frames follow curves |
| Sculpture | Field (SDF) + Surface (marching cubes) | How distance functions define boundaries |
| Sine Object | Surface (parametric) | How topology emerges from equations |
| Floor Pattern | Surface (tiling) + Populate (array) | How symmetry groups tile planes |
| Creature | All 5 stages (DNA-driven) | How genetics encode form potential |

## Next Editors to Build

The gaps in our coverage:

| Missing | Stage | What it would teach |
|---------|-------|-------------------|
| **Noise Field Editor** | Field | How noise parameters sculpt terrain |
| **Growth Editor** | Skeleton (growth) | How attractor-driven growth creates organic networks |
| **CA Form Editor** | Field (CA) | How local rules create global structure |
| **Boolean Editor** | Surface (CSG) | How solid operations carve and join |
| **Physics Form Editor** | Modify (physics) | How gravity and springs create draped/deformed form |
| **WFC Tiling Editor** | Populate (constraint) | How constraints produce valid tilings |
| **Reaction-Diffusion Editor** | Field (RD) | How two chemicals create leopard spots |

## The Universal Pipeline File Format

```json
{
  "name": "Coral Branch",
  "pipeline": [
    { "stage": "skeleton", "type": "space_colonization",
      "params": { "segment_length": 0.05, "influence_distance": 0.3, "kill_distance": 0.1 } },
    { "stage": "surface", "type": "tube_sweep",
      "params": { "start_radius": 0.02, "end_radius": 0.005, "sides": 6 } },
    { "stage": "modify", "type": "noise_displace",
      "params": { "strength": 0.01, "frequency": 2.0 } },
    { "stage": "modify", "type": "taper",
      "params": { "amount": 0.8 } }
  ]
}
```

Every form in the project can be described this way. The pipeline IS the design.
