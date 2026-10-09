# A controlled difference in a three-dimensional field

CA_SoftRules separated local reaction from neighbour exchange. This hall holds two 11³ volumes under the same update and forcing schedule, changing one cell in B. It prepares Fractal_Recursion by distinguishing locally accumulated form from an explicit instruction to repeat.

The placed `self_organization_ca#study:difference` mounts `difference_study.gd`; its model is `difference_model.gd`. The legacy 64³ showcase remains available without this configuration. This study changes the domain size and uses a reproducible forcing schedule rather than independent calls to the global random generator.

Each volume is a PackedFloat64Array, indexed `x + 11*y + 121*z`. A scattered beginning is the explicitly authored arithmetic sequence `(i*73+i*i*19+17)%10`; a uniform beginning stores four. B starts as an exact copy, then address (5,5,5) receives +1 if ONE CELL is enabled. The scattered centre is seven, so this intervention remains within the allowed range.

The next value combines the previous cell, the mean of its valid 26-neighbour Moore neighbourhood, and an address/update-indexed forcing value. Outside positions are omitted; there is no periodic wrapping. The corner averages seven neighbours. Both arrays are double buffered.

```gdscript
var drive:float=disturbance*sample(i,tick)
var va:float=clampf(a[i]*(1.0-coupling)+sa/neighbours[i].size()*coupling+drive,0.0,9.0)
var vb:float=clampf(b[i]*(1.0-coupling)+sb/neighbours[i].size()*coupling+drive,0.0,9.0)
na[i]=float(int(va)) if integer_storage else va
nb[i]=float(int(vb)) if integer_storage else vb
```

The schedule `sample(i,tick)` uses bounded integer arithmetic and 2,001 possible values from -1 to 1. It is a reproducible forcing construction, not a claim of independent random samples. No state-dependent random draw is consumed in one run alone.

PULL ranges from zero to one in quarters; DRIVE ranges from zero to four in units. SEED, STORE, ONE CELL and these parameter controls reset both fields. REPLAY preserves parameters and reconstructs the beginning. STEP performs one synchronous update; +10 schedules at most one update per eligible display frame with a 0.12-second minimum interval. Slow rendering stretches the wall-clock duration without inserting extra generations. The observation stops at 100 updates.

The readout counts addresses with `abs(a[i]-b[i]) > 0.000001`, reports the maximum and the mean absolute difference, and prints the display gain. Fractional averaging with matched forcing and clipping is non-expansive in the maximum difference for 0 <= PULL <= 1: a convex combination cannot exceed the old maximum difference, and clipping cannot increase it. Finite precision remains part of the implementation. Integer truncation adds discontinuous thresholds. A count of differing addresses is not a Lyapunov exponent or an entropy measurement.

Volumes show every address as a separated cube. Three wall cases show the selected spatial Z slice. The third case and the floor share the same difference texture. Its gain is `1 / max(max_difference, 0.000001)` and is explicitly printed; A and B use a fixed 0..9 palette. Z SLICE and COAT do not advance time or edit stored fields. The museum floor and passage remain solid.

The source's older lambda coupled neighbour pull to disturbance. It is not Langton's rule-table lambda. Neither that dial nor these new measurements classify this finite run as a universal critical regime. For the historical claim and a re-examination, see [Mitchell, Hraber and Crutchfield (1993)](https://csc.ucdavis.edu/~evca/Papers/rev-edge.html).

The four secondary works are retained. The disease preview computes the original full 64³ synchronous transition over 1,024 display frames and keeps its four-cell display stride; it does not show every infected address. The fog uses a configured 12³ preview and shows a labelled central Z slice in the compatibility renderer. Neither secondary is evidence for the primary's matched-run results. Their wider pedagogical and headset reviews remain open.
