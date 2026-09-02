Everything you have done to a vector so far, it held still for.

You walked it, flipped it, stretched it, asked two of them how much they agreed, crossed them and got a turn. Through all of it the arrow waited to be operated on. This hall is where it stops waiting, and it stops in two ways, so the hall is in two halves. In the first, there is an arrow at every point, and the room decides where you drift. In the second, there is one arrow, and the world keeps editing it.

## Everywhere at once

```gdscript
func field_at(p: Vector3) -> Vector3:
    var swirl := Vector3(-p.z, 0.0, p.x) * SWIRL_GAIN
    var radial := p * RADIAL_GAIN
    return (swirl - radial).limit_length(2.5)
```

<!-- @VectorFieldFlow -->

A console, and on it a floor of small arrows. Read the function that makes them: two terms, one that circles the origin and one that runs at it, subtracted. Nothing is stored. There is no list of arrows anywhere; the field is a *rule*, evaluated wherever anything asks, and the arrows you see are only the places where somebody asked. Between them the field is just as real and just as unseen.

```gdscript
func advect(pos: Vector3, vel: Vector3, delta: float) -> Array:
    var sample := field_at(pos)
    vel = vel.lerp(sample, 0.08) * 0.98
    return [pos + vel * delta, vel]
```

Watch a particle. It has no memory and no plan. It reads the arrow under its feet, leans toward it, and moves, and that is the whole of its intelligence. A field is force that has decided to be everywhere at once, and a thing inside a field does not need to know anything except where it is.

<!-- @weather_vector_field -->

Now step into one. Five metres square, a hundred and forty-four arrows on the floor, and two wind vectors at body height that you can take hold of. Pull them. They add the way you learned to add in the last hall, head to tail, and the sum is the weather.

```gdscript
func drive_storm(a: Vector3, b: Vector3) -> void:
    var sum := a + b
    _rain_material.gravity = rain_acceleration(sum, gravity_strength)
    _windsock.rotation.y = atan2(sum.x, sum.z)
    _anemometer_speed = sum.length()
```

Everything in the chamber answers to that one sum. The rain slants at it, and the slant is not decided by anyone: it is the ratio of the wind across to the gravity down, and equal amounts give exactly forty-five degrees. The windsock turns to its heading and stretches with its strength. The anemometer spins at its speed. The debris streaks downwind. None of those instruments measures the storm. Each is one projection of the storm's single vector into whatever that instrument can show, a yaw, a length, a slant, which is the last hall's projection again, with weather for the rail.

It is calm when you arrive. The weather is yours to make, and it is made by addition.

<!-- @ -->

## Edited over time

```gdscript
func _physics_process(_delta: float) -> void:
    ball.apply_central_force(acceleration * ball.mass)
    var velocity := ball.linear_velocity
    var position := ball.global_position
    _aim(velocity_arrow, velocity)
    _aim(position_arrow, position)
```

<!-- @VectorMotion -->

One ball, three arrows. Green from the origin to the ball: where it is. Cyan at the ball: where it is going. Orange, and this is the one you can take hold of: how its going is changing. Only the orange one is driven. Velocity is its running sum and position is velocity's, so the other two arrows are read back off the ball rather than set, and the fading trail behind it is the running sum of the running sum, drawn.

Grab the orange arrow and hold it still and the trail becomes a parabola. Position, velocity and acceleration are not three things. They are one quantity seen at three depths of change, and the ball is where all three depths are visible at once.

<!-- @launch_arc -->

Set an angle and a power and fire. You only ever launch a straight vector.

```gdscript
func launch_components(v0: float, theta: float) -> Vector2:
    return Vector2(v0 * cos(theta), v0 * sin(theta))
```

The launch splits into two parts the moment it leaves the pad: a sideways part that carries and never changes, and an upward part that fights gravity and loses. The angle is the whole negotiation between them.

```gdscript
func height_at(vy: float, t: float, gravity: float = 9.8) -> float:
    return vy * t - 0.5 * gravity * t * t
```

The curve is not yours. It is the world's answer to your straight line, and it costs exactly one squared term. Where the two parts are equal, at forty-five degrees, neither is wasted on the other and the range is greatest; thirty and sixty land in the same place, one high and slow, one low and fast. Aim straight up and the range is nothing and all the power goes into height. The pad knows all of this and marks the apex and the landing for you before the arc is flown.

<!-- @bubble_blaster -->

And a gun that wears its velocity on the outside. Pull the trigger and bubbles pour out; on the muzzle, an arrow shows the speed they leave with, and a faint cone shows how they spread. Crank the output and the arrow stretches, the cone widens, and the bubbles fly faster and further.

This is where the two halves of the hall meet. One bubble leaving the muzzle is motion, a vector the world will edit, and gravity begins editing it at once. A stream of them is a field, a velocity assigned to every point of the cone. Every emitter is a little field, and every particle in it is a little motion, and the difference between the halves was only ever whether you were looking at one arrow or all of them.

<!-- @ -->

## Spread over space, spread over time

A field is force spread over space. Motion is force spread over time. Both are vectors that refuse to hold still, and you have now stood inside one and thrown the other.

What has not happened yet is a name. The storm pushed you and the pad threw you and gravity bent the arc, and none of them was called anything but a vector. The next act names them: the forces doing the spreading, met at the size of your body.
