# A trail without a plan

What can a path remember that its next step does not use?

<!-- @random_walk_terrarium -->

A glass tank stands on a dark cabinet to your right as you come in from the north, its keypad toward you, a wing bolted to its far side carrying a small plate of text. Five beads drift in the tank. One is red; the other four are dimmed to grey, so that one trail can be followed before the population is read. Watch the red bead for a dozen steps. Its trail curls, doubles back, seems to head for a corner. Say aloud where the next step will go, then watch it. Do this three or four times. The prediction that survives is the one that promised nothing.

The cabinet's keypad says 2D, 3D, LEVY and RESET. Under 2D every bead stays in the middle plane of the tank; under 3D the beads rise and sink as freely as they wander sideways. Compare the two before touching LEVY: the same fixed step, one more direction to spend it in. Then press LEVY and look for the long jumps among the short ones. Under LEVY most steps are as short as before and about one in eighty is a leap of several step-lengths, never more than ten.

Now read what the wing's plate keeps. Six lines: the rule and its dimension; steps taken and the simulation time they add up to at thirty a second; the frame clock beside it, with the catch-up cap of five steps a frame that keeps a stalled frame from emptying a second of steps into one jump; how many positions of the trail are kept, two hundred at most; the seed, and what RESET does with it; the glass rule. Press RESET and the red bead's trail is redrawn from the middle, and after a few seconds the shape is the one you just saw. The seed is named on the plate, and RESET replays it, cube for cube. NEW SEED on the wing names another and the shape is new. ONE and ALL trade the single red trail for five coloured ones and back.

Three things are drawn in the tank, and it helps to name them apart. The step is a single increment, gone as soon as it is added. The position is the sum of every increment so far, and it is the only thing the walker carries. The trail is a drawing of the last two hundred positions, kept by the display for you. The source keeps the three apart in a few lines:

```gdscript
		var step = _generate_step()
		var new_pos = _walker_positions[i] + step

		# Boundary reflection
		new_pos = _reflect_boundaries(new_pos)

		# Record trail
		_walker_trails[i].append(_walker_positions[i])
		if _walker_trails[i].size() > trail_length:
			_walker_trails[i] = _walker_trails[i].slice(1)
```

Nothing in the step consults the trail. The step in 2D is a fixed length in a random heading:

```gdscript
		WalkMode.WALK_2D:
			var angle = _rand() * TAU
			return Vector3(cos(angle), 0, sin(angle)) * step_size
```

and LEVY varies the length by a heavy-tailed rule with a finite cap:

```gdscript
			var u = _rand()
			var levy_step = step_size * pow(u + LEVY_OFFSET, LEVY_EXPONENT)
			levy_step = minf(levy_step, step_size * LEVY_STEP_CAP)
			return direction * levy_step
```

The cap is ten step-lengths. Read the offset too: with `LEVY_OFFSET` at 0.01 and the exponent at −0.5, the largest value the power can reach is exactly ten, so the cap and the offset agree, and no jump crosses the tank in one step. The tail is heavy but it is not unbounded, and the long jumps you see are the rule's, not a fault.

The glass matters as much as the steps. A step that would leave the tank is folded back by the same distance it overshot:

```gdscript
	if pos.x < -half.x: pos.x = -half.x + (-half.x - pos.x)
	if pos.x > half.x: pos.x = half.x - (pos.x - half.x)
```

Follow a bead near a wall and compare its next positions with one in the interior. The same sampling supplies both attempted steps; the enclosure gives them different outcomes. When a trail doubles back, look for a wall before you call the return a preference for an earlier place. In 2D the rule also pins the height, which is why the plane holds:

```gdscript
	else:
		pos.y = terrarium_size.y / 2.0
```

Because the walls reflect, these walks stay bounded, and you cannot read their long-term spread as the unlimited spreading of a walk in open space. The screen on the cabinet prints a mean squared displacement; watch it stall as the beads meet the glass.

Last, take a crossing. Under 3D, find a place where the red trail seems to cross itself, then step to the side of the tank and look again. Often the two stretches are a hand's width apart in depth, and the crossing was your viewpoint's. A trail is a spatial record as well as a temporal one, and reading it needs both.

<!-- @ -->

What the trail remembers, then, is everything the walker does not: where it has been, in order, for two hundred steps. The walker keeps a position and nothing else, and the next step is drawn without looking. A tangle can suggest hesitation, exploration or an intention to return; none of those readings is in the rule. In the next room the question turns from one path to many draws: not where the accumulated steps go, but how a law shapes the frequencies of a great many sampled values, and what the bell that appears owes to the sum.
