# Springs Lab

Hooke's law and its consequences. The force depends on displacement: stretch it, and it wants back.

Write the spring force.

```gdscript
func spring_force(anchor: Vector3, bob: Vector3, rest: float, k: float) -> Vector3:
    var arm := bob - anchor
    var stretch := arm.length() - rest
    return arm.normalized() * -k * stretch
```

NoC chapter 3's spring, verbatim: direction along the arm, magnitude proportional to how far from rest. Negative because it disagrees with you.

Damp it before it rings forever.

```gdscript
func damped(force: Vector3, velocity: Vector3, damping: float) -> Vector3:
    return force - velocity * damping
```

The mass-spring-damper station exposes all three knobs: mass, stiffness, damping. Critical damping is the setting where it returns home without a single overshoot.

Watch harmonic motion write a wave.

```gdscript
var x := amplitude * sin(TAU * frequency * t)
```

The harmonic demo is a spring's position graphed over time: oscillation is what Hooke's law looks like when nothing interrupts it. This is the door to the wavefunctions sequence.

Couple two pendulums.

```gdscript
func couple(a: Pendulum, b: Pendulum, k: float) -> void:
    var transfer := (a.angle - b.angle) * k
    a.acceleration -= transfer
    b.acceleration += transfer
```

A weak spring between two pendulums and the energy commutes — one dies as the other wakes, then back. The trade is the lesson.

Chain springs into a network.

```gdscript
for edge in spring_edges:
    var f := spring_force(nodes[edge.a].position, nodes[edge.b].position,
                          edge.rest, k)
    nodes[edge.b].acceleration += f / nodes[edge.b].mass
    nodes[edge.a].acceleration -= f / nodes[edge.a].mass
```

Every edge pushes both its ends, oppositely — Newton's third law, structural. The spring network and the kinetic sculpture are this loop, dressed up. Soft bodies, nine sequences from now, are this loop grown large.

Swing the chain, crank the hinge, press the slider.

```gdscript
# joints = constraints: a hinge keeps an axis, a slider keeps a line,
# a cone-twist keeps a wobble inside a cone
```

The joint playground rounds out the springs: constraints are forces the engine applies for you, to keep a promise about geometry.

> Try: tune the mass-spring-damper until the bob comes home fastest WITHOUT overshooting. You have found critical damping by feel.

> Try: pull the slingshot from the previous room in your mind — which station here is its force law?

Next: Gravity — the force that needs no anchor and no contact, only mass and distance.
