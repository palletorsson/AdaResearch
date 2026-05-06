# Tentacle Cube

Dormant machine cube that unfolds mechanical tentacles when the player approaches.

## Behavior

Extends `CharacterBody3D`. State machine: **DORMANT → UNFOLDING → ACTIVE → RETRACTING**

- Stationary cube body with 4 tentacles (4 segments each)
- Tentacles fold flat against cube surface when dormant
- Unfolds and tracks player with IK when active
- Tentacle strikes deal damage on contact

## Files

| File | Purpose |
|------|---------|
| `tentacle_cube.gd` | Main script — fold/unfold, IK tracking, strikes |
| `tentacle_cube.tscn` | Scene |

## Signals

- `enemy_destroyed` — On destruction
- `tentacle_strike(position)` — On tentacle hit
