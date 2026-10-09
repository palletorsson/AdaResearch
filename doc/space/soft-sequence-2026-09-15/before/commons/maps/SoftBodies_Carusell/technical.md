# Spinning hub where cloth and mushrooms learn what centripetal force does to compliant matter

The jelly cube taught that soft bodies deform under gravity and recover through spring constraints. The carousel adds rotation — a rigid hub spinning at constant angular velocity, with soft bodies attached by joints and hanging under the combined influence of gravity and centripetal acceleration. The physics shifts from linear to rotational, and the soft body's response becomes directionally dependent: gravity pulls down, centripetal force pulls outward, and the material negotiates between them.

## The Carousel Hub: Rigid Rotation

The revolving_joy_ride artifact is a RigidBody3D hub rotating about its vertical axis at a configurable angular velocity. The hub does not deform. It is the rigid reference frame against which all soft body behavior is measured.

```gdscript
@export var ride_speed: float = 1.5  # radians per second
var hub: RigidBody3D

func _physics_process(delta: float) -> void:
    hub.angular_velocity = Vector3(0.0, ride_speed, 0.0)
```

Angular velocity is set directly each frame rather than applying torque, ensuring constant rotation regardless of load. The hub's children — arms, chains, attachment points — rotate with it as a rigid assembly. Soft bodies connect to the ends of these arms through PinJoint3D constraints.

## PinJoint3D: Attaching Soft to Rigid

The connection between the carousel arm and the soft body is a pin joint — a single point constraint that allows rotation but not translation. In Godot, PinJoint3D connects two physics bodies at a shared world-space point.

```gdscript
func _attach_soft_body(arm_tip: Node3D, soft_body: SoftBody3D) -> void:
    var pin := PinJoint3D.new()
    pin.global_position = arm_tip.global_position
    pin.node_a = arm_tip.get_path()
    pin.node_b = soft_body.get_path()
    add_child(pin)
```

The pin constrains one vertex of the soft body to the arm tip. All other vertices are free to move under physics. This creates the asymmetry that makes the carousel interesting: one point follows the rigid rotation exactly, while the rest of the body responds to the forces that rotation creates.

## Centripetal Acceleration on a Soft Body

A point mass at radius r from the rotation axis, spinning at angular velocity omega, experiences centripetal acceleration:

```
a_centripetal = omega^2 * r
```

directed radially outward (in the rotating frame) or radially inward (in the inertial frame as the centripetal force maintaining circular motion). For a soft body, each vertex sits at a different radius. Vertices farther from the axis experience greater outward pull. Vertices closer to the axis experience less.

This creates a force gradient across the body. The soft mushroom, hanging from a chain attached to the hub, experiences the strongest outward pull at its lowest point (farthest from the axis when swung outward) and the weakest at its attachment point (on the axis). The spring network responds to this gradient by stretching — the body elongates radially, compressed along the rotation axis and extended outward.

```gdscript
# Pseudocode for per-vertex centripetal force in rotating frame
func _apply_centripetal_forces(soft_body: SoftBody3D, omega: float,
                                axis_pos: Vector3) -> void:
    for i in range(soft_body.get_point_count()):
        var point_pos := soft_body.get_point_position(i)
        var to_axis := point_pos - axis_pos
        to_axis.y = 0.0  # radial component only
        var radius := to_axis.length()
        var centripetal_force := to_axis.normalized() * omega * omega * radius
        # In Godot, SoftBody3D handles this internally through
        # the physics engine when the body is a child of a rotating parent
```

In practice, Godot's physics engine computes these forces automatically when the soft body is connected to a rotating rigid body through joints. The pseudocode illustrates the underlying mechanics: force proportional to omega squared times radius, directed outward in the rotating frame.

## The Swing Angle: Gravity vs. Centripetal Force

A pendulum hanging from a carousel arm settles at an angle where gravity and centripetal force balance. For a point mass, this equilibrium angle theta satisfies:

```
tan(theta) = omega^2 * R / g
```

where R is the horizontal distance from the axis to the attachment point, g is gravitational acceleration, and theta is the angle from vertical. At low omega, gravity dominates and the body hangs nearly vertical. At high omega, centripetal force dominates and the body extends nearly horizontal.

For a soft body, there is no single swing angle. Each vertex finds its own equilibrium based on its distance from the attachment point, the stiffness of the springs connecting it to its neighbors, and the cumulative pull of the vertices below it. The body traces a curve — taut near the attachment, sweeping outward, with the lowest point at the maximum extension.

The soft mushroom makes this visible. Its cap, being wider and more massive than its stem, accumulates more centripetal force and swings further outward than the narrow attachment chain. The body's geometry determines its response to rotation. A sphere would extend uniformly. A mushroom extends asymmetrically, cap leading, stem trailing.

## Cloth Straps Under Rotation

The cloth_straps artifact adds a different soft body topology to the carousel: flat strips of cloth rather than volumetric mushrooms. A cloth strap pinned at its top edge to the carousel frame responds to rotation differently than a volumetric body because it has no internal volume to compress.

Each strap is a SoftBody3D configured as a narrow rectangular mesh. The top row of vertices is pinned to the carousel frame using `set_point_pinned()`. The remaining vertices hang freely.

```gdscript
func _create_cloth_strap(width: int, height: int, frame_bar: Node3D) -> SoftBody3D:
    var cloth := SoftBody3D.new()
    # Configure as narrow strip
    cloth.linear_stiffness = 0.8
    cloth.pressure_coefficient = 0.0  # no inflation — it's a flat strip
    cloth.simulation_precision = 5
    # Pin top row
    for col in range(width):
        cloth.set_point_pinned(col, true)
    return cloth
```

Under rotation, the strap extends outward like the mushroom but with a key difference: being two-dimensional, it has no resistance to folding along its length. Wind effects — the air resistance of the rotating strap — create flutter and ripple that volumetric bodies don't exhibit. The strap's response reveals the aerodynamic component of rotation that solid soft bodies absorb into bulk deformation.

When the player walks through the hanging straps, each one parts around the body, the pinned top edge maintaining contact with the frame while the free bottom edge swings. This is the Soft Bodies sequence's first tactile encounter: the learner feels the cloth against their virtual hands, watches it deform around their presence, and sees it recover when they pass.

## Collision During Rotation

The carousel introduces collision at speed. Soft bodies on the carousel arms sweep through space continuously. When they contact static obstacles — pillars, walls, the player — the collision happens at velocity, not at rest.

Collision response for a soft body moving at rotational velocity involves the same per-vertex detection as the stationary case, but the relative velocity at the contact point adds kinetic energy to the deformation. A mushroom striking a pillar at the carousel's periphery compresses more dramatically than one gently placed against the same surface, because the impact velocity is omega times the radius.

```gdscript
# Impact velocity at the collision point
var v_impact := omega * radius  # tangential velocity
# Kinetic energy at impact
var KE := 0.5 * mass * v_impact * v_impact
```

Higher angular velocity means more violent collisions. The soft body absorbs the impact through deformation — springs compress, energy converts from kinetic to elastic potential, then releases as the body bounces or wraps. The damping coefficient determines how much energy dissipates versus how much rebounds. High damping: the mushroom splatters against the pillar and oozes off. Low damping: it bounces vigorously, oscillating for multiple rotation cycles.

## Interactive Manipulation: Grab and Throw

The grab_long_stick and pick_up_cube artifacts introduce VR hand interaction with the carousel system. The learner can grab a stick and swing it into the path of rotating soft bodies, creating obstacle collisions on demand. The pick_up_cube provides a deformable object to throw at the carousel — testing how a free soft body responds when struck by a rotating rigid arm.

The interaction creates a three-body physics scenario: the rigid carousel (rotating), the interactive tool (player-controlled), and the soft body (physics-driven). The soft body is always the yielding partner — it deforms around both the carousel's demands and the player's interventions, demonstrating that compliance is not passivity but a particular kind of responsiveness to multiple simultaneous forces.

## Angular Velocity as Material Revealer

The carousel's key pedagogical function is that angular velocity acts as a probe. At zero rotation, the soft bodies hang vertically — their response is identical to the jelly cube's gravity-only behavior. At low rotation, slight outward lean reveals centripetal sensitivity. At high rotation, the bodies extend horizontally, springs stretched to their limits, material character fully exposed.

Different materials respond differently to the same rotation speed. A stiff mushroom (high spring constant) barely extends — it maintains its shape against centripetal pull. A soft mushroom (low spring constant) stretches dramatically, elongating into an oval or even separating if stiffness is insufficient to maintain connectivity. The cloth strap, having no volumetric stiffness, extends and flutters regardless.

```gdscript
# Sweep angular velocity to reveal material character
var omega_values := [0.5, 1.0, 1.5, 2.0, 3.0]
# At omega = 0.5: subtle lean, all materials similar
# At omega = 1.5: clear differentiation between stiff and soft
# At omega = 3.0: extreme extension, some materials fail
```

The carousel is a rheometer — a device that measures material properties by applying controlled deformation. Industrial rheometers spin materials to measure viscosity and elasticity. The carousel does the same thing, using angular velocity as the control variable and visible deformation as the readout. The learner does not need equations to understand stiffness. They need to see what happens when the ride speeds up.

## The Full Carousel Loop

```gdscript
func _physics_process(delta: float) -> void:
    # 1. Maintain hub rotation
    hub.angular_velocity = Vector3(0.0, ride_speed, 0.0)

    # 2. Physics engine handles:
    #    - PinJoint3D constraints (soft body attached to arms)
    #    - Gravity on all soft body vertices
    #    - Centripetal forces through joint propagation
    #    - Soft body internal spring resolution
    #    - Collision with static obstacles and player

    # 3. Wind/drag on cloth straps (optional)
    for strap in cloth_straps:
        _apply_air_resistance(strap, ride_speed)

    # 4. Player interaction
    _check_grab_interactions()
```

Godot's physics engine handles most of the work internally. The SoftBody3D nodes compute their own spring forces, constraint satisfaction, and collision response. The pin joints propagate the hub's rotation to the attachment points. The script manages the hub's angular velocity and any additional forces (wind, drag) not handled by the built-in physics.

The carousel is deceptively simple. One rigid body spinning. Soft things attached. Gravity pulling down. But the interaction between rotation, gravity, spring topology, and collision produces behavior that no single force could generate alone. The mushroom's swing angle, the cloth's flutter, the deformation on impact — all emerge from the superposition of forces acting on a compliant material connected to a rotating frame.
