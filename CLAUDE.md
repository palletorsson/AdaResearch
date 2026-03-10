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

| Tool | Command | Purpose |
|------|---------|---------|
| **Dashboard** | `powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode status` | Project status, recommendations |
| **Ada Navigator** | `python tools/ada/ada.py overview` | Seq/map/artifact lookup |
| **Workbench** | `python tools/spine_map_workbench.py status` | Sequence contracts, scaffolding |
| **Pathfinder** | `python tools/map_pathfinder.py check <MapName> --verbose` | Reachability, rule validation |
| **Release Gates** | `python tools/run_release_gates.py --max-grade-c -1 --gate-toggles doc/reports/RELEASE_GATES_TOGGLES.json` | Launch-quality checks |

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
| Legacy registry | `commons/artifacts/grid_artifacts.json` |
| Grid system | `commons/grid/GridSystem.gd` |
| Utility registry | `commons/grid/UtilityRegistry.gd` |

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

## Artifact Creation Pattern

3 files: `<token>.gd`, `<token>.tscn`, registry JSON entry.
- `extends Node3D`, `class_name PascalCase`, procedural in `_ready()`
- Include `apply_grid_config(config_data: Dictionary)`
- Register in `commons/artifacts/registry/<category>.json`
- Commit: `feat: add <token> artifact — description`
