# Spend samples, keep the disagreement

The existing Monte Carlo dartboard now lets you repeat a run, choose how much evidence to collect, and compare eight seeds. This is the next study in the uncertainty plan: the rule stays exact while its estimate varies.

<figure><a href="museum/controls.png"><img src="museum/controls.png" alt="Inside the museum: a cream console with a budget dial and six rectangular buttons, beneath the Monte Carlo board and seed comparison." /></a><figcaption>The installed study, captured in Godot. One local panel keeps the six actions together.</figcaption></figure>

## What changed

The former THROW / AUTO / RESET controls gave access to accumulation. The new console adds a repeatable comparison: budgets of **100, 500, 2000 or 8000**, REPLAY, NEXT SEED, and a table of eight runs. THROW adds one generated sample; +100 adds a batch; FILL reaches the chosen budget. Turning the budget dial clears the run and rewinds its seed. It does not quietly combine two experiments.

<div class="pair"><figure><a href="before/museum/visitor.png"><img src="before/museum/visitor.png" alt="The dartboard and its previous controls before the sample-budget upgrade." /></a><figcaption>Before: the existing board and controls.</figcaption></figure><figure><a href="museum/visitor.png"><img src="museum/visitor.png" alt="The dartboard with its new compact budget console and reading panel." /></a><figcaption>After: the same artifact and location, with explicit run controls. Lighting and capture conditions vary; this is an interface comparison.</figcaption></figure></div>

The dial and rectangular buttons reuse the physical controls developed for the glitch console. Here they steer the sampling conditions. The points are generated from two uniform random draws; the visitor's hand does not aim them. Hand-aimed shots would need a different sampling claim.

All samples remain in the count. Only the newest 300 marks remain visible, so an 8000-sample estimate is not calculated from the 300 dots on display. The console states both quantities. Comparing seeds leaves the current run intact and does not reseed neighbouring artifacts.

## What the comparison actually shows

<figure><a href="museum/seed-comparison.png"><img src="museum/seed-comparison.png" alt="Eight estimates using 500 samples each are shown beside the current dartboard run." /></a><figcaption>The same budget, eight seeds. Differences remain visible beside the active run.</figcaption></figure>

In the tested fixture, seeds 1847–1854 produced the following mean absolute differences from Godot's π constant:

| Samples per seed | Mean absolute difference |
|---|---:|
| 100 | 0.084602 |
| 500 | 0.031398 |
| 2000 | 0.022750 |
| 8000 | 0.014671 |

That is a result for these eight runs. It is not a guarantee for the next seed or the next sample. The 8000-sample run for seed 1847 contained **1785 steps at which absolute error increased**. A test that demanded improvement after every draw would reject correct sampling.

The pedagogical return is precise: the student already knows a point, a list and a loop. Now a stored list supports an estimate. More work can change the evidence without making every intermediate answer better. The [runnable sampler companion](sampler.html) prints the exact core and a complete assertion script; the [main hall tutorial](../../../../commons/maps/Randomness_Examples_of_Randomness/tutorial.md) remains the separate PointBody reconstruction.

## A place in the hall

<figure><a href="museum/overhead.png"><img src="museum/overhead.png" alt="Overhead native view of the full Randomness Examples hall, showing the dartboard beside the main route and the other retained works." /></a><figcaption>Above the existing hall. The dartboard stays in its original bay; the other three works remain. Fifty floor and capsule-clearance samples checked the approach and side bypass.</figcaption></figure>

## What passed—and what remains open

- **24 core checks:** known boundaries, bounded samples, retained counts, exact replay, isolated streams, an independent count calculation and the finite multi-seed comparison.
- **24 checks on code extracted from the printed companion**, plus its eight-assertion runnable example.
- **Two deliberate faults rejected:** excluding circle-boundary points and clearing samples without rewinding the generator.
- **25 native museum checks:** six actual desktop pointer controls, a simulated held XRTools dial, count/display limits, replay, retained camera views and supported approach.

The first installed test caught a real setup defect: map configuration could build the board before `_ready()`, which built it again. The resulting duplicated controls and counts failed the probe. Configuration now waits for scene readiness before building. The [failed receipt](validation/first-installed-check/report.json) is kept beside the [passing native receipt](museum/report.json), [core and mutation results](validation/results.json), and [printed-code results](validation/printed-results.json).

This pass did not test a physical headset, independent learner or Quest performance. The baseline and final logs both report an unresolved resource UID and a blocked authored entrance handled by the hall's safe spawn fallback. Those are existing hall issues; this pass checks the artifact approach, not the whole sequence transition. Renderer/shutdown warnings also remain. The final run contained no script or parse errors. Source snapshots and hashes are retained in the [manifest](source-manifest.json), with the compact [validation record](validation.json).

**Next in this strand:** one saved record, different receivers—the existing camera study can prepare the encounter, but a decoder experiment must state exactly which representation changed.
