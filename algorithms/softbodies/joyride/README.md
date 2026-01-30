# Joyride

Soft body carnival ride simulation — deformable objects spinning on a carousel with obstacles.

## QFEP Connection

Soft bodies are **form meeting force**. The ride imposes circular motion (F, constraint); the soft bodies deform under centrifugal force (E, response). Obstacles add collision — more constraints, more deformation. λ as physics: structure yielding to stress.

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `ride_radius` | 3.0 | Carousel radius |
| `ride_speed` | 1.0 | Rotation (rad/s) |
| `arm_length` | 0.75 | Attachment arm length |
| `soft_body_radius` | 0.25 | Soft body size |
| `obstacle_radius_offset` | 2.0 | Obstacle distance |
| `obstacle_height` | 3.0 | Obstacle height |
| `obstacle_y_pos` | 1.5 | Obstacle vertical position |

## Shaders

Uses queer aesthetic shaders:
- `pinktartan.gdshader` — Pink tartan pattern
- `pearlescent.gdshader` — Iridescent surface
- `frosted_glass.gdshader` — Translucent frost
- `discoLights.gdshader` — Animated lights

## Files

| File | Purpose |
|------|---------|
| `joyride.gd` | Ride simulation |
| `*.tscn` | Scene file |

## Usage

```gdscript
var ride = preload("res://algorithms/softbodies/joyride/joyride.tscn").instantiate()
ride.ride_speed = 2.0  # Faster spin
add_child(ride)
```

## See Also

- `softbodies/` — Other soft body demos
- `physicssimulation/` — Physics systems
