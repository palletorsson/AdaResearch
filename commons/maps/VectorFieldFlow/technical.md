# Every point in space carries an arrow, and walking through them is the definition of flow

In VectorBasics you learned what a single vector is — magnitude, direction, components. In VectorSubtraction you learned what the difference between two vectors means — displacement, the arrow from here to there. In VectorCrossProduct you escaped the plane of two vectors to find a perpendicular third. In Vectors_1 you added arrows tip-to-tail and watched them combine. Every one of those maps dealt with individual vectors: one, two, three at a time, discrete objects you could name and point at.

VectorFieldFlow abandons that discreteness. There are no longer a few arrows. There are arrows everywhere. A vector field assigns a vector to every point in space. Not some points — every point. The field is a function: hand it a position, receive a vector. The arrow at `(2, 0, 3)` may point left. The arrow at `(2, 0, 4)` may point up. The field decides. Position in, vector out.

This is the pivot from particle thinking to field thinking. Previous maps asked "what does this vector do?" This map asks "what does space itself do?" A force field does not wait for an object — it permeates space, assigning instructions to any position. Drop a particle anywhere and the field tells it where to go.

The environment E in QFEP terms is no longer passive geometry. It is the field: structured, directional, active at every coordinate.

## The Field Function

A vector field in three dimensions is a function F that takes a position vector and returns another vector:

```
F(p) -> v
```

Position `p = (x, y, z)` goes in. Vector `v = (vx, vy, vz)` comes out. The output vector might represent force, velocity, acceleration, wind — the interpretation depends on context. The mathematics is identical regardless.

The VectorFieldFlow artifact defines its field function directly:

```gdscript
func _field_value(position: Vector3) -> Vector3:
    var swirl = Vector3(
        -position.z,
        FIELD_VERTICAL_OSCILLATION * sin(elapsed * FIELD_VERTICAL_FREQUENCY),
        position.x
    )
    var radial = position * 0.1
    return (swirl - radial).limit_length(2.5)
```

Two components compose the field. The swirl term creates rotation: the x-output depends on `-position.z` and the z-output depends on `position.x`. This is the signature of a vortex — at any point, the field pushes perpendicular to the radial direction, curling around the origin. The y-output oscillates over time, adding a gentle vertical breathing to the flow.

The radial term pulls inward — `position * 0.1` points outward from the origin, and subtracting it creates a weak inward drift. The result is a spiral: arrows swirl around the center while slowly tightening.

`limit_length(2.5)` caps the magnitude. Without it, positions far from the origin produce arbitrarily large vectors. The field remains well-behaved everywhere — no infinities, no singularities. A design choice, not a mathematical necessity. Real fields blow up at certain points. This one stays bounded for readability.

The field function is pure: same position, same elapsed time, same output. No hidden state. No memory. The field does not know what visited a point before. It only knows where a point is and what time it is.

This statelessness is fundamental. The complexity of a particle's trajectory does not come from a complex field — it comes from the field being evaluated at a sequence of positions, each determined by the previous evaluation. Simple rules, complex paths.

Compare this to the dark_sphere, which carries internal state — `_time_elapsed`, accumulated `rotation.y`, pulsing emission. The sphere remembers its history. The field does not. A field is a snapshot function, rebuilt from scratch every query. The sphere is a process, accumulating over time.

Both exist in the same scene. The difference in architecture is the difference between environment and object.

## Sampling the Field on a Grid

A continuous field cannot be drawn — it assigns vectors to uncountably many points. Visualization requires sampling: evaluate the field at discrete positions and draw arrows there.

```gdscript
const GRID_RANGE := 4
const GRID_SPACING := 0.9

func _create_field_vectors():
    for x in range(-GRID_RANGE, GRID_RANGE + 1):
        for z in range(-GRID_RANGE, GRID_RANGE + 1):
            var origin = Vector3(x * GRID_SPACING, 0.0, z * GRID_SPACING)
            var arrow = spawn_vector(
                origin, Vector3.ZERO,
                Color(0.3, 0.8, 1.0, 1.0), "Field", false
            )
            field_vectors.append(arrow)
```

A 9-by-9 grid of sample points on the xz-plane, each separated by 0.9 units. At every point, an arrow spawns with initial vector `Vector3.ZERO` — a placeholder. The real vectors come from the update loop. The `false` argument disables grab interaction — these arrows are read-only indicators, not manipulable objects.

Eighty-one arrows. The continuous field has infinitely many, but eighty-one is enough to reveal the pattern. The eye interpolates between samples. A vortex pattern is legible from surprisingly few arrows if they are spaced evenly and colored consistently.

The grid spacing matters: too tight and the arrows overlap into visual noise; too wide and the flow structure disappears between samples. 0.9 units is the balance point for this field's scale — large enough to show individual arrows cleanly, small enough that the vortex reads as a coherent rotation rather than a scattering of unrelated directions.

Each frame, every arrow updates to reflect the current field value at its position:

```gdscript
func _update_field_vectors():
    for arrow in field_vectors:
        var local_origin = arrow.position
        var value = _field_value(local_origin)
        update_vector(arrow, value)
```

The field is time-varying — the vertical oscillation term depends on `elapsed`. So the arrows breathe, tilt, shift subtly each frame. The grid is static; the vectors it displays are not. This distinction matters: the sample points do not move, but the vectors at those points change. The field evolves. The sampling grid observes.

## Particles in the Field

A field alone is structure without story. The story begins when something enters the field and responds to it. The VectorFieldFlow artifact drops a particle — a small emissive sphere — into the field and lets the local vector at the particle's position drive its motion.

```gdscript
var particle_velocity: Vector3 = Vector3.ZERO
var particle_position: Vector3 = Vector3.ZERO

const PARTICLE_FOLLOW := 0.35
const PARTICLE_DAMPING := 0.985
const PARTICLE_VERTICAL_LIMIT := 0.35
```

Three constants govern the particle's behavior. `PARTICLE_FOLLOW` controls how quickly velocity aligns with the field. `PARTICLE_DAMPING` applies soft friction each frame. `PARTICLE_VERTICAL_LIMIT` constrains how far the particle drifts off the xz-plane. Two state variables — position and velocity — carry the particle's history forward frame by frame.

The update function runs every frame:

```gdscript
func _update_particle(delta: float):
    var sample = _field_value(particle_position)
    sample.y *= 0.5
    particle_velocity = particle_velocity.lerp(sample, PARTICLE_FOLLOW)
    particle_velocity *= PARTICLE_DAMPING
    particle_position += particle_velocity * delta
```

Four operations in sequence. Sample the field at the particle's current position. Attenuate the vertical component — `sample.y *= 0.5` — keeping motion mostly in the xz-plane for clarity. Lerp velocity toward the sampled vector. Apply damping and integrate position.

The `lerp` is crucial. The particle does not instantly adopt the field's vector. `PARTICLE_FOLLOW` is 0.35 — each frame, velocity moves 35% toward the field's instruction. This creates inertia. The particle overshoots curves, spirals wider than the field alone would dictate, then tightens as the field's influence accumulates.

The damping factor of 0.985 ensures that velocity never grows unboundedly — each frame sheds 1.5% of speed, a soft friction that prevents runaway acceleration.

This is the Euler integration method: `position += velocity * delta`. Each frame advances position by a small step along the current velocity. The method is first-order — it uses only the current velocity, not its rate of change. Higher-order integrators (Runge-Kutta, Verlet) produce more accurate trajectories.

Euler is chosen here because its error is visible and instructive. The particle overshoots corners, drifts off the exact streamline. These imperfections teach that numerical integration is approximation, not truth. The field defines a perfect flow; the discrete simulation follows it imperfectly.

The particle also respects vertical bounds:

```gdscript
if absf(particle_position.y) > PARTICLE_VERTICAL_LIMIT:
    particle_position.y = clampf(
        particle_position.y,
        -PARTICLE_VERTICAL_LIMIT,
        PARTICLE_VERTICAL_LIMIT
    )
    particle_velocity.y *= -0.25
```

When the particle drifts beyond 0.35 units above or below the xz-plane, its y-position is clamped and its y-velocity is reversed at 25% strength — a lossy bounce. The field's vertical oscillation pushes the particle up and down; the clamp keeps it readable. The field says "go up." The boundary says "not that far." The compromise is a damped oscillation near the limit.

## Streamlines and Trajectories

The path a particle traces through a field is a streamline (in a steady field) or a pathline (in a time-varying one). The VectorFieldFlow field varies with time — the vertical oscillation depends on `elapsed` — so the particle's path is technically a pathline. The distinction matters in fluid dynamics.

For this map, the operational point is simpler: the trajectory is determined entirely by where the particle starts and what the field does at each position it visits.

Two particles released from different positions follow different paths. This is the field's essential property — it encodes spatial variation. Consider two sample positions:

```gdscript
# At position (2, 0, 0):
# swirl = (-0, oscillation, 2)  -> pushes along +z
# radial = (0.2, 0, 0)         -> pulls slightly toward origin
# result: strong z-push, weak x-pull

# At position (0, 0, 2):
# swirl = (-2, oscillation, 0)  -> pushes along -x
# radial = (0, 0, 0.2)         -> pulls slightly toward origin
# result: strong negative-x push, weak z-pull
```

Same field, different positions, different instructions. The particle does not choose its path. The field and the starting position choose it.

This is determinism in its purest spatial form — given the field and an initial condition, the trajectory is fixed. No randomness, no choice, no ambiguity.

Pressing R in the artifact resets the particle to the origin:

```gdscript
func _input(event):
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_R:
            reposition_particle(Vector3.ZERO)
            restart_particle()
        if event.keycode == KEY_SPACE:
            particle_velocity = Vector3.ZERO
```

Pressing Space zeroes velocity without moving the particle — an isolated view of the field's local instruction, uncontaminated by momentum from elsewhere.

Reset to origin shows the full spiral from center. Freeze in place shows the local field's immediate effect. Two controls, two ways to interrogate the same field.

## Divergence and Curl: What Fields Do Locally

Two properties characterize what a field does in the neighborhood of a point. Neither requires a formula to understand intuitively.

Divergence measures whether the field spreads out from a point or converges toward it. Stand at a point and watch the arrows around you: if they all point away, divergence is positive — the field is a source there. If they all point inward, divergence is negative — a sink. If they merely pass through with no net expansion or contraction, divergence is zero.

The VectorFieldFlow artifact's radial term (`position * 0.1`, subtracted) creates a weak negative divergence — a gentle inward drift everywhere. The swirl term alone has zero divergence; it pushes things around the origin without compressing or expanding them. Combined, the field is a draining vortex — matter spirals inward.

Curl measures rotation. Stand at a point and watch the arrows around you: if they circulate — clockwise or counterclockwise — the field has curl there.

The swirl term `(-z, 0, x)` is pure curl. It generates a vortex around the y-axis. The curl vector points along y — the axis of rotation. Curl is a vector, not a scalar: it has both a magnitude (how fast the local rotation is) and a direction (which axis the rotation wraps around).

The cross product from VectorCrossProduct is the mathematical engine behind curl — the curl of a field at a point is defined by cross-differentiating the field components. The ij-k notation from VectorBasics returns here: curl is computed as a determinant involving the basis vectors and the partial derivatives of the field. The formalism connects back through the entire sequence.

The artifact does not display divergence or curl numerically. It displays the field. The learner's eyes compute the rest. Seeing arrows spiral inward is understanding negative divergence plus curl simultaneously, without naming either quantity. The visual precedes the vocabulary.

In later maps, divergence and curl gain formulas and computational teeth. Here they are perceptual — patterns the eye detects before the hand writes an equation. The current grid spacing balances both: tight enough to read rotation, wide enough to track convergence.

## The Directional Flow Corridor

The map layout is a directional flow corridor — elongated along one axis (depth 10), narrower on the other (width 6). This shape matters. A square room has no preferred direction. A corridor has inherent flow — the eye and the body move along its length. The learner walks through the field rather than standing outside it.

The field's arrows align with the corridor at some points and cross it at others. Where the vortex sends arrows along the corridor, walking feels natural. Where it sends them against, the spatial dissonance is instructive — the field has its own logic, independent of the room.

The dark_sphere sits within the field at a fixed position. It does not respond to the field — its rotation and pulsation are self-contained:

```gdscript
# dark_sphere's _process — independent of any field
_sphere_mesh.rotation.y += rotation_speed * delta
_sphere_mesh.rotation.x = sin(_time_elapsed * 0.4) * 0.05
```

The sphere occupies a point where the field has a definite value. The learner reads the field arrows nearby and asks: if the sphere were free, where would it go? The sphere is the test particle that chose not to move. Its stillness in a flowing field is itself information.

The info panel displays the particle's state in real time:

```gdscript
func _update_info():
    var field_here = _field_value(particle_position)
    var builder := []
    builder.append("Position = (%.2f, %.2f, %.2f)" % [
        particle_position.x, particle_position.y, particle_position.z
    ])
    builder.append("Velocity = (%.2f, %.2f, %.2f)" % [
        particle_velocity.x, particle_velocity.y, particle_velocity.z
    ])
    builder.append("Field(position) = (%.2f, %.2f, %.2f)" % [
        field_here.x, field_here.y, field_here.z
    ])
    info_label.text = "\n".join(builder)
```

Three lines. Position — where the particle is. Velocity — how it is moving. Field(position) — what the field instructs at that point.

When velocity and field agree, the particle is following the flow faithfully. When they diverge, inertia is carrying the particle against the field's local instruction.

The gap between velocity and field value is the signature of the lerp and damping — the particle's memory of where it has been, resisting where the field says to go now. Watch the numbers while the particle rounds a curve: the field vector rotates before the velocity does. The lag is the lerp. The slowdown is the damping. Both visible in the data before they are visible in the trajectory.

## From Discrete Vectors to Continuous Space

The sequence from VectorBasics through Vectors_1 built understanding of individual vectors: one arrow, two arrows, their sum, their cross product. Each had a name, a purpose, a specific pair of endpoints. VectorFieldFlow dissolves that specificity. No single arrow matters. The pattern matters — the spatial structure that emerges when every point speaks at once.

A vortex is not one vector. It is the collective behavior of a field, visible only when many arrows are seen together. A sink is not a single inward-pointing arrow. It is a pattern of convergence across a region. The unit of meaning shifts from the vector to the field.

This shift from object to field mirrors a deeper shift in physics. Newtonian mechanics tracks particles: position, velocity, force on each body. Field theory tracks the fields themselves: electromagnetic, gravitational, quantum. The particle is a probe; the field is the reality.

VectorFieldFlow does not teach field theory. It teaches field perception — the ability to look at a space full of arrows and see structure: rotation, convergence, flow direction, stagnation points.

The particle tracing its spiral is a reading device. The field is the text. The 81 arrows on the grid are the typeface — discrete samples of a continuous message.

Between any two arrows, the field continues. Between any two sample points, the flow persists. The grid reveals the field the way a mesh reveals a surface — through enough samples to let interpolation do the rest.

The system state S in QFEP terms is the particle's position and velocity. The environment E is the field — a function defined over all of space, independent of the particle. The dynamics are the update rule: sample the field, lerp velocity, integrate position.

The feedback loop between S and E is one-directional here. The particle reads the field; the field ignores the particle. In later maps (VectorForces, the Forces sub-sequence), this coupling becomes bidirectional — objects generate fields that other objects respond to.

For now, the field is sovereign and the particle is obedient.

## Possible Artifacts

**streamline_tracer** — The learner taps or points at any position in the field and a particle spawns there, tracing its streamline forward in time. Multiple particles coexist, each following its own path from its own starting position. The visual result is a family of curves revealing the field's global structure — convergence basins, vortex centers, separatrices where nearby paths diverge. Starting positions differ by centimeters; final trajectories differ by meters.

**field_composer** — Presents two or three basis fields (uniform, radial, vortex) with slider-controlled weights. The learner mixes them in real time and watches the arrow grid update. Superposition — that the sum of two fields is itself a field — becomes tactile. Combining a uniform rightward field with a vortex produces a stagnation point where the two cancel. The learner finds that point by adjusting sliders, discovering fixed points through construction rather than calculation.

**divergence_curl_probe** — A small disc the learner moves through the field. At each position, two indicators: a shrinking or expanding ring showing local divergence, and a spinning arrow showing local curl direction and strength. Quantities computed numerically from field samples in a small neighborhood. No formula — only geometric behavior. The learner discovers that the vortex core has maximum curl and zero divergence, while the radial inflow region has negative divergence and diminishing curl.
