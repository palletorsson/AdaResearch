# The trail is already elsewhere

What does a trail remember that its next step does not use?

<!-- @random_walk_terrarium -->

Five beads move inside a glass tank on a dark cabinet. One is bright red. The other four are dimmed, still moving. Follow the red one for a moment. A turn begins to look like hesitation; a curve seems to be taking it somewhere. Choose a place you think it will reach. Keep that expectation beside what happens.

The keypad offers 2D, 3D, LONG STEP and RESET. Begin with 2D. The trail can turn in any heading, yet it never leaves its level. Move from the front to either side of the tank (a dark board closes the back): the thin arrangement holds. Press 3D. Now the bead can rise and fall. A route that looked crowded from one side may open when you look through another. Find an apparent crossing and change your viewpoint. Do the two stretches meet, or did you put them together by looking?

Earlier, a draw chose a cube from an eligible set. The last room let perturbations accumulate in a stack. Here the draw proposes a movement from the position already reached. The earlier rooms have supplied the parts: a point, coordinates, a line made from samples, an array to keep them, an increment to add. In 2D, one number becomes a heading:

```gdscript
		WalkMode.WALK_2D:
			var angle = _rand() * TAU
			return Vector3(cos(angle), 0, sin(angle)) * step_size
```

The proposed step is 0.015 metres long. Its y component is zero. The code has room for three coordinates and has declined to change one. That flatness is a decision made each time the function returns.

In 3D two draws choose a direction on a sphere; the proposed length stays the same. LONG STEP draws a length too. Try it, then return to 3D. Look for what the longer movements do to the tangle. The cabinet is using this particular rule:

```gdscript
			var u = _rand()
			var levy_step = step_size * pow(u + LEVY_OFFSET, LEVY_EXPONENT)
			levy_step = minf(levy_step, step_size * LEVY_STEP_CAP)
			return direction * levy_step
```

The offset is 0.01, the exponent −0.5, the cap ten. Every length is drawn along this curve; there is no separate switch for a spectacular leap. The largest permitted proposal is 0.15 metres. Even this mode's long reach has an edge.

Look near the glass. A bead approaches, turns, stays inside. There is no test for whether it wants to return. First the code proposes a position; then the enclosure changes it:

```gdscript
		var step = _generate_step()
		var new_pos = _walker_positions[i] + step

		# Boundary reflection
		new_pos = _reflect_boundaries(new_pos)
```

For a wall at x = 0.25, an attempted endpoint at 0.27 returns as 0.23. The overshoot folds back. The displayed segment joins the retained positions on either side of this operation. It does not draw the contact with the wall. A short stroke can therefore stand for a longer proposed movement. The line we learned to trust as a record has left something out again.

The next few lines keep another difference:

```gdscript
		# Record trail
		_walker_trails[i].append(_walker_positions[i])
		if _walker_trails[i].size() > trail_length:
			_walker_trails[i] = _walker_trails[i].slice(1)

		_walker_positions[i] = new_pos
```

Read the order aloud. Keep where we were. Shorten the record. Put the bead where we are now. At step 300 the trail holds positions 100 through 299; the bead has reached position 300. The drawing is already behind the body, and the beginning has gone. Its absence from the glass does not mean those steps were never taken.

Nothing in the step generator reads this trail. Erasing its stored points in a controlled source test leaves the subsequent positions unchanged. The program still has memory: a current position, a generator state, a counter, a rule. What it lacks here is a way to consult the drawn history when choosing a heading. To make a walker avoid its own trail, that relation would have to be built. Between this cabinet and the basin, a sculpture of small cubes shows one way to build it. Before each step, that walk sets aside every neighbouring cell it already occupies and chooses among the rest, stopping early if none is left; it lays at most twenty-three cubes. The walk is finished when the hall is built, and what stands is the path alone: nothing marks the moves it turned down.

The wing beside the tank carries the logbook; its buttons now share the front console with the mode controls. ONE and ALL change which beads and trails are bright. All five continue stepping under either view. Following one has changed your access to the population, without sending the other four away.

Read the seed, then press RESET. The named walk returns from the centre. Compare it at the same step count, with the same mode. NEW SEED chooses a five-digit number different from the current one; an older number can return later. Changing modes retains the seed but spends its draws differently. A number alone is not the whole recipe for a path.

Two times sit together on the plate. Simulation time counts the accepted steps at thirty per second. The frame clock adds the time supplied to the running process since reset. A stalled frame can separate them: this implementation accepts at most five steps in one frame and discards the excess. In a controlled two-second frame, the clock gains two seconds while the walk gains only a sixth of a simulated second. There is no pause control on this cabinet. RESET starts its account over while the museum continues.

Below, MSD measures the five beads' average squared distance from their release point. Watch it increase or decrease. The glass bounds it; the number does not report how much trail has accumulated or how far the beads have travelled. A return toward the centre can lower it while adding more line.

<!-- @random_draw_dot -->

## A hand with company

Pick up the drawing dot. Move your hand slowly across the space, then hold it still. The small green tip keeps wandering. What part of this line belongs to your movement?

This is the grip from Trace with one addition. Thirty times per second, while you hold it, a random direction adds a small step to an offset. The next step starts from the offset already reached:

```gdscript
walk_offset = (walk_offset + direction * STEP_SIZE).limit_length(RADIUS)
tip.global_position = _grab_point.global_position + walk_offset
```

Your hand carries the origin; the tip walks around it. Each proposed step is 1.2 centimetres, and the offset cannot exceed 25 centimetres. At that boundary, the program shortens an outward proposal. Its freedom has a radius.

Press HAND / RANDOM to clear the line and draw with the hand alone. Switch back and try the same gesture. The point-count display still counts retained samples, as it did in Trace. The random clock proposes thirty steps a second, but the visible trail is sampled by the drawing process; a stalled frame can miss intermediate positions.

CLEAR / REPLAY restores the random seed and clears the trail. The random steps can repeat. Your hand need not. Let go and the wandering stops: this encounter gives chance movement only while someone holds it.

<!-- @random_walk_128 -->

Cross the bridge over the narrow basin and enter the larger glass frame. The gallery and the experiment remain at the same level; the gap distinguishes their floors. Its ten-metre field keeps another account of a walk: a visited cell rises. Four possible directions are enough to change the ground. The working lattice has thirty-two cells on each side, despite the older name `random_walk_128`.

Look at a high place. It records repeated visits; it was not selected as a destination. A small rule has become a spatial obstacle through what the surface retained. Compare this ground with the trails in the instrument. Both keep something of movement, and neither keeps everything. The surrounding glass names a boundary of the experiment; the openings let you pass through or watch from outside.

<!-- @ -->

Stay with a shape you had begun to read as a creature. What would its next step need to know for that reading to become a capability? The missing relation is an invitation to make another rule. For now, we leave with a path whose history exceeds both its current position and the drawing we can still see. In Random Gaussian, we gather draws in another way and ask what shape appears when we count where they land.
