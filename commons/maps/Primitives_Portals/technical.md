# 08 Portals

In Primitives_Ignorance, geometry was unmoored — shapes re-encountered as constructs rather than givens, assumptions exposed, formal mastery undermined. That map ended in productive uncertainty. This one makes the uncertainty spatial.

Walk forward. A torus frames the corridor. Then another, slightly smoother. Then another. By the time you reach the teleporter, the ring has stopped looking like a polygon.

It hasn't. That's the lesson.

## The Torus

A torus is two circles in relation. One travels around the other. The inner circle — the tube cross-section — sweeps a closed path defined by the outer circle, the ring's centerline. Two radii govern the shape: `inner_radius` sets how thick the tube is; `outer_radius` sets how far the tube's center sits from the torus's center.

In Godot, `TorusMesh` exposes both, plus two discretization parameters:

```gdscript
var torus_mesh = TorusMesh.new()
torus_mesh.inner_radius = 0.23   # tube radius
torus_mesh.outer_radius = 0.5    # ring radius
torus_mesh.rings = 6             # cross-section count along the outer circle
torus_mesh.ring_segments = 8     # vertex count per cross-section
```

`rings` controls how many cross-sections are distributed around the outer circle — how many slices the torus is divided into longitudinally. `ring_segments` controls how many vertices define each cross-section — how many sides each inner circle has.

Set `rings` to 3 and `ring_segments` to 3: a triangular prism bent into a loop, angular and structural. Increase them to 24 each: something that reads as smooth, continuous, circular. Nothing in the underlying mathematics changed. You changed how many samples the renderer takes.

A smooth torus in 3D graphics is always this — a polygon count decision. The circle itself is not in the mesh. It exists only as the limit toward which the mesh approximates. Resolution is not a property of the curve. It is a resource you allocate.

## The Portal Corridor

`combine_portals.gd` builds the map's central structure: a sequence of tori down the Z axis, each with more rings and ring_segments than the last. The architecture is the argument.

The script starts from a base torus node — `Lowrestorus` — already placed as a child in the scene with minimum segment counts. At `_ready()`, it reads that mesh, hides the original, and spawns modified copies along Z:

```gdscript
func _ready() -> void:
    _base_portal = get_node_or_null(base_path) as MeshInstance3D
    _base_mesh = _base_portal.mesh as TorusMesh
    spawn_portals()

func spawn_portals() -> void:
    _base_portal.visible = false
    var start_rings = max(_base_mesh.rings, 3)
    var start_segments = max(_base_mesh.ring_segments, 3)

    for i in range(count):
        var portal_instance := _base_portal.duplicate()
        var mesh_copy := _base_mesh.duplicate() as TorusMesh
        mesh_copy.rings = start_rings + i
        mesh_copy.ring_segments = start_segments + i * 2
        portal_instance.mesh = mesh_copy

        var transform := base_transform
        transform.origin.z += float(i) * spacing
        portal_instance.transform = transform

        add_child(portal_instance)
```

`duplicate()` matters here. Resources in Godot are reference-counted — if you modify `_base_mesh.ring_segments` directly, every portal sharing that resource changes. `.duplicate()` breaks the reference, producing an independent copy. One mesh, twenty variations, none interfering.

The increment is linear: each portal adds 1 ring and 2 ring_segments. The perceptual effect is not linear. Somewhere around ring_segments = 12, the brain stops counting edges and starts seeing a circle. That threshold is not in the math. It's in the viewer.

Portal 0: visibly faceted, recognizably angular. Portal 19: reading as smooth, apparently continuous. The corridor makes that threshold a place you walk through rather than a number you read.

The `spine_hints()` function marks this artifact with `"oversized"` and `"corridor_incompatible"` — 20 portals at 4.5m spacing span approximately 90m, five times the standard corridor length. The map was designed around this artifact's footprint, not fit into a standard template. Sometimes the geometry sets the terms.

## Approximating π

The reason ring_segments approaches "circle" is the same reason polygons approximate π.

Archimedes, third century BCE: inscribe a regular polygon inside a circle. Double its sides. Double again. The polygon's perimeter approaches the circle's circumference from below; an circumscribed polygon approaches from above. Squeeze between them. With a 96-gon, Archimedes had: `3 + 10/71 < π < 3 + 1/7`. That's 3.1408 to 3.1429.

The formula: a regular n-gon inscribed in a unit circle has perimeter `2n * sin(π/n)`. As n → ∞, this approaches 2π. Each torus cross-section is exactly this — a regular polygon with `ring_segments` sides inscribed in a circle of radius `inner_radius`.

```gdscript
# Perimeter of inscribed n-gon in unit circle
func polygon_perimeter(n: int) -> float:
    return 2.0 * n * sin(PI / float(n))

# Values:
# n=3:  5.196   (triangle, ~83% of 2π)
# n=6:  6.000   (hexagon, ~95.5% of 2π)
# n=12: 6.212   (dodecagon, ~98.9% of 2π)
# n=24: 6.265   (~99.7% of 2π)
# n=64: 6.281   (~99.97% of 2π)
# 2π:   6.283...
```

Each portal in the corridor is one step in this table made physical. You walk from the triangle approximation toward the 96-gon approximation. The circle itself — continuous, infinitely sided — is never in the GPU. It exists only as a limit.

This is not a deficiency. It's a fundamental characteristic of discrete computation. The GPU operates on finite, countable vertices. π is irrational. The gap between them is not a bug; it is the nature of representing continuous mathematics on discrete hardware. Every 3D engine in existence makes this compromise. What changes is how fine you're willing to make it.

## Limits in Time: Zeno

The portal corridor makes limits spatial. `achilles_tortoise.gd` makes them temporal.

Achilles and the Tortoise: Achilles runs faster. He starts behind. He reaches where the Tortoise was — but by then, the Tortoise has moved. He covers half the remaining distance. Then half of that. Each step halves the gap. The steps are infinite. The distance converges.

The animation models this directly:

```gdscript
func _advance() -> void:
    var n := _current_step + 1

    # A_n = L * (1 - 1/2^n) — where Achilles is after step n
    var a_z := -track_length * (1.0 - 1.0 / pow(2.0, float(n)))

    # T_n = L * (1 - 1/2^(n+1)) — where Tortoise is after step n
    var t_z := -track_length * (1.0 - 1.0 / pow(2.0, float(n + 1)))

    var tw := create_tween()
    tw.set_parallel(true)
    tw.tween_property(_achilles, "position:z", a_z, step_interval * 0.5)
        .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
    tw.tween_property(_tortoise, "position:z", t_z, step_interval * 0.5)
        .set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

    if _current_step < _markers.size():
        _markers[_current_step].visible = true
```

Each call to `_advance()` places Achilles at `A_n` and the Tortoise at `T_n`. A tick mark appears at Achilles' new position. The marks accumulate, their spacing halving each step. The visual density near the limit materializes convergence — not as a line on a graph but as a crowding of marks in space.

After ten steps the animation pauses, then resets. `step_count = 10` is ten samples of an infinite series. After ten halvings, the remaining gap is `L / 2^10 = L / 1024` — about 0.6% of the track. Visually indistinguishable from arrival. Mathematically still nonzero.

Watch carefully when the steps become imperceptibly small. That moment — where eye can no longer distinguish movement from stillness — is not the limit. It's when the discretization falls below the perceptual threshold. The limit is elsewhere: at the purple tick at the track's end, marked `limit`, unreached.

Zeno was right about the steps. He was wrong about the sum.

The resolution: geometric series. `Σ(1/2^n)` from n=1 to ∞ equals 1. Infinite terms, finite sum. Zeno assumed that infinitely many steps must take infinite time. They don't, if each step takes proportionally less time. The series converges because the steps shrink fast enough. This is what calculus eventually formalized, two millennia later.

## Continuity vs. Discretization

The portal corridor and the Achilles animation are the same paradox in different domains.

Both ask: what happens when a discrete sequence approaches a continuous value? The corridor approaches a circle. The animation approaches a position. Neither reaches its limit — not because the limit doesn't exist, but because computation is always discrete.

A render frame is a sample. A polygon vertex is a sample. `step_count = 10` takes ten samples of an infinite series. `ring_segments = 38` takes 38 samples of a circle. The continuity these sequences approach is a mathematical object — not a computational one.

The limit exists in the mathematics, not in the execution.

This is the philosophical core of computational geometry. The tools — `TorusMesh`, `ring_segments`, `pow(2.0, n)` — are discrete. The objects they model — circle, convergence, continuity — are not. The engineer's job is to choose a discretization fine enough that the gap doesn't matter.

Fine enough for what? For the viewer's perception. For the physics simulation. For the render budget. For the tolerance declared in the error analysis. "Fine enough" is always relative to a use. The circle-ness of the final portal in the corridor is not absolute. It is adequate for this corridor's purposes, as seen from this distance, rendered at this frame rate.

Archimedes stopped at 96-gons. He had enough: π ≈ 3.14185. Every computer graphics engine implicitly makes the same decision. The question is not "is this a circle?" but "is it circle enough?"

## The Dark Sphere as Reference

At position (3, 18) — roughly the midpoint of the corridor — a dark sphere hovers. `dark_sphere.gd`. It pulses slowly. It rotates. It changes very little.

Its purpose is relational. Against the portal progression, which changes on every axis — resolution, smoothness, visual complexity — the sphere holds constant. Same radius, same slow rotation, same emission range. It is the invariant that makes the portal variation legible. Transformation requires something to transform against.

```gdscript
func _process(delta: float) -> void:
    _time_elapsed += delta
    _sphere_mesh.rotation.y += rotation_speed * delta
    _sphere_mesh.rotation.x = sin(_time_elapsed * 0.4) * 0.05

    var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
    _sphere_material.emission_energy_multiplier = lerpf(pulse_min, pulse_max, pulse_t)
```

`sin()` on emission energy: a sinusoidal oscillation between `pulse_min = 0.05` and `pulse_max = 0.35`, cycling at `pulse_speed = 1.2` Hz. Not random — periodic. The sphere doesn't vary unpredictably. It breathes on a known cycle, reliably present.

It sits at the midpoint — where the portals begin to read as smooth. You pass it once, approximately where the perceptual threshold occurs, where the polygon count is high enough that the brain rounds up to circle. The sphere doesn't comment on this. It marks the location.

Its `spine_hints()` role is `"ambient"`. Not instructional. Not primary. Present. Not every object in a space is a lesson. Some are weather.

## From Portals to Melencolia

This map demonstrated that limits are real and inaccessible simultaneously. The final portal is not a circle. It is a 38-segment polygon that reads as a circle. The Archilles animation does not reach the limit. It falls below perceptual threshold and stops.

These are triumphs of approximation and also, if you look directly at them, demonstrations of permanent incompleteness. Both are true.

Primitives_Melencolia takes up the second reading. Dürer's engraving: the geometer surrounded by instruments — compass, straightedge, magic square, truncated rhombohedron — unable to proceed. All the tools of measurement, and still, orientation and meaning unresolved. The melancholy is not ignorance. It is the melancholy of someone who has mastered the tools and met the limit.

Portals staged the limit as a corridor you walk through. Melencolia stages it as an interior state. The circle was always just beyond reach. After enough portals, you stop noticing. Melencolia asks you to notice again.

The sequence isn't heading toward mastery. It's heading toward a more honest account of what mastery means — which is: knowing your approximation is adequate, not knowing it is complete.

## Possible Artifacts

**pi_approximation_track** — Visualizes the Archimedes method directly: a regular n-gon inscribed in a unit circle with a live readout of perimeter vs. 2π and the percentage gap. The map currently makes the π approximation implicit through the portal progression; this would make the relationship between polygon sides and circle measurement explicit and numerically legible. A learner leaving this map should be able to state what ring_segments = 12 means in terms of π accuracy.

**segment_slider** — A single torus with a VR-interactive ring_segments control, ranging from 3 to 64. The progression in `combine_portals` is predetermined and spatial; this would make the same parameter directly manipulable by the learner in real time. The relationship between the number and the shape becomes a felt experiment rather than an observation.

**convergence_graph** — A 3D spatial plot of `A_n = L * (1 - 1/2^n)` plotted as a curve, shown alongside the Achilles animation. The animation demonstrates the paradox experientially; the curve would make the formula's convergence behavior visible as geometry — the diminishing returns, the horizontal asymptote, the limit as a line that the curve approaches but doesn't cross.

**ring_count_labels** — Labels on each portal showing current rings and ring_segments values as the learner passes through. The visual progression from angular to smooth is evident; the numeric progression is currently invisible. A learner who understands the Archimedes connection would benefit from watching both simultaneously — seeing `ring_segments = 12` on the same portal where the octagonal facets give way to apparent roundness.