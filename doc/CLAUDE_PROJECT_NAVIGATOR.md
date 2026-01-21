# AdaResearch Project Navigator

> A fractal guide for AI navigation - from macro structure to micro implementation

## How to Use This Document

This navigator follows a **self-similar structure**: each level contains the same pattern of organization, just at different scales. Start at the level you need, zoom in or out as required.

---

## Project Vision: The Why

**Ada Research** is named after Ada Lovelace, who wrote about the relationship between computers and generative art in 1842. The project is a VR meta-quest exploring how algorithms create "invisible fences" - how digital tools shape bodies, creativity, and subjectivity.

### Core Question
> Can we put Paul Klee's Pedagogical Sketchbook (1953) in Virtual Drag?

### The Queer Algorithmic Thesis
- As digital resolution increases, content gravitates toward the **stereotypical**
- Complex algorithms (fluid simulation, soft bodies) inherently challenge us to find new ways to see
- Yet platforms take shortcuts → binary stereotypes, heteronormative defaults
- The project probes for **queer potential within the technical/mathematical object itself**

### The Queer Free Energy Principle (QFEP)

The theoretical unifying framework:

```
QFE = F − λE(S) + φΔE(S,t)
```

| Term | Meaning | In the Project |
|------|---------|----------------|
| **F** | Free energy (order, prediction) | Primitives, determinism, structure |
| **E(S)** | System entropy (disorder, freedom) | Randomness, possibility space |
| **λ** | Entropy drive (how much system values chaos) | The dial between order and chaos |
| **φΔE(S,t)** | Rate of entropy change (embrace of becoming) | Positive φ = queer signature |

**Life exists at λ ≈ 0.3-0.5** — enough order to maintain identity, enough chaos to adapt.

**The curriculum embodies this:**
- **Primitives** = F maximized (pure order)
- **Wavefunctions** = F ↔ E(S) oscillation
- **Randomness** = E(S) made visible (entropy as freedom)
- **Emergence** = E(S) → F (patterns from noise)

### Entropy as Organizing Principle
Entropy = measure of disorder/uncertainty. In information theory, **difference requires more complex encoding than sameness**.
- Higher entropy → more noise, information, difference, diversity
- The project explores margins where algorithms meet **incompleteness and paradox**
- Turing's legacy: cryptography, morphogenesis, AI, undecidability, queerness, death

### The Four Work Packages (Research Structure)
1. **Basic Elements** - Randomness, Perlin noise, Voronoi, sine curves, particles
2. **Advanced Elements** - Fractals, flow fields, L-systems, cellular automata, soft bodies
3. **Pattern/World Building** - Reaction-diffusion, graph theory, procedural generation, neural nets
4. **Advanced Techniques** - Swarm intelligence, chaos theory, non-Euclidean spaces

### Expected Outcomes
- The VR world itself
- Exhibited installations
- A book documenting the grammar
- A game wiki explaining algorithms
- Open-source resource for researchers, artists, students

**Key References:**
- `addons/VR_VR_PT_2023.txt` - Full research proposal
- `commons/context/clipboard/tutorial_text/randomness_qfep_axioms.gd` - QFEP theoretical framework

---

## Critical Distinction: Content vs Infrastructure

Understanding this project requires distinguishing **what the map IS** from **what the map CONTAINS**.

### Infrastructure (The Stage)
These elements create the space and enable navigation but are not the content:
- `structure` layer → Physical geometry (cubes, platforms)
- `utilities` layer → Mechanics (teleporters, spawn points, labels)
- `dark_sphere` → Ambient lighting effect

### Content (The Knowledge)
The actual educational material unique to each map:
- `interactables` layer → Educational artifacts (excluding `dark_sphere`)
- `*.md` files → Written theory and documentation

### The Four Documentation Files

Each map folder can contain up to four markdown files:

| File | Purpose | Audience |
|------|---------|----------|
| `blurb.md` | Short poetic summary (1-3 sentences) | Player preview |
| `summary.md` | General overview of the map | Player/Developer |
| `technical.md` | Code examples, implementation notes | Developer |
| `critical.md` | Queer theory critique, philosophical questions | Scholar |

**Example from Point_Zero:**
- **blurb**: "Frames flicker, render passes. Point Zero marks the beginning..."
- **summary**: Layout, key elements, learning sequence, design intent
- **technical**: GDScript examples, Vector3.ZERO, coordinate systems
- **critical**: Thrownness, infrastructure vs foundation, politics of zero

---

## Development Status Matrix

Current state of sequence congruence (map data ↔ documentation alignment):

| Sequence | Maps | Congruence | Status | Notes |
|----------|------|------------|--------|-------|
| **primitives** | 13 | ~80% | Active | Reference implementation |
| **color** | - | ~70% | In progress | Needs polish |
| **transformations** | - | ~70% | In progress | Needs polish |
| **wavefunctions** | - | - | **Current Focus** | Active development |
| **randomness** | 13 | - | Needs md files | Maps exist, docs needed |
| **fractals** | 10 | - | Needs audit | Recent map updates |
| *Others* | - | <50% | Planned | Gradual content increase |

**Congruence** means: maps have corresponding md files, artifacts match documentation, learning flow is coherent.

---

## Level 0: The Whole

**AdaResearch** is a VR/desktop educational platform in Godot 4 exploring algorithms through embodied interaction and queer theory critique.

```
AdaResearch/
├── algorithms/     → Algorithm visualizations (the content)
├── commons/        → Shared infrastructure (the system)
├── core/           → Simulation engines (physics, particles)
├── assets/         → Media resources
├── shaders/        → Visual effects
├── spatial_ui/     → 3D interface components
└── docs/           → Documentation
```

**Entry Points for Common Tasks:**
| Task | Start Here |
|------|------------|
| Understanding a map | `commons/maps/{MapName}/map_data.json` |
| Finding an algorithm | `algorithms/{category}/{subcategory}/` |
| Modifying grid behavior | `commons/grid/Grid*.gd` |
| Adding artifacts | `commons/artifacts/registry/*.json` |
| Audio integration | `commons/audio/` |
| Scene transitions | `commons/managers/AdaSceneManager.gd` |

---

## Level 1: The Four Pillars

### 1.1 Grid System (The Stage)
**Location:** `commons/grid/`

The component-based system that renders maps in 3D space.

```
GridSystem.gd                    → Master orchestrator
├── GridDataComponent.gd         → Data validation, dimensions
├── GridStructureComponent.gd    → 3D cube geometry
├── GridInteractablesComponent.gd → Educational objects
├── GridUtilitiesComponent.gd    → Teleporters, labels, mechanics
├── GridSpawnComponent.gd        → Player positioning
├── GridCeilingComponent.gd      → Sky dome
└── GridAudioComponent.gd        → Spatial sound
```

**Key Reference:** `GRID_CONFIG_SYNTAX_GUIDE.md`

### 1.2 Map/Sequence System (The Curriculum)
**Location:** `commons/maps/`

Hierarchical learning progressions.

```
commons/maps/
├── map_sequences.json           → Master sequence registry
├── sequences/                   → 33 sequence definitions
│   ├── fractals.json           → Maps: Fractals_1 through Fractals_10
│   ├── randomness.json         → 13 maps on entropy/noise
│   └── ...                     → 31 more sequences
└── {MapName}/                   → Individual map folders
	├── map_data.json           → 3-layer structure (INFRASTRUCTURE)
	├── blurb.md                → Short poetic summary
	├── summary.md              → General overview
	├── technical.md            → Code/implementation notes
	└── critical.md             → Queer theory critique
```

**To understand a map's CONTENT**: Read `interactables` in map_data.json + the md files
**To understand a map's INFRASTRUCTURE**: Read `structure` and `utilities` layers

### 1.3 Artifact Registry (The Objects)
**Location:** `commons/artifacts/`

Lookup system connecting names to scenes.

```
commons/artifacts/
├── grid_artifacts.json          → Legacy master (200+ artifacts)
└── registry/                    → Modular registries
	├── fractals.json
	├── randomness.json
	├── cellular_automata.json
	└── ...
```

**Artifact Resolution:** `name` → `GridArtifactRegistry` → `scene path` → instantiation

### 1.4 Algorithm Library (The Knowledge)
**Location:** `algorithms/`

50+ categories of algorithm implementations.

```
algorithms/
├── fractals/                    → Self-similarity, recursion
├── randomness/                  → Entropy, distributions
├── cellularautomata/            → Pattern generation
├── forces/                      → Physics-based
├── wavefunctions/               → Audio/signal
├── graphtheory/                 → Networks
├── emergentsystems/             → Boids, ecosystems
├── chaos/                       → Strange attractors
└── ...                          → 40+ more categories
```

---

## Level 2: Data Structures

### 2.1 Map JSON Schema

```json
{
  "map_info": {
	"name": "MapName",
	"description": "Human readable description",
	"dimensions": { "width": 9, "depth": 16, "max_height": 2 }
  },
  "layers": {
	"structure": [["1","1",...], ...],      // Geometry
	"utilities": [[" ","t",...], ...],      // Mechanics
	"interactables": [[" ","artifact",...], ...] // Objects
  }
}
```

**Layer Quick Reference:**

| Layer | Purpose | Common Values |
|-------|---------|---------------|
| structure | Physical geometry | `0`=empty, `1`=cube, `2`=stacked |
| utilities | Game mechanics | `t`=teleporter, `s`=spawn, `la:text`=label |
| interactables | Educational objects | artifact names from registry |

### 2.2 Artifact Configuration Syntax

```
artifact_name:rotation:y_offset:scale
artifact_name#config_key:value#config_key2:value2
```

**Examples:**
- `grab_sphere_point` → default placement
- `grab_sphere_point:180` → rotated 180°
- `grab_sphere_point:0:2` → elevated 2 units
- `code_display#tutorial:fractals_axioms` → configured clipboard

### 2.3 Sequence Definition Schema

```json
{
  "sequences": {
	"sequence_name": {
	  "name": "Display Name",
	  "description": "...",
	  "maps": ["Map_1", "Map_2", ...],
	  "learning_objectives": [...],
	  "prerequisites": ["other_sequence"],
	  "audio": {
		"ambient_preset": "preset_name",
		"volume": -10.0
	  },
	  "algorithm_paths": {
		"Map_1": "res://algorithms/category/subcategory/"
	  }
	}
  }
}
```

---

## Level 3: System Flows

### 3.1 Map Loading Flow

```
User activates teleporter
	↓
GridSystem._on_teleporter_activated()
	↓
AdaSceneManager.transition_to_map(map_name)
	↓
JsonMapLoader.load_map(map_path)
	↓
Parse 3 layers from JSON
	↓
┌─────────────────────────────────────────────────┐
│ GridStructureComponent.build_from_data()        │
│ GridUtilitiesComponent.setup_utilities()        │
│ GridInteractablesComponent.spawn_interactables()│
└─────────────────────────────────────────────────┘
	↓
GridArtifactRegistry.get_artifact_scene(name)
	↓
Artifact.apply_grid_config(config_dict)
	↓
AmbientSoundController.set_ambient_preset()
	↓
Map rendered and interactive
```

### 3.2 Artifact Resolution Flow

```
Map JSON contains: "grab_sphere_point:180:0.5"
	↓
GridInteractablesComponent parses token
	↓
name: "grab_sphere_point"
rotation: 180
y_offset: 0.5
	↓
GridArtifactRegistry.get_artifact_scene("grab_sphere_point")
	↓
Searches:
  1. commons/artifacts/registry/*.json (modular)
  2. commons/artifacts/grid_artifacts.json (legacy)
	↓
Returns: "res://commons/primitives/point/grab_sphere_point.tscn"
	↓
Scene instantiated, positioned, configured
```

### 3.3 Audio Integration Flow

```
Map loaded
	↓
Sequence definition checked for audio config
	↓
AmbientSoundController.set_ambient_preset(preset_name)
	↓
SoundBankSingleton loads parameters from:
  commons/audio/parameters/{category}/{preset}.json
	↓
Spatial audio positioned in scene
```

---

## Level 4: File Locations Index

### Managers (Singletons)
| Manager | File | Purpose |
|---------|------|---------|
| AdaSceneManager | `commons/managers/AdaSceneManager.gd` | Scene transitions, sequence control |
| GridArtifactRegistry | `commons/managers/GridArtifactRegistry.gd` | Artifact name → scene lookup |
| JsonMapLoader | `commons/managers/JsonMapLoader.gd` | Map JSON parsing |
| SoundBankSingleton | `commons/audio/SoundBankSingleton.gd` | Centralized audio |
| GameManager | `commons/managers/GameManager.gd` | Game state |

### Grid Components
| Component | File | Responsibility |
|-----------|------|----------------|
| GridSystem | `commons/grid/GridSystem.gd` | Orchestration |
| GridDataComponent | `commons/grid/GridDataComponent.gd` | Data validation |
| GridStructureComponent | `commons/grid/GridStructureComponent.gd` | 3D geometry |
| GridInteractablesComponent | `commons/grid/GridInteractablesComponent.gd` | Object spawning |
| GridUtilitiesComponent | `commons/grid/GridUtilitiesComponent.gd` | Mechanics |
| GridSpawnComponent | `commons/grid/GridSpawnComponent.gd` | Player spawn |

### Key Data Files
| Data | Location |
|------|----------|
| All sequences | `commons/maps/sequences/*.json` |
| Sequence registry | `commons/maps/map_sequences.json` |
| Artifact registry (legacy) | `commons/artifacts/grid_artifacts.json` |
| Artifact registries (modular) | `commons/artifacts/registry/*.json` |
| Audio presets | `commons/audio/ambient_presets.json` |
| Sound parameters | `commons/audio/parameters/**/*.json` |
| Tutorial texts | `commons/context/clipboard/tutorial_text/*.md` |

### Scene Templates
| Scene | Location | Purpose |
|-------|----------|---------|
| Grid (VR) | `commons/scenes/grid.tscn` | Standard VR map |
| Grid (Desktop) | `commons/scenes/grid_desktop.tscn` | Desktop variant |
| Lab | `commons/scenes/lab.tscn` | Hub environment |
| VR Staging | `commons/scenes/vr_staging.tscn` | VR initialization |

---

## Level 5: Algorithm Categories

### Active Sequences (with maps)

| Category | Path | Maps | Sequence File |
|----------|------|------|---------------|
| Fractals | `algorithms/fractals/` | 10 | `sequences/fractals.json` |
| Randomness | `algorithms/randomness/` | 13 | `sequences/randomness.json` |
| Primitives | `commons/primitives/` | 11 | `sequences/primitives.json` |
| Vectors | `algorithms/vectors/` | - | `sequences/vectors.json` |
| Cellular Automata | `algorithms/cellularautomata/` | - | `sequences/cellularautomata.json` |
| L-Systems | `algorithms/lsystems/` | - | `sequences/lsystems.json` |
| Forces | `algorithms/forces/` | - | `sequences/forces.json` |
| Wavefunctions | `algorithms/wavefunctions/` | - | `sequences/wavefunctions.json` |

### Algorithm Directory Pattern

```
algorithms/{category}/{subcategory}/
├── {Name}.gd           # Implementation
├── {Name}.tscn         # Scene
└── README.md           # Documentation (optional)
```

---

## Level 6: Common Modifications

### Adding a New Map to a Sequence

1. Create folder: `commons/maps/{MapName}/`
2. Create `map_data.json` with 3-layer structure (infrastructure)
3. Add map name to sequence: `commons/maps/sequences/{sequence}.json`
4. Create the four documentation files (content):
   - `blurb.md` - Short poetic hook
   - `summary.md` - Overview, layout, key elements
   - `technical.md` - Code examples, implementation
   - `critical.md` - Theoretical critique

### Registering a New Artifact

1. Create scene in appropriate location
2. Add entry to `commons/artifacts/registry/{category}.json`:
```json
"artifact_name": {
  "name": "artifact_name",
  "description": "What it does",
  "scene": "res://path/to/scene.tscn"
}
```

### Adding Tutorial Text

1. Create `.md` file in `commons/context/clipboard/tutorial_text/`
2. Register in `tutorial_text.json`
3. Reference via artifact config: `code_display#tutorial:filename`

---

## Quick Search Commands

When exploring this project, use these search patterns:

```bash
# Find all maps in a sequence
grep -r "maps" commons/maps/sequences/fractals.json

# Find artifact definition
grep -r "artifact_name" commons/artifacts/

# Find where artifact is used in maps
grep -r "artifact_name" commons/maps/*/map_data.json

# Find algorithm implementation
ls algorithms/fractals/*/

# Find all sequence definitions
ls commons/maps/sequences/

# Find grid system components
ls commons/grid/Grid*.gd
```

---

## Critical Files Summary

**If you need to understand one file from each system:**

| System | Critical File | Why |
|--------|--------------|-----|
| Grid | `GridSystem.gd` | Orchestrates all components |
| Maps | Any `map_data.json` | Shows 3-layer structure |
| Sequences | `fractals.json` | Complete sequence example |
| Artifacts | `grid_artifacts.json` | Master artifact registry |
| Managers | `AdaSceneManager.gd` | Scene transition logic |
| Audio | `SoundBankSingleton.gd` | Audio system entry point |

---

## Conventions

**Naming:**
- Maps: `PascalCase_Number` (e.g., `Fractals_1`)
- Artifacts: `snake_case` (e.g., `grab_sphere_point`)
- Sequences: `snake_case` (e.g., `cellular_automata`)
- Components: `PascalCase` with `Component` suffix

**Files:**
- Map data: always `map_data.json`
- Critique: always `critical.md`
- Technical notes: always `technical.md`
- Scene files: `.tscn`
- Scripts: `.gd`

---

## Navigation Shortcuts

| I want to... | Go to... |
|--------------|----------|
| Understand a map's **content** | `commons/maps/{MapName}/*.md` + `interactables` layer |
| Understand a map's **infrastructure** | `commons/maps/{MapName}/map_data.json` → `structure`, `utilities` |
| See all maps in a sequence | `commons/maps/sequences/{name}.json` → `maps` array |
| Find an algorithm's code | `algorithms/{category}/{subcategory}/{Name}.gd` |
| Add an interactive object | `commons/artifacts/registry/` |
| Change grid behavior | `commons/grid/Grid{Component}Component.gd` |
| Modify scene transitions | `commons/managers/AdaSceneManager.gd` |
| Add audio to a map | `commons/maps/sequences/{name}.json` → `audio` field |
| Create tutorial content | `commons/context/clipboard/tutorial_text/` |
| Test a map | `commons/scenes/desktop_map_tester.tscn` |

---

## Strategic Development Priorities

Based on current project state, the development sequence for achieving full congruence:

### Immediate (Current Focus)
1. **Wavefunctions** - Active development, establish patterns

### Near-term
2. **Randomness** - Has 13 maps, needs md files for each
3. **Fractals** - Has 10 maps, audit existing docs against recent changes

### Ongoing
4. **All sequences** - Gradual content increase toward 80%+ congruence

### Congruence Checklist for Each Map
- [ ] `map_data.json` has meaningful `interactables` (not just infrastructure)
- [ ] `blurb.md` exists with poetic summary
- [ ] `summary.md` documents layout, elements, learning sequence
- [ ] `technical.md` provides code examples
- [ ] `critical.md` explores theoretical questions
- [ ] Artifacts referenced in map are registered in artifact registry
- [ ] Learning flow connects to previous/next maps in sequence

---

*This document follows the fractal principle: the same organizational patterns repeat at every scale. Zoom in for detail, zoom out for context.*
