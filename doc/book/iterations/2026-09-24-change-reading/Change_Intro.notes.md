# Three experiments

# Two samples before the tangent

This room carries the position/address reasoning of Ribbon_Patterns_03 into a rate with respect to position. Its independent variable is x, not elapsed time. It prepares for the accumulation workbench later in this same hall.

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


# Accumulation: one height represents an interval

Continue to the second bay with the same function, `0.5 + 0.4*sin(2*x) + 0.15*cos(5*x)`, on [0,5]. The earlier bench compared local rates; this bench adds height-times-width contributions. Its axis is position, not elapsed time.

1. Begin with four midpoint rectangles. Use CELL +/- to follow the selected sample and read its height, width and contribution.
2. HOLD the current picture and total. RULE cycles MID, RIGHT, LEFT. Compare equal counts before changing resolution.
3. Return to MID and move the existing count slider through 4, 8, 16, 32, 64, 128. The held panel remains unchanged until another HOLD or RESET.
4. Reveal REFERENCE after predicting which total is closer. It is a separate 4096-midpoint computation. Toggle it off to recover the contribution readout.
5. RESET restores four midpoint rectangles, hides the reference and clears the held comparison.

The calculation is `width=(b-a)/n`, `x=a+(i+fraction)*width`, `total+=f(x)*width`. The sample fractions are 0, 0.5 and 1. Selected samples, rectangle heights and total all use the same rule. The curve drawing stays fixed at 200 intervals. Held geometry copies vertex arrays so later live rebuilds cannot alter it.

At N=4, MID is about 2.23665, RIGHT about 3.26367 and LEFT about 3.53733. The reference is about 2.86384. RIGHT is closer than MID here, disproving the old claim that midpoint always wins. For this smooth function, fine partitions converge toward the integral; six finite slider stops are an experiment, not the limit itself.

The difference bar saturates at 0.05. Its numeric readout retains the signed difference. The function is positive throughout this encounter; signed cancellation and total distance are later experiments, not demonstrations already present here. The rectangles are a mounted plot, not walkable steps.

The third bay is the ftc_bridge. Compare its signed derivative contributions with its endpoint height difference. Its arch is a different function from the two workbenches. Flow_Field follows this encounter, introducing trajectories whose sampling addresses depend on prior movement.


The ftc_bridge uses evidence:longhand with reveal_on_request:true. The arch and signed derivative strips remain visible; COMPARE TOTALS reveals or hides the endpoint height readings, difference marker and 512-interval trapezoid comparison. Other placements retain their configured evidence behavior unless they opt into this reveal. Keep its different source function explicit. The consolidated final.md supplies the traversal order and transitions.

## Operating details retained beside the reading — 24 September 2026

The revised final.md keeps the finite-difference and Riemann-sum sketches and the bridge's trapezoid loop. The full analytic function and derivative remain above; the gold tangent uses that calculation rather than extrapolating the four STEP settings. Pressing DERIVATIVE again hides the comparison. RESET returns the opening wide interval and sample. A hypothetical sharp corner is not part of the smooth function currently offered.

The bridge's signed-rate sum uses 512 intervals; its source curve is a symmetric arch distinct from the two workbenches. Adding magnitudes would be a separate quantity from the signed sum. A net height change is not a complete account of effort, path length or accumulated absolute height change. The rate uses horizontal position; the pulse's animation does not turn that independent variable into time.

The manuscript no longer interrupts the encounter with every display threshold, slider count or stored decimal. Those values remain in this companion: four finite-difference intervals, six rectangle counts, the 200-interval drawn curve, the 0.05 sign/difference-bar thresholds, and the finite 4,096-sample reference. The reference is not an exact integral. Its midpoint estimates include N=8 at about 2.88669, compared with N=4 at about 2.23665 and the reference at about 2.86384.

### Further encounter, not a current capability

A measured visitor-velocity arrow or a slope-responsive walking body could turn these comparisons into locomotion. The present plots do not implement that connection. Keep the question of which rate a body needs, while testing such an encounter before writing it as an accomplished walk. Existing secondary artifacts remain available for that development.

Full previous prose, including all former operating passages: [before this revision](Change_Intro.before.md).
