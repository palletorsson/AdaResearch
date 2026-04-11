# Trans_Intro — Technical Tutorial

## The Three Transformation Cubes

### Transport Cube (Translation)

```gdscript
# Translation is additive — position changes by a delta
position += direction * distance

# The object remains itself, just elsewhere
# No change to rotation, no change to scale
# Pure displacement in space
```

Key properties:
- `move_distance: float` — how far to move (in units)
- `move_direction: Vector3` — which way to move
- `move_speed: float` — animation speed

Translation is **commutative**: move right then forward = move forward then right.

### Rotation Cube (Rotation)

```gdscript
# Rotation is angular — orientation changes by degrees
rotation_degrees += axis * angle

# The object stays in place but faces differently
# 90° is the fundamental unit (what makes a cube a cube)
# Creates new affordances: floor → ramp, wall → floor
```

Key properties:
- `rotation_amount: float` — degrees to rotate (90° is canonical)
- `rotation_axis: Vector3` — axis of rotation (x=pitch, y=yaw, z=roll)
- `rotation_speed: float` — animation speed

Rotation is **non-commutative**: rotate X then Y ≠ rotate Y then X.

### Scale Cube (Scale)

```gdscript
# Scale is multiplicative — size changes by a factor
scale *= scale_factor

# The object doesn't move or turn — it becomes more
# Volume grows cubically: 2× scale = 8× volume (2³)
# Fills space through presence, not position
```

Key properties:
- `scale_factor: float` — multiplier (2.0 = double, 0.5 = half)
- `uniform_scale: bool` — scale all axes equally
- `scale_axes: Vector3` — which axes to scale

Scale is **multiplicative**: 2× then 2× = 4×, not 2+2.

## The Mathematics

| Transform | Operation | Unit | Commutative |
|-----------|-----------|------|-------------|
| Translation | + | meters | Yes |
| Rotation | × (matrix) | degrees | No |
| Scale | × | factor | Yes* |

*Scale is commutative with itself, but not with rotation.

## Implementation Pattern

All three cubes follow the same pattern:
1. Detect player entry (Area3D)
2. Wait for delay
3. Apply transformation with animation
4. Optionally auto-return

```gdscript
func _on_detection_area_body_entered(body: Node3D) -> void:
    if is_player(body):
        trigger_transformation()

func trigger_transformation():
    await get_tree().create_timer(delay).timeout
    animate_transformation()
```

The difference is what `animate_transformation()` does — move, rotate, or scale.
