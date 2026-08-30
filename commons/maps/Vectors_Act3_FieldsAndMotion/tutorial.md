# Fields and Motion

A vector at every point, and a vector the world keeps editing. Before either, addition and scaling must already be ordinary.

Write the field as a function from place to push.

```gdscript
func field_at(p: Vector3) -> Vector3:
    var swirl := Vector3(-p.z, 0.0, p.x) * SWIRL_GAIN
    var radial := p * RADIAL_GAIN
    return (swirl - radial).limit_length(2.5)
```

Two terms subtracted: one that circles the origin, one that runs at it. Nothing is stored — the field is evaluated wherever it is asked, and the arrows on the floor are only samples of it.

Let a particle read its local instruction and go.

```gdscript
func advect(pos: Vector3, vel: Vector3, delta: float) -> Array:
    var sample := field_at(pos)
    vel = vel.lerp(sample, 0.08) * 0.98
    return [pos + vel * delta, vel]
```

The particle has no memory and no plan. It leans toward the vector under its feet and moves. The damping is what stops it outrunning the field it is reading.

Let two fields act on the same particle at once.

```gdscript
func rain_acceleration(wind: Vector3, gravity_strength: float) -> Vector3:
    var down := Vector3(0.0, -gravity_strength * 9.8, 0.0)
    var across := Vector3(wind.x, 0.0, wind.z) * 3.0
    return down + across
```

Rain is a particle advected through gravity and wind together. Nothing decides the slant of the storm — the addition does, and the ratio between the two terms is the angle.

Drive every instrument from the one sum.

```gdscript
func drive_storm(a: Vector3, b: Vector3) -> void:
    var sum := a + b
    _rain_material.gravity = rain_acceleration(sum, gravity_strength)
    _windsock.rotation.y = atan2(sum.x, sum.z)
    _anemometer_speed = sum.length()
```

A dial is not a measurement of the storm. It is one projection of the storm's single vector into whatever that dial can show — a yaw, a speed, a slant.

Drive a body from the top of the chain.

```gdscript
func _physics_process(_delta: float) -> void:
    ball.apply_central_force(acceleration * ball.mass)
    var velocity := ball.linear_velocity
    var position := ball.global_position
    _aim(velocity_arrow, velocity)
    _aim(position_arrow, position)
```

Only acceleration is driven. Velocity is its running sum and position is velocity's, so the arrows below are read back rather than set. Position, velocity and acceleration are one quantity seen at three depths of change.

Split a launch into the part that carries and the part that fights.

```gdscript
func launch_components(v0: float, theta: float) -> Vector2:
    return Vector2(v0 * cos(theta), v0 * sin(theta))
```

vx carries you sideways and never changes. vy fights gravity and loses. The angle is the whole negotiation between them.

Let gravity write the rest.

```gdscript
func height_at(vy: float, t: float, gravity: float = 9.8) -> float:
    return vy * t - 0.5 * gravity * t * t
```

You only ever launch a straight vector. The curve is the world's answer, and it costs exactly one squared term.

Read the arc's two landmarks off the components.

```gdscript
func apex_and_range(v0: float, theta: float, gravity: float = 9.8) -> Vector2:
    var vx := v0 * cos(theta)
    var vy := v0 * sin(theta)
    var t_land := 2.0 * vy / gravity
    return Vector2(vy * vy / (2.0 * gravity), vx * t_land)
```

Both numbers follow from vx and vy and nothing else. Range peaks at 45°, where the two components are equal and neither is wasted on the other.

You can now sample a field at any point, advect a body through it, superpose two fields into one push, run the acceleration-velocity-position chain, and decompose a launch into the components that set its arc. A field is force spread over space; motion is force spread over time. Act IV names the forces doing the spreading.
