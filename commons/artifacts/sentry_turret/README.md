# Sentry Turret

An autonomous tracking turret that detects and engages targets (player or balls) using raycasting and scene queries. Teaches concepts of target acquisition, projectile/laser systems, and object pooling for real-time VFX.

## How It Works

The turret scans for the closest valid target within its detection range by querying scene groups for the player camera and ball objects. Once a target is acquired, the head rotates via `lerp_angle` to track the target's position in local space, computing yaw and pitch independently. In laser mode, continuous damage is applied per-frame with a burn visual effect; in bullet mode, projectiles are spawned from a MultiMesh object pool and travel toward the target with Bresenham-style hit detection. Explosion effects (flash, ring, sparks, light) use pooled MultiMesh instances and tweens for zero-allocation VFX.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `rotation_speed` | float | 5.0 |
| `detection_range` | float | 15.0 |
| `fire_rate` | float | 3.0 |
| `bullet_speed` | float | 20.0 |
| `reload_time` | float | 2.0 |
| `burst_size` | int | 5 |
| `target_player` | bool | true |
| `target_balls` | bool | true |
| `use_laser_damage` | bool | true |
| `laser_damage_per_second` | float | 100.0 |
| `turret_color` | Color | (0.5, 0.5, 0.55) |
| `laser_color` | Color | (1.0, 0.1, 0.0) |

## Features

- Dual fire modes: continuous laser beam or burst-fire projectiles
- MultiMesh object pools for bullets and hit-flash effects (zero per-frame allocation)
- Full explosion VFX: flash sphere, expanding torus ring, spark burst, omni light
- Configurable target mode via map syntax: `sentry_turret#target:player/balls/all`
- Strain-based burn visual on damaged targets with health tracking

## Files

- `sentry_turret.gd` -- Main script
- `sentry_turret.tscn` -- Scene file
