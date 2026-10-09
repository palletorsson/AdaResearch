# Grab, move, let go: the physical joystick family

21 September 2026. Three existing scenes now share a compact physical face, printed release rule, flat live angle readout and real pointer input. Their existing scene paths and the child `JoystickOrigin/InteractableJoystick` remain available to consumers.

## What was repaired

- The smooth scene's visible grip was 5 cm beyond its grab proxy. Its left/right redirect nodes also targeted missing grab points. Grip and target now coincide, and both hand-pose targets resolve.
- All three scenes now align the shaft mesh and cylinder collider with the stick's forward axis. Previously the smooth scene offset the shaft again, while the other two left the cylinder upright across it.
- `joystick_zero.tscn` contained an unused `default_position` property and never enabled `default_on_release`. It now explicitly returns to the native default angles `(0,0)` on real handle release. Pointer release, exit or loss applies the same return rule.
- The existing snap interval is preserved: **5 degrees per step**, not five selectable positions. Smooth and snapped joysticks retain their values when released.
- Flat readouts show both signed angles. The backing face is 20 by 26 cm; the comparison places three unscaled units 27 cm apart on an 86 cm wide inclined case. These are measured layout choices, not universal reach claims.

`physical_joystick.gd` supplies the printing, live reading and pointer ownership. The face, shaft and handle forward their own hit events through small project-local bridges. A second pointer cannot steal a held control; physical pickup cancels a pointer drag. Processing is enabled only while input is active, and the value texture refreshes only when its formatted text changes.

`joystick_driver.gd` extends the native XR Tools joystick without editing the addon. It resolves a held proxy in the joystick's rest frame, then uses the native movement, clamping, detents and release logic. Keeping the held proxy's world position stable prevents the moving parent from applying the same movement repeatedly. The established child API remains radians into `move_joystick`, degrees out through `joystick_moved`. The new root helpers explicitly use degrees: `get_angles_degrees()` and `set_angles_degrees(Vector2)`.

## Where it is integrated

The three existing joystick scene paths are changed, so their consumers receive the repaired components on reload. Identified source consumers include `ControlPanel`, the default interactable sampler, `gadget_wall`, the VR component demo and `UniversalVRAudioController`. These are dependency findings, not claims that every assembled placement was tested.

`commons/interactables/interactable_joystick_demo.tscn` is a focused configuration of the existing `InteractableDemo.gd` (`joystick_reference=true`). Each joystick moves an orange point on a board behind the station. The reference shows settings: the return control recentres its point. A velocity-command receiver would be a different example and must not silently reuse that interpretation.

The new reference also declares `exhibit_control_parts()` for future mounting through the existing adapter. It is currently a focused demo, not a new hall placement or an automatically registered museum artifact. The comparison's supports and case are rendered furniture, without full locomotion collision.

## Evidence

- Preserved-source baseline: 6 checks, with 2 expected failures (smooth grip offset and zero scene's missing return setting). The after demo uses the same scene family and comparison shell; before/after control close-ups share the same camera. The comparison shell is new in both captures, so the before image is a reconstruction with the original controls, not a historical hall photograph.
- 97 focused checks pass: actual XR Tools pickup, grab-driver movement and release, local pointer directions, real collider ray hits, degree quantization and limits, stable held positions, both hand-pose references, geometry alignment, readout/receiver agreement, idle processing, rotation, competing pointers and pointer-loss recovery.
- 46 existing mixed-console checks pass in Braun and Black Mesa variants, including the joystick's signed signal mapping, specimen movement and the physical reset button. Their interface screenshots were inspected for layout regression.
- The final successful focused and regression logs contain no GDScript errors. The pre-existing unresolved UID message remains.

Captures use desktop Godot 4.6 Mobile. Synthetic grabbers exercise the real pickup path; they do not establish tracked-hand comfort. Quest performance, hand-pose fit, seated and shorter visitors, tiny-label legibility and every dependent hall remain untested. The test suite uses unit world scale with an inclined station and yaw rotations 0 and 90 degrees. Do not scale physics controls to fit a panel; use the earlier station-mounting boundary where an exhibit is resized.

## Reproduce

```powershell
python doc/reports/interfaces-2026-09-21/joystick-console/run.py before
python doc/reports/interfaces-2026-09-21/joystick-console/run.py after
python doc/reports/interfaces-2026-09-21/joystick-console/run_regression.py
python doc/reports/interfaces-2026-09-21/joystick-console/publish_review.py
```

The source snapshots in `before/` preserve this pass's starting point. `update_scenes.py` records the one-time migration; do not rerun it on already migrated scenes.

Next: use this physical two-axis vocabulary in an actual spatial encounter and inspect its operating position. Keep the distinction between setting a position and commanding a movement explicit.
