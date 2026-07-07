# Sieve pass — phase: oscillation (forces, wavefunctions)

_Recorded 2026-05-13T10:30:00_

**Target:** the oscillation phase of the spine — sequences 5 (forces) and 6 (wavefunctions). After today's math-density bullet adds and the new change sequence at 4.5, this phase should have a clean conceptual foundation (calculus named in advance, vectors named in transformation already). The pass asks: do these two sequences carry the *oscillation* claim?

## 1. The claim

Phase declared as `oscillation`. The spine names it as the transition between *F_order* (static structure) and *E_entropy* (disorder). Both sequences should *oscillate* — neither pure structure nor pure noise.

- **forces (5):** `Newton's laws - vectors become physics`
- **wavefunctions (6):** `F ↔ E oscillation - sine creates curves`

## 2. The trace

**forces** truth: *"Direction + magnitude = vector. F = ma. Acceleration is the only thing you feel."*
- 17 learning objectives — by far the densest sequence in the spine. Covers vector basics through Hooke's law and n-body dynamics. **Now also names** derivative-as-rate-of-change (today's bullet add).
- 40 artifacts: `VectorBasics`, `VectorFieldFlow`, `chaos_attractor`, `combined_forces_demo`, `becoming_catalyst`, `catalyst_target`, …
- **qfep_connection:** "Vectors define system states — the S in QFEP. Forces introduce change — they drive the temporal evolution φΔE(S,t)."

**wavefunctions** truth: *"Everything oscillates. Fourier shows every signal is a sum of sines."*
- 7 learning objectives, **now including** exponential form + Fourier as integration in the limit.
- **82 artifacts** — the largest in the spine. Spans sine/cosine, FFT, audio synthesis, pendulums.
- **qfep_connection:** "Wavefunctions are the mathematical form of edge-of-chaos dynamics."

## 3. Per-sequence reading

| seq | declared claim | data carry |
|---|---|---|
| forces | vectors-become-physics | strong — VectorBasics through n-body all named, calculus now bridged |
| wavefunctions | sine-creates-curves, F↔E oscillation | strong but **swollen** — 82 artifacts is more than primitives' 67 |

**Forces verdict:** ✓ adequate. Today's `derivative as instantaneous rate` bullet closes the calculus gap. 17 objectives is dense but coherent.

**Wavefunctions verdict:** ⚠ adequate-but-overloaded. The 82-artifact mass suggests **two sub-arcs** under one name:
1. *Geometric oscillation*: unit circle, sine, cosine, phase (the curriculum's claim)
2. *Audio / Fourier*: synthesizer modules, audio racks, FFT visualizers (project-internal expansion, partially driven by other sequences pulling shaders/audio)

The two sub-arcs are pedagogically distinct. *Geometric oscillation* belongs with forces under `oscillation`. *Audio / Fourier* is a downstream application that might belong in its own slot or as a substrate inside lambda_edge.

## 4. Cross-sequence (the phase as a phase)

The forces → wavefunctions transition is one of the **cleanest** in the spine on paper: F=ma teaches change-rate; sine is the closed-form solution to `y'' = -y` (i.e., the simplest oscillator). The change sequence at 4.5 now bridges them — calculus named first, then applied to forces, then refined into wavefunctions.

However the *F ↔ E oscillation* framing only partially holds:
- *forces* primarily teaches deterministic mechanics. There's no E component made visible until the chaos_attractor and n-body artifacts at the end.
- *wavefunctions* claims `F ↔ E oscillation` but its main pedagogy is **geometric** (unit circle → sine), not **oscillatory between order and disorder**. The Fourier framing gestures at the F↔E claim but doesn't carry it.

The phase is *too clean*. Real F↔E oscillation lives in the chaos artifact at the end of forces and the beat-frequencies / double pendulum at the end of wavefunctions — but these are footnotes inside larger structural pedagogy.

## 5. Three-question sieve

### Thicken?
- Yes for *change-as-physical*: bridge from change (4.5) to forces (5) lets the player see calculus applied. Strong handle.
- Yes for *Fourier as integration*: today's wavefunctions bullet add makes this explicit.

### Foreclose?
- The phase's F↔E framing under-delivers. Naming "oscillation" promises a balance act between order and chaos; what we actually teach is *mechanics* + *waveforms*. A learner reading the phase label and then walking forces/wavefunctions may feel the chaos promise is unfulfilled.
- The wavefunctions size (82 artifacts) means many learners won't see the chaos endgame — they'll stop earlier in the sequence.

### Dark spot?
- *The felt difference between an oscillator at rest and at chaos* — the dampened-pendulum-becoming-double-pendulum moment. Visible but not centered.
- *Resonance as F↔E* — when a driving frequency matches a system's natural frequency, *the system's order becomes its instability*. This is the perfect F↔E lesson. It's nominally present (`Interference and resonance: when waves meet`) but not foregrounded.

## 6. Recommendations

1. **Split wavefunctions** (long-horizon, not this pass):
   - `wavefunctions` keeps the geometric oscillation core (unit circle → sine → Fourier).
   - A new sequence `audio_synthesis` or `acoustic_systems` could hold the synthesizer/FFT/audio-rack artifacts. Likely at λ_edge (audio as procedural generation in time).
   - **Defer until oscillation's first re-walk in headset confirms wavefunctions is bloated.**

2. **Foreground resonance** in wavefunctions: one map dedicated to *F↔E via resonance*. Use existing pendulum + audio artifacts. Probably already implicit in `WaveFunctions_Pendulum`; needs naming.

3. **Make F↔E explicit in forces** by promoting `chaos_attractor` from end-cap to standalone map. Currently buried; the n-body chaos moment is the oscillation-phase's truest expression.

4. **Phase truth statement** to add to `curriculum_spine.json` for oscillation:
   *"Things that move under rules can run smooth or run wild. Sine is the rule's most ordered output; chaos is its least. The phase oscillates between them — your job is to feel when."*

## 7. Reorder candidates

None within the phase. Forces → wavefunctions is right. **But:**
- **Move audio-heavy artifacts out** of wavefunctions into a new home (if/when audio_synthesis sequence is created).
- **Promote `chaos_attractor`** to a named final map in forces.

## 8. Verdict

Phase passes the sieve. After today's bullet additions and the new change sequence, the conceptual foundation is solid. The remaining work is **emphasis** (foreground resonance, surface chaos in forces) rather than restructure.

One load-bearing rule out:

> **In `oscillation`, the F↔E claim must be visible at least once per sequence.** Right now it's visible only in two artifacts (chaos_attractor, double_pendulum) buried at sequence-ends. The phase should explicitly produce *the feeling of order-becoming-disorder under continuous drive* — that's the pedagogical payload.
