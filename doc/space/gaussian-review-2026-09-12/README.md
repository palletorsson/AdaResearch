# Random Gaussian review — 12 September 2026

Continued from Random Walk. **Next: Random_Mushrooms.** The thread moves from a reflected step to a distribution's retained values, their grouping and the boundaries that absorb them. Headset work remains deferred while Palle is remote.

## Delivered

- [Illustrated, interactive review](http://localhost:3003/research/possible-bodies/random-gaussian.html).
- [Primary and book passage](http://localhost:3003/necklace/thread?map=Random_Gaussian&role=primary).
- Book: `commons/maps/Random_Gaussian/final.md`; tutorial, technical, critical, summary, blurb and intent revised alongside it.
- Production source: `commons/artifacts/distribution_sampler/distribution_sampler.gd`.
- Builder: `tools/build_gaussian_review.py`.
- Helpers: `ada_run/review_gaussian.py`, `write_gaussian_text.py`, `align_gaussian.py`, `verify_gaussian_review.py`, `verify_gaussian_http.py`.

The existing sampler remains the one primary and the book hero. The primary page shows one written card with 820 words; the complete final has 912 whitespace-delimited words. The nine explicit placements, all 14×22 map layers, nineteen raised cells, museum configuration and teleporter floor override are retained. The scene file is byte-identical to the before snapshot. Map changes are descriptive metadata only. All nine placements match and build, with no refusals or extra placements. Generated furniture also appears in the probe's body inventory; that inventory is not the count of map artifacts.

Both plan rows agree. The primary registry changes only the sampler's description and QFEP prose. Existing secondary artifacts remain; the comparator's book note no longer makes a universal Gaussian-convergence claim. The previous Walk review now links here.

## What the book asks the visitor to discover

PAUSE stops new draws while airborne beads still land. CLEAR resets this named sample and preserves paused/running state. BATCH then makes an equal-count GAUSS/UNIFORM comparison possible. Three hundred uniform draws have their own law; adding more does not turn it into a Gaussian law.

The values stay while their account moves. BINS repartitions retained values without drawing again, but the cabinet's mean and deviation use bin centres. Those estimates can change. Blue counts and pale model counts share a scale; the orange ideal shape has a separate scale. A full-height image does not establish how much evidence supports it. Empty VR bars still have a one-centimetre visible baseline.

The numerical procedure has boundaries before the display does. The logarithm guard limits the computed Gaussian component to approximately 4.29 standard deviations. `_fit` then clamps values outside [0,1] and counts them. Retained values lose the overshoot distance. An edge bin also includes interior values, so its count cannot replace the clipping count. The ideal model and the finite implementation are distinguished explicitly.

The code excerpts follow the actions. Ten GDScript excerpts across final/tutorial/technical were checked against the production source. The ending carries the question into bodies without treating frequency under a model as a measure of a person's value.

## Repairs

1. Replaced `log(u + 0.0001)` with a lower guard `log(maxf(u, 0.0001))` in Gaussian and exponential sampling. Previously an input near one could exceed one after addition, causing a negative Gaussian square-root argument or a small negative exponential result. This deliberately changes numerical seeded samples compared with the old offset, while preserving draw consumption. Replay is tested within the corrected implementation.
2. Enforced capacity at issued draws, including airborne beads. At a cap of ten with four airborne, BATCH can accept only six. The automatic loop and manual path use the same limit.
3. CLEAR removes both flight records and marker meshes. Marker cleanup detaches nodes before queued deletion so indices remain coherent.
4. Landing uses the actual rendered bar top, including its baseline, instead of an unrelated count-to-height formula.
5. Kept the orange model curve within 80% of display height using its own sampled peak. Enlarged and raised the existing sign; its legend explicitly separates count bars from the independently scaled shape. Matched captures show the curve inside its frame and the legend clear of it.

No visitor sliders, pause-of-the-whole-museum claim or new primary was added. The button remains labelled PAUSE while paused; pressing it again resumes the automatic stream. There are nine controls in total.

## Independent evidence

Accepted run: **22:49:31–22:50:17 +02:00, PID 37520: 156 checks, zero assertion failures, engine exit 0.** Production fingerprints stayed stable and the original saved hand was preserved. The runner uses an isolated hand copy, superseding inherited probe wording about a real hand. Fresh complete process inventories preceded engine launches; other Godot work was left alone.

The run covers all nine control paths, actual desktop pointer input, access and collisions, routes, unload/rebuild, seed replay, rebinning, ten logarithm endpoint cases, capped long frames, airborne capacity, CLEAR cleanup, landing height and curve bounds. The source test fixture supplies endpoint inputs; it is not a visitor control. The earlier always-true prefix assertion was replaced with a real comparison to the first two hundred retained values. NEW SEED is tested for its guaranteed change from the current seed and repeatability, rather than demanding that two finite histograms differ.

Four common-seed histories contain one thousand values each at seed 31415: UNIFORM, GAUSS, POISSON and EXPON. Twenty frozen prefix snapshots and twelve full-sample rebin snapshots agree with independently reconstructed counts. All values are finite and in range. Expected counts sum to N within tolerance.

None of the four common-seed samples contains clipping. A fifth EXPON history uses seed 1 and has two clipped draws among one thousand. Its selection rule is disclosed: the first seed in 1–20 with at least one clipped draw among a thousand. This is an edge demonstration, not a typical-sample or frequency claim. There are 5,000 retained values in the review.

For the common EXPON sample, the retained-value mean is 0.162196. Its binned estimate reads 0.166 with ten bins and 0.162 with thirty; the retained mean stays fixed. For POISSON the retained mean is 0.335800 while the binned mean reads 0.344 at sixty bins. These discrepancies are available in the review rather than hidden behind the rounded statistic.

Controlled screenshots use the same camera and exact N. The twelve-value image is not presented as evidence of a twelve-draw button. Actual desktop interaction is captured separately: automatic rain can add draws during a live BATCH interaction.

### Superseded attempts

The first 147-check run passed its assertions, but its exported prefix counts shared mutable arrays and later bins overwrote earlier snapshots. It is retained as rejected export evidence under `initial-147/`. Deep-copying every exported state fixes this. Two subsequent harness compile attempts failed: an indentation error (PID 22204, timeout exit 124) and a duplicate local variable (PID 36000, timeout exit 124). These are retained in `export-indent-failure/` and `export-scope-failure/`. The latter's source changed during the failed attempt, so its receipt is not accepted. An attempted termination of that precisely identified owned process failed; its own timeout ended it. No unrelated process was stopped. The runner now detects parse errors in its fresh child log and ends only its owned child promptly. The final successful run supersedes both attempts.

## Publication and limits

All **56 published files** returned HTTP 200 with matching source hashes. Eight browser records verify the initial 12-value histograms, equal N after regrouping, fixed retained means, selected edge disclosure, the 1,000-tick strips with exactly two clipped red ticks on the right, discrete sampling, one-value boundaries, the review's book disclosure and the correct live primary card. All five images load; no horizontal overflow occurs at the tested desktop width. Histogram layout was visually inspected. Individual-value strips and retained-value means are explicitly review-only features.

The WCN audit has 35 maps, 19 active and final text for all. This room's role, book anchor, hero and placement agree. The audit also records **one unrelated mismatch in Noise_Voxel**: two primaries (`perlin_terrain_sculptor`, `voxelnoise`) and only the sculptor book anchor. It is preserved in `other-hall-mismatches.json` for that hall's review; no global zero-mismatch claim is made.

The accepted run has no script errors, parse errors or ObjectDB shutdown leak warning. Audio-UID, certificate-store and logger errors, compatibility-renderer and empty-registry warnings remain in `verification.json`. Generated `david_drape` took 121 ms to build, a recorded performance concern. Small lettering, tracked-hand approach and Quest performance require the later headset visit. Desktop checks do not settle those questions.

Before snapshots, manifests, hashes, source verification, HTTP results and browser observations are stored alongside this file. Runtime outputs remain under `ada_run/gaussian-review-2026-09-12/`. No commit was made. Continue with Random_Mushrooms: which properties of a body are the sampled values allowed to change?
