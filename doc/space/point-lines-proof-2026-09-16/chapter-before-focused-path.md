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

These example positions give a displacement of one unit along X. In this room we use that unit as a metre. The displacement has magnitude and direction; `length()` gives its magnitude, the distance between the endpoints. The artifact calculates that distance and prints it for us.

Try to keep the number steady as you move. The display can give nearby spans the same rounded reading. Your hand is still moving; the printed measure may stay still. A unit lets us compare, but a reading also depends on how much difference the instrument keeps.

Two distinct positions determine a straight line; the part between them is a segment. We have given that segment a length we can name. What else might a line be asked to establish?

<!-- @redline -->

A red line lies between two faintly different fields. Step across it. Turn back. It is easy to give the two sides names: here and there, this side and the other. Which side did you take to be yours?

The artifact builds two shallow coloured fields on opposite sides of its local Z origin, then lays a narrow red mesh between them. Its own script adds no collision body. The colour divides what we see without erecting a fence to stop the crossing.

We have just watched a connection break a barrier. Here a division remains visible while the body crosses it. A mark and a prohibition require different work. If this red line were to forbid passage, something more would have to be written, enforced, or taken on trust.

Cross it again. The ease of that step belongs to this construction; it cannot promise that every boundary will yield so easily. What did the line do before it stopped anything?

Before we bring a moving body to a straight instruction, try giving two lines an instruction of their own.

## What counts as a plus?

<!-- @line_proof_pair -->

Two sets of loose lines wait above one bench, labelled A and B. Each offers the same four rings. Make a cross in each. The small display changes when its arrangement is accepted.

Let go of the handles, then press **MOVE RIGHT** under A and under B. Each button carries both lines together. Their lengths, their angle and the place where they meet relative to one another stay the same. Compare the answers. Move them back with **MOVE LEFT**. The handles remain available; acceptance can be lost and found again.

What did moving the cross change?

A asks for perpendicular directions and a meeting of the two midpoints, with the endpoints at the marked positions. B asks for the same geometric relations wherever you make them. Both offer rings to help your hands. Only one includes those places in its test.

We can name the distinction with two conditions. This is a shortened description of the checks, with their details gathered into names:

```gdscript
accepted_a = at_targets and perpendicular and centres_meet
accepted_b = perpendicular and centres_meet
```

`and` asks that every condition on its line be true. Carrying the whole cross can preserve its relationship while changing the first answer. The program has to say which differences it will attend to before it can recognise a form.

Try moving one endpoint a little. Does acceptance disappear immediately? These checks allow some angular and positional error. Your hands can find an interval where different arrangements receive the same answer. That tolerance makes the puzzle usable; it also belongs to the definition this instrument has been given.

Press **RESET** to return the scattered lines. Try making a cross away from the rings in B. It still requires something of you. Removing the positional requirement has opened a possibility, while the angle and midpoint tests continue to draw its boundary.

Further on, another line addresses us directly: **WALK THIS LINE.**

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

The puzzles could disagree with a cross you recognised. At these screens, ask what an image lets you recognise.

Four monitors show two lines, three, four, more. Each arrangement rests for six seconds, then takes five seconds to move into another. The counts sit above the images. Stay long enough for what looked settled to change.

Start with two. The segments move alongside one another, cross into a plus, then an X. The count stays the same. A relation changes.

One segment then moves a quarter of a metre in depth. From the fixed frontal camera, the crossing can remain. This view alone cannot tell you that the segments have separated. The code can show the change the image withholds:

```gdscript
# Move both ends of one segment equally: its length stays fixed.
a.z += 0.25
b.z += 0.25
```

Move beside the monitor. The screen becomes oblique; you do not see around the object inside its image. Your viewpoint and the filming camera's viewpoint have come apart. The rods occupy a private three-dimensional scene, filmed onto this flat surface. Other cameras look obliquely or slowly turn. Their images can offer depth through shortening, overlap and movement, while leaving something undecided.

Watch the two-line study offer parallel rails and a drawing whose ends meet. A view can suggest a meeting without establishing that the segments touch. What evidence would another view supply?

Now watch three. Their ends join into a triangle. An outline closes, and you may already begin to supply a face. No face has been made here.

One whole edge moves out of the plane. Follow the gaps opening at its ends. Three non-collinear vertices determine a plane: three straight segments joined into a triangle cannot keep those joins and become a non-planar boundary. Carrying or turning the triangle would keep it flat. Here an edge leaves, and the closure is lost.

At four lines, a square waits. Watch one corner fold out of the plane as the filming camera slowly turns. The outline stays closed and each side keeps its length. The corner turns around the diagonal between its neighbours, carrying its two adjoining edges. Another edge has given the boundary a possibility the triangle could not hold.

There is still no surface between them. How to fill this folded outline is a further decision, one we will return to with triangles. Your hand can reach the monitor, but cannot enter the opening you imagine there.

At the last station, six rods can make a grid or outline a tetrahedron; twelve can outline a cube. Count before naming the body. More edges offer further arrangements, without deciding which surface should span them.

The geometric segment has one dimension. Its rendered rod has thickness; the screen carries pixels. The image lets us infer relationships from these constructions. Later, with Trace, we will ask what a record lets us recover from movement.

## Carry the whole line

<!-- @grabbable_line -->

Pick up the short rod. Carry it across your view. Turn it. Its two ends move together, keeping their distance. A direction you followed on the floor can now be a direction you hold in your hand.

Compare turning it with pulling the demonstration's endpoints apart. One operation carries a fixed span; the other changes the span itself. A length that stays fixed can become a unit for comparing other lengths.

Near whole-number world coordinates the held rod jitters and sounds. Its position has met another test. We will return to coordinates in Grid; here, keep noticing that the span survives while you carry it.

<!-- @two_point_ruler -->

Take the half-metre ruler. Bring its measuring tip to the pale block and press the action control while holding it. Read the number, then look at the blue block.

Lift the tip away, return it to the pale block, and take another reading. The pale block keeps its width. The blue one becomes smaller. Measuring in the air gives no reading and causes no shrinkage.

The number describes one object; the consequence appears on another. Inside `measure()`, the width is read from the pale block's mesh and its transform. A separate instruction multiplies the blue witness's scale by `witness_step`, which starts at `0.72`. A short animation carries it to that size. The scale is bounded, so repeated readings eventually stop making it smaller.

```gdscript
var reading: float = _subject_width_m()
var s: float = clampf(_witness.scale.x * witness_step, WITNESS_MIN, WITNESS_MAX)
```

These two lines are from the instrument's measuring function. The first reads; the second chooses a size for another body. Someone put them in the same action. At the barrier, joining points also opened a passage. Here, taking a reading also changes a size. We could have written a different consequence.

After a few repetitions the connection may begin to feel like a property of measurement. Here we can look at the instructions that produce it. How would you discover the second instruction if the changing body were outside your view?

<!-- @two_points_line -->

Watch the bead travel between its two endpoints. Wait for its return. It slows near the ends. The same path can carry different timings.

```gdscript
var p := a.lerp(b, t)
```

`lerp` interpolates: at `t = 0`, the position is A; at `t = 1`, B. Values between them give positions along the segment. The bead's script uses a cosine to move `t` back and forth. One operation supplies the route, another the rhythm. We will return to that rhythm when we learn how values change over time.

## Where the beam ends

<!-- @laser_measure -->

Take the measuring instrument and aim through the place where the barrier stood. The beam reports the first physics body it hits. If the barrier is still intact, hold the beam on it: this hall enables burning, and the barrier can break that way too. Watch where the measurement ends afterward.

A ray begins at a position and goes in a direction. The bodies it encounters help determine the answer it returns. Here a measurement can participate in changing what can be measured.

<!-- @parallel_lines -->

Walk around the three parallel segments. Here you can change your view of the rods themselves. Their apparent separation changes; they keep their shared orientation. Alongside is another relation a line can offer: company without a meeting point.

<!-- @ -->

Choose two positions and travel between them by a detour. The subtraction `b - a` still gives the same answer as it would for a direct passage. Your curve, your hesitation, the time spent looking at something halfway: none of those events entered those two variables.

There is usefulness in that small answer. We can measure without carrying every journey into the measurement. There is also a reason to want more. I want to keep the turn your hand made, the movement the two ends cannot tell apart from a direct passage.

The next room gives us a way to begin keeping it. We will save positions along the movement. Even then, we will have to choose how many.

Bring the detour.
