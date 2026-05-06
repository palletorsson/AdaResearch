# Grid Artifact — Reusable Algorithm Substrate

## Concept

A single physical VR artifact — a grid of cells — that accepts different **algorithm cartridges**. Same object, different behavior. Drop it into any map, configure which algorithm runs on it, and the player interacts with the same familiar substrate while seeing different algorithms transform it.

**The grid is the Barbie. The algorithm is the outfit.**

---

## Why This Matters

Currently the project has:
- `game_of_life_petri` — a grid that only does Game of Life
- `ca_rule_explorer` — a grid that only does Wolfram rules
- `grid_agent` system — agents that operate on grids with copy/translate/rotate/scale/etc.
- `GridStructureComponent` — the map builder's grid (structural, not algorithmic)

These are all grids doing different things with different code. The Grid Artifact unifies them: **one physical object, many algorithms**.

---

## Physical Form

### Base Object: `AlgorithmGrid`

A flat or shallow 3D grid of cells, physically present in the VR space:

```
┌─────────────────────┐
│ ■ □ ■ □ □ ■ □ ■ □ □ │  ← cells (cubes, flat tiles, or LED-style dots)
│ □ ■ □ □ ■ □ ■ □ ■ □ │
│ ■ □ □ ■ □ ■ □ □ □ ■ │
│ □ □ ■ □ ■ □ □ ■ □ □ │
│ ■ ■ □ □ □ ■ ■ □ ■ □ │
│ □ □ ■ ■ □ □ ■ □ □ ■ │
│ ■ □ □ □ ■ □ □ ■ □ □ │
│ □ ■ □ ■ □ □ ■ □ ■ ■ │
└─────────────────────┘
  [STEP] [PLAY/PAUSE] [RESET] [ALGORITHM ▼]
```

### VR Interaction
- **Touch a cell** → toggle alive/dead (seed the grid)
- **Grab edge** → resize grid
- **STEP button** → advance one generation/step
- **PLAY/PAUSE** → auto-run at configurable speed
- **RESET** → clear or re-seed
- **ALGORITHM selector** → switch which algorithm runs on the grid
- **Speed slider** → generations per second
- **Grab and throw cubes** → seed cells by throwing objects at the grid

### Physical Variants
| Variant | Form Factor | Best For |
|---|---|---|
| `table` | Flat horizontal, sits on a table (height=2) | Petri dish style, looking down |
| `wall` | Vertical, mounted on wall | Display board, Wolfram-style scrolling |
| `volume` | 3D cube of cells | 3D CA, voxel algorithms |
| `ring` | Cylindrical grid | Wrap-around boundary conditions |

---

## Algorithm Cartridges

Each cartridge is a GDScript implementing a simple interface:

```gdscript
class_name GridAlgorithm extends RefCounted

## Human-readable name
func get_name() -> String:
    return "Unknown"

## Short description
func get_description() -> String:
    return ""

## Category for UI grouping
func get_category() -> String:
    return "general"

## What the cell colors mean
func get_legend() -> Dictionary:
    # { color: description }
    return { Color.WHITE: "alive", Color.BLACK: "dead" }

## Initialize the grid state (called on reset)
func initialize(grid: Array, width: int, height: int) -> void:
    pass  # Optional: seed with a starting pattern

## Advance one step. Modify grid in place.
## grid is Array[Array[int]] where values represent cell states
func step(grid: Array, width: int, height: int) -> void:
    pass

## Handle player touching a cell (optional)
func on_cell_touch(grid: Array, x: int, y: int, width: int, height: int) -> void:
    # Default: toggle cell
    grid[y][x] = 0 if grid[y][x] > 0 else 1

## How many distinct states can a cell have?
func get_state_count() -> int:
    return 2  # alive/dead

## Color for each state
func get_state_color(state: int) -> Color:
    return Color.WHITE if state > 0 else Color.BLACK
```

### Cartridge Registry

```
commons/artifacts/algorithm_grid/cartridges/
├── cellular_automata/
│   ├── game_of_life.gd          # B3/S23
│   ├── wolfram_1d.gd            # Rules 0-255
│   ├── brians_brain.gd          # 3-state: alive → dying → dead
│   ├── langtons_ant.gd          # Turing-complete ant
│   ├── wireworld.gd             # Circuit simulation
│   └── seeds.gd                 # B2/S (explosive growth)
│
├── pathfinding/
│   ├── bfs.gd                   # Breadth-first search (flood fill vis)
│   ├── dfs.gd                   # Depth-first search
│   ├── dijkstra.gd              # Weighted shortest path
│   ├── a_star.gd                # A* with heuristic
│   └── maze_generator.gd        # Recursive backtracker / Prim's
│
├── sorting/
│   ├── bubble_sort.gd           # Visualized on 1D row
│   ├── merge_sort.gd            # Split/merge visualization
│   ├── quicksort.gd             # Pivot partitioning
│   └── insertion_sort.gd        # Element-by-element
│
├── spatial/
│   ├── flood_fill.gd            # Paint bucket algorithm
│   ├── voronoi.gd               # Growing seeds → territory
│   ├── wave_function_collapse.gd # Procedural generation
│   ├── convolution.gd           # Image filter kernels (blur, edge detect)
│   └── erosion_dilation.gd      # Morphological operations
│
├── simulation/
│   ├── heat_diffusion.gd        # Temperature spreading
│   ├── reaction_diffusion.gd    # Turing patterns
│   └── forest_fire.gd           # Fire spread simulation
│
└── mathematical/
    ├── sierpinski.gd            # Fractal from CA rules
    ├── pascals_triangle.gd      # Number theory visualization
    └── prime_sieve.gd           # Sieve of Eratosthenes
```

---

## Integration with Existing Systems

### What Already Exists → What It Becomes

| Current | Becomes |
|---|---|
| `game_of_life_petri.gd` | Cartridge: `game_of_life.gd` |
| `ca_rule_explorer.gd` | Cartridge: `wolfram_1d.gd` |
| `grid_agent` copy/translate/rotate | Grid operations available to any cartridge |
| `GridInterface` | Shared utility — cartridges can use it |
| `turing_pattern_generator` | Cartridge: `reaction_diffusion.gd` |

### Map Placement (in map_data.json)

```json
"AlgorithmGrid#mode:game_of_life"
"AlgorithmGrid#mode:pathfinding_bfs#size:16"
"AlgorithmGrid:wall#mode:wolfram_1d#rule:110"
"AlgorithmGrid#mode:wave_function_collapse#size:8"
```

Parameters via `#config`:
- `mode` — which cartridge to load
- `size` — grid resolution (default 16)
- `variant` — table/wall/volume/ring (default table)
- `speed` — generations per second (default 5)
- `auto_run` — start playing automatically (default false)
- `seed` — initial pattern name or "random"

---

## Sequences That Can Reuse This

| Sequence | Cartridge | What Player Sees |
|---|---|---|
| Cellular Automata intro | `game_of_life` | Draw patterns, watch them evolve |
| Wolfram rules | `wolfram_1d` | Slide between rules 0-255, see complexity emerge |
| Pathfinding | `bfs`, `dfs`, `a_star` | Place start/end/walls, watch algorithm search |
| Sorting visualization | `bubble_sort`, `quicksort` | See elements swap in real-time |
| Procedural generation | `wave_function_collapse` | Watch a world build itself from constraints |
| Image processing | `convolution` | Apply blur/sharpen/edge kernels to a pixel grid |
| Diffusion | `heat_diffusion` | Touch to add heat, watch it spread |
| Turing patterns | `reaction_diffusion` | Spots and stripes emerge from math |
| Fractals | `sierpinski` | Watch CA rule 90 build Sierpiński triangle |
| Fire simulation | `forest_fire` | Grow trees, start fires, study spread |

**That's 10+ sequences sharing ONE artifact.** Build the grid once, write cartridges as needed.

---

## File Structure

```
commons/artifacts/algorithm_grid/
├── algorithm_grid.tscn               # Main scene (the physical grid)
├── algorithm_grid.gd                 # Core controller
├── algorithm_grid_cell.gd            # Individual cell behavior
├── grid_algorithm.gd                 # Base class for cartridges
├── grid_cartridge_loader.gd          # Discovers and loads cartridges
├── ui/
│   ├── grid_controls.tscn           # VR control panel (step/play/reset/select)
│   └── grid_controls.gd
└── cartridges/
    ├── cellular_automata/
    ├── pathfinding/
    ├── sorting/
    ├── spatial/
    ├── simulation/
    └── mathematical/
```

### Registry Entry

```json
{
    "algorithm_grid": {
        "name": "Algorithm Grid",
        "lookup_name": "AlgorithmGrid",
        "description": "Universal grid substrate — accepts algorithm cartridges for CA, pathfinding, sorting, spatial algorithms, and simulations",
        "scene": "res://commons/artifacts/algorithm_grid/algorithm_grid.tscn",
        "category": "substrate",
        "configurable": true,
        "parameters": {
            "mode": { "type": "string", "default": "game_of_life", "description": "Algorithm cartridge to load" },
            "size": { "type": "int", "default": 16, "min": 4, "max": 64, "description": "Grid resolution" },
            "variant": { "type": "string", "default": "table", "options": ["table", "wall", "volume", "ring"] },
            "speed": { "type": "float", "default": 5.0, "min": 0.5, "max": 30.0 },
            "auto_run": { "type": "bool", "default": false },
            "seed": { "type": "string", "default": "", "description": "Initial pattern name or 'random'" }
        }
    }
}
```

---

## Other Reusable Substrates (Future)

The Grid Artifact is the first. The same pattern applies to:

| Substrate | Physical Form | Algorithms |
|---|---|---|
| **GraphArtifact** | Nodes (spheres) + edges (lines/springs) | BFS, DFS, Dijkstra, MST, network flow, clustering |
| **SequenceRack** | Row of vertical bars (bar chart) | All sorting, binary search, merge, stack/queue ops |
| **ParticleField** | Bounded volume of floating points | Voronoi, convex hull, KD-tree, K-means, boids |
| **StateMachine** | Glowing nodes with transition arrows | Regex, finite automata, Markov chains, game AI |
| **SignalWire** | Oscilloscope-style waveform display | FFT, filtering, convolution, sampling (exists partially) |

Each follows the same architecture: physical object + cartridge interface + registry.

---

## Implementation Priority

1. **AlgorithmGrid base** — the physical object with cell rendering, VR controls, cartridge loading
2. **Game of Life cartridge** — migrate from `game_of_life_petri.gd` (proves the interface works)
3. **Wolfram 1D cartridge** — migrate from `ca_rule_explorer.gd`
4. **Pathfinding BFS/A* cartridges** — new, high educational value
5. **Wave Function Collapse cartridge** — visually stunning, great for engagement
6. Then expand: sorting, diffusion, Turing patterns, etc.

---

## Critical Perspective (QFEP)

The grid is not neutral. Every grid artifact encodes assumptions:
- **Square cells** → excludes hexagonal, triangular, irregular tessellations
- **Discrete states** → normalizes digital over analog, binary over spectrum  
- **Synchronous update** → all cells step together (what if they didn't?)
- **Fixed topology** → the grid doesn't grow, fold, or tear
- **Homogeneous rules** → same rule everywhere (what about local variation?)

Each cartridge should include a `get_assumptions() -> Array[String]` method listing what the algorithm takes for granted. The critical lens asks: what would this algorithm do on a grid that could change shape? What if cells had memory? What if boundaries were porous?

The grid makes computation *visible*. But visibility is not understanding — it can create the illusion of transparency while hiding the choices that built the grid itself.
