# The trail is already elsewhere

What does a trail remember that its next step does not use?

<!-- @random_walk_terrarium -->

Five beads move inside a glass tank on a dark cabinet. One is bright red. The other four are dimmed, still moving. Follow the red one for a moment. A turn begins to look like hesitation; a curve seems to be taking it somewhere. Choose a place you think it will reach. Keep that expectation beside what happens.

The keypad offers 2D, 3D, LONG STEP and RESET. Begin with 2D. The trail can turn in any heading, yet it never leaves its level. Move from the front to either side of the tank (a dark board closes the back): the thin arrangement holds. Press 3D. Now the bead can rise and fall. A route that looked crowded from one side may open when you look through another. Find an apparent crossing and change your viewpoint. Do the two stretches meet, or did you put them together by looking?

Earlier, a draw chose a cube from an eligible set. The last room let perturbations accumulate in a stack. Here the draw proposes a movement from the position already reached. The earlier rooms have supplied the parts: a point, coordinates, a line made from samples, an array to keep them, an increment to add. In 2D, one number becomes a heading around a circle.

The proposed step is 0.015 metres long. Its y component is zero. The code has room for three coordinates and has declined to change one. That flatness is a decision made each time the function returns.

In 3D two draws choose a direction on a sphere; the proposed length stays the same. LONG STEP draws a length too; the code calls the mode a Lévy flight.[^levy] Try it, then return to 3D. Look for what the longer movements do to the tangle, and ask whether a bead returns less often to a patch it has already worn. Its length comes from an inverse-square-root rule.

The offset is 0.01, the exponent −0.5, the cap ten. Every length is drawn along this curve; there is no separate switch for a spectacular leap. The largest permitted proposal is 0.15 metres. Even this mode's long reach has an edge. A longer proposal can carry it out of a patch it has repeatedly crossed. Does that change its returns? This cabinet gives you a comparison to watch; it does not establish a better search strategy.

Look near the glass. A bead approaches, turns, stays inside. There is no test for whether it wants to return. First the code adds a step to the position already reached; then the enclosure folds the proposed endpoint back inside.

For a wall at x = 0.25, an attempted endpoint at 0.27 returns as 0.23. The overshoot folds back. The displayed segment joins the retained positions on either side of this operation. It does not draw the contact with the wall. A short stroke can therefore stand for a longer proposed movement. The line we learned to trust as a record has left something out again.

The record keeps another difference. Read the order aloud. Keep where we were. Shorten the record. Put the bead where we are now. At step 300 the trail holds positions 100 through 299; the bead has reached position 300. The drawing is already behind the body, and the beginning has gone. Its absence from the glass does not mean those steps were never taken.

Nothing in the step generator reads this trail. Erasing its stored points in a controlled source test leaves the subsequent positions unchanged. The program still has memory: a current position, a generator state, a counter, a rule. What it lacks here is a way to consult the drawn history when choosing a heading. To make a walker avoid its own trail, that relation would have to be built.

<!-- @pixel_cloud -->

On your right, between this cabinet and the basin, a sculpture of small cubes shows one way to build it. Before each step, that walk sets aside every neighbouring cell it already occupies and chooses among the rest, stopping early if none is left; it lays at most twenty-three cubes. The walk is finished when the hall is built, and what stands is the path alone: nothing marks the moves it turned down.

<!-- @random_walk_terrarium -->

The wing beside the tank carries the logbook; its buttons now share the front console with the mode controls. ONE and ALL change which beads and trails are bright. All five continue stepping under either view. Following one has changed your access to the population, without sending the other four away.

Read the seed, then press RESET. The named walk returns from the centre. Compare it at the same step count, with the same mode. NEW SEED chooses a five-digit number different from the current one; an older number can return later. Changing modes retains the seed but spends its draws differently. A number alone is not the whole recipe for a path.

Two times sit together on the plate. Simulation time counts the accepted steps at thirty per second. The frame clock adds the time supplied to the running process since reset. A stalled frame can separate them: this implementation accepts at most five steps in one frame and discards the excess. In a controlled two-second frame, the clock gains two seconds while the walk gains only a sixth of a simulated second. There is no pause control on this cabinet. RESET starts its account over while the museum continues.

Below, MSD measures the five beads' average squared distance from their release point. Watch it increase or decrease. The glass bounds it; the number does not report how much trail has accumulated or how far the beads have travelled. A return toward the centre can lower it while adding more line.

<!-- @random_position_rails -->

## Somewhere to start

Two rails stretch beside the tank. Each carries a block. Slide the white marker to a place you think one will reach, then pull NEXT. Two empty frames appear before either body moves. The machine has made its choices. For a moment, you can see where it intends to put them.

The blue block can cross almost the whole rail. The pink one stays near where it was. Follow a few turns. Try another guess. What does knowing the last position give you?

Both receive the same new number, drawn between minus one and one. Blue uses it to choose a place along the rail. Pink uses it to propose a step of at most forty centimetres from its current place. The small addition carries a past into the next move. A walk needs somewhere to start. The pink block is the coin you tossed two rooms ago, given a beam to walk on.

At the rail ends, an outward step folds back, as it did at the terrarium glass. These bodies have not been offered an endless line. Their twelve most recent landing pairs collect below, newest at the top. Older marks disappear while the pink block keeps the position those movements helped it reach. Erase the record and that next step can still be taken.

Watch the journeys between the empty frames. Both motors take one second, with the same easing. Even blue's fresh destinations arrive by a smooth movement. Looking continuous is not enough to tell us what a process remembers.

RUN repeats the experiment; HOLD lets the revealed move finish and stops the next draw. REPLAY brings both bodies to the centre and repeats their choices. Your marker can move elsewhere. It changes neither rule. A prediction has entered the room, but the machine has no obligation to meet it.

<!-- @random_draw_dot -->

Pick up the drawing dot. Move your hand slowly across the space, then hold it still. The small green tip keeps wandering. What part of this line belongs to your movement?

This is the drawing dot from the Point Trace room, with one addition. Thirty times per second, while you hold it, a random direction adds a small step to an offset. The next step starts from the offset already reached.

Your hand carries the origin; the tip walks around it. Each proposed step is 1.2 centimetres, and the offset cannot exceed 25 centimetres. At that boundary, the program shortens an outward proposal. Its freedom has a radius.

Press HAND / RANDOM to clear the line and draw with the hand alone. Switch back and try the same gesture. The point-count display still counts retained samples, as it did there. The random clock proposes thirty steps a second, but the visible trail is sampled by the drawing process; a stalled frame can miss intermediate positions.

CLEAR / REPLAY restores the random seed and clears the trail. The random steps can repeat. Your hand need not. Let go and the wandering stops: this encounter gives chance movement only while someone holds it.

<!-- @random_walk_128 -->

Cross the bridge over the narrow basin and enter the larger glass frame. The gallery and the experiment remain at the same level; the gap distinguishes their floors. Its ten-metre field keeps another account of a walk: a visited cell rises. Four possible directions are enough to change the ground. The working lattice has thirty-two cells on each side, despite the older name `random_walk_128`.

Look at a high place. It records repeated visits; it was not selected as a destination. This ground counts its returns. Whether returning too often is a problem depends on what we wanted the walker to do; the count alone cannot supply that purpose. A small rule has become a spatial obstacle through what the surface retained. Compare this ground with the trails in the instrument. Both keep something of movement, and neither keeps everything. The surrounding glass names a boundary of the experiment; the openings let you pass through or watch from outside.

<!-- @ -->

In the tutorial, the point leaves your hand and starts choosing its steps. You have supplied a place to begin. The trail makes those choices available to you without making them available to its next heading.

Stay with a shape you had begun to read as a creature. What would its next step need to know for that reading to become a capability? The missing relation is an invitation to make another rule. For now, we leave with a path whose history exceeds both its current position and the drawing we can still see. In Random Gaussian, we gather draws in another way and ask what shape appears when we count where they land.

[^levy]: The source retains the name Lévy flight. This particular sampler is bounded: its offset and exponent limit the proposal even before the enclosure folds it. The name does not make this an unbounded Lévy process or establish a model of animal foraging.
