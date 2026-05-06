# Bug: "Script inherits from native type 'RigidBody3D', so it can't be assigned to an object of type: 'Node'"

## The Error
```
Script inherits from native type 'RigidBody3D', so it can't be assigned to an object of type: 'Node'
res://addons/godot-xr-tools/interactables/interactable_handle.gd
```

## When It Happens
- Only in VR mode (with OpenXR headset connected)
- When loading certain artifacts into a map via the grid system
- Specifically when any scene that references `interactable_handle.gd` gets instantiated

## Root Cause (Partially Fixed)
The `interactable_handle.gd` script extends `XRToolsPickable` which extends `RigidBody3D`. When Godot can't compile the script (UID mismatch or dependency failure), it creates a fallback `Node` instead of `RigidBody3D`, then fails to assign the script.

**UID mismatch was fixed** — 8 scene files had wrong UID `uid://b7ersbm6j30qg` instead of correct `uid://dlojnwxo25bky`. This is committed.

**But the error persists in VR.** It does NOT happen in `--xr-mode off` desktop mode.

## What We Tried
1. Fixed UID mismatch in 8 `.tscn` files ✓
2. Changed `preload()` to `load()` in `UniversalVRAudioController.gd` ✓
3. Made `EurorackModule.gd` skip all 3D control spawning ✓
4. Made `InteractableDemo.gd` fully procedural (zero scene loading) ✓
5. Stripped `interactable_demo.tscn` to bare Node3D ✓
6. None of these fully resolve the VR-mode error

## Files Involved
- `addons/godot-xr-tools/interactables/interactable_handle.gd` — the script that fails
- `addons/godot-xr-tools/objects/pickable.gd` — parent class (extends RigidBody3D)
- `commons/interactables/slider_smooth.tscn` — uses interactable_handle.gd
- `commons/interactables/slider_horizontal.tscn` — uses interactable_handle.gd
- `commons/interactables/dial_smooth.tscn` — uses interactable_handle.gd
- `commons/interactables/wheel_smooth.tscn` — uses interactable_handle.gd
- `commons/interactables/slider_plane.tscn` — uses interactable_handle.gd
- `commons/interactables/slider_time.tscn` — uses interactable_handle.gd
- `commons/audio/interfaces/VRAudioControlDial.tscn` — uses interactable_handle.gd
- `commons/audio/interfaces/VRAudioControlSlider.tscn` — uses interactable_handle.gd
- `commons/audio/interfaces/VRAudioControlSliderVertical.tscn` — uses interactable_handle.gd

## Hypothesis
Godot 4.6 may be scanning ALL `.tscn` files in the project at startup (or when a scene references a directory). Even though our code doesn't `load()` or `preload()` these scenes, Godot's resource scanner parses them and tries to compile the scripts. In VR mode, something about the XR initialization order causes `interactable_handle.gd` to fail compilation, creating a Node fallback.

## Possible Fixes to Try
1. Check if any `.tscn` file in the project still has the wrong UID for interactable_handle.gd
2. Check if the XRTools addon has a known issue with Godot 4.6 script compilation order
3. Check if `interactable_handle.gd` has `@tool` annotation that causes it to run in editor/export contexts where XR isn't ready
4. Try removing `@tool` from `interactable_handle.gd` if present
5. Check if the error is actually non-fatal (controls still work despite the warning)

## Project Info
- Godot 4.6 stable
- XRTools addon (godot-xr-tools)
- Quest 3 VR headset via OpenXR
- Windows 11, RTX 3070
