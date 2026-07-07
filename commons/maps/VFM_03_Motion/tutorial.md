# Motion 101 Lab

Nature of Code's Motion 101, walkable. Position accumulates velocity; velocity accumulates acceleration. That sentence is the whole engine.

Write the mover.

```gdscript
class_name Mover
extends Node3D

var velocity := Vector3.ZERO
var acceleration := Vector3.ZERO

func _physics_process(delta: float) -> void:
    velocity += acceleration * delta
    position += velocity * delta
    acceleration = Vector3.ZERO   # forces re-apply each frame
```

Three lines of accumulation. Every demo in this room — and every creature later in the spine — runs on this loop.

Bounce the ball.

```gdscript
func bounce(ball: Mover, bounds: AABB) -> void:
    for axis in 3:
        if ball.position[axis] < bounds.position[axis] \
        or ball.position[axis] > bounds.end[axis]:
            ball.velocity[axis] *= -1.0
```

NoC example 1.2 lifted into 3D (exercise 1.3): hitting a wall flips one component of velocity. The other two keep going — that's why the bounce looks honest.

Accelerate and decelerate.

```gdscript
func thrust(mover: Mover, amount: float) -> void:
    mover.acceleration += mover.velocity.normalized() * amount
```

Exercise 1.5: speed up along your own heading, brake against it. Acceleration changes velocity; velocity changes position; nothing changes position directly.

Slide down the friction ramp.

```gdscript
func friction(mover: Mover, mu: float) -> Vector3:
    return mover.velocity.normalized() * -mu
```

Friction is a force pointed exactly backwards. Scale it by the coefficient; the ramp's angle decides who wins.

Drop a ball into the fluid column.

```gdscript
func drag(mover: Mover, c: float) -> Vector3:
    var speed := mover.velocity.length()
    return mover.velocity.normalized() * -c * speed * speed
```

NoC example 2.5: drag grows with the *square* of speed. Fast things suffer more — watch the heavy and light balls reach different terminal velocities.

Point in the direction of motion.

```gdscript
func face_heading(mover: Mover) -> void:
    if mover.velocity.length() > 0.01:
        mover.look_at(mover.position + mover.velocity)
```

NoC example 3.3: rotation follows velocity. The trajectory artifact draws the path; the nose follows it.

Watch the cradle trade momentum.

```gdscript
# equal masses, elastic: velocities swap
var tmp := a.velocity; a.velocity = b.velocity; b.velocity = tmp
```

> Try: at the bouncing ball, predict which wall it hits next before it does. You are integrating velocity in your head.

> Try: on the friction ramp, find the slope where the ball neither speeds up nor slows down. That slope is the equation solved by eye.

Next: Forces proper — Newton's second law, mass, and `apply_force`, in the Forces Foundations room.
