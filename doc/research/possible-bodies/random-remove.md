# The set before the choice

[Random Entropy](random-entropy.html) → **Random Remove** → [Random Walk](random-walk.html)

[The primary and its book passage](/necklace/thread?map=Random_Remove&role=primary) · [Waves, randomness and noise plan](/research/waves-chance-noise/index.html#Random_Remove)

Find a cube the machine cannot choose. Keep looking at it while another turns red and disappears. After several presses, this one is still standing. What has kept it there?

![The current removal bench after one desktop pointer press: the grid stays visible between the cased status at left and controls at right](random-remove-desk.png)

The existing `remove_random` bench remains the room's one primary. Its right-hand controls and left-hand status plate are Claude's accepted staging. This continuation preserves the production scripts and geometry, checks the encounter independently, and lets its distinctions carry the book text.

## A choice that cannot reach every cube

RANGE admits sixteen cubes: columns 2–5 and rows 2–5. The other forty-eight are grey. REMOVE ONE chooses only among the remaining amber candidates. A grey cube has no small chance waiting to happen in this run; it has no place in the candidate list.

![One removed cube in the captured seed-29640 range run; its slot plate remains](random-remove-one.png)

Keep going and the result becomes certain in one respect. Every admitted cube will eventually go. Sixteen completed presses empty the same square, whatever their order.

![The same camera and seed after all sixteen candidates have been removed: the final empty range was decided by the filter](random-remove-empty.png)

What differs between histories is still visible partway through. Stop there for a moment. A gap may join another, or leave a cube isolated, or make a broken rhythm you want to keep. The machine waits for the next press; it has no judgement about whether this is the place to stop.

## Eight choices, different places

Compare ROW and COLUMN below. Both start with eight candidates. At seed 777 they select the same list offsets—7, 0, 4, 2, 1, 1, 0, 0 as the lists shrink—yet those positions address different cubes. **The number of possibilities agrees while their places differ.**

This playback uses complete histories exported from the real Godot bench. It makes no fresh random draws. The flat board uses local columns left to right and rows top to bottom; it is a reading view of the model, not the museum camera. “Show removal order” exposes a record available to code and this review; the in-game plate shows only the last removal.

[Step through the captured histories](random-remove.html) in the interactive review.

The other comparisons let you replay a range or inspect two captured seeds over it. At the end, both range histories leave the same shape. Halfway through, the missing addresses can differ. RESET returns this playback to its first step, just as the bench restores its current set.

## Filter, draw, remove

The filter asks a question about each cube's original grid coordinates. ROW and COLUMN are explicit tests:

```gdscript
"Column": return is_equal_approx(pos.x, float(target_column))
"Row": return is_equal_approx(pos.z, float(target_row))
```

Already removed instances are skipped. The surviving eligible indices form a list. Only then does the private generator choose:

```gdscript
var offset := _rng.randi_range(0, active_instances.size() - 1)
var index := active_instances[offset]
```

ROW and COLUMN use equal draw bounds because both start at eight and lose one candidate per step. RANGE and ALL change those bounds as well as the available places. Keeping the seed alone is insufficient to claim equal offsets across differently sized sets.

The last operation changes how the selected instance is drawn:

```gdscript
transform.basis = Basis().scaled(Vector3.ZERO)
multimesh.set_instance_transform(index, transform)
```

The cube's instance slot remains. The remover retains its original transform; the permanent plate retains its visible address. RESET can restore this body because the implementation has kept the means of return. Your museum floor is unaffected by these small absences.

## What the reset remembers

![The cased status beside the tray names the current set, seed and counts; its lower line holds a legend or the last event](random-remove-status.png)

RESET restores all sixty-four transforms and seeds the removal generator with the current run seed. Waiting between completed removals does not consume its draws. A press during the red highlight is ignored; RESET or a mode change cancels the pending deletion so it cannot alter the new run after its delay.

NEW SEED selects a five-digit value and restores the set. It can select a previous value again; different seeds can also produce the same order. The seed is visible but there is no field for entering one. The complete procedure includes the generator, list order, eligibility rule and draw bounds as well as that number.

An excluded cube is protected from deletion here. Exclusion from a draw that offered an opportunity would have another consequence. Before treating inclusion as good or the draw as fair, ask what being chosen does. The bench makes each part available for inspection without deciding the value of every possible application.

## What is ready, and what remains

**87 independent desktop checks passed, zero assertion failures, engine exit 0.** These include the seven button signal paths, actual desktop pointer REMOVE ONE and RESET, all four masks, replay, full ROW/COLUMN/ALL histories, a pending reset or mode change, rapid repeated presses, access, the unchanged surrounding object count and unloading/rebuilding. Six full histories contain 128 removal entries; every order is a permutation of its eligible set, and the replay repeats exactly. Eleven production excerpts were checked across final and tutorial.

The front view keeps the grid and two side stations visible. The existing oblique close view partly overlaps RANGE with the tray edge, so tracked-hand approach and reach still require a later visit. The dark sphere constrains one neighbouring lane; the tested routes around the bench remain open. No headset assessment is claimed.

Three map placements remain declared. The remover and dark sphere build; the secondary `hazards_demo` has no living scene. Book and registry notes that described hunting the host map's grid are corrected. Historical capture parameters and bounds are retained with a note that their harness needs separate review.

This run has no script errors or shutdown leak warning. It does record an unrecognized audio-bus UID, root-certificate and logger errors, renderer/environment warnings, and generated decorations taking 127–298 ms to build. These diagnostics remain separate from the passing encounter checks.

[Desktop report](random-remove-check.json) · [Run receipt](random-remove-run.json) · [Captured histories](random-remove-histories.json) · [Tutorial](random-remove-tutorial.md) · [Technical notes](random-remove-technical.md) · [Critical text](random-remove-critical.md)

**Next: [Random Walk](random-walk.html).** A choice will move a body. What can it reach when each step begins from the place the previous draw left it?

## Book passage

# The set before the choice

In the last room, sorting changed the neighbours while the count stayed. Here, find a cube the process cannot choose.

A board of sixty-four small cubes stands on a pedestal in the middle of the hall, numbered along two edges. Its controls stand to the right; a cased account of the set stands to the left, both turned toward the visitor. Sixteen of the cubes are amber; the other forty-eight are grey.

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

the cube's own transform scaled to nothing, the board underneath untouched. Look into the gap. Its small slot plate is still there. The cube also keeps an address inside the MultiMesh, and the remover has kept its original transform in `_original`. The model can stop drawing this body without forgetting how to put it back. The surface your feet stand on belongs to the museum; these disappearances make no holes in it. Filter, draw, delete: three decisions that are easy to fold into one word, *random*, and only the middle one is.

Press RESET. All sixty-four cubes return, sixteen amber again, and the line shows the same seed. Empty the square a second time and watch the order: it is the first order, cube for cube, because RESET on this bench puts the generator back to the seed it names:

```gdscript
	if replay_on_reset:
		_rng.seed = run_seed
```

Watch the first few removals twice. After RESET, waiting before your next press does not advance the removal generator. The room goes on around the board; the next choice waits for the button. The same run can be taken slowly or quickly, although a press made during the red highlight is ignored while that removal is busy.

Press NEW SEED and try again. The button selects a five-digit seed and restores the set. It may select one you have already used, and a different seed does not guarantee a different removal order. Compare the histories you get rather than requiring difference as proof of randomness.

Then keep a seed and change the rule. Press ROW: all sixty-four return and only row 3 is amber, eight candidates. Press COLUMN for eight the other way. Keep the same seed for ROW and COLUMN and watch the first few removals in each. Both lists start with eight candidates and shrink by one on each removal. The generator therefore receives the same changing bounds, and selects the same positions within the two lists. The addresses at those positions differ: one list follows row 3; the other follows column 3. Press ALL and every cube is admitted, sixty-four candidates. That change also changes the draw's bounds; retaining a seed alone no longer means retaining the same list positions. Equal counts can leave a spatial difference undescribed: a rule can offer the same number of choices while making different places available, and the seed cannot tell.

Stop before the set is empty. Keep this interrupted pattern for a moment. Perhaps the openings make an arrangement you want. Nothing requires another press. The final empty range would erase the distinction between the orders you have been comparing; halfway through, their different choices can still be seen. A slot remembers where a cube is absent. The visible last-removal line remembers one event. The full history remains in `removal_log`, available in the source and the review, beyond what this plate shows.

<!-- @ -->

Ask now whether a random choice can be fair to a cube that was grey. Within the amber set the draw is even; the grey were decided before it ran, by a rule you can read and change, and the seed that makes a run repeatable has no say in it. Carry the changing set into the next room, where a walker takes its steps from draws like these and the set of places it can reach is decided one step at a time.
