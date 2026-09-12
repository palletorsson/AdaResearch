# What the gauge forgets

A gauge hangs on a post at the west side of the corridor, its number glowing over a desk. On the desk, two hundred small coloured tiles stand in a row, and a pale bar lies before the first forty of them.

<!-- @shannon_entropy_meter -->

Look at the tiles and the ten bars before the large number. Each tile is one draw, in the order it was drawn, coloured by its symbol; the strip along the panel's foot spells out the first forty, the ones behind the bar. Find a colour that comes often in the row and one that comes seldom, and compare their bars. The bars collect every occurrence wherever it fell; the row keeps where each one fell. Choose two neighbouring tiles and ask whether their closeness tells you anything about the height of their bars. Then find another tile of the same colour further along.

Now press SORT, on the desk's front. Watch the row and the bars together. The tiles glide into ten blocks, one per symbol; the bars hold their places. Look up at the number. It has stayed too. The pale bar before the first forty disappears: those particular draws no longer occupy the beginning of the sorted row. The plate on the desk's front prints the sorted copy's H beside the reading, the word *equal*, and how many of the two hundred tiles changed place. Press SORT again and the row comes back as it was drawn.

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

3.32 bits for ten symbols, the ceiling marked at the end of the bar. The reading sits just under it, because this sample from an even source did not divide evenly; the bars record this particular sample rather than the ideal distribution as if it had already happened.

Sorting changed the row without changing any tally. The same counts entered the same loop. Yet the row looks like another object. Keep it sorted for a moment: finding every occurrence of a colour has become easier. Return to the order drawn and a colour has its former neighbours again. Which arrangement would you want to work with? The gauge cannot choose between these uses for you.

Press CONTRAST. A second sample takes the wall: the same ten symbols, the same two hundred draws, from a source that makes the first symbol about twice as likely as the second, the second twice as likely as the third, and so on. The probabilities are normalised across ten symbols; they do not promise fixed counts. In this sample the first symbol occurs 109 times. Its bar towers, and the number falls to about 1.82 bits. Nothing in the alphabet or the count changed; the shares did. The plate names the source and its seed, so you can tell the two samples apart by their provenance and not only by their look. Press CONTRAST again and the first sample returns, draw for draw.

The first sample comes from a seeded local generator, giving each symbol the same chance on each call:

```gdscript
		sequence.append(_rng.randi_range(0, num_symbols - 1))
```

The seed lets the gauge recover this sample when it rebuilds. The contrast uses a second seed and a weighted draw; it too can be recovered. Press DISCLOSE and the formula appears under the title; press it again and the source is named on the panel with a pale bar behind each live one showing the count that source expects on average: one flat line for the even source, a descending staircase for the concentrated one, and the plate prints those expected counts beside its name. Keep pressing and the upper panel withholds its bars and strip, then brings them back. The reading stays. Look down: the desk still carries the tiles and its own account of the counts. Information absent from one display can remain within reach on another. How much would you know if you approached only the glowing number?

Now ask what the unchanged number failed to notice. It did not notice the order, which the sorted view rearranged. It cannot notice a pattern between neighbours, a repeated pair, a rhythm, a message, because it never looked at two tiles at once. It does not know whether the row was worth reading. A high reading is not a certificate of meaninglessness and a low one is not a certificate of value; here it averages surprise using the shares counted in this sample, without consulting the neighbours of a draw.

<!-- @ -->

You brought a repeatable arrangement in from the last room. The histogram retained its counts; the entropy reading condensed those counts further. From that number alone you cannot recover even the bars, let alone the neighbours you chose. In the next room the eligible set becomes spatial: before anything is removed at random, a rule has already decided what can be chosen.
