# Falling Blocks

Spawns falling cubes from height that deal damage on player contact.

## Behavior

Extends `Node3D`. Simple environmental hazard.

- Spawns `reset_cube` prefabs at spawn_height (12.0)
- Cubes fall under gravity (35.0) and deal 20.0 damage on hit
- Hit cubes teleport back to spawn height
- Max 1 active cube, respawn interval 1.0–2.5s random
- Configurable rotation randomization and teleport-on-hit behavior

## Files

| File | Purpose |
|------|---------|
| `fallingblocks.gd` | Main script — spawning, gravity, collision |
| `fallingblocks.tscn` | Scene |
