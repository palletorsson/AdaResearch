# Head Arena from the game menu

Later update: the same menu button now enters [the biome arena](../2026-10-12-head-arena-biome/index.html). The museum destination below remains an earlier test scene.

Main menu → **Head Arena**. Hold the pointer over the button until its indicator fills. Take the sphere, choose MOVE / TURN / SCALE, then START. The **MAIN MENU** control beside the sphere returns to the same XR staging session.

![The actual menu with Head Arena](../../../../ada_run/encounter_pilot/Head_Arena_Menu/menu.png)

The entry is `commons/hazards/catalyst_counterpart/head_arena.tscn`, using the existing base rig, a compiled museum subclass and `commons/maps/Catalyst_Test_Arena/museum_plan.json`. This avoids the developer launcher's source-reading mechanism and the export-excluded `commons/testing` folder. It mounts the existing arena logic. Main-spine progress is not cleared.

`MainMenu3D.gd/.tscn` adds the menu button; `vrStaging.gd` can now unload a practice scene and reveal its original menu without restarting XR. The arena's report files are isolated under `user://head-arena/`. The shared museum pack-report writer now respects its existing report-path hook; the ordinary museum retains its original destination.

Validation: `python -X utf8 tools/test_catalyst_first_abilities.py --menu --render` runs the actual main scene, selects through pointer dwell, waits for staged reveal, checks the two pickup providers and physical floor, starts/stops the head, checks eight preserved authoring files, then returns through the in-world control. **21/21 runtime assertions passed**, with a native screenshot inspected. No GDScript errors in the final run. Evidence: `ada_run/encounter_pilot/Head_Arena_Menu/arena-report.json` and `arena-stdout.log`.

Limitation: Godot exits with Windows access violation `3221225477` during shutdown, after the assertions. A control run with `--menu-only`, never loading the arena, reproduces the same shutdown failure; see `menu-only.log`. Therefore this is a passing interaction test, not a clean process-exit test. The existing menu also logs unavailable OpenXR when tested without a headset. Quest reach, comfort and actual controller aiming remain untested. No APK was exported or installed.

The current source has the button. Restart the game to load it. An already installed headset build will need a new export.
