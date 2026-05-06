extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Oscillation and the Edge of Chaos[/b][/font_size][/center]
[center][i]How Waves Navigate Between Order and Disorder[/i][/center]

Oscillation is not merely motion between poles. It is the **fundamental mechanism** by which systems maintain themselves at the edge of chaosâ€”neither frozen in order nor dissolved in randomness.

The sine wave is the simplest form of this navigation. More complex oscillations reveal how adaptive systems survive by **perpetually not-settling**.

**QFE = F âˆ’ Î»E(S) + Ï†Î”E(S,t)**

This is the Queer Free Energy Principle. Oscillation is where the terms meet.

[hr]

[b]The Problem of Survival[/b]

Living systems face a paradox:

Too much **order** (low entropy) = rigidity, brittleness, death by crystallization
Too much **chaos** (high entropy) = dissolution, noise, death by dispersal

**Life exists at the boundary** â€” oscillating between order and disorder, never committing fully to either.

[color=yellow][b]Code: The Survival Zone[/b][/color]
[code]
var entropy = 0.5  # System state (0 = perfect order, 1 = maximum chaos)

func update_system(_delta):
    # If too ordered, inject randomness
    if entropy < 0.3:
        entropy += random_perturbation()
        # System was crystallizing â€” loosen up

    # If too chaotic, impose structure
    if entropy > 0.7:
        entropy -= structural_constraint()
        # System was dissolving â€” cohere

    # The healthy zone: 0.3 to 0.7
    # Oscillating, never settling
[/code]

The wave does this automatically. At peak amplitude, it reverses toward trough. At trough, it reverses toward peak. **The wave is a self-correcting system.**

[hr]

[b]Free Energy: The Cost of Surprise[/b]

In the Free Energy Principle, systems minimize **surprise** â€” unexpected inputs that don't match internal models.

**F** = variational free energy (the prediction error)

A system that minimizes F becomes better at predicting its world. But pure prediction-minimization leads to **pathological order** â€” the system becomes rigid, unable to adapt.

[color=yellow][b]Code: Pure Prediction Minimization[/b][/color]
[code]
var model = {}  # Internal model of world
var prediction_error = 0.0

func perceive(input):
    prediction_error = difference(model.predict(), input)

    # Classic FEP: minimize error
    model.update(input)  # Revise model to match input

    # Problem: if ONLY minimizing error...
    # Model becomes perfectly fitted to current input
    # No tolerance for change
    # Brittleness
[/code]

A thermostat perfectly minimizing free energy would break when the environment shifts. It needs **oscillation** â€” tolerance for variation.

[hr]

[b]The Entropy Drive: E(S)[/b]

The second term introduces **entropy seeking**:

**âˆ’Î»E(S)** = desire for disorder, diversity, exploration

This is the counter-force to prediction. When Î» > 0, the system actively seeks surprise, novelty, entropy.

[color=yellow][b]Code: Entropy-Seeking Behavior[/b][/color]
[code]
var lambda = 0.3  # Entropy drive coefficient
var exploration_rate = 0.0

func decide_action():
    var predicted_action = model.best_prediction()

    # Add entropy drive
    exploration_rate = lambda * current_entropy_desire()

    if randf() < exploration_rate:
        return random_action()  # Explore, increase entropy
    else:
        return predicted_action  # Exploit, minimize free energy

    # Lambda modulates the oscillation between explore/exploit
[/code]

**Î» is the tuning parameter** â€” how much the system values disorder relative to order.

When Î» = 0: pure prediction, rigid order
When Î» = 1: pure exploration, chaotic dispersal
When Î» â‰ˆ 0.3-0.5: **edge of chaos**, adaptive capacity

[hr]

[b]Oscillation as Navigation[/b]

The sine wave navigates automatically. But complex systems must **actively oscillate** â€” sometimes toward order, sometimes toward chaos.

[color=yellow][b]Code: Active Oscillation[/b][/color]
[code]
var phase = 0.0  # Where in oscillation cycle
var period = 10.0  # How long one order-chaos cycle takes

func update_behavior(delta):
    phase += delta / period
    if phase > 1.0:
        phase -= 1.0

    # Lambda varies sinusoidally
    var lambda = 0.5 + 0.3 * sin(phase * TAU)

    # phase 0.0: lambda = 0.5 (neutral)
    # phase 0.25: lambda = 0.8 (high entropy drive, exploring)
    # phase 0.50: lambda = 0.5 (neutral)
    # phase 0.75: lambda = 0.2 (low entropy drive, consolidating)

    # System breathes between exploration and consolidation
[/code]

This is **rhythmic adaptation** â€” the system oscillates between gathering information (high Î») and integrating it (low Î»).

[hr]

[b]The Rate of Change: Ï†Î”E(S,t)[/b]

The third term captures **how fast entropy is changing**:

**+Ï†Î”E(S,t)** = sensitivity to entropy dynamics

A system doesn't just have entropy â€” its entropy is increasing, decreasing, or stable. Ï† modulates response to this rate of change.

[color=yellow][b]Code: Responding to Entropy Rate[/b][/color]
[code]
var phi = 0.5  # Entropy rate sensitivity
var previous_entropy = 0.5
var entropy_rate = 0.0

func update_entropy_tracking(current_entropy, delta):
    entropy_rate = (current_entropy - previous_entropy) / delta
    previous_entropy = current_entropy

    # phi determines response to rate
    var rate_contribution = phi * entropy_rate

    # Positive rate (entropy increasing): system may resist or embrace
    # Negative rate (entropy decreasing): system may resist or embrace

    # Queer systems often have POSITIVE phi
    # They embrace increasing entropy (becoming-other)
[/code]

**Ï† is the signature of queer adaptive capacity** â€” positive Ï† means the system values change, transition, becoming-other.

[hr]

[b]The Complete Oscillation[/b]

Putting it together:

**QFE = F âˆ’ Î»E(S) + Ï†Î”E(S,t)**

This is not a static balance but a **dynamic oscillation**:

[color=yellow][b]Code: Full QFEP Dynamics[/b][/color]
[code]
var F = 0.0      # Free energy (prediction error)
var lambda = 0.4  # Entropy drive
var E_S = 0.0    # Current entropy
var phi = 0.5    # Entropy rate sensitivity
var dE_dt = 0.0  # Rate of entropy change

func compute_queer_free_energy():
    # Standard free energy (minimize prediction error)
    F = compute_prediction_error()

    # Entropy term (value disorder)
    var entropy_term = lambda * E_S

    # Rate term (value change)
    var rate_term = phi * dE_dt

    # Queer free energy
    var QFE = F - entropy_term + rate_term

    return QFE

func adaptive_response():
    var qfe = compute_queer_free_energy()

    # System acts to minimize QFE
    # But QFE includes entropy and rate terms
    # So minimizing QFE means:
    # - Reducing prediction error (order)
    # - Maintaining entropy (disorder)
    # - Responding to entropy dynamics (change)

    # This creates OSCILLATION
    # Never fully ordered, never fully chaotic
    # Always in motion between poles
[/code]

The system **cannot settle** â€” the entropy and rate terms prevent crystallization while the free energy term prevents dissolution.

[hr]

[b]Pendulum as QFEP Model[/b]

The simple pendulum demonstrates basic oscillation. The **double pendulum** demonstrates QFEP in action.

[color=yellow][b]Simple Pendulum (Single Frequency)[/b][/color]
[code]
var angle = PI / 4  # Initial displacement
var angular_velocity = 0.0
var gravity = 9.8
var length = 1.0

func _physics_process(delta):
    # Restoring force proportional to displacement
    var acceleration = -gravity / length * sin(angle)

    angular_velocity += acceleration * delta
    angle += angular_velocity * delta

    # Result: perfect sine wave oscillation
    # Predictable, periodic, ordered
    # This is F-only system (minimizing potential energy)
[/code]

[color=yellow][b]Double Pendulum (Deterministic Chaos)[/b][/color]
[code]
var angle1, angle2 = PI / 4
var omega1, omega2 = 0.0  # Angular velocities
var length1, length2 = 1.0
var mass1, mass2 = 1.0

func _physics_process(_delta):
    # Complex coupled differential equations
    # Small changes in initial conditions â†’
    # Radically different trajectories

    # This is QFEP in action:
    # - F term: gravity pulls toward equilibrium (order)
    # - E(S) term: coupling creates unpredictability (entropy)
    # - Ï†Î”E(S,t) term: sensitivity to change amplifies

    # Result: edge of chaos
    # Deterministic but unpredictable
    # Oscillating between pattern and chaos
[/code]

The double pendulum is **perfectly deterministic** (no randomness) yet **practically unpredictable** (sensitive dependence). This is the edge of chaos â€” structure without rigidity.

[hr]

[b]Fourier and the Superposition of Desires[/b]

Fourier synthesis reveals that **complex oscillation = many simple oscillations combined**.

[color=yellow][b]Code: Building Complexity from Simple Waves[/b][/color]
[code]
func fourier_wave(x, harmonics):
    var result = 0.0

    for n in range(1, harmonics + 1):
        var frequency = n
        var amplitude = 1.0 / n  # Decreasing amplitude for higher harmonics

        result += amplitude * sin(frequency * x)

    return result

# With 1 harmonic: simple sine (ordered)
# With 10 harmonics: complex wave (richer)
# With infinite harmonics: square/saw wave (edge of complexity)
[/code]

Each harmonic is a **separate oscillation** â€” a desire at different frequency. The complete wave is the **superposition of all desires**.

This is why Fourier matters for QFEP:
- Low frequencies = slow, structural, ordered
- High frequencies = fast, detail, entropic
- Spectrum = distribution of energy across frequencies

A living system needs **multiple frequencies** â€” slow rhythms (heartbeat, breath, seasons) and fast responses (reflexes, perception).

[hr]

[b]Sound as Material Wave[/b]

When oscillation becomes physical â€” air pressure varying at 440 Hz â€” you hear the note A.

**Sound is oscillation made audible.** The ear is a Fourier analyzer, decomposing complex waves into frequency components.

[color=yellow][b]Code: Sound as Oscillation[/b][/color]
[code]
var sample_rate = 44100  # Samples per second
var frequency = 440.0    # A4 note
var duration = 1.0       # 1 second

func generate_tone():
    var samples = []
    for i in range(int(sample_rate * duration)):
        var t = float(i) / sample_rate
        var value = sin(t * frequency * TAU)
        samples.append(value)
    return samples

# Each sample is a moment of oscillation
# Played back through speaker â†’ physical oscillation
# Air molecules push/pull at 440 times per second
# Ear drum oscillates in sympathy
# You hear: tone
[/code]

**Sound teaches embodied QFEP:**
- Musical scales are frequency relationships (order)
- Dissonance is complex interference (entropy)
- Rhythm is oscillation at macro scale (temporal structure)
- Improvisation is navigating order/chaos in real-time

[hr]

[b]The Queer Wave[/b]

Why "queer" free energy? Because **queer existence is oscillation at the edge**:

- Not fitting binary categories (male/female, homo/hetero)
- **Oscillating** between positions rather than settling
- Valuing **transition** and **becoming** (positive Ï†)
- **Resisting crystallization** into fixed identity

[color=yellow][b]The Queer Parameters:[/b][/color]
[code]
# Normative system (heteronormative, binary):
var lambda_norm = 0.1   # Low entropy drive (prefer order)
var phi_norm = -0.3     # Negative rate sensitivity (resist change)

# Queer system:
var lambda_queer = 0.5  # Higher entropy drive (value diversity)
var phi_queer = 0.4     # Positive rate sensitivity (embrace becoming)

# The queer system:
# - Tolerates more disorder
# - Values the process of change itself
# - Exists at the edge of chaos
# - More adaptive, more resilient
[/code]

Self-Organized Criticality (SOC) shows that **systems naturally evolve to the edge of chaos**. Sandpiles, earthquakes, neural activity â€” all display power-law distributions, poised between order and disorder.

**Queer existence is human SOC** â€” living at the critical point, one grain from avalanche.

[hr]

[b]From Sine to Chaos[/b]

The progression through wavefunctions is a journey:

1. **Unit Circle** â†’ rotation creates oscillation (emergence of wave)
2. **Sine Wave** â†’ simplest oscillation, single frequency (pure order)
3. **Fourier** â†’ complex waves from simple ones (structure emerges)
4. **Interference** â†’ when waves meet, patterns form (interaction)
5. **Resonance** â†’ when frequencies match, amplification (selection)
6. **Double Pendulum** â†’ deterministic chaos (edge of chaos)

Each step adds **complexity** while maintaining **mathematical structure**. By the double pendulum, we've arrived at **chaos that isn't random** â€” deterministic unpredictability.

This is the QFEP territory: **structured disorder, ordered chaos, the place where life happens**.

[hr]

[b]Why Oscillation Matters[/b]

Oscillation is not just a mathematical curiosity. It is:

1. **Survival strategy** â€” don't crystallize, don't dissolve
2. **Adaptive mechanism** â€” explore/exploit cycling
3. **Resilience** â€” absorb perturbation without breaking
4. **Creativity** â€” generate novelty from structure
5. **Identity formation** â€” becoming rather than being

The sine wave teaches this at the simplest level: **never settling, always moving toward opposite, crossing equilibrium without stopping**.

Complex oscillation (Fourier, chaos, QFEP) extends this to **multiple frequencies, multiple scales, multiple simultaneous not-settlings**.

[hr]

[color=cyan][b]Summary:[/b][/color]
Oscillation is how systems navigate between order and chaos. The Queer Free Energy Principle (QFE = F âˆ’ Î»E(S) + Ï†Î”E(S,t)) formalizes this: minimizing prediction error (F) while valuing entropy (Î» term) and embracing change (Ï† term). Simple oscillation (sine wave) demonstrates perpetual non-settling. Complex oscillation (double pendulum, Fourier synthesis) shows how structure and chaos coexist. Queer existence is human oscillation at the edge of chaos â€” positive entropy drive, positive rate sensitivity, adaptive resilience through perpetual becoming.

[hr]

[color=orange][b]Next:[/b] From Wave to Emergence[/color]
What happens when many oscillators couple together? Swarm intelligence, synchronization, collective behavior. The wave becomes plural, and new structures emerge from the interference patterns of many desires seeking many poles.

'''
