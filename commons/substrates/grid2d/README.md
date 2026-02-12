# Grid2D Substrate

> The backbone. 80+ maps. One object.

Universal 2D cell grid for algorithm visualization. MultiMesh petri dish with per-cell emission, smooth transitions, and swappable algorithm cartridges.

## Architecture

```
grid2d_substrate.gd    — Manager: cartridge lifecycle, play/pause/step, touch, config
grid2d_renderer.gd     — MultiMesh rendering with smooth color/emission interpolation
grid2d_cartridge.gd    — Base class (RefCounted): initialize(), step(), get_state_color()
grid2d_cell.gdshader   — Per-instance emission, idle pulse, rim light via INSTANCE_CUSTOM
grid2d_substrate.tscn  — Petri dish scene: dark glass base, translucent rim, touch area
```

### Scene Tree

```
Grid2DSubstrate (Node3D) [grid2d_substrate.gd]
├── Renderer (Node3D) [grid2d_renderer.gd]
│   └── CellMultiMesh (MultiMeshInstance3D) — created at runtime
├── BasePlate (MeshInstance3D) — dark glass, metallic 0.3, roughness 0.1
├── Rim (MeshInstance3D) — translucent edge, subtle emission
├── Label3D — algorithm display name
└── TouchArea (Area3D)
    └── CollisionShape3D (BoxShape3D)
```

### Rendering Pipeline

1. **Cartridge** computes `PackedInt32Array` grid (state per cell)
2. **Renderer** maps states → colors/emission via cartridge's `get_state_color()` / `get_state_emission()`
3. **Smooth interpolation** every frame: color LERPs, emission decays, birth flash fades
4. **Shader** reads `INSTANCE_CUSTOM.r` (emission energy) and `INSTANCE_CUSTOM.g` (age) for idle pulse and rim light
5. **MultiMesh** pushes per-instance color + custom_data — zero CPU cost per cell per frame

### MultiMesh Data Budget (per cell)

| Channel | Data | Range |
|---------|------|-------|
| `COLOR.rgb` | Cell color | From cartridge |
| `INSTANCE_CUSTOM.r` | Emission energy | 0.0 (dead) → 1.5 (birth flash) |
| `INSTANCE_CUSTOM.g` | Cell age | 0.0 (newborn) → ∞ |
| `INSTANCE_CUSTOM.b` | Spare | — |
| `INSTANCE_CUSTOM.a` | Spare | — |

### Visual Constants

| Constant | Value | What |
|----------|-------|------|
| `BIRTH_FLASH_ENERGY` | 1.5 | Emission spike on cell birth |
| `ALIVE_ENERGY` | 0.8 | Steady-state emission for alive cells |
| `COLOR_LERP_SPEED` | 8.0 | Color transition speed (per second) |
| `EMISSION_LERP_SPEED` | 10.0 | Emission rise speed |
| `DEATH_FADE_SPEED` | 4.0 | Emission decay speed on death |
| `AGE_SPEED` | 0.5 | How fast age accumulates |
| `idle_pulse_strength` | 0.04 | Shader breathing amplitude |
| `idle_pulse_speed` | 2.0 | Shader breathing frequency |

## Cartridges

| File | Algorithm | States | Colors | Interval |
|------|-----------|--------|--------|----------|
| `cartridge_game_of_life.gd` | Conway's B3/S23 | 3 (dead/alive/dying) | Amber alive, blue ghost | default |
| `cartridge_seeds.gd` | B2/S — explosive | 3 (dead/alive/trail) | Electric cyan | default |
| `cartridge_brians_brain.gd` | 3-state oscillators | 3 (off/on/dying) | Hot pink | default |
| `cartridge_rule_1d.gd` | Wolfram 1D (30/110/90) | 2 | Warm gold | default |
| `cartridge_bfs.gd` | BFS flood fill | 5 (empty/wall/frontier/visited/source) | Blue wave, orange source | 0.06s |
| `cartridge_dfs_maze.gd` | DFS recursive backtracker | 4 (wall/corridor/current/backtrack) | Green carver, amber retreat | 0.03s |
| `cartridge_wireworld.gd` | Circuit simulation | 4 (empty/wire/head/tail) | Copper, electric blue, orange | default |
| `cartridge_langtons_ant.gd` | Emergent highway | 4 (white/black/ant×2) | Purple trail, red ant | 0.01s (8 steps/frame) |

## Artifact Registry

Registered in `commons/artifacts/registry/grid2d.json` — 12 entries:
- `grid2d` — generic (defaults to Game of Life)
- `grid2d_life`, `grid2d_seeds`, `grid2d_brians_brain`
- `grid2d_rule30`, `grid2d_rule110`, `grid2d_rule90`
- `grid2d_bfs`, `grid2d_dfs_maze`
- `grid2d_wireworld`, `grid2d_langtons_ant`

Auto-loaded by `GridInteractablesComponent` from the registry directory.

## Map Placement

### Named variants (algorithm auto-detected from lookup_name):
```
"grid2d_life"                          — Game of Life
"grid2d_rule30:90"                     — Rule 30, rotated 90°
"grid2d_seeds:0:1.5"                   — Seeds, elevated 1.5m
"grid2d_wireworld:0:0:0.5"            — Wireworld, half scale
```

### Generic with #algorithm config:
```
"grid2d#algorithm:wireworld"
"grid2d#algorithm:bfs#interval:0.04"
"grid2d:45:1.5:0.5#algorithm:seeds"    — Rotated + elevated + scaled + Seeds
"grid2d#algorithm:life#width:64#height:64#auto_play:true"
```

### Three grids side by side — same substrate, different algorithms:
```
"grid2d_life"           at (2,0)
"grid2d_bfs"            at (6,0)
"grid2d_dfs_maze"       at (10,0)
```

## Writing a New Cartridge

```gdscript
class_name CartridgeMyAlgo
extends Grid2DCartridge

func get_name() -> String:
    return "My Algorithm"

func get_state_count() -> int:
    return 3  # states including dead=0

func get_state_color(state: int) -> Color:
    match state:
        0: return Color(0.03, 0.03, 0.04)  # dead — near black
        1: return Color(0.9, 0.5, 0.2)     # alive — warm
        2: return Color(0.1, 0.2, 0.4)     # trail — cool
    return Color.BLACK

func get_state_emission(state: int) -> float:
    match state:
        0: return 0.0
        1: return 0.9
        2: return 0.2
    return 0.0

func initialize(grid: PackedInt32Array, width: int, height: int) -> void:
    # Set initial cell states (grid is pre-filled with 0s)
    pass

func step(grid: PackedInt32Array, width: int, height: int) -> PackedInt32Array:
    # Compute next generation, return new or modified grid
    var new_grid = PackedInt32Array()
    new_grid.resize(width * height)
    # ... your algorithm ...
    return new_grid

func on_cell_touch(grid: PackedInt32Array, x: int, y: int, width: int, height: int) -> PackedInt32Array:
    # Player touches cell — default toggles 0/1
    var idx = y * width + x
    grid[idx] = 0 if grid[idx] != 0 else 1
    return grid
```

Then:
1. Add to the `Algorithm` enum in `grid2d_substrate.gd`
2. Add preload + match case in `_create_cartridge()`
3. Add to `_resolve_algorithm_from_lookup_name()` map
4. Add to `apply_grid_config()` map
5. Add registry entry in `grid2d.json`

## Visual Design

**Petri dish aesthetic:**
- Dark glass base plate — `albedo: (0.04, 0.04, 0.05)`, metallic 0.3, roughness 0.1
- Translucent rim — subtle emission (0.15 energy), slightly larger than base
- BoxMesh cells — 0.038m side, 0.008m height, 0.002m gap
- Per-cell emission driven by shader custom_data.r
- Birth flash: 1.5 energy → decays to 0.8 steady state
- Death fade: slow dim via DEATH_FADE_SPEED
- Idle breathing: `sin(TIME * 2.0 + phase_offset) * 0.04` in shader
- Rim light on cell edges: `pow(1.0 - dot(N, V), 3.0) * 0.25`
- Toroidal wrap on all CA (edges connect)
- No shadow casting (performance)

**Color philosophy:**
- Each cartridge has a curated palette — not random RGB
- Dead cells: near-black with slight color tint (not pure black)
- Active cells: warm for "alive" (amber, cyan, pink), cool for "trail"
- State transitions always go through intermediate colors via LERP
