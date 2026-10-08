# Two timesteps, one model duration

Phi separated a weight from both measured change and interpretation. This hall puts a parameter in contact with a specific Gray-Scott update. LAMBDA remains one authored route: feed 0.01–0.08, removal 0.08–0.03, diffusion A 0.8–1.2 and diffusion B 0.3–0.7. Varying it changes all four together.

Every tenure now uses the same periodic four-neighbour operator: neighbour average minus centre. The previous interactive solver used neighbour sum minus four times centre at dt=1; only the two endpoint presets used the normalized operator. Normalization divides the spatial diffusion operator by four. This changes effective diffusion relative to the old interactive model; it is not simply a smaller timestep. The current comparison keeps this normalized model identical on both screens.

```gdscript
var reaction := av * bv * bv
na[idx] = av + (_diffusion_a * lap_a - reaction + _feed_rate * (1.0-av)) * dt
nb[idx] = bv + (_diffusion_b * lap_b + reaction - (_kill_rate+_feed_rate)*bv) * dt
```

For pure diffusion, the normalized operator's most negative eigenvalue is -2; explicit Euler needs D*dt <= 1. Our largest diffusion coefficient times the coarser timestep is 1.2*0.3=0.36. That bound alone is not a proof of stability for nonlinear reaction terms. The recorded numerical checks also examine finite, nonnegative concentrations and a selected timestep-refinement comparison. No claim of universal convergence or physical criticality follows.

The fields are not clipped to [0,1]. B can exceed one transiently with the existing seed; imposing the palette range on the simulated concentrations would change the update. An invalid negative/nonfinite value stops calculation and reports a solver fault. The display palette saturates separately. The paired display uses dt=0.3 with dt=0.15, or dt=0.15 with dt=0.075. One coarse tick and two fine ticks advance both by exactly the same model duration, under the same current coefficients.

RESTART reproduces the numbered seed and resets both clocks. NEW SEED increments it and restarts both. DT .3 / .15 switches the pair and restarts the same seed. HOLD / RUN pauses both fields and their clock. LAMBDA changes their common coefficients; use RESTART after selecting it for a comparison of fixed settings. The readout's B difference is the root mean square of cellwise differences, not entropy or a quality score.

SIM SPEED now requests 3–24 model-time units per visitor second, independently of rendered frame count. Work is limited to four coarse ticks per frame. Under load model time can fall behind the requested rate; the readout reports only time actually integrated. This prevents catch-up work from growing without bound. Quest performance remains unmeasured. Display rate changes texture refresh cadence only.

The pair is enabled through comparison_study:on in this hall. Other placements retain their single display and tenure geometry, but receive the common solver, elapsed-time scheduling and separate RESTART / NEW SEED controls. Legacy regime words become LAMBDA LOW / MID / HIGH, explicitly ranges of the knob, not measured dynamics. Historical tenure names frozen/chaos remain configuration vocabulary. Endpoint presets still preroll 192 model-time units.

The map keeps its central terraces and all six placement families. A level east bay gives the paired study a clear approach; controls occupy two compact rows facing into the hall. The other lambda_slider is still an independent secondary. Its legacy locked token is ignored by that script; this pass makes no claim that it is fixed or drives the solver. The continuous museum suppresses its legacy teleporter, and retains five instantiated works. The secondary turing_pattern screen uses noise and trigonometry rather than a stateful reaction-diffusion update. Its malformed shader hash and fractional-part expressions were repaired so that this retained work can render again. These secondary links belong to the Sandbox investigation rather than an inferred connection here.

Numerical probe: check_solver.gd and solver-checks.json in the dated review folder. Museum probe: check_hall.py. Neither replaces headset testing or a learner's account of what changed.
