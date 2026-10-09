# Random Gaussian — a sample and its account

The primary is `distribution_sampler:180#stand:cabinet` at (11,19). This builds on Random Walk's distinction between a sampled event and its stored record. The next room, Random Mushrooms, uses sampled parameters to vary forms. All excerpts below are from `commons/artifacts/distribution_sampler/distribution_sampler.gd`.

## Begin with the existing controls

PAUSE toggles new automatic draws. Existing airborne markers still land. CLEAR removes both their records and meshes, resets the counts and re-seeds the current private generator; it preserves the running/paused setting. For an exact comparison, PAUSE then CLEAR, choose a law and press BATCH three times. BATCH lands up to one hundred immediately; the full run reserves capacity at issue time, including draws still in flight, and caps at one thousand.

UNIFORM, GAUSS, POISSON and EXPON each clear when selected. BINS cycles 30 → 60 → 10 → 30 without redrawing stored values. The button marked PAUSE is used again to resume; the readout names running/paused. There is no mean/deviation slider or seed-entry field on the cabinet.

## A uniform number acquires another law

```gdscript
		DistType.UNIFORM:
			return _rand()
```

```gdscript
		DistType.GAUSSIAN:
			var u1 := maxf(_rand(), 0.0001)
			var u2 := _rand()
			var z := sqrt(-2.0 * log(u1)) * cos(TAU * u2)
			return _fit(gaussian_mean + z * gaussian_std)
```

This guarded Box–Muller construction approximates the normal law directly, using two uniform draws per returned value. Mean 0.5 and deviation 0.15 are parameters. Collecting more values does not turn the UNIFORM law into a Gaussian law. The cabinet's expected frames use the ideal model; its finite generator and lower guard remain approximations.

The lower guard is applied before the logarithm. Adding epsilon to every draw, as the previous version did, allowed inputs greater than one inside `log`, making the Gaussian square-root argument negative. It also shifted all valid draws. Clamping only the lower input fixes that domain error while preserving the two-draw consumption. The computed standard-normal component is bounded by sqrt(−2 log(0.0001)) ≈ 4.29193.

POISSON counts repeated products until a threshold is crossed, then rescales its integer result:

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

With λ=5, its displayed values lie at integer multiples of 1/15 before clamping. It is a discrete law, even when its bars suggest a continuous mound. The number of random draws consumed per value varies.

EXPON also guards its logarithm:

```gdscript
		DistType.EXPONENTIAL:
			var u := maxf(_rand(), 0.0001)
			var val := -log(u) / maxf(exponential_rate, 0.0001)
			return _fit(val / 2.0)
```

At rate 3, the ideal displayed tail beyond one has probability exp(−6) ≈ 0.002479. A sample of a thousand need not include it. The numerical guard bounds the raw result at approximately 1.535 before `_fit` clamps it.

## A boundary and an interval

```gdscript
func _fit(raw: float) -> float:
	if raw < 0.0 or raw > 1.0:
		_clipped += 1
	return clampf(raw, 0.0, 1.0)
```

This operation clips rather than reflects. The clipped count concerns issued draws; the bars and edge counts concern landed values. Pause and let the current flight finish before treating them as the same population. Edge bins also contain valid interior values, so their counts are not a count of clipped draws.

A value landing in the histogram uses:

```gdscript
		var bin_idx := int(sample.value * num_bins)
		bin_idx = clampi(bin_idx, 0, num_bins - 1)
```

The value one belongs to the last bin. Landed values are retained as a `PackedFloat32Array`. BINS uses that same stored record to rebuild counts. Under a new partition, the binned mean and deviation can change while the values and number of draws stay fixed.

## Counts, expectation and shape

`expected_counts()` multiplies each ideal-model bin probability by the current landed N. Gaussian and exponential edge probabilities include the model mass beyond the display. Blue bars and pale model bars share the observed-maximum count scale and the 0.01 m baseline. Empty bins still have that baseline.

The orange model curve is divided by its own sampled peak and drawn to 80% of display height. The sign labels it a shape at a separate scale. This keeps it inside the panel; it cannot serve as a count axis. Expected-count frames, rather than the orange line, provide the quantitative comparison.

## What replay keeps

CLEAR resets the named generator and sample timer as well as values, counters and markers. NEW SEED rejects the immediately current number but can revisit an older one. Replaying a law with equal sample count repeats its values in order. Keeping the seed while changing laws changes how draws are consumed. Rebinning is a different operation: no new draw is consumed.

Next: identify which properties of a mushroom a sampled value is allowed to change.


## Spatial staging — 16 September 2026

The map keeps a reachable instrument alongside its spatial applications. `map_data.json` is authoritative for placements. `#controls:compact` gathers the existing Rack panels, preserving their callbacks, into an 80 cm console. `#glass_width` opts into an enclosure with open entrances; its grid marks are not floor colliders.
