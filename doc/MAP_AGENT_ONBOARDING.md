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

### D) Release Gates
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

## 7) Repo Gotchas (Important)

- `addons/*` is gitignored in this repo. Do not rely on committed changes inside `addons/`.
  - If you must extend addon behavior, prefer a wrapper script under `commons/`.
- The worktree can be dirty. Never revert unrelated user changes.
- Prefer non-destructive commands and explicit audits before broad map edits.

## 8) Handoff Template (for next agent)

When handing off, include:
- objective
- exact files touched
- commands run + outcomes
- validation status
- open risks/blockers
- next 1-3 actions

This avoids context loss between agents and sessions.
