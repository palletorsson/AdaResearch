# Trans Scale

Scaling. Size. Volume scales cubically.

Uniform scale.

```gdscript
func scale_uniform(node: Node3D, factor: float) -> void:
    node.scale = Vector3.ONE * factor
```

All three axes by the same factor. Shape preserved, size changed.

Non-uniform scale.

```gdscript
func scale_non_uniform(node: Node3D, factors: Vector3) -> void:
    node.scale = factors
```

Each axis independent. A Vector3(2, 1, 0.5) stretches horizontally, preserves vertical, shortens depth.

Compute the volume ratio.

```gdscript
func volume_ratio(before: Vector3, after: Vector3) -> float:
    return (after.x * after.y * after.z) / (before.x * before.y * before.z)
```

The product of scale factors gives the volume scale. Double the linear dimensions, multiply volume by 8.

Scale with VR gestures.

```gdscript
var initial_hand_distance: float = 0.0
var initial_scale: Vector3

func start_scaling(target: Node3D, left: XRController3D, right: XRController3D) -> void:
    initial_hand_distance = left.global_position.distance_to(right.global_position)
    initial_scale = target.scale

func update_scaling(target: Node3D, left: XRController3D, right: XRController3D) -> void:
    var current: float = left.global_position.distance_to(right.global_position)
    var factor: float = current / initial_hand_distance
    target.scale = initial_scale * factor
```

Two-handed scale gesture. Spread hands apart to grow, bring them together to shrink.

Clamp the scale.

```gdscript
const MIN_SCALE: float = 0.1
const MAX_SCALE: float = 5.0

func clamp_scale(node: Node3D) -> void:
    var s: Vector3 = node.scale
    node.scale = Vector3(clamp(s.x, MIN_SCALE, MAX_SCALE), clamp(s.y, MIN_SCALE, MAX_SCALE), clamp(s.z, MIN_SCALE, MAX_SCALE))
```

Prevent scale from going to extremes that break interaction or rendering.

Scale physics body with collision shape.

```gdscript
func scale_with_collision(body: RigidBody3D, factor: float) -> void:
    body.scale = Vector3.ONE * factor
    for child in body.get_children():
        if child is CollisionShape3D:
            child.scale = Vector3.ONE * factor
    body.mass = body.mass * pow(factor, 3)
```

Collision scales with the body automatically. Mass needs manual adjustment to reflect the cubic volume change.

Animate a scale transition.

```gdscript
func tween_scale(node: Node3D, target_scale: Vector3, duration: float) -> void:
    var tween := create_tween()
    tween.tween_property(node, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
```

Quadratic ease-out feels natural for growth. Linear scaling feels mechanical.

You can now scale uniformly or non-uniformly, with VR gestures or tweens, while keeping collision shapes and mass consistent. Trans_Pit extends scaling into a lethal hazard room.

Check identity.

```gdscript
func is_identity(t: Transform3D) -> bool:
    return t.is_equal_approx(Transform3D.IDENTITY)
```

Identity preserves the input. Useful as a test for whether a chain of transforms cancels out.

Invert a transform.

```gdscript
func invert(t: Transform3D) -> Transform3D:
    return t.affine_inverse()
```

Undo the transform. Composing t with t.affine_inverse() produces identity.
