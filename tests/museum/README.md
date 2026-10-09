# Museum encounter tests

Run from the AdaResearch repository root:

```powershell
python -X utf8 tests/museum/run.py
```

This suite covers the recent Point One and Point Lines work, including the shared snap-point release behavior. It does not certify the whole museum.

The runner discovers Godot from `--godot`, `GODOT_EXE`, the command path, or the current Windows desktop installation. For another computer:

```powershell
python -X utf8 tests/museum/run.py --godot "D:/Tools/Godot.exe"
```

Useful options:

```powershell
python -X utf8 tests/museum/run.py --list
python -X utf8 tests/museum/run.py --only point-one
python -X utf8 tests/museum/run.py --only point-lines
python -X utf8 tests/museum/run.py --only snap-point-release
python -X utf8 tests/museum/run.py --only trace-ball-ramp
python -X utf8 tests/museum/run.py --static-only
```

Only the Python standard library is required by the runner. Godot cases load the real project scenes and scripts. They run in separate, hidden, headless processes. The suite does not restart the editor, browser server or existing game. It writes test output, not map data or prose. Godot still loads the project's autoloads and may produce its usual cache/log side effects.

## What is checked

| Case | Authored data and text | Isolated Godot behavior |
|---|---|---|
| Point One | Matching point ID and both readout channels; no frame-owned point; paired WORLD/LOCAL cards; primary anchors; secondary encounters; origin order; open partition cells | Uses the authored instrument configs: named target beats a nearer distractor; labelled world/local reporting; channel isolation; pickup-style reparenting; no confinement; moving/rotating/scaling the reference; target removal and reacquisition |
| Point Lines | Glass basin, no fire; marking over a zero cell; black paint; player trace placement, primary role and book anchor | Basin detection and border exclusion; active desktop walker; sample accumulation and lateral deviation; geometry generation; headset projection to rig floor |
| Snap-point release | Reuses Point Lines authored checks | Real pickup/release methods with a synthetic hand: entering and leaving range, changing targets, preview/drop-only modes, duplicate prevention, puzzle scoping and target removal |
| Triangle SHIFT START | Both primary encounters placed with discovery controls; book anchor order | Real timed drawing, pickup/release and pointer buttons; emitted L fan geometry, immutable points/boundary, cyclic restoration, earlier-loop isolation, count/visibility preservation, unfinished-outline and held-tool guards, manual retracing and 3/4/5-corner loops |
| Trace ball ramp | Registry scene and placement in Point Trace | Gravity on the actual ramp, fresh stand supply after release, occupied-stand delay, retained balls, independent traces, old-ball reuse, ball collision and escaped-body retention |

The runtime probes simulate inputs directly. They do not exercise actual controller buttons, full-hall collision geometry or final camera composition. `suite.json` lists the remaining manual checks, and every report repeats them as **not run**. In particular, inspect the marking's actual height over the glass: an authored offset by itself does not establish rendered alignment.

## Reports and failure handling

Every invocation creates a unique folder under `ada_run/test-results/museum/` containing:

- `report.md`: readable result and manual checks.
- `report.json`: structured result.
- Per-case Python logs, Godot console/engine logs and assertion reports.

Exit code **0** means all requested automated checks passed. Exit code **1** means failure. `--static-only` reports **partial** and explicitly skips Godot; it is not evidence of a complete pass.

A Godot case fails for a nonzero exit, timeout, missing/malformed report, insufficient assertions, reported assertion failure, script error or unexpected engine error. Two known project-startup errors (the existing `rwex60pqapc` UID and Windows certificate-store message) are retained in `engine_notices` without failing otherwise successful behavior checks. Do not expand that exception list merely to get green results.

The default timeout is 90 seconds per scene. The runner terminates only its own timed-out child process. Unique report paths prevent results from an earlier run being reused as current evidence.

## Adding a case

1. Write a bounded Python `unittest.TestCase` in this folder for authored contracts, if relevant.
2. Add an isolated Godot scene and probe. Load the actual production implementation; avoid copying its algorithm into the test.
3. Accept `--report=<absolute path>` through `OS.get_cmdline_user_args()`.
4. Always write JSON with an integer `checks` and a `failures` array. Exit nonzero on any failure or if the report cannot be written.
5. Register a unique ID, Python class, scene path, minimum assertion count and manual checks in `suite.json`.
6. Run the new case, then the complete suite after changing shared implementation.

Existing probes demonstrate the report contract:

- `ada_run/shared_point_check.gd`
- `ada_run/point_lines_basin_trace_check.gd`
- `tests/museum/snap_release_check.gd`

Prefer behavioral assertions: “the readout still tracks this point after reparenting” is stronger than checking that a variable has a particular name. Never weaken an expected result simply because the current implementation fails it. If an artistic or pedagogical requirement is uncertain, report it for review.

## Assignment to Claude

Extend this suite with full-museum verification of Point One and Point Lines. First run the existing command and retain its report. Test the opened partition, shared-point readout, glass-basin support, black marking alignment and player-trace visibility while moving between halls. Use the actual museum assembly for spatial tests. Record screenshots and camera positions for visual findings; test headroom and crossing with the actual player collider where possible.

Fix clear implementation faults within those encounters, and add a failing regression test before the fix where practical. Preserve unrelated changes and existing artifact placements. Do not rewrite book prose, change the sequence, remove artifacts or alter intended assertions without an explicit decision from Palle. Keep manual or unavailable checks marked not run.

Return: the run command, report path, screenshots, reproducible failures, files changed and remaining uncertainties. These results are evidence for review, not automatic approval of the patch.
