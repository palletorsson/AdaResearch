# Techstrider

Three-legged procedural walker with animated gait — wanders within a spawn radius.

## Behavior

Extends `Node3D`. Ambient hazard creature.

- 3 legs with phase offsets (120° apart) for stepped gait
- Wanders randomly, choosing new directions periodically
- Body bounces up/down for locomotion realism
- Returns toward spawn point if drifting beyond wander radius

## Files

| File | Purpose |
|------|---------|
| `techstrider.gd` | Main script — gait animation, wandering logic |
| `techstrider.tscn` | Scene |
