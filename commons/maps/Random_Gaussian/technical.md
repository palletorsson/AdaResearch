# Random Gaussian — implementation record

Primary: `res://commons/artifacts/distribution_sampler/distribution_sampler.tscn`, with `distribution_sampler.gd` in the same folder. Placed at (11,19), facing north, under `#stand:cabinet`. The 14×22 map, nineteen recovered platform cells, museum floor override at the teleporter (10,3), clear rectangle [[9,16,13,21]] and existing secondary artifacts remain.

The cabinet carries a 0.6×0.4 m display at 0.95 m, with controls on its outboard shoulder. Its housed headline and six lines identify law, landed/in-flight counts, cap, clipped draws, edge-bin counts, binned statistics, seed and cadence. The sign now distinguishes blue sample counts, pale model counts and the orange model shape at a separate scale.

| Quantity | Current setting |
|---|---|
| Automatic rate | 50 issued draws/s |
| Run cap | 1,000 issued draws, including flight |
| BATCH | Up to 100 draws landed immediately, within remaining reserved capacity |
| BINS | 30 → 60 → 10 → 30; no redrawing |
| Gaussian | mean 0.5, deviation 0.15; guarded Box–Muller |
| Poisson | λ=5; integer result divided by 15 |
| Exponential | rate 3; sampled time divided by 2 |
| Stored range | [0,1], clamped rather than reflected |
| Retained values | PackedFloat32Array, landed values |
| Bar baseline | 0.01 m, including empty bins |
| Orange shape | 80% display height at its own sampled peak |

There are nine panel controls: UNIFORM, GAUSS, POISSON, EXPON, CLEAR; BATCH, PAUSE, NEW SEED, BINS. PAUSE toggles issuance; already issued markers continue to land. CLEAR preserves the running flag and re-seeds, resets counters/timer and clears both flight dictionaries and meshes. NEW SEED rejects the immediately current seed. There are no cabinet mean/deviation controls or seed-entry field.

This review repairs Gaussian and exponential logarithm inputs by applying `maxf(u,0.0001)` instead of adding 0.0001. The Gaussian's old expression could take the square root of a negative number for u>0.9999; the exponential could return a small negative value near u=1. New endpoint tests call the production transforms with injected inputs 0, 0.00001, 0.5, 0.99995 and 1. Draw consumption is unchanged, but seeded numerical values intentionally change where the old offset shifted them. Historical screenshots are not golden numerical baselines for the corrected transform.

Capacity is reserved at `_drawn` rather than `_total_samples`: automatic/manual issuance and BATCH cannot jointly oversubscribe a run while beads are airborne. Manual negative batch sizes cannot reduce counters. CLEAR detaches old meshes before deferred freeing; landing cleanup does the same so remaining dictionary indices correspond to live marker children. Landing tests the actual drawn bar top, including its baseline, instead of the old independent max_samples-based height.

The ideal Gaussian reference uses `normal_cdf`; EXPON uses differences of exponential survival probabilities. Edge probabilities include ideal mass outside the range. These model expectations are not exact descriptions of every finite generator or guarded tail. The orange line is only a model-shape reference and is scaled independently of counts. Binned mean/standard deviation use interval centres, not exact retained values, so changing bins can change their estimates.

The extended live probe exports four 1,000-value samples under a common seed plus a deliberately selected exponential edge example. Snapshots at 1,12,100,300,1000 and rebinning at 10,30,60 are deep copies; the first export exposed mutable count arrays and was superseded. Initial runtime assertions passed, but that first export must not be used for intermediate counts.

Source tests, fresh Godot receipt, exact count/value checks, screenshots, browser validation and diagnostic limits are recorded in `doc/space/gaussian-review-2026-09-12/README.md`. No headset or Quest-performance verification is claimed.
