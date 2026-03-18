# Block Builder Entity

Antimatter "grey goo" entity that consumes nearby geometry and builds a cage of colored octahedron blocks around the player.

## Behavior

- Detects and consumes mesh instances within range (detection range 20.0)
- Tracks a `vertex_budget` that decays via damage
- Builds a hive of blocks in concentric layers around the player (2 layers, spacing 1.5)
- Blocks have a 45-second lifetime
- Movement speed 3.5
- Thought label displays current behavior state

## Files

| File | Purpose |
|------|---------|
| `blockbuilderentity.gd` | Main CharacterBody3D script |
| `blockbuilderentity.tscn` | Scene |

## Key Methods

- `_collect_mesh_instances()` — Scans scene for consumable geometry
- `_refresh_geometry_candidates()` — Updates consumption target list
