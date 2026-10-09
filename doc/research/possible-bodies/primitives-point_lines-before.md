A point had no parts. Keep two positions now, in the same coordinate system. What can you change about their connection without changing which points are connected?

<!-- @line_demo -->

Before touching the two black points, look at what stands beside them: *DO NOT CROSS.* Bring the points near one another and release to request a connection. Watch for the segment between them. What else moved?

The barrier flies apart. You joined two positions, and something a little way off lost its power to stop you. Keep the line. Move one endpoint a short distance. Predict which part of the connection will change, then move it another way.

The connection manager keeps the relation in both directions:

```gdscript
_adjacency[point_a].append(point_b)
_adjacency[point_b].append(point_a)
```

These lines sit inside checks against duplicate connections. Each point gets a neighbour. A changed length or direction need not be a changed neighbour.

The explosion takes another connection, this time between events. The manager emits `connection_created`; the demonstration recognises its two endpoints and, on their first connection, calls the nearby barrier's `trigger_explosion()` in this hall. That instruction removes the collider and scatters the visible pieces. No property of a straight line required this consequence. Someone connected making a line to undoing a prohibition.

What would this room teach if the same success erected the barrier instead?

<!-- @line -->

Compare the connection you made with the already drawn line. A visible segment can be represented by its two endpoints:

```gdscript
var a := Vector3(0, 0, 0)
var b := Vector3(1, 0, 0)
var displacement := b - a
var distance := displacement.length()
```

Here the distance is one metre. The displacement also tells us which way from A to B. Two distinct points determine an infinite straight line; restricting it to what lies between them gives a segment. Storing that geometry and storing a neighbour relation answer different questions.

The demonstration had to learn how to show this. When its spheres grew larger, they swallowed the short connecting line. The connection existed in the program and disappeared in the picture. Making a relation legible takes another decision after making it exist.

<!-- @ -->

## Read it with your feet

<!-- @walk_this_line_marking -->

The white stripe comes with a verb: *WALK THIS LINE.*

Follow it for a few steps, then walk beside it. Try following it backwards. Compare what happens in the room with the correction you may feel tempted to make to your own gait.

The marking draws an instruction. It has no tracking code that rewards your obedience or registers your departure. Whatever correction you made through reading belongs to an encounter between a sign and a reader.

A line can be a useful guide. It can also make walking alongside it feel like getting something wrong. Walking it backwards keeps to the geometry and changes the walk.

<!-- @do_not_cross_barrier -->

If you made the connection first, the words have already gone with the plank. Approach the place where the barrier stood and compare it with the paint. You can cross its former position. If you came here before making the line, look below the plank before testing passage.

While intact, the barrier has a collider: a box extending from the floor to the bar. A gap below the visible plank need not offer a gap in that box. Changing the words changes the request; removing the collider changes the obstruction. Neither requires moving the two ends. Disconnecting your points does not put the barrier back. The room keeps one consequence while letting you revise another.

Geometry, instruction and enforcement can occupy the same place. They still have to be made separately.

<!-- @ -->

## Carry the whole line

<!-- @grabbable_line -->

Pick up the short rod. Turn it, carry it, then compare that movement with pulling the demonstration's endpoints apart. Which length stayed fixed?

The rod's ends belong to one body, so moving it carries both together. Turning changes its direction while its length stays fixed. A fixed span can become a unit for comparing other spans.

Move the held rod slowly through the room. Near whole-number values on a world axis, its centre triggers jitter, changing sound and, with a tracked controller, pulses. The disturbance belongs to its address, not its length.

Use that disturbance as an instrument: search for a quiet position, then find an edge where the noise returns. An imposed interruption can become a way to investigate the rule imposing it.

<!-- @two_point_ruler -->

The ruler holds a half-metre span between two marks. Beside it stand a pale block and a blue one. Compare the span with the pale block by looking. A unit is a distance somebody has decided to hold steady.

This placed display does not yet provide a hand-operated measurement action. Its intended extension is a more difficult question: measuring one object would alter the other while leaving the reported dimension true. For the working encounter here, keep the fixed span; the laser supplies a measurement you can perform.

<!-- @ -->

## Move between the ends

<!-- @two_points_line -->

Watch the bright bead move between the two coloured endpoints. Before it turns, predict where it will slow down. Would the same segment require the same pace?

Interpolation places a point along a segment:

```gdscript
var p := a.lerp(b, t)
```

At `t = 0`, it is at A; at `t = 1`, at B. Values between them stay on the segment. This bead's script moves the parameter back and forth with a cosine, slowing near each end.

The geometry supplies a route. Another function supplies a pace. Straightness alone never required haste, constant speed, or arrival at B as the end of the story. Watch the bead return.

<!-- @ -->

## Measure, then change the measurement

<!-- @laser_measure -->

Take up the measuring instrument. Aim through the place where the barrier stood. What stops the beam now? If you reached the instrument before making the connection, the intact barrier offers another experiment: keep the beam on it and compare the reading before and after it breaks.

A ray needs a starting position and a direction. For distinct endpoints, dividing displacement by its length gives a unit direction:

```gdscript
var direction := displacement / distance
```

The tool casts forward up to its maximum range and reports the first physics body it hits. Its visible beam ends at that collision. This room enables its burning behavior: dwelling on the barrier calls the barrier's explosion action and removes its collider.

On that route, measurement changes what can be measured. On the other, making a connection has already changed the beam's destination. The number alone cannot explain why the distance changed.

<!-- @laser_exploding_sphere -->

The orange sphere provides another response to compare: controller pointer entry triggers its burst, and it returns after a cooldown. The measuring beam and the controller pointer are separate interfaces here. Similar-looking lines need not ask the same question of an object.

The sphere can return; the broken barrier stays gone for this loaded instance. One response supports repetition, while the other changes the route. That difference was authored after the geometry.

<!-- @parallel_lines -->

Walk around the three fixed parallel segments. Their apparent separation changes with your viewpoint. Their shared orientation remains, and their spacing need not be equal. Staying alongside one another leaves more undecided than a command to walk in one direction.

<!-- @ -->

Choose two positions in the room. Travel between them directly, then by a detour. Explain what a segment between the endpoints would keep from both journeys, and what it could not distinguish. You can do this alone, or let someone else choose the second route before comparing.

Next comes Point Trace. Instead of keeping only the ends, we will keep positions along a movement. Bring the detour. The next room has somewhere to store it.
