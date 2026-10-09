The point gave us somewhere to begin. Now there is something to follow.

<!-- @line_demo -->

Two black points wait beside a barrier: **DO NOT CROSS.** Bring the points near one another and release to request a connection. Watch for the segment between them. What else moved?

The barrier flies apart. You joined two positions, and something nearby lost its power to stop you. Move an endpoint. The connection can remain while its length and direction change.

The connection manager keeps each point as the other's neighbour. On their first connection, this demonstration also calls the barrier's `trigger_explosion()`. Someone joined those events in code. Making a line has become a way to open a passage. We could have written a different consequence. Keep that possibility beside the one you have just tried.

<!-- @do_not_cross_barrier -->

The barrier made a different kind of request. While intact, its collider extended from the floor to the bar: the visible gap beneath the plank did not offer passage. Now its former position can be crossed. Disconnecting your points does not put it back.

A phrase, a painted stripe, an invisible collision boundary: each can take part in directing a body. They have been made separately. Changing the words and opening the way are different acts.

<!-- @line -->

The next line has two ends you can hold. Pull them apart, then bring them closer. Watch its length change on the display. Can you find a span of one metre?

Hold one end still and move the other around it. A line can change direction while keeping the same length. We have two things to read in the movement, and a way to separate them:

```gdscript
var a := Vector3(0, 0, 0)
var b := Vector3(1, 0, 0)
var displacement := b - a
var distance := displacement.length()
```

These example positions give a displacement of one unit along X. In this room we use that unit as a metre. The subtraction keeps a direction as well as an amount; taking the length gives us the amount alone. The artifact calculates a distance between its endpoints and prints it for us.

Try to keep the number steady as you move. The display can give nearby spans the same rounded reading. Your hand is still moving; the printed measure may stay still. A unit lets us compare, but a reading also depends on how much difference the instrument keeps.

Two distinct positions determine a straight line; the part between them is a segment. We have given that segment a length we can name. What else might a line be asked to establish?

<!-- @redline -->

A red line lies between two faintly different fields. Step across it. Turn back. It is easy to give the two sides names: here and there, this side and the other. Which side did you take to be yours?

The artifact builds two shallow coloured fields on opposite sides of its local Z origin, then lays a narrow red mesh between them. Its own script adds no collision body. The colour divides what we see without erecting a fence to stop the crossing.

We have just watched a connection break a barrier. Here a division remains visible while the body crosses it. A mark and a prohibition require different work. If this red line were to forbid passage, something more would have to be written, enforced, or taken on trust.

Cross it again. The ease of that step belongs to this construction; it cannot promise that every boundary will yield so easily. What did the line do before it stopped anything?

Further on, another line addresses us directly: **WALK THIS LINE.** We will bring a moving body to an instruction that stays straight.

## Read it with your feet

<!-- @walk_this_line_marking -->

Across the glass cover of a shallow basin, a black stripe: **WALK THIS LINE.** The floor has depth beneath it; the glass supports your crossing.

Try moving along it. Let your pace be your own. You might look down to keep it under you, then look ahead and trust it for a while. Move alongside it. The stripe is still available. It can help you find a direction without having to become the whole of your journey.

I keep thinking of a dance pole: the rod stays straight; the body finds turns around it. Here the line lies on the floor. What movements does that change invite? Following, crossing, keeping company at a small distance. There is pleasure in having something steady to vary a relation with.

The words may also make you correct yourself. A little sideways movement can begin to feel like a mistake. This marking does not score your walk. Its script makes the stripe and lettering; it does not check whether you obey. Yet you have read an instruction, and perhaps begun to arrange yourself around it. Stay with that perhaps. Another visitor may read an invitation where you read a demand.

<!-- @player_trace -->

Turn and look at the route you have left behind. Walk alongside the stripe, then cross it. Compare the straight instruction with the line your movement has written. A sideways turn can become something to look at, rather than something to correct.

The recorder keeps sampled positions and joins them into a path. In VR it uses the headset's horizontal position at the rig's floor height; in the desktop museum it follows the walker. This is one account of your movement, not a drawing of every part of your body. The next hall will let us examine how a trace is made.

## Two lines, then another

<!-- @line_space_workshop -->

Start with two. The little workshop gives you two straight segments and asks what they can do together. Bring them alongside one another. Cross them into a plus, then an X. Turn one away. You have changed a relation without adding a line.

NEXT offers another arrangement. RESET restores the current one after you release the rods. At the first three stations, the number and lengths stay fixed while the arrangement changes. The labels tell you how many segments you have. A rod you release stays where your hand leaves it.

With **SKEW**, look from the front, then move to the side. One line has been displaced a quarter of a metre in depth. The crossing that appeared joined has a gap. Two lines are already enough to leave a shared plane. Adding depth does not have to wait for a complicated object.

```gdscript
# Move both ends of one segment equally: its length stays fixed.
a.z += 0.25
b.z += 0.25
```

Try **RAILS**, then **DRAWING**. In one arrangement the two segments remain parallel in space. In the other, two ends really meet. Both may suggest a journey into the distance from a suitable view. Walk around that suggestion. What did the view supply?

Now take three. Join the ends into a triangle. An outline closes, and you may already begin to supply the face it could carry. No face has been made here.

Move one whole edge out of the plane. The **DISPLACED** preset lets you inspect that move too. Which joins have opened? Try to keep all three ends joined in a non-flat outline. Three non-collinear vertices determine a plane; joining them in pairs cannot produce a closed, non-planar triangle of straight segments. You can carry or turn the triangle in 3D, but it still lies in a plane. To keep closing while leaving that condition behind, we need another possibility.

At **FOUR LINES**, a square waits. Choose **FOLD**, then walk around it. The outline is still closed. Each side has kept its length. One corner has turned around the diagonal between its two neighbours, carrying its two adjoining edges with it. Four sides let this boundary fold out of a plane without tearing its joins apart.

There is still no surface between them. The folded outline does not tell us how to fill it. That decision will return with triangles: a choice of faces can make different surfaces from the same boundary. For now, run a hand through the opening the outline has helped you see.

Four also gives us **FOUR GRID**: two lines in each direction. The crossings occur within the spans, rather than at their ends. Is meeting in the middle the same arrangement as joining at a corner?

At **MORE LINES**, count before naming the form. Six rods make a grid of three by three, with nine crossings. **SIX LIFT** separates the two directions in depth. The same six rods can instead outline a tetrahedron. Twelve outline a cube. These are arrangements of edges, still without filled faces. More rods give us further choices; the number alone cannot decide which body we will imagine between them.

Keep one arrangement you like. Then change just one relation. What did you have to give up to make that change, and what became possible without adding anything?

## Carry the whole line

<!-- @grabbable_line -->

Pick up the short rod. Carry it across your view. Turn it. Its two ends move together, keeping their distance. A direction you followed on the floor can now be a direction you hold in your hand.

Compare turning it with pulling the demonstration's endpoints apart. One operation carries a fixed span; the other changes the span itself. A length that stays fixed can become a unit for comparing other lengths.

Move the held rod slowly through the room. Near whole-number values on a world axis, it begins to jitter and sound; a tracked controller can pulse too. Its position has met an authored rule. Search for a quiet place, then return to the disturbance. Something that interrupts carrying can become an instrument you play by carrying.

<!-- @two_point_ruler -->

The ruler offers a half-metre span beside two blocks. Compare them by looking. Here the unit stays still for you. Later we could make measuring one object change another. For now, there is already something to borrow: a distance held steady so other distances can be read.

<!-- @two_points_line -->

Watch the bead travel between its two endpoints. Wait for its return. It slows near the ends; a straight route has room for a changing pace.

```gdscript
var p := a.lerp(b, t)
```

`lerp` interpolates: at `t = 0`, the position is A; at `t = 1`, B. Values between them give positions along the segment. The bead's script uses a cosine to move `t` back and forth. One operation supplies the route, another the rhythm. We will return to that rhythm when we learn how values change over time.

## Where the beam ends

<!-- @laser_measure -->

Take the measuring instrument and aim through the place where the barrier stood. The beam reports the first physics body it hits. If the barrier is still intact, hold the beam on it: this hall enables burning, and the barrier can break that way too. Watch where the measurement ends afterward.

A ray begins at a position and goes in a direction. The bodies it encounters help determine the answer it returns. Here a measurement can participate in changing what can be measured.

<!-- @laser_exploding_sphere -->

The orange sphere bursts when the controller pointer enters it, then returns after a cooldown. That pointer is another interface, separate from the measuring beam. Similar-looking lines can ask different things of the room. The returning sphere invites another try; the broken barrier leaves a changed route.

<!-- @parallel_lines -->

Walk around the three parallel segments. Their apparent separation changes with your viewpoint. They keep their shared orientation. Alongside is another relation a line can offer: company without a meeting point.

<!-- @ -->

Choose two positions and travel between them by a detour. The subtraction `b - a` still gives the same answer as it would for a direct passage. Your curve, your hesitation, the time spent looking at something halfway: none of those events entered those two variables.

There is usefulness in that small answer. We can measure without carrying every journey into the measurement. There is also a reason to want more. I want to keep the turn your hand made, the movement the two ends cannot tell apart from a direct passage.

The next room gives us a way to begin keeping it. We will save positions along the movement. Even then, we will have to choose how many.

Bring the detour.
