# NonEuclidean_Spaces — Technical

## Two Geometries from One Denial

When the parallel postulate falls, it does not leave a vacuum. It leaves a spectrum. The fifth postulate's negation splits into two cases:

- **Hyperbolic**: Through a point not on a given line, infinitely many lines can be drawn that never intersect the given line. Gaussian curvature K < 0.
- **Elliptic**: Through a point not on a given line, no parallel line exists — every pair of lines eventually meets. Gaussian curvature K > 0.

Euclidean geometry sits at K = 0, a single point on a continuous axis. Flatness is not the default. It is the degenerate case.

## Gaussian Curvature

Gauss's *Theorema Egregium* (1827) established that curvature is an intrinsic property of a surface — it can be measured by creatures living on the surface without reference to any embedding space. The Gaussian curvature K at a point is the product of the two principal curvatures:

```
K = kappa_1 * kappa_2
```

- K > 0: the surface curves the same way in all directions (sphere, dome). Principal curvatures have the same sign.
- K < 0: the surface curves oppositely in perpendicular directions (saddle, Pringle chip). Principal curvatures have opposite signs.
- K = 0: at least one principal curvature is zero (plane, cylinder).

The angle sum of a geodesic triangle encodes curvature directly via the Gauss-Bonnet theorem:

```
alpha + beta + gamma = pi + K * A
```

where A is the triangle's area. On a sphere (K > 0), triangles are "fat" — their angles exceed 180 degrees. On a saddle (K < 0), triangles are "thin" — their angles fall short of 180 degrees.

## Map Architecture: Split Dual Landscape

The NonEuclidean_Spaces map is a 15x13 grid, max height 4. Its layout is a split dual: the left half forms a hyperbolic bowl (heights descending toward center), the right half forms an elliptic dome (heights rising toward center), connected by a narrow bridge at the midline.

The structure layer encodes the curvature through height gradients:
- **Left bowl (hyperbolic)**: heights descend from 2 at the rim to 1 at the bowl floor, with void (0) at the edges — a concave depression.
- **Right dome (elliptic)**: heights rise from 1 at the rim through 2, 3, and up to 4 at the peak — a convex protrusion.
- **Bridge (rows 6-8, col 6-8)**: a narrow isthmus at height 2, connecting the two geometries.

The asymmetry between the halves is deliberate. Hyperbolic space feels expansive — you descend into openness. Elliptic space feels convergent — you climb toward a peak where all paths meet. The spatial experience mirrors the mathematical content.

## Artifact Analysis

### hyperbolic_surface (row 4, col 4)
**@identity essence**: `y = K(x^2 - z^2) — saddle surface with negative Gaussian curvature K < 0`

A room-scale saddle surface generated procedurally. The implementation creates a `SurfaceTool` mesh by iterating over a grid of (x, z) coordinates and computing `y = curvature * (x*x - z*z)`. The curvature parameter defaults to -0.3, producing a pronounced saddle. Geodesic lines on this surface diverge — two initially parallel paths curve away from each other, visible as colored arcs on the mesh.

The critical parameter is `curvature`, which controls the depth of the saddle. More negative values produce more dramatic divergence. The mesh is rendered with a blue-tinted material, visually distinguishing it from the elliptic surface's warm tones.

### elliptic_surface (row 4, col 10)
**@identity essence**: `K > 0 — positive Gaussian curvature; parallel lines converge, triangles have angle sum > 180 degrees`

A dome surface generated as a hemisphere section. The implementation uses spherical coordinates:
```
x = radius * sin(theta) * cos(phi)
y = radius * cos(theta)
z = radius * sin(theta) * sin(phi)
```

The radius parameter controls the curvature: smaller radius means tighter curvature (more dramatic convergence). Geodesics on the sphere are great circles, and any two great circles intersect at exactly two antipodal points. The artifact shows geodesic lines that start parallel at the equator and converge toward the poles.

### curvature_slider (row 6, col 7)
**@identity essence**: `K in [-1, +1] — Gaussian curvature as continuous parameter`

Positioned at the bridge between the two halves, this slider parametrizes the entire space of constant-curvature geometries. Drag left for K < 0 (hyperbolic), center for K = 0 (Euclidean), right for K > 0 (elliptic).

The slider emits a `curvature_changed(value)` signal that both surface artifacts can connect to. When connected, dragging the slider morphs the surfaces in real time: the saddle flattens through K = 0 and inflates into a dome; the dome deflates through flatness and inverts into a saddle. The transition is continuous — there is no discontinuity between geometries, only a smooth parameter sweep.

The implementation maps the slider's normalized position [0, 1] to curvature [-1, +1] via linear interpolation. The color gradient shifts from deep blue (K = -1) through white (K = 0) to warm red (K = +1).

### poincare_disk (row 8, col 3)
**@identity essence**: `geodesics as circular arcs meeting the boundary at right angles; the boundary circle IS infinity`

The Poincare disk model maps the entire infinite hyperbolic plane into a finite circular disk. The implementation draws:
- A boundary circle (the "circle at infinity")
- Geodesics as circular arcs that intersect the boundary at right angles
- Hyperbolic tilings (optional) showing how tiles become infinitely small near the boundary

The disk radius parameter sets the display size. The key insight is metric distortion: equal hyperbolic distances near the center appear as longer Euclidean distances than equal hyperbolic distances near the boundary. Objects near the edge are the same "size" in hyperbolic terms but appear infinitely compressed in the Euclidean embedding.

The model demonstrates that hyperbolic geometry can be consistently embedded within Euclidean geometry — which is the core of Beltrami's consistency proof. If Euclidean geometry is consistent, so is hyperbolic geometry, because here it is, living inside it.

### riemann_sphere (row 8, col 11)
**@identity essence**: `C union {infinity} — the complex plane plus a point at infinity, wrapped onto a sphere via stereographic projection`

The Riemann sphere wraps the infinite complex plane onto a finite sphere using stereographic projection:
```
For point (x, y, z) on the sphere (excluding north pole):
z_complex = (x + iy) / (1 - z)
```

The north pole maps to the point at infinity. The implementation renders a translucent sphere with projected grid lines from the complex plane visible on its surface. Great circles on the sphere correspond to lines and circles in the complex plane.

This artifact complements the Poincare disk: where the disk compresses hyperbolic infinity into a finite region, the Riemann sphere compresses Euclidean-and-beyond infinity onto a closed surface. Both are models that demonstrate how alternative geometries can be visualized within familiar frameworks.

## The Curvature Spectrum

The three constant-curvature geometries form a one-parameter family indexed by K:

| K | Geometry | Parallels | Triangle Sum | Model |
|---|----------|-----------|-------------|-------|
| K < 0 | Hyperbolic | Infinitely many | < 180 deg | Poincare disk |
| K = 0 | Euclidean | Exactly one | = 180 deg | Standard plane |
| K > 0 | Elliptic | None | > 180 deg | Riemann sphere |

The curvature slider makes this family navigable. The learner does not read about three separate geometries — they drag a single parameter and watch one geometry dissolve into another. The continuity is the argument: there is nothing special about K = 0 except that it is familiar.

## Metric Tensors and the Machinery Beneath

Each constant-curvature geometry has a distinct metric tensor that determines distances and angles. In two dimensions:

**Euclidean** (K = 0):
```
ds^2 = dx^2 + dy^2
```

**Hyperbolic** (K = -1, Poincare disk model):
```
ds^2 = 4(dx^2 + dy^2) / (1 - x^2 - y^2)^2
```

**Elliptic** (K = +1, spherical):
```
ds^2 = d(theta)^2 + sin^2(theta) d(phi)^2
```

The metric tensor is the engine that converts the parallel postulate from a logical axiom into a lived spatial experience. When the learner walks the hyperbolic bowl and feels space expanding, they are traversing a metric where distances grow near boundaries. When they climb the elliptic dome and feel convergence, they are in a metric where great circles pull together. The map's height gradients are a crude but effective proxy for these metric effects.

## Independence and Consistency

The existence of these models proves two things:

1. **Independence**: The parallel postulate cannot be derived from the other four, because both its assertion and its negation produce consistent systems.
2. **Relative consistency**: If Euclidean geometry is consistent, so are the alternatives. The models live inside Euclidean space — any contradiction in hyperbolic geometry would propagate into a contradiction in Euclidean geometry.

This is the same model-theoretic technique that will recur throughout the sequence: constructing alternative worlds within familiar ones to establish independence. Godel used it. Cohen used it. The method was born here, in the geometry of curvature.

## Metric Tensor Sampling

```gdscript
# Hyperbolic metric in Poincaré disc model
static func hyperbolic_metric(p: Vector2) -> float:
    var denom: float = 1.0 - p.length_squared()
    return 4.0 / (denom * denom)  # scale factor

# Elliptic (spherical) metric
static func spherical_metric(p: Vector2) -> float:
    return 1.0 / (1.0 + p.length_squared())

# Geodesic distance in hyperbolic plane
static func hyperbolic_distance(a: Vector2, b: Vector2) -> float:
    var a_norm: float = a.length_squared()
    var b_norm: float = b.length_squared()
    var diff: float = (a - b).length_squared()
    return acosh(1.0 + 2.0 * diff / ((1.0 - a_norm) * (1.0 - b_norm)))
```

## Sum of Angles in Curved Spaces

```gdscript
# In hyperbolic geometry, triangle angle sums are less than PI.
# In spherical geometry, they exceed PI.
# The deficit/excess is proportional to the triangle's area times its curvature.
static func hyperbolic_triangle_angle_sum(vertices: Array) -> float:
    var excess: float = spherical_excess(vertices, -1.0)  # negative curvature
    return PI + excess  # less than PI when excess is negative

static func spherical_triangle_angle_sum(vertices: Array) -> float:
    return PI + spherical_excess(vertices, 1.0)  # greater than PI

static func spherical_excess(vertices: Array, curvature: float) -> float:
    var area: float = compute_triangle_area(vertices)
    return curvature * area
```
