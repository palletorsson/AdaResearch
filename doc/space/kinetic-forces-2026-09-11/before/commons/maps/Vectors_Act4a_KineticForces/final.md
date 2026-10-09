In the last hall the arrow was pushed and bent and thrown, and nothing doing the pushing had a name. This is a park, thirty metres a side, and every machine in it is a force with its name on it. Work, drag, launch, turn, fall. Each one is a force bending a path, and each is built at the size of your body so that it is a place you walk into rather than a line you read.

Walk it south to north. The room's own beats are on the floor, one per force.

## Work

```gdscript
func work_done(force: Vector3, displacement: Vector3) -> float:
    return force.dot(displacement)
```

<!-- @force_mower -->

A lawn mower with a handle at an angle, and a push arrow living on the handle. Push it. The arrow splits at once into two, the part along the ground and the part driven down into the dirt, and only the first of them moves the mower. Raise the handle and watch the along-part shrink and the down-part grow while the push itself stays the same length.

That is work, and it is the dot product with its costume off. The world only feels the part of a force that goes its way. Push square to the motion and the work is zero, however hard you push, however long.

```gdscript
func push_split(magnitude: float, theta: float) -> Array[Vector3]:
    var along := Vector3(magnitude * cos(theta), 0.0, 0.0)
    var into_ground := Vector3(0.0, -magnitude * sin(theta), 0.0)
    return [along, into_ground]
```

<!-- @sisyphus_mower -->

And here it is forever: a mower pushed up a striped hill by hands that are not there, handle at thirty-two degrees, sixty newtons a shove, and a ledger counting the joules that bank. Only the cosine of every shove goes into the hill. The rest goes into the dirt, and gravity spends what was banked on the way back down. Effort is conserved. Usefulness is not. One must imagine the mower happy.

<!-- @ -->

## Drag

```gdscript
func drag_step(velocity: Vector3, b: float, delta: float) -> Vector3:
    return velocity * (1.0 - clampf(b * delta, 0.0, 0.6))
```

<!-- @drag_corridor -->

Three zones, three metres each: air, then water, then honey. Walk them and feel your own pace taxed more in each. In every zone a dart is launched at the same speed and glides and dies, its velocity arrow shrinking as it goes, and the same launch that crosses the air zone barely lunges in the honey.

Drag is the world charging you rent on speed. It is proportional to how fast you go and it points against you, so it can slow you to nothing and can never turn you round, because the moment you stop there is nothing left to charge.

```gdscript
func distance_under_drag(v0: float, b: float, t: float) -> float:
    return (v0 / b) * (1.0 - exp(-b * t))
```

Read what that means for how far you get. Coast as long as you like, and the distance approaches a number and stops: your launch speed divided by the medium's rate. In honey that number is close. In air it is far. It is never infinite. A thing that pays rent on its speed has a finite reach, however long it is allowed to travel.

<!-- @ -->

## Launch

<!-- @force_pad -->

A glowing square on the floor, one metre a side, with chevrons pointing the way it will send you. Step on it. It hands you a velocity, six metres a second forward and seven up, and then it has nothing more to do with you: gravity writes the rest, and the rest is an arc.

You met the arc in the last hall as a thing you aimed. Here you are the thing launched. A launch is a velocity you are given, and everything after it is the world's answer, one squared term long. The pad cannot give you a curve. Nothing can. It can only give you a straight line and let gravity bend it.

<!-- @ -->

## Turn

```gdscript
func centripetal(speed: float, radius: float, angle: float) -> Vector3:
    var pos := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
    return -pos.normalized() * (speed * speed / radius)
```

<!-- @centrifuge_ring -->

A pod laps a neon ring three and a half metres across, and two arrows ride it. The velocity is always tangent, along the ring, the way the pod is going. The force is always toward the centre, square to the velocity, and because it is square it never changes the speed, only the direction, which is what going in a circle is: a constant acceleration toward a centre you never reach.

Crank the speed and watch the inward arrow. It grows as the square. Double the speed and the pull quadruples. That is why fast turns throw you, and it is the whole of what a turn costs.

<!-- @prop_carousel -->

A fairground carousel of museum props hung on chains, turning under a canopy. Look at the chains. They lean outward, and every child who has ridden one knows it as being flung out. The chains lean out because they have to pull *in*: the angle of every chain is exactly what it takes to supply the inward pull the prop needs to keep circling, and nothing anywhere pulls outward. The outward feeling is your body wanting to go straight, and the chain refusing.

<!-- @ -->

## Fall

```gdscript
func barycenter_offsets(m1: float, m2: float, separation: float) -> Vector2:
    var total := m1 + m2
    return Vector2(separation * m2 / total, separation * m1 / total)
```

<!-- @orbit_walk -->

Stand at the centre. A heavy star and a lighter planet wheel around you on opposite sides, three and a half metres apart, and on each of them rides a red arrow of exactly the same length pointing at the other. One force, handed out in two opposite directions, stronger as the square of the distance closes.

The point you are standing on belongs to neither of them. It sits where the heavy mass times its distance equals the light mass times its distance, closer to the heavy one, and make one heavier and it slides toward that one while both orbits resize to keep the trade. An orbit is two things falling toward each other and missing, forever, around a centre that neither of them is at.

```gdscript
func slides(theta: float, mu: float) -> bool:
    var down_slope := sin(theta)
    var friction := minf(mu * cos(theta), down_slope)
    return down_slope - friction > 0.0
```

<!-- @wedge_slide -->

At the far end, the smallest fall there is. A block on a wedge, a slider for the angle, and the textbook triangle drawn live beside it: weight, normal, friction, and what is left. A slope does not change gravity. It changes how much of gravity points along the way out, which is the projection of one downward arrow against a ramp, and friction can match that part but never exceed it. So the angle decides, and the weight cancels out of the deciding: at this block's friction the hill holds at fifteen degrees and gives at sixteen, and it would do the same for a block ten times the mass.

<!-- @ -->

## What edits motion

Work, drag, launch, turn, fall. Every one of them is a force bending a path, and every one was met on foot. That is the act's whole claim, and it is worth saying in the plainest words the sequence has: forces are what edit motion. Position is where you are, velocity is where you are going, and a force is the thing with the pen.

The next half of the act holds the forces that give the path back: the ones that pull toward a rest and overshoot, and keep time by doing it.
