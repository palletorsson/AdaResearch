# The set before the choice

In the last room, sorting changed the neighbours while the count stayed. Here, find a cube the process cannot choose.

A board of sixty-four small cubes stands on a pedestal in the middle of the hall, numbered along two edges. Its controls sit together on the console in front; a cased account of the set stands to the left. Sixteen of the cubes are amber; the other forty-eight are grey.

<!-- @remove_random -->

Before pressing anything, count the amber ones. Four rows by four columns, from column 2 to column 5 and row 2 to row 5: sixteen possible first choices. The grey cubes are present, numbered, and out of the question. The plate beside the board says so in its own words: RANGE, columns 2–5, rows 2–5, a seed, and `Eligible: 16   Remaining: 16   Removed: 0`.

Press REMOVE ONE. One amber cube turns red for a moment and is gone; its slot plate stays, so the address survives the cube. The line names it: last removed, column such, row such. Remaining: fifteen. Press again. Does the new gap touch the first? Either answer is possible. Watch the amber set rather than expecting the gaps to spread like a stain.

Now point to a cube you know cannot disappear, and press until the amber is gone. Sixteen presses. The final shape was never in doubt: the square you counted at the start, emptied. What the initial picture did not tell you was the order, and the plate under each gap keeps only the fact of absence, not the turn it was taken on.

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

the cube's own transform scaled to nothing, the board underneath untouched. Look into the gap. Its small slot plate is still there. The cube also keeps an address inside the MultiMesh, and the remover has kept its original transform in `_original`. The model can stop drawing this body without forgetting how to put it back. At this board, the surface your feet stand on belongs to the museum; these small disappearances make no holes in it. Filter, draw, delete: three decisions that are easy to fold into one word, *random*, and only the middle one is.

Press RESET. All sixty-four cubes return, sixteen amber again, and the line shows the same seed. Empty the square a second time and watch the order: it is the first order, cube for cube, because RESET on this bench puts the generator back to the seed it names:

```gdscript
	if replay_on_reset:
		_rng.seed = run_seed
```

Watch the first few removals twice. After RESET, waiting before your next press does not advance the removal generator. The room goes on around the board; the next choice waits for the button. The same run can be taken slowly or quickly, although a press made during the red highlight is ignored while that removal is busy.

Press NEW SEED and try again. The button selects a five-digit seed and restores the set. It may select one you have already used, and a different seed does not guarantee a different removal order. Compare the histories you get rather than requiring difference as proof of randomness.

Then keep a seed and change the rule. Press ROW: all sixty-four return and only row 3 is amber, eight candidates. Press COLUMN for eight the other way. Keep the same seed for ROW and COLUMN and watch the first few removals in each. Both lists start with eight candidates and shrink by one on each removal. The generator therefore receives the same changing bounds, and selects the same positions within the two lists. The addresses at those positions differ: one list follows row 3; the other follows column 3. Press ALL and every cube is admitted, sixty-four candidates. That change also changes the draw's bounds; retaining a seed alone no longer means retaining the same list positions. Equal counts can leave a spatial difference undescribed: a rule can offer the same number of choices while making different places available, and the seed cannot tell.

Stop before the set is empty. Keep this interrupted pattern for a moment. Perhaps the openings make an arrangement you want. Nothing requires another press. The final empty range would erase the distinction between the orders you have been comparing; halfway through, their different choices can still be seen. A slot remembers where a cube is absent. The visible last-removal line remembers one event. The full history remains in `removal_log`, available in the source and the review, beyond what this plate shows.

<!-- @random_removal_arena -->

Behind the board, the set becomes a floor. Ninety-nine cubes span a basin inside a glass frame. Pause on the dark edge before entering. That edge is permanent. The amber cells are not.

Entry asks for one removal. As you walk, each further sixty centimetres of accumulated horizontal movement can ask for another; a pending draw must finish first. One cell turns red for eight-tenths of a second. Then its mesh disappears and its collider is disabled. The gap is now something your body can fall through. Fire burns at the base of the basin.

The board hid a drawing while leaving its little slot plate. This version connects the same selection to support:

```gdscript
func _removed(index: int) -> void:
    colliders[index].set_deferred("disabled", true)
```

The draw chooses from the floor's remaining cells, not from the cube nearest your foot. Walking makes a choice happen; it does not tell the choice where to land. Try the permanent apron and look back. A disappearance becomes a fall only because the code also withdraws support.

REPLAY restores the cells and their colliders, and starts the same seeded order again. NEW SEED restores them with another order. Both controls stand together outside the entrance. Keep the distinction between the small board and the floor: here removal has acquired a consequence because another piece of code joined it to collision.

<!-- @ -->

Ask now whether a random choice can be fair to a cube that was grey. Within the amber set the draw is even; the grey were decided before it ran, by a rule you can read and change, and the seed that makes a run repeatable has no say in it. In the next room, the available choice narrows to two diagonal marks. Follow what their neighbours make of them: when does a choice become a contour, and when can that contour become a passage?
