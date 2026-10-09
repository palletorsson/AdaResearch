# QFEP development: requisite variety and entropic morality

14 September 2026 · Concept development and documentation. No runtime or curriculum configuration changes are part of this contribution.

The [essay, **Q: An Entropic Morality**](entropic-morality.md), develops the user's [original bilingual draft](source-entropic-morality.txt) in relation to the project's [Queer-Q and Self-Q](../../ENTRY.md#the-self-q-recursive-qfep). The original is preserved verbatim, including its opening conversational sentence. The essay is an editorial development, not a literal translation or an already established scientific account of QFEP.

The central proposal is that **Q keeps models and their authority revisable while protecting the capacities of those they leave out**. It adds responsibility for irreversible loss to the existing questions about compression, exclusion, and the maker's own formation.

**Svensk kärnformulering:** Q betecknar en praktik där modellens gränser kan omprövas och där det som modellen lämnar utanför får fortsätta leva, verka och förändra villkoren. Modellering sker inom relationer; den förutsätter inte ett avskilt inre subjekt inför en yttre värld. Ömsesidig hjälp blir ett sätt att upprätthålla delad handlingsförmåga, med ett uttryckligt etiskt åtagande inför andras liv. Bevara möjligheten till framtider som ännu inte kan modelleras. Modellens ofullständighet är inte i sig ett tillräckligt skäl för oåterkallelig förstörelse.

**How the argument was developed.** The essay preserves the draft's connection between limited models, requisite variety, mutual aid, intelligence, and future possibility. It distinguishes omissions in a model from destruction in the world; relevant response variety from arbitrary difference; and uncertainty from the conditions that allow different lives to continue. The ethical commitment is explicit. Mutual aid is a proposed practice supported by that commitment, rather than a theorem deduced from Ashby. Greater intelligence creates no guarantee of moral concern. The draft's Marxian comparison remains an analogy about capacity and its social organization.

**Reading the existing formula.** This contribution does not add a numerical Q term or replace `QFE = F − λE(S) + φΔE(S,t)` with a new law. It proposes questions to ask of the existing vocabulary:

| Term | Question developed here |
|---|---|
| `F` | Whose predictions or conditions of persistence are being served, and can a better score conceal harm elsewhere? |
| `E(S)` | Which states and probabilities does this measure include, and which differences remain outside its alphabet? |
| `λ` | Who can change the weighting, and whose possibilities are traded away by doing so? |
| `φΔE(S,t)` | Which changes permit recovery, and which remove the conditions for later revision? |
| `Q`, as a practice | Can affected participants challenge the variables, boundaries, and objective themselves? |

A quantitative experiment must separately specify its state space, probability estimates, time interval, units or normalization, and whether QFE is being minimized or maximized. A finite difference `ΔE` becomes a rate only when divided by an interval. With fixed terms and minimization, positive `φ` increases the cost of positive `ΔE`; the sign alone cannot establish that a system welcomes change. Shannon entropy, thermodynamic entropy, variational free energy, and political freedom must not be treated as interchangeable quantities. The formula remains an exploratory project construction until an explicit model and evidence support more specific claims.

**Grounding in the repository.** Two existing instruments offer concrete starting points. These observations were checked in source; no live Godot review was performed for this writing task.

- The [Shannon entropy meter](../../../commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.gd) computes symbol-frequency entropy. Its ledger presentation has a SORT operation that rearranges a copy of the sequence without changing the histogram or this entropy. This is an existing way to encounter what a measurement leaves out. It does not itself measure ecological resilience or moral value.
- The [QFEP reactor](../../../commons/interfaces/qfep/qfep_reactor.gd) explicitly uses a simplified visualization: `_calculate_qfe()` sets `F = 1 − λ`, the entropy contribution to `0.8λ`, and the rate contribution to `0.2φ`. It does not estimate a distribution or an entropy derivative. Its `is_at_edge()` checks `0.3 < λ < 0.5`. This interval is authored into the demonstration; it is not empirical evidence for a universal range in which life exists.

**Proposed teaching encounters.** These are development sketches, not implemented features or approved simulation results.

1. **Change what is counted.** Build on the entropy meter's preserved sequence and sorted copy. Let a learner select between single-symbol counts and ordered pairs, then inspect which differences each instrument detects. Keep the original sequence available. The encounter tests whether the learner can distinguish a change in representation from a change in what is represented. Ordered-pair measurement and the selection control would be new work.
2. **Respond together.** Give two stations complementary observations and actions over a shared process. Compare isolated operation, forced control by one station, and negotiated cooperation under an unfamiliar disturbance. Keep resource budgets and disturbance sequences comparable. Vary delay, overlap, and disagreement so cooperation is not guaranteed to win by construction. Record whose needs are met and who can refuse a decision, alongside task performance. The model can test response capacity under its assumptions; its results cannot prove the moral necessity of mutual aid.
3. **Encounter the cost of an apparently successful simplification.** Let a local controller improve its score by removing a route that currently appears redundant. Change the disturbance so the retained route becomes unavailable. Compare retaining alternatives, adding a protective boundary, and restoring a previously removed route. Show the assumptions under which each intervention helps or fails. A reset can restore the teaching simulation, but the encounter should distinguish that convenience from actual ecological recovery. New route dependencies and restoration behaviour would need implementation.

The [QFEP Introduction](../../../commons/maps/QFEP_Introduction/critical.md) can frame the model's selectivity; the [Sandbox](../../../commons/maps/QFEP_Sandbox/map_data.json) can host experiments with who may change its assumptions; the [Synthesis](../../../commons/maps/QFEP_Synthesis/critical.md) can return to the responsibility accompanying increased power. These are candidate connections. Existing map text and configurations have not been rewritten.

**The Self-Q questions applied to this contribution.** It makes the distinction between knowing, controlling, and sustaining others easier to discuss. It could also foreclose action if preservation becomes an absolute injunction, or turn difference into a resource for the strongest participant. The essay therefore includes harmful continuity, losses from inaction, refusal, and the need for protective boundaries. Its remaining uncertainty concerns how to decide what must be retained when resources are finite and affected parties disagree. Neither an entropy reading nor a claim to superior intelligence settles that question.

**Questions to carry forward.** How can participants contest the definition of a successful outcome? How can an encounter expose its own designed assumptions? What counts as repair when restoring a saved state cannot restore a history? What responsibilities follow when some affected beings cannot participate in the decision? These require further conceptual and experimental work, not additional universal constants.

Primary sources for the scientific distinctions and the account of mutual aid are linked beside the relevant claims in the essay: Ashby (1956), Shannon (1948), Spade (2020), Elmqvist and colleagues (2003), and Friston, Thornton, and Clark (2012). The synthesis and proposed ethical principle are this project's argument.
