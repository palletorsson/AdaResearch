# Where drag filled volumes, attraction and repulsion reach across empty space

Terminal velocity in Forces_5 emerged from velocity-dependent resistance — the medium pushing back proportional to speed. Drag requires a medium. Remove the air and drag vanishes. But gravity does not vanish in vacuum. Two masses separated by nothing still accelerate toward each other. Electric charges separated by vacuum still repel or attract. These are action-at-a-distance forces — forces that operate without contact, across empty space. The governing law is the inverse square: double the distance, quarter the force. This single relationship unifies gravitational attraction, electrostatic interaction, and the falloff of light intensity under one geometric principle.

## The Inverse-Square Law

Two masses attract each other with a force proportional to their product and inversely proportional to the square of the distance between them:

```
F = G * m1 * m2 / r²
```

`G` is the gravitational constant — approximately 6.674 x 10^-11 N m² kg^-2. `m1` and `m2` are the masses. `r` is the distance between their centers. The force is always attractive. Gravity only pulls.

Coulomb's law for electric charges mirrors the structure exactly:

```
F = k * q1 * q2 / r²
```

`k` is Coulomb's constant. `q1` and `q2` are the charges. The sign matters: like charges (both positive, both negative) produce positive force — repulsion. Opposite charges produce negative force — attraction. Gravity has one behavior. Electrostatics has two. The equation is the same; the sign of the product determines whether the force vector points toward or away.

In both cases, `r²` sits in the denominator. The force weakens with the square of the distance — not linearly, not cubically, but quadratically. Move twice as far away: one quarter the force. Three times: one ninth. Ten times: one hundredth. The inverse square is steep near the source and shallow far from it. Close objects interact strongly. Distant objects barely notice each other.

This is not an approximation. It is a consequence of geometry — the surface area of a sphere grows as 4πr², so the intensity of anything radiating uniformly from a point dilutes at exactly that rate.

Imagine a source emitting force lines in all directions equally. At distance r, those lines pass through a sphere of area 4πr². At distance 2r, the same number of lines pass through a sphere four times as large. The density of lines — force per unit area — drops by a factor of four. The inverse square is the geometry of spherical spreading. Any isotropic point source in three-dimensional space obeys it.

## Computing Attraction in Code

The `example_3_2` artifact computes gravitational attraction between movers and a central attractor each frame:

```gdscript
func _process(delta: float) -> void:
    for mover in _movers:
        var dir := (_attractor.position - mover.position).normalized()
        var force := dir * attractor_strength
        mover.apply_force(force)
        mover.angular_velocity *= angular_damping
        mover.update(delta)
```

Three operations unfold in sequence. The displacement vector from the mover to the attractor — `_attractor.position - mover.position` — gives both direction and distance. Normalizing extracts pure direction. Scaling by `attractor_strength` produces the force vector. The mover accelerates toward the attractor.

This is a simplified gravity model. The actual inverse-square law divides by distance squared, which the artifact omits — `attractor_strength` acts as constant pull regardless of range. A physically accurate version computes the distance and divides:

```gdscript
var displacement := _attractor.position - mover.position
var distance := displacement.length()
if distance > 0.01:
    var direction := displacement / distance
    var magnitude := G * attractor_mass * mover_mass / (distance * distance)
    var force := direction * magnitude
    mover.apply_force(force)
```

The guard `distance > 0.01` prevents division by near-zero. As `r` approaches zero, `1/r²` approaches infinity — the mathematical singularity at the core of the inverse-square law. Physical reality resolves this because real objects have finite size and overlap before distance reaches zero. Simulation resolves it with a minimum distance threshold.

The `spring_system` artifact uses the same pattern in its `update_physics` method: compute displacement, check for near-zero distance, then apply the force formula.

The distance calculation requires magnitude — `displacement.length()` — which involves a square root. But unlike the drag optimization in Forces_5 where `length_squared()` sufficed for comparison, the inverse-square force needs the actual distance value both for dividing the displacement (normalization) and for the denominator. The square root is unavoidable here.

Each mover-attractor pair costs one `length()` call per frame. For N movers and one attractor, that is N square roots per frame. For N movers attracting each other mutually, it becomes N(N-1)/2 — the pairwise count. Eight movers produce 28 pairs. Sixty-four movers produce 2016. The cost grows quadratically with particle count.

Gravitational simulation is expensive not because the math is hard but because every pair interacts. Real N-body codes use tree algorithms (Barnes-Hut) to reduce the scaling from O(N²) to O(N log N). The artifact's eight movers need no such optimization. But the quadratic scaling explains why galaxy simulations require supercomputers.

The `spring_system` artifact demonstrates the general pattern for taming the singularity:

```gdscript
func update_physics():
    var direction = mass2.position - mass1.position
    var current_length = direction.length()

    if current_length > 0:
        direction = direction.normalized()
        var displacement = current_length - rest_length
        var force_magnitude = stiffness * displacement
        var force = direction * force_magnitude

        mass1.apply_force(force)
        mass2.apply_force(-force)
```

The conditional `current_length > 0` guards against zero-distance normalization. For inverse-square forces specifically, a softening parameter replaces the hard threshold:

```gdscript
var force_magnitude := G * m1 * m2 / (distance * distance + softening)
```

Adding a small constant `softening` to the denominator caps the maximum force. At large distances, `softening` is negligible — the force behaves as a true inverse square. At very small distances, `softening` dominates — the force plateaus instead of diverging. The simulation admits it cannot resolve physics below a certain length scale.

The Forces_5 `force_field_visualizer` used exactly this technique for its point charge field: `field_strength / (dist * dist + 0.01)`. The `0.01` is a softening parameter. It appears wherever an inverse-square law meets a discrete simulation. N-body gravitational codes, electrostatic particle simulations, smoothed particle hydrodynamics — all employ softening. The value depends on the simulation's scale and the minimum meaningful separation between objects.

## Attraction Produces Orbits

A straight-line pull toward a central mass does not always produce a straight-line collision. If the attracted object carries tangential velocity — velocity perpendicular to the line connecting it to the attractor — the result is curved motion. Enough tangential speed and the object misses the attractor, swings around, and returns. An orbit.

The `example_3_2` artifact initializes movers with tangential velocities:

```gdscript
for i in num_movers:
    var angle := (float(i) / num_movers) * TAU
    var radius := randf_range(0.2, 0.35)
    m.position = Vector3(
        cos(angle) * radius,
        0.5 + randf_range(-0.1, 0.1),
        sin(angle) * radius
    )
    m.velocity = Vector3(
        -sin(angle) * 0.3,
        randf_range(-0.05, 0.05),
        cos(angle) * 0.3
    )
```

Each mover starts at a position defined by `cos(angle)` and `sin(angle)` — a point on a circle around the attractor. Its initial velocity uses `-sin(angle)` and `cos(angle)` — the tangent to that circle. Position is radial. Velocity is tangential. The negative sign on the sine component ensures the velocity is perpendicular to the position vector, pointing along the circular path.

This perpendicularity is what produces orbits. A force directed inward (toward the attractor) combined with velocity directed sideways (tangent to the orbit) curves the path without stopping the motion. The force changes the velocity's direction without reducing its magnitude — or rather, it reduces the radial component while the tangential component persists. The object falls toward the attractor and simultaneously moves sideways fast enough to miss it. Continuous falling plus continuous missing equals orbit.

The balance is precise. Too little tangential speed and the object spirals inward and collides. Too much and it escapes — the attractor cannot bend the path enough to close the loop. At exactly the right speed for a given distance, the orbit is circular: every point equidistant from the center. At slightly different speeds, the orbit becomes elliptical — closer and farther in a repeating oval.

Kepler described these shapes empirically. Newton derived them from the inverse-square law. The code produces them from the same force computation running every frame.

The `angular_damping` parameter in the artifact bleeds energy from the system:

```gdscript
mover.angular_velocity *= angular_damping
```

With `angular_damping` at 0.98, each frame removes 2% of angular velocity. Over time, orbits spiral inward — the movers lose tangential speed, fall closer, and eventually collide with or orbit tightly around the attractor. Without damping, a balanced initial condition produces a stable orbit indefinitely. With damping, the orbit decays.

This mirrors physical reality: friction, radiation, and tidal forces drain orbital energy from real satellites. The ISS loses altitude to atmospheric drag and requires periodic reboosts. Damping is not always a simple scalar multiplier, but the principle holds — energy out, orbit shrinks.

## Pointing in the Direction of Motion

The `example_3_3` artifact shows how attraction-driven motion determines orientation. A cone-shaped mover receives time-varying thrust and rotates to face its velocity vector:

```gdscript
func update(delta: float) -> void:
    velocity += acceleration
    velocity = velocity.limit_length(max_speed)
    position += velocity * delta * 60.0
    acceleration = Vector3.ZERO

    if velocity.length() > 0.01 and is_instance_valid(root):
        var target_pos := position + velocity
        root.look_at_from_position(root.position, target_pos, Vector3.UP)
        root.rotate_object_local(Vector3.RIGHT, -PI / 2)
```

The mover calculates a target position one velocity-step ahead — `position + velocity` — and rotates to face it using `look_at_from_position`. The additional rotation by `-PI/2` around the local X axis corrects for the cone mesh's default orientation (Godot cylinders point along Y; the cone needs to point along Z after the look-at).

This orientation logic connects force, velocity, and facing. The force changes velocity. Velocity determines direction of motion. Visual orientation follows velocity. The object does not rotate because something tells it to turn. It rotates because its velocity changed, and it always faces where it is going.

The `velocity.length() > 0.01` guard prevents orientation snap when velocity is near zero — `look_at` with a near-zero direction vector produces erratic rotations. Below the threshold, the mover holds its last known orientation. The same magnitude guard pattern from the force calculations, applied here to visual alignment.

## Spring Forces as Restoring Attraction

The `spring_system` artifact bridges from Forces_3's spring mechanics to distance-dependent attraction. A spring connecting two masses exerts force proportional to displacement from rest length — Hooke's law — but direction depends on relative positions, computed the same way as gravitational direction:

```gdscript
var direction = mass2.position - mass1.position
var current_length = direction.length()
direction = direction.normalized()
var displacement = current_length - rest_length
var force_magnitude = stiffness * displacement
var force = direction * force_magnitude

mass1.apply_force(force)
mass2.apply_force(-force)
```

When `current_length > rest_length`, displacement is positive, and the force pulls the masses together — attraction. When `current_length < rest_length`, displacement is negative, and the force pushes them apart — repulsion. The same equation produces both behaviors depending on the sign of displacement.

Springs are bipolar: they attract when stretched, repel when compressed.

Gravity attracts only. Electrostatics attracts or repels based on charge sign. Springs attract or repel based on displacement sign. Three systems, three variations on the same directional force computation: find the vector between objects, compute a magnitude from some law, apply equal and opposite forces. The structure is identical. The law filling the magnitude slot changes.

The `spring_system` applies damping by scaling velocity directly:

```gdscript
for mass in masses:
    if not mass.is_fixed:
        mass.velocity *= damping
```

A damping factor of 0.95 removes 5% of velocity per frame. Combined with the restoring force, this produces damped oscillation — masses bounce around rest positions with decreasing amplitude until they settle. Underdamped systems oscillate and decay. Overdamped systems creep toward equilibrium without oscillating. Critically damped systems reach equilibrium in minimum time. The `damping` parameter controls which regime the system occupies.

## Fields: Force as Spatial Property

Newton computed gravity between two masses. The field reframes the question. Instead of asking "what force does mass A exert on mass B," the field asks "what force would any test mass experience at this point in space?" The field exists everywhere, whether or not a second mass is present to feel it.

The gravitational field of a mass `M` at distance `r` is:

```
g = G * M / r²
```

This is force per unit mass — the acceleration any object experiences at that distance. Place a 1 kg test mass there and it accelerates at `g`. Place a 10 kg mass and it feels 10 times the force but accelerates at the same rate, because `a = F/m = g`. The field value is acceleration. It depends only on the source mass and position, not on the test object.

```gdscript
func gravitational_field(source_mass: float, position: Vector3,
        source_position: Vector3) -> Vector3:
    var r := position - source_position
    var dist := r.length()
    if dist < min_distance:
        return Vector3.ZERO
    var direction := -r.normalized()
    return direction * G * source_mass / (dist * dist)
```

The negative sign on `r.normalized()` ensures the field points toward the source — gravity attracts. For electrostatics, a positive charge produces a field pointing outward; a negative charge produces a field pointing inward. The field direction encodes whether the source attracts or repels.

This is the conceptual shift from contact to field. Forces_1 through Forces_5 computed forces between specific pairs — push this block, pull that mass, resist this velocity. The field formulation decouples source and responder: the source generates a field everywhere, and any object entering responds according to its own properties (mass for gravity, charge for electrostatics). The field mediates.

Action at a distance troubled Newton — how does the Moon know where Earth is? Fields resolve this by making force local. The Moon responds to the gravitational field at its own position, a field that propagates from Earth at finite speed. In the Newtonian approximation, propagation is instantaneous. In general relativity, it travels at the speed of light. The simulation uses the Newtonian version — field values update instantly each frame.

The field concept also resolves a subtlety about superposition. Multiple sources each generate their own field. The total field at any point is the vector sum of all individual contributions. A test mass at position P feels the gravitational pull of every source simultaneously, each contributing a vector, all summed into one net field vector.

Superposition means the fields add. Two equal masses on opposite sides of a point produce zero net field at that point. Move slightly off-center and one mass is closer, its contribution larger, and a net field emerges pointing toward the nearer source. The `example_3_2` artifact computes a simplified version: each mover feels one source. A full N-body version sums fields from all other movers plus the attractor — superposition in code as a loop over sources.

## Attractive and Repulsive: The Sign of the Product

Gravity is always attractive because mass is always positive — `m1 * m2` is always positive. But in Coulomb's law, charges can be positive or negative. The product `q1 * q2` determines the sign of the force:

```gdscript
func coulomb_force(q1: float, q2: float, r: Vector3) -> Vector3:
    var dist := r.length()
    if dist < min_distance:
        return Vector3.ZERO
    var direction := r.normalized()
    var magnitude := k_coulomb * q1 * q2 / (dist * dist)
    return direction * magnitude
```

When `q1` and `q2` share sign (both positive or both negative), `magnitude` is positive, and the force points along `direction` — away from the other charge. Repulsion. When the signs differ, `magnitude` is negative, and the force reverses — toward the other charge. Attraction.

One equation, two behaviors, distinguished only by sign.

The code does not branch on sign. No `if` statement asks whether charges are like or unlike. The multiplication handles it. Positive times positive is positive. Negative times negative is positive. Positive times negative is negative. The algebra encodes the physics. Signed quantities carry information that would otherwise require conditional logic.

The `example_3_2` movers experience only attraction. Adding a charge model lets some movers repel each other while all are attracted to the center. Clusters form: like-charged movers spread apart while unlike pairs draw together, orbiting a central mass.

This is where the QFEP system reveals its recursive nature. Each mover evaluates forces from every other body. Each force changes velocity. Each velocity changes position. Each position changes distances, which change forces. The loop iterates every frame. Stable orbits, clustered groups, ejected outliers — all emerge from the same pairwise inverse-square law applied recursively across N bodies. The final configuration is not designed. It is the fixed point of the iterative force computation, the pattern the system settles into when no rearrangement further reduces energy.

## Possible Artifacts

**inverse_square_visualizer** — A draggable test mass near a fixed source. Force magnitude displays as a vector arrow whose length shrinks with the square of the distance. A real-time graph plots force versus distance alongside the 1/r² curve. Drag the test mass closer and the arrow grows rapidly; drag it away and the arrow collapses. At half the distance, the arrow quadruples. The visual makes the steepness of the inverse square tangible — close interaction dominates, distant interaction vanishes.

**charge_interaction_sandbox** — Multiple particles with adjustable charge (positive, negative, neutral) on a plane. Like charges repel, opposites attract, neutrals feel no electrostatic force. Toggle charge signs and the system rearranges: opposite pairs collapse together, like pairs scatter, mixed groups form orbiting clusters. Coulomb's law computed pairwise each frame. A force diagram overlay shows the net force vector on a selected particle — the sum of all pairwise interactions.

**orbit_decay_demo** — A single mover orbiting a central attractor with adjustable damping. At zero damping, the orbit is stable and elliptical. As damping increases, the orbit spirals inward. A trail renders the spiral. An energy bar shows kinetic and potential energy draining over time. At high damping the mover plunges directly inward. At low damping the spiral takes many revolutions to decay. The damping slider makes the relationship between energy loss and orbit shape visible — the trajectory is the energy budget drawn in space.
