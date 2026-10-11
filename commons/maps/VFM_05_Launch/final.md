# Stand inside the curve

<!-- @launch_arc -->

The controls are in the middle. A launch lane runs in front of you; another waits behind. The grid under your feet continues beneath both. For once, the diagram is large enough to ask you to turn around.

Press **FIRE**. An amber marker leaves its pad, rises, falls, and stops at the landing height. There was a straight arrow at the start. The marker took a curve.

Raise the launch angle and try again, keeping the speed fixed. At first, the flight reaches farther across the floor. Keep raising it. The higher flight begins to give back horizontal distance. There is more room above the lane, and less progress along it.

**PAIR** adds another flight behind you. Its angle completes the first to ninety degrees: at the opening setting, thirty in one lane and sixty in the other. Both begin at ten metres per second.

Fire and follow them in turn. One is already down while the other is still in the air.

They have travelled the same horizontal distance, about 8.66 metres. One flight takes a second; the other about 1.73. A shared range has left two different uses of space and time.

This equality depends on the world the chamber gives them: constant downward acceleration, no air resistance, and landing at the height of departure. The lanes are separated so we can stand between them. Their markers reach the same distance along the floor, not the same world address.

## Room above the route

**PATH** leaves the predictions hanging in the room. Walk beside the low curve and look across at the taller one. An archway and a low wall would ask different things of these routes. Equal range would no longer settle which flight could get through.

Those obstructions are not part of this calculation. Neither are we: the marker can pass through the place where we stand without touching us. We have been given room to examine a flight from within it. The diagram makes that possible by leaving out the collision.

**SLOW** gives us longer to look. Only the local flight clock slows; the museum keeps running around it. The path is unchanged.

With **PARTS**, the velocity separates into horizontal and vertical arrows. On the way up, the vertical one points upward. At the highest point it reaches zero, then points down. The horizontal one keeps its length.

The downward acceleration arrow remains at the top. For that instant, the marker has stopped rising. It has not stopped being accelerated downward.

Behind **RULE**, two contributions locate it. The initial velocity contributes:

```gdscript
launch_velocity(index) * t
```

Gravity contributes:

```gdscript
Vector3.DOWN * 0.5 * gravity * t * t
```

Add these to the starting position. One contribution grows with elapsed time; the other with time squared. Their different growth gives the straight launch arrow its curved consequence.

Velocity is measured in metres per second: multiplied by seconds, it supplies a displacement. Acceleration is metres per second squared; multiplied by time squared, it supplies another. The floor gives us metre squares, while the arrows have their own stated display scales. Their lengths picture quantities with different jobs.

## Another beginning

Increase **GRAVITY**, keep the launch velocity, and fire again. The stronger downward acceleration shortens both the time aloft and the range. Change **SPEED** instead and the initial condition changes. Gravity continues acting after departure; the launch velocity was given at the beginning.

These controls belong to the marker's model. They do not change gravity for our own body. We occupy the same hall under different arrangements.

A parameter change resets the flight. The apparatus can put the marker back at its beginning while the person comparing it carries the previous run forward. We can try another way of leaving, with a memory of where the first one went.

At landing, the marker freezes at the launch height. Its last velocity arrow shows the incoming flight, before any impact response. Will it bounce, break, roll or stay? This model stops before answering.

The other launch instruments remain beyond the chamber; some address objects or the player. Setting their velocity and applying a continuing force are different interventions. Next, in Motion, the body will keep a velocity from one update to the next. A new push will meet what is already moving.


## A difference between steps

Beside the launch chamber, two points make the same throw. The amber trace follows the formula. The blue point takes ten steps through a second. It finishes above its companion. Nothing struck it. We gave it another way of passing through the calculation.

Move the slider. Twenty steps draw the paths closer; forty bring them closer again. The starting velocity has not changed. The difference belongs to the intervals in which velocity was allowed to remain the same. A smooth picture could have hidden that bargain.

There is no collision in this comparison, no wind to blame. The reference holds only because we have kept those complications outside it. Precision here has a meaning we can name and measure. It still cannot tell us which flight is worth following, or how much of its difference we want to keep.
