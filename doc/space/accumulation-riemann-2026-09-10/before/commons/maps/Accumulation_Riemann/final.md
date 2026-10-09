How much can an estimate change when its pieces become thinner?

The tangent bench inspected one position at a time. This bench uses many sampled positions together. The question is what their contributions can tell you about an interval.

<!-- @riemann_sum_workbench -->

Begin with four rectangles. Look where their tops differ from the curve, then predict what eight rectangles might change. Move the count slider and compare the estimate with the reference shown beside it.

Continue through sixteen, thirty-two, sixty-four and one hundred and twenty-eight. Watch the rectangles become thinner. Distinguish a change in the approximation from a change in the underlying curve: it is the same curve receiving a different number of samples.

Each rectangle uses the function's height at its midpoint. Its contribution is that height multiplied by the interval's width. Adding those contributions produces the midpoint sum. The operation joins a value and the extent over which that value is being used to stand in for the curve.

The displayed reference is itself a numerical midpoint sum, made with 4,096 rectangles. Its density makes it a useful comparison here, but the label does not turn a finite computation into an exact symbolic integral. Compare estimates while keeping that distinction visible.

For suitable functions, refinement lets midpoint sums converge to the integral. This smooth example lets you investigate that approach; it does not prove that every increase in sample count improves every function monotonically. The conditions and error estimates are developed in [OpenStax's numerical integration chapter](https://openstax.org/books/calculus-volume-2/pages/3-6-numerical-integration).

<!-- @ -->

Choose a tolerance you would accept for a particular use, then find the coarsest estimate you would keep. Compare that choice with another visitor's, or repeat the decision under a stricter tolerance. More samples cost additional work. Whether the difference matters depends on what the estimate will be used to decide.

Imagine a narrow peak falling between two sample positions. A coarse picture might miss it while looking perfectly regular. That curve is a proposed further test, rather than a feature you can select at this bench. Name what the missed contribution would do to the estimate.

The next room also accumulates small steps, but its result is a moving path. Keep track of which information is sampled locally and which larger pattern becomes visible only after those samples have been used together.
