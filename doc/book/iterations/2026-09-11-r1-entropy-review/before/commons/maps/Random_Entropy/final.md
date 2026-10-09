# What the gauge forgets

A gauge hangs on a post at the west side of the corridor, its number glowing over a desk. On the desk, two hundred small coloured tiles stand in a row, and a pale bar lies before the first forty of them.

<!-- @shannon_entropy_meter -->

Look at the tiles and the ten bars before the large number. Each tile is one draw, in the order it was drawn, coloured by its symbol; the strip along the panel's foot spells out the first forty, the ones behind the bar. Find a colour that comes often in the row and one that comes seldom, and compare their bars. The bars collect every occurrence wherever it fell; the row keeps where each one fell. Choose two neighbouring tiles and ask whether their closeness tells you anything about the height of their bars. Then find another tile of the same colour further along.

Now press SORT, on the desk's front. The tiles glide into ten blocks, one per symbol, and the pale bar before the first forty disappears, because those forty are scattered through the blocks now. Watch the bars while this happens. They do not move. The number does not move. The plate on the desk's front prints the sorted copy's H beside the reading, the word *equal*, and how many of the two hundred tiles changed place. Press SORT again and the row comes back as it was drawn.

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

3.32 bits for ten symbols, the ceiling marked at the end of the bar. The reading sits just under it, because a finite sample of an even source is never quite even; the bars record this particular sample rather than the ideal distribution as if it had already happened.

So sorting could not have moved anything. The same two hundred tallies went into the same loop. That is the whole of what the sort proves, and it is worth seeing rather than being told, because the row after SORT looks like a different object entirely.

Press CONTRAST. A second sample takes the wall: the same ten symbols, the same two hundred draws, from a source that gives the first symbol half of them, the second a quarter, and so on down. The row is mostly one colour now, the first bar towers, and the number falls to about two bits. Nothing in the alphabet or the count changed; the shares did. The plate names the source and its seed, so you can tell the two samples apart by their provenance and not only by their look. Press CONTRAST again and the first sample returns, draw for draw.

The draws themselves come from a seeded local generator:

```gdscript
		sequence.append(_rng.randi_range(0, num_symbols - 1))
```

two hundred of them, the same two hundred every time the gauge is built, which is how DISCLOSE can take the panel apart and put it back without changing the reading. Press it and the formula appears under the title; press it again and the source is named on the panel with a pale bar behind each live one showing what a uniform law promised. Keep pressing and the panel goes down to the number alone, then climbs again. The reading is the same at every rung. What changes is how much of the measurement is still on the wall beside it.

Now ask what the unchanged number failed to notice. It did not notice the order, which SORT destroyed. It cannot notice a pattern between neighbours, a repeated pair, a rhythm, a message, because it never looked at two tiles at once. It does not know whether the row was worth reading. A high reading is not a certificate of meaninglessness and a low one is not a certificate of value; it is the average surprise per draw, for a reader who guesses each symbol from the shares alone.

<!-- @ -->

You brought a repeatable arrangement in from the last room and watched one number keep everything about its shares and nothing about its arrangement. In the next room the eligible set becomes spatial: before anything is removed at random, a rule has already decided what can be chosen.
