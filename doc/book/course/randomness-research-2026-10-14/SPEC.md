# Randomness: from explanation to shared experiment

**14 October 2026 · Local specification · ready-for-agent (planning input)**

The author requested an audit of the current randomness/noise halls, a proposed sequence using existing and new artifacts, a particle tutorial path, and final writing developed from the supplied research map. This document uses the `to-spec` process. The author explicitly accepted the seven-step experiment cycle and three verification levels recorded below. Hall order, new room names and apparatus designs remain **proposals**, not decisions attributed to the author or instructions to change the live museum immediately.

The existing repository task tracker is the publication destination: [task issue](../../../tasks/randomness_research.json). Its existing open/blocked/done vocabulary is retained. `ready-for-agent` means this specification is usable as planning input; the implementation tasks depend on the route-review task. No external issue tracker is assumed.

[Hall order and artifact decisions](HALLS.md) · [Particle tutorial path](PARTICLE_PATH.md) · [Final-text draft](FINAL.md) · [Complete current inventory](INVENTORY.md) · [Source findings](FINDINGS.md) · [Original supplied text](SOURCE.md)

## Problem Statement

Ada already contains a substantial collection of randomness and noise encounters. The current route can teach a sequence of mechanisms without giving an observation a way to alter the next experiment. A visitor can change many parameters while remaining inside possibilities chosen in advance. Calling that openness does not make the grammar revisable.

The author wants learning and artistic research to share a world. AI changes the time and effort needed to produce an implementation; it also makes inspection, comparison, responsibility for an interpretation, and deciding what to build next more consequential. Ada must support established knowledge and experiments whose outcomes and value are not known beforehand. It must allow an uninteresting, failed or ambiguous experiment to remain an honest result.

The supplied text is a source for final writing. It is not a script to distribute unchanged across eighteen subject labels. The world and its text should gradually give the visitor more power to frame a question, choose an intervention and reconstruct the apparatus.

## Solution

Propose an **18-stop research route in eight movements**, using **15 existing hosts and three new halls**, with twelve existing randomness/noise halls retained as connected side visits. Two existing hosts are later returns to Procedural Generation and the QFEP Laboratory; their prerequisites remain visible. This is a proposed route across the museum, not an automatic replacement of its 25-sequence spine.

Build a **seven-stop particle branch** from five existing particle halls, one proposed field laboratory and the shared rule workshop. The learner carries one small particle model forward. The museum's richer artifacts are comparison material; copying all their machinery is not a prerequisite for asking a question.

The recurring object is an experiment record. At first it preserves a colour arrangement. It later preserves a population, a field, a trajectory, a boundary policy and a rule revision. A record changes what can be compared; it does not stand in for the experience of being there.

The first implementation should be a small complete encounter at the existing seed bench: baseline → one changed interpretation → retained result → replay → independent reconstruction → proposed further change. Expand only after that encounter gives us useful evidence about the method.

## User Stories

1. As a visitor, I want to encounter a work before reading its mechanism, so that my attention can begin with something I notice.
2. As a visitor, I want to record a baseline and its parameters, so that my comparison has a stated starting point.
3. As a visitor, I want to change one condition while retaining the others, so that I can investigate a consequence.
4. As a visitor, I want two results to remain visible together, so that the second does not erase the first.
5. As a visitor, I want to keep a result I find interesting, so that the apparatus's score is not the only selection criterion.
6. As a visitor, I want to keep a failed or inconclusive attempt, so that an experiment need not pretend to have succeeded.
7. As a visitor, I want to know whether REPLAY restores an outcome or samples something new, so that these operations cannot be confused.
8. As a visitor, I want to see what a saved record omits, so that a successful replay does not promise the return of an entire encounter.
9. As a learner, I want to reconstruct an experiment from the tutorial and its declared prerequisites, so that I can investigate outside the production artifact.
10. As a learner, I want each particle lesson to extend my preceding program, so that growing complexity remains traceable.
11. As a learner, I want to change the emitter without silently changing existing particles, so that I can distinguish birth conditions from later dynamics.
12. As a learner, I want to compare a stochastic step with motion in a fixed field, so that both are not called random motion without qualification.
13. As a visitor, I want to change boundaries while preserving the incoming trajectory, so that confinement and disappearance become explicit choices.
14. As a visitor, I want to carry a named result to a specified receiving hall, so that cross-hall continuity is an observable capability.
15. As a visitor, I want a receiving hall to explain an incompatible record, so that failed transfer does not quietly substitute a different experiment.
16. As a maker, I want to change what a sampled value controls, so that more samples are not the only way to enlarge a work.
17. As a maker, I want to revise a connection rule and retain its predecessor, so that structural transformation can be compared and reversed.
18. As a researcher, I want observations to create questions and follow-up changes, so that the learning route can develop knowledge we do not already have.
19. As an author, I want measured findings, interpretations and proposals to remain distinguishable, so that speculative QFEP work does not become an unsupported scientific claim.
20. As an author, I want to preserve the current halls and their reasons while reviewing a new order, so that a proposal does not erase working material.
21. As a collaborator using AI, I want model/version, assistance and intervention choices recorded where relevant, so that generated explanations and code can be examined.
22. As a visitor, I want seated and standing interactions, readable comparisons and a clear exit, so that uncertainty in the experiment does not mean uncertainty about operating the room.
23. As a researcher, I want runtime, headset and human-learning evidence reported separately, so that one passing script cannot certify all three.
24. As a visitor, I want to return to the first instrument with a revised question, so that the last hall opens another investigation.

## Implementation Decisions

### Agreed direction

- The supplied research map grounds the final prose. Existing scene behaviour grounds claims about what the visitor can presently do.
- The route develops from explaining known operations toward examining and revising conditions of possibility. An open question is a legitimate outcome; novelty, pleasure or transformation is not guaranteed by a random process.
- The primary verification follows the author's seven steps: establish and record a baseline; change one condition; observe and compare; preserve a result and relevant state; replay; independently reconstruct; use the observation to propose or implement a further change.
- Three verification levels remain distinct: artifact, experiment cycle, and specified cross-hall integration. Scene loading, stability, performance and VR interaction are separate checks.
- Stored-outcome reproducibility and acquisition of a new unpredictable outcome are different operations with different evidence.

### Proposed architecture and interfaces

1. **Preserve the current museum as the baseline.** Build the research route as a reviewable manifest first. A later integration task must reconcile spine, museum route generation, sequence metadata, portals, teaching prerequisites and prose handovers. Renaming a hall in a plan does not change its runtime identifier.
2. **One small experiment record, introduced by use.** Start locally at the seed bench. Store schema version, experiment and parent IDs, source provenance, generator/version, seed and captured generator states, sampled values when needed, draw roles/order, parameters, simulation step and tick, entity state, boundary policy, rule/interpreter version, ordered interventions and the visitor's observation. Include dependency/engine/build identity for replay claims. Do not build a museum-wide persistence framework before the pilot needs one.
3. **Two comparisons.** SAME RECORD changes interpretation without spending new draws. SAME CONDITIONS, NEW SAMPLE investigates repeated trials. Changing distribution may need a declared sampling adapter; equal seeds alone do not guarantee matched variates if algorithms consume different numbers of draws.
4. **Three replay promises.** Exact data replay reconstructs a retained record; deterministic simulation replay is scoped to a declared build, fixed step and ordered inputs; a fresh physical/network acquisition is a new observation. A screenshot can document appearance but cannot reproduce a simulation. GPU/physics display similarity must not be labelled exact replay without evidence.
5. **Freshness is disclosed.** The opening's saved atmospheric seed remains available offline with its provenance. A crypto source would generate bytes through the engine's secure API. A Quest timing probe would record measured intervals and limitations. Simulated quantum/thermal/atmospheric values must be labelled simulations. A changing number or histogram is not an entropy-source certification.
6. **A staged particle model.** Reuse the visible point and declared input infrastructure, then introduce explicit particle state, a fixed simulation tick, local random streams, birth/death records, emitters, lifetime curves, forces, fields and boundaries. Use a small CPU reference population before considering a rendering scale-up. The tutorial model and production artifact remain separately identified.
7. **Cross-hall transfers are named contracts.** Only the links in the hall plan promise a carried record. Unknown schemas and changed dependencies produce an explanation, an explicit migration or a preserved old record; no silent reseeding. Reloading the application is tested only where persistent retention is promised.
8. **Bounded rule revision.** The initial workshop offers visible, versioned rule edits: detached versus connected cells; connect/disconnect conditions; sensor versus moving-body role. It preserves an undoable predecessor. Arbitrary code execution inside the headset is not required. A cloth sleeve is a later investigation, not a promised first implementation.
9. **AI is a collaborator under examination.** Use saved, versioned examples for an initial model-sampling comparison. Distinguish sampling from a fixed model, modifying the prompt, and changing the model/training. The model proposes hypotheses or code; a visitor decides which intervention to perform and interprets evidence. Assistance is recorded; an automated reconstruction does not establish human learning.
10. **Research writing has a feedback role.** Keep a short observation, what remains uncertain, and the next proposed change beside the record. The final text can be revised after experiments. Tests must not require the visitor to endorse QFEP or reach the author's desired interpretation.

### Scientific and artistic distinctions

Keep source, distribution, correlation and constraint separately adjustable and separately named. Distinguish Shannon entropy of a declared variable from variational free energy, physical entropy, algorithmic complexity, novelty and aesthetic value. A finite histogram cannot prove independence, unpredictability or lack of structure. Deterministic chaos is investigated without fresh random forcing in the comparison. Thresholding a field is not by itself evidence of criticality.

Treat QFEP as the author's proposed theoretical and artistic framework. Specify the measured variable, feedback path, viability criterion and intervention before making a claim about entropy modulation. No universal optimum for lambda is assumed. Conventional FEP research already discusses exploration; the distinction is not that established FEP simply forbids uncertainty. A permeability model is not a demonstrated Markov blanket unless the relevant conditional independence is actually specified and tested.

## Testing Decisions

**Approved primary seam: the observable experiment cycle.** Tests use the participant-facing operations and the record they produce. They check a stated contract, not a particular internal class hierarchy. Start with one complete seed-bench encounter; reuse the same test structure as later instruments expose equivalent operations.

| Level | Evidence and acceptance | Explicit limit |
| --- | --- | --- |
| Artifact | Controls affect the named variable; saved copies stay independent; technical labels agree with source and chosen reference fixtures; an applicable deliberate fault is detected. | Correctness does not establish interest, learning or a universal scientific result. |
| Experiment cycle | A baseline, one intervention, a comparison, a retained result, scoped replay, independent tutorial reconstruction and a resulting question/change are documented. An inconclusive result can satisfy the cycle. | A reconstruction by AI or a scripted fixture is an automation check, not independent human comprehension. |
| Cross-hall integration | Each promised sender/receiver pair preserves declared values, state and provenance; incompatible records are handled explicitly; return navigation works. | No general portability claim outside the named links. |

For each completed cycle record whether there was an observable difference, a meaningful question, or a reason to reconstruct the apparatus. Record who made that judgment and why. “No useful difference under these conditions” remains admissible and may suggest a new intervention. There is no numerical score for artistic transformation.

Use the existing exact-printed-code reconstruction practice: declared incoming program plus printed changes produces the program tested. Never fill gaps by importing the complete museum artifact. The independent reconstruction gate is a person attempting the supplied tutorial with assistance disclosed; it remains **not tested** until that occurs.

Useful behavioural fixtures include: unchanged records under rebinning; different adjacency with equal histograms; restoring a consumed generator state; no extra draw during display changes; a particle population cap and simultaneous deaths; fixed-step trajectories across different render cadences; boundary exits counted separately from emission; deposited signals influencing subsequent decisions; deterministic neighbouring trajectories; a changed rule enabling an outcome unavailable under the previous rule. Statistical checks use stated sample sizes and tolerances, not a demand that every larger Monte Carlo sample be closer.

Separately verify scene resolution/loading, bounded memory and object counts, numerical finiteness, long-run stability, measured CPU/GPU time on a declared device, actual headset controller interaction, comfort and accessibility. A scene file existing on disk is not a successful load. A synthetic grab is not a headset test. Establish performance budgets from the target build and hardware in the pilot; do not invent a passing Quest frame rate.

Before accepting a moved hall, review both neighbours' prose and required capabilities. Current handovers explicitly depend on the old order. Source hashes in the inventory identify the inspected working-tree content; old test reports do not automatically apply to later edits.

## Out of Scope

- Automatically deploying the proposed order, adding all new halls, or rewriting every existing tutorial during this specification pass.
- Replacing the whole curriculum spine or deleting satellite works to make a linear route.
- Certifying a physical/quantum entropy source from headset timing or simulated signals.
- Promising bit-identical whole-world physics/GPU replay across arbitrary engines and devices.
- Training a new generative model, making network AI mandatory, or treating AI output as an independent scientific finding.
- Declaring the imagined sleeve, a revisable Markov blanket, general criticality or a QFEP optimum already demonstrated.
- Requiring every visit to generate a novel result, complete a worksheet, or pursue every optional branch.

## Further Notes

The route proposal and particle path specify buildable experiments; they also name what those experiments cannot yet establish. The final-text draft is separate from these implementation instructions. Its voice should become less certain about outcomes as the visitor becomes more capable of altering the apparatus.

Current source findings, especially simulated TRNG labels, the curl-flow replay gap, particle input/persistence gaps and incomplete noise tutorial revisions, must be addressed before those works carry stronger teaching claims. This pass performs a static audit and validates the plan's references. It does not claim fresh runtime, headset or learner results.

Technical references: [Godot 4.6 RNG seed/state](https://docs.godotengine.org/en/4.6/classes/class_randomnumbergenerator.html), [secure random bytes](https://docs.godotengine.org/en/4.6/classes/class_crypto.html), [particle systems](https://natureofcode.com/particles/), [Friston on variational free energy](https://www.nature.com/articles/nrn2787), and [exploration, novelty and surprise within FEP research](https://discovery.ucl.ac.uk/id/eprint/1423327/1/fpsyg-04-00710.pdf). These inform bounded distinctions, not evidence that the proposed Ada experiments have run.
