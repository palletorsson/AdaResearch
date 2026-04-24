# Vector Operations

Three operations turn arrows into relationships. Dot, cross, projection.

Compute the dot product.

```gdscript
func dot_product(a: Vector3, b: Vector3) -> float:
    return a.dot(b)
    # Equivalent to: a.x * b.x + a.y * b.y + a.z * b.z
```

Scalar result. Measures how aligned the two vectors are.

Interpret the dot product as alignment.

```gdscript
func alignment(a: Vector3, b: Vector3) -> float:
    return a.dot(b) / (a.length() * b.length())
    # Returns cos(angle): 1 = aligned, 0 = perpendicular, -1 = opposing
```

Dividing by the magnitudes gives the cosine of the angle between them. This is the cosine similarity used in recommendation systems.

Compute the cross product.

```gdscript
func cross_product(a: Vector3, b: Vector3) -> Vector3:
    return a.cross(b)
```

Vector result. Perpendicular to both inputs, with length equal to the area of their parallelogram.

Verify the right-hand rule.

```gdscript
func verify_cross_orientation() -> void:
    var right := Vector3.RIGHT
    var up := Vector3.UP
    var back := right.cross(up)
    # back should be (0, 0, 1) — the Godot +Z direction (toward camera)
    assert(back.is_equal_approx(Vector3(0, 0, 1)))
```

The cross product's sign depends on handedness. Godot uses a right-handed system.

Project one vector onto another.

```gdscript
func project(a: Vector3, b: Vector3) -> Vector3:
    return a.project(b)
    # Equivalent to: b.normalized() * a.dot(b.normalized())
```

The projection is a's component along b. Geometrically: a's shadow on b's line.

Compute the rejection.

```gdscript
func rejection(a: Vector3, b: Vector3) -> Vector3:
    return a - a.project(b)
```

The rejection is a's component perpendicular to b. Projection plus rejection equals the original vector.

Decompose gravity on a slope.

```gdscript
func decompose_gravity(slope_normal: Vector3, gravity: Vector3 = Vector3(0, -9.81, 0)) -> Array:
    var perpendicular: Vector3 = gravity.project(slope_normal)
    var parallel: Vector3 = gravity - perpendicular
    return [parallel, perpendicular]
```

The perpendicular component meets the normal force. The parallel component moves the ball down the slope.

You can now measure alignment, compute perpendiculars, and decompose a vector onto any axis or surface. VectorApplied will next put the operations to work on turrets and fields.

Compute the angle between two vectors in degrees.

```gdscript
func angle_degrees(a: Vector3, b: Vector3) -> float:
    var cos_theta: float = clamp(a.dot(b) / (a.length() * b.length()), -1.0, 1.0)
    return rad_to_deg(acos(cos_theta))
```

Clamp the cosine to [-1, 1] before acos to avoid NaN from floating-point error. The result is in degrees.

Test perpendicularity.

```gdscript
func are_perpendicular(a: Vector3, b: Vector3, tolerance: float = 0.001) -> bool:
    return abs(a.dot(b)) < tolerance
```

Dot product is zero iff the vectors are perpendicular. Use tolerance for floating-point comparison.
