# The set before the choice

A board of sixty-four small cubes stands on a pedestal in the middle of the hall, numbered along two edges, with a panel of buttons tilted toward you and two lines of text above the far edge. Sixteen of the cubes are amber; the other forty-eight are grey.

<!-- @remove_random -->

Before pressing anything, count the amber ones. Four rows by four columns, from column 2 to column 5 and row 2 to row 5: sixteen possible first choices. The grey cubes are present, numbered, and out of the question. The line above the board says so in its own words: RANGE, columns 2–5, rows 2–5, a seed, and `Eligible: 16   Remaining: 16   Removed: 0`.

Press REMOVE ONE. One amber cube turns red for a moment and is gone; its slot plate stays, so the address survives the cube. The line names it: last removed, column such, row such. Remaining: fifteen. Press again. Does the new gap touch the first? Either answer is possible. Watch the amber set rather than expecting the gaps to spread like a stain.

Now point to a cube you know cannot disappear, and press until the amber is gone. Sixteen presses. The final shape was never in doubt: the square you counted at the start, emptied. What you could not know was the order, and the plate under each gap keeps only the fact of absence, not the turn it was taken on.

The rule that decided the sixteen is one question asked of every cube's own position on the board:

```gdscript
	match selection_mode:
		"All": return true
		"Column": return is_equal_approx(pos.x, float(target_column))
		"Row": return is_equal_approx(pos.z, float(target_row))
		"Range":
			return pos.x >= x_min and pos.x <= x_max and pos.y >= y_min and pos.y <= y_max and pos.z >= z_min and pos.z <= z_max
```

The coordinates are the board's, not the hall's: column 3 is the cube at x = 3 on this eight-by-eight, wherever the pedestal stands. The rule runs over every cube once and keeps the ones it admits; a cube already removed is skipped before the question is even put:

```gdscript
		if _removed.has(i):
			continue
		var included := _should_include_instance(_original[i].origin)
```

Only then does chance enter, and it enters only the remaining candidates:

```gdscript
	var offset := _rng.randi_range(0, active_instances.size() - 1)
	var index := active_instances[offset]
```

A whole number between zero and one less than the count of what remains, and the cube at that place in the list. The draw never sees a grey cube; there is no probability, however small, of its being chosen in this run. Removal is a third step again:

```gdscript
	transform.basis = Basis().scaled(Vector3.ZERO)
	multimesh.set_instance_transform(index, transform)
```

the cube's own transform scaled to nothing, the board underneath untouched. Filter, draw, delete: three decisions that are easy to fold into one word, *random*, and only the middle one is.

Press RESET. All sixty-four cubes return, sixteen amber again, and the line shows the same seed. Empty the square a second time and watch the order: it is the first order, cube for cube, because RESET on this bench puts the generator back to the seed it names:

```gdscript
	if replay_on_reset:
		_rng.seed = run_seed
```

So the two histories you might have wished to compare are now comparable. Press NEW SEED and empty it a third time for an order that is nobody's fault.

Then keep a seed and change the rule. Press ROW: all sixty-four return and only row 3 is amber, eight candidates. Press COLUMN for eight the other way. The same seed feeds the same draws into a different list, and the same draws land on different cubes; press ALL and the boundary is the board's own edge. Equal counts hide a spatial difference: a rule can offer the same number of choices while making different places available, and the seed cannot tell.

<!-- @ -->

Ask now whether a random choice can be fair to a cube that was grey. Within the amber set the draw is even; the grey were decided before it ran, by a rule you can read and change, and the seed that makes a run repeatable has no say in it. Carry the changing set into the next room, where a walker takes its steps from draws like these and the set of places it can reach is decided one step at a time.
