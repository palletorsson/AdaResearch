# Desktop game-menu verification — 18 October 2026

Open `index.html` for native captures and results. Generate it with `python publish.py` after `python tools/test_game_menu.py` from the repository root.

## Verified

92 navigation assertions passed across eight routes: Void, Museum Runner, Shadow Game, Biome Ladder, Head Arena, New Game, Sequences → Transformation, Maps → AdvancedLaboratory_Lab_Equipment_Simulation. Real `vr_staging.tscn`, real autoloads, mouse events through the menu's physics ray and embedded viewport; no direct invocation of entry callbacks. Return uses each scene's return function or staging API, followed by another mouse click into Void. No headset/Android export was tested.

Separate app name/user data protects the user's progression. The fixture creates directory junctions under ignored `ada_run/menu-integration-test/`; do not recursively delete through those junctions. Sources are shared, not copied into another implementation. Rendering: Godot 4.6 stable, Forward+, RTX 3070.

## Changes

- `commons/scenes/main_menu/desktop_menu_pointer.gd`: mouse hover/click, larger desktop hit targets, embedded-panel events and wheel, skip invisible collision bodies, disable untracked controller pointers.
- `MainMenu3D.gd`: add desktop pointer when XR is not initialized.
- `components/MenuButton3D.gd`: optional dwell argument; original VR default retained, mouse hover does not dwell-click.
- `commons/scenes/start_xr.gd`, `vr_staging.tscn`: explicit `--desktop` user argument skips XR startup. Run with engine flag `--xr-mode off` as well. Godot consumes its engine flag before GDScript sees arguments.
- `commons/managers/AdaSceneManager.gd`: staging listeners accept null game data after Maps. Previously Maps → menu → Void emitted two Dictionary conversion errors.
- `tools/test_game_menu.py`, `tools/probes/game_menu_route.gd`: reproducible route test, screenshots, assertions and exit-status recording.

## Still failing

Every full staging test exits with Windows status 3221225477 / 0xC0000005 after shutdown material-null/resource-leak messages. The harness correctly exits nonzero; `run.json` separates `navigation_passed` from `shutdown_clean`. No other engine errors remain in the final eight-route run.

Diagnostics: autoload-only `boot` run exits 0 with no engine errors. `menu_warm` (staging/menu without entering a destination) reproduces the crash. Disabling background preloads in `menu_cold` did not remove it. Attempted removal of CSG shapes in `menu_no_csg` did not remove it. Cause is not established. Do not report all tests as passing or attribute this to Void. `menu_no_csg.log` contains verbose resource-leak details.

Visual observations: New Game reaches Point Zero but the initial forward view is obscured by a red-and-white striped surface, even after a five-second settle. Transformation arrives in the right chapter but looks bright. These are recorded in the report, not disguised by moving the camera. Arrival movement, exposure and room layout need a separate check before claiming a complete playthrough.

The final run's screenshots and aggregate `run.json` are the evidence; per-route JSON files contain navigation assertions only. Images remain local review evidence, excluded from Git by repository policy.
