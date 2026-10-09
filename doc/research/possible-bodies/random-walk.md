# The trail is already elsewhere

[Random Remove](random-remove.html) → **Random Walk** → [Random Gaussian](random-gaussian.html)

[The primary and its book passage](/necklace/thread?map=Random_Walk&role=primary) · [Waves, randomness and noise plan](/research/waves-chance-noise/index.html#Random_Walk)

Follow the red bead until a turn begins to look like hesitation. What would the next step need to know for that reading to become a capability?

![The existing terrarium and logbook wing from the desktop visitor's viewpoint](random-walk-desk.png)

The room keeps Claude's existing `random_walk_terrarium` as its one primary: a glass tank, dark backboard, enlarged red bead, keypad and logbook wing. All twelve placements and the recovered floor remain. This continuation tests the encounter independently and lets its actual rules carry the book.

## A plane, a volume, a longer reach

Start with 2D. Move around the case and notice the level the bead cannot leave. In 3D that coordinate opens. An apparent crossing might separate when you change your viewpoint. LEVY changes the proposed length as well as the direction; its longest permitted step is 0.15 m.

![2D, 300 steps](random-walk-2d.png)
![3D, 300 steps](random-walk-3d.png)
![LEVY, 300 steps](random-walk-levy.png)

These three captures share a camera and seed 31415. Each follows 300 updates of five walkers. They are controlled source captures: simulation time reads 10 seconds while the unadvanced frame clock reads zero. There is no visitor pause control. The modes consume their random draws differently, so these are not identical paths with another coordinate attached.

## The point the line leaves out

Look for a turn near a wall. The next position is proposed, then folded if it lies outside. The displayed segment joins the retained endpoints. It does not include the contact with the glass.

```gdscript
var step = _generate_step()
var new_pos = _walker_positions[i] + step

# Boundary reflection
new_pos = _reflect_boundaries(new_pos)
```

The reading view below uses actual positions and proposals exported from the Godot artifact, with no replacement random generator. Select **LEVY**, then **Next reflected step** to show its proposal. The amber endpoint is what the draw attempted; red is the position the enclosure kept. Change projection to inspect a difference hidden along another axis. In these particular 300-step captures, the followed 2D and 3D beads never require a reflection. The LEVY bead does, eleven times.

[Explore captured positions and proposals](random-walk.html).

These browser controls belong to the review. The complete captured history and proposed endpoint are not displays added to the VR cabinet. ONE/ALL exists in both places; in Godot all five walkers continue stepping whichever is bright.

The default line keeps only two hundred previous positions. At step 300 those are positions 100–299; the bead is at 300. Show the complete captured history to recover the beginning in this review. Turn that option off and it leaves again. The source has to retain different data to make that return possible.

## A trail the next step never consults

```gdscript
_walker_trails[i].append(_walker_positions[i])
if _walker_trails[i].size() > trail_length:
    _walker_trails[i] = _walker_trails[i].slice(1)

_walker_positions[i] = new_pos
```

Keep where we were. Shorten the record. Put the bead where we are now. The ordering makes the trail lag by one update even before its earliest points are discarded.

The independent check replayed all three captured walks, cleared the stored trails at step 60, and switched from ONE to ALL. Every later position of all five walkers still agreed exactly. The check also confirmed that the stored trail was actually empty before continuing. This is evidence about the unused trail; the program still has position, generator, mode and timing state.

The familiar parts have accumulated: point, coordinates, sampled line, array, increment, draw. To make a bead avoid its own trail would require another connection between those parts. The desire to read a creature in the tangle can suggest that next experiment without making it an existing capability.

## Two accounts of time

![The housed logbook names the rule, steps, clocks, retained trail, seed and boundary](random-walk-logbook.png)

The simulation count and frame clock can diverge. At thirty updates a second, a two-second frame would ordinarily supply sixty updates. The implementation accepts at most five, while its frame clock gains the supplied two seconds. The excess is discarded, not queued for a later frame. The source test verifies both the five accepted updates and the absence of a backlog.

RESET replays the named procedure at equal step counts. It does not reset every fractional timing accumulator. NEW SEED explicitly rejects the current five-digit number, though an older one may return later. Different modes consume different numbers of draws; the seed alone does not specify the path.

The cabinet's MSD measures the five beads' average squared distance from their release point. It can decrease while the trail grows. Glass bounds the possible value; it does not make the reading a measure of path length, history or entropy.

## What is ready

**129 independent desktop checks passed, zero assertion failures, engine exit 0.** The seven control signals, actual desktop pointer 2D/NEW SEED/RESET, three walk rules, reflection, replay, trail retention, clock cap, physical access and unload/rebuild were exercised. Three complete 300-step histories record five walkers each; every frame was checked against replay.

The neighbouring sampling pavilion's string boolean now uses its existing parser, allowing its east observation-window setting to load. The previous script errors are absent. This is the only production-script change; the terrarium itself is preserved. The pavilion annotation now distinguishes a proposed step from the endpoint the walls fold back.

All twelve placements instantiate. The pavilion and a pixel cloud occupy some local routes; the tested door-to-door and terrarium approaches remain open. The fine trails are pale through the glass in these desktop captures, and the small lettering still needs a person at headset distance. No Quest-performance or tracked-hand claim is made.

The run retains startup diagnostics for the audio UID, certificate store and logger, renderer/registry warnings, and two unset viewport-texture errors from the catalyst crystal. These are separate from the repaired window parser. There are no script errors or shutdown leak warnings in this run.

[Desktop report](random-walk-check.json) · [Run receipt](random-walk-run.json) · [Captured histories](random-walk-histories.json) · [Tutorial](random-walk-tutorial.md) · [Technical notes](random-walk-technical.md) · [Critical text](random-walk-critical.md)

**Next: [Random Gaussian](random-gaussian.html).** We gather draws by frequency and ask what kind of shape that account makes visible.

## Book passage

# The trail is already elsewhere

What does a trail remember that its next step does not use?

<!-- @random_walk_terrarium -->

Five beads move inside a glass tank on a dark cabinet. One is bright red. The other four are dimmed, still moving. Follow the red one for a moment. A turn begins to look like hesitation; a curve seems to be taking it somewhere. Choose a place you think it will reach. Keep that expectation beside what happens.

The keypad offers 2D, 3D, LEVY and RESET. Begin with 2D. The trail can turn in any heading, yet it never leaves its level. Walk around the tank: the thin arrangement holds. Press 3D. Now the bead can rise and fall. A route that looked crowded from one side may open when you look through another. Find an apparent crossing and change your viewpoint. Do the two stretches meet, or did you put them together by looking?

The previous room let a draw choose a cube from a set. Here the draw proposes a movement from the position already reached. The earlier rooms have supplied the parts: a point, coordinates, a line made from samples, an array to keep them, an increment to add. In 2D, one number becomes a heading:

```gdscript
		WalkMode.WALK_2D:
			var angle = _rand() * TAU
			return Vector3(cos(angle), 0, sin(angle)) * step_size
```

The proposed step is 0.015 metres long. Its y component is zero. The code has room for three coordinates and has declined to change one. That flatness is a decision made each time the function returns.

In 3D two draws choose a direction on a sphere; the proposed length stays the same. LEVY draws a length too. Try it, then return to 3D. Look for what the longer movements do to the tangle. The cabinet is using this particular rule:

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

Nothing in the step generator reads this trail. Erasing its stored points in a controlled source test leaves the subsequent positions unchanged. The program still has memory: a current position, a generator state, a counter, a rule. What it lacks here is a way to consult the drawn history when choosing a heading. To make a walker avoid its own trail, that relation would have to be built.

The wing beside the tank carries the logbook. ONE and ALL change which beads and trails are bright. All five continue stepping under either view. Following one has changed your access to the population, without sending the other four away.

Read the seed, then press RESET. The named walk returns from the centre. Compare it at the same step count, with the same mode. NEW SEED chooses a five-digit number different from the current one; an older number can return later. Changing modes retains the seed but spends its draws differently. A number alone is not the whole recipe for a path.

Two times sit together on the plate. Simulation time counts the accepted steps at thirty per second. The frame clock adds the time supplied to the running process since reset. A stalled frame can separate them: this implementation accepts at most five steps in one frame and discards the excess. In a controlled two-second frame, the clock gains two seconds while the walk gains only a sixth of a simulated second. There is no pause control on this cabinet. RESET starts its account over while the museum continues.

Below, MSD measures the five beads' average squared distance from their release point. Watch it increase or decrease. The glass bounds it; the number does not report how much trail has accumulated or how far the beads have travelled. A return toward the centre can lower it while adding more line.

<!-- @ -->

Stay with a shape you had begun to read as a creature. What would its next step need to know for that reading to become a capability? The missing relation is an invitation to make another rule. For now, we leave with a path whose history exceeds both its current position and the drawing we can still see. In Random Gaussian, we gather draws in another way and ask what shape appears when we count where they land.
