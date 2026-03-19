# Tools — CLI Utilities and Automation Scripts

Developer tools for analysis, capture, validation, and AI-assisted workflows. Run from the repo root.

## Key CLI Tools

| Script | Command | Purpose |
|--------|---------|---------|
| `map_pathfinder.py` | `python tools/map_pathfinder.py check <Name> --verbose` | Map reachability and rule validation |
| `spine_map_workbench.py` | `python tools/spine_map_workbench.py status` | Sequence contracts and scaffolding |
| `run_release_gates.py` | `python tools/run_release_gates.py --max-grade-c -1` | Launch-quality gate checks |

## Batch Processing

| Script | Purpose |
|--------|---------|
| `batch_capture_remaining.py` | Capture screenshots for artifacts missing images |
| `batch_shader_capture.py` | Capture shader-based artifacts |
| `enrich_registry_metadata.py` | Fill missing metadata fields in artifact registries |
| `classify_artifacts.py` | Auto-classify artifacts by category |
| `generate_artifact_readmes.py` | Generate README files for artifact folders |
| `generate_audit_report.py` | Produce audit report of project state |
| `add_grid_config_stubs.py` | Add `apply_grid_config()` stubs to algorithms |

## Analysis

| Script | Purpose |
|--------|---------|
| `analyze_gdscript.ps1` | Static analysis of GDScript files |
| `audit_helper.py` | Audit helper for manual review workflows |
| `auto_fix_r4v.py` | Auto-fix common R4V (ready-for-VR) issues |
| `enterprise_quality_fix.py` | Batch quality fixes across algorithms |

## AI Bridge and Automation

| Script | Purpose |
|--------|---------|
| `ai_chat_watcher.ps1` | Watches AI chat for new messages |
| `ai_write_response.ps1` | Writes AI responses to bridge files |
| `auto_ctrl_enter.py` | Auto-submit helper for AI workflows |
| `auto_run.py` | Auto-run script for batch operations |

## Content

| Script | Purpose |
|--------|---------|
| `map_text_writer.py` | Write text content for maps |
| `narration_to_encyclopedia.py` | Export narration text to encyclopedia |
| `pull_quest_logs.ps1` | Pull quest/play logs |
| `sync_captures_to_encyclopedia.ps1` | Sync capture images to encyclopedia public dir |
| `tts_technical.sh` | TTS generation for technical narration |

## Godot Scripts

| Script | Purpose |
|--------|---------|
| `VRBrush.gd/.tscn` | VR painting/brush tool |
| `FixBooleansVariants.gd` | Fix boolean variant issues in scenes |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `ada/` | Ada Navigator CLI (`ada.py overview`) and utilities |
| `audio/` | Audio export and audit tools |
| `claude_bridge/` | HTTP bridge between Godot and Claude Code |
| `grid_editor/` | Glass rack grid editor (desktop GUI) |
| `ai_bridge/` | Inter-agent communication protocol and state |
