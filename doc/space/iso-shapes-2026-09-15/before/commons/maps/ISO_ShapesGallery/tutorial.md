# One Algorithm, Seven Sculptures

Every statue in this row is the same marching cubes. Only the field changed.

```gdscript
func sphere(p: Vector3, r: float = 2.0) -> float:
    return r - p.length()                     # positive inside

func torus(p: Vector3, R: float = 2.0, r: float = 0.7) -> float:
    var q := Vector2(Vector2(p.x, p.z).length() - R, p.y)
    return r - q.length()

func gyroid(p: Vector3, s: float = 2.0) -> float:
    p *= s
    return sin(p.x) * cos(p.y) + sin(p.y) * cos(p.z) + sin(p.z) * cos(p.x)
```

Each function answers the same question — how inside is this point? — with different geometry hidden in the arithmetic. The extractor neither knows nor cares which one it is marching:

```gdscript
func extract(field: Callable, size: int = 32, iso: float = 0.0) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    march_all_cells(field, size, iso, st)     # same loop as ISO_Introduction
    st.generate_normals()
    return st.commit()
```

`extract(sphere)`, `extract(torus)`, `extract(gyroid)` — one algorithm, a gallery. This is the sequence's quiet thesis about form: the sculptor is a *function*, and the chisel (marching cubes) is generic.

Fields compose with plain arithmetic, which no mesh can do:

```gdscript
func blend(p: Vector3) -> float:
    return max(sphere(p, 2.0), torus(p, 2.4, 0.5))   # union
func shell(p: Vector3) -> float:
    return 0.15 - abs(sphere(p, 2.0))                # hollow skin
```

`max` unions, `min` intersects (with this sign convention), `abs` makes shells. Add noise to any of them and the statue weathers.

Try: write your own three-line field and hand it to the extractor. The gallery grows by one — no modeling, just a claim about space, evaluated everywhere.
