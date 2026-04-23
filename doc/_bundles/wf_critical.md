<<<ADA_BUNDLE>>>
sequence: wavefunctions
file: critical.md
maps: 13
skipped_passing: 0
created: 2026-04-23T22:21:08
only_failing: false
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: WaveFunctions_Intro>>>
# INTENT: Concept: The control room where oscillation is first encountered — oscilloscopes display waveforms, interactive cubes teach parameters (amplitude, frequency, phase), and the language of periodic motion is established before the journey begins. | Sequence role: Opens the Wavefunctions sequence; the second oscillation-phase spine sequence (after Forces). Where Forces introduced oscillation through springs and pendulums as physical consequences, this sequence treats oscillation as the primary phenomenon. The four cubes (static, rotating, oscillating, transforming) provide a progression from rest to | [... truncated ...]
# BLURB: A small room lined with oscilloscopes. Green traces sweep left to right — sine, square, sawtooth, triangle. Each one a different signature of the same principle: periodic motion between extremes.  Four cubes teach the gr…
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

<<<MAP: WaveFunctions_Pendulum>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Gravity creates rhythm — the pendulum as sine made physical, where restoring force proportional to displacement produces periodic motion that momentum always overshoots. The double pendulum introduces chaos. | Sequence role: Second map in Wavefunctions; grounds the abstract sine wave from the Intro in physical mechanism. The pendulum is the canonical harmonic oscillator — the simplest system where gravity produces oscillation. The Foucault pendulum extends to planetary rotation; the double pendulum introduces chaos (connecting back to Forces_8's N-body sensitivity); follows WaveFunction | [... truncated ...]
# BLURB: Gravity creates rhythm. A weight on a string swings, tracing time with its body. The pendulum is sine made physical — restoring force proportional to displacement, perpetual return toward equilibrium that momentum always…
[empty — file does not yet exist]

<<<MAP: WaveFunctions_Unit_Circle>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Rotation creates oscillation — a point on a spinning circle projects its shadow as a sine wave, revealing that trigonometry's origin is circular motion. The amphitheater frames the unit circle as theater; oscillating bridges make the wave physical underfoot. | Sequence role: Fourth map in Wavefunctions; the conceptual keystone. After sine as equation (Intro), sine as physics (Pendulum), and sine as space (Sine_Space), this map reveals where sine comes from: the projection of uniform circular motion. This is the deepest explanation in the sequence — every subsequent wave phenomenon reduc | [... truncated ...]
# BLURB: Rotation becomes oscillation. A point traveling in a circle traces a sine wave when watched from the side. The unit circle is where trigonometry begins — where angle becomes number, where spinning becomes swinging.  The …
[empty — file does not yet exist]

<<<MAP: WaveFunctions_Sine_Space>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The sine wave made architectural — walk through a sin(t) function frozen in three dimensions, where amplitude is height, frequency is compression, and phase is shift. Oscillation becomes space you inhabit. | Sequence role: Third map in Wavefunctions; transitions from temporal oscillation (pendulums swinging in time) to spatial oscillation (geometry shaped by sine). The sine_wall_corridor makes the wave a walkable environment. After this, the learner understands that waves exist in space as well as time; follows WaveFunctions_Pendulum; leads to WaveFunctions_Unit_Circle. | Technical angle: | [... truncated ...]
# BLURB: The wave made spatial. Walk through a sine function frozen in three dimensions — amplitude as height, frequency as compression, phase as shift. The mathematics of oscillation becomes architecture you can inhabit.  The `s…
[empty — file does not yet exist]

<<<MAP: WaveFunctions_3D_Wave_Propagation>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Waves as disturbances traveling through media — emanating from sources, diminishing by inverse-square law, interfering where they meet. Identity is permeable: to exist in a medium is to be distorted by it. | Sequence role: Fifth map in Wavefunctions; the first intermediate-difficulty map. After four beginner maps establishing what oscillation is and where it comes from, this map introduces propagation — oscillation that moves through space. Distance fields, phase propagation (sin(time - dist)), attenuation, and interference are the new tools. This connects forward to the sound maps and  | [... truncated ...]
# BLURB: Waves move through space. Ripples spreading from a dropped stone, sound radiating from a speaker, light expanding from a star. Here oscillation gains direction — amplitude at every point, phase shifting with distance, in…
[empty — file does not yet exist]

<<<MAP: WaveFunctions_Effect_Sound>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Sound as oscillation made audible — waveforms become bleeps and bloops, FFT decomposes signal into frequencies, and the gap between physical vibration and perceived sound reveals quantization noise and latency. | Sequence role: Sixth map in Wavefunctions; the pivot from visual/spatial waves to auditory waves. Previous maps showed oscillation you see and walk; this map makes oscillation you hear. The rich artifact set (synthesizers, sound controllers, audio monitors) creates a working audio laboratory. Connects forward to Bernini (sound-as-form), John Cage (silence), and Synthesis Lab (F | [... truncated ...]
# BLURB: Sound is oscillation made audible. Waveforms become bleeps and bloops — the 8-bit aesthetic of classic games built from square waves and frequency sweeps. Play with the building blocks of chiptune music, hear mathematics…
[empty — file does not yet exist]

<<<MAP: Wavefunctions_Bernini>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Baroque columns as frozen waves — Bernini's solomonic spirals are sine functions wrapped around cylinders. Vertex displacement via rotation matrices transforms rigid geometry into twisting organic forms. Procedural geometry as the new Baroque. | Sequence role: Seventh map in Wavefunctions; the first art-historical map. After five maps of wave mechanics and one of sound, this map applies oscillation to sculptural form. The advanced difficulty signals that the learner must compose techniques: vertex displacement, rotation matrices, noise layering. Connects to Primitives' geometric heritag | [... truncated ...]
# BLURB: Baroque columns twist like frozen waves. Bernini's solomonic spirals are sine functions wrapped around cylinders — architecture as helical oscillation, stone as solidified motion. The wave captured mid-dance, held for ce…
[empty — file does not yet exist]

<<<MAP: WaveFunctions_John_Cage>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Silence as the space between waves — Cage's 4'33" reveals that music is attention, not sound. Aleatoric algorithms use chance as compositional method; the noise floor proves zero signal is impossible; ambient computation simulates the uneventful. | Sequence role: Eighth map in Wavefunctions; the philosophical counterpoint to the sequence's accumulating complexity. After seven maps building oscillation from simple to baroque, Cage inverts everything: what happens when oscillation stops? The answer — it doesn't, there's always noise — is the deepest lesson. Connects to Randomness sequence | [... truncated ...]
# BLURB: Silence is the space between waves. John Cage's 4'33" reveals that music is not sound but attention—the framework that makes waves meaningful. Absence as frequency zero, the pause that gives oscillation its shape, the re…
[empty — file does not yet exist]

<<<MAP: WaveFunctions_AirMusic>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Sound as spatial event — notes trigger from positions occupied, not keys pressed. Brian Eno's phasing loops drift through FM synthesis, harmony emerging from independent cycling rates rather than deliberate composition. | Sequence role: Ninth map in Wavefunctions; after Cage's silence, sound returns but transformed — not composed in the traditional sense but emergent from spatial position and phasing. The laboratory setting connects to Synthesis Lab (map 12) while the ambient/generative approach connects back to Cage's aleatoric philosophy; follows WaveFunctions_John_Cage; leads to Wave | [... truncated ...]
# BLURB: A laboratory where sound is spatial. Notes trigger not from keys pressed but from positions occupied — walk through the room and the room plays. Brian Eno's phasing loops drift through an FM piano, each voice cycling at …
[empty — file does not yet exist]

<<<MAP: Wavefunctions_Sky_Stairs>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Ascent through oscillation — stairs that climb along sine curves, where each step is a moment in a wave cycle. The tallest structure in the Wavefunctions sequence; climbing stairs IS tracing a waveform. | Sequence role: Tenth map in Wavefunctions; returns to embodied wave experience after the conceptual maps (Cage, AirMusic). The vertical amphitheater launches the learner skyward, then descends through sine-modulated staircases. Floating cube fields sample 3D space at varying heights. Connects back to Sine_Space's spatial wave but extends vertically — the wave is now climbed, not walked | [... truncated ...]
# BLURB: Ascent through oscillation. Stairs that climb along sine curves — each step a moment in a wave cycle. Rising through space by following frequency, the spiral staircase as helix, vertical progress as rotational persistenc…
[empty — file does not yet exist]

<<<MAP: WaveFunctions_TrigWalkingPath>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Sine and cosine as parallel walking paths — two lanes of steps rising and falling according to trigonometric functions, where each footfall lands on a computed position and the path generates itself ahead. | Sequence role: Eleventh map in Wavefunctions; the penultimate map. After Sky_Stairs' vertical wave climbing, this map returns to horizontal traversal but with both sin and cos visible simultaneously. The dual-path design makes the phase relationship between sine and cosine (90° offset) physically walkable. Connects to the Synthesis Lab's decomposition thesis by showing the two funda | [... truncated ...]
# BLURB: Sine and cosine become architecture. Two lanes of steps rise and fall according to trigonometric functions — one traces sin, the other cos — and the learner walks the wave. Each footfall lands on a computed position. The…
[empty — file does not yet exist]

<<<MAP: WaveFunctions_Synthesis_Lab>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Fourier's theorem as the sequence's culmination — any signal decomposes into sine waves, and this laboratory lets the learner stack harmonics, observe resonance, and discover that biological systems (heartbeats, DNA rotation, circadian rhythms) are oscillators too. | Sequence role: Twelfth and final map in Wavefunctions; the synthesis that gives the sequence its name. Every concept from the previous 11 maps converges: sine waves (Intro/Sine_Space), pendulums (Pendulum), circular motion (Unit Circle), propagation (3D Wave), sound (Effect_Sound/AirMusic), form (Bernini), silence (Cage), a | [... truncated ...]
# BLURB: Fourier's theorem: any signal decomposes into sine waves. Any wave, no matter how jagged or complex, is just simple oscillations stacked. This is the room where that principle becomes material.  Layer harmonics on the ad…
[empty — file does not yet exist]

<<<MAP: Chamber_Waves>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Resonance as contact — wave-particle duality staged as creature interaction, where the learner's frequency and the creature's frequency align or beat, and matching is felt rather than computed. | Sequence role: Catalyst chamber for the Wavefunctions sequence, the last map before returning to the Lab. After the sequence walked the learner through sine, pendulum, unit circle, propagation, sound, silence, and Fourier synthesis, this chamber closes Wavefunctions by making oscillation the shared variable of an encounter between two bodies. | Technical angle: Catalyst mode waveform, firing spir | [... truncated ...]
# BLURB: Your helix shots spiral through the air. The waterbomb bounces in rhythm. When your wave matches its frequency, something synchronizes.  This is the catalyst chamber for Wavefunctions — where oscillation becomes contact.…
[empty — file does not yet exist]
