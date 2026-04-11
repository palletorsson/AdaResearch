# Testing — Capture and Validation Scripts

Automated screenshot capture, batch processing, and scene validation tools. Used by the CI-like capture pipeline and developer workflows.

## Capture Scripts (Godot)

Run via `godot_console --path . --xr-mode off --no-window --script <script> -- <args>`.

| Script | Purpose |
|--------|---------|
| `capture_multi_angle.gd` | **Primary** — 4-angle shots for maps or artifacts |
| `capture_all.gd` | Batch capture with manifest-based skip |
| `capture_artifact_shot.gd` | Single artifact screenshot |
| `capture_scene_shot.gd` | Single scene screenshot |
| `capture_tscn_shot.gd` | Screenshot from .tscn path |
| `capture_with_config.gd` | Capture with custom config overrides |
| `capture_manifest.gd` | Manifest tracking for skip-unchanged |
| `batch_capture_inline.gd` | Inline batch capture loop |
| `catalog_batch_screenshot_runner.gd` | Encyclopedia catalog batch |

### Specialized Captures

| Script | Target |
|--------|--------|
| `capture_botanical_flowers.gd` | Flower presets |
| `capture_carpet_gallery.gd` | Carpet/pattern gallery |
| `capture_cove_gallery.gd` | Cove gallery scenes |
| `capture_desktop_vet.gd` | Desktop veterinary check |
| `capture_ecosystem_stages.gd` | Ecosystem growth stages |
| `capture_entrance.gd` | Entrance/lobby |
| `capture_eurorack.gd` | Eurorack audio rack |
| `capture_pattern_compare.gd` | Pattern A/B comparison |
| `capture_rack_2d.gd` / `capture_rack_3d_batch.gd` | Glass rack layouts |

## Validation and Measurement

| Script | Purpose |
|--------|---------|
| `MapTestRunner.gd` | Automated map rule validation |
| `check_aabb_below_ground.gd` | Detects artifacts clipping below floor |
| `measure_artifacts.gd` | Measures artifact bounding boxes |
| `test_auto_ground.gd` | Tests auto-grounding behavior |
| `test_scene_narrator.gd` | Tests TTS narration system |
| `narrate_all.gd` | Batch narration generation |
| `scene_screenshot.gd` | Lightweight scene-to-PNG |

## External Scripts

| Script | Purpose |
|--------|---------|
| `batch_capture_all_scenes.py` | Python orchestrator for full batch |
| `batch_capture_all_scenes.sh` | Shell wrapper |
| `gen_periodic.py` | Generates periodic table test data |

## Output

Screenshots go to `user://multi_shots/<target>/<angle>.png` with `capture_report.json` metadata.
