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

### 6. WalkSurface (continuous 2D terrain) ✅
Room-scale mesh you stand on. Algorithm generates the height field.

- **Shows:** sine terrain, noise landscape, loss surface, pheromone terrain, potential energy surface, fractal terrain, SDF elevation
- **Location:** `commons/context/walkgrids/`
- **Base class:** `TopologySpace.gd` — procedural mesh from height array, with StaticBody3D collision
- **Manager:** `TopologyManager.gd` — orchestrates multiple spaces, teleport between them
- **VR form:** ALREADY PROVEN — sine_space works because you feel the math with your body. Key: responsive to parameter changes (frequency slider → terrain deforms under your feet).
- **Serves:** wavefunctions (1), noise (4), randomness (2), searchpathfinding (2), machinelearning (2), proceduralgeneration (3), physicssimulation (2), fractals (1), swarmintelligence (2), computationalgeometry (2)
- **~20 maps**

**5 existing spaces (cartridges):**

| Space | Script | What you walk on |
|-------|--------|-----------------|
| SineSpace | `SineSpace.gd` | Perfect sine×cos waves — metallic, smooth, surveillance aesthetic |
| NoiseSpace | `NoiseSpace.gd` | Fractal noise terrain — organic, rough, resistance aesthetic |
| VoronoiSpace | `VoronoiSpace.gd` | Cellular territories from proximity — biological boundaries |
| RandomSpace | `RandomSpace.gd` | Pure chaos heightfield — aggressive, unstable, anarchy |
| FractalSpace | `FractalSpace.gd` | Fractal terrain generation |
| KnowledgeTerrainSpace | `KnowledgeTerrainSpace.gd` | Curriculum taxonomy as walkable landscape — the meta-layer |

**Registered in:** `grid_artifacts.json` as `sine_space`, `noise_space`, `voronoi_space`, `random_space`, `fractal_space`, `knowledge_terrain_space`

**Cartridge interface:**
```gdscript
extends TopologySpace
func generate_space():
    var heights = []
    for z in range(resolution + 1):
        for x in range(resolution + 1):
            heights.append(your_algorithm(x, z) * height_scale)
    var mesh = create_mesh_from_heights(heights)
    mesh_instance.mesh = mesh
    create_collision_from_mesh(mesh)
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
| `game_of_life_petri.gd` | Grid2D cartridge: Game of Life | ✅ `cartridge_game_of_life.gd` |
| `ca_rule_explorer.gd` | Grid2D cartridge: Wolfram 1D | ✅ `cartridge_rule_1d.gd` |
| `entropy_axiom_multimesh.gd` | Grid3D (rendering approach) | ✅ Working |
| `commons/context/walkgrids/` | WalkSurface (6 spaces: Sine, Noise, Voronoi, Random, Fractal, Knowledge) | ✅ Working |
| `oscilloscope_display.gd` | Profile (rendering approach) | ✅ Working |
| `distribution_sampler.gd` | BarArray (rendering approach) | ✅ Working |
| `array_sequencer.gd` | BarArray variant (time-based) | ✅ Working |

### Built substrates
| Substrate | Location | Cartridges | Registry |
|-----------|----------|------------|----------|
| **Living Paper** (2D texture) | `commons/substrates/living_paper/` | 35 algorithms (PaperAlgorithm) | `living_paper.json` (34 entries) |
| **Grid2D** (MultiMesh petri dish) | `commons/substrates/grid2d/` | 8 cartridges (Grid2DCartridge) | `grid2d.json` (12 entries) |
| **WalkSurface** (walkable terrain) | `commons/context/walkgrids/` | 6 spaces (TopologySpace) | `grid_artifacts.json` |

### Needs building
| Component | Priority | Why |
|-----------|----------|-----|
| **BarArray unified artifact** | HIGH | 35 maps, sorting visualization is iconic |
| **Grid3D connection layer** | HIGH | Unlocks all 14 graphtheory maps |
| **Profile unified artifact** | MEDIUM | 25 maps, oscilloscope exists |
| **Bar single value** | LOW | Component of others |
| **MeshArtifact** | LOW | Complex, fewer maps, diverse needs |

---

## Build Order

### ✅ Phase 0: Living Paper (completed 2026-02-12)
Lightweight 2D texture substrate — grabbable paper with Image-based cartridges.
- Location: `commons/substrates/living_paper/`
- 35 PaperAlgorithm cartridges across all sequences
- Registered in `commons/artifacts/registry/living_paper.json` (34 entries)
- Map syntax: `"living_paper_mandelbrot"`, `"living_paper#algorithm:rule30"`

### ✅ Phase 1: Grid2D (completed 2026-02-12)
Full MultiMesh petri dish — the backbone serving 80+ maps.
- Location: `commons/substrates/grid2d/`
- `Grid2DCartridge` base class (RefCounted, PackedInt32Array grid)
- `Grid2DRenderer` — MultiMesh with per-cell emission, smooth LERP, birth flash
- `grid2d_cell.gdshader` — idle pulse, rim light, emission from INSTANCE_CUSTOM
- 8 cartridges: Game of Life, Seeds, Brian's Brain, Rule 1D (30/110/90), BFS, DFS Maze, Wireworld, Langton's Ant
- Registered in `commons/artifacts/registry/grid2d.json` (12 entries)
- Map syntax: `"grid2d_life"`, `"grid2d#algorithm:wireworld#interval:0.04"`
- TODO: A*, WFC, flood fill with multiple sources, touch interaction in VR

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
# Same grid2d artifact, placed three times with different cartridges
"grid2d_life"           at (2,0)    # Conway's amber glow
"grid2d_bfs"            at (6,0)    # Blue wavefront expanding
"grid2d_wireworld"      at (10,0)   # Copper circuits firing
```
Player walks between three identical petri dishes. Each running a different algorithm. Touch one to seed it. Watch them evolve differently. SAME object, DIFFERENT behavior. That's the substrate lesson.

### Living Paper comparison wall:
```
# Same living paper, six random walk variants side by side
"living_paper_random_walk"       at (0,0)
"living_paper_brownian"          at (2,0)
"living_paper_levy"              at (4,0)
"living_paper_self_avoiding"     at (6,0)
```
Pick up any paper. It computes while you hold it. Put it down — frozen mid-walk. Compare patterns.

### WalkSurface in optimization:
```
# Same terrain, different generation
"SineSpace:0:0"        # smooth, periodic — you know where the valleys are
"NoiseSpace:0:0"        # rough, unpredictable — local minima everywhere
"LossLandscape:0:0"     # ML loss surface — find the global minimum by walking
```
