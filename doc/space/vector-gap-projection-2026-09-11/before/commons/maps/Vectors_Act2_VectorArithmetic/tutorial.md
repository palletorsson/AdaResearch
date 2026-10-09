# Vector Arithmetic

What vectors do to each other. Before this, a vector must already be a direction and a length that can be slid anywhere without changing.

Add by walking one arrow from the other's tip.

```gdscript
func head_to_tail(a: Vector3, b: Vector3) -> Array[Vector3]:
    var origin := Vector3.ZERO
    return [origin, a, a + b]   # tail, joint, resultant head
```

b is drawn from a's tip, not from the origin. Moving it there is free, because a vector carries no address. The resultant is the arrow that closes the walk.

Subtract by flipping the second arrow and adding it.

```gdscript
func difference(a: Vector3, b: Vector3) -> Vector3:
    var b_flipped := -b
    return a + b_flipped
```

There is no second operation. a − b is a + (−b), and it points from b's tip to a's — the arrow of the gap between them.

Scale a direction without turning it.

```gdscript
func weight_of(mass: float) -> Vector3:
    return Vector3.DOWN * 9.8 * mass
```

A scalar multiplies the length and leaves the line alone. Negative scalars are the one exception: they keep the line and reverse the sense.

Ask two directions how much they agree.

```gdscript
func agreement(a: Vector3, b: Vector3) -> float:
    return clampf(a.normalized().dot(b.normalized()), -1.0, 1.0)
```

Between unit vectors the dot is cos θ. 1 is the same direction, 0 is square, −1 is opposed. One float stands in for a whole angle.

Recover the angle the dot hid.

```gdscript
func angle_between(a: Vector3, b: Vector3) -> float:
    return rad_to_deg(acos(agreement(a, b)))
```

acos undoes the cosine. The dot was never an angle — it is what an angle costs once both lengths have been divided out.

Cast one vector's shadow onto another's line.

```gdscript
func project(a: Vector3, onto: Vector3) -> Vector3:
    var n := onto.normalized()
    return n * a.dot(n)
```

a·n̂ is how far along the rail the shadow falls. Multiplying by n̂ puts that number back on the rail as a vector. That is the projection.

Keep what the shadow left behind.

```gdscript
func reject(a: Vector3, onto: Vector3) -> Vector3:
    return a - project(a, onto)
```

The rejection is perpendicular to the rail by construction, and the two parts add back to a exactly. Every vector splits into a part along another and a part square to it.

Push across an arm instead of along it.

```gdscript
func torque(arm: Vector3, force: Vector3) -> Vector3:
    return arm.cross(force)
```

r × F points up the axle, a third direction perpendicular to both. Its length is |r||F| sin θ, so a push straight down the arm produces nothing at all.

Measure the half of the push the turn threw away.

```gdscript
func wasted_half(arm: Vector3, force: Vector3) -> Vector3:
    var r := arm.normalized()
    return r * force.dot(r)
```

What the projection keeps, the cross discards. Dot and cross are the same question asked in opposite directions: how much do these agree, and how much do they refuse to.

You can now add, subtract and scale vectors, measure agreement with the dot, split one vector along and across another, and produce the third direction born when two refuse to align. To add is to walk; to dot is to agree; to cross is to turn. Act III takes these operations and spreads them over space and time.
