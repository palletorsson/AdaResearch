# Grid3D Substrate

> Walk through the data. Graphs you can stand inside.

Universal 3D graph visualization with dual MultiMesh rendering — spheres for nodes, cylinders for edges. Swappable algorithm cartridges for graph traversal, MST, shortest path, force-directed layout, and more.

## Architecture

```
grid3d_cartridge.gd     — Base class (RefCounted): initialize(), step(), node/edge colors
grid3d_renderer.gd      — Dual MultiMesh: nodes (spheres) + edges (oriented cylinders)
grid3d_substrate.gd     — Manager: cartridge lifecycle, play/pause/step, config
grid3d_node.gdshader    — Per-instance emission + idle pulse for nodes
grid3d_edge.gdshader    — Per-instance emission + alpha for edges
grid3d_substrate.tscn   — Minimal scene: renderer + label
```

### Scene Tree

```
Grid3DSubstrate (Node3D) [grid3d_substrate.gd]
├── Renderer (Node3D) [grid3d_renderer.gd]
│   ├── NodeMultiMesh (MultiMeshInstance3D) — spheres, created at runtime
│   └── EdgeMultiMesh (MultiMeshInstance3D) — cylinders, created at runtime
└── Label3D — algorithm display name
```

### Dual MultiMesh Design

**Nodes:** SphereMesh instances. Per-instance color + emission. Smooth position LERP for force-directed layouts.

**Edges:** CylinderMesh instances (unit height=1, oriented per-frame). Each edge cylinder is:
1. Positioned at midpoint between two nodes
2. Oriented along the node-to-node direction (basis Y = direction)
3. Scaled along Y to match edge length

This allows edges to follow moving nodes in real-time (force-directed) with no scene tree churn.

### Node Dimensions
- Radius: 0.06m (visible in VR at arm's reach)
- Edge radius: 0.012m (thin but visible)
- Default bounds: 2.0 × 1.5 × 2.0m

## 8 Cartridges

### Graph Traversal (3)

| Cartridge | Algorithm | Visual Signature |
|-----------|-----------|-----------------|
| `bfs` | Breadth-first search | Yellow frontier wavefront, green visited |
| `dfs` | Depth-first search | Orange stack plunges deep, backtracks |
| `dijkstra` | Dijkstra shortest path | Cyan frontier expands by distance |

### Minimum Spanning Tree (2)

| Cartridge | Algorithm | Visual Signature |
|-----------|-----------|-----------------|
| `kruskal` | Kruskal's MST (Union-Find) | Sorted edges: green accepted, red rejected |
| `prim` | Prim's MST (grow from source) | Cyan frontier, green tree grows |

### Layout & Structure (3)

| Cartridge | Algorithm | Visual Signature |
|-----------|-----------|-----------------|
| `force_directed` | Force-directed layout | Nodes repel, edges attract — self-organizing |
| `random_graph` | Erdős–Rényi random graph | Edges appear, nodes color by degree |
| `entropy_field` | Order→chaos point cloud | Blue grid → red chaos (no edges) |

## Map Placement

```
"grid3d_bfs"                                   # Named variant
"grid3d#algorithm:kruskal"                     # Config syntax
"grid3d#algorithm:force_directed#nodes:30"     # With node count
"grid3d#algorithm:dijkstra#interval:0.5"       # Slower stepping
```

## Cartridge Interface

```gdscript
class_name Grid3DCartridge extends RefCounted

# Node appearance
func get_node_color(state: int) -> Color
func get_node_emission(state: int) -> float
func get_node_radius(state: int) -> float

# Edge appearance
func get_edge_color(state: int) -> Color
func get_edge_emission(state: int) -> float

# Lifecycle
func initialize(node_count: int, bounds: Vector3) -> Dictionary
func step(positions, states, edges, edge_states, edge_weights) -> Dictionary
func on_node_touch(index, positions, states) -> PackedInt32Array
func has_dynamic_positions() -> bool  # true for force-directed
```

### Initialize Result

```gdscript
{
    "positions": PackedVector3Array,
    "states": PackedInt32Array,
    "edges": [[from, to], ...],
    "edge_states": PackedInt32Array,
    "edge_weights": PackedFloat32Array
}
```

### Step Result

```gdscript
{
    "positions": PackedVector3Array or null,  # null = unchanged
    "states": PackedInt32Array,
    "edges": Array or null,                   # null = unchanged; non-null rebuilds edge MM
    "edge_states": PackedInt32Array,
    "highlights": {node_idx: Color},
    "edge_highlights": {edge_idx: Color},
    "done": bool,
    "description": String
}
```

## Registry

`commons/artifacts/registry/grid3d.json` — 9 entries (1 generic + 8 named variants)
