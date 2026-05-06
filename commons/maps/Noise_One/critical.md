# The noise function has no neighbors, no memory, and no choice — three ontologies break against stateless computation

Every theoretical claim in this document is tested in code. Several claims are expected to break. The breakdowns are the point. A theory that holds everywhere holds trivially. A theory that holds in interactive systems but breaks in stateless fields reveals its actual scope.

Fractal Brownian motion is the critical counterpoint to every claim tested in CA_11 and Forces_1. Wireworld has neighbors, state, conditionals, feedback. Euler integration has accumulation, persistence, history. Noise has none of these. It is a pure function: input coordinates, output scalar. No memory. No context. No time. If an ontological claim is truly universal, it must survive contact with `get_noise_2d(x, z)`.

## Thrownness: The Seed Determines Everything

Heidegger's Geworfenheit — the initial condition is given, not chosen. The trajectory follows from what was imposed at the start.

Thrownness in its purest form. The entire landscape — every mountain, every valley, every ridge — follows from one integer. `noise.seed = randi()` is the moment of thrownness. The function does not choose its seed. It receives it. And from that single given number, an infinite field is determined.

This is more extreme than Forces_1. In dynamics, thrownness is the initial velocity — a vector, three numbers, partial constraint. In noise, thrownness is the seed — one integer, total constraint. Every point in the entire infinite field is determined by that integer. There is no second factor. No force field to modify the trajectory. No delta-t to integrate through. The seed IS the landscape.

Test: does the thrown condition matter? Can the system forget its seed?

The seed is and is not forgotten. Locally, every point differs between seeds — the thrown condition determines each value. Statistically, the seeds converge — zero-mean, same variance, same spectral distribution. The landscape is different but the character is the same.

This splits thrownness into two levels. At the level of individual values: thrownness holds absolutely — each point's value is determined by the seed. At the level of statistical properties: thrownness breaks — the seed doesn't affect the distribution, only the particular realization.

Heidegger does not distinguish these levels. The code forces the distinction.

**Verdict:** Thrownness confirmed at the local level (each value determined by seed). Refined at the statistical level (distribution is seed-independent). The code reveals a two-level structure that the theory doesn't distinguish: thrownness of particular values vs. thrownness of statistical character.

## Agential Realism: The Function Has No Context

Barad: properties are enacted through interaction, not possessed intrinsically. The entity's behavior depends on relational configuration.

Agential realism breaks cleanly. The noise function is a pure function — same input, same output, always. There is no neighborhood to consult. There is no environmental state to depend on. The value at `(5.0, 3.0)` is a property of the function (the seed) and the coordinates, not of any interaction.

This is not a marginal case. The function signature itself falsifies Barad: `get_noise_2d(x: float, z: float) -> float` has no context parameter. There is nowhere to put a neighbor list, a field state, or an environmental variable. The architecture of the computation prevents relational agency.

But test one level up. The fBM loop — does THAT have relational properties?

Also broken. The fBM loop is additive — each octave contributes independently to the sum. Frequency and amplitude follow geometric progressions determined by lacunarity and persistence, not by previous octave values. There is no feedback, no interaction between layers.

The erosion pass is different:

The erosion pass reintroduces agential realism. A cell's eroded height depends on the slope, which depends on neighboring cells. The post-process is relational even though the noise generation is not.

**Verdict:** Agential realism broken for noise generation (pure function, no context). Broken for fBM summation (additive, no inter-octave feedback). Confirmed for erosion (neighbor-dependent slope calculation). The claim has sharp scope: it holds where computation involves neighbors and breaks where computation is pointwise. The boundary is architectural — whether the function signature includes context.

## Performativity: No Memory, No Performance

Butler: identity through constrained repetition. Each iteration constrains the next.

Performativity breaks. The fBM loop has no feedback. Octave 4's contribution to the sum is the same whether octaves 0-3 were computed or not. Removing history changes nothing about later iterations. The loop iterates but does not perform — each pass is independent.

Compare to Forces_1 where `velocity += acceleration * delta` accumulates: frame 60's velocity depends on all 59 previous frames. In fBM, octave 4's value depends on zero previous octaves.

The loop is repetition without constraint. The repetition is additive, not recursive. Butler's performativity requires that the act of repeating changes the conditions under which the next repetition occurs. In fBM, the conditions (frequency, amplitude) follow a preset geometric sequence. The loop is a summation schedule, not a performance.

Domain warping — where one noise sample offsets the coordinates of the next — IS performative. Each octave's output constrains the next octave's input space. But standard fBM does not use domain warping. The performative variant exists but is not the default.

**Verdict:** Performativity broken for standard fBM (additive, no feedback between octaves). Would hold for domain-warped noise (recursive coordinate offset). The claim's scope: performativity requires that iteration outputs feed back into iteration inputs. Additive loops do not qualify.

## Finitude as Constitutive: The Octave Limit

The test confirms finitude as constitutive — but in a surprising way. The limit is not that exceeding it causes explosion (as with the CFL condition in Forces_1). The limit is that exceeding it changes nothing. Beyond 8 octaves, the noise value is identical to machine precision. The additional octaves exist mathematically but are computationally invisible.

This is a different kind of constitutive finitude. Forces_1's spring limit is a boundary of possibility: cross it and the simulation explodes. Noise's octave limit is a boundary of relevance: cross it and nothing changes. Both are constitutive but for different reasons. The spring limit says "you cannot go further." The octave limit says "there is nothing further to go to."

The Nyquist limit is a second finitude. Noise at frequencies above the sampling rate cannot be perceived as coherent — it appears random. The function is still smooth, still continuous, still deterministic. But the observer cannot see the coherence. The limit is in the observation, not the function. Chirimuuta would recognize this: "Understanding is enacted, not extracted." The noise's fine structure exists but cannot be enacted at coarse resolution.

**Verdict:** Finitude confirmed, two forms discovered. (1) Convergence finitude: beyond 8 octaves, additional detail contributes nothing (the series converges). (2) Nyquist finitude: above the sampling rate, coherent structure becomes indistinguishable from randomness (aliasing). Both are constitutive but for different reasons — one is mathematical convergence, the other is observational resolution.

## Boundary as Politics: The Erosion Threshold

The threshold is the full political spectrum. At 0.0: totalitarian smoothing, all difference erased. At 999: anarchic noise, no constraint on slope. At 0.5: the moderate position, which happens to produce "walkable" terrain. "Walkable" is itself a political choice — it assumes a ground-walking agent with human-scale mobility.

**Verdict:** Boundary as politics confirmed. The erosion threshold is a design choice that determines terrain character. No value is "correct" — each produces a different landscape for a different purpose. The default (0.5) encodes assumptions about the intended user.

## QFEP Coordinates

QFEP hits a structural limit in noise. Lambda is meaningful — persistence maps directly to the entropy drive, controlling how much fine-scale variation survives. But phi is undefined. Phi measures response to change over time. Noise has no time. It is a field, not a process. Assigning phi=0.0 is a convention, not a measurement.

This reveals that QFEP is a framework for temporal systems. Applying it to spatial fields requires either (a) treating field evaluation as a degenerate case with phi=0, or (b) acknowledging that QFEP does not apply to stateless computation.

**Verdict:** QFEP partially confirmed. Lambda maps cleanly to persistence (confirmed). Phi is undefined for stateless systems (structural limit). QFEP is a temporal framework applied to a spatial field — the fit is partial.

## Summary of Tests

| Claim | Source | Code Test | Verdict |
|-------|--------|-----------|---------|
| Thrownness | Heidegger | Seed determines entire field; local values diverge, statistics converge | **Confirmed with two levels.** Local thrownness absolute; statistical thrownness breaks |
| Agential Realism | Barad | `get_noise_2d(x, z)` has no context parameter; fBM has no inter-octave feedback | **Broken.** Pure function, no relational agency. Erosion pass is relational. |
| Performativity | Butler | fBM octaves are additive, not recursive; removing early octaves doesn't affect later | **Broken.** No feedback between iterations. Domain warping would restore it. |
| Boundary as Politics | Critical theory | Erosion threshold at 0.0/0.3/0.5/0.8/999 → five terrain characters | **Confirmed.** Threshold is a design choice encoding assumptions about users |
| Finitude | Heidegger/Chirimuuta | Octave convergence (8 octaves = 99.6%); Nyquist aliasing at high frequency | **Confirmed, two forms.** Convergence finitude + observational finitude |
| QFEP Location | QFEP | Lambda maps to persistence; phi is undefined for stateless systems | **Partially confirmed.** Lambda works; phi hits structural limit |
| Emergence | Systems theory | Noise + erosion → terrain; noise alone → terrain; erosion alone → nothing | **Refined.** Rules alone produce landscape; post-processing adds plausibility but isn't required |

Two claims break cleanly in noise that held in CA_11 and Forces_1: agential realism and performativity. Both require interaction and memory, which noise lacks by architecture. The breakdowns are not failures of the theory — they are scope conditions. Barad's agential realism holds for interactive systems where entities consult neighbors. It does not hold for pointwise evaluation of pure functions. Butler's performativity holds where iteration feeds back into itself. It does not hold for additive loops.

The breakdowns tell us something the confirmations cannot: these ontologies have boundaries. They describe the world of interaction, feedback, and state. They do not describe the world of pure functions and spatial fields. The boundary between these worlds is architectural — whether the function signature includes a context parameter.
