# HL Turret Vectors

A Half-Life-inspired sentry turret that demonstrates all core vector operations in a single interactive artifact. The turret tracks and shoots at a bouncing ball target, with each vector operation (subtraction, magnitude, normalization, dot product, cross product, projection, addition, scalar multiplication) visualized in real time.

## How It Works

The turret continuously computes vector math to track a physics-driven ball target. Direction to the target is found via vector subtraction, range is checked using magnitude, the aim direction is normalized, a dot product determines if the target is within the field of view, and a cross product finds the rotation axis for aiming. Projected ground positions, laser endpoints via vector addition, and bullet velocities via scalar multiplication are all rendered as colored arrows, lines, and arcs. VR sliders control field of view, fire rate, and bullet speed.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `turret_height` | float | 0.4 |
| `barrel_length` | float | 0.25 |
| `field_of_view_degrees` | float | 90.0 |
| `max_range` | float | 2.5 |
| `tracking_speed` | float | 2.0 |
| `shooting_enabled` | bool | true |
| `fire_rate` | float | 3.0 |
| `bullet_speed` | float | 4.0 |
| `bullet_lifetime` | float | 2.0 |
| `show_bullet_vectors` | bool | true |
| `ball_color` | Color | (0.2, 0.8, 1.0) |
| `ball_bounce` | float | 0.8 |
| `ball_radius` | float | 0.08 |

## Features

- All nine core vector operations visualized simultaneously
- Physics-driven ball target with gravity and bounce
- VR-enabled: grab the ball, adjust sliders for FOV, fire rate, and bullet speed
- Colored vector arrows with labeled panels for each operation
- Muzzle flash and spark hit effects
- Field of view cone and range circle overlays
- Lead-target prediction using velocity integration

## Files

- `hl_turret_vectors.gd` -- Main script
- `hl_turret_vectors.tscn` -- Scene file
