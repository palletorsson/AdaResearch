extends Node

var text = '''[center][font_size=28][b]Bézier Curves[/b][/font_size][/center]
[center][i]Parametric Curves, Control Points, Smooth Paths[/i][/center]

**Bézier curves create smooth curves through control points.**

**Linear (2 points):** P(t) = (1-t)P₀ + tP₁
**Quadratic (3 points):** Recursive lerp
**Cubic (4 points):** Most common (SVG, fonts, animation)

[hr]

[b]De Casteljau's Algorithm[/b]

**Recursive linear interpolation:**

[color=yellow][b]Code:[/b][/color]
[code]
func bezier(points: Array, t: float) -> Vector2:
    if points.size() == 1:
        return points[0]

    var new_points = []
    for i in range(points.size() - 1):
        var lerped = points[i].lerp(points[i + 1], t)
        new_points.append(lerped)

    return bezier(new_points, t)

# Cubic Bezier (4 control points)
var p0 = Vector2(0, 0)
var p1 = Vector2(1, 2)  # Control point
var p2 = Vector2(3, 2)  # Control point
var p3 = Vector2(4, 0)

# Generate curve
for i in range(100):
    var t = i / 100.0
    var point = bezier([p0, p1, p2, p3], t)
    draw_point(point)
[/code]

**Properties:**
- **Starts at P₀, ends at Pₙ**
- **Tangent at P₀ toward P₁**
- **Smooth** (infinitely differentiable)
- **Convex hull** (curve stays within control polygon)

[hr]

[b]Applications[/b]

- **Vector graphics** (SVG paths, fonts)
- **Animation** (easing curves, motion paths)
- **CAD** (smooth surface design)
- **Camera paths** (cinematic movement)

[hr]

[b]Queer Bézier[/b]

**Bézier curves are influenced by control points but DON'T pass through them.**

**This is indirect determination:**
- **Control points guide** but don't dictate
- **Curve negotiates** between influences
- **Smooth interpolation** (not sharp corners)

**Queer trajectory as Bézier:**
- **Parents/society = control points** (influence but we don't become them)
- **Our path curved by proximity** but not forced through them
- **Smooth negotiation** between pressures
- **Tangent to origins** (we leave in direction shaped by start)

**We don't follow straight lines through control points.** **We curve, influenced but autonomous.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Bézier curves: parametric curves through control points. De Casteljau: recursive lerp. Properties: endpoints fixed, tangent to first/last edge, smooth, convex hull. Applications: vector graphics, animation, CAD. Queer Bézier: control points guide but don't determine, smooth negotiation between influences, tangent to origins, autonomy within constraints.

'''
