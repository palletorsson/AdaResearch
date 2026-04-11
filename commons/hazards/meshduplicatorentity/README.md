# Mesh Duplicator Entity

Chaos entity that scans and duplicates scene meshes, creating visual disorder.

## Behavior

Extends `Node3D`. Glitch/chaos hazard.

- Scans for mesh instances within radius
- Duplicates them with random offsets, scale variations, and rotation
- Optional glitch materials applied to duplicates
- Manages a duplication pool with lifecycle tracking
- Chaos level increases with more duplicates

## Files

| File | Purpose |
|------|---------|
| `meshduplicatorentity.gd` | Main script — scanning, duplication, glitch effects |

## Signals

- `mesh_found(mesh_instance)` — On scan detection
- `mesh_duplicated(original, duplicate)` — On duplication
- `chaos_level_increased(level)` — On escalation
- `entity_overloaded()` — On max capacity
