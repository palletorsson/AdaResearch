# Vector Foundations — Technical

The map stages three islands that introduce vectors as ordered triples, as tip-to-tail additions, and as decompositions along chosen axes. The underlying data type is Godot's Vector3, a lightweight struct of three floats.

```gdscript
# Vector construction and access
var v := Vector3(1.0, 2.0, -0.5)
print(v.x, v.y, v.z)  # 1.0 2.0 -0.5
print(v.length())      # sqrt(1 + 4 + 0.25) ≈ 2.29
print(v.normalized())  # unit vector in the same direction

# Basis triple: i, j, k — the three orthonormal axes
const I := Vector3(1, 0, 0)
const J := Vector3(0, 1, 0)
const K := Vector3(0, 0, 1)

# Any point expressed as a combination
func combination(x: float, y: float, z: float) -> Vector3:
    return x * I + y * J + z * K
```

## Addition and Subtraction

Tip-to-tail addition and the parallelogram rule are equivalent ways of visualising vector addition. Both produce the same resultant, and the map demonstrates them side by side.

```gdscript
func add_tip_to_tail(a: Vector3, b: Vector3) -> Vector3:
    return a + b  # Godot's + operator does componentwise addition

func parallelogram(a: Vector3, b: Vector3) -> Array:
    # Four corners of the parallelogram
    var origin := Vector3.ZERO
    return [origin, a, a + b, b]
```

Subtraction is addition of the negated vector. Geometrically, A − B points from B's tip to A's tip, which is why subtraction is how you get a direction between two points.

## Decomposition

Decomposing a vector along a basis means projecting it onto each axis. Godot exposes component access directly, but the projection operation generalises to non-orthogonal bases.

```gdscript
func decompose_orthogonal(v: Vector3) -> Array:
    return [v.x, v.y, v.z]  # components along i, j, k

func project_onto(v: Vector3, axis: Vector3) -> Vector3:
    var axis_normalized := axis.normalized()
    return axis_normalized * v.dot(axis_normalized)
```

## Complexity

Every operation above is O(1) — three floats in, three floats out. The map's visualisations cost more than the arithmetic: each arrow rendered is a mesh with dozens of triangles, so drawing a hundred vectors is a hundred draw calls unless they are batched.

The becoming_catalyst pickup at the edge of the third island is a standard interactable. Picking it up sets a player flag that unlocks the catalyst's force mode for the rest of the sequence.

Within the sequence, VectorFoundations establishes the basis as a convention. Every later map manipulates the coefficients this map introduces, and the coefficients are always coefficients against a chosen frame.

## Coordinate Systems

Godot 4 uses a right-handed coordinate system with Y pointing up. OpenGL uses the same. DirectX uses a left-handed system with Y up; Unity also uses left-handed. These are conventions that affect how cross products work: the right-hand rule in a right-handed system produces different outputs than in a left-handed system for the same inputs.

```gdscript
const UP := Vector3.UP        # Vector3(0, 1, 0)
const RIGHT := Vector3.RIGHT  # Vector3(1, 0, 0)
const FORWARD := Vector3.FORWARD  # Vector3(0, 0, -1) in Godot
```

The forward-is-negative-z convention is a Godot-ism worth knowing: barrel direction of a default-oriented gun is `-transform.basis.z`, not `+transform.basis.z`.

## Float Precision

Vector3 in Godot 4 is single-precision (32-bit). For maps contained in a 100-unit box, precision is sub-millimetre and imperceptible. For larger worlds, precision degrades: at 100,000 units from the origin, float granularity is about 0.01 units, which is visible as jitter. Large-world games use double-precision vectors or relative coordinate systems to avoid this.

## Homogeneous Coordinates

3D transformations are usually implemented with 4×4 matrices that multiply homogeneous vectors (x, y, z, w). The w coordinate distinguishes positions (w=1) from directions (w=0) and lets translation, rotation, and scaling all be expressed as matrix multiplication. Godot's Transform3D wraps a Basis (3×3) plus an origin (Vector3), giving the same expressive power with a more compact representation.

## Common Pitfalls

Normalising a near-zero vector produces NaN or infinity. The safe pattern checks length before dividing:

```gdscript
func safe_normalize(v: Vector3) -> Vector3:
    var len: float = v.length()
    if len < 0.0001: return Vector3.ZERO
    return v / len
```

Comparing Vector3 with == works, but floating-point arithmetic makes exact equality unreliable. Use `is_equal_approx` for tolerance-based comparison.
