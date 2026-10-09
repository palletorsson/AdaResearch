from pathlib import Path
import hashlib,json
root=Path.cwd();out=root/'doc/book/iterations/2026-09-24-launch-and-motion'
base=json.loads((out/'baseline.json').read_text(encoding='utf-8'))
texts={}
texts['VFM_05_Launch']='''# Stand inside the curve

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
'''
texts['VFM_03_Motion']='''# When the push ends

<!-- @VectorMotion -->

Step between the two control banks. The cube waits beyond them, held a metre above the grid. Press **PUSH X** once, then leave the controls alone.

The command lasts one second. The cube keeps going.

There is time to look back at the button. It has finished its small contribution. Something of that contribution is still crossing the room.

**COAST** does not stop it. **BRAKE** slows it. Two controls that might sound like ways of ending movement have asked different things of the body.

Reset and begin again. This time, press COAST before the push has finished. The cube leaves with less speed. Cutting the command short changes how much motion it acquires; it does not take back what has already accumulated.

In Launch we watched a position calculated from an initial velocity and elapsed time. Here the body keeps its current velocity in the physics engine. Each new influence meets that state. The apparatus does not supply a complete curve in advance.

With **PARTS** visible, cyan gives velocity and amber gives the force requested by the controls. When the pulse ends, amber disappears. Cyan remains.

## What the body brings

The opening cube has a mass of one kilogram. The push requests two newtons for one second. Before a boundary intervenes, its velocity changes by about two metres per second. Acceleration equals force divided by mass; it changes velocity for as long as it acts.

**MASS** resets the run and lets us try the same pulse with two kilograms. The velocity change is halved. The cube looks the same size. A property that matters to its response was not something its silhouette could tell us.

Return to one kilogram. Let PUSH X finish, then **PUSH F**. The new command points forward. The cube travels sideways as well as forward, because the second contribution meets a velocity already there. The latest instruction does not contain the whole movement.

During each physics update, the source hands the requested force to the engine:

```gdscript
body.apply_central_force(global_basis * local_force)
```

The multiplication turns the room's local direction into a world direction. The engine integrates the response. This call neither sets a destination nor replaces velocity with the new arrow.

BRAKE also applies a force, directed against the current velocity. It weakens near rest to avoid sending the cube back the other way. Stopping takes an intervention and time. **RESET** can erase the velocity immediately because resetting an experiment has been granted a different power.

With **DRAG** enabled, COAST leaves the cube slowing. The command has ended, but the damping has not. With DRAG off, this chamber removes gravity and linear damping. Continued movement becomes available under those particular conditions.

## A boundary for one body

At the amber perimeter the cube rebounds. We can walk across that same line.

The boundary recognises a collision layer to which the cube belongs. Our body and the control furniture are excluded. We appear to share a room, while its rules give us different possible encounters. For the cube, the line is a limit. For us, it can be a place to stand and watch.

The cube also keeps its height and cannot turn. These are locks, not achievements of balance. A three-dimensional body has been admitted to a horizontal experiment. Release a lock and another movement becomes possible; the controls here leave those locks in place.

Pink shows acceleration measured from successive velocities. At a rebound it may jump while the command reads zero. The boundary has acted through collision response. The force we requested is only one contributor to the change we observe.

**TRAIL** retains the latest 120 position samples. Follow the cube long enough and the beginning leaves the drawing. Its velocity can still carry a contribution whose trace has already been discarded.

The run has room for a recent history. It has not kept everything that made the present.

<!-- @friction_ramp -->

## Before the slide

Farther into the hall, a much smaller block waits on a ramp. At thirty degrees, change **μ**, the friction coefficient, until STATIC becomes SLIDING. Reset and approach that boundary again, more slowly.

Now keep μ fixed and change **ANGLE**. Another adjustment can reach the beginning of movement.

Just before it starts, look at the arrows. Stillness has not emptied the block of influences. Gravity pulls partly down the incline and partly into its surface. Support answers the inward component; friction can answer the downhill component, up to the bound selected here.

The model tests:

```gdscript
sin(angle_rad) > friction_mu * cos(angle_rad)
```

On one side it holds the block still. On the other it accumulates downhill velocity. The comparison sets the downhill component against the maximum friction supplied by this model. A continuous adjustment has crossed a condition that permits another behaviour.

Let it slide and watch the speed increase. At the bottom it returns automatically, ready for another run. Friction has not thrown it uphill.

There is another abrupt return inside the rule. Raise resistance into STATIC while the block is moving: the program sets its velocity to zero at once. Compare that cut with the large cube's gradual braking.

This small ramp exposes a threshold while abbreviating the motion around it. One coefficient serves both starting and sliding, and the displayed travel is slowed to fit the exhibit. What could we discover if starting friction and sliding friction differed? If a new condition had to meet the movement already under way?

<!-- @ -->

Ahead, the influences will depend on where the body arrives. A field waits across the room; a moving body reaches each part with a velocity of its own.
'''
for m,t in texts.items():
 rel=f'commons/maps/{m}/final.md'
 assert hashlib.sha256((root/rel).read_bytes()).hexdigest()==base[rel], 'Concurrent edit: '+m
for m,t in texts.items():(root/f'commons/maps/{m}/final.md').write_text(t,encoding='utf-8')
print(json.dumps({m:{'before':len((out/f'before/commons/maps/{m}/final.md').read_text(encoding='utf-8-sig').split()),'after':len(t.split())} for m,t in texts.items()},indent=2))
