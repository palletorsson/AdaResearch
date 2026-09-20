# What gets to stand for an interval?

The curve has followed us. In Change_Intro, two samples could report a fall while the curve was rising at the first point. Here we keep the same function and ask it for something else. Across this whole interval, how much area lies between the curve and the baseline?

<!-- @riemann_sum_workbench -->

Four blue rectangles wait under the line. Their tops cut through it. Somewhere a rectangle includes space above the curve; elsewhere it leaves space beneath it uncounted. Before touching the slider, choose one rectangle. Where would you put its top?

The console begins at **MID / N 4**. Press **CELL +** to move the red sample through the four intervals. The selected height and width appear together, followed by their product. Each interval is 1.25 units wide. One height has been asked to represent everything that happens across that width.

Press **HOLD**. A second panel keeps these four rectangles and their total. Now press **RULE** once. The live rectangles take their heights from the right edges of their intervals. The curve has not moved. The widths have not changed. Watch how much of the picture changes anyway.

Which total would you trust? Keep the question open while pressing **RULE** again for the left edges, then again for the midpoints. The held panel remembers the version you chose to keep. Its stillness gives the moving comparison somewhere to land.

The calculation is short enough to read aloud:

```gdscript
var width = (b - a) / n
var total = 0.0
for i in range(n):
    var x = a + (i + fraction) * width
    total += f(x) * width
```

`fraction` is 0 for the left edge, 0.5 for the midpoint, and 1 for the right edge. An address, a height, a width, an addition. The loop keeps doing the same small thing. What looks like a filled area is made from these contributions.

This is a Riemann sum. Here `a` is 0 and `b` is 5. The function stays positive, so the contributions are positive areas. In another model, a rate multiplied by a time interval could give an amount gained during that interval. We would need to name that rate and those units. Moving this slider does not turn its position axis into a clock.

Return to the midpoint rule and leave the held four-rectangle panel beside it. Move the count slider one stop. Eight narrower rectangles now look at the same curve. Follow their tops. A ridge that passed between two samples may now receive a sample of its own. Continue through 16, 32, 64 and 128. What becomes easier to estimate, and what becomes harder to distinguish by eye?

The held total stays at about 2.23665. At eight midpoint samples the live total is about 2.88669. More samples have changed the account substantially. The smooth-looking line did not warn us how much the first four would miss.

Only now press **REFERENCE**. The console shows a separate estimate made from 4,096 midpoint rectangles, about 2.86384, and the signed difference between the live sum and that reference. Toggle it off to return to the selected contribution. The small difference bar has a cap of 0.05; two full bars can conceal very different discrepancies. Read the numbers as well as the shape.

Try **RESET**, hold the four midpoint rectangles again, and select the right-edge rule. Against this reference, those four right-edge samples are closer than the four midpoints. A familiar method has no entitlement to win every coarse comparison. For this smooth function, sufficiently fine partitions bring the estimates together; that does not make every finite sampling choice equivalent.

There are several resolutions in front of you. The curve is drawn with 200 line intervals. Your sum uses one of six counts. The reference uses 4,096 rectangles. The integral is the limit these sums approach as the partition width tends to zero; none of the buttons reaches that limit. The apparently continuous image and the reassuring reference number each have a finite construction we can inspect.

<!-- @ -->

What did we reject to make a total possible? Variation inside each interval has been replaced by one selected height. Then the individual contributions have been gathered into a number that cannot tell us where they came from. The held picture keeps some of that history available. It still cannot keep everything.

Ada needs such reductions to run. The question is where to reopen them. An estimate can be useful enough to act on while leaving a difference worth returning to. Who chooses the tolerance, and for which body or task?

Carry the loop into **Flow_Field**. Here each contribution could be sampled at a predetermined address. A moving body will arrive at its next address partly because of its previous update. What changes when the path through the samples is itself being made?
