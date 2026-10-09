# The shape we counted

What changes when the values stay where they are, but we count them differently?

The two dice could reach the same height by different throws. Their coloured columns kept those ingredients visible. Here we gather values into groups. What will the new picture keep of their differences?

<!-- @distribution_sampler -->

Yellow beads fall toward a row of blue bars. Some bars grow; others wait. An orange line already knows the shape we have come to expect. Look at the beads and the bars before letting that line finish the picture for you.

The cabinet stands in the middle of the hall, its controls facing you as you approach. The other distribution studies stand around it. Its left panel offers UNIFORM, GAUSS, POISSON, EXPON and CLEAR. On the right are BATCH, PAUSE, NEW SEED, BINS and WIDTH. GAUSS is running when you arrive. New beads stop coming after a thousand draws, about twenty seconds; if nothing is falling when you get there, press CLEAR and they begin again.

Press PAUSE. Watch what keeps moving. The beads already released continue to fall. The plate counts them as “in flight” until they land; only the issuing of new draws has stopped. Wait for that count to reach zero. The histogram is now still enough to describe. Where is its highest bar? Where are its gaps? Which of those observations had the word “Gaussian” encouraged you to expect?

CLEAR empties the display and restarts its named seed. While paused, it stays empty. Press BATCH. One hundred values are counted immediately, without the falling animation. Describe this particular arrangement. Press twice more, reading the total each time. A gap may close; another bar may fall further short of the pale bar behind it. More evidence does not promise that every part of the picture will improve at the next press.

Those pale bars carry the model's expected counts at the current number of landed values. Blue and pale share a count scale. Their disagreement is available to examine; the pale shape does not instruct a blue bar to grow toward it. The disagreement is easiest to read where blue falls short, because the pale then shows above it; a blue bar that exceeds its expected count hides the pale top.

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

There is the logarithm, the square root, the turning cosine again. The mean is 0.5; the standard deviation is 0.15: two draws in three land within 0.15 of the middle, nineteen in twenty within 0.30, and the rare ones make the tails. Press WIDTH and the deviation cycles through 0.08, 0.15 and 0.25 with a cleared display, so the same two-in-three can be watched staying inside a narrower or a wider band. The code directly transforms draws into an approximation to a normal distribution. It does not wait for an arbitrary collection of values to become Gaussian. UNIFORM will keep its own law as more draws arrive.

Read the small guard on `u1`. Zero cannot enter the logarithm. Values below 0.0001 share that lower bound, limiting the computed reach to about 4.29 standard deviations. Even before a value reaches the screen, the numerical procedure has made a boundary. The ideal orange model and this finite computation are close enough to compare, and still worth distinguishing.

There is another boundary at the screen itself:

```gdscript
func _fit(raw: float) -> float:
	if raw < 0.0 or raw > 1.0:
		_clipped += 1
	return clampf(raw, 0.0, 1.0)
```

The previous room's glass reflected an overshoot. Here a value past one is kept at one; a value below zero is kept at zero. Its distance beyond the edge is lost from the retained value. Look at the plate's clipped count and its two edge-bin counts. They need not agree: an edge bin also contains values that were inside the display all along.

Try EXPON, then press BATCH three times. More values gather near the left. Occasionally a draw from its long right tail is clamped at one. A finite run need not contain such a draw; the model's tail is a probability, not an appointment. NEW SEED lets another run take place. Its number differs from the current one, though an older number can return later.

Return to GAUSS or UNIFORM, stay paused (the plate's last line should read “paused”; press PAUSE only if it reads “running”), clear, and collect three batches. Now press BINS. Thirty become sixty, then ten, then thirty again. The landed count stays at three hundred. Nothing has been sampled again. The stored values are assigned to new intervals:

```gdscript
	for v in _values:
		_bins[clampi(int(v * num_bins), 0, num_bins - 1)] += 1
```

Watch the mean and the σ marked “binned.” They can change too. The plate estimates each value by the centre of its bin, so changing the intervals changes that estimate. The values have stayed; the account of them has moved. Return to thirty bins and the earlier account returns.

Look back at the height of the picture. Blue bars are scaled against the tallest blue bar, with a small visible baseline even for an empty bin. A handful of values can already occupy almost the whole height. The orange model shape has its own scale. Its curve cannot tell you how much evidence has arrived; the count can.

CLEAR and repeat the batches if you want to point at the same sample twice. That return depends on the seed and the procedure, including which law spends the random draws. It gives a discussion somewhere to stand while the surrounding museum continues.

<!-- @GaussianPaintSplatter -->

A few steps from the cabinet, a white plate collects coloured dots. Their positions come from the same guarded transform you read above, yet no dot lands near the middle: a draw within one standard deviation of the centre is discarded, leaving no mark, and nothing on the plate counts it. That is about two draws in five, taken from the densest part of the model: on a line the same hole would swallow two draws in three, but on a plane it is a disc, and a disc one deviation across holds fewer. Its label calls the hole a “Safe Zone.” From the painting alone, could you tell a centre that was never reached from one that was refused?

<!-- @ -->

We have met a centre, but have not discovered a command to belong to it. Frequent under a chosen model does not mean preferable, healthy or correct. Before carrying this shape onto a body, ask what was measured, what the bins kept, and what the edges absorbed. In Random Mushrooms, sampled numbers become differences among forms. Which features of those bodies will be allowed to vary?
