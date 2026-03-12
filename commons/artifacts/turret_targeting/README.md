# Turret Targeting

A laser turret that tracks and destroys falling balls, teaching core vector math operations through a kinetic gameplay scenario. The turret uses vector subtraction to find direction, magnitude to check range, normalization to aim, and the dot product to confirm target lock before firing.

## How It Works

A ball dropper spawns colored rigid-body spheres from above with randomized spread and velocity. The laser turret scans for targets by querying all active balls, scoring them by distance and alignment with the last known target direction. Once a target is acquired, the turret head smoothly rotates toward it using lerp_angle on yaw and pitch. When the dot product between the aim direction and the target direction exceeds 0.97 (near-perfect alignment), the turret fires a visible laser beam that applies damage over time. Balls glow and burn as health depletes, then explode with a particle burst on destruction. The turret remembers where targets were last seen and sweeps toward that direction when idle.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `turret_position` | Vector3 | (0, 0, 0) |
| `dropper_offset` | Vector3 | (0, 3, 2) |
| `drop_interval` | float | 2.5 |
| `max_balls` | int | 4 |
| `auto_drop` | bool | true |
| `detection_range` | float | 8.0 |
| `burn_time` | float | 0.3 |
| `laser_color` | Color | (1.0, 0.05, 0.0) |
| `show_stats` | bool | true |
| `show_controls` | bool | true |

## Features

- Full vector math pipeline: subtraction (direction), magnitude (range), normalization (aim), dot product (lock)
- Laser beam with glow, flickering intensity, and impact spark particles
- Ball dropper with object pooling, color cycling, and physics-based falling
- Progressive burn effect on targets with emission ramp-up
- Explosion particle burst on ball destruction
- VR control panel: manual drop, reset, and auto-drop toggle
- Live stats display showing turret status, active balls, and destroy count
- Smart idle scanning toward last known target direction

## Files

- `turret_targeting.gd` -- Main orchestrator script
- `laser_turret.gd` -- Turret tracking, firing, and damage logic
- `ball_dropper.gd` -- Ball pool management and spawning
- `turret_targeting.tscn` -- Main scene file
- `laser_turret.tscn` -- Turret sub-scene
- `ball_dropper.tscn` -- Dropper sub-scene
