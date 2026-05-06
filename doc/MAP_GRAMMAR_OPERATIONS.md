# Map Grammar — Operations Reference

> Auto-research vocabulary for generating maps. Each operation mutates a
> `MapState` (rows × cols × structure/utilities/interactables). Configs
> in `tools/map_grammar/research_configs.json` chain operations to
> produce full `map_data.json` files in `commons/maps/`.

The grammar has **21 operations** in **6 categories**, each producing a
form_type that the project's existing `commons/artifacts/grammar_operations.json`
tracks (so generated maps stay honest to the curriculum's gating).

## Categories

| Category | Ops | When to use |
|---|---|---|
| **shape**     | `room`, `frame`, `plinth_field`, `circle_room` | Build the footprint — rectangles, walls, courtyards |
| **walk**      | `drunkard_walk`, `lsystem_walk`, `corridor`    | Carve walkable paths via agent or rewriting |
| **partition** | `bsp`, `subdivide`, `voronoi_cells`            | Divide space into discrete regions |
| **automaton** | `ca_evolve`                                     | Smooth / re-shape via local rules |
| **field**     | `noise_field`                                   | Threshold a continuous height function |
| **motif**     | `mirror`, `tile_motif`, `rotate90`, `checker`, `border_plinths` | Apply symmetry / repetition to existing structure |
| **safety**    | `thicken`, `safe_borders`                       | Make walks safe (no falls off the map) |
| **height**    | `staircase`                                     | Vertical variation — climb gradients |
| **finish**    | `spawn_at`, `teleport_at`                       | Place spawn / teleporter cells |

## Reference

### `room`  *(shape)*
Rectangular floor of size h×w starting at (r, c). Optional `border` height places walls on the edges.
```json
{ "op": "room", "params": { "r": 2, "c": 2, "h": 8, "w": 12, "border": 4 } }
```

### `frame`  *(shape)*
Wall-of-height-h around the entire grid edge.
```json
{ "op": "frame", "params": { "h": 2 } }
```

### `plinth_field`  *(shape)*
Scatter plinth cells (h=2 or 3) over walkable cells with a regular spacing.
```json
{ "op": "plinth_field", "params": { "spacing": 3, "plinth_h": 2 } }
```

### `circle_room`  *(shape)*
Round walkable room of radius `radius` at (r, c). Optional `border` ring of walls.
```json
{ "op": "circle_room", "params": { "r": 8, "c": 8, "radius": 4, "border": 3 } }
```

### `drunkard_walk`  *(walk)*
Random walker carves floor cells until `fraction` of the grid is walkable.
```json
{ "op": "drunkard_walk", "params": { "fraction": 0.4 } }
```

### `lsystem_walk`  *(walk)*
Carve floor along an L-system turtle path. `F` = step + carve, `+ -` = turn, `[ ]` = push/pop.
```json
{ "op": "lsystem_walk", "params": {
    "axiom": "F+F+F+F",
    "rules": { "F": "F+F-F-FF+F+F-F" },
    "iterations": 2, "angle": 90,
    "start_r": 2, "start_c": 2
}}
```

### `corridor`  *(walk)*
Carve a 2-wide L-shaped corridor between two anchor cells.
```json
{ "op": "corridor", "params": {
    "from_r": 1, "from_c": 1, "to_r": 14, "to_c": 14, "width": 2
}}
```

### `bsp`  *(partition)*
Recursively split the canvas into rectangles, each leaf becoming a room of floor with optional `pad` border.
```json
{ "op": "bsp", "params": { "min_size": 3, "pad": 1 } }
```

### `subdivide`  *(partition)*
Fractal recursive subdivide; each leaf gets a height sampled from `heights`.
```json
{ "op": "subdivide", "params": { "depth": 4, "heights": [0, 1, 1, 1, 2, 3] } }
```

### `voronoi_cells`  *(partition)*
N seed points → each cell takes nearest seed's height. Cell boundaries become walls of `border` height.
```json
{ "op": "voronoi_cells", "params": { "n_seeds": 6, "border": 3 } }
```

### `ca_evolve`  *(automaton)*
Cellular-automaton smoothing — `iterations` of "wall if N+ wall neighbours". Tightens caves.
```json
{ "op": "ca_evolve", "params": { "iterations": 4, "birth": 5 } }
```

### `noise_field`  *(field)*
Smoothed value-noise threshold. `blur` passes a box filter; cells above `threshold` become floor.
```json
{ "op": "noise_field", "params": { "threshold": 0.55, "blur": 4 } }
```

### `mirror`  *(motif)*
Apply horizontal / vertical / both symmetry — cheap way to push generated maps toward the corpus's measured 0.85+ symmetry mean.
```json
{ "op": "mirror", "params": { "axis": "horizontal" } }
```

### `tile_motif`  *(motif)*
Stamp a small 2D pattern across the grid at a step. Pattern is a list-of-lists of integer heights.
```json
{ "op": "tile_motif", "params": {
    "motif": [[1, 1, 1], [1, 2, 1], [1, 1, 1]],
    "step": 4, "offset_r": 2, "offset_c": 2
}}
```

### `rotate90`  *(motif)*
Rotate the entire grid 90° clockwise (square grids only).
```json
{ "op": "rotate90", "params": {} }
```

### `checker`  *(motif)*
Checkerboard of two heights. `period` controls block size.
```json
{ "op": "checker", "params": { "h_a": 1, "h_b": 2, "period": 1 } }
```

### `border_plinths`  *(motif)*
Plinths along the grid perimeter at `period` step.
```json
{ "op": "border_plinths", "params": { "period": 3, "h": 3 } }
```

### `thicken`  *(safety)*
Dilate walkable cells by `radius` so single-cell paths become 2+ wide. **Always run after walks/lsystems** unless thinness is intentional.
```json
{ "op": "thicken", "params": { "radius": 1 } }
```

### `safe_borders`  *(safety)*
Push walkable cells away from the grid edge — prevents the player walking off into nothing.
```json
{ "op": "safe_borders", "params": { "edge_h": 2 } }
```

### `staircase`  *(height)*
Linear ramp of plinths from height `start` rising by `step` per cell along a cardinal direction.
```json
{ "op": "staircase", "params": {
    "r": 9, "c": 5, "direction": "east", "length": 4, "start": 1, "step": 1
}}
```

### `spawn_at` / `teleport_at`  *(finish)*
Place the spawn / teleporter at (r, c). If no coords given, picks the first / last walkable cell. The runner auto-appends these if missing.
```json
{ "op": "spawn_at", "params": { "r": 5, "c": 3 } }
{ "op": "teleport_at", "params": { "r": -1, "c": -1 } }
```

## Composing — typical chains

| Goal | Recipe |
|---|---|
| Linear corridor map | `room` → `corridor` |
| Symmetric branching | `lsystem_walk` → `thicken` → `mirror` |
| Open-air gallery | `circle_room` → `border_plinths` → `tile_motif(plinth)` |
| Cave system | `drunkard_walk` → `ca_evolve` → `safe_borders` |
| Fractal city | `subdivide` → `corridor` → `safe_borders` |
| Districts joined by corridors | `voronoi_cells` → `thicken` |
| Atrium with ramps | `room` → `frame` → `circle_room(border)` → `staircase` |
| Pure geometry pattern | `checker` → `mirror(both)` |

## The auto-research loop

```
configs (research_configs.json)
        ↓
   tools/map_grammar_research.py        [render → write maps + manifest]
        ↓
   commons/maps/<id>/map_data.json      [real maps on disk]
        ↓
   tools/map_grammar_eval.py            [score → evals.json + hints]
        ↓
   tools/map_grammar/next_gen_queue.json   [proposed next-gen configs]
        ↓
   tools/map_grammar_research.py --library next_gen_queue.json
        ↓
   re-evaluate                          [the loop closes]
```

Stars 1–5 are mapped from objective metrics: walkable count, connectivity (BFS-from-spawn coverage), thin-cell ratio, symmetry, height variety. Verdicts: `broken < weak < working < strong < exemplary`.

The proposer reads `next_gen_hints` strings produced by the evaluator and emits concrete config variants — append `thicken`, add `corridor`, apply `mirror`, bump `fraction`, expand grid. Each broken/weak entry produces one or more gen+1 candidates; running them through the same pipeline either fixes the verdict or surfaces a deeper problem for human attention.

## Form-type alignment to the formal grammar

The project's `commons/artifacts/grammar_operations.json` declares 19 form_types unlocked by sequence order. Map operations map to form_types like:

| Op | form_type | unlocked at |
|---|---|---|
| `room`, `frame`, `plinth_field`, `circle_room` | `solid` | primitives (1) |
| `tile_motif`, `checker`, `mirror` | `pattern` / `lattice` | arrays (5) |
| `noise_field` | `field` / `terrain` | noise (8) |
| `ca_evolve` | `automaton` | cellularautomata (9) |
| `subdivide` | `fractal` | fractals (10) |
| `lsystem_walk` | `growth` | lsystems (11) |
| `voronoi_cells`, `bsp`, `wfc_lite` (TBD) | `generated` | proceduralgeneration (12) |

So a map "for sequence 5" can use `room`, `frame`, `tile_motif`, `mirror`, etc. — but not `noise_field` (waits for sequence 8) or `ca_evolve` (waits for 9). This is the same gating `BiomeRingComponent` applies to foliage; applying it to map composition keeps generated content honest.

## Output artefacts

Every run produces:

- **Maps**: `commons/maps/<id>/map_data.json` — full schema, identical to hand-authored
- **Per-map iso thumb**: `commons/maps/<id>/map_iso.png`
- **Gallery thumb**: `ada_encyclopedia/public/map-grammar-gallery/<id>.png`
- **Gallery manifest**: `ada_encyclopedia/public/map-grammar-gallery/manifest.json`
- **Evals**: `ada_encyclopedia/public/map-grammar-gallery/evals.json`
- **Next-gen queue**: `tools/map_grammar/next_gen_queue.json`

Browse at:
- `/galleries/map-grammar` — gallery with stars + verdicts
- `/maps-all` — every map in `commons/maps/` as iso voxel thumbnails
- `/map-3d/<name>` — Three.js voxel viewer with grammar-trace panel
