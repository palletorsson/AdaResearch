# Vector Operations — Technical

Three islands demonstrate dot product, cross product, and projection — the three operations that make vectors useful beyond addition.

```gdscript
# Dot product: scalar, measures alignment
func dot(a: Vector3, b: Vector3) -> float:
    return a.x * b.x + a.y * b.y + a.z * b.z
    # Equivalent to: a.length() * b.length() * cos(angle_between)

# Cross product: vector perpendicular to both inputs
func cross(a: Vector3, b: Vector3) -> Vector3:
    return Vector3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    )
    # Length equals area of parallelogram spanned by a and b
    # Direction given by right-hand rule

# Projection: shadow of a onto b
func project(a: Vector3, b: Vector3) -> Vector3:
    var b_unit := b.normalized()
    return b_unit * a.dot(b_unit)
```

Godot provides these as built-in methods on Vector3: `a.dot(b)`, `a.cross(b)`, `a.project(b)`. The implementations above expose the arithmetic explicitly for the map's teaching.

## The Alignment Island

The first island lets the learner rotate two vectors while displaying their dot product in real time. The scalar peaks at `|a|·|b|` when the vectors are aligned, drops to zero when they are perpendicular, and becomes negative when they point in opposing directions.

```gdscript
func _process(_delta: float) -> void:
    var d := vector_a.dot(vector_b)
    alignment_label.text = "A · B = %.2f" % d
    var cos_theta := d / (vector_a.length() * vector_b.length())
    angle_label.text = "θ = %.1f°" % rad_to_deg(acos(cos_theta))
```

## The Cross-Product Island

The cross-product rig renders two input arrows in a plane and a third arrow rising perpendicular to the plane. The perpendicular's length equals the parallelogram's area.

```gdscript
func update_cross_display() -> void:
    var c := vector_a.cross(vector_b)
    cross_arrow.direction = c
    cross_arrow.length = c.length()
    area_label.text = "Area = %.2f" % c.length()
```

## The Decomposition Island

A ball rests on an inclined surface. Gravity decomposes into a component parallel to the slope (which moves the ball) and a component perpendicular to it (which the normal force cancels).

```gdscript
func gravity_decomposition(slope_normal: Vector3, gravity: Vector3) -> Array:
    var perp_component := project(gravity, slope_normal)
    var para_component := gravity - perp_component
    return [para_component, perp_component]
```

## Complexity

All three operations are O(1). The geometric displays add constant overhead. The map's performance budget is dominated by the arrow meshes rather than by the vector math.

Within the sequence, Operations converts the previous map's basis into operating machinery. VectorApplied will next put the operations to work on concrete tasks.

## The Geometry of the Dot Product

The dot product geometrically equals the product of the magnitudes times the cosine of the angle between them. Rearranging: cos(angle) = dot(a,b) / (|a||b|). This is the standard way to compute the angle between two vectors.

```gdscript
func angle_between(a: Vector3, b: Vector3) -> float:
    var denom: float = a.length() * b.length()
    if denom < 0.0001: return 0.0
    var cos_theta: float = clamp(a.dot(b) / denom, -1.0, 1.0)
    return acos(cos_theta)  # radians
```

The clamp is essential because floating-point error can push the cosine slightly outside [-1, 1], and acos returns NaN for values outside that range.

## Cross Product Sign

The cross product's sign follows the right-hand rule. If the fingers curl from a to b, the thumb points in the direction of a × b. Reversing the order flips the sign: b × a = -(a × b). This asymmetry is load-bearing — it is how cross products distinguish "above" from "below" a plane.

## Projection vs Rejection

The projection of a onto b gives the component of a along b. The rejection is the perpendicular component: a - proj_b(a). Together, projection and rejection decompose any vector into parallel and perpendicular parts relative to any other vector.

```gdscript
func project_and_reject(a: Vector3, b: Vector3) -> Array:
    var proj := a.project(b)
    var rej := a - proj
    return [proj, rej]
```

This is the core of many graphics and physics operations. Surface normals decompose motion into "sliding along surface" (rejection) and "pushing into surface" (projection).

## When Cosine Similarity Is Wrong

Dot product measures alignment regardless of magnitude. For two vectors pointing the same direction but of very different magnitudes, the dot product is large even though the "similarity" is complete. Cosine similarity — dot product divided by magnitude product — normalises this and is used in information retrieval and recommender systems for exactly this reason.

## Numerical Stability

Gram-Schmidt orthogonalisation — the process of converting a basis into an orthonormal one using dot products and projections — is numerically unstable when basis vectors are nearly parallel. Modified Gram-Schmidt and QR decomposition via Householder reflections are more robust alternatives. For 3D vectors the instability is rarely practical, but it matters in higher dimensions.
