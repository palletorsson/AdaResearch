# Turret Targeting

A laser turret that tracks and destroys falling balls, demonstrating core vector operations in real-time.

## Vector Operations Demonstrated

| Operation | Application |
|-----------|-------------|
| **Subtraction** | `direction = target - turret` → direction to target |
| **Magnitude** | `distance = direction.length()` → range check |
| **Normalization** | `aim = direction.normalized()` → unit aim vector |
| **Dot Product** | `lock = aim.dot(barrel_dir)` → aim quality check |

## Scenes

- **`TurretTargeting.tscn`** — Combined demo (turret + dropper + stats)
- **`LaserTurret.tscn`** — Standalone turret unit
- **`BallDropper.tscn`** — Standalone ball dropper

## Usage

### Combined Demo
```gdscript
var demo = preload("res://algorithms/vectors/11_turret_targeting/TurretTargeting.tscn").instantiate()
add_child(demo)
```

### Separate Units
```gdscript
var turret = preload("res://algorithms/vectors/11_turret_targeting/LaserTurret.tscn").instantiate()
var dropper = preload("res://algorithms/vectors/11_turret_targeting/BallDropper.tscn").instantiate()
dropper.position = Vector3(0, 3, 2)  # Above turret
add_child(turret)
add_child(dropper)
```

## Controls

| Key | Action |
|-----|--------|
| `SPACE` | Drop ball immediately |
| `R` | Reset (clear balls, reset stats) |
| `T` | Toggle auto-drop |

## How It Works

1. **Dropper** releases colorful balls one at a time
2. **Turret** scans for targets (idle rotation)
3. When ball enters range: turret tracks using vector subtraction
4. When aim locks (dot product > 0.97): laser fires
5. Laser burns ball (emission intensifies over burn_time)
6. Ball explodes with colored particles
7. Repeat

## Parameters

### Turret
- `rotation_speed` — How fast turret tracks (rad/s)
- `detection_range` — Max targeting distance
- `fire_delay` — Lock time before firing
- `burn_time` — How long laser burns before explosion
- `laser_color` — Beam color

### Dropper
- `drop_interval` — Seconds between drops
- `max_balls` — Maximum balls alive at once
- `ball_radius` — Size of balls
- `spawn_spread` — Random XZ offset

## Integration

The turret automatically finds balls from:
- `ball_dropper` group (BallDropper nodes)
- `colorballs` group (ColorBalls spawners)
- Any node with "ball" in name + RigidBody3D child
