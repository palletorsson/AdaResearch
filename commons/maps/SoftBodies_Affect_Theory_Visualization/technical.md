# A single radiolarian in a display case — where procedural geometry meets biological form

The sequence's penultimate map shifts from physics simulation to biological visualization. A single radiolaria artifact generates a procedural specimen — a silica skeleton built from CSG boolean operations on spheres, cylinders, and tori. The map is an intimate gallery: small (7x9 grid), low spatial temperature (0.4), no interactive tools. The learner walks around the specimen and looks.

## Procedural Radiolarian Generation

The radiolaria artifact constructs biological forms through CSG (Constructive Solid Geometry) composition. A base sphere is modified by union, subtraction, and intersection with secondary primitives to produce specimens that look grown rather than designed.

```gdscript
# From radiolaria @identity:
# CSG boolean operations (UNION, SUBTRACTION) on spheres, cylinders, and tori
# generating radiolaria, spiky forms, lattice spheres, ringed forms, and pollen

@export var number_of_forms: int = 9
@export var grid_size: int = 3
@export var spacing: float = 2.5
@export var spikiness_probability: float = 0.5
```

Six form types are selected per grid cell by `randi() % 6`:

**Radiolaria** — A sphere with spikes radiating at golden-ratio angles derived from icosahedron vertices. The golden ratio (phi = (1 + sqrt(5)) / 2) distributes points on a sphere with near-optimal uniformity, the same principle that sunflower seeds use.

```gdscript
# Golden-ratio spike placement on a sphere:
# Fibonacci lattice: each point at angle = i * golden_angle
var golden_angle := PI * (3.0 - sqrt(5.0))
for i in range(num_spikes):
    var theta := acos(1.0 - 2.0 * (i + 0.5) / float(num_spikes))
    var phi := golden_angle * i
    var dir := Vector3(
        sin(theta) * cos(phi),
        sin(theta) * sin(phi),
        cos(theta)
    )
    _add_spike(center, dir, spike_length, spike_radius)
```

**Spiky forms** — Spheres with elongated cylindrical projections. Each spike is a CSG cylinder unioned with the base sphere. The `spikiness_probability` parameter gates how many spikes each form receives — at 0.0, smooth spheres only; at 1.0, every specimen bristles.

**Lattice spheres** — CSG subtraction carves holes in a sphere, creating a cage-like structure reminiscent of radiolarian silica shells. The subtraction primitives are small spheres or cylinders placed at lattice points on the main sphere's surface.

```gdscript
# Lattice sphere via subtraction:
func _create_lattice_sphere(center: Vector3, radius: float,
                              hole_count: int) -> CSGCombiner3D:
    var combiner := CSGCombiner3D.new()
    var base := CSGSphere3D.new()
    base.radius = radius
    combiner.add_child(base)

    for i in range(hole_count):
        var dir := _fibonacci_point_on_sphere(i, hole_count)
        var hole := CSGCylinder3D.new()
        hole.radius = radius * 0.15
        hole.height = radius * 2.5
        hole.operation = CSGShape3D.OPERATION_SUBTRACTION
        hole.look_at_from_position(center + dir * radius, center)
        combiner.add_child(hole)
    return combiner
```

**Ringed forms** — Tori (CSG torus shapes) combined with spheres, producing Saturn-like specimens or multi-ring structures. The torus wraps around the base sphere at varying inclination angles.

**Pollen grains** — Spheres with small bump protrusions uniformly distributed across the surface, mimicking the micro-texture of real pollen. Each bump is a small CSG sphere unioned to the surface.

**Hybrid forms** — Combinations of the above, where multiple modification passes (spikes + holes + rings) create complex specimens. The random feature gating via `randf()` means each sub-feature is independently probable, creating combinatorial variety.

## The Golden Ratio and Biological Geometry

The golden-angle distribution of spikes is not an aesthetic choice — it is the solution to a mathematical problem: how to place N points on a sphere with maximum mutual distance. The Fibonacci lattice approximates this optimum, and the same principle governs phyllotaxis in plants, seed packing in sunflowers, and spine distribution in real radiolarians.

```gdscript
# Phyllotaxis: the divergence angle between successive organs
# Optimal divergence angle = 360 / phi^2 ≈ 137.5 degrees
# This is the golden angle — it never repeats, never aligns,
# producing the densest possible packing without periodicity

var golden_angle_degrees := 360.0 / (PHI * PHI)  # ≈ 137.508
```

The golden ratio enters not because beauty requires it, but because optimization does. The most efficient packing produces the most visually striking pattern. Beauty and function converge because they solve the same problem. Haeckel drew radiolarians as art precisely because their geometry is optimal — and optimal geometry is unavoidably beautiful.

## The Silica Skeleton: Soft Process, Hard Result

The radiolarian's skeleton is the endpoint of a soft body process. In life, the single-celled organism's protoplasm — a soft, fluid material — shapes the silica deposition. Surface tension at the protoplasm-water interface determines where mineral accumulates. The skeleton is not built by a constructor; it crystallizes at the boundary where soft matter meets its environment.

This bridges the entire Soft Bodies sequence. The jelly cube deformed under force and recovered. The cloth draped under gravity and wind. The playground merged soft physics with procedural growth. Now the radiolarian presents the terminal case: a form that was soft during formation and rigid in its final state. The skeleton is a fossil of the forces that shaped it — surface tension, osmotic pressure, thermal gradients, all frozen in silica.

The artifact models only the final form — the rigid skeleton, built from CSG primitives. The growth process is implicit. The viewer sees the result and must infer the process. This is deliberate: the gap between the procedural generation (which is instantaneous, computed in `_ready()`) and the biological reality (which unfolds over the organism's lifetime) invites the learner to think about what is missing. The form is present. The history is absent. The artifact is a snapshot of a process that the simulation did not run.

## The Display Case: Intimate Scale

The map is 7x9 cells — the smallest in the Soft Bodies sequence. One specimen, one display case, one viewing experience. The spatial temperature is 0.4 — cool, contemplative, unhurried. The spawn point faces the specimen directly.

```json
"dimensions": {
    "width": 7,
    "depth": 9,
    "max_height": 1
},
"metadata": {
    "spatial_temperature": 0.4
}
```

The design is museum-like. The learner walks around the specimen, observing from multiple angles. The CSG geometry casts shadows. The spikes create parallax as the viewpoint shifts. The lattice holes reveal interior structure when the viewer moves to align their sightline with the perforations.

No interaction. No sliders. No manipulation. This is a map for looking. After five maps of squeezing, throwing, and squishing, the sequence pauses and asks the learner to simply observe a form that soft processes created. The restraint is the point.

## CSG Performance and Limitations

CSG operations in Godot are computed at scene load, not per-frame. The boolean operations (union, subtraction, intersection) produce a triangle mesh that the renderer draws as static geometry. This means the radiolarian is computationally cheap once generated — no ongoing physics, no spring calculations, no collision response.

```gdscript
# CSG generation is a build-time cost:
# 6 forms × (1 base sphere + 5-20 modifier primitives) = 30-120 CSG operations
# Each operation: mesh boolean → typically 100-500ms
# Total generation time: 3-10 seconds in _ready()
# After generation: static mesh, zero per-frame cost
```

The limitation is mesh quality. CSG booleans on complex compositions can produce non-manifold geometry — edges shared by more than two faces, holes in the surface, degenerate triangles. Godot's CSG implementation handles most cases but can produce visual artifacts at intersection seams. For a museum display piece, these artifacts are minor. For physics simulation, they would be unacceptable — another reason the radiolarian is observation-only.

## Connection to Haeckel

Ernst Haeckel published *Kunstformen der Natur* (Art Forms in Nature) in 1904 — one hundred lithographic plates of organisms, many of them radiolarians. The drawings are scientifically accurate and aesthetically transcendent. Haeckel saw no boundary between science and art because the organisms themselves made no such distinction. Their geometry is simultaneously functional (structural integrity, buoyancy, filtration) and beautiful (symmetry, fractal self-similarity, golden-ratio proportions).

The artifact makes this bridge explicit. The procedural generation uses mathematical principles (golden-ratio distribution, CSG booleans, random feature gating) that produce forms visually reminiscent of Haeckel's plates. The algorithm did not study Haeckel. It converged on similar geometry because it solves similar problems — distributing features on a sphere, creating lattice structures, combining simple primitives into complex wholes. The convergence is not coincidence. It is the same mathematics.
