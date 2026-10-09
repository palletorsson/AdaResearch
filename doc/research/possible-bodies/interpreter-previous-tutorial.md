# Grammars and Curves

Different rules produce different curves. Each rule is a shape's DNA.

Koch snowflake.

```gdscript
var koch := LSystem.new()
koch.axiom = "F--F--F"  # triangle
koch.rules = {"F": "F+F--F+F"}
koch.angle_deg = 60.0
```

Starts as a triangle. Each F expands to a kink; four generations produce the snowflake.

Dragon curve.

```gdscript
var dragon := LSystem.new()
dragon.axiom = "FX"
dragon.rules = {
    "X": "X+YF+",
    "Y": "-FX-Y",
}
dragon.angle_deg = 90.0
```

Two non-terminal symbols, X and Y. The dragon curve folds on itself at right angles.

Hilbert curve.

```gdscript
var hilbert := LSystem.new()
hilbert.axiom = "A"
hilbert.rules = {
    "A": "+BF-AFA-FB+",
    "B": "-AF+BFB+FA-",
}
hilbert.angle_deg = 90.0
```

Space-filling curve. Each generation packs more detail into the same region.

Sierpinski triangle.

```gdscript
var sierpinski := LSystem.new()
sierpinski.axiom = "A"
sierpinski.rules = {
    "A": "B-A-B",
    "B": "A+B+A",
}
sierpinski.angle_deg = 60.0
```

Two mutually recursive rules. The interpretation treats both A and B as F for drawing.

Implement drawing for any symbol.

```gdscript
func interpret_curve(lstring: String, step: float, angle_rad: float) -> Array:
    var segments: Array = []
    var position := Vector2.ZERO
    var heading: float = 0.0
    for c in lstring:
        match c:
            "F", "A", "B":
                var end := position + Vector2(cos(heading), sin(heading)) * step
                segments.append([position, end])
                position = end
            "+":
                heading += angle_rad
            "-":
                heading -= angle_rad
    return segments
```

Treat all non-terminals as drawing commands. The logical distinction between A and B matters for the rewrite; the interpretation ignores it.

Normalise the scale.

```gdscript
func fit_to_bounds(segments: Array, target_size: Vector2) -> Array:
    var min_p := Vector2.INF; var max_p := -Vector2.INF
    for seg in segments:
        min_p = min_p.min(seg[0]); min_p = min_p.min(seg[1])
        max_p = max_p.max(seg[0]); max_p = max_p.max(seg[1])
    var span: Vector2 = max_p - min_p
    var scale: float = min(target_size.x / span.x, target_size.y / span.y)
    var offset: Vector2 = -min_p * scale
    var scaled: Array = []
    for seg in segments:
        scaled.append([seg[0] * scale + offset, seg[1] * scale + offset])
    return scaled
```

Measure the bounding box, compute a scale that fits, apply it. The curve renders at consistent size regardless of generation.

Render side by side.

```gdscript
func render_gallery(systems: Array, positions: Array) -> void:
    for i in systems.size():
        var lstring: String = systems[i].expand(4)
        var segments: Array = interpret_curve(lstring, 0.1, deg_to_rad(systems[i].angle_deg))
        segments = fit_to_bounds(segments, Vector2(2, 2))
        render_at_position(segments, positions[i])
```

Four grammars at four positions. The gallery makes the grammar-curve relationship comparative.

You can now encode multiple grammars, interpret them uniformly, fit each to a target bounding box, and render them side by side. LSystems_Architecture extends L-systems into building-scale form.
