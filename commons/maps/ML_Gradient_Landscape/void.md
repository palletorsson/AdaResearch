# ML_Gradient_Landscape — Three Meanings of Error

*Floor 177 · Care Unit Model B's working chapter (`void.md`, building on `final.md` and `walked.md`)*

---

## 1. Standing on the parameter plane

On Floor 177, the room spells its two separate decisions directly onto the walls: **SCORE** and **FOLLOW**. At `one-line-three-errors`, the floor itself is the plane of candidate lines — walking east increases slope, walking north increases intercept. Where Model B stands selects one straight plank suspended among five observation posts to the north, with red vertical sticks measuring each residual.

Without moving a single observation or changing the candidate line, three bars beside the posts assign that exact same line **three different errors**:

- **Squared error (blue):** penalizes large residuals quadratically — one distant point dominates the entire sum.
- **Huber loss (green):** quadratic near zero, linear far out — dampening the pull of a single extreme residual.
- **Wavy loss (pink):** adds a periodic ripple to the quadratic bowl, creating local valleys where downhill movement can stall.

Three arrows lie at Model B's feet, one per rule, pointing one gradient step downhill. Walking along one arrow follows that definition of improvement while the other two turn beneath you.

## 2. One unusual point, and the step that overshoots

Flip **OUTLIER** from `off` to `on`: only the fifth observation rises from `0.7` to `4.7`. On the exact clean-fit line (`slope = 0.5, intercept = 0.2`), squared error and its gradient jump sharply higher than Huber's, pulling the learner hard toward that single point while Huber holds closer to the remaining four.

Then flip **STEP** from `short` (`0.5`) to `long` (`1.2`): the direction still points downhill at your feet, yet the longer step leaps straight past the valley and lands at a *higher* error than where you began — turning the arrow tip red. Choosing a score (**SCORE**) and choosing how aggressively to follow it (**FOLLOW**) are two separate judgements.

*A small mistake can change my next attempt.* — Stand on one candidate line, compare Squared, Huber, and Wavy errors on the same observations, flip OUTLIER to see how one point pulls them apart, then lengthen STEP to watch a downhill step overshoot.

## 3. Who is the outlier?

Beside the floor plane stand `loss_function_comparator` (three rolling marbles on rescaled surfaces), `gradient_descent_visualization` (both bowl and `plateau` basins), and `void_ml_pca` (flattening a point cloud onto dominant axes). Together they expose the political question hidden inside every loss function: **when one observation sits far from the majority line, is it a broken sensor, a rare event, or a body whose reality the consensus fit erased?** No mathematical loss can decide that for you — squaring it lets one anomaly hijack the fit; dampening it can silence evidence that mattered most.

## 4. What carries downward

Carrying this question into the lower tower (`F203 SpeculativeComputation_Situated_Computation`): if changing the scoring rule changes what counts as an improvement on the exact same observations, what happens when four witnesses stand in different places and write four incompatible accounts of the same event?

---

*Verified Ghost Student Spine Stop #8 receipt: `doc/book/iterations/2026-11-21-ml-three-errors/checks.json` (`01-f177-overview.png`, `02-outlier-off-short.png`, `03-outlier-on-short.png`, `04-outlier-long-dual-hud.png`).*
