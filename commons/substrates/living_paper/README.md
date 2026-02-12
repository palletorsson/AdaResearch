# Living Paper — Universal 2D Algorithm Substrate

> Pick it up. It computes. Put it down. It remembers.

A grabbable paper that draws itself. The same physical object runs any 2D algorithm — random walks, cellular automata, sorting, fractals, L-systems, pathfinding, noise, reaction-diffusion, and more.

## Architecture

```
living_paper_manager.gd     — Scene controller, grab/drop lifecycle, cartridge factory
paper_algorithm.gd          — Base cartridge class: initialize(), step() → bool
living_paper.tscn           — Scene: GrabPaper (XR pickable) + texture quad + label
```

### Scene Tree

```
LivingPaper (Node3D) [living_paper_manager.gd]
└── GrabPaper (XRToolsPickable) [grab_paper.tscn instance]
    ├── CollisionShape3D (BoxShape3D)
    ├── MeshInstance3D (card body — BoxMesh 0.195 × 0.01 × 0.205)
    ├── Label (inherited, cleared — was "Color Info" placeholder)
    ├── RandomWalkPlanMesh (QuadMesh 0.19 × 0.19 — algorithm texture)
    └── id_info_Label3D (algorithm display name)
```

Grab → algorithm steps at `interval`. Drop → pause. History stays visible on texture.

### Key fix (2026-02-12)
- `RandomWalkPlanMesh` transform aligned to match card face (no rotation — identity basis, y=0.004 offset)
- Inherited `Label` node cleared to empty string (was showing "Color Info" placeholder from base `grab_paper.tscn`)
- Base `grab_paper.tscn` also fixed — default Label text now empty

## Cartridges (35 algorithms)

### Randomness
| Algorithm | Class | What you see |
|-----------|-------|-------------|
| `RANDOM_WALK_SIMPLE` | PaperRandomWalk | Cardinal direction walk |
| `RANDOM_WALK_BROWNIAN` | PaperRandomWalk | Organic drift |
| `RANDOM_WALK_LEVY` | PaperRandomWalk | Small steps + rare huge jumps |
| `RANDOM_WALK_SELF_AVOIDING` | PaperRandomWalk | Never revisits — gets trapped |
| `RANDOM_WALK_FRACTAL` | PaperRandomWalk | 30% chance to branch |
| `RANDOM_WALK_FIBONACCI` | PaperRandomWalk | Golden angle spiral |

### Cellular Automata
| Algorithm | Class | What you see |
|-----------|-------|-------------|
| `CA_1D_RULE30` | PaperCA1D | Wolfram chaos — orange cascade |
| `CA_1D_RULE110` | PaperCA1D | Turing complete — green structures |
| `CA_1D_RULE90` | PaperCA1D | Sierpinski triangle — purple fractal |
| `CA_2D_LIFE` | PaperCA2D | Conway's gliders and oscillators |
| `CA_2D_SEEDS` | PaperCA2D | Explosive growth |
| `CA_2D_BRIANS_BRAIN` | PaperCA2D | Firing neurons |

### Arrays / Sorting
| Algorithm | Class | What you see |
|-----------|-------|-------------|
| `SORTING_BUBBLE` | PaperSorting | Bars swapping, O(n²) visible |
| `SORTING_INSERTION` | PaperSorting | Cards inserting into place |
| `SORTING_MERGE` | PaperSorting | Pairs merging into larger groups |
| `SORTING_QUICK` | PaperSorting | Pivot partitioning recursively |

### Wavefunctions
| Algorithm | Class | What you see |
|-----------|-------|-------------|
| `SINE_WAVE` | PaperSineWave | Seismograph needle on paper |
| `FOURIER_SERIES` | PaperFourier | Harmonics building up complex wave |
| `LISSAJOUS` | PaperLissajous | Parametric figure tracing itself |

### Fractals
| Algorithm | Class | What you see |
|-----------|-------|-------------|
| `MANDELBROT` | PaperMandelbrot | Set revealing scanline by scanline |
| `JULIA_SET` | PaperJuliaSet | Random c-value, unique every time |
| `SIERPINSKI` | PaperSierpinski | Chaos game dots forming triangle |
| `KOCH_CURVE` | PaperKochCurve | Snowflake gaining detail each step |

### L-Systems
| Algorithm | Class | What you see |
|-----------|-------|-------------|
| `LSYSTEM_TREE` | PaperLSystem | Binary tree growing stroke by stroke |
| `LSYSTEM_FERN` | PaperLSystem | Barnsley fern unfolding |
| `LSYSTEM_DRAGON` | PaperLSystem | Dragon curve folding |

### Noise
| Algorithm | Class | What you see |
|-----------|-------|-------------|
| `PERLIN_NOISE` | PaperPerlinNoise | Terrain rendered row by row |
| `NOISE_OCTAVES` | PaperNoiseOctaves | Octaves layering: blur → detail → terrain |

### Search / Pathfinding
| Algorithm | Class | What you see |
|-----------|-------|-------------|
| `BFS_FLOOD` | PaperBFS | Color flooding through random walls |
| `DFS_MAZE` | PaperDFSMaze | Corridors carving, backtracking visible |

### Pattern Generation
| Algorithm | Class | What you see |
|-----------|-------|-------------|
| `REACTION_DIFFUSION` | PaperReactionDiffusion | Turing spots/stripes self-organizing |
| `DLA_CRYSTAL` | PaperDLA | Crystal growing from random walkers |

### Computational Geometry
| Algorithm | Class | What you see |
|-----------|-------|-------------|
| `VORONOI` | PaperVoronoi | Seeds appearing, cells forming |

### Machine Learning
| Algorithm | Class | What you see |
|-----------|-------|-------------|
| `KMEANS` | PaperKMeans | Points drifting toward centroids |

### Physics
| Algorithm | Class | What you see |
|-----------|-------|-------------|
| `HEAT_DIFFUSION` | PaperHeatDiffusion | Hot spot spreading, blue→red gradient |

### Data Structures
| Algorithm | Class | What you see |
|-----------|-------|-------------|
| `QUADTREE` | PaperQuadtree | Space splitting as points appear |

## Artifact Registry

Registered in `commons/artifacts/registry/living_paper.json` — 34 entries.
Auto-loaded by `GridInteractablesComponent` from the registry directory.

## Map Placement

### Named variants (algorithm auto-detected from lookup_name):
```
"living_paper_random_walk"
"living_paper_mandelbrot"
"living_paper_life"
"living_paper_voronoi:90"              — rotated 90°
"living_paper_bubble_sort:0:1.5"       — y-offset 1.5m
"living_paper_rule30:0:0:0.5"          — half scale
```

### Generic with #algorithm config:
```
"living_paper#algorithm:rule30"
"living_paper#algorithm:mandelbrot"
"living_paper:90#algorithm:life#interval:0.05"
```

### Multiple papers side by side:
```
"living_paper_brownian"     at (1,0)
"living_paper_levy"         at (3,0)
"living_paper_self_avoiding" at (5,0)
```

## Extending

To add a new algorithm, create a cartridge in `cartridges/`:

```gdscript
extends PaperAlgorithm
class_name PaperMyAlgorithm

func get_name() -> String:
    return "My Algorithm"

func initialize(img: Image, width: int, height: int) -> void:
    # Setup initial state on the image

func step(img: Image, step_index: int) -> bool:
    # Draw one step on img
    # Return false when done
    return true
```

Then:
1. Add to the `Algorithm` enum in `living_paper_manager.gd`
2. Add to `_create_algorithm()` match block
3. Add to `_resolve_algorithm_from_lookup_name()` map
4. Add to `apply_grid_config()` map
5. Add registry entry in `living_paper.json`
