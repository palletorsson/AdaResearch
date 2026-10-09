# The shape of many draws

What can many draws reveal that one draw cannot?

<!-- @distribution_sampler -->

At the far end of the hall, past the mound and the comparator, a dark cabinet stands against the east wall with a histogram on top of it. Thirty bars, a faint orange curve over them, small yellow beads falling from the top of the display and landing on the bars. Under the histogram a plate keeps six lines; on a shoulder at hand height, two panels: UNIFORM, GAUSS, POISSON, EXPON and CLEAR on the left, BATCH, PAUSE, NEW SEED and BINS on the right. GAUSS is running when you arrive.

Press PAUSE, then CLEAR, and watch the first dozen beads land. Say what you see before you say what it means. Three bars up, two of them next to each other, one off to the left; nothing in the middle yet. It is tempting to say that the bell is forming. It is not visible, and the plate agrees: landed 12 of a cap of 1000. Press BATCH and a hundred draws land at once without the rain. Now there is a hump, lopsided, with a gap in it. Press BATCH twice more. The hump is a hill; the gap has filled; the tallest bar is not quite in the middle.

Behind every bar a pale frame stands at the height the law expects for that bin at this many draws. The bars and the frames are the same kind of thing, counts at the present N, and the point of the room is the difference between them. At three hundred draws some bars stand over their frames and some under; that is what a sample looks like. Do not read the frames as a target the bars have failed. Read them as the other half of a comparison that needs both halves.

Press UNIFORM. The histogram clears, the seed on the plate stays, and three presses of BATCH give you three hundred draws again. Now every frame is the same height, ten, and the bars wander round it, none of them tall. Equal N, another law. The plate says which:

```gdscript
		DistType.UNIFORM:
			return _rand()
```

one number from the generator, used as it comes. GAUSS uses two:

```gdscript
		DistType.GAUSSIAN:
			var u1 := _rand()
			var u2 := _rand()
			var z := sqrt(-2.0 * log(u1 + 0.0001)) * cos(TAU * u2)
			return _fit(gaussian_mean + z * gaussian_std)
```

The same stream feeds both. The Box-Muller transform turns two uniform draws into one normal one, and the small offset inside the logarithm, which keeps log of zero away, also caps how far a draw can stray: about 4.3 standard deviations, and no further. A mean of 0.5 and a deviation of 0.15 put most of that on the display. The rest is folded:

```gdscript
func _fit(raw: float) -> float:
	if raw < 0.0 or raw > 1.0:
		_clipped += 1
	return clampf(raw, 0.0, 1.0)
```

A draw beyond the display's edge lands on the edge, and the third line of the plate counts how many did. Under GAUSS the count stays at zero or one per thousand. Press EXPON and the picture changes shape: the tallest bar is the leftmost, the curve drops away, and the plate's last frame carries what the law puts past the right edge, about a quarter of a percent, so the bounded display does not pretend the law stops where the panel does.

A landed bead goes to a bin by one line:

```gdscript
		var bin_idx := int(sample.value * num_bins)
		bin_idx = clampi(bin_idx, 0, num_bins - 1)
```

Thirty bins are a way of reading, not a fact about the law. Press BINS: the same draws are re-binned into sixty, then ten, then thirty again, and the plate's landed count does not move. Nothing is drawn again. If the picture looks different in ten bins than in sixty, the difference is yours.

Press CLEAR twice more, with a BATCH after each, and compare the two histograms. They are the same, bin for bin, because the plate names a seed and CLEAR re-seeds before it empties the bins:

```gdscript
	if sample_seed >= 0:
		if _rng == null:
			_rng = RandomNumberGenerator.new()
		_rng.seed = sample_seed
```

NEW SEED names another and the picture is new. A replay is what lets you point at one sample twice; it does not make the sample less random.

<!-- @ -->

Look, last, at the orange curve. It is the law's density, drawn at its own scale, and it never changes with N. The bars are normalised to the tallest of them, so they always fill the display. The two agree in shape and in nothing else, and a picture that put them on one axis would be lying about one of them. Keep that separation when you read a bell curve anywhere: the mean is the middle of a frequent region under one model, not a measure of how normal a thing or a person ought to be, and the edge bins here hold what the model could not fit. In the next room a population of forms is grown from draws like these, and the question becomes which of its features were allowed to vary at all.
