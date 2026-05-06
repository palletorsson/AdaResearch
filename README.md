# Ada Research

> An artistic-research VR project that investigates algorithms by turning them into worlds the body can enter, manipulate, and think through.

Ada Research is a three-year artistic research project that uses the making of a VR game-world to investigate algorithms, computational geometry, and the limits of formal systems.

At its core, it is a **meta-quest into the world of algorithms**. "Meta" because the project is not only about presenting algorithmic ideas; it studies them by building an environment out of them. The development of the world is itself part of the research.

The project explores questions like:
- How do algorithms shape perception, knowledge, and action?
- What can algorithmic systems do well, and where do they break down?
- Are the limits of algorithms technical, ontological, social, or political?
- How can embodied, spatial, and visual experience help people understand structures that are usually taught symbolically?

It does this through immersive VR scenes where the user can encounter points, lines, primitives, transformations, grids, recursion, randomness, and more advanced mathematical structures as **explorable environments** rather than only as abstract notation.

But Ada Research is not just an educational math visualization project. It also has a critical and artistic aim. It questions dominant, streamlined, stereotyped digital worlds and tries to open space for alternative ways of seeing and building — often from queer, marginal, or non-standard perspectives. It is both:

- **a research platform** for embodied understanding of algorithms, and
- **a critique** of how algorithmic representation organizes the world.

Named after **Ada Lovelace** — invoking the history of computation, imagination, and formal systems. Built in **Godot 4.6** with OpenXR. *Can we put Paul Klee's Pedagogical Sketchbook in Virtual Drag?*

### The Queer Free Energy Principle (QFEP)

The theoretical framework unifying the curriculum:

```
QFE = F - lambda * E(S) + phi * dE(S,t)
```

| Term | Meaning | In the Curriculum |
|------|---------|-------------------|
| **F** | Free energy (order, prediction) | Primitives, geometry, structure |
| **E(S)** | Entropy (disorder, freedom) | Randomness, noise, possibility space |
| **lambda** | Entropy drive (0 to 1) | The dial between order and chaos |
| **phi * dE** | Rate of change sensitivity | Positive phi = the queer signature |

Life exists at lambda ~ 0.3-0.5: enough order to maintain identity, enough chaos to adapt. The curriculum physically embodies this — you start at pure order (primitives), move through oscillation (waves, forces), into entropy (randomness, noise, cellular automata), reach the edge of chaos (fractals, L-systems), enter integration (morphogenesis, swarms, soft bodies), and arrive at synthesis (foundations crisis, QFEP laboratory).

## Scale

| Metric | Count |
|--------|-------|
| Sequences | 42 (18 spine + 24 branch) |
| Maps | 500+ |
| Artifacts | 750+ across 12 registries |
| Algorithm categories | 52 |
| AI skills | 14 Claude Code slash commands |
| CLI tools | 15+ Python/PowerShell |

## The 18 Spine Sequences

The core curriculum, ordered by QFEP trajectory:

| # | Sequence | QFEP Phase | What You Learn |
|---|----------|------------|----------------|
| 1 | `primitives` | F (order) | Points, lines, triangles, cubes — the atoms of 3D |
| 2 | `transformation` | F (order) | Translation, rotation, scale — and the pits that kill you |
| 3 | `color` | oscillation | Chromatic space, perception |
| 4 | `forces` | oscillation | Newton, vectors, gravity |
| 5 | `wavefunctions` | oscillation | Sine, audio, signal processing |
| 6 | `randomness` | E(S) entropy | Distributions, walks, entropy meters |
| 7 | `noise` | E(S) entropy | Perlin, flow fields, terrain |
| 8 | `cellularautomata` | E(S) entropy | Game of Life, local rules to global patterns |
| 9 | `fractals` | lambda edge | Self-similarity, recursion, infinite detail |
| 10 | `lsystems` | lambda edge | Grammar-based growth, branching |
| 11 | `proceduralgeneration` | lambda edge | WFC, Markov, dungeon generation |
| 12 | `morphogenesis` | integration | Turing patterns, reaction-diffusion |
| 13 | `swarmintelligence` | integration | Boids, flocking, emergence |
| 14 | `softbodies` | integration | Deformable physics |
| 15 | `machinelearning` | integration | Neural nets, backpropagation |
| 16 | `foundationscrisis` | synthesis | Godel, Russell, limits of formal systems |
| 17 | `qfeplaboratory` | synthesis | Full QFEP embodied — tune the formula |
| 18 | `criticalalgorithms` | synthesis | Algorithmic bias, queer futures |

## How It Works

### Content Chain

```
Sequence JSON --> Map JSON --> Artifact Registry --> Scene (.tscn/.gd)
```

### 3-Layer Grid System

Every map is a `map_data.json` file with three layers:

- **structure**: heights 0-5 defining floors, walls, and voids
- **utilities**: spawn points, teleporters, ramps, hazards, labels
- **interactables**: artifacts placed by lookup name with rotation and offset

### Map Narrative Design (5 phases)

1. **Entry** — spawn + context setting
2. **Teaching** — the main artifact, front and center
3. **Exploration** — related artifacts to discover
4. **Reflection** — text panels and darkness
5. **Exit** — teleporter to the next map

### Each Map Has 4 Documentation Files

- `blurb.md` — poetic hook (what draws you in)
- `summary.md` — overview (what you'll learn)
- `technical.md` — code examples and implementation
- `critical.md` — queer theory critique (the unique part)

## Major Systems

### Catalyst Bracelet

The player's building tool, found in a wireframe pedestal in the lab. Three bracelet stones:
- **Cube** (blue) — Minecraft-style block placement with cardinal neighbors
- **Wedge** (orange) — walkable ramp/prism placement
- **Off** (grey) — deactivates building

Trigger places, grip removes, other hand rotates bracelet to switch modes. Look direction determines placement: 4 compass directions, 2 cells out. In-memory persistence across maps, fresh each game launch.

### Ecology Progression

The world grows as you advance through the curriculum:

| Stage | Sequences | What Appears |
|-------|-----------|-------------|
| Sterile | 1-2 | Grey lab, no nature |
| First flowers | 3-4 | Sparse grass and flowers in biome ring |
| Forest | 5-8 | Trees, bushes, fungi, Perlin terrain |
| Living ground | 9-10 | Presence grid, organisms mark terrain |
| Creatures | 11 | DNA-driven walking entities with L-system trees |
| Full evolution | 12+ | Self-generating world, breeding, transmutation |

Powered by `EcosystemManager`, `BiomeRingComponent`, `NatureRenderer`, and the full Nature System (CritterDNA, MorphologyRouter, EvolutionSystem, TransmutationManager).

### Death and Hazards

Hazard zones (`h:fire`, `h:death`, `h:electric`) and turrets deal damage. On hit: red VR vignette flash, teleport to spawn, 3-second immunity. Health reaches 0: full death sequence (shake, particles, fade) and game reset.

### Creature System

Unified DNA genome drives all 5 kingdoms (tree, creature, flower, fungus, hybrid). Procedural morphology generates meshes from genes. Creatures have a personality arc: FOE → WARY → NEUTRAL → CURIOUS → FRIEND. Player bonds through observation, feeding, touch, and shared survival. At bond 0.95: transmutation grants kingdom-specific abilities.

### Science Screen

2D visualization display inside VR. Tracks player interaction with point, line, and triangle primitives. Renders real-time coordinate grids, measurements, and formulas. The bridge between web-based 2D thinking tools and 3D VR experience.

## VR Design

### 6-Level Capacity Progression

1. **OBSERVE** — watch phenomena
2. **TOUCH** — grab objects, feel haptics
3. **MANIPULATE** — edit vertices, draw traces
4. **CONSTRUCT** — build shapes, solve puzzles
5. **CONTROL** — sliders, tune parameters
6. **EMBODY** — your movement IS the input

### Three Scales

- **INTIMATE** — table-scale, arm's reach
- **ROOM** — walk around installations
- **WORLD** — architectural/landscape scale

## Companion Tools

| Tool | Location | Purpose |
|------|----------|---------|
| **Ada Encyclopedia** | `ada_encyclopedia/` | Next.js web app: map-builder, voxel-editor, pattern-maker, facade-builder, pokemon-studio, search, blog |
| **Claude Context Manager** | Separate repo | Session browser, clone, memory, working tree management |
| **Ada Writer** | Separate repo | Book writing tool |

## CLI Tools

Run from repo root:

| Tool | Command | Purpose |
|------|---------|---------|
| Pipeline Scorer | `python tools/sequence_pipeline_scorer.py` | Score all 18 spine sequences through 7 stages |
| Heat Map | `python tools/heat_map_generator.py` | Priority scoring for what needs work |
| LOD Query | `python tools/lod_query.py <topic>` | Fractal-depth context lookup |
| Dashboard | `powershell -File commons/tools/project_dashboard_cli.ps1 -Mode status` | Project status and recommendations |
| Pathfinder | `python tools/map_pathfinder.py check <MapName> --verbose` | Map reachability validation |
| Release Gates | `python tools/run_release_gates.py` | Launch-quality checks |
| Garden Listener | `python tools/garden_listener.py --diagnosis` | Sequence/map/artifact health audit |

## 7-Stage Completion Pipeline

```
1. Structure     - maps defined in sequence JSON
2. Documentation - blurb.md + intent.md per map
3. Artifacts     - every interactable has a scene file
4. Maps          - map_data.json with 3 layers
5. Validation    - pathfinder passes
6. VR Testing    - walked in headset
7. Polish        - captures fresh, docs updated
```

HEAD = lowest incomplete stage. Work at the head. Move it forward.

## Getting Started

### Prerequisites

- Godot 4.6
- VR headset (optional — desktop mode available)
- Python 3.10+ (for CLI tools)

### Quick Start

1. Clone and open in Godot
2. Run `commons/scenes/lab.tscn` — the hub environment
3. Pick up the bracelet from the wireframe pedestal
4. Use teleporters to navigate between maps
5. Grab and interact with artifacts

### Desktop Testing

- Map Studio: `commons/maps/catalog/MapStudioDesktop3D.tscn` — split-view map editor
- Grid Desktop: `commons/scenes/grid_desktop.tscn` — test any map

### Encyclopedia (Web)

```bash
cd ada_encyclopedia
npm install && npm run dev
# Open http://localhost:3003
```

Map builder, artifact browser, search, flows, blog, and more.

## Architecture

```
AdaResearch/
├── algorithms/              # 52 categories of algorithm visualizations
│   ├── nature_system/       # CritterDNA, morphology, evolution, spawner
│   └── ...
├── commons/
│   ├── artifacts/           # 750+ educational objects (12 registry files)
│   ├── audio/               # Procedural sound system (70+ parameter files)
│   ├── grid/                # Component-based map rendering from JSON
│   ├── hazards/             # Creatures, danger zones, catalyst bracelet
│   ├── managers/            # Scene, game, progression, ecosystem, death
│   ├── maps/                # 500+ map directories + sequence definitions
│   └── scenes/              # Lab hub, VR staging, desktop testers
├── doc/                     # Architecture, onboarding, guides
└── tools/                   # CLI tools (Python/PowerShell)
```

### Key Entry Points

| System | File | Purpose |
|--------|------|---------|
| Grid | `commons/grid/GridSystem.gd` | Renders maps from JSON |
| Artifacts | `commons/artifacts/registry/*.json` | 12 modular registries |
| Sequences | `commons/maps/sequences/*.json` | Curriculum definitions |
| Catalyst | `commons/hazards/becoming_catalyst/` | Bracelet building tool |
| Ecology | `commons/managers/EcosystemManager.gd` | Progressive nature |
| Death | `commons/managers/DeathEffect.gd` | Damage/death feedback |
| Nature | `algorithms/nature_system/` | DNA, morphology, evolution |

## Documentation

| Document | Purpose |
|----------|---------|
| [doc/ENTRY.md](doc/ENTRY.md) | Project overview, QFEP framework |
| [doc/ARCHITECTURE.md](doc/ARCHITECTURE.md) | Technical system reference |
| [doc/MAP_BUILDING_GUIDE.md](doc/MAP_BUILDING_GUIDE.md) | How to build maps |
| [doc/VR_GAMEPLAY_DESIGN.md](doc/VR_GAMEPLAY_DESIGN.md) | VR design philosophy |
| [doc/ONBOARDING_GUIDE.md](doc/ONBOARDING_GUIDE.md) | Comprehensive onboarding |
| [doc/MAP_EDITING_PIPELINE.md](doc/MAP_EDITING_PIPELINE.md) | End-to-end map editing flow |
| [CLAUDE.md](CLAUDE.md) | AI quick reference (auto-loaded by Claude Code) |

## References

- Ada Lovelace, *Notes on the Analytical Engine* (1842)
- Paul Klee, *Pedagogical Sketchbook* (1953)
- Karl Friston, *The Free Energy Principle*
- Lynn Gamwell, *Mathematics and Art: A Cultural History* (2015)
- Daniel Shiffman, *The Nature of Code*
- Donna Haraway, *Staying with the Trouble* (2016)
- Karen Barad, *Meeting the Universe Halfway* (2007)

## License

MIT - see [LICENSE](LICENSE)
