# Entropy: which differences become consequential?

15 October 2026 · A research thread across the existing maps

**Working hypothesis:** a computational system can generate many variations while allowing only a narrow range of consequences. Entropy gives us several precise ways to investigate those variations, records and constraints. The significance of a difference also requires an encounter: something that changes what a body, instrument or participant can do.

This develops Palle's [2023 proposal](../../../VR_VR_PT_2023.md), particularly its question about sophisticated computation producing standardized forms. The [new supplied proposal](../../iterations/2026-10-15-entropy-across-maps/supplied-proposal.md) is retained verbatim. The earlier proposal remains a historical document; this framework records a refinement, rather than silently rewriting its claims.

## A small, generative loop

Start with an observed tension. The colour reading stays while the arrangement changes. A sphere takes a new route and still returns. Two distinct gestures supply the same seed. Do not require every map to display an entropy meter.

1. **Keep a baseline.** Preserve the actual state, observations, code/version, seed or raw draws, and the schedule needed to reproduce it.
2. **Name the intervention.** Change the world, change how it is recorded, or change what the rules permit. Distinguish these; combine them only when the combined change is itself the question.
3. **Compare one consequence.** State what the instrument measures and what the encounter makes perceptible. An unchanged number can be the finding.
4. **Replay and reconstruct.** Reproduce the saved result, then rebuild the small mechanism from its declared tutorial dependencies. These are separate checks.
5. **Decide what to change next.** Retain the mechanism, revise the account, alter a rule, or stop an unproductive line. Preserve the reason and the contrary evidence.

Use the optional [observation card](observation-card.md) within the existing writing-wall Research loop. A gem remains a candidate until an intervention makes its tension inspectable. Its value is not the size of an entropy increase. A useful result might reveal a previously invisible distinction, expose a limit, or give a specific reason to reconstruct the apparatus. A result may also be inconclusive.

## Keep the quantities distinct

| Account | What must be declared | Useful role in Ada |
| --- | --- | --- |
| Shannon entropy, `H(X)` | Outcomes, probabilities, sampling rule and logarithm base. Bits for base two. | Counts and uncertainty. A balanced checkerboard and a balanced shuffled board both give one bit when X is only the colour of a uniformly selected cell. |
| Conditional entropy and mutual information | Joint distribution of source X and record Y; what the observer knows. | Ask which distinctions a particular record retains. `I(X;Y) = H(X) − H(X|Y)`. |
| Entropy rate | A process, observation alphabet, time unit and dependence on history; assumptions for the limit. | Ask what longer history contributes to prediction. A short one-step statistic is a narrower measurement. |
| Boltzmann / Gibbs entropy | Compatible physical microstates and macrostate, or a probability distribution over physical states. | The two-compartment model introduces multiplicity. Physical entropy uses J/K; its `ln Ω` display is dimensionless. |
| Thermodynamic entropy production | Physical model, system boundary, reservoirs, energy/entropy flows, units and protocol. | A later investigation of what sustains an organization. No existing disorder slider establishes this quantity. |

Shannon's theory distinguishes the distribution of symbols from their temporal dependencies; a histogram cannot stand in for every information-theoretic account. [Shannon, 1948](https://people.math.harvard.edu/~ctm/home/text/others/shannon/entropy/entropy.pdf). Boltzmann counting and Gibbs probabilities require their stated ensembles; our sixteen-site configuration study has no temperature or heat reservoir. [Tong, statistical mechanics](https://www.damtp.cam.ac.uk/user/tong/statphys/statmechhtml/S1.html).

Kolmogorov–Sinai entropy belongs to a specified measure-preserving dynamical system and its partitions. A finite boid trace, divergence between two runs, or a changed timestep does not establish it. For a closed deterministic implementation with finitely many internal states, long-run block uncertainty is bounded by its initial-state uncertainty; its asymptotic information rate is zero. This finite-state deduction does not prevent difficult prediction over a practical observation period. External inputs and a continuum model require their own accounts. [Sinai, definition](https://www.scholarpedia.org/article/Kolmogorov-Sinai_entropy).

At the physical scale, local organization can persist through exchanges with an environment. Thermodynamic claims need a system-plus-environment account; the increase of a coarse-grained statistic need not describe every small stochastic trajectory. [Tong, thermodynamics](https://www.damtp.cam.ac.uk/user/tong/statphys/statmechhtml/S4.html). Prigogine's dissipative structures motivate studying sustaining conditions, not attaching a heat interpretation to every changing pattern. [Prigogine's Nobel lecture](https://www.nobelprize.org/uploads/2018/06/prigogine-lecture.pdf).

Landauer's familiar `k_B T ln 2` bound applies to erasure of one unbiased bit under the standard isothermal assumptions. It is not a conversion factor from Godot operations to measured heat. Runtime or frame count alone does not measure energy consumption. [Landauer, 1961](https://www.cpt.univ-mrs.fr/~verga/pdfs/Landauer-1961uq.pdf).

## Connecting concepts

**Algorithmic complexity** concerns the shortest generating description in a specified universal description system. A practical compressed file length is an encoding result, not an exact Kolmogorov-complexity measurement. Retain its decoder, settings and data representation. This offers a return through fractals and L-systems: an intricate appearance may have a short generative rule. [Vitányi](https://homepages.cwi.nl/~paulv/papers/incomp.pdf).

**Min-entropy** asks about the most probable outcome: `−log2(max p)`. It can accompany the source-distribution question, with no security certification inferred from a short exhibit sample. [NIST](https://csrc.nist.gov/glossary/term/min_entropy).

**Variety and regulation** ask what responses are available for which disturbances. Ashby's framework supplies a way to specify that relation; it does not equate more variation with a better world. [Ashby, An Introduction to Cybernetics](https://ashby.info/Ashby-Introduction-to-Cybernetics.pdf). Diversity measures also depend on chosen categories. Cross-entropy and KL divergence can become later ML comparisons once their reference and predicted distributions are explicit. None of these supplies a score for queer potential.

## What the current artifacts make possible

**Random Return.** Its generated destination changes while its route rule brings the sphere back to its centre. Release can end the carried ride; the participant is not literally forced to complete it. The potential research intervention is to change the return rule and compare the resulting possibilities. Another seed alone does not perform that change.

**MOVE / KEEP.** The current code records quantized position, orientation and elapsed timestamps, hashes the encoded record, and maps part of the digest into 0–999. It also preserves the full sample receipt. The seed channel has at most `log2(1000) ≈ 9.966` bits of entropy under any distribution, with equality only for a uniform one. This is an alphabet bound, not a measured entropy or a judgment about the entire saved gesture. The [collision example](cards/seed-record.md) uses explicitly synthetic records.

**Noise One.** REMAP reads the retained/computable signed field value again. It does not recover negative distinctions from a black pixel alone. For a chain `X → Y → Z` without additional information about X, processing Y cannot increase its mutual information with X. Reaccessing X changes the experiment. [Polyanskiy and Wu, data processing](https://arxiv.org/abs/1508.06025). A four-value fixture makes this distinction exact before attempting a sensor or image estimate.

**Entropy.** The two-compartment bench already compares an invariant colour histogram with changing configuration multiplicity. The prefab study compares intact assemblies with independent mesh motion. Its shared slider gives a useful encounter, but the two modes use different draw assignments: it has not isolated grouping alone. The [prefab card](cards/prefab-disorder.md) records that limitation and a matched-motion follow-up.

The [cross-map plan](cross-map-plan.md) carries these questions into Trace, Pendulum, CA, Swarm, reaction–diffusion and ML. These are candidate returns, with implementation and evidence status attached, rather than additional definitions every final must recite.

## Text and space learn from the same result

The tutorial gives a capacity: construct the mechanism, change one condition, keep enough to reproduce it and propose another operation. The final follows the encountered difference—through objects, bodily consequences and short definitions when needed. Both may initiate an experiment. A numerical fixture belongs in evidence; it does not manufacture a visitor's discovery.

Random Entropy retains its adopted room/final order: ledger → jar → two compartments → displaced points → ruin → signal room. The new prefab comparison is optional. Future spatial changes should follow a question that needs adjacency, return, comparison or passage. Conceptual connections can cross this walking order. The 48-value bench remains the first research pilot.

For QFEP, record the concrete threshold: when does a distinction disappear from a record, a passage stop supporting movement, or an existing rule cease to support the question? Then record whether changing that rule produces a useful difference. Calling this queer potential is an artistic and philosophical proposition to investigate, not an inference from an entropy score or a calibrated QFEP equation.

The framework keeps the original ambition while refining its claim: **computational worlds make some differences operative. Research asks which ones, under what conditions, and what becomes possible when those conditions can change.**
