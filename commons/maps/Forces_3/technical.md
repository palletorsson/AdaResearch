# The coil that remembers where it was and fights to return

Forces_2 traced the arc that gravity writes — a parabola, clean and eternal, one constant force pulling everything earthward. But parabolas never end on their own. A projectile under gravity alone would fall forever. Something must arrest the fall, store the energy, push back. That something is a spring.

A spring is a force that depends on position. Gravity is constant — it pulls at 9.8 m/s^2 whether the object sits at rest or hurtles downward. A spring is contextual. Its force is zero at equilibrium, weak near equilibrium, strong far from it. Displacement determines opposition. The further the stretch, the harder the return. This positional dependence is the conceptual leap from Forces_2: the first force that reads the state of the world before deciding how hard to push.

## Hooke's Law: F = -kx

Robert Hooke's insight, compressed to three symbols. The force a spring exerts is proportional to its displacement from equilibrium and opposite in direction.

```gdscript
extends Node3D

@export var mass: float = 1.0
@export var spring_constant: float = 4.0
@export var equilibrium_y: float = 3.0

var velocity := Vector3.ZERO

func _physics_process(delta: float) -> void:
    var displacement := position.y - equilibrium_y
    var spring_force := Vector3(0.0, -spring_constant * displacement, 0.0)
    var acceleration := spring_force / mass
    velocity += acceleration * delta
    position += velocity * delta
```

`displacement` is the signed distance from equilibrium. Positive means the mass sits above equilibrium — the spring pulls down. Negative means below — the spring pushes up. The minus sign in `-spring_constant * displacement` encodes this opposition. Stretch produces compression force. Compression produces stretch force. Always toward the center. Always proportional.

The spring constant `k` determines stiffness. A high `k` means the spring fights hard against any displacement — short oscillations, rapid return. A low `k` means the spring yields easily — long, slow swings. Double `k` and the restoring force doubles for the same stretch. The spring gets tighter, not longer.

```gdscript
# Stiff spring: k = 20, snaps back fast
var force_stiff := -20.0 * displacement

# Soft spring: k = 2, drifts back slowly
var force_soft := -2.0 * displacement
```

Same displacement, tenfold difference in force. The stiff spring accelerates the mass violently toward center. The soft spring nudges it. Both reach equilibrium eventually. The path there looks entirely different.

## Equilibrium: The Zero-Force Point

Equilibrium is the position where the spring exerts no force. At `position.y == equilibrium_y`, displacement is zero, force is zero. The mass sits motionless if placed there with zero velocity. No push, no pull, no motion.

```gdscript
var displacement := position.y - equilibrium_y
# When displacement == 0.0:
var spring_force := -spring_constant * 0.0  # == 0.0
# No force. No acceleration. No change.
```

But equilibrium is unstable in the dynamic sense. Place the mass exactly at equilibrium with zero velocity and it stays. Disturb it by any amount — even a fraction of a unit — and the restoring force activates. The disturbance does not decay on its own. The mass returns to equilibrium but carries velocity through the center, overshoots, and the process reverses. Equilibrium is the point the mass passes through, not the point it settles at.

This is the engine of oscillation. The spring does not damp. It restores. Restoration with inertia produces overshoot. Overshoot produces displacement in the opposite direction. Displacement produces force in the opposite direction. The cycle repeats. Equilibrium is the fulcrum, not the destination.

## The Integration Loop: From Law to Motion

The same Euler integration from Forces_1 and Forces_2 applies unchanged. Compute force. Divide by mass for acceleration. Accumulate into velocity. Accumulate into position.

```gdscript
func _physics_process(delta: float) -> void:
    var displacement := position.y - equilibrium_y
    var spring_force := Vector3(0.0, -spring_constant * displacement, 0.0)

    var acceleration := spring_force / mass
    velocity += acceleration * delta
    position += velocity * delta
```

Two lines of integration. The same two lines from every previous Forces map. The architecture of simulation does not change when the force changes. Only the force computation differs. Gravity was `Vector3(0, -9.8, 0)` — constant, independent of state. The spring force is `-k * displacement` — dependent on position, recalculated every frame.

The force accumulator pattern from Forces_2 absorbs springs naturally:

```gdscript
var forces: Array[Vector3] = []

func _physics_process(delta: float) -> void:
    var displacement := position.y - equilibrium_y
    forces.append(Vector3(0.0, -spring_constant * displacement, 0.0))  # spring
    forces.append(Vector3(0.0, -mass * 9.8, 0.0))                     # gravity

    var net := Vector3.ZERO
    for f in forces:
        net += f
    var acceleration := net / mass
    velocity += acceleration * delta
    position += velocity * delta
    forces.clear()
```

Gravity and spring coexist through superposition. The net force is their vector sum. When the mass hangs below the natural spring length, gravity pulls down and the spring pulls up. A new equilibrium emerges — lower than the spring's natural rest point — where gravitational pull and spring pull cancel exactly. The mass oscillates around this shifted equilibrium, not the spring's original one.

## Oscillation Emerges

Pull the mass downward past equilibrium and release it. Frame by frame:

```gdscript
# Frame 0: displaced below equilibrium, velocity zero
# displacement = -2.0, force = +k*2.0 (upward), velocity = 0

# Frame N: mass reaches equilibrium
# displacement = 0.0, force = 0.0, velocity = max (upward)

# Frame M: mass reaches peak above equilibrium
# displacement = +2.0, force = -k*2.0 (downward), velocity = 0

# Frame P: mass returns to equilibrium heading down
# displacement = 0.0, force = 0.0, velocity = max (downward)

# Frame Q: back to starting position. Cycle complete.
```

Force is maximum at the extremes. Velocity is maximum at the center. They are 90 degrees out of phase — when one peaks, the other zeros. This quarter-cycle offset is the signature of simple harmonic motion. It is not coded. It emerges from the integration of `-kx` over time.

The dark_sphere, attached to the spring, traces this oscillation physically. Its vertical position over time draws a sine wave:

```
y(t) = A * cos(omega * t)
```

Where `A` is the amplitude (initial displacement) and `omega = sqrt(k / m)` is the angular frequency. Higher `k` means faster oscillation. Higher `m` means slower. The formula falls out of the differential equation `m * a = -k * x`, which is `m * x'' = -k * x`, which has the solution `x(t) = A * cos(sqrt(k/m) * t)`.

The code never calls `cos()`. The sinusoidal motion is a consequence of the integration loop applying `-kx` every frame. Euler integration approximates the true solution. With small enough `delta`, the approximation is visually indistinguishable from the analytic cosine. With large `delta`, the approximation drifts — the mass gains energy it should not have, and oscillations grow instead of staying constant. This is Euler integration's instability, visible as a spring that slowly winds itself up.

## Period and Frequency

The period `T` — time for one full oscillation — depends on mass and stiffness:

```
T = 2 * PI * sqrt(m / k)
```

Frequency is its inverse:

```
f = 1 / T = (1 / (2 * PI)) * sqrt(k / m)
```

```gdscript
var omega := sqrt(spring_constant / mass)
var period := 2.0 * PI / omega
var frequency := 1.0 / period
```

A spring with `k = 4.0` and `m = 1.0` has `omega = 2.0`, period `PI` seconds (~3.14s), frequency ~0.318 Hz. Double the mass to 2.0: period stretches to `PI * sqrt(2)` (~4.44s). The heavier mass swings slower. Double the spring constant to 8.0 with original mass: period shrinks to `PI / sqrt(2)` (~2.22s). The stiffer spring swings faster.

Amplitude does not affect period. A small oscillation and a large one take the same time to complete a cycle. This is unique to linear restoring forces — Hooke's law is linear in displacement. Nonlinear springs (where force depends on `x^2` or `x^3`) break this independence. The linear spring is special: amplitude-independent period, exact sinusoidal motion, and clean analytic solutions. It is the harmonic oscillator, the most fundamental periodic system in physics.

## Energy in the Spring

A spring stores energy when stretched or compressed. Potential energy in a spring:

```
PE_spring = 0.5 * k * x^2
```

Kinetic energy of the mass:

```
KE = 0.5 * m * v^2
```

At the extremes of oscillation, velocity is zero and all energy is potential. At equilibrium, displacement is zero and all energy is kinetic. Total mechanical energy stays constant throughout:

```gdscript
func compute_spring_energy(disp: float, vel_y: float) -> Dictionary:
    var pe := 0.5 * spring_constant * disp * disp
    var ke := 0.5 * mass * vel_y * vel_y
    return { "potential": pe, "kinetic": ke, "total": pe + ke }
```

Energy oscillates between two forms. Potential peaks when kinetic bottoms. Kinetic peaks when potential bottoms. The sum is constant — no energy enters, no energy leaves. The spring is a conservative system. Every joule invested in displacement returns as motion. Every joule of motion converts back to displacement. Perfect symmetry, infinite repetition.

Forces_2 showed kinetic-potential exchange along a parabolic arc — potential highest at the apex, kinetic highest at impact. The spring does the same exchange, but cyclically. The parabola is a one-way trip (up, then down). The spring is a loop. Energy sloshes back and forth forever, and the oscillation that results is the temporal expression of that energy exchange.

## Damping: When Energy Leaves

Real springs do not oscillate forever. Friction, air resistance, and internal material losses drain energy from the system. A damped spring loses amplitude with each cycle until it settles at equilibrium.

```gdscript
@export var damping: float = 0.3

func _physics_process(delta: float) -> void:
    var displacement := position.y - equilibrium_y
    var spring_force := Vector3(0.0, -spring_constant * displacement, 0.0)
    var damping_force := -damping * velocity

    var net_force := spring_force + damping_force
    var acceleration := net_force / mass
    velocity += acceleration * delta
    position += velocity * delta
```

The damping force is proportional to velocity and opposite in direction. Fast motion gets damped hard. Slow motion gets damped lightly. At rest, damping force is zero — it does not prevent motion, only resists it.

`-damping * velocity` — the full velocity vector, not just the y-component. Damping opposes motion in whatever direction it occurs. For a vertical spring, only `velocity.y` matters. For a spring in 2D or 3D, the damping force automatically aligns against the velocity vector. The minus sign does the work.

Three damping regimes exist:

```gdscript
# Underdamped: oscillates with decaying amplitude
# damping < 2 * sqrt(k * m)
var critical_damping := 2.0 * sqrt(spring_constant * mass)

# Critically damped: returns to equilibrium as fast as possible, no oscillation
# damping == critical_damping

# Overdamped: returns to equilibrium slowly, no oscillation
# damping > critical_damping
```

Underdamping is the interesting case. The mass still oscillates, but each swing is smaller than the last. The envelope of the oscillation decays exponentially. Plot position versus time and the sine wave fits inside a collapsing exponential — `A * exp(-gamma * t) * cos(omega_d * t)`, where `gamma = damping / (2 * mass)` and `omega_d` is the damped frequency, slightly lower than the natural frequency.

Critical damping is the engineering target for shock absorbers and door closers — return to rest as quickly as possible without bouncing past. Overdamping returns without oscillation but slower than critical. The choice between regimes is the choice between responsiveness and stability.

## The Spring as State Machine

The spring-mass system cycles through four phases per oscillation:

```gdscript
# Phase 1: Moving toward equilibrium from below
# displacement < 0, velocity > 0, force > 0
# Spring pushes up, mass accelerates upward

# Phase 2: Moving away from equilibrium above
# displacement > 0, velocity > 0, force < 0
# Spring pulls down, mass decelerates

# Phase 3: Moving toward equilibrium from above
# displacement > 0, velocity < 0, force < 0
# Spring pulls down, mass accelerates downward

# Phase 4: Moving away from equilibrium below
# displacement < 0, velocity < 0, force > 0
# Spring pushes up, mass decelerates
```

Four quadrants. In phases 1 and 3, force and velocity align — the mass speeds up. In phases 2 and 4, force opposes velocity — the mass slows down. Acceleration and deceleration alternate every quarter-cycle. The mass is always either speeding up or slowing down. It passes through maximum speed only at the instant of crossing equilibrium, and through zero speed only at the extremes.

This four-phase cycle maps directly onto the QFEP oscillation framework. The system's state vector — `(position, velocity)` — traces an ellipse in phase space. Each quadrant of the ellipse corresponds to one phase. The ellipse does not shrink (undamped) or spirals inward (damped). Phase space makes the periodicity geometric — the loop is the oscillation, visible as shape rather than timeline.

## The Spring Visualizer

The spring_visualizer artifact from the intent gap makes the force-displacement relationship physical. A visible coil connects the anchor point to the dark_sphere. As the sphere moves, the coil stretches and compresses. Force arrows scale with displacement — long arrows at the extremes, vanishing at equilibrium.

```gdscript
@export var coil_segments: int = 20
@export var coil_radius: float = 0.15
@export var rest_length: float = 2.0

func _update_coil(anchor: Vector3, mass_pos: Vector3) -> void:
    var current_length := anchor.distance_to(mass_pos)
    var direction := (mass_pos - anchor).normalized()

    for i in coil_segments:
        var t := float(i) / float(coil_segments)
        var along := anchor + direction * current_length * t
        var angle := t * coil_segments * TAU / 4.0
        var offset := Vector3(cos(angle), 0.0, sin(angle)) * coil_radius
        _set_segment_position(i, along + offset)
```

The coil distributes `coil_segments` points between anchor and mass. Each point spirals around the axis connecting them. When the spring stretches, the coils spread apart — wider spacing signals tension. When it compresses, coils bunch together — tight spacing signals compression. The visual density of the coil encodes the spring's state without arrows or numbers.

A position-versus-time graph running alongside the coil reveals the sinusoidal pattern. Each frame plots a dot at `(time, position.y)`. Over seconds, the dots assemble into the cosine curve that the integration loop produces. The coil shows the mechanism. The graph shows the consequence. Force arrows bridge the two — visible at each extreme, absent at center, always pointing toward equilibrium.

## From Spring to Everything That Vibrates

The harmonic oscillator is not a special case. It is the general case. Any system near a stable equilibrium behaves like a spring. Pendulums, vibrating strings, atoms in a crystal lattice, electrical circuits with inductors and capacitors — all reduce to `F = -kx` for small displacements. The spring is the prototype.

Forces_4 introduces friction as the force that destroys what the spring conserves. Where the spring converts energy back and forth without loss, friction converts kinetic energy to heat — irreversibly. The damping term previewed here becomes the central subject. A spring without damping oscillates forever. A spring with friction eventually stops. The transition from perpetual oscillation to eventual rest is the transition from conservative to dissipative physics, and it is where the Forces sequence turns from ideal to real.

## Possible Artifacts

**spring_visualizer** -- A visible coil connecting an anchor point to the dark_sphere mass. The coil stretches and compresses as the mass oscillates, with coil density encoding spring state. Force arrows at the mass scale proportionally to displacement and always point toward equilibrium. A synchronized position-vs-time graph plots each frame as a dot, assembling the emergent sinusoidal curve. Exports for spring constant, mass, initial displacement, damping coefficient, coil segment count, and graph time window.

**energy_bar_display** -- Two vertical bars — one for kinetic energy, one for spring potential energy — updating each frame beside the oscillating mass. A third bar shows total energy as their sum. In the undamped case, the total bar stays constant while the other two seesaw. With damping enabled, the total bar gradually shrinks, and a fourth bar (heat/loss) grows to account for the deficit. Exports for bar scale, color mapping, and damping toggle.

**phase_space_tracer** -- Plots the mass's state as a point in (position, velocity) space. Each frame adds a dot. Without damping, the dots trace a closed ellipse — one loop per oscillation, repeating exactly. With damping, the ellipse spirals inward toward the origin (equilibrium at rest). The shape of the spiral encodes the damping regime: wide loops for underdamped, tight convergence for critically damped, no loop for overdamped. Exports for axis scale, trail length, and damping coefficient.
