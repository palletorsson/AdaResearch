# Subdivided Primitives

Mesh subdivision and smoothing comparison — transforming angular geometry into organic curves.

## QFEP Connection

Subdivision transforms **discrete into continuous**. A cube has 8 vertices (low F, simple); subdivide and smooth, and it approaches a sphere (high F, complex). The subdivision level is λ — how much computation do you invest to approach smoothness? Perfect smoothness requires infinite subdivision.

## How It Works

```
Level 0 (cube):       Level 1:            Level 2:            Level ∞ (sphere):
   ┌───────┐            ╭───────╮           ╭─────────╮           ╭─────────╮
   │       │           ╱         ╲         ╱           ╲         ╱           ╲
   │       │    →     │           │   →   │             │   →   │             │
   │       │           ╲         ╱         ╲           ╱         ╲           ╱
   └───────┘            ╰───────╯           ╰─────────╯           ╰─────────╯
   8 vertices           ~26 vertices        ~98 vertices          ∞ vertices
```

## Subdivision Methods

### Standard Subdivision
Each face splits into 4:
```
┌─────────┐       ┌────┬────┐
│         │   →   ├────┼────┤
│         │       │    │    │
└─────────┘       └────┴────┘
```

### Smooth Corner (Spherical Blending)
Vertices pushed outward toward enclosing sphere:
```
Original: sharp corners
Blended:  corners become curved
```

### Rounded Corner
Explicit corner geometry added:
```
Corner replaced with small spherical cap
```

## Parameters

| Variable | Description |
|----------|-------------|
| `subdivisions` | Number of subdivision iterations |
| `corner_radius` | For rounded corners, sphere blend radius |

## Comparison Scene

Three cubes side by side:
1. **Left**: Standard subdivided
2. **Center**: Smooth corner (vertex pushed)
3. **Right**: Rounded corner (explicit caps)

## Files

| File | Purpose |
|------|---------|
| `subdivided.gd` | Comparison generator |
| `*.tscn` | Scene file |

## Usage

```gdscript
var subdiv = preload("res://algorithms/primitives/subdivided/subdivided.tscn").instantiate()
add_child(subdiv)
```

## Technical Notes

- Uses `SurfaceTool` for procedural mesh generation
- `generate_normals()` creates smooth shading
- `generate_tangents()` enables normal mapping
- `index()` optimizes vertex sharing

## VR Experience

Compare the three cubes. The standard subdivision still shows facets at low levels; smooth corner looks more organic; rounded corner has explicit curved corners. All approach spherical as subdivision increases — but with different vertex counts and visual characteristics.

## Applications

- **Character modeling**: Smooth organic forms
- **Product design**: Rounded edges
- **CAD**: Filleted corners
- **Game assets**: LOD (level-of-detail) meshes

## Mathematical Note

Catmull-Clark subdivision converges to:
- Bi-cubic B-spline surfaces (regular regions)
- Extraordinary points at original vertices

Loop subdivision (for triangles) converges similarly.

## See Also

- `primitives/` — Other basic shapes
- `computationalgeometry/` — Mesh operations
- `fractals/` — Self-similar subdivision
