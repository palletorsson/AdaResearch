# Change and accumulation

## Between two readings

<!-- @tangent_slope_workbench -->

The green line slopes down. The curve leaves the red point going up.

Follow it towards the green point. Between the two samples there is a crest. The line joining them has passed straight across something the curve had to go through.

We have learned to ask what belongs at an address: a point, a colour, a piece of a pattern. Here we ask for a value at one address and another value nearby. Both readings are accurate. Together they report a fall. Stand with the red point a little longer and a different direction becomes visible.

Press **STEP**. The green point comes closer. Press again and watch the joining line turn. The curve has stayed where it was.

The calculation has two parts:

```gdscript
var rise = f(x + h) - f(x)
var rate = rise / h
```

`x` is the position of the red sample; `h` is the interval to the green one. The function `f` supplies the height at either address. Subtract the heights and divide by the interval: a change in height per unit of horizontal position. The console gives that relation a number.

A broad interval reached beyond the crest. A shorter one stays on the rising part. Neither line needs to accuse the other of lying. They have looked across different distances.

Now press **DERIVATIVE**. A gold tangent appears at the red point. Above the curve, a second plot shows how its local slope varies from place to place.

The derivative asks what the finite ratios approach as the interval tends to zero, where that limit exists. The gold line comes from an analytic calculation for this smooth function. We can compare our samples with it, although none of the four STEP settings reaches the limit itself. Dividing by zero would not bring us closer.

![A shorter interval and the revealed slope plot at the museum workbench](/book-images/figures/change/two-readings-near-museum.png)

*The red sample has stayed at the same address. The green one has come closer; their joining line now rises. Above the curve, the second plot gives its slope another place to appear.*

Move the red point with the slider. Find a crest. The curve is high there; the gold line is almost level. Follow the slope plot while moving down the other side. Height and rate have acquired separate lives in the picture: a high value can be changing very little, and a low one can be changing quickly.

Try two places of similar height on opposite sides of a crest. A height alone would not tell you which side you had reached. Even the tangent answers only locally. Extend its line in your imagination and watch it leave the curve behind.

The independent variable here is position. Moving your hand quickly over the slider does not turn the displayed rate into a velocity. To ask how fast a body moves, we would need positions and the times at which it occupied them. For now the curve waits while we change the distance across which we read it.

Across the hall, a puck circles a closed track with an arrow turning beside it. There, a clock advances the position. Watch how the arrow turns as the puck rounds a bend.

<!-- @ -->

We can make the interval smaller. We can also ask something that needs the whole interval. The next workbench keeps this same curve.

## One height stands for an interval

<!-- @riemann_sum_workbench -->

Four blue rectangles reach up towards the same curve. Their tops cut through the line: some include space above the curve, others leave space beneath it uncounted. We want the area between the curve and the baseline. These four awkward shapes offer a beginning.

Choose a rectangle. **CELL +** moves the red sample from one interval to the next. At each, the console gives a height, a width and their product. One height has been asked to represent everything that happens across that width.

Press **HOLD**. A second panel keeps the four rectangles and their total. Then press **RULE**. The live rectangles take their heights from the right edges instead of the midpoints. Another press takes the left edges; one more returns to the midpoints. The held image stays available through all three. The curve has not moved, nor have the intervals. What changed was where each interval was asked to speak from.

The loop can be written like this:

```gdscript
var width = (b - a) / n
var total = 0.0
for i in range(n):
    var x = a + (i + fraction) * width
    total += f(x) * width
```

`a` and `b` mark the ends of the region. `n` divides it into equal intervals. A `fraction` of 0 chooses the left edge, 0.5 the midpoint, 1 the right edge. Multiply each selected height by its width and add the contributions. This is a Riemann sum.

The function stays above the baseline here, so every contribution adds positive area. The loop does not need to see the filled picture we are making from it.

Return to MID and increase the count to eight. Keep the held four beside them. A ridge that passed between two samples can now receive a sample of its own. The total changes noticeably. Continue to narrower rectangles. Their differences become harder to see as the tops gather around the line.

![Eight live rectangles beside four held rectangles inside the museum](/book-images/figures/change/four-held-eight-live-museum.png)

*Eight live intervals on the left, four held on the right. The earlier reading remains available.*

There is pleasure in watching the little steps approach a curve. The smooth-looking line has been there throughout, as though it already knew the answer. But it too was drawn from a finite set of positions. The two pictures have different resolutions.

Press **REFERENCE**. Another total appears, made from 4,096 midpoint rectangles. It gives our smaller sums something to compare with; it does not stand outside the same process of sampling. The integral is the limit approached as the intervals become arbitrarily narrow. This reference, like every setting on the slider, remains finite.

Return to four rectangles and compare MID with RIGHT. Against this reference, the right-edge choice happens to come closer. A familiar method has no entitlement to win every coarse comparison. For this smooth curve, sufficiently fine partitions bring the estimates together, but the first few choices can disagree substantially.

HOLD has given that disagreement somewhere to stay. We can change the live picture without asking our memory to preserve every earlier rectangle. The extra display is a small provision for thinking: the answer we left behind remains available to challenge the next one.

<!-- @ -->

The total is useful when we want the area. The picture is useful when we want to see how we arrived at it. We might need a finer estimate for one task and be ready to act on a coarser one for another. How much work should the calculation do before we let its result matter?

At the bridge, contributions will begin to cancel.

## Returning to the same height

<!-- @ftc_bridge -->

A pulse travels up an arch and down the other side. Its destination is level with its beginning. Watch it reach the end, then look at the strips beneath the bridge. Some rise above their baseline; others extend below it.

The arch is a new curve. The strips describe its signed rate of height change against horizontal position. Rising contributes positively, falling negatively. Press **COMPARE TOTALS**. The height difference between the endpoints appears beside a numerical sum of those rates across the span.

Zero net change does not mean that nothing happened.

The calculation adds each interval's width times the average of the rates at its two ends. Its structure is:

```gdscript
var dx = span / samples
for i in range(samples):
    total += (slope_at(i) + slope_at(i + 1)) * 0.5 * dx
```

For a continuously differentiable height function, integrating its signed derivative recovers the final height minus the initial height. This is the net-change relationship in the fundamental theorem of calculus. The bridge offers a finite numerical comparison with the endpoint difference. Watching the two agree gives the relationship a visible form, although the numerical experiment is not its proof.

The earlier rectangles added heights to estimate an area. Here we add changes to recover a difference. Keep the input in mind: the same habit of accumulation has been given another job.

There is still something we cannot recover from slopes alone. Lift the whole arch in your imagination. Its rises and falls remain the same; its starting height changes. To recover absolute height from a rate, we must also choose somewhere to begin.

In **Point_Lines**, `b - a` gave the same answer for a direct walk and a detour. The arch brings that question into height. Its climb can cancel its descent in this account. A traveller who had to make both would have another account to give. Adding the magnitudes of the changes would keep the rise and the fall from cancelling, but would answer a different question.

<!-- @ -->

The pulse begins again. We know where it will end, and still have the arch to follow.

Other encounters wait beyond the bridge: three sampling rules side by side at the pump, frame-sized steps on the staircase, paper boats in a gutter river, a marble in a swaying bowl. Each offers another way to ask what a description of movement keeps.

In the next room, the last step will help decide where the next reading happens. The loop is about to make a route of its own.
