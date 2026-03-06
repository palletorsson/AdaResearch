# Flat surface where motion meets resistance and the spring's stored energy finally dissipates

Springs pull back. Friction holds still. Forces_3 introduced restoring force — F = -kx, oscillation, equilibrium disturbed and re-sought. The spring stores energy, returns it, stores it again. Nothing is lost. The oscillation persists because every joule that enters the spring comes back out. This is idealized. This is not how surfaces work.

Friction is the first dissipative force in the sequence. Energy that enters friction does not come back. Kinetic energy converts to heat, and heat disperses. The oscillation from Forces_3 — a ball on a spring bouncing forever — decays when friction enters the system. The spring still pulls, but friction eats the return. Each cycle loses amplitude. Eventually the system rests. Not because the spring stopped pulling, but because friction consumed the energy that sustained the motion.

## Static Friction: The Threshold That Holds

A block sits on a surface. Push it gently. Nothing happens. Push harder. Still nothing. The block does not move until the applied force exceeds a threshold — the maximum static friction force:

```
F_s <= mu_s * N
```

`mu_s` is the coefficient of static friction — a dimensionless number that depends on both surfaces. `N` is the normal force — the perpendicular reaction of the surface to the object's weight. On flat ground, `N = mg`. Static friction matches the applied force exactly, up to the limit. Push with 3 Newtons and static friction pushes back with 3 Newtons. Push with 5 and it pushes back with 5. It is reactive, not constant.

```gdscript
@export var mass: float = 2.0
@export var mu_static: float = 0.6
var gravity := 9.8
var normal_force: float

func _ready() -> void:
    normal_force = mass * gravity  # N = mg on flat surface

func try_push(applied_force: Vector3) -> Vector3:
    var max_static := mu_static * normal_force
    var horizontal := Vector3(applied_force.x, 0.0, applied_force.z)

    if horizontal.length() <= max_static:
        # Static friction cancels the push entirely
        return Vector3.ZERO
    else:
        # Threshold exceeded — object begins to move
        return horizontal
```

Below the threshold, the net horizontal force is zero. The object does not accelerate. Does not creep. Does not budge. Static friction is not a constant force — it is a constraint that adjusts to oppose whatever pushes against it, perfectly, until it cannot. The inequality `F_s <= mu_s * N` encodes this: static friction can be anything from zero to its maximum. Only at the breaking point does it reach `mu_s * N`.

The dark_sphere on this map's surface demonstrates the threshold. Apply a force to it. Below `mu_s * N`, the sphere stays locked. The force arrows on the free body diagram — applied force rightward, friction leftward — balance exactly. Net force: zero. Acceleration: zero. The First Law governs.

## The Normal Force: Surface Speaks Back

Normal force is the surface's response to being pressed. Place an object on flat ground and gravity pulls it downward at `mg`. The ground pushes back upward at `mg`. Third Law — equal and opposite. The normal force prevents the object from falling through the floor.

```gdscript
# On flat ground
var weight := mass * gravity  # force of gravity downward
var normal := weight           # surface pushes upward equally
# Net vertical force: weight - normal = 0
# Object does not accelerate vertically
```

On a flat surface, `N = mg` exactly. On an inclined surface, the normal force is `mg * cos(theta)` — only the component perpendicular to the surface counts. Friction depends on `N`, so friction depends on inclination. A steeper slope means less normal force, which means less friction, which means easier sliding. The relationship is geometric: the angle of the surface decomposes gravity into two components, one that drives sliding (parallel) and one that drives the normal force (perpendicular).

```gdscript
# On an inclined plane at angle theta
var theta := deg_to_rad(30.0)
var gravity_parallel := mass * gravity * sin(theta)      # drives sliding
var gravity_perpendicular := mass * gravity * cos(theta)  # sets normal force
var normal := gravity_perpendicular
var max_friction := mu_static * normal
```

At 30 degrees with `mu_s = 0.6`: `gravity_parallel = mg * 0.5`, `max_friction = 0.6 * mg * 0.866 = 0.52 * mg`. The parallel component exceeds the maximum friction. The object slides. At 20 degrees: `gravity_parallel = mg * 0.342`, `max_friction = 0.6 * mg * 0.94 = 0.564 * mg`. Friction wins. The object holds. The critical angle — where the object just begins to slide — satisfies `tan(theta) = mu_s`. For `mu_s = 0.6`, that angle is about 31 degrees.

## Kinetic Friction: Constant Resistance During Motion

Once the object moves, static friction releases and kinetic friction takes over. Kinetic friction is simpler — a constant force opposing the direction of motion:

```
F_k = mu_k * N
```

No inequality. No matching. A fixed magnitude, always opposing velocity. `mu_k` is the coefficient of kinetic friction, and it is always less than `mu_s` for the same pair of surfaces. Starting motion costs more than sustaining it. This discontinuity — the drop from static to kinetic at the moment of breakaway — is why objects lurch when they start sliding. The holding force vanishes and the resisting force that replaces it is weaker.

```gdscript
@export var mu_kinetic: float = 0.4
var velocity := Vector3.ZERO
var is_moving := false

func apply_kinetic_friction(delta: float) -> void:
    if velocity.length() < 0.001:
        velocity = Vector3.ZERO
        is_moving = false
        return

    var friction_magnitude := mu_kinetic * normal_force
    var friction_direction := -velocity.normalized()
    var friction_force := friction_direction * friction_magnitude

    # a = F/m
    var deceleration := friction_force / mass
    velocity += deceleration * delta

    # Prevent friction from reversing the velocity
    if velocity.dot(friction_direction) > 0.0:
        velocity = Vector3.ZERO
        is_moving = false
```

The friction direction is always `-velocity.normalized()` — opposite the motion. The magnitude is `mu_k * N` — constant regardless of speed. Kinetic friction does not care how fast the object moves. A block sliding at 1 m/s and a block sliding at 100 m/s experience the same frictional force (assuming the same surfaces and normal force). The deceleration is constant: `a = mu_k * g`. On flat ground with `mu_k = 0.4`, that is `0.4 * 9.8 = 3.92 m/s^2`.

The final check — `velocity.dot(friction_direction) > 0.0` — prevents overshoot. Without it, friction could decelerate the object past zero and push it backward, which is unphysical. Friction opposes motion. It cannot create motion. The dot product detects when velocity has flipped direction relative to the friction vector, and clamps to zero.

## The Static-to-Kinetic Transition

The moment of breakaway is a discontinuity. Below threshold: no motion, friction equals applied force. Above threshold: motion begins, friction drops to `mu_k * N`. The force required to sustain motion is less than the force required to start it.

```gdscript
func update_friction(applied: Vector3, delta: float) -> void:
    var horizontal := Vector3(applied.x, 0.0, applied.z)
    var max_static := mu_static * normal_force

    if not is_moving:
        if horizontal.length() > max_static:
            is_moving = true
            # Transition: subtract kinetic friction, not static
            var net := horizontal - horizontal.normalized() * (mu_kinetic * normal_force)
            var accel := net / mass
            velocity += accel * delta
        # else: static friction cancels applied force, nothing moves
    else:
        apply_kinetic_friction(delta)
        position += velocity * delta
```

The `if not is_moving` branch handles the static regime. Once the threshold breaks, `is_moving` flips to true and the system transitions to kinetic. The applied force now contends with `mu_k * N` instead of `mu_s * N` — a smaller opponent. The object accelerates. If the applied force is removed, kinetic friction alone decelerates the object back to rest, and `is_moving` returns to false.

This transition resembles a phase change. Below threshold: solid-like behavior, no flow, forces balance. Above threshold: fluid-like behavior, continuous motion, energy dissipating. The QFEP framework describes exactly such transitions — the lambda parameter crossing a critical value triggers a shift between qualitatively different regimes. Static friction is the ordered phase. Kinetic friction is the dissipative phase. The threshold is the bifurcation point.

## Friction as Energy Sink

Springs conserve energy. Friction destroys it. The work done by friction equals force times distance, and that work converts entirely to thermal energy — heat that disperses into the environment and cannot be recovered by the mechanical system.

```gdscript
func compute_friction_work(distance_traveled: float) -> float:
    # Work = F_k * d (force times displacement)
    var friction_force := mu_kinetic * normal_force
    return friction_force * distance_traveled
```

A block sliding 5 meters with `mu_k = 0.4` and mass 2 kg on flat ground: `F_k = 0.4 * 2.0 * 9.8 = 7.84 N`. Work = `7.84 * 5.0 = 39.2 J`. That energy is gone from the system. The block had `0.5 * 2.0 * v^2` joules of kinetic energy at the start. When friction's total work equals the initial kinetic energy, the block stops.

Stopping distance from initial speed `v_0`:

```
d = v_0^2 / (2 * mu_k * g)
```

Derived from setting kinetic energy equal to friction work: `0.5 * m * v_0^2 = mu_k * m * g * d`. Mass cancels — stopping distance is independent of mass, just as free-fall acceleration is. A heavy block and a light block, pushed to the same initial speed on the same surface, slide the same distance before stopping. The heavy block exerts more friction force but has proportionally more kinetic energy. The ratio holds.

```gdscript
func stopping_distance(initial_speed: float) -> float:
    return (initial_speed * initial_speed) / (2.0 * mu_kinetic * gravity)
    # At v_0 = 10 m/s, mu_k = 0.4: d = 100 / (2 * 0.4 * 9.8) = 12.76 m
```

## Friction Meets the Spring

Connect the spring from Forces_3 to a surface with friction. The system oscillates — but each cycle loses energy. The spring stores potential energy and converts it to kinetic. Friction converts kinetic to heat. The spring cannot recover what friction has taken. Amplitude decays. The oscillation dies.

```gdscript
@export var spring_k: float = 10.0
@export var mu_kinetic: float = 0.3
var equilibrium_pos := Vector3(4.0, 0.0, 0.0)
var velocity := Vector3.ZERO

func _physics_process(delta: float) -> void:
    var displacement := position - equilibrium_pos
    var spring_force := -spring_k * displacement  # F = -kx

    var friction_force := Vector3.ZERO
    if velocity.length() > 0.001:
        friction_force = -velocity.normalized() * (mu_kinetic * normal_force)

    var net_force := spring_force + friction_force
    var acceleration := net_force / mass
    velocity += acceleration * delta
    position += velocity * delta
```

Without friction (`mu_k = 0`), position oscillates as a pure sine wave — simple harmonic motion, amplitude constant forever. With friction, the sine wave's envelope shrinks. Each pass through equilibrium is slower than the last. The amplitude decreases roughly linearly for Coulomb (dry) friction, unlike viscous damping which decreases exponentially. The distinction matters: dry friction brings the system to a hard stop at finite time. Viscous damping (which Forces_5 introduces through drag) decays asymptotically — approaching zero but never reaching it.

The spring-with-friction system illustrates irreversibility entering the sequence. Forces_3's spring was conservative — time-reversible, energy-preserving. Run the simulation backward and the spring works identically. Friction breaks this symmetry. Run the simulation backward and friction would add energy instead of removing it, accelerating the system instead of decelerating it. The arrow of time appears with friction. Dissipation is the mechanism. Heat is the symptom.

## Coefficient as Surface Property

The coefficient of friction `mu` encodes the interaction between two surfaces. It belongs to neither surface alone — it characterizes the pair. Rubber on concrete: `mu_s ~ 0.8`. Steel on ice: `mu_s ~ 0.03`. The same block on different surfaces slides differently. The same surface under different blocks slides differently.

```gdscript
# Surface material lookup
var surface_mu := {
    "ice":       { "static": 0.03, "kinetic": 0.01 },
    "wood":      { "static": 0.4,  "kinetic": 0.2 },
    "rubber":    { "static": 0.8,  "kinetic": 0.6 },
    "sandpaper": { "static": 0.9,  "kinetic": 0.75 },
}

func get_friction_coefficients(surface_name: String) -> Dictionary:
    return surface_mu.get(surface_name, { "static": 0.5, "kinetic": 0.3 })
```

On ice, the dark_sphere barely decelerates — `mu_k = 0.01` means almost zero friction, almost zero energy loss per meter. The sphere coasts. On sandpaper, it stops within a body length. The physics loop is identical. Only the coefficient changes. One number transforms the behavior from frictionless glide to abrupt halt.

The intent identifies this gap: a friction_surface_demo where adjustable `mu` values show the same push producing different outcomes on different surfaces. The coefficient is abstract until compared across materials. Ice vs rubber is the comparison that makes `mu` tangible.

## Friction in the Force Accumulator

Forces_2 introduced the force accumulator pattern — collect forces, sum them, divide by mass, integrate. Friction slots into this pattern without modifying the architecture:

```gdscript
var forces: Array[Vector3] = []

func _physics_process(delta: float) -> void:
    # Gravity
    forces.append(Vector3(0.0, -mass * gravity, 0.0))

    # Normal force (on ground)
    if position.y <= ground_y:
        forces.append(Vector3(0.0, mass * gravity, 0.0))

        # Kinetic friction (only while moving horizontally)
        if velocity.length() > 0.001:
            var f_k := mu_kinetic * normal_force
            forces.append(-velocity.normalized() * f_k)

    var net := Vector3.ZERO
    for f in forces:
        net += f

    var accel := net / mass
    velocity += accel * delta
    position += velocity * delta
    forces.clear()
```

Three forces: gravity down, normal up, friction opposing horizontal motion. The net vertical force is zero on the ground (gravity and normal cancel). The net horizontal force is kinetic friction alone, decelerating the slide. The accumulator does not distinguish friction from gravity from spring force — they are all `Vector3` values summed together. The abstraction established in Forces_1 absorbs friction without expansion.

The QFEP feedback term operates here. Friction depends on velocity — its direction is always `-velocity.normalized()`. The force depends on the state it modifies. This is feedback: the system's motion determines the force that opposes that motion. Faster motion does not produce stronger friction (that distinction belongs to drag in Forces_5), but friction's direction tracks velocity continuously. The feedback is directional, not magnitudinal.

Forces_5 extends this dissipation principle into fluids. Air resistance and drag scale with velocity — the faster the object moves, the harder the medium pushes back. Friction is the constant tax. Drag is the progressive tax. Together they define the two regimes of resistance that govern every object moving through the physical world.

## Possible Artifacts

**friction_surface_demo** -- A flat track divided into four material zones: ice, wood, rubber, sandpaper. The dark_sphere launches horizontally at configurable speed. As it crosses each zone boundary, the coefficient changes and the deceleration shifts visibly. Velocity arrows shrink at different rates per zone. Side readout shows current `mu_k`, friction force magnitude, and remaining kinetic energy. Exports for launch speed, zone length, and per-zone coefficients. The primary artifact gap identified in the intent.

**static_threshold_rig** -- A block on a flat surface with a horizontal force arrow that grows as the learner increases applied force via slider. Below `mu_s * N`, a matching friction arrow grows in opposition. At the threshold, the friction arrow snaps to the shorter kinetic value and the block lurches forward. The discontinuity between static and kinetic friction becomes visible as the sudden mismatch between applied and resisting force. Exports for mass, `mu_s`, `mu_k`, and force ramp rate.

**damped_spring_oscillator** -- The Forces_3 spring system with an added friction surface beneath the mass. Traces position over time as a decaying sinusoidal curve. A toggle switches friction off to compare damped and undamped oscillation side by side. Energy bar shows kinetic, potential, and cumulative heat loss — the three-way accounting that makes irreversibility concrete. Exports for spring constant `k`, mass, `mu_k`, and initial displacement.
