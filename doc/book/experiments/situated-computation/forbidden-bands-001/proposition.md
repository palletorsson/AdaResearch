# A verdict earned off the body

**State: PROPOSED — nothing has run under this record; the dish exists in the working tree and stands in this hall as an uncommitted placement made 2026-10-13, and the hall texts predate it and do not mention it.**

This companion binds two passages of the Situated Computation hall to the [forbidden_bands dish](../../../../../commons/artifacts/forbidden_bands/forbidden_bands.gd), modelled on the [seed-bench pilot](../../random-definition/seed-bench-001/proposition.md) under the [recursive architecture](../../../RECURSIVE_ARCHITECTURE.md). The pilot has since executed; this record has not. The exact bound source versions live in [the record](./experiment.json). The placement token `forbidden_bands:0:0.95` sits uncommitted in the hall's [map_data.json](../../../../../commons/maps/SpeculativeComputation_Situated_Computation/map_data.json).

The [tutorial](../../../../../commons/maps/SpeculativeComputation_Situated_Computation/tutorial.md) says: "Their verdicts and percentages are supplied by their configuration. They do not measure the approaching player." It initiates the question whether a readout's verdict can be earned by measurement instead of supplied by configuration — and whether a learner can reconstruct that verdict by hand, before the run, from the apparatus's published constants, so the printed azimuth is a prediction they made rather than a number they were handed.

The [final](../../../../../commons/maps/SpeculativeComputation_Situated_Computation/final.md) says: "The creature is still hunting. Keep the two encounters distinguishable: an assigned judgement on a screen, and a rule that acts on a body. What would we need to observe before calling either one dangerous?" It initiates the question of what observation separates a constraint that actually refused the body from one the body never met, and which control condition must be witnessed before the red bands may be called forbidding at all.

The proposition is conditional: **if two settled runs of the same dish differ only in the bands export, then the signed difference between their rest azimuths is a refusal measured off a body — a verdict earned, where the hall's four readouts are supplied.** This operational mapping is one reading of the passages, not their definitive literary meaning.

## Competing interpretations

**`forbidden-bands.interp.control-first`** (final). Attribution-by-control on the bands export. Control: bands="none", lean="firm" — after `is_settled()` returns true, read `at_rim()` and `rest_azimuth_deg()`; the control earns the later claim only if the ball rests at the rim near azimuth 0, the plate's RESTS DOWNHILL branch. Condition: bands="pair", lean="firm" — read `rest_azimuth_deg()`, `on_band()`, `nearest_band_edge_deg()`. The band is forbidding iff the rest azimuth leaves the pair arc centred at 14.0 deg (half-width 28.0 deg, from `_band_arcs()`) while `on_band()` is false: refusal measured as the control-to-condition angular difference. *Assumes:* the fixed-step accumulator (FIXED_H = 1.0/240.0) makes the two runs integrate identically regardless of engine tick rate — the script's own stated claim, assumed, not evidence; the deliberate 14-degree offset of the arcs breaks the knife-edge symmetry the same way every run, so one condition run is representative; `is_settled()` true without the timeout suffix means a genuine rest. *Excludes:* the belt value and the ON THE FORBIDDEN branch; varying lean; headset legibility of the plate and the hall's creature; any claim that the deflection equals a particular number — only that it exits the band's sector.

**`forbidden-bands.interp.verdict-vocabulary`** (tutorial). The tutorial's presentation-versus-stored-data lesson (its `read()`/COVER/REVEAL deep-copy discipline) applied to the dish's own two layers: the Label3D plate text built by `_verdict()` is presentation; `rest_azimuth_deg()`, `rest_rho_m()`, `on_band()`, `at_rim()` and `nearest_band_edge_deg()` are the stored, probe-readable claim. A verdict counts as measured iff the azimuth printed in the plate's RESTS CLEAR / RESTS DOWNHILL / ON THE FORBIDDEN strings equals `rest_azimuth_deg()` recomputed from the settled shell, and the plate's colour choice agrees with `on_band()` and `at_rim()`. The hall's four readouts fail this test by design; the dish is the proposed counter-exhibit. *Assumes:* the readable methods are the authoritative record, as the tutorial treats `claims.records` over the returned view; `_verdict()` and the methods read the same settled state (physics stopped at settle). *Excludes:* whether the deflection is physically correct — only whether display and record cohere; timing questions except as a precondition; the hall's situated_readout code, which is neither compared against nor modified.

**`forbidden-bands.interp.foreclosure-gradient`** (tutorial + final). "A rule that acts on a body" as a threshold question on the lean export: at which of {"level", "faint", "firm", "steep"} is the band rule ever consulted? The minimum of K\*rho^2 − S\*x sits at x = S/2K, interior unless S > 2\*K\*R = 0.288. "level" (0.0) and "faint" (0.12) predict a rest short of the rim with `at_rim()` false and the bands never met — "level" at the centre (predicted `rest_rho_m()` 0.0, under `_verdict()`'s 0.05 m threshold: the CENTERED branch), "faint" at a predicted 0.0667 m, interior but above that threshold, so the predicted plate branch with bands present is RESTS MID-DISH — while "firm" (0.34) and "steep" (0.55) predict the rim as the constraint. Sweep lean with bands="pair": the prediction is that the rule exists at every lean but acts on the body only past the threshold. *Assumes:* the point-mass paraboloid arithmetic classifies interior versus rim despite ignoring the shell's ball_radius 0.06; GRIP 0.12 does not hold the ball interior at firm or steep. *Excludes:* the exact deflection azimuth at firm or steep; varying bands ("pair" is fixed); the belt's no-escape geometry and VR encounter quality.

## Bounded comparison

**Baseline (control):** bands = "none", lean = "firm". Prediction — labelled a prediction, nothing has run under this record: the ball reaches the rim and rests straight downhill; `is_settled()` true, `at_rim()` true, `rest_azimuth_deg()` near 0, the plate's RESTS DOWNHILL branch.

**Single change:** bands: "none" → "pair" — the only edited export. Prediction, equally labelled: the rest azimuth exits the pair arc centred at 14.0 deg with half-width 28.0 deg, `on_band()` false, the RESTS CLEAR branch; the signed difference from the baseline azimuth is the measured refusal.

**Held fixed:** lean = "firm" (LEANS value 0.34); dish_radius = 0.16 and ball_radius = 0.06 (export defaults); show_readout = true; dish_color, band_color, ball_color and clear_color at export defaults; all script constants — DISH_K = 0.9, BAND_DEPTH = 0.06, BAND_H = 0.05, SUBSTEPS = 4 (declared at line 74 but never referenced by the current fixed-step loop), GRIP = 0.12, SETTLE_EPS = 0.0001, SETTLE_TICKS = 45, TIMEOUT_TICKS = 1200, FIXED_H = 1.0/240.0; the drop point `Vector3(0, ball_radius + 0.02, 0)` from `_rebuild()`; the hall placement token and rotation (`forbidden_bands:0:0.95`); the engine physics tick rate — the accumulator's rate-independence is relied on as an assumption only, covered by the 60/90 Hz gate named in the learning debt.

## Invented arithmetic fixture

This is an invented hand calculation, not output. It uses constants from the artifact's `.gd` alone — DISH_K = 0.9, LEANS = {level 0.0, faint 0.12, firm 0.34, steep 0.55}, dish_radius = 0.16, BAND_DEPTH = 0.06, `_band_arcs()` for "pair" = [[14.0, 28.0], [194.0, 28.0]] — and none of the registry's descriptive numbers or past probe results. The ball is treated as a point on the tilted paraboloid y = DISH_K \* rho^2 − S \* x; ignoring the shell radius is deliberate and logged as debt.

Interior minimum along the downhill axis (z = 0): dy/dx = 0 at x\* = S / (2 \* DISH_K) = S / 1.8; interior iff x\* < dish_radius = 0.16, i.e. iff S < 2 \* 0.9 \* 0.16 = 0.288.

- level (S = 0.0): x\* = 0.0 / 1.8 = 0.0000 m → interior; predicted CENTERED, rim never consulted.
- faint (S = 0.12): x\* = 0.12 / 1.8 = 0.0667 m → interior (0.0667 < 0.16); rest short of the rim, bands never met — and since 0.0667 m exceeds `_verdict()`'s 0.05 m CENTERED threshold, the predicted plate branch with bands present is RESTS MID-DISH, not CENTERED.
- firm (S = 0.34): x\* = 0.34 / 1.8 = 0.1889 m → past the wall (0.1889 > 0.16); the rim is the constraint.
- steep (S = 0.55): x\* = 0.55 / 1.8 = 0.3056 m → past the wall; the rim is the constraint.

Clear-arc preference at firm + pair: band face radius = 0.16 − 0.06 = 0.10. Point A, downhill axis at the face: y_A = 0.9 \* 0.10^2 − 0.34 \* 0.10 = 0.009 − 0.034 = −0.0250 m. Point B, rim at the band's near edge, azimuth −14 deg (the pair arc spans −14 to +42): x_B = 0.16 \* cos(14 deg) = 0.16 \* 0.9703 = 0.15525, y_B = 0.9 \* 0.16^2 − 0.34 \* 0.15525 = 0.02304 − 0.05278 = −0.0297 m. y_B − y_A = −0.0047 m: the clear edge is 4.7 mm lower, so deflection out of the band's sector to a clear rest (`on_band()` false) is predicted to be preferred over a park against the forbidden. All of the above are predictions from an invented calculation; no run has occurred under this record.

## What could change the work

- The control run (bands="none", lean="firm") does not rest at the rim near azimuth 0 — `at_rim()` false or |`rest_azimuth_deg()`| large after `is_settled()` — breaking attribution-by-control and showing the point-mass fixture misclassifies the finite shell (ball_radius 0.06, GRIP 0.12).
- Either condition reaches TIMEOUT_TICKS in the hall (the plate appends "(still moving at timeout)", `_timed_out` true): the verdict would be a fact about a timeout, not a rest, and the settle criterion (SETTLE_EPS, SETTLE_TICKS) needs rework before any companion claim.
- Two launches of the same hall settle bands="pair" to different sides or different verdict branches: the 14-degree symmetry break is insufficient in situ, and "where you come to rest is the shape of what refused you" stops being a reproducible answer.
- The hall's map token is found to carry bands/lean values that `apply_grid_config()` silently fails to set (BANDS_SET/LEANS membership checks fail and the dish stays at defaults "pair"/"firm"): the installed encounter then differs from the configured one and the comparison must move to a bench scene.
- final.md's own proposed next experiment (panels revealing "a distinct criterion and the observation it used") is implemented, changing what the bound passage asks and possibly superseding the dish's role as the hall's only earned verdict.

## The seven-step cycle, as planned future work

1. Capture the control run with receipts: command, build, physics tick rate, settle status and the raw readable-method outputs.
2. Change only the bands export to "pair" and re-run; no other export, constant or placement moves.
3. Compare the two rests separately as machine record (azimuth, rho, `on_band()`, `at_rim()`) and as a visitor's account of what refused what.
4. Keep an independent copy of both runs' outputs beside this record's identity.
5. Replay the condition: a second launch settling to the other side or another branch triggers the reconsideration above, not a quiet reinterpretation.
6. Independent reconstruction: a learner derives the fixture classification by hand from the `.gd` constants before seeing any run, and the printed azimuth is checked against their prediction.
7. Review tutorial and final independently — revise, retain with reasons, or hold an open question — and let the observation, not this proposal, select the next experiment.

## What remains open

- Execution: no bench or hall run has occurred under this record.
- Observation: the [log](observations.md) is empty.
- Both text reviews: [pending](revision.md); neither text is obliged to change.
- Human encounter: no visitor has met the dish through this record.
- Independent reconstruction: nobody has re-derived the fixture or the verdict by hand.

The [text simulation](text-simulation.md) is the authored, hypothetical trace of what execution might show. The learning debt (shell offset versus the point-mass fixture; whether the hall token configures the placed dish before or after `_ready()`; whether the dish answers "forbidding" or only a weaker neighbour of "dangerous") is recorded in [the record](./experiment.json) with its next tests.
