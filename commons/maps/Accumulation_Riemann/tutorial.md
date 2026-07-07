# Rectangles All the Way Down

The smooth area was a limit. These are the rectangles it is the limit *of*.

```gdscript
func riemann_sum(a: float, b: float, n: int) -> float:
    var dx := (b - a) / n
    var total := 0.0
    for i in n:
        total += f(a + i * dx) * dx     # left-hand rule
    return total
```

`n` rectangles, each `dx` wide, each as tall as the curve at its left edge. Crude at `n = 4`, honest at `n = 400`. The error is visible as the staircase poking above and below the curve.

Build the staircase so the argument is walkable:

```gdscript
func build_rectangles(a: float, b: float, n: int) -> void:
    var dx := (b - a) / n
    for i in n:
        var x := a + i * dx
        var bar := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(dx * 0.95, f(x), 0.3)
        bar.mesh = box
        bar.position = Vector3(x + dx * 0.5, f(x) * 0.5, 0)
        add_child(bar)
```

One box per sliver, height sampled from the curve. Crank `n` with the pump and the staircase melts toward the smooth region from the previous map.

The pump can compute π, which is the map's party trick — a quarter circle of radius 1 has area π/4:

```gdscript
func quarter_circle(x: float) -> float:
    return sqrt(max(0.0, 1.0 - x * x))

func pi_estimate(n: int) -> float:
    return 4.0 * riemann_sum_of(quarter_circle, 0.0, 1.0, n)
```

`n = 10` gives 3.30; `n = 1000` gives 3.143. π emerges from nothing but rectangles and patience — an irrational number assembled by finite honest labor, never finished, always approaching.

Try: compare left-rule, right-rule, and midpoint at the same `n`. Midpoint wins every time; ask the rectangles why.
