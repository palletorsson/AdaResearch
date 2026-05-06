# Hull Crusher

Morphing convex polyhedron with orbiting point-nodes that define its hull — fires points as projectiles.

## Behavior

Extends `HazardCreatureBase`. 90 HP. Teaches convex hull geometry.

- ~10 yellow spheres orbit on Lissajous curves (orbit radius 0.6)
- Central hull mesh scales to approximate the AABB of orbiting points
- During CHASE: fires points as projectiles toward player (speed 6.0, damage 12.0)
- Fired points shrink the hull; respawn after 4.0s delay

## Files

| File | Purpose |
|------|---------|
| `hull_crusher.gd` | Main script — Lissajous orbits, hull morphing, projectile firing |
| `hull_crusher.tscn` | Scene |

## Key Parameters

| Parameter | Value |
|-----------|-------|
| `num_points` | 10 |
| `orbit_radius` | 0.6 |
| `fire_interval` | 2.0s |
| `point_respawn_time` | 4.0s |
| `projectile_speed` | 6.0 |
| `projectile_damage` | 12.0 |
