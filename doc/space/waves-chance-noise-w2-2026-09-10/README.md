# Waves, Randomness and Noise — batch W2 archive (2026-09-10)

Fable 5.1, working from item 5 of `doc/book/handoffs/fable-wcn-runtime-followup.md`. One hall: **WaveFunctions_Effect_Sound**.

## What is here

- `before/` — byte copies of every file changed, taken before the first edit: `DualBallFMController.gd` (recovered from HEAD; the eleven patch anchors all matched the HEAD text, so the working copy carried no earlier change in those regions), `DualBallFMController.tscn` (unchanged in the end), `MelodyChaser3D.gd`, `commons/audio/UniversalVRAudioController.gd`, the map and its ten texts.
- `before_sha256.txt` / `after_sha256.txt` — hashes of those files before and after, the after list adding the new field notes, the probe and its port, and the two tools.

## Structure

No structure or utility cell was moved. The map keeps the recovery contract of `doc/space/wave-platform-recovery-2026-09-10/` (interior `2` = 1 m platform, perimeter `w`, `museum.wall_height` 3, `gate_depth_rows` 0). Added under `map_info.museum`: `sculpture_clear_rects` [[6,9,11,13]] and `artifact_placement: "map"`.

## Placement

`DualBallFMController` (4,5) → `DualBallFMController:180#stand:desks#evidence:longhand` (8,11). Nothing else moved.

## Reversal

Copy the `before/` files back over their originals; delete `field_notes.md`, the probe and its port, the report and the W2 batch file; remove the `effect` line from `tools/run_wcn_probe.sh` and `effect_sound` from `tools/port_wcn_probes_live.py`.

## Runtime

Not run at the time of the archive: a Godot editor (PID 40320) and its play instance held the project. `bash tools/run_wcn_probe.sh effect` and `… effect live` are the runs owed.

## Completion, 2026-09-11

Both lanes ran with Godot free (bare 89 / 0, live 94 / 0). Three runtime fixes followed the first attempt — the readout lowered to 1.30 m and the scope raised (the plate hid the lanes), the decoration cube (7,4) → (11,7) with four plinth-free rectangles (the museum's walk was severed under map placement), and `timbre_sculptor#sound:near` (a continuous hum 3.3 m from the desks; `before/commons/artifacts/timbre_sculptor/timbre_sculptor.gd` is its pre-edit copy) — plus `root.add_child` in every SceneTree probe and the guard stop in the capture block. `after_sha256.txt` is refreshed to the files as returned. Account: `ada_run/waves_chance_noise/2026-09-11-w2-completion.md`.
