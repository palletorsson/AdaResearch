# Collision Crasher

Central body with 5 orbiting tethered blocks demonstrating elastic collision physics.

## Behavior

Extends `HazardCreatureBase`. 85 HP.

- 5 colored BoxMesh blocks orbit on spring tethers (tether_k 15.0, damping 0.5)
- Elastic collisions conserve momentum between blocks
- Impulse arrows visualize collision forces on player contact
- Tether radius increases during CHASE state
- Block damage: 10.0 per hit

## Files

| File | Purpose |
|------|---------|
| `collision_crasher.gd` | Main script — spring physics, collision math, impulse visualization |
| `collision_crasher.tscn` | Scene |

## Key State

- `_blocks` array: mesh, position, velocity, mass, color per block
- `_total_ke` / `_total_momentum`: conserved quantities for physics validation
