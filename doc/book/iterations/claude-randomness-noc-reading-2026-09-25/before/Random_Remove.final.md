# The set before the choice

In the last room, sorting changed the neighbours while the count stayed. Here, find a cube the process cannot choose.

A board of sixty-four small cubes stands on a pedestal a few steps inside the entrance, on the hall's centre line, numbered along two edges. Its controls sit together on the console in front; a cased account of the set stands to the left. Sixteen of the cubes are amber; the other forty-eight are grey.

<!-- @remove_random -->

Before pressing anything, count the amber ones. Four rows by four columns, from column 2 to column 5 and row 2 to row 5: sixteen possible first choices. The grey cubes are present, numbered, and out of the question. The plate beside the board says so in its own words: RANGE, columns 2–5, rows 2–5, a seed, and `Eligible: 16   Remaining: 16   Removed: 0`.

Press REMOVE ONE. One amber cube turns red for a moment and is gone; its slot plate stays, so the address survives the cube. The line names it: last removed, column such, row such. Remaining: fifteen. While a cube is still red, the same line says *Choosing* instead, with the address already filled in: the draw is made before the deletion. Press again. Does the new gap touch the first? Either answer is possible. Watch the amber set rather than expecting the gaps to spread like a stain.

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

The coordinates are the board's, not the hall's: column 3 is the cube at x = 3 on this eight-by-eight, wherever the pedestal stands. The rule runs over every cube once, when a run begins, and keeps the ones it admits. The loop carries a guard for a cube already removed, but on this bench it never fires: every run empties `_removed` before the question is put, so all sixty-four are asked, each at its original place:

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

the cube's own transform scaled to nothing, the board underneath untouched. In the same step its entry leaves the list, `active_instances.remove_at(offset)`; the rule is not asked again before the next run, and until then the list only shrinks. Look into the gap. Its small slot plate is still there. The cube also keeps an address inside the MultiMesh, and the remover has kept its original transform in `_original`. The model can stop drawing this body without forgetting how to put it back. At this board, the surface your feet stand on belongs to the museum; these small disappearances make no holes in it. Filter, draw, delete: three decisions that are easy to fold into one word, *random*, and only the middle one is.

Press RESET. All sixty-four cubes return, sixteen amber again, and the line shows the same seed. Empty the square a second time and watch the order: it is the first order, cube for cube, because RESET on this bench puts the generator back to the seed it names:

```gdscript
	if replay_on_reset:
		_rng.seed = run_seed
```

Watch the first few removals twice. After RESET, waiting before your next press does not advance the removal generator. The room goes on around the board; the next choice waits for the button. The same run can be taken slowly or quickly, although a press made during the red highlight is ignored while that removal is busy.

Press NEW SEED and try again. The button selects a five-digit seed and restores the set. It may select one you have already used, and a different seed does not guarantee a different removal order. Compare the histories you get rather than requiring difference as proof of randomness.

Then keep a seed and change the rule. Press ROW: all sixty-four return and only row 3 is amber, eight candidates. Press COLUMN for eight the other way. Keep the same seed for ROW and COLUMN and watch the first few removals in each. Both lists start with eight candidates and shrink by one on each removal. The generator therefore receives the same changing bounds, and selects the same positions within the two lists. The addresses at those positions differ, except once: one list follows row 3 and the other follows column 3, so on any press where ROW's line says column 5, row 3, COLUMN's says column 3, row 5. In a run taken to the end, both lines name column 3, row 3 exactly once, on the same press: the one cube both rules admit. Press ALL and every cube is admitted, sixty-four candidates. That change also changes the draw's bounds; retaining a seed alone no longer means retaining the same list positions. Equal counts can leave a spatial difference undescribed: a rule can offer the same number of choices while making different places available, and the seed cannot tell.

Stop before the set is empty. Keep this interrupted pattern for a moment. Perhaps the openings make an arrangement you want. Nothing requires another press. The final empty range would erase the distinction between the orders you have been comparing; halfway through, their different choices can still be seen. A slot remembers where a cube is absent. The visible last-removal line remembers one event. The program keeps this run's full order in `removal_log`, readable through `get_state` but not on this plate, until RESET, NEW SEED or a mode button clears it. The comparison between your runs is kept only by you.

<!-- @sampling_hoppers -->

Beside the board, two glass cases hold the same eight numbered blocks. Each has a handle. Pull the one on the left. A block comes forward, leaves a small copy in the row below, and travels back into its place. Pull the one on the right. Its block stays out. Behind it, the numbered slot is empty.

Try to get the same number again. On the left you can wait for it; nothing promises how long. On the right, the number you have just drawn is no longer available. An absence has become part of the next choice.

The left-hand case returns its member before allowing another draw. All eight remain eligible. The right-hand case loses a candidate each time: eight, seven, six. Stop with one block left. Can you name the next result before pulling? Seven earlier choices have left only one answer. Which number survives to that moment still depends on their order.

Here code chooses the member. The movement lets you follow what happens to it afterward. Both machines begin with the same seed, so their first choices match. Then their available sets part company. The left-hand row can contain repetitions; the right-hand row can fill with every number once. The left keeps only its latest twelve draws, though its count continues. The right stops after eight.

REPLAY BOTH restores the blocks and begins the two orders again. Watch the returning block rejoin its neighbours. Giving it back is an instruction too. What looked like another chance depended on making it available again.

<!-- @random_removal_arena -->

Behind the board, the set becomes a floor. Ninety-nine cubes span a basin inside a glass frame. Pause on the dark edge before entering. That edge is permanent. The amber cells are not.

Entry asks for one removal. As you walk, each further sixty centimetres of accumulated horizontal movement can ask for another; a pending draw must finish first. One cell turns red for eight-tenths of a second. Then its mesh disappears and its collider is disabled. The gap is now something your body can fall through. Fire burns at the base of the basin.

The board hid a drawing while leaving its little slot plate. This version connects the same selection to support:

```gdscript
func _removed(index: int) -> void:
    colliders[index].set_deferred("disabled", true)
```

The draw chooses from the floor's remaining cells, not from the cube nearest your foot. Walking makes a choice happen; it does not tell the choice where to land. Try the permanent apron and look back. A disappearance becomes a fall only because the code also withdraws support.

REPLAY restores the cells and their colliders, and starts the same seeded order again. NEW SEED restores them with another order. Before either is pressed, the order was not drawn for you: the floor is given the same seed each time the hall is built, so every visitor, walking any path, meets the same cells going in the same sequence. Unlike the board, the floor names no seed, so after NEW SEED you cannot say which order you are in. Both controls stand together outside the frame's entrance. Keep the distinction between the small board and the floor: here removal has acquired a consequence because another piece of code joined it to collision.

<!-- @ -->

Ask now whether a random choice can be fair to a cube that was grey. Within the amber set the draw is even; the grey were decided before it ran, by a rule you can read and change, and the seed that makes a run repeatable has no say in it. In the next room, the available choice narrows to two diagonal marks. Follow what their neighbours make of them: when does a choice become a contour, and when can that contour become a passage?
