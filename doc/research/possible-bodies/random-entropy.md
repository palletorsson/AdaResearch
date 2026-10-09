# What the gauge forgets

[Random Definition](random-definition.html) → **Random Entropy** → [Random Remove](random-remove.html)

[The primary and its book passage](/necklace/thread?map=Random_Entropy&role=primary) · [Waves, randomness and noise plan](/research/waves-chance-noise/index.html#Random_Entropy)

Choose two neighbouring colours. Perhaps they make a pair you would keep. Find them again in the enlarged row on the desk's front. Now press SORT and follow what happens to their closeness.

![The meter as drawn: 200 small tiles above an enlarged record of the first forty](random-entropy-drawn.png)

The upper ribbon gathers into blocks of colour. The bars hold still. So does the number. Below the moving tiles, the first forty keep the neighbours they had before. **What did the gauge fail to notice?**

![The same camera after SORT: the upper ribbon regroups while the enlarged original excerpt stays in place](random-entropy-sorted.png)

Claude's existing installation carries this encounter: `shannon_entropy_meter` is the room's one primary and its book anchor. This continuation improves the local controls and caption, checks the complete comparison and develops the text around what can actually be found at the desk.

## Keep the counts. Move the neighbours.

Here are the two complete samples exported by Godot. Try SORT before reading the explanation. The browser wraps the two-metre ribbon into ten rows of twenty; read across each row, then down. Its first-forty excerpt stays as drawn. This is a view of the captured values, not a new random generator or a reproduction of the museum lighting.

[Compare the captured samples](random-entropy.html) in the interactive review.

The browser histogram uses a fixed **0–200 count scale** so the two samples can be compared directly. In the museum, each histogram makes its own largest bar ten centimetres tall. The different rulers are part of the comparison.

The meter begins with one tally for each symbol:

```gdscript
for s in sequence:
    counts[s] += 1
```

Nothing in that loop records where a symbol stood. SORT moves the tile instances into a stable order without rewriting the sampled sequence. In the arrival sample, 198 of 200 instances change place. Their counts remain 17, 11, 21, 31, 17, 18, 19, 24, 13 and 29. The same counts enter the next loop:

```gdscript
for c in counts:
    if c > 0:
        var p: float = float(c) / float(sequence_length)
        entropy -= p * (log(p) / log(2.0))
```

The result is **3.255647 bits per symbol**, both before and after sorting. This marginal measurement uses the shares in the sample. It does not look at neighbouring pairs or use their order to predict the next symbol. A repeated cycle through ten symbols can reach the same maximum as any other evenly populated sample.

## Another sample, another ruler

Press CONTRAST. The alphabet and sample size stay: ten symbols, two hundred draws. This second cached sample comes from a weighted source, with each symbol about half as likely as the one before it. It also has its own seed. Switching back restores the first sample; the buttons do not keep resampling it.

![The concentrated sample from the same desktop camera: symbol zero occurs 109 times, and four symbols have no occurrences](random-entropy-concentrated.png)

The first symbol occurs 109 times. Four symbols never occur. The entropy falls to **1.817600 bits per symbol**. Compare their counts with the marks on the panel: a zero still has a visible bar because the display includes this line:

```gdscript
height = max(0.002, height)
```

Every bar gets at least two millimetres. The tallest also has the same ten-centimetre height in both samples, although its count changes from 31 to 109. Its neighbours make it look dominant; its own height cannot tell you how many occurrences it holds. Read the ledger below it.

DISCLOSE first brings in the formula, then the source and its pale expected-count bars. Those expectations follow the selected source. The uniform source expects twenty of each on average; its actual sample did not divide evenly. The concentrated source supplies a descending set of expectations. Small expected values share the same minimum visible height as some zeros. Keep the numbers beside the picture.

## What becomes possible in the rearrangement?

A sorted row makes every occurrence of a colour easy to find. The original row keeps the pairs and interruptions you first encountered. You might use one as a stock of colours and the other as the beginning of a fabric. The unchanged number cannot decide which arrangement matters to that work.

There are two losses to follow here. Counts discard positions. The entropy reading condenses those counts again: from H alone you cannot recover even the ten bar values. The first-forty record lets the body remain beside some of the relations the gauge has omitted.

This gives the critical question somewhere specific to land. Which relations must a representation preserve for the thing we want to do? A high value is no general certificate of freedom, and a low one does not describe a body's possibilities. Here we can change a relation that matters to us while leaving the instrument satisfied that nothing changed.

## At the desk

![Close desktop inspection of the three front controls with matte faces and pale lettered tags](random-entropy-controls.png)

| Control | What happens here |
|---|---|
| SORT | Rearranges the upper ribbon, then restores its draw order. Counts, H and the enlarged original excerpt stay fixed. |
| CONTRAST | Selects the other cached sample, retaining the sorting choice. Its counts, colours and source expectations replace the current ones. |
| DISCLOSE | Steps the upper panel through ledger → works → origin → oracle → tally → ledger. The desk keeps its own tiles and account throughout. |

The button panel is larger, its backing and lettered tags remain readable under room lighting, and the front excerpt caption now says “first forty · as drawn.” A false ×4 label is gone: the enlargement uses different factors for width and height. Fine lettering on the upper panel still needs a closer approach. Headset reach and reading remain for a later visit.

## Evidence and the next room

**149 independent desktop checks passed, zero assertion failures, engine exit 0.** They exercise real button signals and desktop pointer presses, sorting, both orders of source/disclosure selection, source expectations, the zero and maximum-entropy endpoints, approach, unload and rebuilding. The three comparison captures share the same camera pose. The two exported samples are independently counted and their entropy recomputed; twelve production excerpts are checked across final, tutorial and technical texts.

All nine map placements remain declared. Eight instantiate; the secondary `replay_casino` has no living scene and is still missing from the built room. The primary is present and tested. The run has no script errors, but reports an unrecognized audio-bus UID, a root-certificate error, a logger failure and an ObjectDB shutdown warning. These remain recorded separately from the passing checks. No headset observation is claimed.

[Desktop report](random-entropy-check.json) · [Run receipt](random-entropy-run.json) · [Captured samples](random-entropy-samples.json) · [Tutorial](random-entropy-tutorial.md) · [Technical notes](random-entropy-technical.md) · [Critical text](random-entropy-critical.md)

**Next: [Random Remove](random-remove.html).** Before the draw chooses a place, what has already decided which places are eligible? The question moves from an arrangement on a desk into the space we can walk.

## Book passage

# What the gauge forgets

In the last room, one discarded draw changed which values became neighbours. Here, choose a pair of neighbouring colours before touching a button.

A gauge hangs on a post at the west side of the corridor, its number glowing over a desk. On the desk, two hundred small coloured tiles stand in a row, and a pale bar lies before the first forty of them.

<!-- @shannon_entropy_meter -->

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

<!-- @ -->

The last room asked how an arrangement could return. This room asks what survives when we describe one. The histogram retains the counts; the entropy reading condenses those counts further. From that number alone you cannot recover even the bars, let alone the neighbours you chose. In the next room the eligible set becomes spatial: before anything is removed at random, a rule has already decided what can be chosen.
