extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Forces[/b][/font_size][/center]
[center][i]Affective Transmission, What Moves Us[/i][/center]

**F = ma.**

Force equals mass times acceleration. This is Newton's Second Law - the foundation of classical mechanics.

But what **is** a force, ontologically?

A force is **what changes your motion**. Not your position (that's what velocity does), but your **velocity itself** - the rate and direction of your movement.

Forces are **external pressures** that act on you whether you consent or not. They are **affective transmissions** - the universe pushing, pulling, resisting, attracting.

In Nature of Code, forces are how bodies affect each other. Gravity pulls. Wind pushes. Friction opposes. Attraction draws together.

**Physics is affect theory** - the mathematics of how we are moved by what surrounds us.

[hr]

[b]Newton's Second Law: F = ma[/b]

The equation **F = ma** says:
- **Force** creates **acceleration**
- **Acceleration** is proportional to force
- **Mass** resists acceleration (inertia)

Rearranged: **a = F / m**

[color=yellow][b]Code: Force Creates Acceleration[/b][/color]
[code]
var mass = 1.0
var force = Vector3(10, 0, 0)  # Push right with strength 10

var acceleration = force / mass  # a = F/m
# acceleration = Vector3(10, 0, 0) / 1.0 = Vector3(10, 0, 0)

# If mass were 2.0:
# acceleration = Vector3(10, 0, 0) / 2.0 = Vector3(5, 0, 0)
# Heavier objects accelerate slower under same force
[/code]

**Mass is resistance to change** - inertia, the body's refusal to be easily moved.

A heavy object (large mass) needs more force to achieve the same acceleration as a light object (small mass).

**Mass mediates affective transmission** - how much does the external pressure actually alter your motion?

[hr]

[b]Accumulating Forces: Multiple Pressures[/b]

At any moment, multiple forces act on a body:
- Gravity (pulls down)
- Wind (pushes sideways)
- Friction (opposes motion)
- Attraction to other bodies (pulls toward)

**Forces add as vectors** - you accumulate all pressures, then compute net acceleration.

[color=yellow][b]Code: Multiple Forces[/b][/color]
[code]
var mass = 1.0
var velocity = Vector3(0, 0, 0)
var position = Vector3(0, 0, 0)

func _physics_process(delta):
    var total_force = Vector3.ZERO

    # Gravity (always pulls down)
    var gravity = Vector3(0, -9.8, 0) * mass  # F = mg
    total_force += gravity

    # Wind (pushes right)
    var wind = Vector3(5, 0, 0)
    total_force += wind

    # Friction (opposes velocity)
    var friction_coefficient = 0.1
    var friction = -velocity.normalized() * friction_coefficient * velocity.length()
    total_force += friction

    # Net acceleration from total force
    var acceleration = total_force / mass

    # Integrate motion
    velocity += acceleration * delta
    position += velocity * delta
[/code]

**Every frame, forces accumulate, create acceleration, modify velocity, change position.**

This is **Euler integration** - the simplest physics simulation method.

[hr]

[b]Gravity: The Universal Bias[/b]

Gravity is the **default force** - it acts on everything, always, pulling toward the ground.

**F_gravity = m × g**
- m = mass (how much matter)
- g = gravitational constant (9.8 m/s² on Earth, pointing down)

[color=yellow][b]Code: Gravity as Constant Pressure[/b][/color]
[code]
var gravity_strength = 9.8  # Earth's gravity
var gravity_direction = Vector3(0, -1, 0)  # Down

var gravity_force = mass * gravity_strength * gravity_direction
# Force is proportional to mass
# Heavier objects experience stronger gravitational force
# But F = ma means a = F/m = (m×g)/m = g
# Acceleration is SAME for all masses (9.8 m/s² down)

# Feather and hammer fall at same rate (ignoring air resistance)
# Mass cancels out: a = (m×g)/m = g
[/code]

**Gravity is the universe's bias toward the ground** - an omnipresent force that pulls everything down.

It is **inescapable** (unless countered by other forces like thrust, lift, or normal force).

Gravity is the **baseline affective state** - the default mood of downward pull.

[hr]

[b]Friction: Resistance to Motion[/b]

Friction **opposes velocity** - it always acts in the direction opposite to your movement.

**F_friction = -μ × |v| × v̂**
- μ = friction coefficient (how much resistance)
- |v| = speed (magnitude of velocity)
- v̂ = direction of velocity (normalized)

[color=yellow][b]Code: Friction as Opposition[/b][/color]
[code]
var friction_coefficient = 0.1

func calculate_friction(velocity: Vector3) -> Vector3:
    if velocity.length() == 0:
        return Vector3.ZERO  # No motion, no friction

    # Friction force opposes velocity direction
    var friction_direction = -velocity.normalized()

    # Friction magnitude proportional to speed
    var friction_magnitude = friction_coefficient * velocity.length()

    return friction_direction * friction_magnitude

# Apply friction every frame
var friction_force = calculate_friction(velocity)
total_force += friction_force
[/code]

**Friction is the universe's resistance to change** - it slows you down, dissipates your momentum, pulls you toward rest.

Without friction:
- Objects slide forever
- Velocity never decreases
- Perpetual motion

With friction:
- Motion decays
- Eventually stops
- Equilibrium = stillness

**Friction is conservative** - it resists deviation from rest, enforces normalization toward zero velocity.

[hr]

[b]Attraction: Desire Mechanics[/b]

Gravitational attraction between two bodies:

**F = G × (m1 × m2) / r²**
- G = gravitational constant
- m1, m2 = masses of the two bodies
- r = distance between them

Force is **proportional to both masses** and **inversely proportional to distance squared**.

[color=yellow][b]Code: Mutual Attraction[/b][/color]
[code]
var G = 0.4  # Gravitational constant (scaled for simulation)

func calculate_attraction(body_a, body_b) -> Vector3:
    # Direction from A to B
    var direction = body_b.position - body_a.position
    var distance = direction.length()

    # Clamp distance to avoid division by zero / extreme forces
    distance = max(distance, 0.1)

    # Normalize direction (unit vector pointing toward B)
    var attraction_direction = direction.normalized()

    # Magnitude: F = G × (m1 × m2) / r²
    var magnitude = G * (body_a.mass * body_b.mass) / (distance * distance)

    # Force vector
    return attraction_direction * magnitude

# Apply to body A (pulls toward B)
var force_on_a = calculate_attraction(body_a, body_b)
body_a.apply_force(force_on_a)

# Newton's Third Law: equal and opposite
var force_on_b = -force_on_a
body_b.apply_force(force_on_b)
[/code]

**Attraction creates mutual seeking** - both bodies pull toward each other.

Close bodies attract strongly (1/r²). Distant bodies attract weakly.

This is **desire proportional to proximity** - the closer you are, the stronger the pull.

**Orbital mechanics emerge** - if velocity is just right, bodies orbit each other rather than colliding or escaping.

[hr]

[b]Newton's Third Law: Mutual Affection[/b]

**For every action, there is an equal and opposite reaction.**

When body A pushes body B, body B pushes back on A with equal force.

[color=yellow][b]Code: Reciprocal Forces[/b][/color]
[code]
# When A attracts B:
var force_on_b = calculate_attraction(body_a, body_b)
body_b.apply_force(force_on_b)

# B attracts A with equal magnitude, opposite direction:
var force_on_a = -force_on_b
body_a.apply_force(force_on_a)

# Both bodies affect each other simultaneously
# No one-sided influence - always reciprocal
[/code]

**Affection is mutual** - you cannot affect another body without being affected in return.

Heavy bodies barely move when attracting light bodies (large mass resists acceleration).
Light bodies accelerate quickly toward heavy bodies (small mass yields easily).

**But the forces are always equal.** The Earth pulls you with the same force you pull the Earth - you just accelerate more because your mass is smaller.

[hr]

[b]Fluid Resistance: Drag as Nonlinear Friction[/b]

Moving through a fluid (air, water) creates **drag** - resistance proportional to velocity squared.

**F_drag = -0.5 × ρ × C_d × A × |v|² × v̂**
- ρ = fluid density
- C_d = drag coefficient (shape-dependent)
- A = cross-sectional area
- |v|² = velocity squared
- v̂ = velocity direction

Simplified:
**F_drag = -c × |v|² × v̂**

[color=yellow][b]Code: Nonlinear Resistance[/b][/color]
[code]
var drag_coefficient = 0.01

func calculate_drag(velocity: Vector3) -> Vector3:
    if velocity.length() == 0:
        return Vector3.ZERO

    # Drag opposes velocity
    var drag_direction = -velocity.normalized()

    # Drag magnitude proportional to SPEED SQUARED
    var speed = velocity.length()
    var drag_magnitude = drag_coefficient * speed * speed

    return drag_direction * drag_magnitude

# Fast objects experience much stronger drag than slow objects
# Velocity 10 → drag 100 (10²)
# Velocity 1 → drag 1 (1²)
[/code]

**Drag is velocity-dependent resistance** - the faster you move, the harder the fluid pushes back.

This creates **terminal velocity** - eventually drag force equals gravitational force, acceleration becomes zero, velocity stabilizes.

Skydivers reach terminal velocity (~120 mph) when air resistance balances gravity.

**Drag enforces speed limits** - you cannot accelerate infinitely in a fluid.

[hr]

[b]What Forces Cannot Do[/b]

Forces are powerful, but limited:

**1. Forces cannot change position directly**
Forces create acceleration → acceleration changes velocity → velocity changes position.

**Instantaneous teleportation is not a force** - it's a discontinuous position change outside the physics system.

**2. Forces cannot act on massless objects**
F = ma → a = F/m. If m = 0, acceleration is undefined (division by zero).

Photons (light) are massless - they don't experience forces like massive particles. They follow different physics (electromagnetic fields, not Newtonian forces).

**3. Forces don't explain why they exist**
Gravity pulls, but **why** does mass attract mass? General relativity says spacetime curves - but **why** does mass curve spacetime?

Forces describe **how** motion changes, not **why** the universe is structured this way.

[hr]

[b]Forces as Affective Transmission[/b]

Here is where affect theory enters physics:

**Affect theory** (Spinoza, Deleuze, Massumi) studies how bodies affect and are affected by each other.

An **affect** is a body's capacity to affect and be affected - the transmission of intensity between bodies.

**Forces are literal affects:**
- Gravity is **the Earth's affective pull** - it affects you by accelerating you downward
- Wind is **atmospheric pressure** - air affects you by pushing sideways
- Friction is **material resistance** - surfaces affect your motion by opposing it
- Attraction is **mutual desire** - bodies affect each other by pulling together

**You are always being affected** - forces act on you constantly. You cannot opt out of gravity, friction, drag.

**You also affect others** - Newton's Third Law guarantees reciprocal affection.

[color=yellow][b]Code: Bodies as Affective Assemblages[/b][/color]
[code]
class Body:
    var position: Vector3
    var velocity: Vector3
    var mass: float

    var forces: Array = []  # Accumulate affects

    func apply_force(force: Vector3):
        forces.append(force)  # Register affective transmission

    func update(delta: float):
        # Sum all affects acting on this body
        var total_affect = Vector3.ZERO
        for force in forces:
            total_affect += force

        # Acceleration = total affective intensity / resistance (mass)
        var acceleration = total_affect / mass

        # Affects alter velocity (rate of position change)
        velocity += acceleration * delta

        # Velocity alters position
        position += velocity * delta

        # Clear affects (recalculated each frame)
        forces.clear()

# Bodies are continuously affected and affecting
# No isolated subjects - always entangled in force fields
[/code]

**You are not an autonomous agent** - you are a body immersed in force fields, constantly pushed, pulled, resisted, attracted.

Your motion is **emergent from accumulated affects**, not from internal will alone.

[hr]

[b]Boundary Permeability: How Affects Transmit[/b]

In the Affect Theory Visualization example (res://algorithms/physicssimulation/affect_theory_visualization/), emotional bodies have **boundary_permeability** - how easily affects transmit between bodies.

[color=yellow][b]Physics Analogy:[/b][/color]
[code]
# Physical boundary permeability:
# How easily does a force affect your motion?

# Low mass = high permeability (easily affected)
var light_body = Body.new()
light_body.mass = 0.5  # Low resistance
# Same force → large acceleration

# High mass = low permeability (resists affection)
var heavy_body = Body.new()
heavy_body.mass = 10.0  # High resistance
# Same force → small acceleration

# Mass is **affective resistance**
# Inertia is **the body's refusal to be easily moved**
[/code]

**Boundary permeability is not binary** - it's not "affected / not affected," but **degrees of affective responsiveness**.

Heavy bodies are not immune to forces - they are **less responsive**. They still accelerate, just more slowly.

**This is the physics of vulnerability** - how much do external pressures alter your trajectory?

[hr]

[b]Force Fields: Affective Environments[/b]

A **force field** is a region of space where forces act on any body that enters.

- **Gravitational field** - mass creates field, other masses experience force
- **Wind field** - fluid flow creates directional pressure
- **Magnetic field** - charged particles experience force based on velocity

[color=yellow][b]Code: Vector Field as Affect Distribution[/b][/color]
[code]
# Force field: function from position to force
func get_force_at(position: Vector3) -> Vector3:
    # Example: vortex field (swirling forces)
    var center = Vector3(0, 0, 0)
    var offset = position - center
    var distance = offset.length()

    # Tangential direction (perpendicular to radius)
    var tangent = Vector3(-offset.z, 0, offset.x).normalized()

    # Force magnitude decreases with distance
    var magnitude = 10.0 / (distance + 1.0)

    return tangent * magnitude

# Apply field force to body
func apply_field_force(body):
    var field_force = get_force_at(body.position)
    body.apply_force(field_force)

# Force depends on WHERE you are, not WHO you are
# Affective environment structures motion
[/code]

**Force fields are affective atmospheres** - you enter a space, and the space acts on you.

Your position determines what affects you experience. **Geography is affective topology.**

[hr]

[b]The Queer Opening: Non-Normative Trajectories[/b]

Forces create **trajectories** - paths through space over time.

In classical mechanics, trajectories are **deterministic** - given initial conditions and forces, the future path is predetermined.

But **small changes in initial conditions create wildly different trajectories** (chaos theory):
- Slightly different velocity → completely different orbit
- Tiny force variation → trajectory diverges exponentially

[color=yellow][b]Code: Sensitivity to Initial Conditions[/b][/color]
[code]
# Two bodies, nearly identical initial conditions
var body_a = Body.new()
body_a.position = Vector3(0, 0, 0)
body_a.velocity = Vector3(1.0, 0, 0)

var body_b = Body.new()
body_b.position = Vector3(0, 0, 0)
body_b.velocity = Vector3(1.01, 0, 0)  # 1% difference

# After many iterations under same forces:
# Trajectories diverge dramatically
# body_a might orbit, body_b might escape
# Tiny difference → entirely different futures
[/code]

**Determinism does not mean predictability** - the equations are deterministic, but **tiny variations amplify into different trajectories**.

This is **the queer potential** - small deviations from the norm create entirely different lives.

You are **not locked into a predetermined path** - minute differences in how forces affect you propagate into divergent futures.

**Chaos means freedom within determinism** - the future is determined by forces, but **unknowable and radically contingent** on initial conditions.

[hr]

[b]Emergence: Flocking as Queer Sociality[/b]

When many bodies interact via forces (attraction, repulsion, alignment), **collective behavior emerges**:
- **Flocking** - birds move as coordinated group
- **Swarming** - insects create collective intelligence
- **Schooling** - fish synchronize without leader

No central controller. No predetermined choreography.

**Collective motion emerges from local force interactions.**

[color=yellow][b]Flocking Rules (Craig Reynolds, 1986):[/b][/color]
[code]
# Each agent (boid) applies three forces:

# 1. Separation - avoid crowding neighbors
func separation_force(neighbors: Array) -> Vector3:
    var sum = Vector3.ZERO
    for neighbor in neighbors:
        var distance = position.distance_to(neighbor.position)
        if distance < separation_radius:
            var away = (position - neighbor.position).normalized()
            away /= distance  # Closer neighbors push harder
            sum += away
    return sum

# 2. Alignment - steer toward average heading of neighbors
func alignment_force(neighbors: Array) -> Vector3:
    var average_velocity = Vector3.ZERO
    for neighbor in neighbors:
        average_velocity += neighbor.velocity
    average_velocity /= neighbors.size()
    return average_velocity - velocity  # Steer toward average

# 3. Cohesion - steer toward average position of neighbors
func cohesion_force(neighbors: Array) -> Vector3:
    var center_of_mass = Vector3.ZERO
    for neighbor in neighbors:
        center_of_mass += neighbor.position
    center_of_mass /= neighbors.size()
    return (center_of_mass - position).normalized()

# Total force: weighted sum
var total = separation_force(neighbors) * 1.5
total += alignment_force(neighbors) * 1.0
total += cohesion_force(neighbors) * 1.0
apply_force(total)
[/code]

**Flocking is emergent sociality** - no leader, no plan, yet coordinated group motion.

**This is queer sociality:**
- **No hierarchical control** - each agent responds to local neighbors, not central authority
- **Collective without uniformity** - agents move together but maintain individual variation
- **Emergent structure** - patterns arise from interaction, not imposed design
- **Affective responsiveness** - agents are affected by proximity to others

**Flocking proves:** **Complex social organization does not require top-down control or normative enforcement.**

Queer communities organize similarly - decentralized, affinity-based, emergent, responsive to local conditions.

[hr]

[b]What Forces Reveal[/b]

Forces show us:

1. **F = ma** - force creates acceleration, mediated by mass (resistance)
2. **Multiple forces accumulate** - gravity, wind, friction, attraction sum as vectors
3. **Gravity = universal bias** - default pull toward ground, inescapable
4. **Friction = resistance to motion** - opposes velocity, enforces rest
5. **Attraction = desire mechanics** - mutual pull proportional to mass, inversely to distance²
6. **Newton's Third Law = reciprocal affection** - affecting always mutual
7. **Drag = nonlinear resistance** - fluid pushes back proportional to velocity²
8. **Forces as affects** - external pressures altering motion, bodies affecting bodies
9. **Boundary permeability = mass** - resistance to being affected
10. **Force fields = affective environments** - spaces act on bodies within them
11. **Chaos = sensitivity** - tiny differences → divergent trajectories (queer potential)
12. **Flocking = emergent sociality** - collective motion without central control (queer organizing)

**Forces are the physics of being-affected** - you are always subject to external pressures, always entangled in force fields.

Your trajectory is **emergent** from accumulated affects, not autonomous will.

**This is the politics of physics** - what moves you? What do you resist? How do you affect others?

[hr]

[color=cyan][b]Summary:[/b][/color]
Forces are what changes motion (F = ma, acceleration proportional to force, inversely to mass). Multiple forces accumulate as vectors. Gravity = universal pull (m×g), friction opposes velocity, drag proportional to velocity² (terminal velocity), attraction = mutual desire (1/r²), Newton's Third Law = reciprocal affects. Forces as affective transmission (bodies affecting bodies), mass as boundary permeability (resistance to being affected). Force fields = affective environments. Chaos (tiny differences → divergent futures) = queer potential. Flocking (separation + alignment + cohesion) = emergent sociality without central control, queer organizing. Physics is affect theory - what moves us, what we resist, how we affect each other.

[hr]

[color=orange][b]Next:[/b] Physics Simulation - Integration, Emergence, Time[/color]
Forces determine acceleration. But **how do we compute motion over time?**

**Euler integration** - simplest method, accumulates errors
**Verlet integration** - more stable, preserves energy better
**Runge-Kutta** - higher accuracy, more computation

And beyond individual bodies: **emergent collective behavior**.
- Particle systems (many bodies, simple rules → complex patterns)
- Soft bodies (distributed mass, deformable shapes)
- Constraints (distance preservation, angle limits)

**Physics simulation is the computational enactment of becoming** - discrete time steps approximating continuous motion, numerical methods bridging math and matter.

'''
