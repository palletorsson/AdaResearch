# Candidate gem: when variation reaches an edge

15 October 2026. A first numerical probe of Palle's proposed gem-search method. This supplements the 48-value seed-bench pilot; it does not replace that pilot or change an installed artifact.

## Minimal loop

1. **Propose a consequential tension.** Name a capacity of the subject, the condition that makes it consequential, and a consequence worth investigating. A topic or metaphor alone is insufficient.
2. **Build two comparable cases.** Keep the input/state and all unrelated conditions fixed. Change one receiving rule or parameter. Include a condition where the difference should disappear.
3. **Try to defeat the claim.** Replay, return to the baseline, and test a counterexample. If ordinary nonrandom input has the same effect, narrow any claim of uniqueness to randomness.
4. **Judge the encounter.** Can someone notice a difference, make a new use, challenge the explanation or reconstruct the operation? Reject, revise or carry forward the candidate. Technical effects establish feasibility, not artistic significance.

The working card is: **capacity → receiving condition → intervention → consequence → counterexample → next use/question**. “Threshold” can mean a numerical crossing, a rule change, a perceptual transition or a change in who can act. Specify which; do not call all of them mathematical phase transitions.

## This candidate

**Question:** How much of an apparently random movement belongs to the random input, and how much to the rule at the edge?

The apparatus is a one-dimensional point in [-1, 1]. At each of 48 ticks, it adds `gain * (2*u - 1)` to its previous position. The sample is generated once with xorshift32 and seed 42, then reused. This is discrete displacement, not a physical force calculation and not a claim of fresh physical randomness. It is a new standalone sample, not the current Godot bench's runtime sample.

Compare two receiving rules:

- **Clamp:** keep the position at the edge and discard overshoot.
- **Reflect:** fold the overshoot back inside the interval.

For this finite sample the first-contact gain is approximately **0.534621**. It is calculated from the largest absolute unconstrained cumulative displacement. At exact contact the policies still agree; they differ when a step overshoots.

| Condition | Result |
| --- | --- |
| Gain 0.427697, below contact | Neither path reaches the edge. Policies agree within floating-point tolerance. |
| Gain 0.641545, above contact | Both policies record two overshoot events. Their greatest positional difference is approximately 0.477006. |
| Replay the above-contact case | Each recorded path reproduces exactly in this implementation. |
| Return to the below-contact case | The baseline reproduces exactly. |
| Replace the input with constant positive increments | Policies still differ: the effect is not exclusive to randomness. |

The counterexample narrows the claim. We have a working example of a receiving rule contributing to a path, but have not established a distinctive ontology of randomness. A sharper follow-up could investigate how an apparently unbiased input acquires a visible pattern through accumulation and boundary handling. That would need adequate samples and a stated measure before making statistical claims.

## QFEP, edges and leaks

The connection is an inquiry about the receiving conditions: what gets retained, discarded or redirected, who can revise that rule, and what other use the revision permits. This follows the project's distinction between allowing difference to fit and allowing it to affect the terms of the encounter. See [the QFEP afterword](../../afterword-qfep.md).

The next spatial version could show discarded overshoot as a visible trace outside the track. That is a proposed representation, not a result of this numerical run. It would let the visitor inspect something the clamp normally hides. A later intervention might route that remainder into another instrument, giving a discarded quantity a use. Test that separately: adding a receiver changes the apparatus and cannot be credited as a discovery of the first comparison.

Clamping is not inherently oppressive, reflection is not inherently emancipatory, and crossing an edge is not automatically beneficial. The simulation can expose a choice and make it revisable. It cannot settle an ethical judgement by displaying a larger number or a more elaborate path.

## Two texts and a room

- **Tutorial:** reconstruct the update and the two boundary rules, predict their agreement below contact, reproduce the divergence, and test the constant-input counterexample.
- **Final:** proposed movement of attention—follow the point to the edge; attend to the displacement that does not appear; return to the point with a changed understanding of what authored its movement. No visitor response has yet been observed.
- **Spatial arrangement:** proposed paired tracks driven synchronously by the same recorded input, with accessible controls and an optional overshoot trace. Judge whether the distinction can be encountered before requiring the reader to endorse an interpretation.

## Surveying the sequences

Across the 24 sequences Palle names, begin with a candidate survey rather than declaring a gem in every map. For each map inspect the actual operation and offer at most a few candidates. Record the subject, tension, exact artifact/code location, smallest probe, possible counterexample, and any grounded QFEP connection. Allow “no strong candidate yet.” The current pass has not audited all 24 sequences.

A candidate deserves a larger build when the consequence is legible, the subject-specific claim survives challenge, and the result creates an operation, a question or an unintended use worth returning to. A “super gem” is a provisional editorial judgement when the same encounter also exposes and lets us reconsider the conditions under which difference can act. It is not a numerical score derived from the simulation.

## Reproduce

From the AdaResearch_46 repository root:

```sh
node doc/book/experiments/randomness-gem-boundary/probe.mjs
```

The script contains the complete model, assertions and counterexample. It writes [receipt.json](receipt.json), including the 48 source values, both paths, event records and unresolved questions. Mechanical checks pass. No Godot, browser, headset, reader or visitor test is claimed.
