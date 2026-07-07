# Vector Operations Lab

Two products and their consequences. Dot answers *how aligned*; cross answers *which way is perpendicular*.

Take the dot product at the workbench.

```gdscript
var d := a.dot(b)   # |a||b|cos(θ)
```

One scalar out. Positive when the vectors agree, zero at right angles, negative when they oppose.

Align the dots with the aligner.

```gdscript
func alignment(a: Vector3, b: Vector3) -> float:
    return a.normalized().dot(b.normalized())
```

Normalizing first strips magnitude out of the answer. What remains is pure agreement, −1 to 1.

Recover the angle.

```gdscript
var angle := acos(clamp(alignment(a, b), -1.0, 1.0))
```

NoC exercise 5.9, solved on the bench: the dot product is how code measures angles without a protractor.

Cast a projection shadow.

```gdscript
func project(v: Vector3, onto: Vector3) -> Vector3:
    var n := onto.normalized()
    return n * v.dot(n)
```

The shadow station does this with light: the projection is the part of v that lies along the other vector.

Take the cross product.

```gdscript
var perp := a.cross(b)   # perpendicular to both
```

Its direction is the right-hand rule; its length is the area of the parallelogram the two vectors span.

Crank the torque.

```gdscript
func torque(arm: Vector3, force: Vector3) -> Vector3:
    return arm.cross(force)
```

The crank is the cross product with a handle. Push at right angles and the crank turns hardest; push along the arm and nothing happens — the cross of parallel vectors is zero.

Compute work at the energy station.

```gdscript
func work(force: Vector3, displacement: Vector3) -> float:
    return force.dot(displacement)
```

Work is the dot; torque is the cross. The two products split force into what moves you and what spins you.

Press the normal force demo.

```gdscript
var normal := surface_normal * gravity.dot(-surface_normal)
```

The ground pushes back along its normal, exactly hard enough. Projection again, wearing a physics costume.

> Try: at the torque crank, find the push direction that turns the crank not at all. Then check it against the dot aligner — what does the gauge read?

Next: Motion. The vectors stop posing and start moving — velocity, acceleration, and the bouncing ball.
