# Vector Foundations

Three arrows name directions. Every point in space is a combination of them.

Plant the three basis arrows.

```gdscript
const I := Vector3(1, 0, 0)  # east
const J := Vector3(0, 1, 0)  # up
const K := Vector3(0, 0, 1)  # north
```

Unit vectors. Length 1 each. Orthogonal.

Write a point as coefficients of the basis.

```gdscript
func compose(x: float, y: float, z: float) -> Vector3:
    return x * I + y * J + z * K
```

The coefficients are the point's coordinates. Coefficient arithmetic is the vector arithmetic underneath.

Build a vector from a direction and a magnitude.

```gdscript
func from_direction_and_length(direction: Vector3, length: float) -> Vector3:
    return direction.normalized() * length
```

Scale the direction by the length. The result points the same way with the specified magnitude.

Add two vectors tip-to-tail.

```gdscript
func add_tip_to_tail(a: Vector3, b: Vector3) -> Vector3:
    return a + b
```

Godot's + operator does componentwise addition. The result is the vector from a's tail to b's tip.

Subtract two points to get the vector between them.

```gdscript
func between_points(from_p: Vector3, to_p: Vector3) -> Vector3:
    return to_p - from_p
```

The direction runs from first argument to second. Length equals the distance between them.

Decompose a vector onto each axis.

```gdscript
func decompose(v: Vector3) -> Array:
    return [v.x, v.y, v.z]
```

Direct component access. The result is the triple of coefficients in the standard basis.

Project a vector onto any axis.

```gdscript
func project_onto_axis(v: Vector3, axis: Vector3) -> float:
    return v.dot(axis.normalized())
```

The scalar is the signed length of the projection. Positive if aligned, negative if opposing.

Pick up the force catalyst.

```gdscript
func check_catalyst_pickup() -> void:
    var catalyst := get_tree().get_first_node_in_group("becoming_catalyst")
    if catalyst and catalyst.was_picked_up:
        unlock_force_mode()
```

The catalyst is a grabbable artifact. Picking it up sets a flag the rest of the sequence reads.

You can now write any point as a combination of basis vectors, add and decompose vectors, and pick up the catalyst that unlocks the remainder of the sequence. VectorOperations will next introduce three operations: dot, cross, and projection.

Scale a vector.

```gdscript
func scale_vector(v: Vector3, s: float) -> Vector3:
    return v * s
```

Positive scale preserves direction, negative reverses it. Scale of zero collapses the vector to the origin.

Normalise any vector to unit length.

```gdscript
func safe_normalise(v: Vector3) -> Vector3:
    if v.length() < 0.0001: return Vector3.ZERO
    return v.normalized()
```

Guard against zero-length inputs to avoid NaN. The result is either a unit vector or the zero vector.

Cross product basics.

```gdscript
func quick_perp(a: Vector3, b: Vector3) -> Vector3:
    return a.cross(b)
```

Length of a vector.

```gdscript
func vector_length(v: Vector3) -> float:
    return v.length()
# Equivalent: sqrt(v.x*v.x + v.y*v.y + v.z*v.z)
```

Distance between two points.

```gdscript
func distance(a: Vector3, b: Vector3) -> float:
    return a.distance_to(b)
# Equivalent: (b - a).length()
```
