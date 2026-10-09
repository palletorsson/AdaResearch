# Breathing walls and dancing flags — where soft bodies learn to negotiate obstacles

The first two maps established deformation (jelly cube) and rotation (carousel). Now the soft body meets the obstacle. Static and dynamic rigid geometry forces the compliant material to continuously re-adapt its shape, revealing the collision response pipeline in detail and introducing aerodynamic force through wind-cloth interaction.

## Penalty-Based Collision: Soft Against Rigid

When a soft body vertex penetrates a rigid surface, the physics engine must push it back. The simplest approach is penalty force — a spring-like repulsion proportional to penetration depth:

```gdscript
func resolve_soft_rigid_collision(point: MassPoint, surface_normal: Vector3,
                                   surface_point: Vector3, penalty_k: float) -> void:
    var penetration := (surface_point - point.position).dot(surface_normal)
    if penetration > 0.0:
        # Point is behind the surface — push it out
        point.position += surface_normal * penetration
        # Penalty force for future frames
        point.acceleration += surface_normal * penetration * penalty_k / point.mass
```

The penalty stiffness `penalty_k` governs how aggressively the surface repels penetrating vertices. Too low, and the soft body sinks partially into obstacles before bouncing back — visible interpenetration that breaks the illusion. Too high, and the collision response becomes unstable, potentially launching vertices at extreme velocities. The balance mirrors the spring stiffness problem from the jelly cube: compliance versus stability, with the CFL condition lurking as the upper bound.

For Godot's SoftBody3D, collision against StaticBody3D and RigidBody3D surfaces uses the Bullet or GodotPhysics engine's built-in constraint solver rather than explicit penalty forces. The principle is identical — penetrating vertices are projected onto the surface — but the implementation handles edge cases (grazing contacts, vertex-edge collisions, multiple simultaneous contacts) that a naive penalty approach misses.

## The Breathing Room: Dynamic Obstacle Geometry

The breathing_room artifact introduces obstacles that move. Two SoftBody3D walls oscillate sinusoidally, expanding inward on the inhale and contracting on the exhale:

```gdscript
# From breathing_room @identity:
# P(t) = (sin(t * breath_speed) + 1) * 0.5 * breath_amplitude
@export var breath_speed: float = 0.8
@export var breath_amplitude: float = 1.0

func _physics_process(delta: float) -> void:
    var pressure := (sin(Time.get_ticks_msec() * 0.001 * breath_speed) + 1.0) * 0.5
    pressure *= breath_amplitude
    for wall in breathing_walls:
        wall.pressure_coefficient = pressure
```

The pressure_coefficient in Godot's SoftBody3D controls internal pressure — positive values inflate the body outward, simulating a pressure differential across the surface. By oscillating this coefficient sinusoidally, the wall expands and contracts rhythmically. The corridor between two such walls alternately widens and narrows, forcing any soft body (or player) passing through to time their passage.

This is collision with a moving target. A soft body caught between contracting walls experiences bilateral compression — pressure from both sides simultaneously. The spring network must transmit forces laterally while the body squeezes through. Structural springs along the compression axis absorb most of the load. Shear springs prevent the body from extruding sideways. The body flattens, elongates perpendicular to the compression, and reforms when the walls retract.

```gdscript
# Bilateral compression creates force balance:
# Left wall pushes right → structural springs compress → right side bulges
# Right wall pushes left → structural springs compress → left side bulges
# Net effect: body thins along compression axis, extends along free axes
# Volume approximately conserved through spring network redistribution
```

## The Flagdancer: Aerodynamic Force on Cloth

The flagdancer artifact demonstrates wind acting on a constrained cloth surface. A cloth mesh pinned along one edge — the flagpole — responds to a wind force field that varies in space and time.

Wind force on a surface depends on the angle between the wind direction and the local surface normal. A surface facing into the wind receives maximum force. A surface parallel to the wind receives none. This is the dot-product interaction:

```gdscript
func _apply_wind_to_cloth(cloth: SoftBody3D, wind_dir: Vector3,
                           wind_speed: float, time: float) -> void:
    for i in range(cloth.get_point_count()):
        if cloth.is_point_pinned(i):
            continue
        var normal := _estimate_vertex_normal(cloth, i)
        var exposure := abs(normal.dot(wind_dir))
        var turbulence := sin(time * 2.5 + cloth.get_point_position(i).x * 1.5) * 0.4
        var force := wind_dir * wind_speed * exposure * (1.0 + turbulence)
        # Apply as impulse to the specific vertex
        var current_pos := cloth.get_point_position(i)
        cloth.set_point_position(i, current_pos + force * 0.001)
```

The `exposure` factor means the flag billows when facing the wind and goes slack when edge-on. Turbulence adds spatial and temporal variation — the sine function's dependence on both time and x-position creates rippling waves across the surface rather than uniform displacement.

The flagdancer implements this through skeletal animation rather than per-vertex physics — bone displacement driven by sinusoidal functions gives the visual impression of wind-driven cloth without the computational cost of full spring-mass simulation. This is a deliberate simplification. The visual result is convincing for a flag because flags are thin, constrained at one edge, and the viewer expects periodic rippling. A full cloth simulation would be more accurate but unnecessary for the pedagogical goal: making wind-cloth interaction visible.

## Collision Modes: Wrapping, Compression, Sliding

Three distinct collision behaviors emerge when soft bodies meet obstacles:

**Wrapping** occurs when a soft body encounters a convex obstacle. Vertices in contact stay on the surface. Adjacent vertices, pulled by springs, drape around the obstacle's curvature. The body conforms to the obstacle's shape, the spring network distributing the contact forces across many vertices. Wrapping is what distinguishes soft collision from rigid collision — the body doesn't bounce off, it envelops.

**Compression** occurs between parallel surfaces — the breathing room scenario. The body thins along the compression axis. Springs parallel to the compression resist shortening. Springs perpendicular transmit the squeeze outward. Volume is approximately conserved through the spring network's cooperative response.

**Sliding** occurs when a soft body moves tangentially along a surface. Friction between the contacting vertices and the surface determines whether the body grips or glides. In Verlet-based systems, friction is implemented through the old_position manipulation:

```gdscript
func apply_surface_friction(point: MassPoint, surface_normal: Vector3,
                             friction_coeff: float) -> void:
    var velocity := point.position - point.old_position
    var normal_vel := surface_normal * velocity.dot(surface_normal)
    var tangent_vel := velocity - normal_vel
    # Reduce tangential velocity by friction coefficient
    point.old_position = point.position - (normal_vel + tangent_vel * (1.0 - friction_coeff))
```

High friction: the body grips the surface, deforms around it, drags along slowly. Low friction: the body slides freely, maintaining its shape while translating along the obstacle. The breathing_room with friction creates a peristaltic effect — the contracting walls grip the body and squeeze it forward, like a throat swallowing.

## Multi-Point Contact and Force Distribution

When a soft body drapes over an obstacle edge, some vertices rest on top while others hang freely below. The edge creates a discontinuity in the force distribution — vertices above the edge experience surface contact forces, vertices below experience only gravity and spring tension. The springs crossing the edge transmit the transition:

```gdscript
# Vertex A: on the platform surface, contact forces active
# Vertex B: hanging below the edge, only gravity and springs
# Spring A-B: transmits the weight of B (and everything below B)
#             upward to A, which is supported by the surface
# The spring tension at the edge equals the total hanging weight
# below the drape point — this is the catenary load
```

The drape profile — the curve the soft body traces from the supported surface to the hanging region — is approximately catenary, modified by the spring stiffness. Stiff springs produce a sharp bend at the edge. Soft springs produce a gradual curve. The drape shape is a direct readout of the material's bend resistance.

## Continuous Re-Adaptation

The breathing_room forces continuous re-adaptation because the obstacle geometry never stops changing. Unlike a static collision (where the soft body settles into equilibrium), oscillating walls prevent equilibrium from forming. The soft body is perpetually catching up:

1. Walls contract — body compresses
2. Springs store elastic energy — body resists
3. Walls retract — springs release, body expands
4. Body overshoots rest shape — oscillation begins
5. Before oscillation settles — walls contract again

The phase relationship between the wall's breathing cycle and the body's natural oscillation frequency determines the response character. If the wall breathes at the body's resonant frequency, deformation amplifies — constructive interference. If off-resonance, the body barely responds to the wall's oscillation. This is forced oscillation, the same physics as pushing a child on a swing: timing matters as much as force.

```gdscript
# Natural frequency of a spring-mass system:
# f_natural = (1 / 2*PI) * sqrt(k / m)
# If breath_speed matches f_natural, resonance occurs
# Deformation amplitude can exceed steady-state by 5-10x
```

## The Full Obstacle Pipeline

```gdscript
func _physics_process(delta: float) -> void:
    # 1. Update dynamic obstacles
    _update_breathing_walls(delta)
    _update_flagdancer_wind(delta)

    # 2. For each soft body:
    for body in soft_bodies:
        # a. Apply gravity
        # b. Apply spring forces (Hooke's law)
        # c. Verlet integration
        # d. Constraint satisfaction (multiple iterations)
        # e. Collision against static geometry
        # f. Collision against dynamic geometry (breathing walls)
        # g. Surface friction
        # h. Sync visual mesh
        pass  # handled internally by Godot's SoftBody3D

    # 3. Player interaction
    _check_grab_interactions()
```

The pipeline is the same six-step loop from Soft Body Deformation, extended with dynamic obstacle updates and friction. The key addition is step (f) — collision against geometry that moved since last frame. This requires re-evaluating contact points every frame rather than caching them, increasing computational cost but enabling the breathing room's continuous negotiation.
