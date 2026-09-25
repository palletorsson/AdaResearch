# Lines, Networks, Measure

The point gave us somewhere to begin. Now put two positions into relation.

<!-- @line_demo -->

Two black points wait beside a barrier: **DO NOT CROSS.** Bring one close to the other, then let go. Watch for the segment that joins them. What else moved?

The barrier flies apart.

Keep hold of this small beginning: **two distinct points determine a straight line.**[^point-lines-euclid] Here we draw only the part between them: a segment. Move an endpoint. The segment changes length and direction while the connection remains.

Already something else has attached itself to the lesson. Joining two points has opened a passage.

<!-- @do_not_cross_barrier -->

Try crossing where the barrier stood. Before it broke, an invisible collision shape filled the space from the floor to the bar. The space looked open beneath the plank, but you could not pass through it. The explosion removes that shape too. Disconnecting the points does not put it back.

On the first connection, the demonstration calls the nearby barrier's `trigger_explosion()`. Someone joined those events in code. Geometry supplies a relation; another instruction gives that relation a consequence for your body. We could have made the connection ring a bell, or left the barrier standing.

The words, the plank and the collision boundary all helped to say **DO NOT CROSS**. Opening the way required changing what enforced that instruction. For a moment, a line has given us passage through another line's prohibition.

In the first room, leaving the target made another arrival possible. Here, the first connection leaves a passage open even after the points separate. The rooms keep different things from the gestures we make in them.

<!-- @line -->

This line has two ends you can hold. Pull them apart, then bring them closer. Watch the length display. Can you find a span of one metre?

Hold one end still and move the other around it. Try keeping the same distance. The segment can turn while its length stays steady. Once we choose to go from A to B, we can calculate a displacement with a distance and a direction.

Here is an example using the positions we began learning to write in the first room:

```gdscript
var a := Vector3(0, 0, 0)
var b := Vector3(1, 0, 0)
var displacement := b - a
var distance := displacement.length()
```

`b - a` subtracts the starting coordinates from the ending coordinates. Here the result is `(1, 0, 0)`: one unit along X, none along Y or Z. In this room we use that unit as a metre. `length()` returns one number for the size of that displacement: `1.0`.

Reverse the subtraction: `a - b` gives `(-1, 0, 0)`. Its length is still one metre. The points have stayed where they are; the direction between them has changed because we chose the other point as the start.

Even here, another question appears. Your hand may keep moving while the rounded number stays the same. How much difference can a display show? Remember it when we reach Trace and Grid.

Two points were enough to begin. They have not made the world small.

Nearby, a ruler offers a measure. Two crosses invite comparison. On the workshop's four monitors, lines turn, cross and pull apart; a laser waits for something to stand in its way. Each could occupy the rest of our visit. There is pleasure in following these associations, in finding how quickly a familiar mark acquires another use.[^point-lines-ingold]

The clock in the first room was already running when we arrived. Beginning required leaving some code unread. Continuing asks us to choose a thread and let other questions remain open.

You have changed a line with your hands. Ahead, a line has acquired words.

<!-- @walk_this_line_marking -->

Across the glass cover of a shallow basin, a black stripe: **WALK THIS LINE.** The glass supports your crossing.

Try following it. Then walk alongside it. Cross it at an angle. The stripe stays straight through all three journeys.

Did a sideways step feel like a mistake? The marking does not measure how closely you follow it. Its script draws the stripe and lettering. Yet you may already have corrected a step in answer to the words.[^point-lines-ahmed-paths] You might also find yourself dancing around the same steady line.

Choose which end to start from, and the line gives you a direction to follow. It cannot settle what following will mean to a body.

<!-- @player_trace -->

Turn and look at the route your movement has left behind. Compare it with the stripe. Where do the two lines part company?[^point-lines-ahmed-deviation] One was waiting for you; the other has taken shape while you moved.

The recorder saves positions and joins them with straight segments. The X and Z come from your headset; the line is drawn near floor level. A lean can change the drawing even when your feet stay put.

Choose a start and an end. Walk between them with a detour. Imagine walking directly between those same positions instead. The endpoint calculation, `b - a`, gives the same answer for both journeys. It contains no record of the turn you took.

The trace has kept more positions. How many did it need? What happened between the ones it kept?

<!-- @ -->

We can leave the other experiments here. The question taking us towards the exit has become precise: **what must we save if we want to keep something of the journey?**

Two endpoints were enough for the segment. To remember the detour, we will need to add something.

Bring the detour.

[^point-lines-euclid]: See Euclid, [*Elements*, Book I, Postulate 1](https://mathcs.clarku.edu/~djoyce/elements/bookI/post1.html), on drawing a straight line between two points. The construction concerns the finite segment; extending it and treating it as an unbounded line are further steps. The postulate is a historical reference, not an account of the renderer or the barrier’s programmed response.

[^point-lines-ingold]: Tim Ingold, [*Lines: A Brief History*](https://www.routledge.com/Lines-A-Brief-History/Ingold/p/book/9781138640399) (Routledge Classics edition, 2016), especially “Traces, Threads and Surfaces” and “Up, Across and Along.” Walking, drawing, weaving and connecting enter his inquiry as different practices of making lines. This helps us take the room’s proliferation seriously: a connector, a trace and a boundary need not perform the same work merely because we call each a line.

[^point-lines-ahmed-paths]: Sara Ahmed, [*Queer Phenomenology*](https://www.dukeupress.edu/queer-phenomenology) (2006), 15–20, especially 16: repeated journeys make paths, while established paths help direct later journeys. Ada takes up this relation as an experiment. Its stripe is authored rather than worn into the ground, and its instruction does not score compliance. Being oriented by a line, evaluated against one and physically blocked by one remain different operations to investigate.

[^point-lines-ahmed-deviation]: Ahmed, [*Queer Phenomenology*](https://www.dukeupress.edu/queer-phenomenology), 20, considers how deviations can leave marks and generate other lines. This sampled drawing offers one specific record, not the whole history of the body’s deviation.
