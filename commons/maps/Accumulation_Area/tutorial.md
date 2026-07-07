# How Much, Not How Fast

The question turns around. The derivative asked for the rate at an instant; the integral asks for the total over a stretch.

```gdscript
func f(x: float) -> float:
    return 1.0 + 0.5 * sin(x)

func area_under(a: float, b: float, steps: int = 1000) -> float:
    var dx := (b - a) / steps
    var total := 0.0
    for i in steps:
        total += f(a + (i + 0.5) * dx) * dx   # midpoint sample
    return total
```

Chop the interval into slivers, measure the height at each, multiply by the width, add. Every numerical integral ever computed is this loop wearing different clothes.

Fill the region so the area is a thing, not a concept:

```gdscript
func build_area_mesh(a: float, b: float, steps: int = 64) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var dx := (b - a) / steps
    for i in steps:
        var x0 := a + i * dx
        var x1 := x0 + dx
        # two triangles: baseline up to the curve
        st.add_vertex(Vector3(x0, 0, 0)); st.add_vertex(Vector3(x0, f(x0), 0)); st.add_vertex(Vector3(x1, f(x1), 0))
        st.add_vertex(Vector3(x0, 0, 0)); st.add_vertex(Vector3(x1, f(x1), 0)); st.add_vertex(Vector3(x1, 0, 0))
    return st.commit()
```

The shaded region between baseline and curve *is* the integral — drag the right-hand edge and watch the readout accumulate.

Units matter and make it real: if `f` is speed in meters per second and `x` is seconds, the area is meters — distance traveled. Rate × time, summed. The derivative and the integral are already circling each other; the Riemann map next door shows the machinery, and the reconciliation map proves the circle closes.

Try: set `steps` to 4, then 40, then 4000. Watch the total stop changing. That stabilization is the limit — the moment "chopping finer" runs out of things to correct.
