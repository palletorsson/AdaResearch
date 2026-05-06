# Ground-level arena where vectors become forces and objects learn to fall

In the vector maps we built the grammar: components, magnitude, direction, subtraction, cross product, dot product, projection, torque. Every one of those operations was static geometry. Arrows drawn, measured, decomposed — but frozen. Nothing fell. Nothing accelerated. Nothing bounced.

Now the arrows move.

This map is the transition from kinematics to dynamics. Kinematics describes motion — position, velocity, trajectory. Dynamics explains it. The difference is a single equation: **F = ma**. Force equals mass times acceleration. Three letters, three laws, and the entire mechanical universe follows.

## The First Law: Nothing Changes Without a Reason

Newton's First Law is the most underrated idea in physics. Objects at rest stay at rest. Objects in motion stay in motion — same speed, same direction — unless acted on by an external force. This is inertia.

```gdscript
# A body with no forces applied
var velocity := Vector3(2.0, 0.0, 1.0)

func _physics_process(delta: float) -> void:
    position += velocity * delta
    # velocity never changes — no force, no acceleration
    # the object drifts forever at (2, 0, 1) per second
```

The object moves in a straight line at constant speed for eternity. No friction, no gravity, no drag. The velocity set at initialization persists unchanged because nothing acts on it. This is the default state of the universe — not stillness, but persistence.

The radical implication: motion does not require explanation. Only *change* in motion requires explanation. A ball rolling across a table slows down because friction — an external force — opposes its motion. Remove friction and the ball rolls forever. Aristotle thought objects needed a continuous push to keep moving. Newton said they needed a push to stop.

The dark_sphere artifact floats and rotates without any force model. Its `rotation.y += rotation_speed * delta` is pure kinematics — velocity applied without cause. The First Law says this is valid. An object spinning in the void keeps spinning. Force is required only to change the state, not to maintain it.

```gdscript
# Inertia in isolation — no force, no change
var linear_velocity := Vector3.ZERO
var angular_velocity := Vector3(0.0, 0.15, 0.0)

func _physics_process(delta: float) -> void:
    position += linear_velocity * delta
    rotation += angular_velocity * delta
    # Both persist indefinitely. Inertia is the default.
```

Linear and angular motion obey the same principle. A spinning object keeps spinning. A still object stays still. Inertia is not a force — it is the absence of forces made visible.

## Force as a Vector

A force has magnitude and direction. It is a vector. Gravity near Earth's surface pulls downward at approximately 9.8 meters per second squared. In Godot's coordinate system, where y points up:

```gdscript
var gravity := Vector3(0.0, -9.8, 0.0)
```

One vector. Direction: straight down. Magnitude: 9.8. The simplest force — constant, uniform, always present. The x and z components are zero because gravity doesn't push sideways. The y component is negative because down is negative y in Godot's coordinate system.

Forces combine by vector addition. Two forces acting on the same object produce a net force equal to their sum:

```gdscript
var gravity := Vector3(0.0, -9.8, 0.0)
var wind := Vector3(3.0, 0.0, 0.0)
var net_force := gravity + wind  # Vector3(3.0, -9.8, 0.0)
```

The net force points diagonally — down and to the right. The object doesn't choose which force to obey. It obeys the sum. This is superposition: forces are independent, each contributing to the total. The vector addition from the earlier maps — same head-to-tail construction, same component-wise sum — now describes physical interaction. The math hasn't changed. The meaning has.

The `basis_vectors_rig` carries into this map. Its three colored arrows define the coordinate frame against which forces are measured. Gravity's `(0, -9.8, 0)` means "nothing along i-hat, -9.8 along j-hat, nothing along k-hat." The basis vectors aren't decorative. They're the ruler against which every force is decomposed.

## The Second Law: F = ma

The First Law says what happens without force. The Second Law says what happens with it. Apply a force F to an object of mass m, and it accelerates:

```
a = F / m
```

Acceleration is force divided by mass. Same force, more mass, less acceleration. Same force, less mass, more acceleration. Mass is resistance to acceleration — the scalar that stands between force and motion.

```gdscript
var mass := 2.0  # kilograms
var force := Vector3(0.0, -9.8, 0.0) * mass  # gravitational force = mg
var acceleration := force / mass  # Vector3(0.0, -9.8, 0.0)
```

Gravitational force is `mass * g`. Divide by mass to get acceleration and the mass cancels. Every object near Earth accelerates downward at 9.8 m/s^2 regardless of mass. Galileo demonstrated this. Newton explained why.

But acceleration is not the whole story. Force causes acceleration. Acceleration changes velocity. Velocity changes position. Three layers, each feeding the next:

```gdscript
var mass := 5.0
var gravity := Vector3(0.0, -9.8, 0.0)
var velocity := Vector3.ZERO
var acceleration := Vector3.ZERO

func apply_force(force: Vector3) -> void:
    acceleration += force / mass

func _physics_process(delta: float) -> void:
    apply_force(gravity * mass)       # weight = mg
    velocity += acceleration * delta  # integrate acceleration
    position += velocity * delta      # integrate velocity
    acceleration = Vector3.ZERO       # reset for next frame
```

This is Euler integration — the simplest numerical method for simulating motion. Each frame: accumulate forces, compute acceleration, update velocity, update position, clear the accumulator. The `acceleration = Vector3.ZERO` at the end is critical. Forces are applied fresh each frame. Acceleration doesn't persist — it's recomputed from whatever forces act at that moment. Velocity persists because of inertia.

The `apply_force` function divides by mass. Call `apply_force(Vector3(10, 0, 0))` on an object with mass 1 and it accelerates at 10. Call the same force on mass 10 and it accelerates at 1. The force is identical. The response is not. Mass is not weight — weight is `mass * g`, a force. Mass is the property that determines how stubbornly an object resists being pushed.

## Euler Integration: The Simulation Loop

The two lines that drive everything:

```gdscript
velocity += acceleration * delta
position += velocity * delta
```

Acceleration scaled by the time step adds to velocity — the definition of acceleration as rate of change of velocity. If acceleration is `(0, -9.8, 0)` and delta is 1/60 of a second, velocity gains `(0, -0.163, 0)` each frame. Downward. Accumulating. Then velocity scaled by the time step adds to position. As velocity grows more negative in y, position decreases faster. The object falls — slowly at first, then faster. Not constant speed, but constantly increasing speed.

```gdscript
# Full falling body simulation
extends Node3D

@export var mass: float = 1.0
var velocity := Vector3.ZERO
var acceleration := Vector3.ZERO
var gravity := Vector3(0.0, -9.8, 0.0)

func _physics_process(delta: float) -> void:
    # Apply gravity (force = mass * gravity, then a = F/m = gravity)
    acceleration = gravity

    # Euler integration
    velocity += acceleration * delta
    position += velocity * delta
```

Twelve lines. A complete falling object. The acceleration equals gravity directly because the mass cancels — `F/m = mg/m = g`. Velocity increases by 9.8 m/s every second. The quadratic curve of free fall emerges from two linear updates.

Euler integration is not accurate for large time steps — it introduces energy drift. More sophisticated integrators (Verlet, Runge-Kutta) fix this. But Euler is correct enough to see the physics, and simple enough to understand completely. Later maps refine the method. This map establishes the pattern.

## Mass and Momentum

Momentum is mass times velocity:

```
p = mv
```

A vector quantity. Direction from velocity, magnitude scaled by mass. A 10 kg object moving at 2 m/s carries the same momentum as a 2 kg object at 10 m/s — but the heavy object is harder to redirect because mass resists velocity change. Momentum unifies mass and velocity into a single measure of "how much motion."

```gdscript
var mass_heavy := 10.0
var mass_light := 1.0
var force := Vector3(0.0, -9.8, 0.0)

# After 1 second of the same force:
var vel_heavy := (force / mass_heavy) * 1.0  # (0, -0.98, 0)
var vel_light := (force / mass_light) * 1.0  # (0, -9.8, 0)

var p_heavy := mass_heavy * vel_heavy  # (0, -9.8, 0)
var p_light := mass_light * vel_light  # (0, -9.8, 0)
# Same momentum. Different velocities. Different masses.
```

Same force, same time, same momentum. This is the impulse-momentum theorem: `F * dt = dp`. But drop two spheres from the same height under gravity — both accelerate at 9.8 m/s^2, both hit at the same speed. The heavier sphere has more momentum: `p = mv`, same `v`, bigger `m`. The impact feels different. The heavier sphere pushes the ground harder. This is why mass matters even though all objects fall at the same rate.

## Bouncing: Collision and Restitution

A falling object hits the ground. What happens?

```gdscript
var ground_y := 0.0
var restitution := 0.8  # coefficient of restitution: 0 = dead stop, 1 = perfect bounce

func _physics_process(delta: float) -> void:
    acceleration = gravity
    velocity += acceleration * delta
    position += velocity * delta

    # Ground collision
    if position.y <= ground_y:
        position.y = ground_y                    # clamp to surface
        velocity.y = -velocity.y * restitution   # reflect and lose energy
```

Has the object passed through the floor? If so, snap it back and reverse the y-component of velocity. The `restitution` coefficient scales the reflected velocity. At 1.0 — perfect elasticity, no energy loss. At 0.0 — perfect inelasticity, dead stop. At 0.8, each bounce returns 80% of the velocity, and the ball gradually settles.

The reflection `velocity.y = -velocity.y * restitution` does two things. The negation reverses direction — the ball was going down, now it goes up. The multiplication by restitution reduces magnitude — each bounce is weaker. After enough bounces, the velocity becomes negligibly small and the ball rests on the ground. Energy dissipates. The system finds equilibrium.

The energy loss is quadratic in restitution because kinetic energy depends on velocity squared. `KE = 0.5 * m * v^2`. After a bounce, `v_new = v_old * restitution`, so `KE_new = KE_old * restitution^2`. A restitution of 0.8 doesn't mean 80% of energy survives — it means 64%. At 0.5, only 25%. The ball dies faster than the coefficient suggests.

Mass affects the bounce visually. A heavy sphere and a light sphere with the same restitution follow identical trajectories — same height, same timing. But the heavy sphere transfers more force to the ground at each impact. Newton's Third Law explains why.

## The Third Law: Equal and Opposite

Every force has a partner. When object A pushes object B, object B pushes back on A with equal magnitude and opposite direction. Action and reaction. Always paired, always simultaneous, always on different objects.

```gdscript
# Ball hits the ground
# Force on ball from ground: Vector3(0, F_normal, 0)  — upward
# Force on ground from ball: Vector3(0, -F_normal, 0) — downward
# Equal magnitude. Opposite direction. Different objects.
```

The Third Law is not about balance. The forces act on different objects, so they don't cancel. The ground pushes the ball up (the ball bounces). The ball pushes the ground down (the ground absorbs the impact). If the ground is Earth, its mass is so large that `a = F/m` produces negligible acceleration. The Earth accelerates toward the falling ball. The number is real. Too small to measure.

```gdscript
# Two balls colliding — simplified 1D elastic collision
func resolve_collision(ball_a: Dictionary, ball_b: Dictionary) -> void:
    var m1 := ball_a.mass
    var m2 := ball_b.mass
    var v1 := ball_a.velocity.y
    var v2 := ball_b.velocity.y

    # Conservation of momentum + conservation of energy (elastic)
    ball_a.velocity.y = (v1 * (m1 - m2) + 2.0 * m2 * v2) / (m1 + m2)
    ball_b.velocity.y = (v2 * (m2 - m1) + 2.0 * m1 * v1) / (m1 + m2)
```

In a collision between two objects, the Third Law guarantees momentum is conserved. Whatever momentum A gains, B loses. The velocities redistribute according to the masses — a heavy ball barely flinches when struck by a light one, while the light ball rockets away. Same force on both (Third Law), different accelerations (Second Law) because different masses.

The Third Law is a conservation law in disguise — conservation of momentum follows directly from the Third and Second Laws combined. In the QFEP framework, the feedback term captures how a system's state change propagates back into itself. Action-reaction is the physical prototype: every push generates a counter-push. The system cannot act on its environment without the environment acting back. Force is a dialogue, not a monologue.

## From Static Vectors to Dynamic Systems

The vector sub-sequence built tools for describing space — how far, which way, what angle. This map asks: what makes things move through that space? The answer is force, mediated by mass, expressed as acceleration. The same `Vector3` that stored a position now stores a force. The same addition that combined displacements now combines forces.

The `VectorBasics` artifact and `basis_vectors_rig` remain because force decomposition is vector decomposition. Gravity is pure j-hat. Wind might be pure i-hat. A rocket thrust has components along all three. The basis vectors aren't left over from the previous sequence — they're the frame in which forces make sense.

The dark_sphere becomes the test mass. In the vector maps it was ambient — a floating orb demonstrating rotation and pulsing. Now it receives forces. Its position is no longer a static coordinate but a state variable — updated each frame by velocity, which is updated by acceleration, which is computed from forces. Three layers, each the derivative of the next. Position is the integral of velocity. Velocity is the integral of acceleration. Acceleration is force divided by mass.

`velocity += acceleration * delta` approximates the integral of acceleration over a small time interval. `position += velocity * delta` approximates the integral of velocity. At 60 fps, delta is about 0.0167 seconds — small enough for convincing physics, large enough for real time.

The QFEP oscillation phase begins here. In the exploration phase (the vector maps), states were static and attention moved between them. Now states evolve. Forces push systems between ordered and disordered configurations. A ball at rest is ordered — low entropy, predictable. A ball bouncing is oscillating — energy converting between kinetic and potential, position cycling between ground and apex. The lambda parameter that governs order-to-chaos transitions now has a physical mechanism: force.

## Possible Artifacts

**mass_comparison_demo** -- Two or three spheres of different sizes, dropped simultaneously from the same height. All fall at the same rate — confirming gravitational acceleration is mass-independent. On impact, each sphere displays its momentum `p = mv` as a scaled arrow, and the ground beneath shows a ripple proportional to impact force. Same trajectory, different consequences. Exports for mass values, restitution per sphere, and drop height.

**free_body_diagram** -- An overlay that attaches to any physics body and draws every applied force as a labeled arrow from the center of mass. Gravity always present, pointing down. Normal force appears on contact, pointing up. Net force drawn as a thicker arrow — the vector sum. Labels show magnitude in Newtons. Updates each frame, so during a bounce the arrows flip in real time. Connects the abstract `apply_force()` call to the geometric reality of arrows on an object.

**euler_integration_tracer** -- Drops a sphere and records its position at every physics frame as a dot, building a trail through space. Dot spacing reveals acceleration — wide at the bottom of a fall (high velocity), tight near the apex of a bounce (velocity approaching zero). A side panel shows position, velocity, and acceleration updating live. Toggling between Euler and analytical solutions shows the integration error. Exports for time step multiplier, trail color, and maximum trail length.
