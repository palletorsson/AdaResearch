# Stand inside the curve

[Working route](index.html#VFM_05_Launch) · [Primary and book](/necklace/thread?map=VFM_05_Launch&role=primary) · [Previous: the gap and its remainder](vector-gap-projection.html) · [Vector / Forces plan](vectors-forces-plan.html)

**Launch now has a full-scale interactive chamber.** Stand between two control banks, with one flight lane in front and another behind. Positions use actual scene metres. The 12.5-metre-wide frame holds flights that can travel up to ten metres horizontally under the available settings.

![Two flights around the central operator position](launch_chamber_overview.png)

## Try it from the middle

Start with **FIRE**. Change **ANGLE− / ANGLE+** and predict whether a steeper launch will go farther. **PAIR** adds the complementary angle in the other lane at the same speed. Fire again and turn around: both reach the same horizontal range, but the shallow flight lands first.

**SLOW** advances this experiment's clock at quarter speed. **PATH** reveals the calculated curves; **PARTS** shows current velocity components and downward acceleration. **RULE** displays the equation and arrow scales. **SPEED** cycles 6, 8 and 10 m/s; **GRAVITY** switches the model between 10 and 15 m/s². Parameter changes restart the comparison; the reveal and playback controls do not reset it.

![Standing at the central controls, inside the flight diagram](launch_chamber_inside.png)

At 30° and 60°, speed 10 m/s and gravity 10 m/s², both ranges are about 8.66 metres. Flight times differ: 1 and 1.73 seconds. The apex has zero vertical velocity while downward acceleration remains. That is the new relationship carried forward from vector components.

The lanes have different Z positions, so equal horizontal range is not one world landing address. This is an analytic visualization with collision-free markers, uniform gravity, no drag and equal launch/landing heights. Landing freezes the incoming impact state. It does not simulate the collision or apply a force to the visitor.

## A reusable way to stage later rooms

Put controls within the space being studied. Give the visitor a clear standing position and routes around the controls. Make several views or bodies read one explicitly defined model. State units and display scales; reveal the construction after an observable comparison. Here the floor is metre scale, velocity arrows draw 1 m/s as 0.2 m, and acceleration arrows draw 1 m/s² as 0.1 m.

For Motion this can become a body whose state persists between updates. For later force rooms, a shared field could influence an object and a player adapter. Those connections still need implementation; this chamber does not claim them in advance.

## What changed and what was checked

launch_arc remains the single primary. All **17 artifact identities** remain; the **16 supporting exhibits** keep their relative layout fourteen source rows beyond the new arrival. The hall is now 34 × 38 cells. [Placement ledger](launch-chamber-placements.json). An extra entrance partition that cut through the rear lane was removed through this map's museum gate setting.

[**40 desktop checks pass**](launch-chamber-check.json): actual pointer controls, complementary ranges, separate landing times, velocity components, parameter limits, playback timing, analytic motion across frame partitions, pooled arrow geometry, unchanged player position, collision-free markers, control height and sampled centre/side routes. The captures are from the actual museum with the target hall visible. No GDScript errors appeared in the final probe. Headset reach, comfort and sustained performance remain untested; supporting exhibits were preserved rather than newly certified.

**Next: VFM_03_Motion**, on the unchanged route. Compare a curve evaluated from its known formula with a body that carries velocity forward into the next update.

## Book chapter

# Stand inside the curve

<!-- @launch_arc -->

The controls are in the middle. A launch lane runs in front of you; another waits behind. The grid under your feet continues beneath both. For once, the diagram is large enough to ask you to turn around.

Press **FIRE**. An amber marker leaves its pad, rises, falls, and stops at the landing height. There was a straight arrow at the start. The marker took a curve.

Change the angle and try again. **ANGLE−** and **ANGLE+** move it in five-degree steps. Keep the speed fixed. Does aiming higher always carry the marker farther across the floor?

At first it may seem so. Keep going. The higher flight begins to give back horizontal distance. There is more room above the lane, and less progress along it.

Now **PAIR** adds the complementary angle in the lane behind you. At the opening setting, one launch is thirty degrees and the other sixty. Both begin at ten metres per second. Press FIRE and follow them in turn.

One is already down while the other is still in the air.

They have travelled the same horizontal distance: about 8.66 metres under this chamber's chosen gravity. One flight takes a second; the other about 1.73. A shared range has left two very different uses of space and time.

The two lanes are separated so that you can stand between them. Their markers do not land at one world address. They land at the same X coordinate, each in its own lane. Even a comparison that says *the same place* needs us to say which difference we are overlooking.

The control bank behind you offers **SLOW**. It advances the local flight clock at a quarter of ordinary playback speed. The museum keeps running. This small clock gives us longer to look at the ascent, the turn and the descent; it does not change the calculated path.

Press **PATH** when you want both predictions to remain in the room. Walk beside a low curve. Look across at the taller one. An archway and a low wall would ask different things of these routes. Neither obstruction is part of the calculation yet. Here you can stand where a physical projectile could not be allowed to pass through you.

**PARTS** opens another way of reading the flight. The velocity has a horizontal component and a vertical component. On the way up, the vertical one points upward. Near the highest point it shrinks to zero, then points down. The horizontal one keeps its length.

A downward acceleration arrow is still present at the top. Zero vertical velocity has not meant that the influence producing its change went away.

These arrows have units. Velocity is metres per second, drawn here with one metre per second occupying 0.2 metres. Acceleration is metres per second squared, drawn with one unit occupying 0.1 metres. Their lengths are representations with stated scales. The floor grid itself is one metre to a square.

Press **RULE**. The chamber computes each position from the launch condition and elapsed model time. Its vertical contribution contains this term:

```gdscript
Vector3.DOWN * 0.5 * gravity * t * t
```

The initial velocity contributes another:

```gdscript
launch_velocity(index) * t
```

Added to the starting position, they locate the marker. One term grows with time; the other with time squared. The curve is already in their different rates of growth.

We have met addition, subtraction and components. Here a component has acquired a role in a temporal model. The launch velocity is the initial condition. Gravity continues to change the velocity after departure. A destination would tell us where to go; it would not supply this history of getting there.

**SPEED** cycles through six, eight and ten metres per second. **GRAVITY** switches this chamber's downward acceleration between ten and fifteen metres per second squared. Change one, keep the others fixed, and fire again. A stronger downward acceleration shortens the time aloft and the range for the same launch velocity. These values belong to this model; the control does not change gravity for your body or for the museum's other objects.

Parameter changes reset the local flight. PATH, PARTS, RULE and SLOW let you inspect it without resetting it. FIRE always begins another run. This is how the apparatus makes comparisons repeatable: it can return an experiment to its beginning, while the person comparing it carries the previous run forward.

The bright path has sixty-four straight segments. The moving marker is evaluated from the equation at each rendered frame, rather than stepping from segment to segment. Look closely enough and two representations of the same flight disclose their different resolutions. Slow playback gives more rendered observations of the movement; it does not add pieces to the stored path.

At landing, the marker freezes at the launch height. With PARTS visible, its last velocity arrow is the incoming impact velocity, not a claim that a resting body continues moving. No collision response has been computed. The room has answered where this model reaches that height, and stopped before the next question.

Beyond the chamber, the other launch instruments remain. Some address actual objects or the player. Their names do not guarantee the same physical operation: setting a launch velocity and applying a continuing force are different interventions.

Next is Motion. We have a curve calculated from a known rule. What changes when the body carries velocity forward from one update to the next, and the next influence has not already been folded into a complete answer?


## Motion is now built

[When the push ends](motion-chamber.html): a full-scale force-controlled body, central controls and the friction ramp comparison. Both book primaries are placed; 34 desktop checks pass. Continue from Motion to Fields and Motion. Headset review remains open.
