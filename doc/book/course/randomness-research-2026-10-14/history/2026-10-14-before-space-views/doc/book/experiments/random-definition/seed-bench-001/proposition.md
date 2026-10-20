# The same values can become heights

**Original floating-cube proposition, now tested in a scoped scripted cycle.** The current human-directed successor is [fixed-bottom bars](ANCHORED_BARS.md); the original recipe below remains as history. See [observations](observations.md) and [two text reviews](revision.md). Human encounter and independent reconstruction remain open. This companion belongs to Random Definition and the existing Endless Museum. It extends the existing seed lesson through a selected interpretation. It does not replace its colour grids or the tutorial's +1 DRAW comparison.

The [source passage](../../../../../commons/maps/Random_Definition/final.md) says: “A picture needs one more agreement. Here, three successive draws supply the red, green and blue amounts of a cube.” Its exact source version is bound in [the record](experiment.json).

Our new proposition is conditional: **If the same retained values are also assigned to height, what changes in the encounter while the sampled data stays fixed?** The operational mapping below is one reading of that question. It is not its definitive literary meaning.

Two texts initiate this pilot. The [tutorial](../../../../../commons/maps/Random_Definition/tutorial.md) already asks the reader to exchange red and blue assignments while keeping the same requests: what can we reconstruct and explain when values change jobs? The final asks what else the apparatus could allow: does assigning height change how we encounter the same retained arrangement? Both exact passages are bound in the companion. Either text can originate a later experiment independently.

Before testing, name what could change the work: a reconstruction failure may require a tutorial revision; correct geometry with no useful perceived difference may leave the final's question unresolved or suggest another interpretation. A technical fault and an uninteresting encounter are different findings. We will review both texts without demanding that both change. The user has selected this 48-value comparison as the first planned pilot; its native execution is now recorded, while the human stages remain future work.

## Bounded comparison

Keep forty-eight scalar values in their original order, grouped as sixteen triples. Capture them once, with seed, generator/build, before/after generator states and draw order. Do not reseed or draw when switching interpretation. Retained-value replay must work even if a later generator implementation changes.

Use a pilot-local 4×4 XZ grid with row-major index `i = 4 * row + column`, fixed 0.10 m spacing and 0.04 m cube sides. Both modes use this layout, the same cubes, camera/light/host transform and RGB values. The shared base centre height is 0.10 m above the study origin. The proposed height span is 0.30 m; these dimensions are design choices, not comfort measurements. Mount the study in the museum only after checking the available bay. Do not move the installed vertical grids to create it.

| Interpretation | Mapping for cell `i`, triple `(a, b, c)` | What remains fixed |
| --- | --- | --- |
| A: RGB with fixed height | `RGB = (a, b, c)`; local centre `y = 0.10 m` | All 48 values, roles/order, XZ positions, cube size, lighting and host |
| B: the same RGB, height from the triple | `RGB = (a, b, c)`; local centre `y = 0.10 m + 0.30 m * (a + b + c) / 3` | The same conditions as A; only the height rule changes |

This uses all forty-eight values in both mappings. The mean deliberately loses channel order: two differently coloured triples can have the same height. We keep RGB visible in B to avoid changing colour and height together. Replacing RGB with neutral grey is a separate future rendering trial. Changing the three-value mean to one selected channel is another possible interpretation, with its own ID and explicit omissions.

The cubes remain independent display objects. This test introduces no force, connection, collision rule or cloth model. A viewer's shadow or occlusion may change as a consequence of height; record that consequence, not a claim that perception was held constant.

## Prediction and possible failure

Predict which cells will share a height and which features the observer will notice. [The text simulation](text-simulation.md) is a hypothetical account. An observable geometry change, an unchanged judgment, a meaningful question and an implementation failure are all possible outcomes. There is no required preference for B.

For an independent arithmetic reference, use an explicitly invented fixture containing sixteen triples: zeroes; ones; `(1, 0, 0)`; `(0, 1, 0)`; then twelve triples of `(0.5, 0.5, 0.5)`. The proposed formula yields heights `0.10`, `0.40`, `0.20`, `0.20`, then twelve times `0.25` metres. The red and green triples give different colours at equal height. These were the pre-run calculated expectations, not promised values of seed 42; the native probe has now confirmed this explicitly invented fixture.

## Complete cycle and writing return

1. Capture the 4×4 baseline and predict the consequence of B. Keep raw values and the exact procedure.
2. Switch only the height rule, without an RNG call or a mutation of the retained baseline.
3. Compare per-cell state and the visitor's account separately. Record what changed, did not change or failed.
4. Keep an independent copy with configuration, values, mapping version and relevant state; test export/import/clear where promised.
5. Replay from retained data; compare within the declared build/tolerance. Restoring data does not acquire new randomness.
6. Independently reconstruct the complete printed continuation, starting from the declared seed lesson. Record assistance. Automation and a human attempt are separate evidence.
7. Use the observation to propose a next interpretation, apparatus edit or changed question. Review tutorial and final independently: revise, retain with reasons, or preserve an open question. Record the evidence behind each decision and any successor version. W005 then decides whether to continue, redirect, defer or stop further work; the sleeve is not automatically next.

Tests must detect a draw spent on a mode switch, an aliased kept record, a wrong triple/index or a changed baseline after import. Runtime stability, scene loading, performance and physical VR use remain separate. The actual experiment must supply its scene, probe, runs and evidence before any passing claim.

Main task .003 and writing tasks .001–.002 own this pilot; W005 records its consequence for the plan. The broader opening-order A/B trial uses distinct IDs and conditions. It must not be conflated with this A/B height comparison.

The arithmetic comparison is largely predictable. It first tests the research method and the ability to reconstruct and question it. A subsequent experiment should follow an actual observation, disagreement or reconstruction difficulty. No unexpected discovery or second run is claimed by this proposal.
