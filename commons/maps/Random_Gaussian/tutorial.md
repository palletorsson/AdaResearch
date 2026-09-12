# Random Gaussian

Many draws, one law, the shape they make. Every excerpt below is from `commons/artifacts/distribution_sampler/distribution_sampler.gd`, the histogram on the cabinet.

Draw one number. Everything the sampler shows comes through this function, from the global stream by default or from a private generator once a seed is named:

```gdscript
func _rand() -> float:
	# The pre-seeded history, when one is being laid down. Null at every other
	# moment, including the whole of the default path.
	if _evidence_rng != null:
		return _evidence_rng.randf()
	if sample_seed < 0:
		return randf()
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = sample_seed
	return _rng.randf()
```

Choose a law. UNIFORM uses the number as it comes; GAUSS turns two into one by the Box-Muller transform; POISSON counts how many uniform draws it takes to fall under e^−λ; EXPON takes a logarithm:

```gdscript
		DistType.UNIFORM:
			return _rand()
```

```gdscript
		DistType.GAUSSIAN:
			var u1 := _rand()
			var u2 := _rand()
			var z := sqrt(-2.0 * log(u1 + 0.0001)) * cos(TAU * u2)
			return _fit(gaussian_mean + z * gaussian_std)
```

```gdscript
		DistType.POISSON:
			var L := exp(-poisson_lambda)
			var k := 0
			var p := 1.0
			while p > L:
				k += 1
				p *= _rand()
			return _fit(float(k - 1) / maxf(poisson_lambda * 3, 0.0001))
```

```gdscript
		DistType.EXPONENTIAL:
			var u := _rand()
			var val := -log(u + 0.0001) / maxf(exponential_rate, 0.0001)
			return _fit(val / 2.0)
```

Fit the value to the display. The histogram runs from 0 to 1; a draw outside lands on the edge it crossed, and the fold is counted:

```gdscript
func _fit(raw: float) -> float:
	if raw < 0.0 or raw > 1.0:
		_clipped += 1
	return clampf(raw, 0.0, 1.0)
```

Bin it. A bead falls from the top of the display and, when it lands, one bin grows:

```gdscript
		var bin_idx := int(sample.value * num_bins)
		bin_idx = clampi(bin_idx, 0, num_bins - 1)
```

Draw the bars against the tallest, so the display is always full:

```gdscript
	var max_count := 1
	for count in _bins:
		max_count = maxi(max_count, count)
```

Draw the law's density at its own scale, which is why the curve and the bars share a shape and not an axis:

```gdscript
		DistType.GAUSSIAN:
			var z := (x - gaussian_mean) / maxf(gaussian_std, 0.0001)
			return exp(-0.5 * z * z) / (maxf(gaussian_std, 0.0001) * sqrt(TAU))
```

Decide what CLEAR means. Without a seed the stream continues and the next histogram is new; with a seed the generator is re-seeded first, and the same draws return:

```gdscript
	if sample_seed >= 0:
		if _rng == null:
			_rng = RandomNumberGenerator.new()
		_rng.seed = sample_seed
```

The cabinet names a five-digit seed on its plate, lands a hundred at once on BATCH, pauses the rain, re-bins the same draws on BINS, and draws behind every bar the count the law expects at the present N with the folded mass in the edge bins — so the bars have something honest to be compared with.

The next room, Random Mushrooms, grows a population from draws like these.
