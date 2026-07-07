# Shape as a Condition

A sphere is not vertices. It is a sentence: every point whose distance from the center equals the radius. Implicit modeling takes the sentence as the object.

Signed distance functions are the cleanest dialect — each returns *how far to the surface*, negative inside:

```gdscript
func sd_sphere(p: Vector3, r: float) -> float:
    return p.length() - r

func sd_box(p: Vector3, b: Vector3) -> float:
    var q := p.abs() - b
    return q.max(Vector3.ZERO).length() + min(max(q.x, max(q.y, q.z)), 0.0)

func sd_torus(p: Vector3, R: float, r: float) -> float:
    return Vector2(Vector2(p.x, p.z).length() - R, p.y).length() - r
```

The payoff is an algebra. Solid modeling becomes three one-liners:

```gdscript
func op_union(a: float, b: float) -> float:        return min(a, b)
func op_intersect(a: float, b: float) -> float:    return max(a, b)
func op_subtract(a: float, b: float) -> float:     return max(a, -b)
```

`min` says "the nearer surface wins" — union. `max` keeps only where both are inside — intersection. Negating one flips its inside out — subtraction. The entire CSG chapter of this curriculum, three functions.

The distinctly implicit move is the *smooth* union — blending shapes no mesh operation can blend:

```gdscript
func op_smooth_union(a: float, b: float, k: float) -> float:
    var h := clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return lerp(b, a, h) - k * h * (1.0 - h)
```

`k` is the fillet radius: 0 gives a hard seam, 0.5 melts the joint like wax. A model, then, is one function:

```gdscript
func model(p: Vector3) -> float:
    var body := op_smooth_union(sd_sphere(p - Vector3(0, 1, 0), 1.0),
                                sd_box(p, Vector3(1.2, 0.4, 1.2)), 0.3)
    return op_subtract(body, sd_torus(p - Vector3(0, 1.2, 0), 0.9, 0.25))
```

Feed `model` to marching cubes and it becomes walkable; hand it to a raymarcher and it renders without ever becoming a mesh at all.

Try: change one constant and re-extract. There is no undo stack because there was never an edit — only a claim about space, revised. The mesh was always just a quotation from the function.
