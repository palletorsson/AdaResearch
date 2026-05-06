# Substrate → Sequence Map

Which reusable substrates serve which algorithms across sequences.

## The 8 Substrates

| # | Substrate | What it is | Exists as | Status |
|---|-----------|-----------|-----------|--------|
| 0 | **Living Paper** (2D texture) | Grabbable paper with pixel-level drawing | `commons/substrates/living_paper/` | ✅ Built (35 cartridges) |
| 1 | **Bar** (single value) | One vertical line — height = value | *new* | Planned |
| 2 | **Profile** (1D line) | ImmediateMesh ribbon strips over grid | `commons/substrates/profile/` | ✅ Built (16 cartridges) |
| 3 | **BarArray** (1D discrete) | Array of vertical bars on 2D canvas | `distribution_sampler.gd` | Exists (needs unification) |
| 4 | **Grid2D** (2D discrete) | MultiMesh petri dish with cell emission | `commons/substrates/grid2d/` | ✅ Built (8 cartridges) |
| 5 | **Grid3D** (3D volume) | Dual MultiMesh: spheres (nodes) + cylinders (edges) | `commons/substrates/grid3d/` | ✅ Built (8 cartridges) |
| 6 | **WalkSurface** (2D continuous) | Room-scale walkable mesh terrain | `commons/context/walkgrids/` | ✅ Working (5 spaces) |
| 7 | **MeshArtifact** (deformable 3D) | Algorithms reshape branches/cloth/joints | *new* | Planned |

---

## Mapping: Sequences → Substrates

### PROFILE (1D continuous line)

Algorithms that show a value changing over time or space — one continuous curve.

| Sequence | Maps that could use Profile | What the line shows |
|----------|---------------------------|-------------------|
| **wavefunctions** | WaveFunctions_Intro, Sine_Space, Unit_Circle, Fourier_Form, Beat_Frequencies | Sine wave, composed wave, beat envelope |
| **searchpathfinding** | Gradient_Descent | Loss curve descending over iterations |
| **machinelearning** | Neural_Networks, Clustering, Dimensionality_Reduction | Loss convergence, decision boundary (1D slice) |
| **statistics** | Normal_Distribution, Central_Limit_Theorem, Regression | Distribution curve, regression line, CLT convergence |
| **noise** | Noise_Functions, Perlin_Simplex | 1D noise profile, octave layers |
| **randomness** | Random_Walk, Random_Gaussian | Walk displacement over time, bell curve forming |
| **proceduralaudio** | Additive_Synthesis, Subtractive_Synthesis, FM_Synthesis | Waveform shape, filter response, modulated wave |
| **fractals** | Koch_Curve (1D profile of self-similar coastline length) | Fractal dimension measurement |
| **physicssimulation** | Mass_Spring_Damper, Three_Body_Problem | Oscillation decay, chaotic trajectory (projected) |

### BAR ARRAY (1D discrete — vertical bars)

Algorithms that operate on ordered sequences of values.

| Sequence | Maps that could use BarArray | What bars show |
|----------|-----------------------------|---------------|
| **datastructures** | Heap_Operations, Segment_Tree, Fenwick_Tree | Heap array (bars = priorities), range queries highlighted |
| **searchpathfinding** | Dijkstra, A*, BFS, DFS | Distance values per node (sorted), frontier visualization |
| **machinelearning** | Clustering (k-means), Classification, Attention_Mechanisms | Cluster distances, feature importances, attention weights |
| **randomness** | Random_Gaussian, Examples_of_Randomness | Histogram bins forming distribution |
| **noise** | Noise_Functions | Frequency spectrum bars |
| **proceduralaudio** | ALL (Additive, Subtractive, FM, Granular, Effects) | Frequency spectrum, harmonic amplitudes, grain density |
| **wavefunctions** | Fourier_Form, Synthesis_Lab, Beat_Frequencies | Fourier coefficients, harmonic series, spectral analysis |
| **statistics** | Coinflip, Diceroll, Normal_Distribution, Hypothesis_Testing | Frequency counts, p-value bars, sample distributions |
| **computationalgeometry** | Closest_Pair (distance comparisons) | Sorted distances between pairs |
| **fractals** | Fibonacci_Sequences | Fibonacci numbers as growing bars |
| **primitives** | sort_algorithm_animation | THE classic — bars swapping during sort |

### GRID 2D (discrete cell grid — flat)

Algorithms that operate on 2D discrete space.

| Sequence | Maps that could use Grid2D | What cells show |
|----------|---------------------------|----------------|
| **cellularautomata** | ALL 12 maps (CA_1 through CA_12) | Cell states — alive/dead, rule colors, generations |
| **recursiveemergence** | CA_1D, CA_2D, Rule_30_110, Lattice_Gas | 1D automata (scrolling rows), 2D life, lattice gas particles |
| **searchpathfinding** | BFS, DFS, A*, Dijkstra | Grid with walls — frontier expanding, path found |
| **patterngeneration** | Wang_Tiles, Penrose_Tilings, DLA | Tile placement, growth patterns |
| **proceduralgeneration** | Maze, Wave_Function_Collapse, Cave | Maze walls, WFC tile resolution, cave/floor |
| **datastructures** | Hash_Maps, BSP_Trees, Quadtrees_Octrees | Hash table buckets (2D), spatial partition cells |
| **swarmintelligence** | Ant_Colony, Physarum | Pheromone grid, nutrient map |
| **machinelearning** | CNNs, GANs, VAEs | Convolution kernels, generated images, latent space 2D |
| **graphtheory** | Path_Finding_3d (2D slice), Topological_Sort | Adjacency matrix visualization |
| **computationalgeometry** | Point_in_Polygon, Morphological_Operations, EDT | Binary image operations, distance field |
| **patterngeneration** | ALL (One through Seven) | Pattern rules generating 2D output |
| **noise** | Perlin_Simplex, Blue_Noise, Noise_Functions | 2D noise field as grayscale grid |
| **transformation** | ALL (Translate, Rotate, Scale) | Grid cells being transformed |
| **arrays** | Array_Basics, Array_Patterns | Index visualization, pattern tiling |

### GRID 3D (volumetric MultiMesh — walkthrough)

Algorithms that need 3D spatial representation.

| Sequence | Maps that could use Grid3D | What dots/cubes show |
|----------|---------------------------|---------------------|
| **cellularautomata** | CA_9 (3D), CA_10 (continuous) | 3D cell states, volumetric evolution |
| **randomness** | Random_Space, Random_Space_Geometry, entropy_axiom | Point cloud density, entropy distribution |
| **noise** | Noise_Volume, Noise_Voxel | 3D noise field, voxel density |
| **proceduralgeneration** | Marching_Cubes (all variants), Isosurfaces | Density field → surface extraction |
| **datastructures** | Quadtrees_Octrees, BSP_Trees | Octree subdivision, BSP partition planes |
| **physicssimulation** | Fluid_Simulation_SPH, Particle_Systems | Particle positions, fluid density |
| **machinelearning** | Dimensionality_Reduction, Clustering | 3D point cloud of data, cluster boundaries |
| **graphtheory** | Force_Directed_3d, Graphspace_3d, Path_Finding_3d | Node positions, edge connections (NEEDS CONNECTION LAYER) |
| **swarmintelligence** | Boids, Particle_Swarm | Agent positions in 3D, swarm density |
| **computationalgeometry** | Convex_Hull, Closest_Pair, Voronoi | 3D point set, hull surface, Voronoi cells |
| **fractals** | Menger_Sponge, Sierpinski_Pyramid, 3D trees | Fractal point/cube removal |

### WALK SURFACE (continuous 2D terrain)

Algorithms that generate continuous landscapes you walk on.

| Sequence | Maps that could use WalkSurface | What terrain shows |
|----------|---------------------------------|-------------------|
| **wavefunctions** | Sine_Space (ALREADY WORKS) | Sine terrain — feel frequency/amplitude with body |
| **noise** | Noise_One, Noise_Perlin_Simplex, Noise_Space_10 | Perlin terrain, simplex landscape, layered octaves |
| **randomness** | Random_Pheromone, Random_Space_Geometry | Pheromone-shaped terrain, random height field |
| **searchpathfinding** | Gradient_Descent, Simulated_Annealing | Loss landscape — walk downhill to find minimum |
| **machinelearning** | Neural_Networks (loss landscape), Clustering | Fitness landscape, cluster topography |
| **proceduralgeneration** | Dome, CubeMound, Cave | Procedurally generated walkable terrain |
| **physicssimulation** | Force_Fields, Vector_Fields | Potential energy surface — feel the forces |
| **fractals** | Fibonacci_Terrain | Fractal terrain generation |
| **swarmintelligence** | FlowFields, Ant_Colony | Pheromone terrain evolving under swarm activity |
| **computationalgeometry** | Distance_Fields_SDF, Voronoi | SDF as elevation, Voronoi cell boundaries as ridges |

---

## Coverage Summary

| Substrate | Sequences that use it | Total maps |
|-----------|-----------------------|-----------|
| **Profile** | 9 sequences | ~25 maps |
| **BarArray** | 11 sequences | ~35 maps |
| **Grid2D** | 14 sequences | ~80+ maps |
| **Grid3D** | 11 sequences | ~30 maps |
| **WalkSurface** | 10 sequences | ~20 maps |
| **Bar** (single) | used within above | component |

**Grid2D is the backbone** — it serves the most sequences by far. That's why the pattern_tile_puzzle / grid_agent pattern is so important.

---

## Reuse Matrix

Which sequences share the SAME substrate instance (could literally swap algorithm cartridges):

### Grid2D cartridge swaps (same grid, different algorithm)

```
CA_1 (Game of Life)     ←→ SearchPathfinding (A*)     ←→ ProceduralGen (WFC)
    same grid                same grid                     same grid
    cell = alive/dead        cell = wall/open/frontier      cell = tile state
    rule = neighbors         rule = shortest path           rule = constraint propagation
```

### BarArray cartridge swaps

```
Sorting (bars swap)     ←→ FFT spectrum (bars = freq)   ←→ Histogram (bars = count)
    same bars                same bars                       same bars
    algorithm = bubble       algorithm = Fourier              algorithm = binning
```

### WalkSurface cartridge swaps

```
Sine_Space (sine)       ←→ Perlin terrain (noise)       ←→ Loss landscape (gradient)
    same surface             same surface                    same surface
    generate = sin(x,y)     generate = perlin(x,y)          generate = loss(w1,w2)
```

### Grid3D cartridge swaps

```
Entropy (random dots)   ←→ Marching cubes (density)     ←→ Octree (subdivision)
    same volume              same volume                     same volume
    value = random           value = density threshold       value = subdivision level
```

---

## Connection Layer (Grid3D addition)

Grid3D currently renders isolated points. For graph algorithms it needs visible connections.

**Sequences that need connections on Grid3D:**
- graphtheory: ALL 14 maps (edges between nodes)
- datastructures: Graph_Structures, Trees, Linked_Lists (parent→child links)
- machinelearning: Neural_Networks (layer connections), Attention (attention lines)
- swarmintelligence: Ant_Colony (trail connections), Boids (neighbor awareness)
- proceduralgeneration: Space_Colonization (growth edges), Branching_Growth

**Implementation:** Second MultiMesh of thin cylinders, same pattern as cell MultiMesh.
Each edge = one cylinder instance, positioned/rotated between two cell positions.

---

## What Doesn't Fit (needs its own thing)

| Sequence | Why it doesn't fit the 6 substrates |
|----------|-------------------------------------|
| **lsystems** | Tree/branching structure — recursive, not grid/array |
| **fractals** (some) | Self-similar geometry — recursive subdivision, not flat grid |
| **graphtheory** (some) | Force-directed layouts — continuous positioning, not grid cells |
| **softbodies** | Mesh deformation — vertex manipulation, not discrete cells |
| **joints** | Constraint chains — linked rigid bodies, not arrays |
| **transformation** (some) | 3D object transforms — operate on meshes, not grids |

These might need a 7th substrate: **MeshArtifact** — a deformable 3D mesh that algorithms reshape.
