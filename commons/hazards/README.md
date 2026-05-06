# Hazards System

Enemies, environmental dangers, and interactive entities that populate Ada Research maps. Not traditional game enemies — these are **algorithmic creatures** that embody computational concepts, teaching through encounter rather than elimination.

## Design Philosophy

Hazards in Ada Research follow the Q-FEP principle: the same algorithmic potential manifests differently depending on relational context. A plasma critter shocks on raw contact but becomes a healing torch when touched with a stick. A force field damages in hazard mode but benefits in transmuted mode. The creature isn't conquered — it's *understood*.

## Base Classes

| Class | File | Purpose |
|-------|------|---------|
| `DangerZone` | `DangerZone.gd` | Area3D damage volume — 6 hazard types (fire, vacuum, electric, toxic, radiation, generic) |
| `HazardCreatureBase` | `HazardCreatureBase.gd` | CharacterBody3D with shared state machine, patrol/chase AI, health, personality system |

### HazardCreatureBase State Machine

All creatures extending `HazardCreatureBase` share these AI states:

1. **IDLE** — Stationary, waiting
2. **PATROL** — Random walk through environment
3. **DETECT** — Player spotted, transitioning to chase
4. **CHASE** — Pursuing player
5. **ATTACK** — Executing creature-specific attack
6. **STUNNED** — Temporarily disabled
7. **DEAD** — Destroyed

Subclasses override `_build_mesh()`, `_process_visual()`, and `_process_attack()` to define unique behavior.

## Module Categories

### Algorithmic Creatures (extend HazardCreatureBase)
| Module | Concept | Description |
|--------|---------|-------------|
| `branching_vine` | L-systems | Procedural vine that grows toward player |
| `bricoleur_golem` | Bricolage/rebuild | Asymmetric body from random parts, rebuilds on damage |
| `collision_crasher` | Physics/momentum | Orbiting tethered blocks with elastic collisions |
| `data_tree_walker` | Binary trees | Walking BST with visible AVL rotations on damage |
| `escher_stairwalker` | Impossible geometry | Penrose stair loop, glitch lunges |
| `fractal_hydra` | Fractal branching | Heads split on damage, max depth 3 |
| `gradient_hunter` | Gradient descent | Samples positions, gets stuck in local minima |
| `grammar_markov` | Markov chains | 4-state face transitions drive attack patterns |
| `graph_weaver` | Graph theory | 8-node network, BFS shortest path hunting |
| `hull_crusher` | Convex hull | Orbiting points define morphing hull |
| `index_sentinel` | Array indexing | 4x4 grid fires by [i][j] index pattern |
| `joint_articulator` | Joint mechanics | 6 limbs with different joint types |
| `lifeform_walker` | Cellular automata | Game of Life grid as armor |
| `maze_spinner` | Procedural generation | Rotating 5x5 maze around crystalline core |
| `mesh_morpher` | Topology | Morphs between sphere/cube/torus/cylinder |
| `paradox_stalker` | Logical paradoxes | Dual ghost silhouettes, Zeno's paradox |
| `qfep_calibrator` | Q-FEP parameters | Morphing dodecahedron with oscillating parameter beams |
| `spring_mass_bouncer` | Spring physics | 3x3 mass-spring grid, Hooke's law deformation |
| `tesseract_phaser` | 4D geometry | Wireframe tesseract phasing in/out via 4D rotation |
| `wave_rider` | Wave mechanics | Sine wave ribbon, fires at resonance peaks |

### Origami Creatures (CharacterBody3D, standalone)
| Module | Concept | Description |
|--------|---------|-------------|
| `armadillo_droideka` | Folding geometry | Articulated shell, fire bolt projectiles |
| `kaleidocycle` | Ring symmetry | Rotating kaleidocycle origami pattern |
| `kresling_spire` | Kresling fold | Twist-extending sniper tower |
| `miura_crawler` | Miura-ori | Flat corrugated sheet, inchworm locomotion |
| `scissor_stalker` | Scissor linkage | Hoberman legs with 3x extension |
| `sphere_droideka` | Shell geometry | Rolling ball, unfolds to tripod with shield |
| `waterbomb_hopper` | Waterbomb base | Bouncing origami tessellation |

### Environmental Hazards (Area3D / Node3D)
| Module | Concept | Description |
|--------|---------|-------------|
| `chromatic_field` | Color theory | 3 rotating RGB spheres, hue-based damage |
| `constraint_web` | CSP solving | 5x5 tile grid, domain collapse explosions |
| `force_field` | Q-FEP duality | 12 force types, hazard ↔ transmuted modes |
| `hazardousmaterial` | Material science | 6 toxic types with lingering damage |
| `isosurface_trap` | Scalar fields | Metaball charges drift toward player |
| `noise_field` | Noise functions | 10x10 Simplex noise tiles, scrolling danger |
| `pattern_mine` | SDF contours | 8 mines with distance field rings |
| `resonance_chamber` | Standing waves | Harmonic bar positions shift with frequency |
| `spatial_voronoi` | Voronoi diagrams | Ground cells with drifting seeds and status effects |

### Projectiles & Traps
| Module | Description |
|--------|-------------|
| `fallingblocks` | Spawns falling cubes from height |
| `fireball` | RigidBody3D projectile with explosion |
| `origami_pyre_plane` | Lethal floor with affine transformation cycle |
| `spiketrap` | Emerging ground spikes with warning phase |

### Complex Systems
| Module | Description |
|--------|-------------|
| `becoming_catalyst` | Player's evolving VR tool — 10 projectile modes unlocked by curriculum |
| `blockbuilderentity` | Geometry-consuming entity that cages the player |
| `gridagent` | 9-tier algorithmic entities that traverse and modify grids |
| `loving_triangle` | Non-hostile companion, dances with the Catalyst |
| `octapod_crawler` | 8-legged IK creature, hatches from egg-plant pod |
| `plasma` | Form-shifting energy substance with stick tool interaction |
| `swarm_hive` | Stationary hive spawning boid particles |
| `techstrider` | Three-legged procedural walker |
| `tentacle_cube` | Dormant cube that unfolds mechanical tentacles |

### Chaos / Meta
| Module | Description |
|--------|-------------|
| `frameratemanipulator` | Manipulates game FPS as gameplay mechanic |
| `meshduplicatorentity` | Duplicates scene meshes creating visual chaos |
| `nullvalueinjector` | Injects null values to cause runtime errors |
| `recursion_spiral` | Fibonacci spiral of self-similar nodes |

### Utilities
| Module | Description |
|--------|-------------|
| `hazards_demo` | Test scene for previewing hazard behaviors |
| `mushroom` | Edible mushroom with effect system |
| `timelimit` | Countdown timer UI that restarts the level |
