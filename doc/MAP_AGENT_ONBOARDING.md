# Map Agent Onboarding (CLI + Context)

This file is the fast start for any AI agent joining AdaResearch.

Use this when you need:
- project context in 2 minutes
- exact CLI tools to run
- a safe default workflow before making edits

## 1) Core Project Context

AdaResearch is a Godot 4 VR/desktop project where algorithms are taught through maps and interactable artifacts.

Scope guard for this document:
- This workflow is for map/level production and map-adjacent validation.
- Do not use this as the primary guide for global architecture, engine-wide refactors, or non-map systems.

The main content chain is:

`Sequence JSON -> Map JSON -> Artifact Registry -> Scene (.tscn/.gd)`

At map level, everything is built on 3 layers in `map_data.json`:
- `structure`: spatial geometry (floors/walls/heights)
- `utilities`: spawn, teleports, subtitles, labels, support objects
- `interactables`: artifacts and interactive objects by lookup name

## 2) First 15 Minutes (Required)

Run these commands in order from repo root:

```powershell
# 1) High-level project status and priorities
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode status
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode recommend

# 2) Sequence/map navigation index
python tools/ada/ada.py overview
python tools/ada/ada.py spine

# 3) Current workspace state
git status --short
```

If the task is sequence-specific:

```powershell
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode sequence -Name <sequence_name>
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode context -Name <map_name>
```

## 3) Main CLI Tools

### A) Dashboard CLI (planning + missing content)
Path: `commons/tools/project_dashboard_cli.ps1`

Use for:
- backlog status
- near-win prioritization
- map/sequence context

Common commands:

```powershell
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode nearwin
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode tasks
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode missing -Format csv
```

Reference: `commons/tools/PROJECT_DASHBOARD_CLI.md`

### B) Ada Navigator CLI (code/content lookup)
Path: `tools/ada/ada.py`

Use for:
- locating maps/artifacts/docs fast
- tracing references

Common commands:

```powershell
python tools/ada/ada.py seq <sequence_name>
python tools/ada/ada.py map <map_name>
python tools/ada/ada.py refs <artifact_lookup_name>
python tools/ada/ada.py find "<query>"
```

Reference: `tools/ada/README.md`

### C) Spine Map Workbench (map scaffolding/audits)
Path: `tools/spine_map_workbench.py`

Use for:
- sequence contract audits
- artifact curation audits
- scaffold map creation

Common commands:

```powershell
python tools/spine_map_workbench.py status
python tools/spine_map_workbench.py sequence-contract
python tools/spine_map_workbench.py suggest --sequence <sequence_name>
```

### D) Map Pathfinder (reachability + path finding)
Path: `tools/map_pathfinder.py`

Use for:
- checking map construction rules (spawn height, teleport row, reachability)
- finding shortest path from spawn to any artifact or teleport
- ASCII visualization of walkability and paths

Common commands:

```powershell
# Check all 4 rules on a single map
python tools/map_pathfinder.py check Crisis_Synthesis --verbose

# Check all curriculum maps
python tools/map_pathfinder.py check --all

# Show ASCII map with reachability overlay
python tools/map_pathfinder.py show Russell_Paradox

# Find shortest path from spawn to an artifact
python tools/map_pathfinder.py path Crisis_Synthesis --to qfep_formula_3d

# Find path to teleport
python tools/map_pathfinder.py path Euclid_Parallel --to teleport
```

### E) Release Gates
Path: `tools/run_release_gates.py`

Use for:
- launch-quality gate checks

Common commands:

```powershell
python tools/run_release_gates.py --max-grade-c -1 --gate-toggles doc/reports/RELEASE_GATES_TOGGLES.json
python tools/run_release_gates.py --max-grade-c -1 --gate-toggles doc/reports/RELEASE_GATES_TOGGLES.json --require-all-gates-enabled
```

## 4) In-Engine Validation/Testing Scenes

- Content validator UI: `res://commons/dev_tools/ContentValidatorDesktop.tscn`
- Map catalog/editor: `res://commons/maps/catalog/MapCatalogDesktop3D.tscn`
- Automated runtime map testing: `res://commons/testing/map_test_runner.tscn`
- Batch map screenshots via catalog:
  - script: `res://commons/testing/catalog_batch_screenshot_runner.gd`
  - output: `user://catalog_map_screenshots/`

Runnable examples:

```powershell
# Quick content validation report
godot --path . --script res://commons/dev_tools/validate_content.gd

# Open map test runner scene directly
godot --path . res://commons/testing/map_test_runner.tscn

# Headless batch screenshots through MapCatalogDesktop3D
godot_console --path . --script res://commons/testing/catalog_batch_screenshot_runner.gd -- --sequence=primitives --max-maps=5 --out=user://catalog_map_screenshots
```

## 5) Default Agent Workflow

1. Discover scope (`project_dashboard_cli`, `ada.py`, file reads)
2. If map placement/spatial composition is involved, provide suggestions before edits
3. Implement smallest safe change set
4. Validate (`ContentValidatorDesktop`, map test runner, or relevant CLI audit)
5. Summarize touched files + remaining risks

For skill sequencing, use: `doc/SKILL_WORKFLOW.md`

## 6) Done Criteria (Map Task)

A map/level task is done when all are true:
- The requested map edits are implemented and saved in tracked files.
- Validation completed (at least one):
  - `ContentValidatorDesktop` pass for affected scope, or
  - CLI validation/audit command relevant to the task.
- Runtime smoke check completed on affected map(s) (interactive or scripted runner).
- Evidence captured when requested (for example screenshot output/report paths).
- Handoff summary includes: files changed, commands run, known risks, next actions.

## 7) Map Construction Rules

Every map must satisfy these rules. Violating them causes the player to fall into void or get stuck.

**Movement model:** The player can walk between same-height tiles and **drop down 1 level** (e.g. h2→h1). Dropping **2 or more levels** (e.g. h3→h1) requires a `tc` transport cube. The player **cannot climb up** without a `wp` ramp.

### Rule 2: Teleport needs +1 row of floor cubes in z
The teleport (`t` in utilities) requires **a structure row with floor cubes (h>0) behind it in +z**. Without it the player falls through on arrival. The row immediately after the teleport row in structure must contain floor tiles to catch the player.

Reference: `res://commons/maps/Russell_Paradox/map_data.json` — teleport at row 10 on void, row 11 has floor cubes behind it.

### Rule 3: Teleport must be reachable
The teleport tile must be reachable from spawn. The player can drop down to it or walk to it, with utility assistance if needed (see Rule 4).

### Rule 4: All interactable artifacts must be reachable
Every artifact placed in the interactables layer must be reachable by the player through one of:
- **Walking/dropping** — adjacent floor tiles at same or lower height (player can always fall down)
- **Ramp/walkpath (`wp`)** — required for **climbing up** between height levels (e.g. `wp:180` ramps south). Reference: `res://commons/maps/F30_Ramp_Walkpath/`
- **Transport cube (`tc`)** — moving platforms that bridge gaps over void or between heights (e.g. `tc:3:z:auto` moves 3 units on z-axis). Reference: `res://commons/maps/F31_Transport_Cube/`

If an artifact sits on an elevated tile (higher than spawn) or across a void gap, the utilities layer **must** provide a path to it.

### Rule 5: Teleport must stand on y=0 (void)
The structure cell at the teleport position **must be `"0"`** (void). The teleport itself provides the landing — it should not have floor geometry underneath. Auto-fixable: `map_pathfinder.py fix`.

### Rule 6: Only one teleport per map
In the normal case a map should have **exactly one teleport**. Multiple teleports are allowed in special cases but trigger a warning during validation.

### Checking and fixing rules

```powershell
# Check rules on a map
python tools/map_pathfinder.py check Russell_Paradox --verbose

# Auto-fix Rule 2 and Rule 5 across all curriculum maps
python tools/map_pathfinder.py fix --all

# Dry run (show what would change without writing)
python tools/map_pathfinder.py fix --all --dry-run
```

## 8) Encyclopedia Web Editors & API

The Ada Encyclopedia (`ada_encyclopedia/`) provides web-based editors and an API layer. Run `npm run dev` (port 3003).

### Visual Map Editors
- **Map Builder** — `localhost:3003/map-builder` — 3-layer editor with AI generation, simulation, export
- **Voxel Editor** — `localhost:3003/voxel-editor` — 3D structural editor with height variation

### Key API Endpoints
- `GET /api/game/context?format=markdown` — Full game context for AI
- `GET /api/ai/capabilities?format=markdown` — Complete tool inventory
- `POST /api/game/generate` — AI map generation (topology, complexity)
- `POST /api/game/analyze` — Map rule validation
- `POST /api/game/simulate` — AI pathfinding simulation
- `GET /api/maps?name=<Name>` — Map data retrieval
- `POST /api/scenes/capture` — Godot scene screenshot via web

### Full Pipeline
See `doc/MAP_EDITING_PIPELINE.md` for the end-to-end flow: Discover → Edit → Validate → Capture → Review → Bridge → Iterate.

## 9) Repo Gotchas (Important)

- `addons/*` is gitignored in this repo. Do not rely on committed changes inside `addons/`.
  - If you must extend addon behavior, prefer a wrapper script under `commons/`.
- The worktree can be dirty. Never revert unrelated user changes.
- Prefer non-destructive commands and explicit audits before broad map edits.

## 10) Handoff Template (for next agent)

When handing off, include:
- objective
- exact files touched
- commands run + outcomes
- validation status
- open risks/blockers
- next 1-3 actions

This avoids context loss between agents and sessions.
