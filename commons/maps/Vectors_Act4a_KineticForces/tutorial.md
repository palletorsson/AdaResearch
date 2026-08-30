# Kinetic Forces

The named forces that bend a path, met at the size of your body. Before them, motion must already be a vector the world edits, and the dot product must already mean agreement.

Pay only for the part of a push that goes the world's way.

```gdscript
func work_done(force: Vector3, displacement: Vector3) -> float:
    return force.dot(displacement)
```

W = F·d is the dot product with its costume off. W = F d cos θ is the same line written out. Push square to the motion and the work is zero however hard you push.

Split the push at the handle.

```gdscript
func push_split(magnitude: float, theta: float) -> Array[Vector3]:
    var along := Vector3(magnitude * cos(theta), 0.0, 0.0)
    var into_ground := Vector3(0.0, -magnitude * sin(theta), 0.0)
    return [along, into_ground]
```

Raise the mower's handle and θ grows: the along-part shrinks, the into-ground part grows, the total is unchanged. Effort is conserved. Usefulness is not.

Charge rent on speed.

```gdscript
func drag_step(velocity: Vector3, b: float, delta: float) -> Vector3:
    return velocity * (1.0 - clampf(b * delta, 0.0, 0.6))
```

Drag is proportional to velocity and against it, so it slows you to nothing and never reverses you. Air is a small b; honey is a large one.

Ask how far the rent lets you get.

```gdscript
func distance_under_drag(v0: float, b: float, t: float) -> float:
    return (v0 / b) * (1.0 - exp(-b * t))
```

The integral of v₀e^(−bt). As t grows the exponential goes to zero and the distance stops at v₀/b — a finite reach, no matter how long you coast.

Tilt the floor and let gravity split itself.

```gdscript
func slope_components(theta: float) -> Vector2:
    return Vector2(sin(theta), cos(theta))   # down-slope, into-slope, for mg = 1
```

A slope does not change gravity. It changes how much of gravity points along your escape — the projection and the rejection of one downward vector against the ramp.

Find the angle where holding on stops working.

```gdscript
func slides(theta: float, mu: float) -> bool:
    var down_slope := sin(theta)
    var friction := minf(mu * cos(theta), down_slope)
    return down_slope - friction > 0.0
```

Friction can match the down-slope pull but never exceed it. Divide the condition through by cos θ and it becomes tan θ > μ — the angle decides, and the weight cancels out.

Aim an acceleration at a centre nothing reaches.

```gdscript
func centripetal(speed: float, radius: float, angle: float) -> Vector3:
    var pos := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
    return -pos.normalized() * (speed * speed / radius)
```

Velocity stays tangent to the ring, the force perpendicular to it, so it changes direction and never speed. Double the speed and a = v²/r quadruples. That is why fast turns throw you.

Find the point two bodies agree to circle.

```gdscript
func barycenter_offsets(m1: float, m2: float, separation: float) -> Vector2:
    var total := m1 + m2
    return Vector2(separation * m2 / total, separation * m1 / total)
```

The shared centre sits where m₁d₁ = m₂d₂, closer to the heavier body. Neither body stands on it. Make one heavier and it slides toward that one, both orbits resizing to keep the trade.

Pull both ways at once.

```gdscript
func mutual_pull(star: Vector3, planet: Vector3, g_m1_m2: float) -> Array[Vector3]:
    var to_planet := planet - star
    var f := g_m1_m2 / maxf(to_planet.length_squared(), 0.01)
    var dir := to_planet.normalized()
    return [dir * f, -dir * f]
```

F = G m₁m₂/r² is one force handed out in two opposite directions. An orbit is two things falling toward each other and missing, forever, around a point that belongs to neither.

You can now compute the work a slanted push does, decay a velocity through a medium, decompose weight on a ramp and predict when it gives way, aim an acceleration inward, and locate the centre two masses share. Work, drag, launch, turn, fall — every one is a force bending a path. Act IV-b holds the forces that give the path back.
