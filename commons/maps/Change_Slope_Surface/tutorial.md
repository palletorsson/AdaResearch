# Two Slopes at Once

The curve becomes a surface. One slope becomes two — east and north — and together they make an arrow.

```gdscript
func h(x: float, z: float) -> float:
    return 2.0 * sin(x * 0.5) * cos(z * 0.5)   # the terrain

func partial_x(x: float, z: float, e: float = 0.01) -> float:
    return (h(x + e, z) - h(x - e, z)) / (2.0 * e)

func partial_z(x: float, z: float, e: float = 0.01) -> float:
    return (h(x, z + e) - h(x, z - e)) / (2.0 * e)
```

A partial derivative freezes every axis but one. `partial_x` asks: stepping east, how fast does the ground rise? `partial_z` asks the same going north. Neither alone describes the hill — together they do.

The two partials assemble into the gradient.

```gdscript
func gradient(x: float, z: float) -> Vector2:
    return Vector2(partial_x(x, z), partial_z(x, z))
```

The gradient points in the direction of steepest ascent, and its length says how steep. Negate it and you have the direction water flows — and, eight sequences from here, the direction a neural network's loss rolls downhill. Same arrow.

Plant an arrow on the terrain where you stand:

```gdscript
func slope_arrow_at(x: float, z: float) -> Transform3D:
    var g := gradient(x, z)
    var up_slope := Vector3(g.x, 0.0, g.y)
    var origin := Vector3(x, h(x, z), z)
    return Transform3D(Basis.looking_at(up_slope.normalized()), origin)
```

Try: stand at a saddle — uphill east-west, downhill north-south. `partial_x` and `partial_z` disagree about the sign of the world, and both are right. That disagreement is why surfaces need two numbers where curves needed one.
