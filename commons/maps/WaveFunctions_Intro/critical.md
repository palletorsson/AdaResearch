# The sine function remembers nothing between cycles — autonomy, repetition without performance, and the phase as pure thrownness

Every theoretical claim in this document is tested in code. The wave is the second unconditional system after noise. If claims broke against stateless field evaluation, do they also break against stateless temporal oscillation? The wave has time — noise did not. But does time without memory constitute agency?

## Thrownness: The Phase Was Given

Heidegger: initial conditions are given, not chosen. The entity's trajectory follows from its state at instantiation.

The phase is thrownness in its most transparent form. The oscillator does not choose φ. It receives it. And the entire future — every position at every time — follows from that single number plus two parameters (A, ω). Change φ by π/2 and the oscillator starts at maximum displacement instead of zero. The shape is identical. The timing is permanent.

But unlike Forces_1, the thrown condition here is trivial. In dynamics, different initial velocities produce different trajectories — the thrownness genuinely matters. In oscillation, different phases produce the same trajectory shifted in time. The phase changes *when* you arrive but not *what* you encounter. Thrownness is confirmed but weakened: the thrown condition affects timing, not content.

Omega is a stronger thrown parameter than phase. Different omegas produce structurally different motion — different periods, different velocities, different peak accelerations. The oscillator doesn't choose its omega. It receives it as an export parameter. Thrownness through omega is as strong as thrownness through initial velocity in Forces_1.

**Verdict:** Thrownness confirmed, two strengths discovered. Phase is weak thrownness (shifts timing, not content). Omega is strong thrownness (determines trajectory structure). Both are given, not chosen.

## Performativity: Repetition Without Constraint

Butler: identity through constrained repetition. Does the wave's repetition constitute performance?

Performativity breaks. The wave repeats, but repetition creates no constraint. Cycle 10 is identical to cycle 1. The oscillator has no memory of having oscillated before. Each cycle is a fresh evaluation of `sin(omega * time + phase)` — the function doesn't know how many times it has been called.

Compare to Forces_1 where velocity accumulates: the 60th frame's velocity depends on all 59 previous frames. The wave's position at frame 60 depends only on the current time — `sin(omega * 60 * dt + phase)`. Remove all frames between 1 and 59 and frame 60 is unchanged.

The wave is path-independent. You can skip directly to any future time without computing the intervening frames. This is the opposite of performativity. Butler requires that the process of getting there matters — that the path constrains the destination. The wave says: the destination is determined by the clock, not by the journey.

But: `time += delta` IS accumulation. The time variable persists across frames. Does time itself constitute performativity?

Time is an index, not a performance. The accumulated `time += delta` could be replaced by `OS.get_ticks_msec() / 1000.0` — a direct clock read with no accumulation. The oscillator would behave identically. The time variable is an implementation convenience, not a constitutive process.

**Verdict:** Performativity broken. The wave repeats but repetition creates no constraint. Cycles are independent. Time is an index, not a performative accumulation. Path-independence proves it: you can skip to any frame without computing the intervening ones. The wave oscillates without performing.

## Finitude as Constitutive: Amplitude and Frequency Limits

Amplitude infinity doesn't break the math — `sin()` is always bounded in [-1, 1], and any finite amplitude produces a valid position. The limit is practical (rendering, physical meaning) not constitutive (the computation itself). This is different from the CFL condition in Forces_1 where exceeding dt causes the simulation to explode.

The Nyquist limit appears again — same form as in noise. Above ω ≈ 188 rad/s at 60 fps, the oscillation cannot be observed. The wave is still oscillating (the math is correct) but the sampling rate cannot capture it. The coherent motion becomes indistinguishable from random jumping.

This is the same observational finitude Chirimuuta describes: "Understanding is enacted, not extracted." The wave's fine temporal structure exists but cannot be enacted at coarse sampling rates.

**Verdict:** Finitude refined. Amplitude limits are practical (the math doesn't break). Frequency limits are constitutive (Nyquist aliasing — coherent oscillation becomes perceptually random above the sampling rate). Same pattern as noise: convergence finitude absent, observational finitude present.

## Agential Realism: The Wave Has No Context

Agential realism breaks for the same reason as in noise: the function has no context parameter. The wave oscillates regardless of what surrounds it. Two waves side by side do not interact. Each follows its own equation independently.

Superposition creates an interesting edge case:

Even superposition is not relational in Barad's sense. Adding two waves does not change either wave. The combination exists in the sum, not in the components. Each wave retains its identity. This is not intra-action (mutual constitution) but composition (independent aggregation).

**Verdict:** Agential realism broken. The wave is fully autonomous. Even superposition is composition, not intra-action. The claim's scope: agential realism requires that entities modify each other through interaction. Autonomous oscillators do not interact.

## QFEP Coordinates

Waves at λ=0, φ=0: fully ordered, no exploration, no response to change. Prediction: deterministic periodic behavior, no adaptation, no emergence. Matches observed behavior exactly.

Compared to Forces_1 (λ=0, φ=-0.3): both are deterministic, but Forces_1 has dissipation (restitution reduces energy), giving it negative phi. The wave has no dissipation — amplitude never decays (in this idealized model). It is more rigid than physics.

Compared to Noise_One (λ=0.5, φ=0): noise has structured variation (mid-lambda), while the wave has zero variation (lambda=0). Both have phi=0 (no feedback). The wave is more ordered than noise.

**Verdict:** QFEP location confirmed. λ=0, φ=0 correctly predicts fully deterministic, non-adaptive, periodic behavior. Phi is again problematic for systems without feedback — neutral by convention rather than measurement.

## Summary of Tests

| Claim | Source | Code Test | Verdict |
|-------|--------|-----------|---------|
| Thrownness | Heidegger | Phase is weak thrownness (timing only); omega is strong (structure) | **Confirmed, two strengths.** Phase matters less than omega; both are given |
| Performativity | Butler | Cycles independent; time is index not accumulation; path-independent | **Broken.** Repetition creates no constraint. Skip frames, same result |
| Agential Realism | Barad | No context parameter; superposition is composition not intra-action | **Broken.** Fully autonomous, no relational properties |
| Finitude | Heidegger/Chirimuuta | Amplitude limits practical; Nyquist limit constitutive | **Refined.** Observational finitude (aliasing) constitutive; magnitude finitude practical |
| QFEP Location | QFEP | λ=0, φ=0 predicts deterministic, periodic, non-adaptive | **Confirmed.** Most ordered system tested so far |

Waves confirm the pattern emerging from noise: unconditional systems break agential realism and performativity. The wave adds one refinement noise could not provide: it has time but not memory. The wave evaluates `sin(omega * t + phase)` — time appears in the argument but does not accumulate as state. This proves that time alone is insufficient for performativity. What Butler requires is not repetition-in-time but state-dependent-iteration — where each step's output feeds into the next step's input. The wave has repetition without feedback. Noise had neither repetition nor feedback. Both break performativity, for complementary reasons.

The cross-domain pattern: performativity requires stateful feedback. Agential realism requires contextual input. Thrownness requires only that initial conditions are externally given. Thrownness is the most universal claim — it holds everywhere. The others have structural prerequisites.
