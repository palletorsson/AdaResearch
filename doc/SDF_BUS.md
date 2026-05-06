# SDF Bus — the transition contract between form generators

## Problem

Twenty form-generator editors (`commons/scenes/editors/`) each express a different principle — CA, L-system, noise, sweep, boolean, parametric surface. They produce incompatible outputs (ArrayMesh, MultiMesh, shape trees, procedural). There's no way to **transition between principles** without breaking geometry.

A creature that is 60% L-system and 40% sweep is unrepresentable today. Not because the design is wrong — because the intermediate representation doesn't exist.

## Contract

Every form generator implements **one method**:

```gdscript
func signed_distance(p: Vector3) -> float
```

Returns the signed distance from world-space point `p` to the nearest surface of the form. Negative inside, positive outside. That's the whole protocol.

This is not a new idea — it's the SDF (signed distance field) — but applied as the **lingua franca** across editors instead of a single rendering trick.

## Why SDF wins for expression

- **Always manifold.** The zero-isosurface of any well-behaved SDF is a closed manifold. No broken geometry, no self-intersection, no degenerate triangles.
- **Blendable by construction.** `lerp(sdf_a(p), sdf_b(p), t)` is always a valid SDF. Two forms can morph into each other smoothly at every value of `t ∈ [0, 1]`, and every in-between is renderable.
- **Composable.** Union = `min(a, b)`. Intersection = `max(a, b)`. Subtraction = `max(a, -b)`. Smooth union with radius `k` gives rounded transitions. These are the primitive transitions.
- **Resolution-independent.** The SDF is a continuous function. Render at low resolution for preview, high resolution for production. No retopology needed.

## Base class — `FormSDF`

```gdscript
class_name FormSDF
extends Resource

## Core: distance from p to nearest surface. Negative inside, positive outside.
func signed_distance(_p: Vector3) -> float:
    push_error("FormSDF subclasses must override signed_distance()")
    return INF

## Bounding box of the form in world space — used to size voxel grids
## during mesh extraction. Return a generous AABB; tighter is cheaper.
func get_aabb() -> AABB:
    return AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))

## Optional: batch sampling. Default implementation falls back to per-point.
## Subclasses can override for vectorized field evaluation.
func sample_grid(origin: Vector3, size: Vector3, res: Vector3i) -> PackedFloat32Array:
    var out := PackedFloat32Array()
    out.resize(res.x * res.y * res.z)
    var step := size / Vector3(res)
    for z in res.z:
        for y in res.y:
            for x in res.x:
                var p := origin + Vector3(x, y, z) * step
                out[z * res.y * res.x + y * res.x + x] = signed_distance(p)
    return out
```

## Transition operators

Static library of pure-math functions in `SdfOps`:

```gdscript
# Boolean
static func union(a: float, b: float) -> float: return minf(a, b)
static func intersect(a: float, b: float) -> float: return maxf(a, b)
static func subtract(a: float, b: float) -> float: return maxf(a, -b)

# Smooth (k controls rounding radius, usually 0.1 – 1.0)
static func smooth_union(a: float, b: float, k: float) -> float
static func smooth_intersect(a: float, b: float, k: float) -> float

# Transition — the one we care about most
## Linear morph from a to b as t goes 0 → 1. Always a valid SDF.
static func morph(a: float, b: float, t: float) -> float:
    return lerp(a, b, clampf(t, 0.0, 1.0))

## Smooth morph with non-linear easing — sharper transition near t=0 and t=1.
static func morph_smooth(a: float, b: float, t: float) -> float

# Field ops
static func displace(d: float, amount: float) -> float
static func inflate(d: float, r: float) -> float: return d - r
static func shell(d: float, thickness: float) -> float
```

## Per-principle SDF subclasses

One subclass per generator family. Each stores the editor's parameters and implements `signed_distance()`:

| Principle | Class | SDF strategy |
|---|---|---|
| Sweep / tube | `SweepSDF` | Distance to capsule chain |
| L-system / growth | `GrowthSDF` | Union of capsule SDFs along branches |
| CA form | `CASurfaceSDF` | Distance to nearest live cell + voxel shape |
| Reaction-diffusion | `RDSurfaceSDF` | Heightfield from concentration, implicit surface |
| Noise terrain | `NoiseTerrainSDF` | Plane + displacement from noise |
| Parametric surface | `ParametricSDF` | Distance to sampled surface (approx) |
| Boolean / CSG | `CSGSdf` | Recursive ops on child SDFs |
| Fractal | `FractalSDF` | Kaleidoscopic IFS (classic SDF fractal) |
| Base geometry | `PrimitiveSDF` | Exact: sphere, box, torus, capsule |

Each subclass is authored in its existing editor. The editor's preview renders the SDF; "save" writes a `.tres` resource that any other tool can load.

## Rendering

Two visualizations for a single SDF:

1. **Voxel preview** (fast, for editor UI) — sample the SDF on a grid, render filled voxels for negative values as a MultiMesh. No mesh extraction. Good for tuning, not for final render.
2. **Mesh extraction** (for final output) — marching cubes or surface nets, producing a manifold ArrayMesh. Expensive; run on save.

## Transition example

```gdscript
var ca: CASurfaceSDF = preload("res://mymap/ca_form.tres")
var growth: GrowthSDF = preload("res://mymap/growth.tres")

# Render a form that is 40% CA, 60% L-system growth
var t: float = 0.6
var blend := BlendedSDF.new(ca, growth, t)
# blend.signed_distance(p) = lerp(ca.signed_distance(p), growth.signed_distance(p), t)

# In the artifact:
for p in voxel_grid:
    var d := blend.signed_distance(p)
    if d < 0: place_voxel(p)
```

The resulting geometry is always manifold. No generator was broken. The **transition itself is an expressible form**.

## Why this doesn't destroy the editors

Each editor remains the primary way to author **its** principle. The SDF is the interchange — it's what flows between them. An author uses `ca_form_editor` to design a CA form, saves it as SDF, then in a pipeline editor blends it with a sweep SDF authored elsewhere. The editors keep their voices; the SDF is the medium.

## Priority rollout

1. **Ship `FormSDF` + `SdfOps`** — the protocol and the math (no generators yet).
2. **Prototype two concrete SDFs** — `CASurfaceSDF` and `GrowthSDF`. Prove a blend renders.
3. **Voxel preview renderer** — lightweight MultiMesh visualization of `signed_distance < 0`.
4. **Marching cubes** — when production meshes are needed. Scoped separately.
5. **Migrate editors** — one per commit, each adding `to_sdf() -> FormSDF` method. Editors keep their existing rendering; SDF is additive.
6. **Blend editor** — new UI that takes two SDF resources, a morph slider, and renders the result. Validates the whole bus.

## Main tradeoff

SDF accuracy vs. sharpness. Forms with sharp features (CA's grid cells, L-system's thin branches) soften at low SDF resolution. High resolution costs memory and sample time. Mitigation: each SDF subclass can override `sample_grid()` with an analytic-exact or accelerated implementation; only the slow fallback is the generic per-point one.
