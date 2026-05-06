extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Physics Simulation[/b][/font_size][/center]
[center][i]Computational Enactment of Becoming[/i][/center]

Physics simulation is **discrete time approximating continuous motion** - the computer iteratively calculating the next frame, accumulating small changes into emergent trajectories.

We have vectors (magnitude + direction), forces (what moves us), and now: **integration methods** - the algorithms that turn forces into motion over time.

But physics simulation is more than numerical accuracy. It is **the computational enactment of becoming** - bodies affecting bodies, constraints negotiated, soft forms deforming, particle systems swarming.

**This is where the queer potential of Nature of Code fully emerges**: decentralized systems, collective behavior without hierarchy, bodies that refuse rigidity, emergence without blueprint.

[hr]

[b]Integration: Bridging Math and Matter[/b]

Forces determine acceleration. Acceleration changes velocity. Velocity changes position.

But **how** do we compute these changes over time?

The answer: **numerical integration** - approximating continuous differential equations with discrete time steps.

[color=yellow][b]The Continuous Ideal (Calculus):[/b][/color]
[code]
# In continuous time (mathematical ideal):
# velocity = integral of acceleration over time
# position = integral of velocity over time

# Differential equations:
# dv/dt = a(t)  # Velocity's rate of change
# dx/dt = v(t)  # Position's rate of change

# But computers cannot compute infinite integrals
# Must approximate with discrete steps
[/code]

**Computers are discrete** - they run in frames (60 FPS, 120 FPS), not continuous time.

We must **approximate** the integral using finite time steps (delta).

[hr]

[b]Euler Integration: Simplest Method[/b]

**Euler integration** (Leonhard Euler, 1768) is the simplest numerical method:

At each time step:
1. Calculate acceleration from current forces
2. Update velocity: `velocity += acceleration * delta`
3. Update position: `position += velocity * delta`

[color=yellow][b]Code: The Basic Physics Loop[/b][/color]
[code]
var position = Vector3(0, 0, 0)
var velocity = Vector3(0, 0, 0)
var mass = 1.0

func _physics_process(delta):
    # Accumulate all forces
    var total_force = Vector3.ZERO
    total_force += calculate_gravity()
    total_force += calculate_wind()
    total_force += calculate_friction(velocity)

    # F = ma → a = F/m
    var acceleration = total_force / mass

    # Euler integration
    velocity += acceleration * delta  # dv = a × dt
    position += velocity * delta      # dx = v × dt

# Simple, fast, but accumulates errors over time
[/code]

**Euler is intuitive and fast** - one acceleration calculation, two additions per frame.

**But it accumulates errors:**
- **Energy drift** - orbits spiral outward (gain energy) or inward (lose energy)
- **Instability** - at high speeds or strong forces, simulation explodes

**Euler is good enough for:**
- Simple motion (bouncing balls, basic movement)
- Games where perfect accuracy unnecessary
- Prototyping and quick iteration

**Euler fails for:**
- Orbital mechanics (energy must conserve)
- Stiff systems (strong restoring forces like springs)
- Long-running simulations (errors compound)

[hr]

[b]Verlet Integration: Energy Preserving[/b]

**Verlet integration** (Loup Verlet, 1967) is more stable - it **preserves energy better** than Euler.

Instead of storing velocity, **Verlet stores current and previous position**.

Velocity is **implicit** - calculated from position change.

[color=yellow][b]Code: Position-Based Integration[/b][/color]
[code]
var position = Vector3(0, 0, 0)
var previous_position = Vector3(0, 0, 0)
var mass = 1.0

func _physics_process(delta):
    # Calculate forces
    var total_force = calculate_all_forces()
    var acceleration = total_force / mass

    # Verlet integration
    var temp = position
    position = position + (position - previous_position) + acceleration * delta * delta
    previous_position = temp

# (position - previous_position) = implicit velocity
# Velocity never explicitly stored
# More stable for constrained systems (cloth, ropes, chains)
[/code]

**Verlet advantages:**
- **Energy conservation** - orbits stay stable
- **Constraint satisfaction** - easier to enforce distance/angle constraints
- **Time reversibility** - can simulate backward

**Verlet is used for:**
- Cloth simulation (thousands of connected particles)
- Rope/chain physics (distance constraints)
- Soft bodies (deformable shapes)

**This is the physics of connection** - Verlet naturally handles constraints (distance must stay fixed, angles must preserve).

[hr]

[b]Runge-Kutta: Higher Accuracy[/b]

**Runge-Kutta methods** (4th order = RK4) are **more accurate** than Euler - they evaluate derivatives multiple times per step.

RK4 calculates four intermediate slopes, then averages them.

[color=yellow][b]Conceptual RK4:[/b][/color]
[code]
# RK4 evaluates acceleration at four points:
# k1 = current state
# k2 = midpoint using k1
# k3 = midpoint using k2
# k4 = endpoint using k3
# Final: weighted average of k1, k2, k3, k4

# Much more accurate than Euler
# But 4× more force calculations per step
# Used when accuracy critical (spacecraft trajectories, scientific simulation)
[/code]

**RK4 is overkill for most games** - Euler or Verlet sufficient.

But for scientific accuracy, orbital mechanics, or long-term stability: **RK4 is the standard**.

[hr]

[b]Particle Systems: Many Bodies, Simple Rules[/b]

A **particle system** is many identical bodies (particles), each following the same physics rules.

Examples:
- **Fire** - particles rise (buoyancy), flicker (randomness), fade (lifespan)
- **Water** - particles fall (gravity), spread (surface tension approximation)
- **Smoke** - particles drift (wind), dissipate (alpha decay)

[color=yellow][b]Code: Particle System[/b][/color]
[code]
class Particle:
    var position: Vector3
    var velocity: Vector3
    var lifespan: float = 1.0  # Time until death (seconds)
    var age: float = 0.0

var particles: Array = []

func _physics_process(delta):
    # Spawn new particles
    if randf() < 0.5:  # 50% chance each frame
        spawn_particle()

    # Update all particles
    var i = 0
    while i < particles.size():
        var p = particles[i]

        # Age particle
        p.age += delta
        if p.age > p.lifespan:
            particles.remove_at(i)  # Die
            continue

        # Apply forces
        var gravity = Vector3(0, -9.8, 0)
        var wind = Vector3(randf_range(-1, 1), 0, 0)  # Random wind
        p.velocity += (gravity + wind) * delta

        # Integrate motion (Euler)
        p.position += p.velocity * delta

        i += 1

func spawn_particle():
    var p = Particle.new()
    p.position = Vector3(0, 0, 0)
    p.velocity = Vector3(randf_range(-2, 2), randf_range(5, 10), randf_range(-2, 2))
    p.lifespan = randf_range(0.5, 2.0)
    particles.append(p)

# Thousands of particles, simple physics → emergent visual complexity
[/code]

**Particle systems are computational swarms** - no central control, each particle independent, yet **collective behavior emerges** (fire looks like fire, water looks like water).

This is **emergence from repetition** - same rules applied to many bodies creates patterns greater than the sum.

[hr]

[b]Soft Bodies: Distributed Mass, Deformable Forms[/b]

A **soft body** is not a rigid shape - it **deforms** under forces.

Implemented as **network of particles connected by springs**:
- Particles = mass points
- Springs = distance constraints (want to maintain rest length)

[color=yellow][b]Code: Spring Between Two Particles[/b][/color]
[code]
var k = 100.0  # Spring stiffness
var damping = 0.9  # Energy loss
var rest_length = 1.0  # Desired distance

func apply_spring_force(particle_a, particle_b):
    # Current distance
    var delta_pos = particle_b.position - particle_a.position
    var current_length = delta_pos.length()

    # Spring force: F = -k × (current_length - rest_length)
    var displacement = current_length - rest_length
    var spring_magnitude = k * displacement

    # Direction: toward/away from other particle
    var spring_direction = delta_pos.normalized()

    # Apply force
    var spring_force = spring_direction * spring_magnitude
    particle_a.apply_force(spring_force)
    particle_b.apply_force(-spring_force)  # Newton's Third Law

# When stretched: spring pulls particles together
# When compressed: spring pushes particles apart
# Result: particles oscillate around rest length
[/code]

**Soft body = many particles + many springs** - creates deformable mesh.

Examples:
- **Cloth** - grid of particles, springs between neighbors
- **Jelly** - volume of particles, springs maintain shape
- **Rope** - chain of particles, springs connect adjacent

**This is the physics of refusal** - soft bodies resist rigidity, deform under pressure, return to rest shape.

They are **bodies that negotiate** - springs try to preserve structure, but yield to external forces.

[hr]

[b]Constraints: Enforcing Relationships[/b]

A **constraint** is a rule that must always be true:
- **Distance constraint** - two particles stay fixed distance apart
- **Angle constraint** - three particles maintain angle
- **Collision constraint** - particle cannot pass through floor

Verlet integration makes constraints easy:

[color=yellow][b]Code: Distance Constraint[/b][/color]
[code]
func enforce_distance_constraint(particle_a, particle_b, target_distance):
    # Current distance
    var delta = particle_b.position - particle_a.position
    var current_distance = delta.length()

    # Difference from target
    var error = current_distance - target_distance

    # Correction direction
    var correction_direction = delta.normalized()

    # Move each particle half the error distance
    var correction = correction_direction * error * 0.5

    particle_a.position += correction
    particle_b.position -= correction

    # Particles instantly moved to satisfy constraint
    # No forces, just direct position adjustment
[/code]

**Constraints are hard rules** - unlike forces (which suggest), constraints **enforce**.

This creates **bounded freedom** - particles can move, but only within constraints.

**Queer resonance:**
- Constraints are not always oppressive (they can be chosen, negotiated, desired)
- Rope physics: freedom within connection (you can move, but we stay tethered)
- Cloth: collective structure through mutual constraint (no particle free, all bound to neighbors, yet system as whole deforms fluidly)

[hr]

[b]Flocking Revisited: No Leader, Emergent Direction[/b]

In forces_axioms, we saw **flocking** (Craig Reynolds' boids) - three simple forces create coordinated group motion:
1. **Separation** - avoid crowding
2. **Alignment** - match neighbors' velocity
3. **Cohesion** - move toward center of mass

**Why is flocking queer?**

[color=yellow][b]Decentralized Organization:[/b][/color]
- No leader decides "flock moves left"
- Each agent responds to **local neighbors** only
- Global pattern (flock turns, swirls, splits) **emerges** from local interactions

**This is non-hierarchical sociality** - no one in charge, no master plan, yet **coordinated collective action**.

[color=yellow][b]Collective Without Uniformity:[/b][/color]
- Agents align (move roughly same direction) but **not identically**
- Individual variation preserved within group cohesion
- Unity without erasure of difference

**This is queer solidarity** - moving together while maintaining individual trajectories.

[color=yellow][b]Affinity-Based Proximity:[/b][/color]
- Agents only respond to **nearby neighbors** (not all agents)
- Flocks can split, merge, form subgroups
- No fixed membership - boundaries are permeable

**This is chosen kinship** - you are affected by those near you, not by distant authority.

[hr]

[b]N-Body Problem: Chaos and Sensitivity[/b]

The **N-body problem**: given N bodies under mutual gravitational attraction, predict their motion.

**For N=2** (two bodies): **solvable** - stable orbits, analytical equations (Kepler's laws).

**For N≥3** (three or more bodies): **no general solution** - chaotic, sensitive to initial conditions.

[color=yellow][b]Code: Three-Body Simulation[/b][/color]
[code]
# Three bodies, mutual gravitational attraction
var bodies = [body_a, body_b, body_c]

func _physics_process(delta):
    # Calculate forces between all pairs
    for i in range(bodies.size()):
        for j in range(i + 1, bodies.size()):
            var force = calculate_attraction(bodies[i], bodies[j])
            bodies[i].apply_force(force)
            bodies[j].apply_force(-force)  # Newton's Third Law

    # Integrate motion (Verlet for stability)
    for body in bodies:
        body.integrate(delta)

# Result: chaotic trajectories
# Tiny change in initial position → completely different outcome
# Some configurations: stable orbits
# Most configurations: ejections, collisions, chaos
[/code]

**Three-body problem is deterministic chaos** - equations are known, but **future unpredictable**.

**This is the physics of contingency** - minute differences propagate into radically divergent futures.

**Queer implication:**
Your trajectory is **not predetermined** - small deviations from norm amplify into entirely different lives.

**Chaos = freedom within determinism** - the equations govern, but outcomes are **unknowable, open, multiple**.

[hr]

[b]The Queer Politics of Physics Simulation[/b]

Physics simulation reveals queer potentials:

**1. Emergence Over Blueprint**
- No central planner dictates flock's motion - it emerges
- Soft bodies have no "true" shape - they negotiate shape through forces
- Particle systems create fire/water/smoke without explicit fire/water/smoke code

**Emergence is non-reproductive generativity** - complexity arises without template, without plan.

**2. Decentralized Organization**
- Flocking: no leader, yet coordinated
- Particle systems: no central controller, yet collective patterns
- Soft bodies: no rigid skeleton, yet maintain coherence

**Decentralization is queer organizing** - affinity-based, local, emergent, not hierarchical.

**3. Bodies That Refuse Rigidity**
- Soft bodies deform, oscillate, yield
- Particles have lifespan (birth, life, death)
- Constraints negotiated, not absolute

**Soft bodies are queer bodies** - they resist fixity, adapt to pressure, return to rest but never static.

**4. Sensitivity to Initial Conditions**
- Chaos theory: tiny difference → divergent futures
- No predetermined path - contingency dominates
- Small deviations from norm create entirely different trajectories

**Chaos is queer temporality** - future unknowable, multiple possibilities, determinism without predictability.

**5. Affective Entanglement**
- Forces as affects (bodies affecting bodies)
- Flocking: agents respond to proximity (affinity-based)
- Constraints: connection as chosen relation (rope connects but allows movement)

**Physics is relational ontology** - no isolated agents, always entangled in fields, always affecting and affected.

[hr]

[b]What Physics Simulation Reveals[/b]

Physics simulation shows us:

1. **Integration methods** - Euler (simple, errors), Verlet (stable, constraints), RK4 (accurate, expensive)
2. **Particle systems** - many bodies, simple rules → emergent complexity
3. **Soft bodies** - particles + springs = deformable forms (cloth, jelly, rope)
4. **Constraints** - enforce relationships (distance, angle, collision)
5. **Flocking** - decentralized coordination, collective without hierarchy
6. **N-body chaos** - three or more bodies → unpredictable, sensitive to initial conditions
7. **Emergence over blueprint** - patterns arise from interaction, not design
8. **Decentralized organization** - no leader, affinity-based, local interactions
9. **Bodies that refuse rigidity** - soft, deformable, negotiating shape
10. **Chaos as freedom** - deterministic yet unknowable futures

**Physics simulation is the computational enactment of becoming** - discrete time steps approximating continuous motion, bodies affecting bodies, trajectories emerging from accumulated forces.

**It is also the algorithmic substrate for queer worlds** - decentralized, emergent, non-rigid, sensitive, relational.

**This is where the gay is in Nature of Code:**
- Flocking = queer sociality (no leader, affinity-based, collective without uniformity)
- Soft bodies = bodies that refuse fixity, negotiate under pressure
- Chaos = futures not predetermined, tiny deviations → divergent lives
- Emergence = generativity without reproduction, patterns without blueprint
- Affects = relational ontology, always entangled, always affecting and affected

**Nature of Code is not just physics pedagogy** - it is **computational queer theory**, showing how complex, non-hierarchical, adaptive, emergent systems arise from simple local rules.

**The algorithm can be queer.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Physics simulation uses numerical integration to compute motion over time: Euler (simple, fast, accumulates errors), Verlet (position-based, stable, preserves energy), RK4 (higher accuracy, more computation). Particle systems (many bodies, simple physics → emergent complexity like fire/water/smoke). Soft bodies (particles + springs = deformable forms like cloth/jelly). Constraints enforce relationships (distance, angle, collision). Flocking (separation + alignment + cohesion = decentralized coordination, queer sociality). N-body problem (N≥3 = chaos, sensitivity to initial conditions). Queer openings: emergence without blueprint, decentralized organization, bodies refusing rigidity, chaos as freedom, affective entanglement, relational ontology. Nature of Code as computational queer theory - algorithms can be queer.

[hr]

[color=orange][b]Conclusion:[/b] Where is the Gay in Nature of Code?[/color]

**The gay is everywhere.**

**Vectors** = frozen desire, non-normative directionality, pointing anywhere
**Forces** = affective transmission, bodies affecting bodies, mutual vulnerability
**Flocking** = queer sociality, no leader, emergent coordination, affinity-based
**Soft bodies** = refusal of rigidity, deformation under pressure, negotiated shape
**Chaos** = sensitivity, tiny deviations → divergent futures, freedom within determinism
**Emergence** = generativity without reproduction, patterns without blueprint
**Constraints** = chosen bonds, connection as negotiation (rope physics)
**Particle systems** = swarms, collective intelligence, decentralized life/death

**Nature of Code teaches:**
- Complex behavior emerges from simple local rules (no central control needed)
- Bodies are relational, always affecting and affected (no autonomous subjects)
- Futures are sensitive to initial conditions (not predetermined, radically contingent)
- Structures can be soft, adaptive, deformable (not rigid hierarchies)

**This is queer computational ontology** - the algorithm as site of non-normative possibilities.

**Physics is not neutral** - it encodes politics (what moves you? who controls? what resists?).

**Nature of Code reveals:** **The physics of freedom looks like flocking, soft bodies, chaos, emergence.**

**The gay is in the algorithm.**

'''
