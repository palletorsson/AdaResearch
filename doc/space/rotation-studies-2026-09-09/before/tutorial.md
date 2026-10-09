# Trans Rotation

Rotation around an axis. Angles. Quaternions.

Rotate a node around the Y axis.

```gdscript
func rotate_y(node: Node3D, angle_rad: float) -> void:
    node.rotate(Vector3.UP, angle_rad)
```

The axis is the rotation's pivot. The angle is signed: positive counter-clockwise looking down the axis.

Rotate a vector without a node.

```gdscript
func rotate_vector(v: Vector3, axis: Vector3, angle_rad: float) -> Vector3:
    return v.rotated(axis.normalized(), angle_rad)
```

Vector3.rotated does the arithmetic directly. The axis must be unit length for correct results.

Rotate around a pivot point.

```gdscript
func rotate_around(node: Node3D, pivot: Vector3, axis: Vector3, angle_rad: float) -> void:
    var offset: Vector3 = node.global_position - pivot
    var rotated: Vector3 = offset.rotated(axis, angle_rad)
    node.global_position = pivot + rotated
    node.rotate(axis, angle_rad)
```

Translate to pivot frame, rotate, translate back. Both position and orientation update.

Chain three Euler-angle rotations.

```gdscript
func euler_rotate(node: Node3D, euler: Vector3) -> void:
    node.rotate(Vector3.UP, euler.y)
    node.rotate(Vector3.RIGHT, euler.x)
    node.rotate(Vector3.FORWARD, euler.z)
```

YXZ order. Different orders produce different results because rotations don't commute in 3D.

Use a quaternion to avoid gimbal lock.

```gdscript
func quaternion_rotation(axis: Vector3, angle_rad: float) -> Quaternion:
    return Quaternion(axis.normalized(), angle_rad)

func apply_quaternion(node: Node3D, q: Quaternion) -> void:
    node.quaternion = q * node.quaternion
```

Quaternions combine without gimbal lock. Two quaternions multiply cleanly; composing a chain is just multiplication.

Slerp between two rotations.

```gdscript
func slerp_rotation(from_q: Quaternion, to_q: Quaternion, t: float) -> Quaternion:
    return from_q.slerp(to_q, t)
```

Spherical linear interpolation. Unlike lerp, slerp maintains constant angular velocity.

Animate a rotation over time.

```gdscript
func animate_rotation(node: Node3D, target_quaternion: Quaternion, duration: float) -> void:
    var start_q: Quaternion = node.quaternion
    var tween := create_tween()
    tween.tween_method(
        func(t): node.quaternion = start_q.slerp(target_quaternion, t),
        0.0, 1.0, duration
    )
```

The tween interpolates the slerp parameter. The node rotates smoothly between start and target orientations.

You can now rotate around arbitrary axes and pivots, chain Euler rotations, combine quaternions without gimbal lock, and animate rotations with slerp. Trans_RotationSpectacle extends rotation into a stage performance.

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

Compose with multiplication.

```gdscript
func combine(a: Transform3D, b: Transform3D) -> Transform3D:
    return a * b
```

Right-to-left application order. a * b applies b first, then a.

Extract the origin.

```gdscript
func get_origin(t: Transform3D) -> Vector3:
    return t.origin
```

The origin is the translation part of the transform. Ignore the basis to get just the position.
