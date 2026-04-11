# Sphere Droideka

Spherical armored droid — rolls as a compact ball of shell plates, unfolds to tripod stance with shield dome and twin blasters.

## Behavior

Extends `CharacterBody3D`. State machine: **BALL → UNROLL → DEPLOY → AIM → FIRE → RETRACT → ROLL_UP**

- ~8 latitudinal shell bands form the compact ball
- Unfolds to tripod stance with deployable shield
- Fires projectile bursts from twin blasters
- Procedurally generated shell geometry

## Files

| File | Purpose |
|------|---------|
| `sphere_droideka.gd` | Main script — shell generation, state machine, combat |
| `sphere_droideka.tscn` | Scene |

## Signals

- `fired_projectile(position, direction)` — On projectile launch
- `enemy_destroyed` — On destruction
