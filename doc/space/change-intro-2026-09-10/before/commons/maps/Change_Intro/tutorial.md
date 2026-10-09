# The Slope at a Point

A curve. A tangent. One number where they touch.

The derivative is a limit you can compute by shrinking a step.

```gdscript
func f(x: float) -> float:
    return 0.4 * x * x - 1.2 * x + 2.0

func slope_at(x: float, h: float = 0.001) -> float:
    return (f(x + h) - f(x)) / h
```

Take a small step `h`, measure the rise, divide. As `h` shrinks, the answer settles — that settling value is the slope at exactly `x`.

Ride the tangent along the curve.

```gdscript
func tangent_points(x: float, half_len: float = 0.8) -> Array[Vector2]:
    var m := slope_at(x)
    var p := Vector2(x, f(x))
    var dir := Vector2(1.0, m).normalized() * half_len
    return [p - dir, p + dir]
```

The tangent is the line through `(x, f(x))` with direction `(1, slope)`. Slide `x` with a slider and redraw: where the curve rises the line tilts up, at the crest it lies flat, past the crest it tilts down.

The symmetric version is more honest for the same cost:

```gdscript
func slope_centered(x: float, h: float = 0.001) -> float:
    return (f(x + h) - f(x - h)) / (2.0 * h)
```

Step both ways and average. Errors on either side cancel.

Try: find the `x` where `slope_at(x)` reads zero. That is the bottom of the valley — the curve's one moment of stillness, and the whole of optimization in one number.
