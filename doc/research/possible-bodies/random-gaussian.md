# The shape we counted

[Random Walk](random-walk.html) → **Random Gaussian** → [Random Mushrooms](random-mushrooms.html)

[The primary and its book passage](/necklace/thread?map=Random_Gaussian&role=primary) · [Waves, randomness and noise plan](/research/waves-chance-noise/index.html#Random_Gaussian)

A curve is waiting before the beads arrive. What can this particular arrangement tell us before we let the model finish it?

![The existing distribution cabinet from the desktop visitor's operating position](random-gaussian-desk.png)

The `distribution_sampler` remains the room's single primary. Its cabinet, two outboard panels, headline and six-line account are retained. This continuation repairs the sampling and marker bookkeeping, keeps the model curve inside its display, and writes the book around a distinction the controls can actually expose: **the values stay while the account of them moves.**

## Enough to look full

![Twelve actual GAUSS values at seed 31415, with blue sample bars, pale model counts and the orange model shape](random-gaussian-twelve.png)

This is a controlled twelve-value capture. It is not a claim that the cabinet has a twelve-draw button. Its tallest blue bar already occupies almost the full display height. That height alone cannot tell us how many observations support the shape.

The orange model shape now stays inside the frame. Its sign says that it has a separate scale. Pale model-count bars share the blue bars' count scale, providing the quantitative comparison at the present N. Empty blue bins still have the cabinet's one-centimetre baseline.

## Same count, another law

![GAUSS, N 300](random-gaussian-three-hundred.png)

![UNIFORM, N 300](random-gaussian-uniform.png)

These two captures use the same seed and N=300, with thirty bins and a shared camera. The sampler constructs GAUSS using a guarded Box–Muller transform. UNIFORM uses each draw directly. More UNIFORM draws will not turn their law into a Gaussian law.

```gdscript
var u1 := maxf(_rand(), 0.0001)
var u2 := _rand()
var z := sqrt(-2.0 * log(u1)) * cos(TAU * u2)
return _fit(gaussian_mean + z * gaussian_std)
```

The logarithm guard matters at both ends. The earlier added offset could push an input above one and make the square root invalid. The repaired lower guard keeps values finite; it also limits the computed tail. The ideal model remains a reference against which to examine a finite numerical implementation.

## Change the grouping

Choose a small sample, then increase N. Change the bins while leaving N fixed. Compare the mean computed from the retained values with the estimate from bin centres. The latter can move even though every value remains.

This reading view uses exported Godot values and model probabilities. It makes no fresh random draws. The plots use visible count axes, with one shared height scale across the pair; their zero-count bars have zero height. “Retained mean” is an extra calculation for this review. The VR plate shows the binned estimate.

[Compare the captured values](random-gaussian.html).

The optional tick strip exposes individual retained values without changing them. In the cabinet, BINS cycles 30 → 60 → 10 → 30. Returning to the earlier partition restores its counts and estimates.

## What the edge absorbs

The previous room reflected an overshoot. Here the display clamps an out-of-range value to zero or one:

```gdscript
func _fit(raw: float) -> float:
    if raw < 0.0 or raw > 1.0:
        _clipped += 1
    return clampf(raw, 0.0, 1.0)
```

The retained value loses its original distance past the edge. The clipped counter remembers that the crossing occurred. Edge-bin counts also contain ordinary interior values, so they cannot substitute for that counter.

At common seed 31415 none of the thousand EXPON draws is clipped, despite the ideal model's nonzero right tail. The second exponential sample above is deliberately selected: **seed 1, 2 clipped draws**. The recorded selection rule was the first seed in 1–20 with at least one clipped value among a thousand. It shows how the edge behaves; it is not presented as a typical sample or a larger clipping probability.

## A pause with something still happening

![The cabinet's account identifies issued and landed evidence, clipping, bins, seed and running state](random-gaussian-readout.png)

PAUSE stops new automatic draws. Already airborne beads keep falling. CLEAR now removes their meshes as well as their records, preserves paused/running state and restarts the named seed. BATCH lands up to one hundred immediately and reserves room for beads already in flight.

The check exercises a cap of ten with four beads airborne: BATCH can land only six. Further manual samples and batches add nothing until CLEAR starts another run. After PAUSE, the existing four can finish and bring the landed total to ten. Beads now land at the height of the bar actually drawn.

This is a local pause; the museum keeps running. The controls give a group a repeatable sample to discuss without pretending to suspend every process around it.

## What is ready

**156 independent desktop checks passed, zero assertion failures, engine exit 0.** These cover the existing nine control paths, actual desktop pointer input, law comparisons, seed replay, retained-value rebinning, logarithm endpoints, airborne capacity, marker cleanup, bar landing height, model-curve bounds, access and unload/rebuild.

The review contains four common-seed samples of one thousand values each and the separately labelled edge example. Intermediate count snapshots are frozen copies and checked against their own N. An earlier export held mutable count arrays and is retained only as rejected evidence. Two subsequent review-harness compile errors were corrected before the accepted run.

The room's 14×22 layers, recovered floor/platforms, teleporter floor override and secondary artifacts remain. Headset approach, small lettering and Quest performance still need the later visit. The accepted run's startup diagnostics are recorded separately from the passing checks; no headset verification is claimed.

[Desktop report](random-gaussian-check.json) · [Run receipt](random-gaussian-run.json) · [Captured values](random-gaussian-histories.json) · [Tutorial](random-gaussian-tutorial.md) · [Technical notes](random-gaussian-technical.md) · [Critical text](random-gaussian-critical.md)

**Next: [Random Mushrooms](random-mushrooms.html).** Which properties of a body are the sampled values allowed to change?

## Book passage

# The shape we counted

What changes when the values stay where they are, but we count them differently?

<!-- @distribution_sampler -->

Yellow beads fall toward a row of blue bars. Some bars grow; others wait. An orange line already knows the shape we have come to expect. Look at the beads and the bars before letting that line finish the picture for you.

The cabinet stands in the south-east of the hall, beyond the other distribution studies. Its left panel offers UNIFORM, GAUSS, POISSON, EXPON and CLEAR. On the right are BATCH, PAUSE, NEW SEED and BINS. GAUSS is running when you arrive.

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

<!-- @ -->

We have met a centre, but have not discovered a command to belong to it. Frequent under a chosen model does not mean preferable, healthy or correct. Before carrying this shape onto a body, ask what was measured, what the bins kept, and what the edges absorbed. In Random Mushrooms, values like these become differences among forms. Which features of those bodies will be allowed to vary?
