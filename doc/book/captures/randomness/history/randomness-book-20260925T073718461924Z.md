# randomness: the chapters

## Random Definition

*Random_Definition*

# A pattern that returns

In Synthesis Lab, five amounts could bring a familiar curve back. Here, choose a patch of colour you would not have thought to put together.


Two large grids stand side by side above the controls. Find your patch in one of them, then look in the same place in the other. Press REPLAY and return to those cells before surveying the whole picture.

The patch is back. Press RANDOM, choose something in the arrangement it gives you, and replay that one. RANDOM is allowed to choose a seed again, including the one already here. A result can surprise us and still know the way back to itself.

The seed readout offers a tempting name for the picture. Remember it. Then press +1 DRAW.

The right-hand grid changes while the left keeps its arrangement. The seed has not changed. Look at the cube positions too: nothing has moved sideways to make this difference. One value was requested before the colouring began and was given no colour at all.

Above the grids, two strips show the first twenty-four draws as bar heights. Before the extra draw, their contours match. Switch it on: the right strip begins at draw two. Find its first bar in the second position on the left. The colours changed because the same stream was grouped differently, three numbers per cell. The strips expose a repeatable sequence, not a claim that these few numbers reveal a period or hidden geometric order.

This is the extra operation, applied to the last grid:

```gdscript
if _extra_on and i == _columns.size() - 1:
	for k in range(extra_draws):
		_rng.randf()
```

The underlying sequence has not been rearranged. The generator has moved one position farther into it before the first cube asks for red.

A call to `_rng.randf()` requests one number between zero and one. Colour takes three calls:

```gdscript
mat.albedo_color = Color(
	_rng.randf(),
	_rng.randf(),
	_rng.randf()
)
```

Red, green, blue. Then red, green, blue again. Sixty-four cubes use 192 draws. With one value discarded at the start, what would have supplied green now supplies red, blue becomes green, and the next cube's red enters this cube's blue. Nothing in a draw says that it is red. Red is the use made of its place in these three calls. The old boundaries between colours were made by counting in threes. Shift where that counting begins and the same stream dresses the grid differently.

Press +1 DRAW again to switch the extra draw off. The match returns. This button toggles one discarded draw; repeated presses do not keep adding more. REPLAY reconstructs each grid by restoring the generator to its seed and repeating the chosen procedure. We needed more than the seed's number: which generator, which calls, and which use of their results. The picture's name had left out part of its making.

Use RANDOM again and wait before replaying. The room continues around you; waiting does not advance the generator that colours these grids. Try to predict one cell from its neighbour. Then use REPLAY to recover it. Difficulty guessing from the picture and the ability to repeat its construction are different things you can encounter here. Neither observation makes the other disappear.

There is no need to prefer the matched pair. Keep the extra draw on and compare the two colourings as possible companions. Perhaps the misplaced beginning gives you a relation you want. The line that interrupts a demonstration of sameness can also be used to make another palette.

Move the seed slider slowly. Your hand travels between positions while the readout counts whole numbers, from 0 to 999. The handle can move a little without choosing another seed. The controls offer many seeds, yet every result still arrives as sixty-four cubes with three varying colour channels. Another seed cannot add a cube or let one leave its cell. Those would be other changes to the program. Here, randomness varies what the program has made variable.

The three textile panels offer another comparison. Each begins with seed 41. Diagonals, upright and horizontal marks, then blocks: three pairs of signs receive the same draws. Choose a cell and follow its colour across the panels. NEXT SEED changes the draws in all three; RESET returns to 41. These bolts are held still so their marks can be compared. Chance has not chosen what a mark means. The program supplied that vocabulary before drawing.


The crank across the room makes a generator advance by hand, one state at a time. It gives each request a gesture. We could follow every request here too, but the picture has already asked for 192 of them. What can we leave unexamined and still recognise how it was made?

The next room gathers a sequence into a histogram and an entropy reading. Carry one small patch with you. We are about to ask what a number can retain of an arrangement that was worth looking at.

---

## Random Entropy

*Random_Entropy*

# What the gauge forgets

In the last room, one discarded draw changed which values became neighbours. Here, choose a pair of neighbouring colours before touching a button.

A gauge hangs on a post in the middle of the hall, its number glowing over a desk. On the desk, two hundred small coloured tiles stand in a row, and a pale bar lies before the first forty of them.


Look at the tiles and the ten bars before the large number. Each tile is one draw, in the order it was drawn, coloured by its symbol; the strip along the panel's foot spells out the first forty, the ones behind the bar. Find a colour that comes often in the row and one that comes seldom, and compare their bars. The bars collect every occurrence wherever it fell; the row keeps where each one fell. Choose two neighbouring tiles and ask whether their closeness tells you anything about the height of their bars. Then find another tile of the same colour further along.

The first forty also appear enlarged across the desk's front, labelled “as drawn.” Keep one pair in that row in view.

Now press SORT, on the desk's front. Watch the row and the bars together. The tiles glide into ten blocks, one per symbol; the bars hold their places. Look up at the number. It has stayed too. The pale bar before the first forty disappears: those particular draws no longer occupy the beginning of the sorted row. The plate on the desk's front prints the sorted copy's H beside the reading, the word *equal*, and how many of the two hundred tiles changed place. The enlarged excerpt stays as drawn while the two hundred tiles regroup above it. One part of the desk keeps the old neighbours available beside the new ones. Press SORT again and the upper row comes back as it was drawn.

What the gauge counts is this:

```gdscript
	for s in sequence:
		counts[s] += 1
```

one tally per symbol, and nothing about where in the sequence the symbol stood. The number is made from the tallies alone:

```gdscript
	for c in counts:
		if c > 0:
			var p: float = float(c) / float(sequence_length)
			entropy -= p * (log(p) / log(2.0))
```

Each symbol's share of the two hundred, times the logarithm of that share, summed and negated. A symbol that never occurred is skipped rather than given a zero times an infinity, and the largest the sum can be is log₂ of the alphabet:

```gdscript
	var max_h: float = log(num_symbols) / log(2.0)
```

About 3.32 bits per symbol for ten equally frequent symbols, the ceiling marked at the end of the bar. The reading sits just under it, because this sample from an even source did not divide evenly; the bars record this particular sample rather than the ideal distribution as if it had already happened.

Sorting changed the row without changing any tally. The same counts entered the same loop. Yet the row looks like another object. Keep it sorted for a moment: finding every occurrence of a colour has become easier. Return to the order drawn and a colour has its former neighbours again. Which arrangement would you want to work with? The gauge cannot choose between these uses for you.

Press CONTRAST. A second sample takes the wall: the same ten symbols, the same two hundred draws, from a source that makes the first symbol about twice as likely as the second, the second twice as likely as the third, and so on. The probabilities are normalised across ten symbols; they do not promise fixed counts. In this sample the first symbol occurs 109 times. Its bar towers, and the number falls to about 1.82 bits. Nothing in the alphabet or the count changed; the shares did. The plate names the source and its seed, so you can tell the two samples apart by their provenance and not only by their look. Look closely at the smallest bars and compare them with the counts on the desk. Four symbols did not occur in this sample. They still have tiny marks. The display gives every bar at least two millimetres:

```gdscript
height = max(0.002, height)
```

A visible mark can stand for zero. The tallest bar also reaches the same height in both samples: the display divides by that sample's largest count. Read the counts to compare how many occurrences there were. The ruler has changed with the thing it measures.

Press CONTRAST again and the first sample returns, draw for draw.

The first sample comes from a seeded local generator, giving each symbol the same chance on each call:

```gdscript
		sequence.append(_rng.randi_range(0, num_symbols - 1))
```

The seed lets the gauge recover this sample when it rebuilds. The contrast uses a second seed and a weighted draw; it too can be recovered.

Press DISCLOSE and the formula appears under the title; press it again and the source is named on the panel with a pale bar behind each live one showing the count that source expects on average: one flat line for the even source, a descending staircase for the concentrated one, and the plate prints those expected counts beside its name. Keep pressing and the upper panel withholds its bars and strip, then brings them back. The reading stays. Look down: the desk still carries the tiles and its own account of the counts. Information absent from one display can remain within reach on another. How much would you know if you approached only the glowing number?

Now ask what the unchanged number failed to notice. It did not notice the order, which the sorted view rearranged. It cannot notice a pattern between neighbours, a repeated pair, a rhythm, a message, because it never looked at two tiles at once. It does not know whether the row was worth reading. A high reading is not a certificate of meaninglessness and a low one is not a certificate of value; here it averages surprise using the shares counted in this sample, without consulting the neighbours of a draw.


Beyond the ledger, enter the square glass enclosure. Start at the blue end. The points sit in rows; toward the other end their positions stray further from those rows. Walk sideways as well as forward. The same field can look lined up from one direction and tangled from another.

Here the random offset grows with a point's position along z. The plan stays square; the rule still has a direction. This is a field of displaced points, not a spatial picture of the ledger's number. The meter counted symbol shares. This work moves bodies away from lattice addresses. Putting them in one hall gives us something to compare, and a reason to resist calling every visible irregularity the same entropy.


Beyond the glass, four pale columns carry a lintel. A brick wall fills the space behind them. Choose a joint and wait. A piece drops out of the construction and comes to rest below. A capital loses its place; a shaft becomes a stump. The fallen stone is still here.

Press RUN / PAUSE to hold the scene, or ONE STONE to place the next selected piece among the rubble. The counter keeps two accounts: 116 stones, and how many have moved. The first number stays. Does the building stay with it? Look through the gaps and move around the surviving columns. What was a boundary now lets you see across it.

The program chooses among the exposed tops of the wall and columns. The bottom two courses remain. RESTORE puts the pieces back, resets the seed and waits for you to start it again. The same dismantling order can return; it was never centuries of weather compressed into a minute. The fall and the landing places were arranged too.

Turn toward the museum wall beside the columns. This time the pale courses belong to the hall itself. Its small console offers the same three actions. Let the top stones come down. Through the thinning edge, the view continues beyond the room. The floor stays beneath your feet; a low course keeps the edge. The structure that contained the demonstration has become another arrangement under the rule.

RESTORE closes those openings with the same stones and their collision. A wall is more than an image here: its written arrangement decides where a body can go. What else did we accept as background because it had not yet moved?

The ledger at the entrance counted symbols without keeping their neighbours. These stones make that omission bodily: the same inventory can hold different views, gaps and forms. Nothing has calculated the thermodynamic entropy of this ruin. Before calling its broken outline a higher number, we would have to say what we are measuring. What does a count of stones tell us about what they can still hold?


The last room asked how an arrangement could return. This room asks what survives when we describe one. The histogram retains the counts; the entropy reading condenses those counts further. From that number alone you cannot recover even the bars, let alone the neighbours you chose. In the next room the eligible set becomes spatial: before anything is removed at random, a rule has already decided what can be chosen.

---

## Random Remove

*Random_Remove*

# The set before the choice

In the last room, sorting changed the neighbours while the count stayed. Here, find a cube the process cannot choose.

A board of sixty-four small cubes stands on a pedestal in the middle of the hall, numbered along two edges. Its controls sit together on the console in front; a cased account of the set stands to the left. Sixteen of the cubes are amber; the other forty-eight are grey.


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


Behind the board, the set becomes a floor. Ninety-nine cubes span a basin inside a glass frame. Pause on the dark edge before entering. That edge is permanent. The amber cells are not.

Entry asks for one removal. As you walk, each further sixty centimetres of accumulated horizontal movement can ask for another; a pending draw must finish first. One cell turns red for eight-tenths of a second. Then its mesh disappears and its collider is disabled. The gap is now something your body can fall through. Fire burns at the base of the basin.

The board hid a drawing while leaving its little slot plate. This version connects the same selection to support:

```gdscript
func _removed(index: int) -> void:
    colliders[index].set_deferred("disabled", true)
```

The draw chooses from the floor's remaining cells, not from the cube nearest your foot. Walking makes a choice happen; it does not tell the choice where to land. Try the permanent apron and look back. A disappearance becomes a fall only because the code also withdraws support.

REPLAY restores the cells and their colliders, and starts the same seeded order again. NEW SEED restores them with another order. Both controls stand together outside the entrance. Keep the distinction between the small board and the floor: here removal has acquired a consequence because another piece of code joined it to collision.


Ask now whether a random choice can be fair to a cube that was grey. Within the amber set the draw is even; the grey were decided before it ran, by a rule you can read and change, and the seed that makes a run repeatable has no say in it. Carry the changing set into the next room, where a walker takes its steps from draws like these and the set of places it can reach is decided one step at a time.

---

## Randomness 10 PRINT Algorithm

*Randomness_10_PRINT_Algorithm*

# A maze made of marks

When do independent marks begin to look like a maze?


Choose a small group of cells and identify the two diagonal orientations. Follow one contour across several corners. Before calling it a route, ask what you have actually followed: a continuous-looking mark, the edge of a barrier, or an open passage between barriers?

Watch a diagonal change and compare the connections around it. One local replacement can alter a much longer-looking contour. The field can reorganise without a designer redrawing every enclosure by hand.

Stay with one corner shared by neighbouring cells. Notice which diagonal endpoints reach it and which turn your attention elsewhere. When a nearby mark changes, first describe the immediate difference at that corner, then follow its consequences farther along the contour. You may discover that a path you were reading has become two separate pieces, or that separate pieces now appear joined. Compare that reading with the open space around the marks. A connection between drawn segments and a connection between passages are different observations. Keeping one corner as your reference makes the larger rearrangement traceable instead of treating the whole field as a new unexplained maze.

The generating rule makes one of two choices for each cell. Neighbouring marks meet because the grid places their endpoints in shared positions. A larger visual structure appears through those local adjacencies, even though the individual choices did not include an instruction to make that particular structure.

This version adds an ant and navigation calculations to the marks. Those are separate procedures. A pattern that looks like a maze does not by itself guarantee an open route from its entrance to its exit, and a changing field can invalidate a route that previously seemed available.

Read the same arrangement once as a textile and once as a passage system. The first reading may care about rhythm, density and contour. The second makes additional demands about clearance, connection and destination. Neither reading changes the original two-choice rule, but they ask different things of its result.

There is no need to treat the larger structure as either secretly planned or entirely meaningless. A simple local procedure and a particular representation can produce relationships worth investigating. The useful question is which relationships are supplied by the rule and which promises your interpretation adds.


Next, the die offers six visible outcomes instead of two marks. You will compare individual results with a growing record, and ask what repeated observations can establish that one throw cannot.

---

## Random Cubes

*Random_Cubes*

# One throw and many throws

How much can one throw tell you about a die?


Take the die and throw it onto the table. Wait for it to settle, then compare the upward face with the result shown. Watch what the reward does, but do not let the most spectacular result stand in for the whole experiment.

Throw again. Look at the face counts and the running mean as well as the latest answer. A short sequence can contain repetitions or missing faces without settling the question of whether the die is fair. The record becomes useful because it keeps outcomes that your attention might otherwise replace with the newest one.

Before your next throw, choose one reported face to follow through several results. After each settlement, check whether its count changed, even when another outcome attracted your attention. Also compare the mean before and after a high or low result. An outcome above the current mean pulls it upwards; an outcome below pulls it downwards. Neither direction alone tells you whether the die became fairer. This small record separates a face's frequency from the numerical average of all faces. If you change your throwing method, mark that change in your own account so that a later pattern is not silently attributed to the die alone.

There are six possible reported faces. If each were equally likely, their mean value would be 3.5. That is a statement about a distribution, not a face you can roll and not a promise that every small batch averages exactly 3.5. The observed mean belongs to the throws made so far.

Here the result is read from the settled orientation of a simulated physical die. Its shape, contact with the table and the way you throw all contribute to what happens. A cube's symmetry is a reason to investigate fairness, not a proof that every practical way of throwing it produces equal probabilities.

Compare a gentle throw with a more vigorous one. Keep track of which method produced which outcomes; combining the records immediately would erase the intervention you are testing. A larger reward also tells you about the rule converting pips into falling balls. It does not make one outcome more earned than another.


The next room shifts attention from a single outcome to changes accumulating in an arrangement. Carry forward the habit of naming what is allowed to vary before calling the whole result random.

---

## Random Rotate Random XYZ

*Random_Rotate_Random_XYZ*

# What remains in a changing stack

Which part of an arrangement can change while its pieces remain?


Watch the two stacks long enough for their changes to begin. Choose one piece and compare its orientation with the line of its neighbours. Then look at its position and colour separately. Use TOGGLE to pause the process and inspect the difference; RESET restores the starting arrangement.

The changes do not happen uniformly across the whole display. Pieces acquire different amounts of drift, rotation and darkening. Yet their size stays fixed in this version. An arrangement can become less regular without every object shrinking, disappearing or becoming a different kind of object.

Pause while a chosen piece remains easy to recognise. Compare its edges with the original stack direction, then compare its centre with neighbouring centres. A piece can turn substantially while moving only a little, so one broad description of disorder can conceal different changes. Resume briefly and pause again, keeping the same piece in mind. Check its colour separately from those spatial comparisons. If it becomes difficult to identify, RESET gives you the ordered arrangement again. The renewed view restores a reference for comparison; it need not promise an identical sequence of later perturbations. Try explaining one changed relation before judging the whole stack's appearance.

The demonstration keeps a changing state for each instance. Random perturbations contribute to its movement, while bounds, damping and a gradually increasing decay value constrain what those perturbations can do. The result accumulates over time. A small angular change repeated many times can produce a visibly altered orientation even though no single step seems dramatic.

Pause and describe the result without using the word decay. Say which pieces moved, which turned and which changed appearance. This forces the general impression back into observable distinctions. The label names the model's presentation; it is not a measurement of thermodynamic entropy or a complete physical explanation of how a material deteriorates.

The two stacks also have different configured rates. Their difference therefore cannot be attributed only to their shapes or to the number of pieces. A controlled comparison would need to match those other conditions before isolating one cause.


A rotation-only version at matched rates would be a useful next experiment. The random-walk room takes one accumulated quantity, position, and gives it a clearer history. There you can separate the next-step rule from the trail the display keeps of earlier steps.

---

## Random Walk

*Random_Walk*

# The trail is already elsewhere

What does a trail remember that its next step does not use?


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

The wing beside the tank carries the logbook; its buttons now share the front console with the mode controls. ONE and ALL change which beads and trails are bright. All five continue stepping under either view. Following one has changed your access to the population, without sending the other four away.

Read the seed, then press RESET. The named walk returns from the centre. Compare it at the same step count, with the same mode. NEW SEED chooses a five-digit number different from the current one; an older number can return later. Changing modes retains the seed but spends its draws differently. A number alone is not the whole recipe for a path.

Two times sit together on the plate. Simulation time counts the accepted steps at thirty per second. The frame clock adds the time supplied to the running process since reset. A stalled frame can separate them: this implementation accepts at most five steps in one frame and discards the excess. In a controlled two-second frame, the clock gains two seconds while the walk gains only a sixth of a simulated second. There is no pause control on this cabinet. RESET starts its account over while the museum continues.

Below, MSD measures the five beads' average squared distance from their release point. Watch it increase or decrease. The glass bounds it; the number does not report how much trail has accumulated or how far the beads have travelled. A return toward the centre can lower it while adding more line.


Cross the bridge over the narrow basin and enter the larger glass frame. The gallery and the experiment remain at the same level; the gap distinguishes their floors. Its ten-metre field keeps another account of a walk: a visited cell rises. Four possible directions are enough to change the ground. The working lattice has thirty-two cells on each side, despite the older name `random_walk_128`.

Look at a high place. It records repeated visits; it was not selected as a destination. A small rule has become a spatial obstacle through what the surface retained. Compare this ground with the trails in the instrument. Both keep something of movement, and neither keeps everything. The surrounding glass names a boundary of the experiment; the openings let you pass through or watch from outside.


Stay with a shape you had begun to read as a creature. What would its next step need to know for that reading to become a capability? The missing relation is an invitation to make another rule. For now, we leave with a path whose history exceeds both its current position and the drawing we can still see. In Random Gaussian, we gather draws in another way and ask what shape appears when we count where they land.



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

---

## Random Gaussian

*Random_Gaussian*

# The shape we counted

What changes when the values stay where they are, but we count them differently?


Yellow beads fall toward a row of blue bars. Some bars grow; others wait. An orange line already knows the shape we have come to expect. Look at the beads and the bars before letting that line finish the picture for you.

The cabinet stands in the middle of the hall, its controls facing you as you approach. The other distribution studies stand around it. Its left panel offers UNIFORM, GAUSS, POISSON, EXPON and CLEAR. On the right are BATCH, PAUSE, NEW SEED and BINS. GAUSS is running when you arrive.

Press PAUSE. Watch what keeps moving. The beads already released continue to fall. The plate counts them as “in flight” until they land; only the issuing of new draws has stopped. Wait for that count to reach zero. The histogram is now still enough to describe. Where is its highest bar? Where are its gaps? Which of those observations had the word “Gaussian” encouraged you to expect?

CLEAR empties the display and restarts its named seed. While paused, it stays empty. Press BATCH. One hundred values are counted immediately, without the falling animation. Describe this particular arrangement. Press twice more, reading the total each time. A gap may close; another bar may stand further from the pale bar behind it. More evidence does not promise that every part of the picture will improve at the next press.

Those pale bars carry the model's expected counts at the current number of landed values. Blue and pale share a count scale. Their disagreement is available to examine; the pale shape does not instruct a blue bar to grow toward it.

Now press UNIFORM. The bins clear, the seed stays, and three batches again give three hundred values. Keep the same thirty bins. Each pale bar now expects ten. Compare the two arrangements at equal count before deciding which looks more irregular. UNIFORM has used each number directly:

```gdscript
		DistType.UNIFORM:
			return _rand()
```

GAUSS has given two numbers another job:

```gdscript
		DistType.GAUSSIAN:
			var u1 := maxf(_rand(), 0.0001)
			var u2 := _rand()
			var z := sqrt(-2.0 * log(u1)) * cos(TAU * u2)
			return _fit(gaussian_mean + z * gaussian_std)
```

There is the logarithm, the square root, the turning cosine again. The mean is 0.5; the standard deviation is 0.15. The code directly transforms draws into an approximation to a normal distribution. It does not wait for an arbitrary collection of values to become Gaussian. UNIFORM will keep its own law as more draws arrive.

Read the small guard on `u1`. Zero cannot enter the logarithm. Values below 0.0001 share that lower bound, limiting the computed reach to about 4.29 standard deviations. Even before a value reaches the screen, the numerical procedure has made a boundary. The ideal orange model and this finite computation are close enough to compare, and still worth distinguishing.

There is another boundary at the screen itself:

```gdscript
func _fit(raw: float) -> float:
	if raw < 0.0 or raw > 1.0:
		_clipped += 1
	return clampf(raw, 0.0, 1.0)
```

The previous room's glass reflected an overshoot. Here a value past one is kept at one; a value below zero is kept at zero. Its distance beyond the edge is lost from the retained value. Look at the plate's clipped count and its two edge-bin counts. They need not agree: an edge bin also contains values that were inside the display all along.

Try EXPON. More values gather near the left. Occasionally a draw from its long right tail is clamped at one. A finite run need not contain such a draw; the model's tail is a probability, not an appointment. NEW SEED lets another run take place. Its number differs from the current one, though an older number can return later.

Return to GAUSS or UNIFORM, pause, clear, and collect three batches. Now press BINS. Thirty become sixty, then ten, then thirty again. The landed count stays at three hundred. Nothing has been sampled again. The stored values are assigned to new intervals:

```gdscript
	for v in _values:
		_bins[clampi(int(v * num_bins), 0, num_bins - 1)] += 1
```

Watch the mean and the σ marked “binned.” They can change too. The plate estimates each value by the centre of its bin, so changing the intervals changes that estimate. The values have stayed; the account of them has moved. Return to thirty bins and the earlier account returns.

Look back at the height of the picture. Blue bars are scaled against the tallest blue bar, with a small visible baseline even for an empty bin. A handful of values can already occupy almost the whole height. The orange model shape has its own scale. Its curve cannot tell you how much evidence has arrived; the count can.

CLEAR and repeat the batches if you want to point at the same sample twice. That return depends on the seed and the procedure, including which law spends the random draws. It gives a discussion somewhere to stand while the surrounding museum continues.


We have met a centre, but have not discovered a command to belong to it. Frequent under a chosen model does not mean preferable, healthy or correct. Before carrying this shape onto a body, ask what was measured, what the bins kept, and what the edges absorbed. In Random Mushrooms, values like these become differences among forms. Which features of those bodies will be allowed to vary?

---

## Random Mushrooms

*Random_Mushrooms*

# Which differences were invited?

In the previous room the numbers gathered into bars. Here they have caps and stems. Which differences can this recipe make?


The glass enclosure around the bed makes a population into a place you can enter. Its front opening leaves room beside the specimen table; another opening is opposite. Begin at the compact console, then move among the mushrooms. The cage holds an experiment, not a claim that these bodies exhaust what a mushroom could be.

A bed fills the middle of the hall. Before it, six mushrooms stand on numbered discs. Look past the table and choose two in the bed that seem related. A cap bends out over a stem; another, smaller, repeats its proportions. Before pressing anything, decide what you are using to recognise their relation.

Press SHOW. A magenta ring moves to the next disc, and rings with tall pins mark its copies in the bed. Keep pressing until the plate names the template you were following. There may be many copies, or none in this particular population. The table still gives the absent form a place.

The discs run from 0 to 5: tan cap, red cap, flat brown cap, tall white mushroom, puffball, glowing cap. These are construction recipes rather than six biological species. Within this build, each recipe has become a template. A copy carries its template's details with it:

```gdscript
		var mushroom = mushroom_types[type_index].duplicate()
		mushroom.name = "Mushroom_" + str(i)
```

Look at two marked copies again. Their positions, turning and scale can differ. Their material situation can differ too: a cap lit by a neighbour need not look like the same cap in shadow. SHOW names a construction relationship; it cannot make every appearance identical.

Now press SIZE. The bed is rebuilt. Find your pair. Their places and orientations remain, but the extra scaling has gone. They have not all become the same physical size: a tall template remains tall beside a low one. The plate says “scale 1 · template sizes kept.” What did you think the button would remove?

For a scattered mushroom, the scale had been chosen here:

```gdscript
		var scale_factor = _size(0.7 + _rf() * 0.6)  # 0.7 to 1.3
		mushroom.scale = Vector3(scale_factor, scale_factor, scale_factor)
```

And the switch decides what to do with that value:

```gdscript
func _size(v: float) -> float:
	return v if size_variation else 1.0
```

The draw still happens when the scale rule is off. Only its use changes. If the program skipped the draw, the following decisions would receive different numbers and our comparison would slip away. Press SIZE again. The earlier scales return.

The seed on the plate makes this return possible under the same recipe. REGROW rebuilds the population and its ground. NEW SEED chooses a number different from the current one; it does not promise a number never used before. A new build can also change details inside a template, such as the puffball's bumps. Six available recipes do not mean six eternally identical objects.

Press KIND until the plate says “scattered.” Count what it calls accepted and rejected. Together they account for eighty candidate positions. The total mushroom count can be larger: two other routines add bodies later. First look at the spaces between the scattered ones. Which gaps seem intentional?

Continue to “rejected.” Grey markers appear at candidate positions that the placement rule refused. They were never mushrooms that died. At each proposed position, a noise field was consulted:

```gdscript
		var noise_val = noise.get_noise_2d(pos_x * 2, pos_z * 2)

		# Skip if noise value is too low (creates natural clearings)
		if noise_val < -0.3:
			_rejected.append(Vector3(pos_x, get_ground_height(pos_x, pos_z), pos_z))
			continue
```

Even the source calls them “natural clearings.” The marks let us read what that phrase stands for here. A number crossed a threshold. In Gaussian, a value beyond the display was kept at its boundary. Here an unsuccessful candidate leaves a recorded position and no body.

Keep pressing KIND until it says “rings.” Green marks pick out the members added by the circle routine. One circle is requested at this bed's six-metre size. Find its arc, then imagine the rest continuing beyond the boards. Its members were given equal angular intervals:

```gdscript
	for i in range(count):
		var angle = (2.0 * PI / count) * i
		var pos_x = center_x + cos(angle) * radius
		var pos_z = center_z + sin(angle) * radius
```

The radius helps set the requested count. Positions outside the bed are skipped. The plate's bracket counts the members actually placed; it does not show the missing ones. A partial circle can carry the trace of two decisions: draw the ring, then admit only what fits.

The next KIND is “clusters.” Two cluster routines choose their own centres, spreads and templates. Their members receive random angles and distances. They do not pass through the scattered candidates' noise test. Bodies from different routines can overlap. Nothing here negotiates for room.

Walk round the west and south margins. Three larger red-capped mushrooms stand just inside the boards. They come from a separate pickable scene and are counted separately. A similar cap has acquired another capability. In the headset, hold one and bring it close to your face: its eating rule starts a visual effect with a ten-second hold and a fade in and out and the mushroom dissolves. The garden has offered a way to change the looking, as well as the thing looked at. The desktop carry lets you inspect it, but holds it beyond that eating distance.

At the smaller arrival stage, wait for a silhouette. Another place is chosen from those still empty. Six arrivals fill it; the program does not keep producing bodies without somewhere to put them. Press REPLAY and watch the places return in the same order.

Choose one figure and press DRESS. A hem widens, a collar appears, the pleats take another colour. Try again. How far can this wardrobe take the figure?

Now press FORMS. Branches extend from the garment. Read the dress number: it has stayed. Switch FORMS back and the earlier dress returns. You did not need a luckier draw to find the branches. They needed another instruction. DRESS samples within the available recipe; FORMS switches between two recipes, one of which adds branches. Neither button changes the six places or the arrival order.[^Random_Mushrooms--chance-repertoire]

These figures still turn towards you as flat images. Their new outlines give them no new way to walk, touch or refuse. A different appearance has not yet become a different permission. Which of those changes would you make next?

Beyond the garden, three couture bodies stand together. All begin with the hare head and sheath garment. Their seeds are 41, 42 and 43. Look for differences in proportion, print and pose before pressing NEXT SEED. Three more individuals appear under the same two named constructions.

Keep this trio and press GARMENT. The seeds stay while the sheath gives way to a crinoline, then quilting, bloom and fringe. The body generator receives another construction instruction. Some details may change with the construction too: a seed is not a promise that every branch of a program spends its draws in the same way. RESET restores the starting trio. The garment's possibilities were authored; chance finds individuals within them. Which possibility would you want to add to this wardrobe?


The sampled sizes never grow a seventh template between two others. That would need another rule. Yet these rules could carry other forms, other ranges, other permissions. Which difference would you add first, and what would have to change to let it exist? Carry that question into the recovered gallery: what can the same act of drawing a value become when it meets a brush, a tally or a growing path? After that, Random Game asks your body to answer in time.

[^Random_Mushrooms--chance-repertoire]: The “Randomness” chapter of *10 PRINT CHR$(205.5+RND(1)); : GOTO 10*, pp. 125–127, discusses chance operations in Cage, Kelly and Morellet: variation takes place within constructed parameters and arrangements. The distinction between sampling a wardrobe and changing its repertoire is this hall’s experiment, rather than a claim that chance abolishes authorship.

---

## Random Space Geometry

*Random_Space_Geometry*

# What neighbours share

What makes neighbouring random heights belong together?


Look closely at neighbouring columns in the two small grids. On the WHITE NOISE side, compare one height with the next. On the PERLIN NOISE side, follow a group of heights across several cells. Describe the difference before calling either one a landscape.

Keep SEED fixed and adjust FREQUENCY. Watch how the scale of features changes on the coherent side. Then choose another seed or press RESAMPLE and repeat the comparison. The two kinds of field remain distinct even when their particular arrangements change.

Choose three adjacent columns on each side and describe their relative heights: rising, falling, or turning between the two. Move one position along and repeat. You are examining a local relationship rather than asking which grid contains the single tallest column. At a lower frequency, follow how far a broad feature extends on the coherent side; at a higher setting, repeat along the same row. If a small region happens to look similar on both sides, examine a longer stretch before declaring the procedures equivalent. Independent draws can produce a chance run of similar heights, while a coherent field can still contain differences between nearby samples.

Independent samples supply each white-noise height separately. Perlin noise supplies related values at nearby positions through a spatial construction. Those local relationships make broader features possible. The two grids use comparable height displays, but they do not draw from identical distributions merely because their values fit within similar bounds.

The seed makes each construction repeatable under the same settings. Frequency changes how rapidly the coherent field varies across the sampled positions. You are changing a rule about relationships in space, rather than choosing every column individually.

Look for something terrain-like in the independent grid, then for an unexpected edge in the coherent one. Perception is good at supplying landscapes. That skill can help you notice a structure, but it cannot establish that erosion, water or geological forces produced it. These are height fields with a colour mapping, not miniature geological histories.


One productive misuse is to withhold the landscape reading and describe only local differences. A future shared scale or alternative palette could make that comparison easier. The next room uses random samples for estimation: their placement will matter because a numerical answer depends on how the sampling rule covers a region.

---

## Randomness Examples of Randomness

*Randomness_Examples_of_Randomness*

# What chance may change

Four works have returned to the gallery. Walk toward the painting on the floor, then take either side around its frame. The dartboard waits to the right, the pipes farther along to the left, and a changing particle study near the rear. Each gives chance a different job.


Stand at the near edge of the canvas. Find a thin line, a broad mark and a cluster of small splatters. Wait for another layer, then follow the brush cursor as it traces a path. Walk around the frame. A mark that was distant is now close enough to inspect.

This is a Pollock-inspired generative homage, not a reconstruction of a particular painting. The program chooses positions, colours from a fixed palette, drip sizes and line widths. A line begins with a sampled direction, then turns by small sampled angles as it advances. At an edge, the direction reflects back toward the canvas. Chance can bend the route; it cannot enlarge the canvas or invent a colour outside the palette.

The marks are painted into a two-dimensional image shown on the floor. The small three-dimensional cursor follows the generated stroke path. It lets us watch a procedure; it is not a brush whose movement you are controlling, and the drops are not a simulation of falling paint.

Choose a passage you like. Which part could have arrived differently? Which part was already decided by the palette, line rule, canvas and interval between additions? Calling the result random can make those authored choices disappear from view. The work becomes more interesting when we keep them visible.


Move to the dartboard's console on the right. If new marks are appearing, press AUTO to pause them, then RESET. Press THROW and find the new point. Compare its location with the circle, then check which counter changed. Add a few more points individually before using AUTO to build a larger sample.

An inside point increases both the inside count and the total. An outside point increases only the total. Before requesting another point, predict what each possibility would do to the estimate. Check with THROW, and explain the change from the counters before looking at the distance from pi.

The circle is inscribed in a square. When points are sampled uniformly across that square, the fraction landing inside estimates the fraction of area occupied by the circle. Multiplying that fraction by four gives the displayed estimate of pi:

`estimate = 4 × inside / total`

A growing sample does not require every new estimate to improve. Repeat the prediction when many points are already present: one addition usually changes the ratio less. A steadier number still depends on how the points were sampled.

THROW requests a generated sample. You are not aiming a physical dart with your hand. A sampler that favoured the centre would tend to count too many points inside; adding more of those points would not repair the bias. Pause AUTO and RESET to compare another run. The board keeps at most 500 darts, so RESET also begins a new sample when the board has filled.

Here chance chooses the evidence. The circle's boundary and the counting rule remain fixed. Who gets to decide that the sampling procedure covers the space fairly enough for the answer we want?


Cross to the pipe study on the left. Follow a length to its next corner, then look for a place where the path doubles back near an earlier passage. If growth has finished by the time you arrive, the whole retained path is still available to inspect.

The pipe advances in one of six axis directions. A preference sometimes keeps it moving straight; otherwise the program shuffles possible turns and takes a direction that stays inside its bounds. It rejects an immediate reversal. It does not keep a list of occupied cells, so crossing an earlier route is allowed.

The default run stops after 180 segments. A dense tangle therefore does not certify that the volume has been filled, or that every corner was reached. The limit ends the run whether or not its shape looks complete to us.

Look across the empty spaces between pipes. The same local rules could have left different gaps. What would change if a previous visit made a place forbidden? That would add a memory and a new restriction, not merely turn up the amount of randomness.


The particle study occupies the last bay on the right. Stay through a full cycle. Its five chapters change about every ten seconds. Watch for a change in the particles' arrangement as well as their movement; the chapter transition restages them.

For this gallery, every chapter stays inside the same spherical boundary. A particle that would escape is brought back to the edge and its outward velocity reflected. This added limit keeps the changing study above the floor and within its bay.

In the first chapter, random forces change velocities that persist from one frame to the next. Damping slows them, and a boundary turns escaping particles back. Successive positions retain a history. They are not independent points redrawn across the whole volume.

The noise chapter follows a smooth field made from sine and cosine functions in this implementation. The pattern chapter adds spiral motion and oscillation to its opening arrangement. The emergence chapter combines separation, alignment and cohesion with small random nudges. The evolution chapter ranks particles by their distance from a moving target; the leading tenth influence the others.

These are five sketches of different procedures, not five strengths of the same white noise. Nor is the final chapter a population that breeds: the same fixed set of particles keeps moving under a selection rule. A title gives us a starting question; the update rule tells us what is actually happening.


Look back toward the painting. In one work, chance chose marks; in another, samples to count. It chose permitted directions for the pipe and different kinds of variation within the particle study. In every case something decided what a random choice was permitted to change.

Carry that question through the rear exit to Random Game. When a platform moves or a wait changes, distinguish the rule you can learn from the event you still have to discover.

---

## Random Pheromone

*Random_Pheromone*

# A path that recruits its next visit

What changes when a walker helps make the evidence its next decision will read?


Choose a small patch of terrain and follow more than one visit. Compare it with a quieter patch nearby. Watch where traces gather and where the surface begins to rise, then look for later walkers returning through those regions.

Keep one rising patch as a landmark and attend to the approaches made towards it. Does traffic return along a familiar direction, arrive from several directions, or shift towards a nearby patch? Compare a short interval with a longer observation before calling a route permanent. The visible height lets you retain a place in view even while the current signal changes. That makes it possible to ask whether present movement is still reinforcing an earlier concentration of visits. If the answer is difficult to see, say which evidence is missing: the current scent, the timing of deposits, or a clearer trace of individual movement.

Each visit leaves pheromone and changes the local height. Later choices can favour a stronger pheromone signal, while some movement remains random. A path can therefore become established partly because it has already been used. No walker needs a complete plan of the resulting network for this feedback to occur.

This differs from the terrarium's memoryless step rule. There, the trail helped the observer read the past without steering the next step. Here the environment keeps a signal that participates in future decisions. The mark has become part of the mechanism.

The signal and the raised terrain do not keep identical histories. Pheromone decays; the surface records accumulated visits in another form. A visually prominent ridge and the strongest current scent therefore need not mean exactly the same thing. Distinguish what you can see from what the movement rule reads.

Try identifying a route that may have begun as an accident. Repeated use can reinforce it, but reinforcement does not establish that it is globally shortest, fairest or best. The procedure rewards a particular local signal, and that signal partly reflects its own earlier choices.


A walker that avoided the strongest trace would make a different world from the same act of leaving marks. That comparison is an available direction for development rather than a control offered here. Next, the noise mixer returns to field construction: several contributions at different scales will combine without depending on a history of visits.

---

## Random Space

*Random_Space*

# Layers that look like land

How much of a landscape can be made by repeating a rule at different scales?


Reduce OCT to one and look at the broad changes across the picture. Add layers while keeping LAC and PER fixed. Follow one large feature and see how finer variations appear around it rather than assuming each new layer replaces the previous one.

Next adjust PER. Compare how strongly the smaller-scale contributions stand out. LAC changes the frequency ratio between successive layers; PER changes their relative amplitudes. SEED selects another set of offsets, providing a different arrangement under the same kind of construction.

Begin with OCT at one and inspect a broad light region beside a broad dark region. Increase the layer count while tracking their boundary. Then reduce PER and ask which finer variations become less prominent. Return to one layer before changing LAC: with no later layers to separate in frequency, that comparison gives you a baseline for what the spacing control concerns. Add layers again and watch its influence become available across them. Describe a change in feature size separately from a change in colour contrast. The picture remaps its range, so those two visual changes need not report the same numerical difference.

The field adds scaled versions of a base function. Each layer samples at another frequency and contributes another weighted value. In this display the base is made from several sine expressions, so the noise-like surface connects back to the synthesis lab's lesson: a complex appearance can come from adding simpler contributions.

Colour supplies another part of the reading. Low and high values are mapped through an earth-toned palette, encouraging you to see water, vegetation, rock or peaks. Those interpretations are useful associations, but the program has not thereby simulated water movement or the growth of plants.

Describe the picture once using landscape names and once using only high values, low values and spatial variation. Notice what the first description adds. The texture is also normalised to its own range, so a strong colour contrast need not indicate a large absolute numerical difference from another setting.


A neutral palette or fixed shared scale would expose another part of this construction and make a useful later comparison. The cycling platform in the next room puts uncertainty into timing instead of texture. You will know the order of its states while remaining uncertain about when it moves between them.

---

## Random Game

*Random_Game*

# Told, or finding out

In the mushroom bed, a draw helped decide which body appeared. In the gallery it became paint, an estimate and a path. Here it helps decide whether a body will still be there when yours arrives.


Three cyan stones cross a rectangular pit. Their tops stand a little above the museum floor. Beyond them, a prism carries a five-digit number. Watch the middle stone before stepping onto it. When it leaves, what would you be standing on?

The stone turns orange and sinks. The bed below remains. Then green, a rise, cyan again. Watch a second cycle. The order may already feel familiar while the pauses refuse to settle into a beat.

The stele at the lip names four states: IT STANDS, IT LEAVES, IT IS GONE, IT RETURNS. The procedure follows that order. A draw supplies the standing wait:

```gdscript
var visible_wait: float = _next_random_wait()
_note_step("stands", visible_wait)
await get_tree().create_timer(visible_wait).timeout
```

Inside the function, the interval becomes a number:

```gdscript
return _rng.randf_range(min_wait, max_wait)
```

For this crossing, the standing wait lies between 2.4 and 4.6 seconds; the hidden wait between 1.1 and 2.2. Sinking, rising and the short collider delays take additional time. Knowing those bands does not name the next draw.

Look at the tablet beside the pit. Each stone has a line: its present state, the last drawn wait and the time left of that wait. Now you can know something that watching cyan alone withheld. The current pause has already been chosen. The next one has not yet been drawn.

```gdscript
_step_wait = wait_seconds
_step_until_ms = Time.get_ticks_msec() + int(round(wait_seconds * 1000.0))
```

The counter reads the stored deadline. It does not keep asking for another duration. During LEAVES and RETURNS, the tablet retains the preceding draw at zero remaining time: it is an account of a wait, not a new measurement of movement.

Try the first stone when it stands. Its top is 22 centimetres above the hall floor, approached by a ramp and short landing; the spaces between stones are twelve centimetres. A stone can leave while you are on it. The pit has a bed 1.02 metres below the hall floor and a ramp up its west side. The corridor east of the pit also reaches the far lip. Crossing is one way to investigate this room; going around is another.

Watch the gold rings. They light during the final 1.2 seconds of a standing wait. Press CUE and try observing without them. Each stone still has a small beacon that lights during its movement. The tablet still shows its deadline. This experiment changes the notice carried by the stones; it does not remove every way to anticipate them.

Neither cue draws another wait. Yet the same next event becomes available to you differently: a ring before movement, a beacon during it, a number on a surface you must turn toward. Before describing a missed step as poor timing, ask where its warning was readable.

There is another separation under your feet:

```gdscript
_set_collision_enabled(false)
_set_state(CycleState.HIDDEN)
```

The collider remains enabled through the sink and its short delay. It is disabled while the stone is hidden, then enabled before the rise. Appearance, movement and support have separate instructions. A dim shape below you is not necessarily something the collision system will hold you on. The bed supplies the recovery surface.

REPLAY returns all three stones to their standing positions and restarts their seeded waits. Try it after a stone has begun moving. A repeated seed would mean little if an earlier motion kept pulling that stone down. Restarting must also cancel the old motion and restore support.

The prism names this local construction. NEW SEED chooses a different current number; an older number may eventually return. REPLAY does not rewind the other artifacts or the visitor. You bring knowledge from the previous attempt into a crossing whose first waits have been restored.


The next glass enclosure carries the removal rule under your feet. Here there are eighty-one cells. Entering selects one; walking farther asks for more. Red gives a short warning, then both the visible cell and its support disappear. The basin below burns. The dark apron remains a route around the changing set, and the console outside the entrance can restore it. This is a deliberate return to Random Remove: the rule you inspected there now participates in a crossing.


Beyond it, three doors face you. Stay at the console behind the amber line and choose one. A door lifts. It might remain a passage. It might announce fire, wait one second, then send a short jet toward the line. Watch before moving forward.

One door is assigned passage at the beginning of the round:

```gdscript
rng.seed = run_seed
safe_door = rng.randi_range(0, 2)
```

The other two are assigned fire. Pressing a button reveals an existing choice; it does not redraw the outcome. A jet reaches 2.7 metres and then stops. That door closes again. The passage stays open until reset. There is always one passage in this construction, because we wrote that guarantee before drawing its index.

REPLAY restores the same assignment. NEW SEED makes another seeded round, which may choose the same passage. After looking once, your next attempt is different even when the doors are not. Memory belongs to the player as well as to the machine.


After the doors, cubes arrive from above. Watch from the edge before entering their space. Does the interval between arrivals vary in the way the stones' pauses did?

At the housed panel, press RUN / STOP. Wait. Some cubes continue moving. Press CLEAR and compare what disappears. Stopping the source did not recall what it had already released. Clearing the flights leaves the source's running state as it was, so stop it first when you want an empty field that stays empty.

Here the timer attempts a launch every half-second. It skips the attempt if 24 projectiles are already active. The irregularity begins elsewhere:

```gdscript
var spawn_pos = field_origin + Vector3(
    _rng.randf_range(-half_w, half_w),
    field_spawn_height,
    _rng.randf_range(-half_d, half_d)
)
```

Two draws choose x and z in an eight-metre square. Height is fixed at eight metres above the field origin. The floor lines mark that region of initial centres. They are neither walls nor a forecast of every place a cube may reach.

Another draw gives an initial downward speed between 1.6 and 2.6 metres per second. Small sideways velocities and later changes let the bodies drift. The projectile carries its own generator. A seed that repeats its launch position does not, by itself, repeat those later changes or its collisions.

The crossing drew a duration. This machine draws positions and velocities on a regular launch clock. Both are called random, but the word cannot tell you where to look. Keep track of which encounter supplied your evidence: a sampled wait at the crossing, or a sampled launch in the field.

At the last podium, wait for a small wooden cube. It drops from three metres above the floor onto a two-metre-square surface. Another arrives at the other position. The positions alternate; after the first one-second wait, each new delay is drawn between 0.3 and 1.3 seconds. The places are dependable while the rhythm is not.

Pick one up. Arrivals wait while either cube is held. Release it and the waiting continues. There are at most two cubes: an arrival replaces the cube in its alternating slot. RUN / STOP holds the arrival clock, leaving released cubes to fall. REPLAY restores the arrival sequence, not the history of your hand or an identical physical landing.

Beside the podium, five cutout profiles recede into the room. Their uneven horizons sit around eye height, 1.7 metres. The nearest is dark; those behind grow lighter. Move sideways and watch one contour uncover another. A landscape appears between flat panels.

Each panel joins seventeen heights. The two ends are fixed; the interior samples vary, with smaller permitted deviations near the edges. PROFILE changes the contours. These heights are a separate experiment, not a graph of the cube delays. Here you can look back and forth along the sequence. At the podium you had to wait through it. What did seeing the whole shape let you anticipate?


The room leaves a more specific question than whether a world is predictable. Which decisions are already made, which are still to come, and what tells us the difference? In Noise Types we will carry that question between neighbouring places. A choice can be uncertain and still have a relation to the choice beside it.

---
