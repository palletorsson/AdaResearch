# Randomness: a research map for Programming, Art, QFEP and Ada Research

I think randomness deserves to be one of the central subjects of Ada Research, not simply one algorithm among others. It connects mathematics, information theory, physics, computation, generative art, evolution, perception, and the emergence of new forms.

But each of your four perspectives asks a different question.

| Perspective                        | Central question                                                                                            |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Programming                        | How can we generate, control, distribute, measure and reproduce randomness?                                 |
| Art                                | What happens to form, authorship, meaning and experience when outcomes are not completely determined?       |
| QFEP — Queer Free Energy Principle | How can systems move between stability and uncertainty, and when can variation transform the system itself? |
| Ada Research                       | How can randomness become an observable, inhabitable, programmable and reconstructable artistic encounter?  |

The most important distinction is that randomness, entropy, unpredictability, complexity, novelty and chaos are not interchangeable concepts.

A statistically random sequence might produce an aesthetically uninteresting image. A completely deterministic cellular automaton might produce extraordinary complexity. A tiny random mutation might fundamentally change a system's future, while a thousand random changes might accomplish almost nothing.

For Ada, the interesting question is therefore not merely how to produce more randomness, but:

Where does uncertainty enter? What can it change? What remains stable? And under what conditions does a difference become consequential?

## 1. The major subjects of randomness

I would organize the field into 18 research subjects. These are not necessarily 18 separate museum halls: they are concepts and mechanisms that can intersect across many installations.

| Subject                             | Essential principle                                                            | Possible Ada encounter                                         |
| ----------------------------------- | ------------------------------------------------------------------------------ | -------------------------------------------------------------- |
| 1. Sources of randomness            | Physical entropy, human input, hardware noise, quantum events                  | The Quest listens to its own timing fluctuations               |
| 2. Pseudorandomness                 | Deterministic generators produce statistically random-looking sequences        | The seed bench and REPLAY                                      |
| 3. Seeds and states                 | Reproduction requires preserving more than a starting number                   | +1 DRAW changes subsequent colour assignments                  |
| 4. Probability distributions        | Uniform, Gaussian, Bernoulli, Poisson, exponential, power-law                  | Change a distribution and watch the world reorganize           |
| 5. Independence and correlation     | Random values can be statistically independent or dependent                    | Compare scattered colours with locally correlated patterns     |
| 6. Noise and random fields          | White, pink, Brownian, Perlin, Simplex, Worley, blue noise                     | Generate textures, landscapes, sounds and spatial structures   |
| 7. Stochastic processes             | Random walks, Brownian motion, Lévy flights, Markov chains                     | Walk with an object whose next movement is sampled             |
| 8. Monte Carlo methods              | Repeated random sampling estimates quantities and explores possibilities       | Estimate an unknown shape through thousands of random probes   |
| 9. Chaos and sensitivity            | Deterministic systems can become practically unpredictable                     | Two nearly identical initial states diverge                    |
| 10. Entropy and information         | Quantify uncertainty relative to a defined variable and distribution           | Compare colour histograms with spatial arrangements            |
| 11. Complexity and emergence        | Simple rules can produce complex behaviour without continuous random input     | Cellular automata and artificial life                          |
| 12. Thresholds and criticality      | Small perturbations can trigger large changes near a transition                | A tiny change causes a structure to reorganize                 |
| 13. Mutation and evolution          | Random variation meets nonrandom selection                                     | An evolutionary population of strange objects                  |
| 14. Procedural grammars             | Rules constrain which forms can be generated                                   | Let randomness change the grammar, not just its output         |
| 15. Stochastic machine learning     | Sampling, initialization, training and generative distributions                | Compare AI outputs, latent trajectories and model revisions    |
| 16. Chance and authorship           | Delegating decisions to chance changes the role of the artist                  | A work whose outcomes neither maker nor visitor fully controls |
| 17. Feedback and entropy modulation | Variation can be encouraged or suppressed according to system state            | A QFEP system alternates exploration and consolidation         |
| 18. Randomness and power            | Who chooses the variables, probabilities, constraints and acceptable outcomes? | The visitor discovers that the apparent freedom was designed   |

Several of these are technically distinct but artistically inseparable. For example, an artwork using Gaussian noise also raises questions about distribution, the visual language given to those numbers, and the degree of control retained by its author.

## 2. For programming: the architecture of randomness

For programming, I would distinguish four especially important levels.

### Source — where does unpredictability originate?

A program can obtain random-looking values from a seeded generator or request unpredictable values from an operating system's cryptographic random generator.

It can also experiment with physical sources such as electronic noise or high-resolution CPU jitter, although an irregular measurement is not automatically a trustworthy entropy source.

For Ada, this is where the Oculus/Quest becomes interesting. The computer can potentially investigate the physical and computational processes that make its own operation imperfectly regular.

### Distribution — what kinds of outcomes are likely?

A uniform distribution gives each outcome in a specified range the same probability. A Gaussian distribution concentrates values around a mean. A Poisson distribution models event counts under particular assumptions.

Uniform distribution

Equal probabilities across the eight bins

Gaussian distribution

Values cluster near the centre

These are not just mathematical choices. They create different worlds. A room in which every direction is equally probable behaves differently from one in which movements usually remain near a preferred direction.

### Correlation — how are random events related?

White noise, Perlin noise and Brownian motion illustrate different ways that randomness can acquire spatial or temporal relationships.

An independently sampled random field may look fragmented. A correlated field can produce smooth changes, coherent surfaces and recognizable formations.

The key artistic point is that randomness does not imply the absence of structure.

Indeed, controlling correlation is one of the principal ways of making random variation aesthetically and procedurally useful.

### Constraint — what is randomness allowed to affect?

This is perhaps the most important level for Ada.

A program might allow randomness to choose colours, positions, rotations, velocities, connections, materials, rules or even the topology of an object.

Those choices determine what kind of variation can occur.

The 4×4 colour grids are a particularly good elementary example. Forty-eight draws determine RGB values, while the cells remain fixed.

But imagine preserving the same random stream and changing the interpretation of its values.

One program creates colours. Another changes the dimensions of cubes. Another determines which cells connect. Another allows a corner of the grid to escape its original structure.

The source of randomness could remain unchanged while the space of possible outcomes changes radically.

That is a crucial bridge from programming to artistic research.

## 3. For art: chance, form and the unexpected

The history of art gives us several quite different uses of randomness.

Hans Arp explored chance arrangements and collage. John Cage used chance operations, including the I Ching, to organize compositional decisions. Vera Molnár investigated systematic variation and controlled disorder in geometric structures.

Their work offers different answers to a fundamental question: what happens when the artist no longer determines every aspect of the result?

I would distinguish five artistic problems.

Chance as delegation. The artist transfers some decisions to a procedure. But the artist still chooses the procedure, its boundaries and often the results presented.

Chance as material. Randomness can have rhythm, density, granularity, scale and texture. It can become something experienced sensorially rather than merely understood mathematically.

Chance as encounter. Something happens that neither the visitor nor the artist expected. The question becomes whether that event alters their relationship with the work.

Chance as composition. Aesthetic selection can follow generation. The artist might preserve an unexpected arrangement, reject another or change the rules because of what appears.

Chance as transformation. The unexpected result leads to a revision of the very procedure that made it. This final category is particularly important for your recursive method.

A useful distinction is between surprise and novelty.

Surprise is relative to an expectation. Novelty depends on a comparison with what has occurred before. Neither necessarily creates artistic value.

A white-noise image may have high pixel-level uncertainty while remaining completely predictable as an aesthetic category. A tiny alteration to a familiar form might instead be profoundly consequential.

The artist's investigation therefore concerns which differences matter, to whom, and under what conditions.

## 4. For QFEP: randomness as a means of transformation

For the Queer Free Energy Principle, I would put the greatest weight on the relationship between stability, exploration and reorganization.

Your QFEP framework proposes that an adaptive system should not be understood solely in terms of reducing uncertainty. It may also benefit from strategically seeking variation, destabilizing its established organization, and discovering possibilities its existing model excludes.

There is a scientific distinction to preserve here: the conventional Free Energy Principle concerns variational free energy, which is not interchangeable with Shannon entropy or physical entropy. QFEP's broader use of entropy modulation is a proposed theoretical and artistic extension, rather than an established consequence of the FEP.

One way to make the QFEP idea operational in Ada is through a cycle:

Stabilize

Preserve a recognizable organization

Explore

Introduce controlled variation

Reorganize

Revise relationships or boundaries

Consolidate

Retain newly viable structures

Repeat without assuming a final stable optimum

Three subjects become especially important.

### A. Entropy modulation

Rather than increasing randomness indefinitely, the system varies its openness to stochastic perturbation.

In Ada, imagine an artificial organism whose morphology is initially stable. Increasing variation allows mutations to appear. Some destroy the organism's coherence; others produce viable structures that were previously inaccessible.

The research question becomes how much organization must be retained to make further transformation possible.

### B. Revisable boundaries

In your QFEP interpretation, boundaries are not simply protective enclosures. They can become sites of exchange, ambiguity and reconstruction.

This is where the Markov blanket becomes interesting as a speculative artistic model. A conventional Markov blanket has a precise statistical definition involving conditional independence. Its artistic reinterpretation as a revisable interface needs to be developed rather than assumed.

An Ada organism might initially distinguish inside from outside. Random mutations could alter its permeability, sensory boundaries or relationship to other entities.

The more interesting result might not be a new appearance but a new way of relating to the environment.

### C. Transformation of the state space

Ordinary variation explores alternatives permitted by existing rules.

QFEP offers a reason to investigate moments when those rules become inadequate and must be revised.

A random colour is a different state.

A cube escaping the grid changes the geometry of possible states.

A new rule allowing the escaped cube to become a sensor, connector or garment changes what kinds of entities and relationships the system can support.

This is where randomness can contribute to queering a computational system—not simply through irregularity, but through the reconstruction of the categories and constraints that organize it.

Randomness alone is not queer. A random process can reproduce the same norms, classifications and exclusions indefinitely.

## 5. For Ada: a sequence of research encounters

I would organize the randomness investigations around increasingly consequential forms of variation. This is a conceptual progression, not necessarily a proposal to rearrange your existing halls.

01

Where does randomness come from?

Distinguish secure random bytes, pseudorandom generators and experimental physical entropy. Use the Quest's timing fluctuations as a measured phenomenon, not as a presumed random source.

02

What can return?

Keep your seed bench, sphere and RAND historical reference. Investigate the distinction between returning to a position, reproducing a sequence and reconstructing an experience.

03

What is a normal outcome?

Allow visitors to change distributions while observing how probability shapes an environment. Examine the assumptions hidden inside seemingly neutral random selection.

04

Can randomness form a structure?

Compare independent random values, correlated noise, random walks and procedural grammars. Connect this to 10 PRINT, noise and procedural generation.

05

How much information survives?

Compare entropy measurements, distributions, adjacency, temporal order and spatial organization. Demonstrate that two arrangements can share a histogram while differing substantially in structure.

06

When does a small difference become enormous?

Explore sensitivity to initial conditions, bifurcations, percolation, critical thresholds and emergent behaviour. Distinguish deterministic chaos from stochastic dynamics.

07

Can an organization survive its own transformation?

Use mutation, artificial life, cellular automata and QFEP-style entropy modulation. Observe which structures persist, reorganize or disappear.

08

Who decided what could change?

Make the generative grammar accessible. Allow visitors—or the artistic research process itself—to change what the randomness controls. Here the grid might become the imagined sleeve.

The last encounter is not simply a conclusion. It can return the visitor to the first instrument with a different understanding of what randomness is being asked to do.

## 6. A rigorous experiment for the recursive artistic method

I think Ada could use a consistent experimental structure across the randomness-related halls.

One experiment, six possible interventions

Start with the existing 4×4 colour grid.

Source

Distribution

Correlation

Structure

Feedback

Reconstruction

Intervention Replace a fixed seed with one sampled from the OS secure generator.

Research observation Is the result newly unpredictable, and what must be recorded to replay it?

This would make the epistemological method repeatable without requiring every artistic outcome to conform to a fixed narrative.

The research documentation would preserve the source, generator, seed or state, sampling method, parameters, intervention and observed result. For exact replay, other relevant information—such as event ordering, engine version and physics state—may also be necessary.

The writing would then identify what remained unexpected, what difference mattered, and whether that encounter justified a change to the implementation.

This is quite different from simply generating variations and choosing the most attractive one.

## 7. The conceptual problem I would put at the centre

There is a recurring assumption in generative art that increasing random variation increases possibility.

But a system can have enormous statistical variability while remaining structurally impoverished.

Imagine a million possible arrangements of sixteen coloured cubes. Their colours can vary freely, yet every cube remains imprisoned in its cell.

Now imagine a single new rule allowing two cubes to connect and detach.

That one rule might produce a more consequential enlargement of the system's possibilities than millions of additional random colours.

In mathematical terms, it is useful to distinguish between changing a probability distribution over an established set of states and changing the state space or transition rules themselves.

The two are related but not equivalent.

For QFEP, this is where the distinction between entropy modulation and structural transformation becomes essential. Higher entropy within an existing model does not by itself create new categories of possibility.

And for Ada Research, this leads to a central artistic proposition:

Randomness produces variation. Constraints determine where variation can occur. Observation makes some differences consequential. Artistic reconstruction can change the constraints themselves.

That proposition connects the computational, aesthetic and theoretical work without collapsing their differences.

It also gives your recursive method a clear research role. Writing is not merely the report that follows an experiment. It can identify a previously overlooked possibility, which is subsequently implemented, experienced and revised.

My strongest recommendation would be to organize the randomness research around three recurring questions:

What is uncertain? What remains invariant? What would have to change for something previously impossible to become possible?

Those questions can travel from the simplest random-number example to procedural generation, artificial life, neural networks, evolutionary systems and the QFEP framework. They would give Ada a coherent investigation without requiring randomness to mean the same thing in every hall.&#x20;