var text = '''[b]Forces[/b]
[i]The Building Blocks of Motion[/i]

Forces are vectors that cause objects to accelerate according to Newton's Second Law: F = ma.

In nature, the complex behaviors we observe emerge from simple forces interacting with objects over time.

[code]
func apply_force(force: Vector2):
    # F = ma, so a = F/m
    acceleration += force / mass

func update(delta: float):
    velocity += acceleration * delta
    position += velocity * delta
    acceleration = Vector2.ZERO
[/code]

[hr]

[b]Gravity & Orbital Mechanics[/b]

Gravity comes in two main forms in simulations:

[i]Constant Gravity (g = 9.8 m/s²):[/i]
Creates predictable parabolic trajectories, useful for projectile motion in games, rain/snow effects, and platformer physics.

[i]Universal Gravitation:[/i]
Follows Newton's formula: F = G(m₁m₂)/r²
This creates orbital mechanics, N-body simulations, and gravitational slingshot effects.

[code]
func calculate_gravity(body1, body2):
    var direction = body2.position - body1.position
    var distance = direction.length()
    direction = direction.normalized()

    var G = 6.67e-11
    var force = G * body1.mass * body2.mass / (distance * distance)
    return direction * force
[/code]

[hr]

[b]Friction & Dampening[/b]

Friction transforms kinetic energy into heat, slowing objects to rest.

[i]Friction Types:[/i]
- Coulomb friction: F = μN (proportional to normal force)
- Drag friction: F = -cv (proportional to velocity)
- Squared drag: F = -cv² (proportional to velocity squared)

[code]
func apply_friction():
    var friction_coefficient = 0.05
    var friction = velocity.normalized() * -1.0
    friction *= friction_coefficient * mass
    apply_force(friction)

func apply_air_resistance():
    var drag_coefficient = 0.01
    var speed_squared = velocity.length_squared()
    var drag = velocity.normalized() * -drag_coefficient * speed_squared
    apply_force(drag)
[/code]

[hr]

[b]Attraction & Repulsion[/b]

Attraction and repulsion forces create some of the most interesting dynamic behaviors:
- Electromagnetism (charged particles, magnets)
- Molecular bonds
- Animal behaviors (flocking, predator avoidance)

These forces typically follow inverse square law: F ∝ 1/r²

[code]
func apply_attraction(particle, attractor, strength):
    var direction = attractor.position - particle.position
    var distance = max(direction.length(), 5.0)
    direction = direction.normalized()

    var force_magnitude = strength * particle.mass
    force_magnitude *= attractor.mass / (distance * distance)

    particle.apply_force(direction * force_magnitude)
[/code]

[hr]

[b]Complex Force Fields[/b]

When forces vary across space, they create force fields that produce complex, emergent behaviors.

[i]Flow Fields:[/i]
Direct objects along vector currents, simulating wind, fluid dynamics, and crowd movement.

Perlin noise creates organic, natural-looking flow patterns by generating smooth random variations over space.

[code]
func generate_flow_field(resolution, strength):
    var field = []
    for y in range(resolution):
        var row = []
        for x in range(resolution):
            var angle = noise.get_noise_2d(x * 0.1, y * 0.1) * TAU
            var force = Vector2(cos(angle), sin(angle)) * strength
            row.append(force)
        field.append(row)
    return field
[/code]
'''
