# Substrate System — Reusable Algorithm Artifacts

> Build the substrate once. Swap the algorithm. Reuse across sequences.

## Principle

A **substrate** is a dumb physical object — cells, bars, dots, mesh. It doesn't know what algorithm it's running. An **algorithm cartridge** plugs in and tells it what to compute. Same substrate, different cartridge, different sequence.

**Must look good in VR.** Emissive materials with bloom. Smooth transitions (no snapping). Physical thickness and material quality. Subtle idle animation. Sound on every state change. This is not a debugging tool — it's the thing the player stands next to and touches.

## The 7 Substrates

```
Bar → Profile → BarArray → Grid2D → Grid3D
 0D      1D        1D        2D        3D
                                  + Edges (connection layer)
                    + WalkSurface (continuous 2D)
                    + MeshArtifact (deformable 3D)
```

### 1. Bar (single value)
One vertical line. Height = value. The atom.

- **Shows:** threshold, counter, health bar, single variable
- **VR form:** Glowing rod. Pulses when value changes. Color shifts with magnitude.
- **Used within:** other substrates as component

### 2. Profile (1D continuous)
A continuous curve on a 2D canvas.

- **Shows:** waveforms, convergence curves, distribution shapes, filter response
- **Exists as:** `oscilloscope_display.gd`
- **VR form:** Luminous line on a dark surface — like an oscilloscope tube. Line has glow falloff. Points of interest pulse.
- **Serves:** wavefunctions (9 maps), proceduralaudio (8 maps), statistics (5 maps), noise, searchpathfinding (gradient descent), physicssimulation (oscillation decay)
- **~25 maps**

### 3. BarArray (1D discrete)
Array of vertical bars on a 2D canvas. The workhorse for 1D algorithms.

- **Shows:** sorting, FFT spectrum, histograms, attention weights, feature importances, harmonic amplitudes
- **Exists as:** `distribution_sampler.gd`
- **VR form:** Physical bars with volume and bevel. Active bars glow. Swapping bars animate smoothly. Comparison pairs highlight. Can be wall-mounted (flat) or table-top (physical bars you can flick).
- **Serves:** datastructures (heap, segment tree, fenwick), proceduralaudio (ALL 8 maps), wavefunctions (fourier), machinelearning (attention, clustering), statistics (6 maps), randomness, computationalgeometry
- **~35 maps**

**Cartridge interface:**
```gdscript
func initialize(values: Array[float]) -> void
func step() -> Dictionary  # {swaps: [[i,j]], highlights: [i], comparisons: [[i,j]]}
func on_bar_touch(index: int) -> void
func get_bar_color(index: int, value: float) -> Color
```

### 4. Grid2D (2D discrete cells)
Flat cell grid. Touch to toggle. The backbone — serves the most sequences.

- **Shows:** CA, pathfinding, WFC, mazes, patterns, hash tables, CNNs, pheromone maps, morphological ops
- **Exists as:** `pattern_tile_puzzle.gd`, `grid_agent/`, `game_of_life_petri.gd`, `ca_rule_explorer.gd`
- **VR form:** TABLE (flat, petri dish — look down), WALL (vertical, Wolfram scroll), RING (cylindrical, no edges). Cells glow and fade between states. Touch interaction. Step/play/reset controls.
- **Serves:** cellularautomata (ALL 12), recursiveemergence (5), searchpathfinding (4), patterngeneration (7+), proceduralgeneration (3+), datastructures (4), swarmintelligence (3), machinelearning (3), computationalgeometry (5), noise (3), transformation (6), arrays
- **~80+ maps**

**Cartridge interface:**
```gdscript
func initialize(grid: Array, width: int, height: int) -> void
func step(grid: Array, width: int, height: int) -> Array  # returns new grid
func on_cell_touch(grid: Array, x: int, y: int) -> Array  # returns modified grid
func get_state_color(state: int) -> Color
func get_state_count() -> int  # how many distinct states
```

**Already proven:** pattern_tile_puzzle does exactly this — same grid, swap the symmetry rule (10 repeat modes + 17 wallpaper groups). Just generalize to arbitrary algorithm cartridges.

### 5. Grid3D (volumetric MultiMesh)
Thousands of dots/cubes in 3D space. Walk through it.

- **Shows:** entropy/randomness, density fields, marching cubes, octree, 3D CA, particle positions, cluster clouds
- **Exists as:** `entropy_axiom_multimesh.gd`
- **VR form:** Glowing points floating in space. Per-instance color and emission. Points pulse/breathe. Walking through the field feels like walking through data.
- **Connection layer:** Second MultiMesh of thin cylinders for edges. Enables graph algorithms.
- **Serves:** cellularautomata (2), randomness (3), noise (3), proceduralgeneration (5+), datastructures (2), physicssimulation (3), machinelearning (3), graphtheory (ALL 14 — with connections), swarmintelligence (3), computationalgeometry (3)
- **~30 maps** (+ 14 graphtheory with connection layer)

**Connection layer implementation:**
```gdscript
# EdgeMultiMesh — same pattern as cell MultiMesh
var edge_multimesh: MultiMesh  # thin cylinders
# Each edge: positioned at midpoint, rotated toward target, scaled to distance
func add_edge(from_idx: int, to_idx: int, color: Color) -> void
func remove_edge(from_idx: int, to_idx: int) -> void
func set_edge_color(from_idx: int, to_idx: int, color: Color) -> void
```

### 6. WalkSurface (continuous 2D terrain)
Room-scale mesh you stand on. Algorithm generates the height field.

- **Shows:** sine terrain, noise landscape, loss surface, pheromone terrain, potential energy surface, fractal terrain, SDF elevation
- **Exists as:** `walkgrids/TopologySpace.gd` (SineSpace, NoiseSpace, VoronoiSpace, etc.)
- **VR form:** ALREADY PROVEN — sine_space works because you feel the math with your body. Key: responsive to parameter changes (frequency slider → terrain deforms under your feet).
- **Serves:** wavefunctions (1), noise (4), randomness (2), searchpathfinding (2), machinelearning (2), proceduralgeneration (3), physicssimulation (2), fractals (1), swarmintelligence (2), computationalgeometry (2)
- **~20 maps**

**Already has cartridge interface:**
```gdscript
func generate_space(x: float, z: float) -> float  # override per algorithm
```

### 7. MeshArtifact (deformable 3D)
A 3D mesh that algorithms reshape, branch, connect, or deform.

- **Shows:** L-systems (branching), softbodies (deformation), joints (constraints), fractals (recursive geometry), force-directed graphs (continuous positioning)
- **VR form:** Organic, responsive. Branches grow visibly. Cloth drapes. Joints click. The mesh is alive.
- **Serves:** lsystems (12), softbodies (8), fractals (some — recursive 3D), graphtheory (force-directed — continuous, not grid)
- **~25 maps**

---

## What Already Exists → What Needs Building

### Already exists (migrate, don't rewrite)
| Component | Becomes | Status |
|-----------|---------|--------|
| `pattern_tile_puzzle.gd` | Grid2D (TABLE variant, with wallpaper cartridges) | ✅ Working |
| `grid_agent/grid_operations.gd` | Grid2D shared operation library | ✅ Working |
| `game_of_life_petri.gd` | Grid2D cartridge: Game of Life | → migrate to cartridge |
| `ca_rule_explorer.gd` | Grid2D cartridge: Wolfram 1D | → migrate to cartridge |
| `entropy_axiom_multimesh.gd` | Grid3D (rendering approach) | ✅ Working |
| `walkgrids/TopologySpace.gd` | WalkSurface (base class + cartridges) | ✅ Working |
| `oscilloscope_display.gd` | Profile (rendering approach) | ✅ Working |
| `distribution_sampler.gd` | BarArray (rendering approach) | ✅ Working |
| `array_sequencer.gd` | BarArray variant (time-based) | ✅ Working |

### Needs building
| Component | Priority | Why |
|-----------|----------|-----|
| **Grid2D unified artifact** | HIGH | 80+ maps, most infrastructure exists |
| **BarArray unified artifact** | HIGH | 35 maps, sorting visualization is iconic |
| **Grid3D connection layer** | HIGH | Unlocks all 14 graphtheory maps |
| **Profile unified artifact** | MEDIUM | 25 maps, oscilloscope exists |
| **Bar single value** | LOW | Component of others |
| **MeshArtifact** | LOW | Complex, fewer maps, diverse needs |

---

## Build Order

### Phase 1: Grid2D (highest impact)
1. Define `AlgorithmCartridge2D` base class (interface above)
2. Create `AlgorithmGrid2D` scene — MultiMesh cells, touch interaction, step/play/reset, speed slider
3. Migrate `game_of_life_petri` → Game of Life cartridge
4. Migrate `ca_rule_explorer` → Wolfram 1D cartridge
5. Write pathfinding cartridges: BFS, DFS, A*, flood fill
6. Write WFC cartridge
7. Register in artifact registry with `#mode:game_of_life` syntax
8. Test in CA_1 and SearchPathfinding_BFS maps

### Phase 2: BarArray
1. Define `AlgorithmCartridge1D` base class
2. Create `AlgorithmBars` scene — physical bars, smooth animation, highlight/compare/swap states
3. Write sorting cartridges: bubble, insertion, merge, quick, heap
4. Write FFT cartridge (Fourier coefficients as bars)
5. Write histogram cartridge (binning incoming values)
6. Register with `#mode:bubble_sort` syntax

### Phase 3: Grid3D connections
1. Add `EdgeMultiMesh` to entropy_axiom approach
2. Define `AlgorithmCartridge3D` with edge support
3. Write graph cartridges: BFS, Dijkstra, MST, force-directed
4. Test in GraphTheory_Minimum_Spanning_Tree

### Phase 4: Profile
1. Generalize oscilloscope_display into `AlgorithmProfile`
2. Write waveform cartridges: sine, fourier series, noise, convergence
3. Test in WaveFunctions_Intro

### Phase 5: MeshArtifact
1. Define deformable mesh interface
2. L-system cartridge, softbody cartridge
3. Test in LSystems maps

---

## VR Design Principles (non-negotiable)

1. **Emission + bloom** — every cell/bar/dot has emissive material. Active elements glow brighter. Bloom post-processing makes it sing.
2. **Smooth transitions** — LERP everything. Color fades (0.2s). Bar height slides (0.15s). Cell births/deaths fade in/out. No snapping.
3. **Physical thickness** — bars have depth. Cells have height. Nothing is paper-thin. In VR you need parallax.
4. **Sound per state change** — cell birth: soft chime. Cell death: quiet thud. Bar swap: click. Pathfinding step: subtle pulse. Sound is half the presence.
5. **Idle motion** — slight breathing/pulsing on active cells. Gentle bob on bars. The artifact feels alive even paused.
6. **Scale matters** — table-top (arm's reach, detail, tactile) vs wall (2m, readability) vs room (walkable, embodied). Each substrate has scale variants.
7. **Color with meaning** — not random colors. States map to a curated palette. Active = warm (amber/cyan). Frontier = cool (blue). Dead = dim. Found = bright.

---

## Cartridge Swap Examples

### Grid2D in one map, three cartridges:
```
# Same AlgorithmGrid2D artifact, placed three times with different cartridges
"AlgorithmGrid2D#mode:game_of_life:1:0"
"AlgorithmGrid2D#mode:a_star:3:0"
"AlgorithmGrid2D#mode:wfc:5:0"
```
Player walks between three identical grids. Each running a different algorithm. Touch one to seed it. Watch them evolve differently. SAME object, DIFFERENT behavior. That's the substrate lesson.

### BarArray in sorting sequence:
```
# Same bars, cycle through algorithms
"AlgorithmBars#mode:bubble_sort#size:32:2:0"
# VR button swaps cartridge: bubble → merge → quick → heap
# Same bars reorganize differently. Feel the O(n²) vs O(n log n).
```

### WalkSurface in optimization:
```
# Same terrain, different generation
"SineSpace:0:0"        # smooth, periodic — you know where the valleys are
"NoiseSpace:0:0"        # rough, unpredictable — local minima everywhere
"LossLandscape:0:0"     # ML loss surface — find the global minimum by walking
```
