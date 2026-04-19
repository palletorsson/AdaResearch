# Ada Research — AI Quick Reference

> **Read this first.** This file is auto-loaded by Claude Code on session start.

## Start Here

| Document | Purpose |
|----------|---------|
| `doc/ENTRY.md` | Project overview, QFEP framework, content chain |
| `doc/MAP_AGENT_ONBOARDING.md` | Map workflow, CLI tools, validation, done criteria |
| `doc/ONBOARDING_GUIDE.md` | Comprehensive guide with all AI skills listed |
| `doc/MAP_EDITING_PIPELINE.md` | End-to-end map editing flow (7 steps) |
| `doc/ARCHITECTURE.md` | Technical system architecture |

## Core Rule

- **Do not change core behavior like the grid system without deep consideration and notifying the user first.**

## Project Layout

Godot 4 VR/desktop project. Algorithms taught through maps and interactable artifacts.

**Content chain:** `Sequence JSON → Map JSON → Artifact Registry → Scene (.tscn/.gd)`

**3-layer grid** (in `map_data.json`):
- `structure`: geometry (floors/walls/void/heights)
- `utilities`: spawn, teleporter, ramps, transport cubes, labels
- `interactables`: artifacts by lookup name

**Scale:** ~42 sequences, ~503 maps, ~752 artifacts, 18 spine sequences

## CLI Tools

Run from repo root:

### Steering & Status
| Tool | Command | Purpose |
|------|---------|---------|
| **Pipeline Scorer** | `python tools/sequence_pipeline_scorer.py` | Score all 19 spine sequences through 7 completion stages |
| **Pipeline (single)** | `python tools/sequence_pipeline_scorer.py <seq_id>` | Score one sequence |
| **Dashboard** | `powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode status` | Project status, recommendations |
| **Heat Map** | `python tools/heat_map_generator.py` | Temperature-based priority scoring |

### Navigation & Context
| Tool | Command | Purpose |
|------|---------|---------|
| **LOD Query** | `python tools/lod_query.py <topic>` | Fractal-depth context lookup |
| **LOD Tree Gen** | `python tools/lod_tree_generator.py` | Regenerate LOD_TREE.json from codebase |
| **LOD Writer** | `python tools/lod_session_writer.py --topic X --insight Y --lod N` | Record session discoveries |
| **Ada Navigator** | `python tools/ada/ada.py overview` | Seq/map/artifact lookup |

### Validation & Quality
| Tool | Command | Purpose |
|------|---------|---------|
| **Pathfinder** | `python tools/map_pathfinder.py check <MapName> --verbose` | Reachability, rule validation |
| **Verify Sequence** | `python tools/verify_sequence.py <seq_id>` | Full sequence validation |
| **Workbench** | `python tools/spine_map_workbench.py status` | Sequence contracts, scaffolding |
| **Release Gates** | `python tools/run_release_gates.py --max-grade-c -1 --gate-toggles doc/reports/RELEASE_GATES_TOGGLES.json` | Launch-quality checks |

### Content & Identity
| Tool | Command | Purpose |
|------|---------|---------|
| **Garden Listener** | `python tools/garden_listener.py --diagnosis` | Audit sequence/map/artifact health |
| **Query Identities** | `python tools/query_identities.py truths` | Find @identity truth statements |
| **Map Text Writer** | `python tools/map_text_writer.py` | Generate blurb/intent/technical docs |
| **Classify Artifacts** | `python tools/classify_artifacts.py` | Auto-classify artifacts by category |

### Companion Tools (separate repos)
| Tool | Location | Purpose |
|------|----------|---------|
| **Context Manager** | `C:\Users\palle\Documents\GitHub\claude_context_manager` | Session browser, clone, memory, working tree |
| **Encyclopedia** | `C:\Users\palle\Documents\GitHub\ada_encyclopedia` | Web editors, search, substrates, API |
| **Writer** | `C:\Users\palle\Documents\GitHub\ada_writer_pro` | Book writing tool |

### Sequence Completion Pipeline (7 stages)
```
1. Structure     — maps defined in sequence JSON
2. Documentation — blurb.md + intent.md per map
3. Artifacts     — every interactable has a scene file on disk
4. Maps          — map_data.json with 3 layers
5. Validation    — pathfinder passes
6. VR Testing    — walked in headset, feedback via bridge
7. Polish        — captures fresh, docs updated
```
HEAD = lowest incomplete stage. Work at the head. Move it forward.

## Godot Capture Pipeline

Godot exe: `C:/Users/palle/Desktop/Godot_v4.6-stable_win64_console.exe`

Always use `--xr-mode off` to suppress OpenXR popup. Add `--no-window` for headless.

```powershell
# Single artifact (4 angles)
godot_console --path . --xr-mode off --no-window --script res://commons/testing/capture_multi_angle.gd -- --mode=artifact --target=<lookup_name>

# Single map (4 angles)
godot_console --path . --xr-mode off --no-window --script res://commons/testing/capture_multi_angle.gd -- --mode=map --target=<MAP_NAME>

# Full batch with manifest-based skip
godot_console --path . --xr-mode off --no-window --script res://commons/testing/capture_all.gd -- --outdir=user://capture_output --sequence=<seq> --skip-unchanged
```

Output: `user://multi_shots/<target>/<angle>.png` + `capture_report.json`

## Encyclopedia Integration

The Ada Encyclopedia (`ada_encyclopedia/`) is a Next.js web app providing visual editors and API access.

**Required env var:** `ADA_RESEARCH_PATH` — absolute path to this repo.

**Web editors** (run `npm run dev` in encyclopedia, default port 3003):
- `/map-builder` — 3-layer map editor with AI generation and simulation
- `/voxel-editor` — 3D structural level editor
- `/grid-editor` — VR glass rack layout designer
- `/pattern-maker` — Wallpaper group pattern editor

**Key API routes:**
- `GET /api/game/context?format=markdown` — Full game context for AI
- `GET /api/ai/capabilities?format=markdown` — Tool inventory for AI
- `POST /api/game/generate` — AI map generation
- `POST /api/game/analyze` — Map validation
- `POST /api/game/simulate` — AI pathfinding simulation
- `GET /api/maps?name=<Name>` — Map data retrieval
- `GET /api/artifacts` — Artifact registry

## Desktop ↔ AI Feedback Bridge

In VR, the DesktopMapSwitcherOverlay lets users type comments during gameplay. These are written to:
- `ada_run/desktop_feedback.md` (markdown entries with timestamp, map, sequence, artifacts)
- `ada_run/desktop_feedback.json` (structured JSON)
- `ada_run/codex_change_requests.md` (queued for AI)

AI reads feedback via the `/ada-bridge-listener` skill or direct file read.

## Map Editing Pipeline

```
1. DISCOVER  → ada.py overview / project_dashboard_cli.ps1 -Mode status
2. EDIT      → localhost:3003/map-builder  OR  direct JSON edit
3. VALIDATE  → map_pathfinder.py check <Name> --verbose  OR  POST /api/game/analyze
4. CAPTURE   → capture_multi_angle.gd --mode=map --target=<Name>
5. REVIEW    → View screenshots, POST /api/game/simulate, VR test
6. BRIDGE    → Read ada_run/desktop_feedback.md for VR session notes
7. ITERATE   → Apply feedback, return to step 2
```

See `doc/MAP_EDITING_PIPELINE.md` for detailed documentation.

## Key Paths (Truth Sources)

| What | Path |
|------|------|
| Curriculum spine | `commons/maps/curriculum_spine.json` |
| Sequence definitions | `commons/maps/sequences/*.json` |
| Map data | `commons/maps/{MapName}/map_data.json` |
| Artifact registries | `commons/artifacts/registry/*.json` |
| Legacy registry (deprecated) | `commons/artifacts/grid_artifacts.json.deprecated` |
| Grid system | `commons/grid/GridSystem.gd` |
| Utility registry | `commons/grid/UtilityRegistry.gd` |
| Hazard creatures | `commons/hazards/` — DangerZone, transformation blocks |
| Catalyst bracelet | `commons/hazards/becoming_catalyst/` — bracelet system |
| Nature system | `algorithms/nature_system/` — CritterDNA, morphology, evolution, spawner |
| Death effect | `commons/managers/DeathEffect.gd` — red flash, shake, reload |
| Ecosystem manager | `commons/managers/EcosystemManager.gd` — ecology progression |
| Soft stages | `commons/maps/soft_stages.json` — ecology density/kingdoms per sequence |

## AI Skills

| Command | Phase | Description |
|---------|-------|-------------|
| `/ada-dashboard` | orient | Coverage gaps, recommendations |
| `/ada-question-assistant` | orient | Answer project questions |
| `/ada-test-player` | assess | Walk sequences from source |
| `/ada-sequence-expert` | assess | Sequence design, progression |
| `/ada-code-guide` | understand | Deep GDScript walkthrough |
| `/ada-map-expert` | build | Create, edit, validate maps |
| `/ada-queer-theory-expert` | ground | QFEP and critical theory |
| `/ada-tutor` | ground | Teaching-level explanations |
| `/ada-bridge-listener` | verify | VR feedback → AI action |
| `/ada-humanizer` | document | Clean text for docs and UI |
| `/ada-code-documenter` | document | Generate code documentation |
| `/ada-task-manager` | track | Task management (plan/done/report) |
| `/ada-knowledge-updater` | track | Scan codebase, update knowledge |
| `/ada-orchestrator` | track | Session handoff, onboarding |

## Quick Context Loading

For targeted work, use the LOD query tool instead of reading everything:
```
python tools/lod_query.py <topic>
```

This returns only the relevant context at the right depth. The tree is generated from the actual codebase.

| Command | What you get |
|---------|-------------|
| `python tools/lod_query.py` | Project overview — stats, all sequences listed |
| `python tools/lod_query.py mosaicanalysis` | Sequence detail — maps, artifacts, truth statement |
| `python tools/lod_query.py MANN_Gallery_Museum` | Map detail — dimensions, artifacts placed |
| `python tools/lod_query.py pompeii_mosaic_floor` | Artifact detail — exports, key functions, file path |
| `python tools/lod_query.py pompeii_mosaic_floor._build_truchet_field` | Function detail |
| `python tools/lod_query.py meander` | Fuzzy search — finds all meander-related items |
| `python tools/lod_query.py --list sequences` | List all sequence IDs |

To record what this session discovered:
```
python tools/lod_session_writer.py --topic "meander" --insight "tiles repeat, mosaics don't" --lod 3
```

To regenerate the tree after codebase changes:
```
python tools/lod_tree_generator.py
```

## Map Building (IMPORTANT — read before making maps)

See `doc/MAP_BUILDING_GUIDE.md` for full details. Key points:

**Three layers:** structure (heights 0-5), utilities (sp/t/ds/r/m/an/3t), interactables (artifact:rotation:y_offset)

**Maps are narrative spaces with 5 phases:**
1. Entry (spawn + context)
2. Teaching (main artifact)
3. Exploration (related artifacts)
4. Reflection (text + darkness)
5. Exit (teleporter)

**Map Studio:** `/map-studio` in the encyclopedia — 3-layer visual editor built from scratch.

**Spine sequences are the priority** — 19 sequences forming the core curriculum.

## Heat Map

Run `python tools/heat_map_generator.py` to see what needs work.
The `/continue` skill reads this to pick the next task.

## Final Lap (thesis-landing readiness)

When working on final-arc sequences (`foundationscrisis`, `qfeplaboratory`, `postfoundationscrisis`), start with:

```
curl http://localhost:3003/api/final-lap?format=markdown
```

Returns underdeveloped maps, missing-map slots, unwalked maps, and recent VR feedback — context-enhancing at session start. Page: `localhost:3003/final-lap`. Scores live in `doc/final_lap_scores.json` — update at end of sessions that touch final-arc maps.

## Artifact Creation Pattern

3 files: `<token>.gd`, `<token>.tscn`, registry JSON entry.
- `extends Node3D`, `class_name PascalCase`, procedural in `_ready()`
- Include `apply_grid_config(config_data: Dictionary)`
- Register in `commons/artifacts/registry/<category>.json`
- Commit: `feat: add <token> artifact — description`

## Catalyst Bracelet System

Found on wireframe pedestal (bracelet, not crystal). 3 stones switch modes: cube (voxel block), wedge (walkable prism), off.
- Cardinal neighbor placement: 4 directions, 2 cells out from player
- trigger=place, grip=remove, bracelet rotation switches active stone
- Placed blocks persist in memory across maps within a session; fresh each game launch
- Source: `commons/hazards/becoming_catalyst/`

## Death System

DeathEffect is an autoload: red flash overlay, time freeze, camera shake, particles, haptic feedback, fade to black, then map reload.
- Fire hazard: 35 dmg per 0.3s tick. Lasers: 100 dps. `h:death`: instant kill.
- DangerZone utility codes in map_data.json: `h:fire`, `h:death`, `h:electric`, `h:toxic`, `h:vacuum`
- Source: `commons/managers/DeathEffect.gd`, `commons/hazards/`

## Ecology Progression

`soft_stages.json` defines creature density, kingdoms, and terrain per sequence stage.
- BiomeRingComponent spawns foliage and living CritterEntity organisms around maps
- NatureRenderer handles fog, sky color, and particles. EvolutionSystem + TransmutationManager drive self-generating behavior
- Progression: seq 1-2 grey/sterile, seq 3 first flowers, seq 11 creatures appear, seq 12+ full evolution
- Source: `algorithms/nature_system/`, `commons/managers/EcosystemManager.gd`
