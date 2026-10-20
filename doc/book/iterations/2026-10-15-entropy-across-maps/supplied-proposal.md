# Entropy as a central concept in Ada Research

I think entropy could become one of the most important conceptual connections across Ada Research. But I would develop it as a family of related scientific ideas rather than a single explanation of disorder, complexity or difference.

Your original 2023 proposal makes a provocative connection between entropy, queer morphology, algorithmic diversity and the tendency of digital systems to reproduce stereotypes. It asks how increasingly sophisticated technology can nevertheless produce increasingly standardized forms.&#x20;

VR_VR_PT_2023.txt



I think that question has become even more interesting in the current project.

The key proposition I would investigate is:

A system can contain enormous computational variation while permitting very little meaningful difference.

Your Randomness hall already demonstrates this. A thousand seeds can produce many different excursions, but none can change the sphere's compulsory return. The computational space is varied; the rules governing its consequences remain fixed.

This points to four recurring questions:

- How many different states or outcomes are possible?
- Which differences can be observed, retained or transmitted?
- How much uncertainty develops as a system evolves?
- What must be constrained, consumed or discarded for a system to maintain its organization?

These questions connect statistical mechanics, information theory, dynamical systems, artistic research and your interest in queer computational worlds. They do not, however, all measure the same thing.

## 1. The most relevant kinds of entropy

| Concept                                    | What it investigates                                                             | Important Ada connections                                 |
| ------------------------------------------ | -------------------------------------------------------------------------------- | --------------------------------------------------------- |
| Shannon entropy                            | Uncertainty over possible outcomes                                               | Randomness, Noise, procedural generation, ML              |
| Conditional entropy and mutual information | What a record tells us, and what remains unknown                                 | Trace, Grid, movement sampling, sensors                   |
| Entropy rate and dynamical entropy         | How uncertainty develops through time                                            | Swarm, Chaos, cellular automata                           |
| Algorithmic complexity                     | How concisely a particular pattern can be generated                              | Fractals, L-systems, procedural worlds                    |
| Thermodynamic entropy                      | Physical states, irreversible processes and energy dispersal                     | Forces, soft bodies, artificial life                      |
| Entropy production and self-organization   | How organized structures are sustained away from equilibrium                     | Reaction-diffusion, artificial life, evolutionary systems |
| Min-entropy                                | The predictability of the most likely outcome                                    | Random-number generation, cryptography                    |
| Variety and diversity measures             | How possible states and their distributions affect regulation and representation | Swarms, agent systems, queer morphology                   |

I would prioritize the first four for the book's existing computational encounters, then develop thermodynamics, self-organization and variety more deeply as the algorithms become complex.

One mathematical starting point is Shannon entropy:

\\[ H(X)=-\sum_i p_i\log_2 p_i \\]

It measures uncertainty in a random variable with specified possible outcomes and probabilities, in bits.

But entropy is always entropy of something, under a particular definition of states and probabilities. Changing what the system distinguishes can change what the number tells us. This issue is central to both information theory and statistical mechanics.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://onlinelibrary.wiley.com\&sz=32)

Wiley Online Library

+1



## 2. Statistical entropy is not the same as complexity

This is perhaps the first important distinction for Ada.

Imagine two surfaces containing equal numbers of black and white cells. One is arranged in a perfectly regular checkerboard; the other has its cells shuffled.

Both have the same Shannon entropy if we measure only the colour of a randomly selected cell: one bit per cell, assuming equal probabilities.

But their spatial organization is very different.

Regular pattern

32 dark, 32 light

Shuffled pattern

32 dark, 32 light

Conceptual comparison. The colour-frequency entropy is the same; the arrangement and spatial correlations are different.

A regular checkerboard can be described by a very short rule. A random-looking arrangement may require much more information to specify exactly.

This leads to Andrey Kolmogorov's algorithmic complexity: the length of the shortest program that produces a particular object or sequence. Unlike Shannon entropy, it concerns an individual description rather than only a probability distribution. Exact Kolmogorov complexity is generally uncomputable.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://plato.stanford.edu\&sz=32)

plato.stanford.edu



This is particularly relevant to Fractals, L-systems, procedural generation and cellular automata.

A tiny rule can produce an enormous, intricate structure. Conversely, a huge collection of uncorrelated noise samples can contain little organization worth exploring.

Ada should investigate not only the amount of variation, but how variation becomes structured, related and consequential.

## 3. Information loss and the entropy of an observation

This is probably the most productive area for your existing artifacts.

Consider three encounters:

Noise_One: Different negative values become the same black colour. REMAP allows those values to become distinguishable again.

Point_Trace: A continuous movement becomes a series of retained positions. The lines between those positions are constructed, not recovered observations.

Randomness — MOVE / KEEP: Many distinct recorded gestures can be reduced to the same seed between zero and 999.

These encounters concern an information-theoretic problem.

Let \\(X\\) represent an original signal, and \\(Y\\) the record made from it. The conditional entropy

\\[ H(X\mid Y) \\]

describes how much uncertainty about the original remains when we know the record.

Mutual information,

\\[ I(X;Y)=H(X)-H(X\mid Y), \\]

describes how much information the two variables share.

In a simple processing chain, once information has been discarded, subsequent processing alone cannot reconstruct which of the original possibilities occurred. This is formalized by the data-processing inequality.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://onlinelibrary.wiley.com\&sz=32)

Wiley Online Library



That gives Ada a very concrete experimental question:

What can the next artifact know about an event that the previous artifact has compressed?

The movement sampler supplies a particularly clear example. A seed chosen from 1,000 possible values can carry at most about 10 bits of Shannon entropy. But a gesture can have an enormous range of trajectories, timings and rotations.

The reduction creates equivalence classes: different movements that become the same input to the subsequent generator.

The interesting artistic question is not simply that information is lost. It is what those lost distinctions could have done if they had remained available.

And importantly, a lossy digital transformation is not, by itself, a measurement of thermodynamic entropy production.

## 4. Entropy rate, chaos and the production of unpredictability

A still image can have an irregular distribution. A dynamical system raises a different question: how does uncertainty about its future develop?

Entropy rate describes the average rate of new uncertainty in a stochastic process, accounting for dependence between successive observations.

In dynamical systems, Kolmogorov–Sinai entropy provides a more specialized measure of information production by dynamics. Positive dynamical entropy can occur in deterministic systems.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://onlinelibrary.wiley.com\&sz=32)

Wiley Online Library

+1



This is especially important for your Swarm Intelligence hall.

Your boids can begin in an identical configuration and diverge when the simulation receives different time steps. The source material already documents this sensitivity.

But different trajectories do not automatically demonstrate positive Kolmogorov–Sinai entropy. That requires an appropriate dynamical and statistical analysis.

An experimental direction would be to compare:

- Identical initial states and identical update schedules.
- Identical initial states with small, documented perturbations.
- The growth of differences over simulated time.
- Whether those differences saturate because of the room's finite boundaries.

This also connects to the Edward Lorenz tradition of sensitive dependence on initial conditions and to Lyapunov exponents, which measure rates of separation between nearby trajectories.

What I find especially interesting for Ada is that a system can be deterministic without being predictably navigable for an observer with limited precision.

And predictability can depend on timescale. A flock may be relatively predictable one frame ahead and practically impossible to forecast accurately much further ahead.

## 5. Thermodynamic entropy: What does it cost to maintain a form?

Here the concept becomes quite different.

Thermodynamic entropy concerns physical states and processes. In statistical mechanics, the Boltzmann expression

\\[ S=k_B\ln\Omega \\]

relates entropy to the number of microstates compatible with a specified macrostate, under the relevant assumptions.

The second law governs the entropy of isolated systems: it cannot decrease in a spontaneous process. A local system, however, can become more ordered while exchanging energy and entropy with its surroundings.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://plato.stanford.edu\&sz=32)

plato.stanford.edu



For Ada Research, this becomes particularly relevant to self-organization and artificial life.

A living organism maintains its organization through ongoing physical processes, requiring energy, exchange and dissipation. Patterns in driven, far-from-equilibrium systems can persist precisely because energy continues to flow through them. This is an important part of the research tradition associated with Ilya Prigogine.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://pmc.ncbi.nlm.nih.gov\&sz=32)

PMC

+1



Your cloth simulation offers a useful model of related questions, but the simulation is not itself a thermodynamic experiment. The solver can dissipate mechanical energy through damping without accounting for physical heat or thermodynamic entropy in the simulated world.

The headset and computer, on the other hand, really do consume energy and produce heat.

That gives Ada two very different experimental scales:

Inside the simulation: What conditions allow a form or movement to persist? What happens when those conditions change?

Outside the simulation: What are the physical energy and computational costs of producing, maintaining and updating that virtual form?

The link between information and thermodynamics also includes Rolf Landauer's principle: logically irreversible erasure of one bit has a theoretical minimum dissipated heat of \\(k_BT\ln 2\\) under the standard conditions. That is a fundamental bound, not a claim that each Godot operation dissipates exactly this amount.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://www.nature.com\&sz=32)

Nature Reviews Physics



This opens a question that could become central to the project's ethical dimension:

What must a system continually consume, transform or release in order to preserve the differences that constitute it?

## 6. Variety, diversity and the queer question

I think this is where entropy becomes politically and philosophically interesting, provided we retain the scientific distinctions.

Your proposal connects the mathematical possibility of variation with a critique of the normative forms produced by algorithms.&#x20;

VR_VR_PT_2023.txt



But it would be a mistake to argue that higher Shannon entropy necessarily means greater cultural diversity, queer potential or freedom.

A system might produce millions of visually distinct faces while reproducing a very narrow range of social stereotypes.

Its pixel-level uncertainty could be enormous, while the distribution of identities, roles or relationships remains highly constrained.

Conversely, a small, carefully constructed space of possibilities might allow a participant to change the governing rules in ways that a much larger generative system does not.

Here I would introduce two neighbouring concepts.

Ecological diversity: Shannon entropy is used to measure distributions across species or other categories. Hill numbers can express that diversity as an effective number of equally common categories. But the measure depends on what categories are distinguished and how their frequencies are sampled.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://pmc.ncbi.nlm.nih.gov\&sz=32)

PMC



Requisite variety: W. Ross Ashby's cybernetics investigates how a regulator's available responses limit its capacity to handle disturbances. The principle is mathematically specific, rather than a general claim that more diversity is always better.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://ashby.info\&sz=32)

REQUISITE VARIETY



These could be brought into conversation with Ahmed, Haraway and Guattari, while keeping their philosophical and scientific claims distinct.

For me, the most promising formulation is:

Queer potential is not a quantity of entropy. It may become possible where the rules for distinguishing, combining and transforming states can themselves be questioned or changed.

The Random Return sphere makes that distinction material. Randomizing its direction increases variation in its excursions. Changing the compulsory return changes the structure of its possibilities.

That is a much stronger artistic argument than calling randomness inherently queer.

## 7. A practical entropy research framework for the maps

I would add an optional entropy reading to the existing artifact research process. Not every map needs a numerical entropy meter.

| Map                                  | Proposed investigation                                                          | What should remain distinct                                          |
| ------------------------------------ | ------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| Random_Definition                    | Measure output distribution and predictability across seeds                     | Random-like appearance versus genuine new entropy                    |
| Noise_One                            | Compare values before and after clipping, remapping and quantization            | Information in the source versus information visible in the display  |
| Point_Trace / Grid                   | Compare retained positions with original movement                               | Representation, sampling and reconstruction                          |
| WaveFunctions_Pendulum               | Compare sampling schedules and their ability to reveal motion                   | Periodic source versus apparent stillness                            |
| CA_ExpandingSpace                    | Compare spatial state, support thresholds and recovery                          | Numerical state versus the possibility of action                     |
| Swarm Intelligence                   | Measure separation of nearby trajectories over time                             | Determinism versus practical predictability                          |
| Reaction-Diffusion / Artificial Life | Investigate pattern formation, persistence and driving conditions               | Simulated organization versus physical thermodynamic dissipation     |
| ML / Evolutionary systems            | Examine probability distributions, selection pressures and loss of alternatives | Statistical uncertainty versus meaningful representational diversity |

One additional concept worth introducing in ML halls is cross-entropy and relative entropy (KL divergence). These quantify predictive performance and differences between probability distributions, not the intrinsic value or cultural diversity of what a model produces.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://onlinelibrary.wiley.com\&sz=32)

Wiley Online Library



For any actual experiment, I would record the quantity being measured, the distribution or ensemble, the observation scale, the intervention, the measured difference, and the claims that the measurement cannot support.

That would help prevent entropy from becoming a universal explanation applied retrospectively to every artifact.

## 8. A conceptual development from the 2023 proposal

There is one sentence in the older proposal I would now refine:

> As we step towards more entropy, noise - information, difference, and diversity increase.

It captures an ambition, but these quantities do not necessarily increase together.&#x20;

VR_VR_PT_2023.txt



Noise can increase uncertainty while making a signal harder to recover. More statistical variety can coexist with fewer meaningful relationships. More data can reinforce existing categories instead of expanding them. A highly organized structure can require continual energy throughput.

I would propose a revised research hypothesis:

> Computational systems produce worlds by making some differences operative and leaving others without consequence. Entropy offers several ways to investigate uncertainty, information, dynamics and the physical conditions under which organization persists. But no single entropy measure tells us which differences matter. The artistic research begins where these measurements meet the actual possibilities of bodies, instruments and environments.

This would keep your original interest in the queer potential of algorithms while giving it a more rigorous foundation.

It also connects directly to the literary method we've been developing. The final text can encounter a difference that the instrument does not preserve, a form that persists under unexpected conditions, or a rule that produces endless variation while preventing structural change.

Those are not illustrations of entropy. They are places where different accounts of entropy, information and possibility can be investigated.

## My recommendation

I would make four concepts central to the next stage of Ada Research: Shannon entropy, conditional information, dynamical entropy and thermodynamic entropy production. Algorithmic complexity and requisite variety would serve as essential connecting concepts.

But I would not organize the book into six chapters about these definitions.

Instead, let the concepts reappear differently as the computational world becomes more complex:

Randomness asks where uncertainty comes from. Trace asks what remains of an event. Noise asks which values become perceptible. Swarm asks how uncertainty develops. Artificial Life asks how organization persists. The later questions of intelligence and agency ask who can change the conditions under which differences become consequential.

The scientific measurements remain distinct, while the artistic investigation accumulates across them.

The larger question for Ada may not be whether entropy increases or decreases. It may be: what kinds of difference can a system sustain, what must it sacrifice to do so, and who or what is permitted to change those conditions?