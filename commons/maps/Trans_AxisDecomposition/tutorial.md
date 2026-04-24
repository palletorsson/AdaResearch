# Axis Decomposition

Decompose any vector into its component along each axis.

Extract the components.

```gdscript
func components_on_axes(v: Vector3) -> Array:
    return [v.x, v.y, v.z]
```

Direct access. The triple of components is a decomposition against the standard basis.

Compute the component along an arbitrary axis.

```gdscript
func component_along(v: Vector3, axis: Vector3) -> float:
    return v.dot(axis.normalized())
```

The dot product with a unit-length axis gives the signed projection. Positive if aligned, negative if opposing.

Reconstruct a vector from its components.

```gdscript
func reconstruct(cx: float, cy: float, cz: float) -> Vector3:
    return Vector3.RIGHT * cx + Vector3.UP * cy + Vector3.FORWARD * cz
```

Weighted sum of basis vectors. The reconstructed vector matches the original exactly.

Decompose against a custom basis.

```gdscript
func decompose_custom(v: Vector3, basis: Array) -> Array:
    return [v.dot(basis[0].normalized()), v.dot(basis[1].normalized()), v.dot(basis[2].normalized())]
```

Three dot products, one per basis vector. The basis must be orthogonal and normalised for correct reconstruction.

Visualise each component as a coloured arrow.

```gdscript
func draw_decomposition(v: Vector3) -> void:
    draw_arrow(Vector3.ZERO, Vector3.RIGHT * v.x, Color.RED)
    draw_arrow(Vector3.RIGHT * v.x, Vector3.RIGHT * v.x + Vector3.UP * v.y, Color.GREEN)
    draw_arrow(Vector3.RIGHT * v.x + Vector3.UP * v.y, v, Color.BLUE)
```

Three arrows, tip to tail. The sum reaches the original vector.

Sum multiple vectors component-wise.

```gdscript
func sum_components(vectors: Array) -> Vector3:
    var total := Vector3.ZERO
    for v in vectors:
        total += v
    return total
```

Each axis sums independently. The total's x is the sum of all x components, etc.

Project a vector onto a plane.

```gdscript
func project_onto_plane(v: Vector3, plane_normal: Vector3) -> Vector3:
    return v - v.project(plane_normal)
```

Subtract the component perpendicular to the plane. What remains lies in the plane.

You can now decompose a vector onto any basis, reconstruct it, and project it onto any plane. Trans_Rotation extends the geometric operations into angular space.

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
