# XR Tools Changes

This file tracks local modifications to `godot-xr-tools` used by this project.

Use it when addon code is ignored or replaced upstream so critical fixes are not lost.

## Change Log

### 2026-02-12
- File: `addons/godot-xr-tools/objects/pickable.gd`
- Scope: `controller_action()` and `controller_action_release()`
- Change: added early return when `_grab_driver` is null.
- Reason: prevent runtime error when a custom pickable rejects normal grab setup but action input still routes through pickup controller.
- Error observed: `Invalid access to property or key 'primary' on a base object of type 'Nil'`.
- Local context: triggered while using `res://commons/primitives/cubes/subdivision_cube.tscn` in `res://commons/maps/Fractals_2/`.
- Upstream status: TODO (open issue/PR in `godot-xr-tools`).

## Template For Future Entries

### YYYY-MM-DD
- File: `addons/godot-xr-tools/...`
- Scope:
- Change:
- Reason:
- Error/trace:
- Upstream status:
