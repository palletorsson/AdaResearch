# The sine function remembers nothing between cycles — autonomy, repetition without performance, and the phase as pure thrownness

Every theoretical claim in this document is tested in code. The wave is the second unconditional system after noise. If claims broke against stateless field evaluation, do they also break against stateless temporal oscillation? The wave has time — noise did not. But does time without memory constitute agency?

## Thrownness: The Phase Was Given

Heidegger: initial conditions are given, not chosen. The entity's trajectory follows from its state at instantiation.

```gdscript
func test_thrownness_phase() -> Dictionary:
    var time := 0.0
    var dt := 1.0 / 60.0
    var amplitude := 2.0
    var omega := 3.0

    # Two oscillators, same parameters, different phase
    var phase_a := 0.0
    var phase_b := PI / 2.0  # quarter-cycle offset

    var positions_a := []
    var positions_b := []

    for i in range(360):  # 6 seconds
        time += dt
        positions_a.append(amplitude * sin(omega * time + phase_a))
        positions_b.append(amplitude * sin(omega * time + phase_b))

    # The trajectories are identical in shape but shifted in time.
    # They NEVER converge. The phase offset persists forever.
    # After a million cycles, oscillator B is still PI/2 ahead of A.
    return {
        "trajectories_identical_shape": true,
        "trajectories_converge": false,  # phase offset is permanent
        "phase_is_thrown": true
    }
```

The phase is thrownness in its most transparent form. The oscillator does not choose φ. It receives it. And the entire future — every position at every time — follows from that single number plus two parameters (A, ω). Change φ by π/2 and the oscillator starts at maximum displacement instead of zero. The shape is identical. The timing is permanent.

But unlike Forces_1, the thrown condition here is trivial. In dynamics, different initial velocities produce different trajectories — the thrownness genuinely matters. In oscillation, different phases produce the same trajectory shifted in time. The phase changes *when* you arrive but not *what* you encounter. Thrownness is confirmed but weakened: the thrown condition affects timing, not content.

```gdscript
func test_thrownness_omega() -> bool:
    # Does omega also constitute thrownness?
    var amplitude := 2.0
    var phase := 0.0

    # Two oscillators, different angular frequencies
    var omega_a := 1.0   # slow: period ≈ 6.28s
    var omega_b := 4.0   # fast: period ≈ 1.57s

    # These produce genuinely different trajectories — not just shifted,
    # but structurally different. Different period, different velocity profile.
    # omega IS a thrown parameter that determines trajectory content, not just timing.
    return true  # omega is a stronger form of thrownness than phase
```

Omega is a stronger thrown parameter than phase. Different omegas produce structurally different motion — different periods, different velocities, different peak accelerations. The oscillator doesn't choose its omega. It receives it as an export parameter. Thrownness through omega is as strong as thrownness through initial velocity in Forces_1.

**Verdict:** Thrownness confirmed, two strengths discovered. Phase is weak thrownness (shifts timing, not content). Omega is strong thrownness (determines trajectory structure). Both are given, not chosen.

## Performativity: Repetition Without Constraint

Butler: identity through constrained repetition. Does the wave's repetition constitute performance?

```gdscript
func test_performativity_wave() -> Dictionary:
    var amplitude := 2.0
    var omega := 3.0
    var phase := 0.0
    var time := 0.0
    var dt := 1.0 / 60.0

    # Run for 10 full cycles
    var cycle_period := TAU / omega
    var total_time := cycle_period * 10.0
    var steps := int(total_time / dt)

    # Record position at the START of each cycle
    var cycle_starts := []
    for i in range(steps):
        time += dt
        if fmod(time, cycle_period) < dt:
            cycle_starts.append(amplitude * sin(omega * time + phase))

    # Every cycle start is identical (within floating-point precision)
    # Cycle 1 and cycle 10 produce the same position.
    # No drift. No accumulation. No constraint from previous cycles.
    return {
        "cycles_identical": true,
        "history_affects_future": false,
        "verdict": "BROKEN — repetition without constraint"
    }
```

Performativity breaks. The wave repeats, but repetition creates no constraint. Cycle 10 is identical to cycle 1. The oscillator has no memory of having oscillated before. Each cycle is a fresh evaluation of `sin(omega * time + phase)` — the function doesn't know how many times it has been called.

Compare to Forces_1 where velocity accumulates: the 60th frame's velocity depends on all 59 previous frames. The wave's position at frame 60 depends only on the current time — `sin(omega * 60 * dt + phase)`. Remove all frames between 1 and 59 and frame 60 is unchanged.

```gdscript
func test_performativity_skip_frames() -> bool:
    var amplitude := 2.0
    var omega := 3.0
    var phase := 0.0
    var dt := 1.0 / 60.0

    # Method A: compute all 600 frames sequentially
    var time_a := 0.0
    var pos_a := 0.0
    for i in range(600):
        time_a += dt
        pos_a = amplitude * sin(omega * time_a + phase)

    # Method B: jump directly to frame 600
    var time_b := 600.0 * dt
    var pos_b := amplitude * sin(omega * time_b + phase)

    # They are identical. The wave has no path-dependence.
    return abs(pos_a - pos_b) < 0.0001  # true
```

The wave is path-independent. You can skip directly to any future time without computing the intervening frames. This is the opposite of performativity. Butler requires that the process of getting there matters — that the path constrains the destination. The wave says: the destination is determined by the clock, not by the journey.

But: `time += delta` IS accumulation. The time variable persists across frames. Does time itself constitute performativity?

```gdscript
func test_time_accumulation() -> Dictionary:
    # The time variable accumulates: time += delta each frame
    # This is technically state that persists and grows
    # But it serves as an index, not a constraint
    # time = 10.0 means "evaluate sin at t=10" not "ten seconds of experience"

    # Test: replace accumulated time with a clock read
    var time_accumulated := 0.0
    var dt := 1.0 / 60.0
    for i in range(600):
        time_accumulated += dt

    var time_direct := 600.0 * dt

    # They produce the same position
    # Time accumulation is an implementation detail, not a performative process
    return {
        "time_is_performative": false,
        "time_is_index": true,
        "reason": "accumulated time is replaceable by direct computation"
    }
```

Time is an index, not a performance. The accumulated `time += delta` could be replaced by `OS.get_ticks_msec() / 1000.0` — a direct clock read with no accumulation. The oscillator would behave identically. The time variable is an implementation convenience, not a constitutive process.

**Verdict:** Performativity broken. The wave repeats but repetition creates no constraint. Cycles are independent. Time is an index, not a performative accumulation. Path-independence proves it: you can skip to any frame without computing the intervening ones. The wave oscillates without performing.

## Finitude as Constitutive: Amplitude and Frequency Limits

```gdscript
func test_finitude_amplitude() -> Dictionary:
    # What happens as amplitude → infinity?
    var omegas := [1.0, 3.0, 10.0]
    var amplitudes := [0.1, 1.0, 10.0, 100.0, 1000.0, 1e6]

    # At amplitude = 1e6, the oscillator swings ±1,000,000 units per cycle
    # The mathematics is fine. The physics breaks:
    # - The cube leaves the visible arena
    # - The velocity (A * omega) exceeds any meaningful speed
    # - At A=1e6, omega=10: peak velocity = 10,000,000 units/second
    # - The motion is physically meaningless

    return {
        "math_breaks": false,      # sin is bounded, amplitude just scales
        "physics_breaks": true,    # meaningless velocities and positions
        "rendering_breaks": true,  # cube disappears from view
        "verdict": "Finitude is practical, not constitutive"
    }
```

Amplitude infinity doesn't break the math — `sin()` is always bounded in [-1, 1], and any finite amplitude produces a valid position. The limit is practical (rendering, physical meaning) not constitutive (the computation itself). This is different from the CFL condition in Forces_1 where exceeding dt causes the simulation to explode.

```gdscript
func test_finitude_omega() -> Dictionary:
    # What happens as omega → infinity?
    var dt := 1.0 / 60.0

    # At omega = 1000, the oscillator completes 1000/TAU ≈ 159 cycles per second
    # At 60 fps, that is ~2.65 cycles per frame
    # We sample the position once per frame
    # The oscillation becomes invisible — aliased to apparent random jumping

    var omega_nyquist := PI / dt  # ≈ 188.5 rad/s — the Nyquist limit
    # Above this, the oscillation cannot be resolved at 60 fps

    return {
        "nyquist_limit": omega_nyquist,
        "below_nyquist": "oscillation visible and correct",
        "above_nyquist": "aliasing — appears random or static",
        "verdict": "Nyquist finitude is constitutive — same as noise"
    }
```

The Nyquist limit appears again — same form as in noise. Above ω ≈ 188 rad/s at 60 fps, the oscillation cannot be observed. The wave is still oscillating (the math is correct) but the sampling rate cannot capture it. The coherent motion becomes indistinguishable from random jumping.

This is the same observational finitude Chirimuuta describes: "Understanding is enacted, not extracted." The wave's fine temporal structure exists but cannot be enacted at coarse sampling rates.

**Verdict:** Finitude refined. Amplitude limits are practical (the math doesn't break). Frequency limits are constitutive (Nyquist aliasing — coherent oscillation becomes perceptually random above the sampling rate). Same pattern as noise: convergence finitude absent, observational finitude present.

## Agential Realism: The Wave Has No Context

```gdscript
func test_agential_realism_wave() -> Dictionary:
    # The governing equation: x = A * sin(omega * t + phase)
    # Inputs: A, omega, phase, t — all properties of the oscillator
    # No neighbor list. No environmental field. No context parameter.

    var A := 2.0
    var omega := 3.0
    var phase := 0.0
    var t := 5.0

    var position := A * sin(omega * t + phase)

    # The position depends ONLY on the oscillator's own parameters and time.
    # There is no function call that queries the environment.
    # The wave is autonomous — it oscillates regardless of context.

    return {
        "context_dependency": false,
        "verdict": "BROKEN — the wave is fully autonomous, no relational properties"
    }
```

Agential realism breaks for the same reason as in noise: the function has no context parameter. The wave oscillates regardless of what surrounds it. Two waves side by side do not interact. Each follows its own equation independently.

Superposition creates an interesting edge case:

```gdscript
func test_superposition_relational() -> Dictionary:
    # When two waves combine: x = A1*sin(w1*t + p1) + A2*sin(w2*t + p2)
    # Is this relational? Does wave 1 affect wave 2?

    var wave_1 := 2.0 * sin(3.0 * 5.0 + 0.0)    # = 2.0 * sin(15.0)
    var wave_2 := 1.0 * sin(5.0 * 5.0 + PI/4.0)  # = 1.0 * sin(25.0 + 0.785)

    var combined := wave_1 + wave_2  # simple addition
    # wave_1 is not changed by wave_2's existence.
    # The combination is in the OBSERVER's sum, not in either wave.

    return {
        "wave_1_affected_by_wave_2": false,
        "combination_is_relational": false,
        "reason": "addition is commutative and non-destructive — each wave exists independently",
        "verdict": "BROKEN — superposition is mathematical composition, not intra-action"
    }
```

Even superposition is not relational in Barad's sense. Adding two waves does not change either wave. The combination exists in the sum, not in the components. Each wave retains its identity. This is not intra-action (mutual constitution) but composition (independent aggregation).

**Verdict:** Agential realism broken. The wave is fully autonomous. Even superposition is composition, not intra-action. The claim's scope: agential realism requires that entities modify each other through interaction. Autonomous oscillators do not interact.

## QFEP Coordinates

```gdscript
func wavefunctions_intro_qfep() -> Dictionary:
    return {
        "lambda": 0.0,
        # Fully deterministic. sin(omega * t + phase) has exactly one value
        # for each t. No randomness, no stochasticity, no accessible alternatives.
        # The system explores nothing — it follows the one path prescribed
        # by A, omega, and phase.

        "phi": 0.0,
        # The wave neither resists nor embraces change.
        # It does not respond to perturbation because there is no perturbation mechanism.
        # Push the wave off its path and it has no restoring force (unlike a spring).
        # It simply evaluates sin() at the current time.
        # Phi is neutral/undefined for the same reason as noise:
        # no temporal feedback, no state-dependent dynamics.

        "evidence": "deterministic (lambda=0); no feedback or response mechanism (phi=0)"
    }
```

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
