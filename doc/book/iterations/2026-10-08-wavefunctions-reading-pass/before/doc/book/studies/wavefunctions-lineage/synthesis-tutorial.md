# Five amounts, one shape

## Learning elements

- Harmonic number and coefficient
- A weighted sum from a list and loop
- Holding phase while comparing recipes
- Copying a baseline without resetting the clock
- The limits of a finite representation

Find the dark synthesis bench in the museum. Press HOLD. Lower H2 through H5 one by one. The pale curve changes until only a sine remains. None of the five smooth component rows has the slope you first saw; the slope belonged to their sum.

In Beats, two nearby frequencies drifted in and out of alignment. Here the frequencies stay in integer ratios: one, two, three, four and five times a fundamental. We change their amounts. The unchanged PointBody returns five times as a hand control; LineSkin draws the five contributions and their sum. Arrays supplies the list, and Trace supplies the loop through stored entries.

## Build beside the existing bench

Use the prepared Endless Museum, with its player, XR Tools, camera and lighting. Save the three scripts below together. Attach `12_five_amounts.gd` to an empty Node3D at **hall-local (16, 0, 11), Y rotation 180 degrees, unit scale**. The script creates all five points, six rows and labels. Keep `point_body.gd` and `line_skin.gd` unchanged.

Raise a point to increase its harmonic's amount. Local Y = 0.8 metres means zero; 1.6 metres means one. Release it to keep that height. Horizontal movement does not change its coefficient. Each point keeps its harmonic identity even if you move it past another.

The display starts held. The **H1 point's trigger toggles HOLD/RUN**. The **H5 point's trigger restores BASELINE**, releasing any held controls and returning their heights. It preserves the phase and held state. These are the established PointBody actions; we are giving them new jobs.

## Multiply a contribution, then add it

`amounts[h]` is a coefficient. `h + 1` is the harmonic number because array indices begin at zero. The coefficient changes the amount; the harmonic number changes how many cycles fit in one fundamental cycle. A nonnegative coefficient can still contribute a negative value when its sine is below zero.

{CODE}

`sum_at()` starts a new total for each angle. It does not add yesterday's curve to today's. Each pass through the loop adds one signed contribution at the same angle. This is the familiar sum extended from two named values to a list.

The baseline is copied with `duplicate()`. Editing the working list must not edit the recipe we hope to restore. `restore_baseline()` copies it again, moves the handles and leaves `phase` alone. The inherited `drop()` releases a held control before repositioning it; otherwise the hand would continue commanding its position.

## Hold one thing still

While held, move a point and inspect the resulting change at one fixed horizontal position. Only when RUN is selected does `_process()` advance the common phase, at 0.2 fundamental cycles per second. Multiplying that shared angle by each harmonic number keeps the ratios intact.

At phase zero, a quarter of the way across the rows is angle PI/2. H1 contributes +1; H3 contributes −1/3; H5 contributes +1/5. H2 and H4 are zero there. Predict the total: about 0.867. Now remove H3. The sum rises to 1.2 at that place. Removing something can increase the result because what you removed was negative.

All six rows use the **same gain: 0.16 metres per signal unit**. Their baselines are vertically separated, so add displacements from those baselines, not absolute screen heights. Unlike the last lesson, the sum has no extra half gain. It can extend farther than any component. The display does not normalize it when you change the recipe.

The program draws one fundamental cycle as 64 cylinder segments. Five harmonics do not make an exact sawtooth jump. The finite sum is smooth; the displayed polyline is a further sampling of it. These are two separate limits. This construction also supplies no negative coefficient, independent phase or constant offset. It does not express every periodic shape, and it produces no sound.

## The carried pieces

These are the earlier grabbable point and finite-cylinder renderer. Their complete files remain here so the example can be reconstructed.

{POINT_CODE}

{LINE_CODE}

## Make a change you can explain

1. With the display held, remove H3. Predict the change at the quarter-cycle position, then inspect it. Restore BASELINE with H5's trigger.
2. Lower H2 through H5. Compare the sum with H1. Their displacement should agree because they use the same gain. Lower H1 too: all rows become flat.
3. Run the phase, then hold it. Change several amounts and restore BASELINE. The old shape returns at the held phase. Repeat while running: the recipe returns, but time keeps moving.
4. Build a second recipe: `[1.0, 0.0, 1.0 / 3.0, 0.0, 0.2]`. Before running it, predict what the second half of a cycle will do. With only odd harmonics, it is the negative of the first half. The complete `12_odd_recipe.gd` variation is included in the code download.

The museum bench uses the same weighted-sine principle with sliders, four visible cycles and finer sampling. Its component rows and sum have different drawing gains; its H3 baseline is rounded to 0.333. It hides component ribbons below 0.01 and assigns recipe names within a tolerance. Our reduced study keeps every component line and does not classify recipes. Those extra display decisions are useful to investigate in the exhibit without rebuilding them here.

Native checks execute the exact printed files, known signed contributions, both PointBody actions, baseline independence, phase preservation, displayed geometry and the odd-harmonic variation. Deliberately wrong indexing, unsigned contributions and a shared baseline must fail. Passing these checks establishes code behaviour; it does not establish a reader's understanding or headset comfort.

## What travels onward

In the separate Room Memory encounter, each filtered recording becomes the next input. This tutorial recalculates a curve from a recipe instead. Keep that difference. To recover the same curve at the same instant, we need both its amounts and its phase. Random Definition will ask what else must be retained when the next result is chosen rather than prescribed by this cycle.
