# Rhizomatic Maze Space

3D navigable maze generator using rhizomatic (non-hierarchical) network principles — organic tunnel systems without dead ends or clear solutions.

## QFEP Connection

Traditional mazes have a solution — one correct path (F). Rhizomatic mazes have **multiple valid paths**, cross-connections, loops (E). The `connection_probability` controls how networked the maze becomes. At high values, it stops being a maze at all — just interconnected space. λ as navigation paradigm.

## How It Works

```
Layer 3:    ·───·───·
           /│   │  /│
Layer 2:  ·─┼─·─┼─· │
         /│ │ │ │ │/│
Layer 1: ·─┼─·─┼─·─┼─·
           │   │   │
         ──┴───┴───┴──

Vertical layers connected by shafts.
Horizontal paths branch and reconnect.
Chambers form at high-connectivity nodes.
```

Algorithm:
1. Initialize seed growth points
2. Iterate: grow, branch, merge close points
3. Probabilistically add cross-connections
4. Identify chambers (high-connectivity nodes)
5. Build organic tunnel geometry

## Parameters

### Maze Structure
| Export | Default | Description |
|--------|---------|-------------|
| `maze_size` | (40, 20, 40) | Total volume |
| `path_width` | 2.5 | Tunnel diameter |
| `branch_probability` | 0.7 | Chance of branching |
| `connection_probability` | 0.4 | Lateral connections |
| `vertical_layers` | 3 | Stacked levels |
| `organic_distortion` | 0.8 | Path waviness |

### Growth
| Export | Default | Description |
|--------|---------|-------------|
| `growth_iterations` | 200 | Total growth steps |
| `merge_threshold` | 6.0 | Distance to merge points |
| `chamber_probability` | 0.15 | Enlarged node chance |
| `deadend_pruning` | 0.3 | Remove some dead ends |

### Visual
| Export | Default | Description |
|--------|---------|-------------|
| `tunnel_segments` | 8 | Cylinder smoothness |
| `surface_detail_level` | 3 | Mesh complexity |

## Materials

| Type | Use | Color |
|------|-----|-------|
| Tunnel | Main passages | Blue-grey |
| Chamber | Large nodes | Darker blue |
| Growth | Organic details | Green |

## Components

| Class | Purpose |
|-------|---------|
| `RhizomaticMazeSpace` | Main controller |
| `RhizomaticMazeGenerator` | Network generation |
| `RhizomaticPathNetwork` | Path queries |
| `OrganicMeshBuilder` | Geometry construction |
| `RhizomaticMaterials` | Material library |

## Files

| File | Purpose |
|------|---------|
| `RhizomaticMazeSpace.gd` | Main scene script |
| `RhizomaticMazeGenerator.gd` | Network algorithm |
| `RhizomaticPathNetwork.gd` | Navigation queries |
| `OrganicMeshBuilder.gd` | Mesh utilities |
| `RhizomaticMaterials.gd` | Material definitions |

## Usage

```gdscript
var maze = RhizomaticMazeSpace.new()
maze.maze_size = Vector3(60, 30, 60)  # Large maze
maze.connection_probability = 0.6  # Very interconnected
maze.vertical_layers = 5  # Multi-level
add_child(maze)
```

## VR Experience

Navigate a maze with no clear "correct" path. Every route leads somewhere; dead ends are rare. The challenge isn't finding THE way out — it's understanding the space itself. Chambers provide rest areas and orientation points. The organic geometry makes cardinal directions meaningless.

## Deleuze & Guattari Connection

From *A Thousand Plateaus*:
- **No beginning or end**: Enter anywhere, exit anywhere
- **Non-hierarchical**: No main path, no tributaries
- **Multiple entries**: Many ways in, many ways through
- **Cartography over tracing**: Map as you go, don't follow predetermined routes

## See Also

- `rhizomaticstructure/` — Simpler rhizomatic generation
- `proceduralgeneration/` — Maze algorithms
- `spacetopology/` — Topological variations
