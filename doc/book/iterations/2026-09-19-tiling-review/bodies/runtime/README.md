# Ribbon probe evidence

These scripts are copies of existing probes under `commons/testing/`, whose originals remain unchanged. `probe-adaptations.diff` records every adaptation. All output/control/recipe/appearance paths are redirected into this folder. The three hall probes override the inherited capture helper to save here with its twenty-frame settling period. Initial camera positions were retained; visual inspection then found two outdated viewpoints after the compact hall layout. The context image is moved from +8 m to +4.5 m with 90° FOV, ahead of the neighbouring sphere exhibit. Runway views use interior x=-5 m, replacing x=+9 m outside the compact east wall. First-run evidence is retained under `initial-viewpoints/`. Captures compare controls in an unchanged artifact implementation; they are not before/after change images.

Six additional assertions make the received review's questions explicit: moving the visible slice leaves all 64 values unchanged and supports undo (three assertions); the context targets/connector are actually unshaded and the plane spans four by two metres (two assertions); sending a pointer event to the actual runway SWAP LOOKS button changes silhouettes while preserving all four saved recipes (one assertion). The existing standalone runway probe also checks 120 simulated seconds, passing separation, yielding to a synthetic camera position, resumption, pose/walk and pointer controls. It runs headless without images.

Run from the repository root:

```powershell
python doc/book/iterations/2026-09-19-tiling-review/bodies/runtime/run_probe.py layer_pattern
python doc/book/iterations/2026-09-19-tiling-review/bodies/runtime/run_probe.py carrier_comparison
python doc/book/iterations/2026-09-19-tiling-review/bodies/runtime/run_probe.py fabric_studio
python doc/book/iterations/2026-09-19-tiling-review/bodies/runtime/run_probe.py drag_catwalk
```

The runner uses the known Godot 4.6 binary, explicit workspace log files, XR off and dummy audio. Rendered runs use Vulkan/mobile, 1600×1000, CREATE_NO_WINDOW and hidden startup information; only the standalone behavior probe uses `--headless`. Each `*.run.json` records exact arguments, exit status, probe SHA256, before/after fingerprints and whether tracked sources changed during execution. The shared museum implementation is retained, including the root task's separate compile repair; these tests do not replace shared source files.

`*.process.log` contains complete process output; `*.godot.log` is Godot's explicit log. `probe_*.json` contains the hall assertions. Pointer events are programmatically sent through XRToolsPointerEvent. This is desktop execution, not headset or tracked-controller testing, and it cannot establish human perception or learning.
