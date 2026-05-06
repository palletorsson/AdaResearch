extends Node

var text = '''[center][font_size=28][b]Catmull-Rom Splines[/b][/font_size][/center]
[center][i]Interpolating Curves, Smooth Paths[/i][/center]

**Catmull-Rom splines create smooth curves that pass through all control points.**

**Unlike Bézier:** Curve **goes through** control points (not just influenced by them).

**Natural for:** Animation paths, camera rails, trajectory interpolation.

[hr]

[b]Concept[/b]

**Bézier curves:** Control points **pull** curve toward them (curve doesn't pass through).
**Catmull-Rom:** Curve **passes through** every control point.

**Key property:** **C1 continuous** - smooth velocity (no sharp direction changes).

**Defined by:** **4 points at a time** - P0, P1, P2, P3
- Curve segment goes from **P1 to P2**
- **P0 and P3** determine tangent directions at P1 and P2

[hr]

[b]Formula[/b]

[color=yellow][b]Mathematics:[/b][/color]
```
P(t) = 0.5 * (
    (2 * P1) +
    (-P0 + P2) * t +
    (2*P0 - 5*P1 + 4*P2 - P3) * t² +
    (-P0 + 3*P1 - 3*P2 + P3) * t³
)

Where t ∈ [0, 1]
```

**For t=0:** P(0) = P1 (starts at P1)
**For t=1:** P(1) = P2 (ends at P2)

[color=yellow][b]Code:[/b][/color]
[code]
func catmull_rom_point(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
    var t2 = t * t
    var t3 = t2 * t

    return 0.5 * (
        (2.0 * p1) +
        (-p0 + p2) * t +
        (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
        (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
    )

func generate_catmull_rom_curve(control_points: Array, resolution: int = 20) -> Array:
    var curve_points = []

    # Need at least 4 points
    if control_points.size() < 4:
        return curve_points

    # For each segment (between consecutive control points)
    for i in range(control_points.size() - 3):
        var p0 = control_points[i]
        var p1 = control_points[i + 1]
        var p2 = control_points[i + 2]
        var p3 = control_points[i + 3]

        # Generate points along segment from p1 to p2
        for j in range(resolution):
            var t = float(j) / float(resolution)
            var point = catmull_rom_point(p0, p1, p2, p3, t)
            curve_points.append(point)

    # Add final control point
    curve_points.append(control_points[control_points.size() - 2])

    return curve_points
[/code]

[hr]

[b]Tension Parameter[/b]

**Standard Catmull-Rom** has fixed tension (tau = 0.5).

**Generalized form** allows **adjustable tension**:

[color=yellow][b]Code with Tension:[/b][/color]
[code]
func catmull_rom_with_tension(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
                               t: float, tension: float = 0.5) -> Vector3:
    var t2 = t * t
    var t3 = t2 * t

    # Tangent at p1: tension * (p2 - p0)
    # Tangent at p2: tension * (p3 - p1)

    var m1 = tension * (p2 - p0)  # Tangent at start
    var m2 = tension * (p3 - p1)  # Tangent at end

    # Hermite basis functions
    var h00 = 2*t3 - 3*t2 + 1
    var h10 = t3 - 2*t2 + t
    var h01 = -2*t3 + 3*t2
    var h11 = t3 - t2

    return h00 * p1 + h10 * m1 + h01 * p2 + h11 * m2

# tension = 0.0 → loose, flowing curves
# tension = 0.5 → standard Catmull-Rom
# tension = 1.0 → tight, almost linear
[/code]

**Tension controls curvature:**
- **Low tension (0.0):** Loose, exaggerated curves
- **High tension (1.0):** Tight, nearly straight segments

[hr]

[b]vs Bézier Curves[/b]

| **Bézier** | **Catmull-Rom** |
|---|---|
| Curve approximates control points | Curve interpolates control points |
| Direct control of shape | Automatic smooth interpolation |
| 4 points → 1 segment | 4 points → 1 segment (middle) |
| Tangents via control points | Tangents calculated from neighbors |
| More artistic control | More natural paths |

**Bézier:** Sculpt the curve (manual tangent control).
**Catmull-Rom:** Just place waypoints (automatic smoothing).

[hr]

[b]Closed Loops[/b]

**Challenge:** Catmull-Rom needs 4 points, but first/last segments lack neighbors.

**Solution:** **Wrap around** - use points from other end.

[color=yellow][b]Code for Closed Curves:[/b][/color]
[code]
func generate_closed_catmull_rom(control_points: Array, resolution: int = 20) -> Array:
    var curve_points = []
    var n = control_points.size()

    for i in range(n):
        var p0 = control_points[(i - 1 + n) % n]  # Wrap before
        var p1 = control_points[i]
        var p2 = control_points[(i + 1) % n]      # Wrap after
        var p3 = control_points[(i + 2) % n]      # Wrap further

        for j in range(resolution):
            var t = float(j) / float(resolution)
            var point = catmull_rom_point(p0, p1, p2, p3, t)
            curve_points.append(point)

    return curve_points
[/code]

**Modulo wrapping** creates seamless closed loop.

[hr]

[b]Applications[/b]

- **Camera paths** (smooth cinematics through waypoints)
- **Character movement** (natural interpolation between positions)
- **Animation curves** (smooth keyframe interpolation)
- **Procedural roads/rivers** (smooth paths through terrain points)
- **Trajectory prediction** (smooth motion from sparse samples)

[hr]

[b]Centripetal Catmull-Rom[/b]

**Problem:** Standard Catmull-Rom can create **loops and cusps** when control points unevenly spaced.

**Solution:** **Centripetal parameterization** - adjust t based on point spacing.

[color=yellow][b]Code:[/b][/color]
[code]
func centripetal_catmull_rom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
                             t: float, alpha: float = 0.5) -> Vector3:
    # Calculate parameter distances (not uniform)
    var t0 = 0.0
    var t1 = t0 + pow(p1.distance_to(p0), alpha)
    var t2 = t1 + pow(p2.distance_to(p1), alpha)
    var t3 = t2 + pow(p3.distance_to(p2), alpha)

    # Rescale t to segment [t1, t2]
    var t_scaled = t1 + t * (t2 - t1)

    # Recursively interpolate (de Casteljau style)
    var a1 = lerp_time(p0, p1, t0, t1, t_scaled)
    var a2 = lerp_time(p1, p2, t1, t2, t_scaled)
    var a3 = lerp_time(p2, p3, t2, t3, t_scaled)

    var b1 = lerp_time(a1, a2, t0, t2, t_scaled)
    var b2 = lerp_time(a2, a3, t1, t3, t_scaled)

    return lerp_time(b1, b2, t1, t2, t_scaled)

func lerp_time(p0: Vector3, p1: Vector3, t0: float, t1: float, t: float) -> Vector3:
    if abs(t1 - t0) < 0.0001:
        return p0
    return p0 + (p1 - p0) * ((t - t0) / (t1 - t0))

# alpha = 0.0 → uniform (standard Catmull-Rom)
# alpha = 0.5 → centripetal (no loops/cusps)
# alpha = 1.0 → chordal
[/code]

**Alpha = 0.5** prevents self-intersecting loops (most robust).

[hr]

[b]Queer Catmull-Rom[/b]

**Catmull-Rom passes through all waypoints.**

Bézier approximates - curve pulled toward control points but **doesn't touch them**.
Catmull-Rom **visits every point** - no waypoint ignored.

**This is queer presence:**
- **All points matter** (not just endpoints)
- **Every position visited** (not bypassed)
- **Path determined by context** (P0 and P3 shape curve at P1-P2, even though curve doesn't reach them)

**You are shaped by points you never touch** - P0 and P3 influence the curve between P1 and P2, yet curve never reaches them.

**Queer influence:** Shaped by histories and futures you don't directly inhabit. Your trajectory affected by what came before (P0) and what comes after (P3), even as you move through present (P1 to P2).

[hr]

[b]Tension as Affective Intensity[/b]

**Tension parameter** controls curvature:
- **Low tension:** Loose, flowing, exaggerated arcs
- **High tension:** Tight, constrained, nearly linear

**This is affective intensity:**
- **Loose tension:** Emotions flow freely, curves amplified
- **Tight tension:** Movements constrained, restrained curvature

**Tension is not stiffness** - it's how much the curve **responds** to influences.

**Queer navigation:** Sometimes you need loose curves (explore widely). Sometimes tight (stay close to path). **Tension adjusts responsiveness.**

[hr]

[b]Automatic Tangents[/b]

**Bézier:** You manually set tangent handles (explicit control).
**Catmull-Rom:** Tangents **calculated from neighbors** (implicit from context).

**Tangent at P1 = (P2 - P0) / 2** - direction determined by what's before and after.

**This is relational velocity:**
- Your direction (tangent) not chosen explicitly
- **Determined by where you've been (P0) and where you're going (P2)**
- No abstract "handle" to manipulate - only context

**Queer becoming:** Velocity shaped by relational context, not predetermined intention.

**You can't set your direction independently** - it emerges from your position within the sequence.

[hr]

[b]Centripetal: Anti-Normative Spacing[/b]

**Uniform Catmull-Rom** assumes equal spacing (can create loops if points clustered).
**Centripetal** adjusts for **actual distances** - respects non-uniform spacing.

**This is anti-normative parameterization:**
- **Doesn't assume regular intervals** (uniform spacing)
- **Adapts to actual distances** (respects irregularity)
- **Prevents pathological curves** (no loops/cusps from clustering)

**Queerness clusters unevenly** - not uniformly distributed, not regularly spaced.

**Centripetal Catmull-Rom handles this** - works with irregular spacing, doesn't force normalization.

**No forced uniformity** - works with distribution as it is.

[hr]

[color=cyan][b]Summary:[/b][/color]
Catmull-Rom splines: interpolating curves passing through all control points. 4 points (P0, P1, P2, P3) → segment P1 to P2. Tangents calculated from neighbors (automatic). Tension parameter controls curvature. vs Bézier: interpolates vs approximates, automatic vs manual tangents. Centripetal parameterization prevents loops (alpha=0.5). Applications: camera paths, animation, trajectories. Queer Catmull-Rom: all waypoints visited (presence matters), shaped by points never touched (P0, P3 influence P1-P2), tension as affective intensity, tangents from relational context not intention, centripetal respects non-uniform spacing (anti-normative). Velocity emerges from position in sequence.

'''
