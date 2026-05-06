# Contributing to Ada Research

A practical first-day guide for new contributors. Read this, then start building.

## What Is This Project?

Ada Research is a Godot 4.6 VR/desktop app that teaches algorithms through embodied interaction. You walk through rooms (maps), touch artifacts (algorithm visualizations), and progress through a curriculum organized by the Queer Free Energy Principle (QFEP) — a framework connecting order, chaos, and emergence.

The dual-lens approach: every algorithm has a **technical** explanation AND a **critical theory** lens examining the politics of computation.

## Prerequisites

- **Godot 4.6** — `C:/Users/palle/Desktop/Godot_v4.6-stable_win64_console.exe` (or your own install)
- **Python 3.10+** — for CLI tools
- **Node.js 18+** — only if working on the encyclopedia web app
- **Git** — standard workflow on `dev` branch, PRs to `main`

## Repo Layout

```
AdaResearch_46/
├── algorithms/           # ~52 categories of algorithm implementations (.gd/.tscn)
├── commons/
│   ├── artifacts/        # Artifact registry (registry/*.json) + shared scenes
│   ├── audio/            # Procedural audio system
│   ├── globals/          # Autoload singletons
│   ├── grid/             # THE core system — builds maps from JSON
│   ├── managers/         # Scene manager, progression, game state
│   ├── maps/             # Map data + sequence definitions
│   │   ├── sequences/    # *.json sequence playlists
│   │   ├── curriculum_spine.json  # The 19-sequence learning order
│   │   └── {MapName}/    # Per-map folders (map_data.json + 4 markdown files)
│   ├── primitives/       # Reusable 3D building blocks
│   └── testing/          # Capture scripts, validators
├── core/                 # Physics/particle engines
├── addons/               # Third-party plugins (godot-xr-tools)
├── ada_encyclopedia/     # Next.js web app (editors, API)
├── doc/                  # Documentation and reports
├── tools/                # Python CLI tools
└── CLAUDE.md             # AI assistant quick reference
```

## The Content Chain

This is the most important thing to understand:

```
Sequence (.json)  →  Maps (map_data.json)  →  Artifacts (registry)  →  Scenes (.tscn/.gd)
```

1. **Sequences** (`commons/maps/sequences/*.json`) define ordered playlists of maps with learning objectives and unlock requirements.
2. **Maps** (`commons/maps/{Name}/map_data.json`) are 3-layer grids:
   - `structure` — geometry (0=void, 1+=floor/walls at that height)
   - `utilities` — mechanics (`s`=spawn, `t:MapName`=teleporter, `wp`=ramp, `tc`=transport cube, `an`=annotation)
   - `interactables` — artifacts placed by lookup name (`artifact_name:rotation:scale`)
3. **Registries** (`commons/artifacts/registry/*.json`) map lookup names to scene paths.
4. **Scenes** (`algorithms/.../*.tscn` + `.gd`) are the actual Godot implementations.

Each map folder also has 4 markdown companion files (`blurb.md`, `summary.md`, `technical.md`, `critical.md`) shown as an in-game booklet.

## Key Autoloads and Managers

These singletons are always available at runtime:

| Singleton | What It Does |
|-----------|-------------|
| `AdaSceneManager` | Loads maps, advances sequences, handles transitions |
| `MapProgressionManager` | Tracks which sequences are unlocked, saves progress |
| `GridArtifactRegistry` | Resolves `lookup_name` → scene path from registries |
| `GameManager` | Game state, scoring, player data |
| `SoundBankSingleton` | Procedural audio generation and caching |
| `TextManager` | Localization and text lookup |
| `GameSettings` | Persistent user preferences |
| `DesktopModeManager` | VR vs desktop mode detection |

## The Grid System

The grid is the core architecture — **do not modify it without discussion**. Located in `commons/grid/`:

- `GridSystem.gd` — orchestrator that coordinates all components
- `GridStructureComponent.gd` — builds 3D geometry from the structure layer
- `GridUtilitiesComponent.gd` — spawns teleporters, ramps, annotations, etc.
- `GridInteractablesComponent.gd` — resolves and instantiates artifacts
- `GridSpawnComponent.gd` — positions the player at spawn point
- `UtilityRegistry.gd` — defines all utility token types

## How to Create an Artifact

Every artifact follows this pattern (3 files):

**1. Script** (`algorithms/category/token/token.gd`):
```gdscript
extends Node3D
class_name PascalCaseName

func _ready():
    # Build your visualization procedurally here

func apply_grid_config(config_data: Dictionary):
    # Accept configuration from the grid system
    pass
```

**2. Scene** (`algorithms/category/token/token.tscn`):
```
[gd_scene format=3]
[ext_resource type="Script" path="res://algorithms/category/token/token.gd" id="1"]
[node name="Token" type="Node3D"]
script = ExtResource("1")
```

**3. Registry entry** — add to the appropriate file in `commons/artifacts/registry/`:
```json
"token_name": {
    "name": "Display Name",
    "lookup_name": "token_name",
    "description": "What this artifact teaches",
    "scene": "res://algorithms/category/token/token.tscn",
    "category": "category_tag",
    "complexity": "beginner",
    "tags": ["tag1", "tag2"]
}
```

Registry files by domain: `arrays.json`, `fractals.json`, `transforms.json`, `physics_simulation.json`, `randomness.json`, `machinelearning.json`, `procgen_extra.json`, `qfep.json`, etc.

## How to Edit a Map

1. Open `commons/maps/{MapName}/map_data.json`
2. Edit the 3-layer grid (or use the web editor at `localhost:3003/map-builder`)
3. Validate: `python tools/map_pathfinder.py check MapName --verbose`
4. Capture screenshots: see the Godot capture section below

**Map rules to follow:**
- Players can walk same-height tiles and drop 1 level freely
- Climbing requires a ramp (`wp`); jumping 2+ levels requires a transport cube (`tc`)
- Teleporter positions must have `"0"` in the structure layer (void cell)
- The row behind a teleporter (z+1) must have floor tiles for landing
- All artifacts must be reachable from spawn

## CLI Tools

Run from the repo root:

```bash
# Project status and recommendations
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode status

# Navigate sequences, maps, artifacts
python tools/ada/ada.py overview

# Validate a specific map
python tools/map_pathfinder.py check MapName --verbose

# Sequence contract audit
python tools/spine_map_workbench.py status

# Run release quality gates
python tools/run_release_gates.py --max-grade-c -1 --gate-toggles doc/reports/RELEASE_GATES_TOGGLES.json
```

## Godot Capture Pipeline

Always use `--xr-mode off` to suppress the OpenXR headset popup:

```bash
# Capture 4 angles of an artifact
"C:/Users/palle/Desktop/Godot_v4.6-stable_win64_console.exe" --path . --xr-mode off --no-window --script res://commons/testing/capture_multi_angle.gd -- --mode=artifact --target=<lookup_name>

# Capture 4 angles of a map
"C:/Users/palle/Desktop/Godot_v4.6-stable_win64_console.exe" --path . --xr-mode off --no-window --script res://commons/testing/capture_multi_angle.gd -- --mode=map --target=<MAP_NAME>
```

Output lands in `user://multi_shots/<target>/`.

## Encyclopedia Web App

The `ada_encyclopedia/` directory is a Next.js app with visual editors:

```bash
cd ada_encyclopedia && npm run dev  # starts on port 3003
```

- `/map-builder` — 3-layer map editor with AI generation
- `/voxel-editor` — 3D structural level editor
- `/grid-editor` — VR glass rack layout designer
- `/pattern-maker` — wallpaper group pattern editor
- `/facade-builder` — Italian facade composer

## Commit Conventions

```
feat: add <token> artifact — description
feat: elevate <ArtifactName> — what was improved
fix: <MapName> teleporter reachability
docs: update <document> — what changed
```

Include `[oversight:TASK_ID]` when working from a task tracker.

## Good Starter Tasks

These are concrete first contributions to get familiar with the codebase:

1. **Write a missing README.md** — Many algorithm folders (`algorithms/color/drawing`, `algorithms/nature_system/demo`, etc.) lack README files. Pick one, read the code, write a short explanation.

2. **Add `apply_grid_config()` to a stub** — Many artifacts have empty `apply_grid_config()` methods. Pick one, read the script to understand its parameters, implement real config handling.

3. **Fix a map validation warning** — Run `python tools/map_pathfinder.py check <MapName> --verbose` on various maps. Fix any reachability or teleporter issues.

4. **Write companion markdown** — Some maps have missing or thin `blurb.md`/`summary.md`/`technical.md`/`critical.md` files. Read the map's artifacts, then write the teaching content.

5. **Elevate a placeholder artifact** — Some artifacts are marked PLACEHOLDER in their code (minimal implementation). Pick one from the task list and add real algorithm visualization, VR sliders, and `apply_grid_config()`.

## Key Reference Documents

| Document | When to Read It |
|----------|----------------|
| `doc/ENTRY.md` | Project overview, QFEP formula, stats |
| `doc/ARCHITECTURE.md` | System architecture deep dive |
| `doc/MAP_AGENT_ONBOARDING.md` | Map workflow, CLI tools, validation |
| `doc/ONBOARDING_GUIDE.md` | Comprehensive reference (AI-oriented) |
| `doc/MAP_EDITING_PIPELINE.md` | End-to-end map editing workflow |
| `doc/HOW_TO_ADD_MAP_SEQUENCE.md` | Adding new maps and sequences |
| `doc/MAP_QUALITY_SYSTEM.md` | Quality standards for maps |
| `CLAUDE.md` | AI assistant quick reference (auto-loaded) |

## Questions?

- Check `doc/ONBOARDING_GUIDE.md` for the comprehensive reference
- Run `/ada-question-assistant` for AI-assisted answers about the project
- Read the code — the truth is always in the JSON files and GDScript, not the docs
