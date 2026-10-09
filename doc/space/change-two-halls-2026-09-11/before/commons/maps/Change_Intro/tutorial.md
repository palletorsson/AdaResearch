# Two samples before the tangent

This room carries the position/address reasoning of Ribbon_Patterns_03 into a rate with respect to position. Its independent variable is x, not elapsed time. It prepares for Accumulation_Riemann.

The primary is `tangent_slope_workbench`, with the map-only `comparison:true` adapter in `rate_comparison.gd`. The existing slider and five buttons share a widened console. The base workbench retains its single smooth function and analytic derivative:

```gdscript
static func _f(x: float) -> float:
    return 0.5 + 0.4 * sin(2.0 * x) + 0.15 * cos(5.0 * x)

static func _df(x: float) -> float:
    return 0.8 * cos(2.0 * x) - 0.75 * sin(5.0 * x)
```

At first the tangent, derivative subplot and sign indicator are hidden. A second green point and the segment joining it to the red sample show a finite difference. STEP cycles h through 0.5, 0.25, 0.125 and 0.0625; near x=5, h is negated to keep the other sample inside the domain. The readout displays the actual signed interval.

```gdscript
var rise = bench._f(x + h) - bench._f(x)
var rate = rise / h
```

At initial x=1, the h=0.5 estimate is about -0.5956, while the analytic derivative is about +0.3863. At h=0.0625 the estimate is about +0.2971. The wider interval crosses a crest. This gives the learner a concrete disagreement to investigate before DERIVATIVE reveals the analytic tangent and plot.

The slider selects x continuously; x - and x + change it by 0.125 with endpoint clamping. RESET restores x=1, h=0.5 and the hidden analytic comparison. DERIVATIVE toggles the comparison without changing either function. Source curve vertices remain fixed; only sample markers, tangent, secant and readouts change.

The rendered polyline uses 200 intervals. The two sample values and derivative are evaluated from the formula, not estimated from those rendered vertices. The plotted axes have different drawing scales; the numeric derivative is df/dx in model coordinates. The sign indicator's magnitude threshold (0.05) is labelled near zero, not an extremum detector. Four finite sample intervals are not a numerical proof of a limit or an assertion that smaller always means more accurate.

The comparison adapter is opt-in. Other placements retain the existing slider/tangent interface. This does not connect the displayed slope to the player's walking physics. Headset legibility, tracked-hand slider use and comfort remain to be checked.
