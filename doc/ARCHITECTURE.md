# AdaResearch Architecture

> Technical reference for system design and data flow

## Overview

AdaResearch is a VR/desktop educational platform built in Godot 4. The architecture centers on three pillars:

1. **Grid System** — Component-based map rendering
2. **Artifact System** — Educational object registry and spawning
3. **Sequence System** — Curriculum progression and map organization

```
┌─────────────────────────────────────────────────────────────────┐
│                         AUTOLOADS                               │
│  GameManager · SceneManager · SoundBank · TraceData · etc.      │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│  Grid System  │     │   Artifact    │     │   Sequence    │
│  (rendering)  │◄────│   Registry    │     │   System      │
└───────────────┘     └───────────────┘     └───────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              ▼
                    ┌───────────────────┐
                    │    Map Data       │
                    │   (JSON files)    │
                    └───────────────────┘
```

---

## Directory Structure

```
AdaResearch/
├── algorithms/          # Algorithm implementations (content)
│   ├── cellularautomata/
│   ├── fractals/
│   ├── randomness/
│   ├── wavefunctions/
│   └── ...              # 50+ categories
│
├── commons/             # Shared infrastructure
│   ├── artifacts/       # Object registries
│   ├── audio/           # Sound system
│   ├── globals/         # Autoload scripts
│   ├── grid/            # Grid system components
│   ├── managers/        # Scene/game managers
│   ├── maps/            # Map data and sequences
│   ├── primitives/      # Basic 3D objects
│   ├── scenes/          # Reusable scenes
│   └── ui/              # Interface components
│
├── core/                # Physics and particle engines
│   ├── physics/
│   ├── particle.gd
│   ├── walker3d.gd
│   └── ...
│
├── addons/              # Third-party and custom plugins
│   ├── godot-xr-tools/  # VR interaction toolkit
│   └── ...
│
├── assets/              # Media (textures, models, audio)
├── shaders/             # Visual effects
├── spatial_ui/          # 3D interface components
└── docs/                # Documentation
```

---

## Autoloads (Singletons)

Globally accessible managers loaded at startup:

| Autoload | Script | Purpose |
|----------|--------|---------|
| `GameManager` | `commons/managers/GameManager.gd` | Game state, scoring, player data |
| `SceneManager` | `commons/managers/AdaSceneManager.gd` | Scene transitions, map loading |
| `SoundBank` | `commons/audio/SoundBankSingleton.gd` | Audio generation and caching |
| `MapProgressionManager` | `commons/managers/MapProgressionManager.gd` | Sequence/map progression |
| `TextManager` | `commons/managers/TextManager.gd` | Localization, text lookup |
| `TraceData` | `commons/globals/trace_data.gd` | Persistent drawing/trace storage |
| `EquipmentRegistry` | `commons/globals/equipment_registry.gd` | Player tool inventory |
| `Subtitles` | `commons/ui/subtitles/SubtitleManager.gd` | Accessibility subtitles |
| `XRToolsUserSettings` | `addons/godot-xr-tools/...` | VR user preferences |
| `XRToolsRumbleManager` | `addons/godot-xr-tools/...` | Haptic feedback |

---

## Grid System

**Location:** `commons/grid/`

The component-based system that renders maps from JSON data.

### Architecture

```
GridSystem.gd (orchestrator)
    │
    ├── GridDataComponent.gd        # Validates dimensions and data
    ├── GridStructureComponent.gd   # Renders physical geometry (cubes)
    ├── GridUtilitiesComponent.gd   # Spawns mechanics (teleporters, labels)
    ├── GridInteractablesComponent.gd # Spawns educational artifacts
    ├── GridSpawnComponent.gd       # Player spawn positioning
    ├── GridCeilingComponent.gd     # Sky dome rendering
    └── GridAudioComponent.gd       # Map-specific audio
```

### Data Flow

```
map_data.json
      │
      ▼
JsonMapLoader.load_map()
      │
      ▼
GridSystem.initialize()
      │
      ├──► GridStructureComponent.build_from_data()
      │         └── Creates cube geometry from `structure` layer
      │
      ├──► GridUtilitiesComponent.setup_utilities()
      │         └── Spawns teleporters, labels from `utilities` layer
      │
      └──► GridInteractablesComponent.spawn_interactables()
                └── Resolves artifacts from `interactables` layer
                         │
                         ▼
                GridArtifactRegistry.get_artifact_scene(name)
                         │
                         ▼
                    Scene instantiated
```

### Map JSON Schema

```json
{
  "map_info": {
    "name": "Example_Map",
    "description": "Human-readable description",
    "dimensions": { "width": 9, "depth": 16, "max_height": 2 }
  },
  "layers": {
    "structure": [["1","1",...], ...],
    "utilities": [[" ","t",...], ...],
    "interactables": [[" ","artifact_name",...], ...]
  }
}
```

### Layer Reference

| Layer | Purpose | Values |
|-------|---------|--------|
| `structure` | Physical geometry | `0`=empty, `1`=cube, `2`=stacked, `3`+ for height |
| `utilities` | Game mechanics | `t`=teleporter, `s`=spawn, `la:text`=label |
| `interactables` | Educational content | Artifact names from registry |

### Utility Registry

**Location:** `commons/grid/UtilityRegistry.gd`

Single source of truth for utility types:

```gdscript
enum UtilityType {
    TELEPORTER,           # "t" - Map transitions
    SPAWN_POINT,          # "s" - Player spawn
    LABEL,                # "la:text" - Floating labels
    SEQUENCE_TELEPORTER,  # "st" - Sequence navigation
    DARK_SPHERE,          # "dark_sphere" - Ambient lighting
    # ...
}
```

---

## Artifact System

**Location:** `commons/artifacts/`

Maps artifact names to scene paths for spawning.

### Registry Structure

```
commons/artifacts/
├── grid_artifacts.json          # Legacy master (700+ entries)
└── registry/                    # Modular registries
    ├── arrays.json
    ├── cellular_automata.json
    ├── foundations.json
    ├── fractals.json
    ├── furniture.json
    ├── lsystems.json
    ├── qfep.json
    ├── randomness.json
    ├── soft_bodies.json
    └── wavefunctions.json
```

### Artifact Entry Schema

```json
{
  "artifact_name": {
    "name": "Display Name",
    "lookup_name": "artifact_name",
    "description": "What it does",
    "scene": "res://path/to/scene.tscn",
    "category": "category_tag",
    "interaction": "grab|observe|touch",
    "complexity": "beginner|intermediate|advanced",
    "tags": ["tag1", "tag2"]
  }
}
```

### Configuration Syntax

Artifacts in map JSON can include inline configuration:

```
artifact_name:rotation:y_offset:scale
artifact_name#key:value#key2:value2
```

**Examples:**
- `grab_sphere_point` — Default placement
- `grab_sphere_point:180` — Rotated 180°
- `grab_sphere_point:0:2` — Elevated 2 units
- `code_display#tutorial:fractals_axioms` — With config

### Resolution Flow

```
"grab_sphere_point:180:0.5" (from map JSON)
         │
         ▼
GridInteractablesComponent.parse_token()
         │
         ├── name: "grab_sphere_point"
         ├── rotation: 180
         └── y_offset: 0.5
         │
         ▼
GridArtifactRegistry.get_artifact_scene("grab_sphere_point")
         │
         ├── Search registry/*.json (modular)
         └── Fallback to grid_artifacts.json (legacy)
         │
         ▼
Returns: "res://commons/primitives/point/grab_sphere_point.tscn"
         │
         ▼
Scene instantiated with transforms applied
```

---

## Sequence System

**Location:** `commons/maps/`

Organizes maps into learning progressions.

### Structure

```
commons/maps/
├── map_sequences.json           # Master registry (lists all sequences)
├── sequences/                   # 40+ sequence definitions
│   ├── primitives.json
│   ├── randomness.json
│   ├── fractals.json
│   ├── wavefunctions.json
│   ├── cellularautomata.json
│   └── ...
└── {MapName}/                   # Individual map folders
    ├── map_data.json            # 3-layer grid data
    ├── blurb.md                 # Short poetic hook
    ├── summary.md               # Overview
    ├── technical.md             # Code examples
    └── critical.md              # Theory critique
```

### Sequence Definition Schema

```json
{
  "sequences": {
    "sequence_name": {
      "name": "Display Name",
      "description": "What this sequence teaches",
      "maps": ["Map_1", "Map_2", "Map_3"],
      "learning_objectives": ["obj1", "obj2"],
      "prerequisites": ["other_sequence"],
      "audio": {
        "ambient_preset": "preset_name",
        "volume": -10.0
      },
      "algorithm_paths": {
        "Map_1": "res://algorithms/category/path/"
      }
    }
  }
}
```

### Content vs Infrastructure

Each map has two distinct concerns:

| Concern | Source | Purpose |
|---------|--------|---------|
| **Infrastructure** | `structure` + `utilities` layers | Physical space, navigation |
| **Content** | `interactables` layer + `*.md` files | Educational material |

---

## Audio System

**Location:** `commons/audio/`

Centralized sound generation with hierarchical configuration.

### Architecture

```
SoundBankSingleton.gd (autoload)
    │
    ├── Generates/caches sounds
    ├── Manages audio buses
    └── Provides sound lookup API
    
AmbientSoundController.gd (per-scene)
    │
    ├── Loads ambient presets
    ├── Handles pause/resume
    └── Manages continuous layers + random events
    
GridAudioComponent.gd (grid integration)
    │
    └── Connects map loading to audio system
```

### Configuration Hierarchy

```
Global defaults (map_sequences.json → audio_defaults)
    │
    └──► Sequence overrides (sequences/*.json → audio)
            │
            └──► Map overrides (map_data.json → audio)
```

### Key Files

| File | Purpose |
|------|---------|
| `SoundBankSingleton.gd` | Core sound generation and caching |
| `AmbientSoundController.gd` | Per-map ambient management |
| `presets/*.json` | Ambient preset definitions |
| `parameters/**/*.json` | Sound parameter files (70+) |
| `SOUND_SYSTEM_GUIDE.md` | Complete audio documentation |

---

## Scene Management

**Location:** `commons/managers/AdaSceneManager.gd`

### Transition Flow

```
User activates teleporter
        │
        ▼
GridSystem._on_teleporter_activated(map_name)
        │
        ▼
SceneManager.transition_to_map(map_name)
        │
        ├── Fade out (0.3s quick / 1.0s normal)
        ├── Unload current scene
        ├── Load new map via JsonMapLoader
        ├── Initialize GridSystem
        └── Fade in
```

### Scene Types

| Scene | Location | Purpose |
|-------|----------|---------|
| `grid.tscn` | `commons/scenes/` | VR map template |
| `grid_desktop.tscn` | `commons/scenes/` | Desktop map template |
| `lab.tscn` | `commons/scenes/` | Hub environment |
| `vrStaging.tscn` | `commons/scenes/` | VR initialization |

---

## VR Integration

**Addon:** `addons/godot-xr-tools/`

### Key Components

- **XRToolsUserSettings** — VR user preferences (autoload)
- **XRToolsRumbleManager** — Haptic feedback (autoload)
- **XRToolsPickable** — Grabbable object base class
- **XRToolsInteractableArea** — Interaction zones

### Player Setup

The VR player rig includes:
- XR Origin (tracking reference)
- Left/Right XRController3D (hand tracking)
- Movement providers (teleport, smooth locomotion)
- Interaction providers (grab, poke)

---

## Core Simulation

**Location:** `core/`

Physics and particle engines for algorithm visualizations.

### Key Classes

| Class | Purpose |
|-------|---------|
| `particle.gd` | Base particle with position, velocity, forces |
| `particle_emitter.gd` | Spawns and manages particle systems |
| `walker3d.gd` | Random walk implementation |
| `fish_tank.gd` | Bounded particle container |
| `neural_network.gd` | Simple neural net for ML demos |
| `perceptron.gd` | Single-layer perceptron |

### Physics Subfolder

`core/physics/` contains:
- Force calculations
- Collision detection
- Spring/constraint systems

---

## Data Flow Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER INTERACTION                             │
│            (teleporter activated, artifact grabbed)             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SCENE MANAGER                                │
│            (handles transitions, loading)                       │
└─────────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   JSON MAP      │  │    ARTIFACT     │  │     AUDIO       │
│   LOADER        │  │    REGISTRY     │  │     SYSTEM      │
└─────────────────┘  └─────────────────┘  └─────────────────┘
          │                   │                   │
          └───────────────────┼───────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    GRID SYSTEM                                  │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐               │
│  │ Structure   │ │ Utilities   │ │Interactables│               │
│  │ Component   │ │ Component   │ │ Component   │               │
│  └─────────────┘ └─────────────┘ └─────────────┘               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    RENDERED MAP                                 │
│         (cubes, teleporters, artifacts, audio)                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Extension Points

### Adding a New Algorithm Category

1. Create folder: `algorithms/{category}/`
2. Add scenes and scripts
3. Create registry: `commons/artifacts/registry/{category}.json`
4. Create sequence: `commons/maps/sequences/{category}.json`
5. Add to `map_sequences.json`

### Adding a New Map

1. Create folder: `commons/maps/{MapName}/`
2. Create `map_data.json` with 3 layers
3. Add to sequence: `sequences/{sequence}.json` → `maps` array
4. Create documentation files (`blurb.md`, `summary.md`, etc.)

### Adding a New Artifact

1. Create scene in appropriate location
2. Add entry to `commons/artifacts/registry/{category}.json`
3. Use in maps via `interactables` layer

### Adding a New Utility Type

1. Add enum value to `UtilityRegistry.gd`
2. Implement handling in `GridUtilitiesComponent.gd`
3. Document the syntax

---

## File Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Maps | `PascalCase_Number` | `Fractals_1`, `Point_Zero` |
| Artifacts | `snake_case` | `grab_sphere_point` |
| Sequences | `snake_case` | `cellular_automata` |
| Components | `PascalCaseComponent` | `GridStructureComponent` |
| Scenes | `snake_case.tscn` | `grid_desktop.tscn` |
| Scripts | `PascalCase.gd` or `snake_case.gd` | `GridSystem.gd` |

---

## Related Documentation

- `doc/CLAUDE_PROJECT_NAVIGATOR.md` — Comprehensive project guide
- `commons/audio/SOUND_SYSTEM_GUIDE.md` — Audio system details
- `doc/HOW_TO_ADD_MAP_SEQUENCE.md` — Sequence creation guide
- `doc/GRID_CONFIG_SYNTAX_GUIDE.md` — Map JSON syntax
- `CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md` — Gameplay walkthrough
