# Spatial Partitioning

Algorithms that divide space into regions — Voronoi diagrams, BSP trees, Delaunay triangulation, and Poisson disk sampling.

## QFEP Connection

Spatial partitioning creates **order from points**. Scatter random seeds (E), and these algorithms impose structure (F): Voronoi gives each seed its territory, BSP recursively halves space, Delaunay connects neighbors optimally. Chaos in, organization out.

## Algorithms

### Voronoi Diagrams (`voronoi_diagram_3d/`)

Each point "owns" the region closest to it.

```
┌─────────────────────────┐
│       ·  │      ·       │
│    A     │    B         │
│          │              │
│──────────┼──────────────│
│          │              │
│    C     ·     D        │
│          │              │
└─────────────────────────┘
```

Applications:
- Cave systems
- Building interiors
- Fractured objects
- Coral reefs
- Rock formations

### Binary Space Partitioning (`binary_space_partitioning/`)

Recursively divide space with planes.

```
┌─────────────────────────┐
│           │             │
│     A     │      B      │
│           │─────────────│
│───────────│      C      │
│     D     │             │
└─────────────────────────┘
```

Applications:
- Dungeon generation
- Room layouts
- BSP trees for rendering

### Delaunay Triangulation (`delaunay_triangulation_3d_cell/`)

Connect points so no point lies inside any triangle's circumcircle.

```
    ·─────·
   /│\   /│\
  / │ \ / │ \
 ·──┼──·──┼──·
  \ │ / \ │ /
   \│/   \│/
    ·─────·
```

Properties:
- Maximizes minimum angle (no sliver triangles)
- Dual of Voronoi diagram
- Optimal for mesh generation

### Poisson Disk Sampling (`poisson_disk_sampling_3d/`)

Random points with minimum distance guarantee.

```
┌─────────────────────────┐
│  ·     ·     ·    ·     │
│     ·     ·     ·       │
│  ·     ·     ·     ·    │
│     ·     ·     ·       │
│  ·     ·     ·    ·     │
└─────────────────────────┘
```

Properties:
- No clustering (unlike pure random)
- Blue noise distribution
- Natural-looking scattering

## Relationships

```
Poisson Sampling ──► Voronoi Diagram
        │                  │
        │                  │ (dual)
        ▼                  ▼
   Random Points     Delaunay Triangulation
```

Poisson gives better seed distribution for Voronoi. Delaunay and Voronoi are mathematical duals.

## Parameters (Voronoi example)

| Export | Default | Description |
|--------|---------|-------------|
| `region_size` | (10,10,10) | Volume dimensions |
| `num_seeds` | 20 | Cell count |
| `seed_distribution` | Random | Seed placement method |
| `render_mode` | Outer faces | Visualization style |
| `resolution` | 32 | Boundary detail |

## Files

| Folder | Contents |
|--------|----------|
| `voronoi_diagram_3d/` | 3D Voronoi with applications |
| `voronoi_diagrams/` | 2D Voronoi variants |
| `binary_space_partitioning/` | BSP tree generation |
| `delaunay_triangulation_3d_cell/` | 3D triangulation |
| `poisson_disk_sampling_3d/` | Blue noise sampling |

## VR Experience

Walk through Voronoi caves, explore BSP-generated dungeons, see Delaunay meshes from inside. These algorithms create the spaces you inhabit — understanding them reveals the math behind procedural worlds.

## See Also

- `proceduralgeneration/` — Other generation methods
- `graphtheory/` — Graph structures from partitions
- `wfc/` — Constraint-based generation
