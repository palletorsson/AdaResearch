Nothing in the last hall acted on anything. This one is where vectors first act on each other, and the hall is built to say it twice: every idea once as a toy in your hand, then once at the size of a room you step into.

There are six operations. Three verbs carry them, and the room's own reflection puts them in one line at the end. You will arrive there having done each one with your hands.

## To add is to walk

```gdscript
func head_to_tail(a: Vector3, b: Vector3) -> Array[Vector3]:
    var origin := Vector3.ZERO
    return [origin, a, a + b]   # tail, joint, resultant head
```

<!-- @vector_add -->

Two pads on the front of a console, one per vector. Drag a pad and that arrow's tip follows your hand: cyan for the first, amber for the second, and the second is drawn *from the first's tip*, not from the origin. Moving it there costs nothing, because you learned in the last hall that a vector has no address. The green arrow that closes the walk is the sum.

That is the whole of addition. Not a count. A walk: go a, then go b, and a plus b is where you are standing.

<!-- @vector_addition_walk -->

Now step into it. Three metres of grid, half a metre to a line, and the endpoints at body height where you can take hold of them. Walk the first arrow. Walk the second from where the first left you. The parallelogram draws itself around you, and the resultant is the diagonal you would have taken if you had known where you were going.

<!-- @ -->

## Subtraction is the gap

```gdscript
func difference(a: Vector3, b: Vector3) -> Vector3:
    var b_flipped := -b
    return a + b_flipped
```

<!-- @vector_sub -->

The same console, flipped. Set a and b, and watch what is drawn: a, then *minus* b head to tail, with a faint ghost of the original b left standing so you can see the flip happen. The result points from b's tip back to a's. That is what subtraction is, and read the code again to see what it is not: there is no second operation. a minus b is a plus the reverse of b, and the arrow you get is the arrow of the gap between them, the one that says how far, and which way, one thing is from another.

<!-- @ -->

## A volume knob for a direction

```gdscript
func weight_of(mass: float) -> Vector3:
    return Vector3.DOWN * 9.8 * mass
```

<!-- @example_2_3_gravity_scaled_by_mass_vr -->

Three masses on a ladder, half a kilogram, one and a half, three, and over each a force arrow pointing at the floor. Every arrow points the same way. Only the lengths differ, and they differ in exactly the ratio of the masses, because a scalar multiplies a length and leaves the line alone.

A scalar cannot turn a vector. It can stretch it, shrink it, and, if it is negative, reverse it along the same line, and that is the whole of what a plain number can do to a direction. Gravity is the room's example because it is the one scalar you have been carrying since you arrived: nine point eight, times whatever you weigh, straight down.

<!-- @ -->

## To dot is to agree

```gdscript
func agreement(a: Vector3, b: Vector3) -> float:
    return clampf(a.normalized().dot(b.normalized()), -1.0, 1.0)
```

<!-- @dot_aligner -->

A turret on a pedestal, and a cube drifting past it. The gold arrow is where the turret aims; the cyan arrow is the direction to the cube. Swivel until they agree, and watch the charge: it is one number, the dot of the two directions, and it climbs from nothing as the angle closes. At an agreement of 0.985, which is within ten degrees, the beam locks and the cube turns from red to green.

That number is the cosine of the angle between them, once both lengths have been divided out. One float stands in for a whole angle: one is the same direction, zero is square on, minus one is opposed. The dot product was never an angle. It is what an angle *costs*.

```gdscript
func angle_between(a: Vector3, b: Vector3) -> float:
    return rad_to_deg(acos(agreement(a, b)))
```

<!-- @vector_dot_product_xl -->

Five metres square, and the two arrows share an origin you can stand at. Take hold of either and swing it; the readout above you gives the dot and the angle side by side, so you can watch one fall as the other opens. Stretch the second with the slider and the dot grows while the angle does not move. The hinge between them is the angle made into a thing you can push.

<!-- @ -->

## The part of you that lives on someone else's line

```gdscript
func project(a: Vector3, onto: Vector3) -> Vector3:
    var n := onto.normalized()
    return n * a.dot(n)
```

<!-- @projection_shadow -->

A sun overhead, a rail on the floor, and an object floating off to one side of it. Its shadow lands on the rail, and the distance of that shadow from the origin is the dot of the object's position with the rail's direction. Multiply that number back along the rail and you have the projection: the part of the object that lives on the rail's line.

```gdscript
func reject(a: Vector3, onto: Vector3) -> Vector3:
    return a - project(a, onto)
```

The perpendicular drop from the object to its shadow is the rest. Every vector splits this way, into a part along another and a part square to it, and the two parts add back to the original exactly.

<!-- @vector_projection_reflection_xl -->

Walk into it. A vector arrives at a glowing plane and comes apart against it: the projection lying in the plane, the reflection leaving it. Take hold of the plane's normal and tilt it, and both halves recompute as you turn. This is the operation a mirror performs, and a floor, and every surface a thing has ever bounced off.

<!-- @ -->

## To cross is to turn

```gdscript
func torque(arm: Vector3, force: Vector3) -> Vector3:
    return arm.cross(force)
```

<!-- @torque_crank -->

A lever arm on a flywheel's hub, and a push. The cross product of the arm and the push is a third arrow, gold, pointing up the axle, and the wheel turns about it. Its length is the two lengths times the sine of the angle between them, and read what that means with your hands: push straight along the arm and nothing happens at all. Push square across it and the wheel spins hardest. The cross product is the turn left over when two directions refuse to align.

You have used it before without being told. Two rooms into the first chapter, every face in the museum got its direction from two edges crossed at a corner. Here the same operation, with a push instead of an edge, is what makes anything turn.

<!-- @vector_cross_product_xl -->

Five metres square. Two arrows span a glowing parallelogram on the floor, and the purple arrow rises out of it, perpendicular to both. Swing either arrow and the parallelogram thins toward nothing as they line up, and the purple arrow shrinks with it. The paddle wheel spins by the right-hand rule, and the readout confirms what you can see: the product is square to both of its parents, always.

```gdscript
func wasted_half(arm: Vector3, force: Vector3) -> Vector3:
    var r := arm.normalized()
    return r * force.dot(r)
```

Now put the two products beside each other. What the projection keeps of a push, the part along the arm, is exactly what the cross product throws away, and what the cross product keeps is exactly what the projection discarded. Dot and cross are one question asked in opposite directions: how much do these two agree, and how much do they refuse to.

<!-- @ -->

## Out of reach

<!-- @vector_addition_xl_laser -->

<!-- @vector_subtraction_xl_laser -->

At the far end, addition and subtraction once more, built so large that the tips are past your arm. Point a hand's laser at an endpoint, hold, and sweep, and the sum and the difference redraw at a scale no hand could hold. The room has now shown you each operation three ways: in your hand, around your body, and beyond your reach, which is the size most of them come at.

<!-- @ -->

## Three verbs

To add is to walk. To dot is to agree. To cross is to turn.

That is the act, and it is a definition no page could give you, because each verb was something your body did before it was something you knew. Nothing here was a symbol. Every operation was a thing one vector did to another, and you were the thing doing it.

The next act takes these and spreads them over space and time, so that a vector is no longer one arrow you hold but a field of them, everywhere at once, and the arrow stops holding still.
