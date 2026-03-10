# Map Editing Pipeline

End-to-end workflow for creating and iterating on maps, from discovery to VR-verified completion.

## Overview

```
DISCOVER → EDIT → VALIDATE → CAPTURE → REVIEW → BRIDGE → ITERATE
```

This pipeline connects CLI tools, web editors, Godot capture scripts, VR testing, and AI feedback into a single loop. Each step has multiple tool options — use whichever fits the task.

---

## Step 1: Discover

**Goal:** Understand current project state, what needs building, where there are gaps.

```powershell
# Project status and recommendations
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode status
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode recommend

# Sequence/map overview
python tools/ada/ada.py overview
python tools/ada/ada.py spine

# Specific sequence or map context
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode sequence -Name <seq>
python tools/ada/ada.py seq <sequence_name>
python tools/ada/ada.py map <map_name>
```

**Encyclopedia API:**
- `GET /api/game/context?format=markdown` — Full game context for AI
- `GET /api/stats` — Project-wide statistics
- `GET /api/ai/capabilities?format=markdown` — Tool inventory

---

## Step 2: Edit

**Goal:** Create or modify map layout.

### Option A: Web Map Builder (visual)

Run encyclopedia dev server (`npm run dev` in `ada_encyclopedia/`, port 3003), then open:

- **`localhost:3003/map-builder`** — 3-layer editor with:
  - Structure layer: floors, walls, void, heights
  - Utilities layer: spawn, teleporter, ramps, transport cubes
  - Interactables layer: artifact placement
  - AI generation: topology-aware (corridor, hub-spoke, maze, bridged-islands, etc.)
  - Simulation: AI pathfinding playthrough
  - Analysis: rule validation
  - Export: JSON for `map_data.json`

- **`localhost:3003/voxel-editor`** — 3D structural editing for height-based maps

### Option B: Direct JSON Edit

Edit `commons/maps/{MapName}/map_data.json` directly. See `doc/MAP_AGENT_ONBOARDING.md` section 7 for map construction rules.

### Option C: AI Generation

```
POST /api/game/generate
Body: { topology, artifactTokens, complexity, dimensions, ... }
```

---

## Step 3: Validate

**Goal:** Check map construction rules before visual testing.

```powershell
# Full rule check with ASCII visualization
python tools/map_pathfinder.py check <MapName> --verbose

# Check all curriculum maps
python tools/map_pathfinder.py check --all

# Show walkability map
python tools/map_pathfinder.py show <MapName>

# Find path from spawn to artifact/teleport
python tools/map_pathfinder.py path <MapName> --to <artifact_or_teleport>
```

**Rules checked:**
1. Spawn exists and is reachable
2. Teleport has +1 row of floor behind it in +z
3. Teleport is reachable from spawn
4. All artifacts are reachable (walking, ramps, transport cubes)
5. Teleport stands on y=0 (void)
6. Only one teleport per map

**Encyclopedia API:**
- `POST /api/game/analyze` — Rule validation
- `POST /api/game/validate` — Construction checks

---

## Step 4: Capture

**Goal:** Take screenshots for visual review.

```powershell
# Multi-angle map capture (above, front, left, right)
godot_console --path . --xr-mode off --no-window --script res://commons/testing/capture_multi_angle.gd -- --mode=map --target=<MAP_NAME>

# Multi-angle artifact capture (front, left, right, top)
godot_console --path . --xr-mode off --no-window --script res://commons/testing/capture_multi_angle.gd -- --mode=artifact --target=<lookup_name>

# Full batch with skip-unchanged (for entire sequences)
godot_console --path . --xr-mode off --no-window --script res://commons/testing/capture_all.gd -- --outdir=user://capture_output --sequence=<seq> --skip-unchanged
```

**Output:** `user://multi_shots/<target>/<angle>.png` + `capture_report.json`

**Encyclopedia API:**
- `POST /api/scenes/capture` — Capture via web API

---

## Step 5: Review

**Goal:** Check visual quality, run AI simulation, optionally test in VR.

**Screenshots:** View in `user://multi_shots/<target>/` folder.

**AI Simulation:**
```
POST /api/game/simulate
Body: { mapName, ... }
```
Returns: pathfinding trace, artifact collection order, estimated difficulty.

**Desktop Testing:**
Run `commons/scenes/desktop_map_tester.tscn` in Godot editor for WASD walkthrough.

**VR Testing:**
Load any map with the VR headset. Use the overlay panel to leave feedback (see Step 6).

---

## Step 6: Bridge (VR ↔ AI Feedback)

**Goal:** Collect iteration feedback from VR sessions.

### How it works

1. **In VR:** The `DesktopMapSwitcherOverlay` has a comment panel. User types feedback and clicks save.
2. **Godot writes to:**
   - `ada_run/desktop_feedback.md` — Timestamped markdown entries
   - `ada_run/desktop_feedback.json` — Structured JSON
   - `ada_run/codex_change_requests.md` — Queued change requests for AI
3. **AI reads:** The `/ada-bridge-listener` skill polls `desktop_feedback.md` for new entries. Or read the file directly.

### Entry format (markdown)

```markdown
## 2026-02-20T10:25:06 | Map_Name
- Sequence: `sequence_name`
- Map: `map_name`
- Interactables: `artifact1`, `artifact2`
- Artifact Paths:
  - `artifact1`: `res://path/to/artifact.tscn`

[User comment text]

---
```

---

## Step 7: Iterate

**Goal:** Apply feedback and return to Step 2.

```powershell
# Auto-fix common rule violations (dry run first)
python tools/map_pathfinder.py fix --all --dry-run
python tools/map_pathfinder.py fix --all

# AI-driven refinement
POST /api/game/refine
```

### Done Criteria (from MAP_AGENT_ONBOARDING.md)

A map task is done when:
- Map edits are implemented and saved
- Validation completed (CLI or ContentValidator)
- Runtime smoke check completed (interactive or scripted)
- Evidence captured when requested (screenshots)
- Handoff summary includes: files changed, commands run, known risks, next actions
