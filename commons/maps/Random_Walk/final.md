# The trail is already elsewhere

What does a trail remember that its next step does not use?

<!-- @random_walk_terrarium -->

Five beads move inside a glass tank. One is bright red; the other four are dimmed, still moving. Follow the red one. A turn begins to look like hesitation; a curve seems to be taking it somewhere. Choose a place you think it will reach. Keep that expectation beside what happens.

Begin with 2D. The trail can take any heading, yet it never leaves its level. Move from the front to either side of the tank. The thin arrangement holds. Press 3D. Now the bead can rise and fall. Find an apparent crossing and change your viewpoint. Do the two stretches meet, or did you put them together by looking?

The last room let turns accumulate in a stack. Here a draw proposes movement from the position already reached. We have met the parts: a point, coordinates, an increment, a line made from samples, an array to keep them. In 2D, one number becomes a heading around a circle. The code has three coordinates and declines to change one. Flatness is a decision made at every step.

In 3D the proposed length stays the same. LONG STEP draws a length too. Try it, then return to 3D. Does a longer movement carry the bead out of a patch it has repeatedly crossed? The code calls this a Lévy flight, but even its longest proposal has a limit. The comparison does not establish a better search strategy.[^levy]

Near the glass, a bead approaches, turns and stays inside. The enclosure folds its proposed endpoint back. For a wall at x = 0.25, an attempted endpoint at 0.27 becomes 0.23. The drawn segment joins retained positions without visiting the contact point. A short stroke can stand for a longer proposal. The line has left something out again.

It also arrives late. The record stores the position before the bead moves, then gives up its oldest entries. At step 300 the trail holds positions 100 through 299; the bead has reached 300. Its beginning has gone, and its latest place has not entered the line. Neither absence means that movement did not happen.

The step proposes a change, the position retains its result, and the trail stores selected earlier positions for us. Nothing in the heading rule reads the trail. Erasing its stored points in a controlled test leaves subsequent positions unchanged. There is still memory: current position, generator state, counter. To make the walker avoid its own drawing, another relation would have to be built.

<!-- @pixel_cloud -->

On your right, a sculpture of small cubes shows one way. Before each step, that walk sets aside the neighbouring cells it already occupies and chooses among the rest. It stops if none is available. The walk has finished by the time you arrive. What stands is its path; nothing marks the moves it refused.

<!-- @random_walk_terrarium -->

Back at the tank, ONE and ALL change which beads and trails are bright. All five keep stepping. Following one changed your access to the population without sending the others away.

Read the seed, then RESET. Compare the returning path at the same step count and in the same mode. Changing modes spends the draws differently; a number alone is not the whole recipe. The plate also carries two clocks, which can disagree when a frame stalls.[^walk-clock] Even the time offered as evidence has a procedure.

Below them, MSD measures the beads' average squared distance from their release point. A return toward the centre can lower it while adding more line. The gauge does not measure how far they travelled. Look back at the trail: which account answers the question you wanted to ask?

<!-- @random_position_rails -->

## Somewhere to start

Two rails each carry a block. Slide the white prediction marker to a place you think one will reach, then pull NEXT. Empty frames appear before either body moves. The machine has made its choices; for a moment you can see its destinations.

Blue can cross almost the whole rail. Pink stays near where it was. Both received the same number. Blue used it as a new position; pink used it as an increment. The small addition carries a past into the next move. What does knowing the last position give you now?

At the ends, an outward step folds back. The latest twelve landing pairs collect below; older marks disappear while pink keeps the position they helped it reach. The past can survive in a present state after its record is gone.

Watch the journeys between the empty frames. Both take one second with the same easing. Even blue's fresh destination arrives smoothly. Looking continuous is not enough to tell us what a process remembers.

HOLD lets the revealed move finish and stops the next draw. REPLAY returns the bodies and repeats their choices. Your marker can move elsewhere. A prediction has entered the room, but the machine has no obligation to meet it.

<!-- @random_draw_dot -->

Pick up the drawing dot. Move your hand slowly, then hold it still. The green tip keeps wandering. What part of this line belongs to you?

The Point Trace tool has acquired an offset that takes random steps. Your hand carries its origin. The tip walks around it, confined to a radius of twenty-five centimetres. At the boundary an outward proposal is shortened. Its freedom has a radius.

Press HAND / RANDOM to clear the line and draw with the hand alone. Switch back and repeat the gesture. The trail keeps samples of the movement, not every intermediate position.[^drawing-clock]

CLEAR / REPLAY restores the random seed. Those steps can repeat; your hand need not. Let go and the wandering stops. This encounter gives chance movement only while someone holds it.

<!-- @random_walk_128 -->

Cross the bridge over the narrow basin and enter the larger glass frame. The floors remain at the same level, but the gap separates gallery from experiment. Here a visited cell rises. Four directions are enough to change the ground.

A high place records returns; it was not chosen as a destination. Whether returning too often is a problem depends on what we wanted the walker to do. The count cannot supply that purpose. Movement has become a spatial obstacle through what the surface retained. Compare this ground with the cabinet's lines. Each gives part of a history a different body.[^walk-field]

<!-- @ -->

In the tutorial, the point leaves your hand and begins choosing steps. You have supplied its starting place. Its trail makes those choices available to you without making them available to the next heading.

Stay with a shape you had begun to read as a creature. What would its next step need to know for that reading to become a capability? For now, its history exceeds both its current position and the drawing we can still see. In Random Gaussian we gather draws another way and ask what shape appears when we count where they land.

[^levy]: The ordinary proposal is 0.015 metres. LONG STEP multiplies it by an inverse-square-root sample with offset 0.01, exponent −0.5 and cap ten, giving a maximum of 0.15 metres before boundary folding. This bounded implementation is not an unbounded Lévy process or evidence about animal foraging. The nearby self-avoiding pixel sculpture lays at most twenty-three cubes.

[^walk-clock]: The cabinet accepts thirty simulation steps per second, at most five per frame, discarding excess time. A two-second frame can therefore add two seconds to its frame clock but only a sixth of a second to its simulated walk. RESET restarts both accounts; the cabinet has no pause control. NEW SEED selects a five-digit number different from the current one, although an older one may recur.

[^drawing-clock]: While held, the random offset proposes 1.2-centimetre steps thirty times per second. The drawing process samples the visible trail separately, so a stalled frame can omit intermediate positions. Replay resets the random procedure, not a visitor's gesture.

[^walk-field]: The larger field is ten metres across with thirty-two cells per side, despite its older source name, `random_walk_128`. Its height records visits; that height does not guide the next step.
