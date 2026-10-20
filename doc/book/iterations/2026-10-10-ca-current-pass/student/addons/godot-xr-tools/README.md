# Godot XR Tools (Vendored)

**Version:** 4.5.1
**Upstream:** [GodotVR/godot-xr-tools](https://github.com/GodotVR/godot-xr-tools)
**License:** MIT

This is a vendored copy of Godot XR Tools, the standard XR interaction toolkit for Godot 4. It provides the VR foundation that Ada Research builds on.

## What Ada Research Uses

| Module | Purpose in this project |
|--------|------------------------|
| `functions/` | Movement (smooth/teleport), pickup, pointer, climb |
| `hands/` | Hand meshes, poses, animations for VR controllers |
| `interactables/` | Grab, poke, snap zone — base classes for our custom interactables |
| `objects/` | Grabbable bodies, highlight rings, virtual keyboard |
| `player/` | XR rig, body tracking, fade effects |
| `staging/` | Scene switching, loading screens |
| `desktop-support/` | Keyboard/mouse fallback when no headset is connected |

## Maintenance Notes

- Do not edit files in this directory — they are upstream code
- To update: replace the folder contents from a new release of godot-xr-tools
- Project customizations live in `commons/` (e.g., custom interactables extend XR Tools base classes)
- See upstream repo for full documentation of each module
