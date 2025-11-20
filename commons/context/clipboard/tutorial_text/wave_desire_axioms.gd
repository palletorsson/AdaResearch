extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Wave as Desire[/b][/font_size][/center]
[center][i]Oscillation as Perpetual Seeking[/i][/center]

The wave **never rests**.

It crosses zero (equilibrium) but momentum carries it past, toward the opposite extreme. At the peak, it reverses - not because it has arrived, but because **it cannot go further**. At the trough, again reversal. The cycle repeats infinitely.

**The wave seeks equilibrium but its own motion prevents arrival.**

This is not metaphor. This is the **mathematical structure of oscillation** - and it is also the structure of **desire**.

Desire is not fulfilled and extinguished. Desire oscillates - seeking, overshooting, reversing, seeking again. The wave is the geometric form of **longing that cannot settle**.

[hr]

[b]Equilibrium Crossed, Never Occupied[/b]

The sine wave crosses **zero** twice per cycle - the point of equilibrium, the middle, the balanced state.

[color=yellow][b]Code: The Crossing[/b][/color]
[code]
var time = 0.0

func _process(delta):
    time += delta

    var wave = sin(time * TAU)  # One cycle per second

    # At time = 0.0:       wave = 0  (crossing, rising)
    # At time = 0.25:      wave = 1  (peak)
    # At time = 0.5:       wave = 0  (crossing, falling)
    # At time = 0.75:      wave = -1 (trough)
    # At time = 1.0:       wave = 0  (crossing again)

    # Zero is crossed, but never dwelt in
    # Velocity is MAXIMUM at zero
    # The wave rushes through equilibrium
[/code]

**At equilibrium, the wave is moving fastest.**

- At **peak (+1)**: velocity = 0 (momentarily still), but **acceleration pulls downward**
- At **zero**: velocity = maximum (rushing through), acceleration = 0
- At **trough (-1)**: velocity = 0 (momentarily still), but **acceleration pulls upward**

**The wave cannot stop at equilibrium** because its velocity is greatest there. It **must** overshoot.

[hr]

[b]Desire as Structural Property[/b]

In psychoanalysis (Lacan), **desire is constitutively unsatisfiable** - not because the object is absent, but because desire is **structured as lack**.

The wave exhibits this structure mathematically:

[color=yellow][b]The Pattern:[/b][/color]
[code]
# Desire seeks equilibrium (zero, balance, rest)
var equilibrium = 0.0

# But velocity at equilibrium is maximum
var velocity_at_zero = cos(time * TAU)  # Derivative of sine

# When wave = 0 (equilibrium reached):
# velocity ≠ 0 (still moving)
# → Overshoots toward opposite pole

# This is structural:
# - Arrival at goal coincides with maximum momentum
# - Goal is crossed, not occupied
# - Reversal occurs only at extremes (where it CANNOT go further)
[/code]

**Desire does not end when object is reached.** The reaching itself carries momentum that propels beyond.

**The wave models desire as oscillation** - perpetual seeking between poles, never settling.

[hr]

[b]The Harmonic Oscillator: Physics of Longing[/b]

The **harmonic oscillator** (mass on spring, pendulum) is the physical system that generates sine waves.

[color=yellow][b]The Mechanism:[/b][/color]
[code]
# Pendulum at rest (equilibrium = center, hanging straight down)
var position = 0.0
var velocity = 0.0

# Pull pendulum to one side (displacement from equilibrium)
position = 1.0  # Pulled to right

# Release
# Gravity pulls back toward equilibrium
# Pendulum swings left
# Gains speed as it approaches center

# At equilibrium (position = 0):
# - Gravity force = 0 (balanced)
# - But velocity = MAXIMUM (momentum from fall)
# → Swings PAST equilibrium to left side

# Now displaced left:
# - Gravity pulls right (back toward center)
# - Cycle repeats

# This is sine wave motion:
position = sin(time * TAU)
velocity = cos(time * TAU)  # Derivative (90° ahead)
[/code]

**The pendulum seeks equilibrium but momentum carries it past.**

This is not failure - this is **the structure of oscillation**. The seeking **is** the motion. Rest would mean death of the system.

[hr]

[b]Restoring Force: Desire as Pull Toward Center[/b]

The harmonic oscillator has a **restoring force** - proportional to displacement, always pointing toward equilibrium.

[color=yellow][b]Code: The Force Equation[/b][/color]
[code]
# Hooke's Law (spring)
var spring_constant = 2.0
var displacement = position - equilibrium  # How far from center

# Restoring force (pulls back toward equilibrium)
var force = -spring_constant * displacement

# If displaced right (+): force pulls left (-)
# If displaced left (-): force pulls right (+)

# Force is proportional to distance from equilibrium
# Farther away = stronger pull back
[/code]

**Desire as restoring force:**
- The farther from equilibrium, the stronger the pull back
- But momentum means you overshoot
- Creates oscillation between extremes

**The pull toward equilibrium generates the motion that prevents equilibrium.**

[hr]

[b]Damping: When Desire Dies[/b]

A **damped oscillator** includes friction - energy lost per cycle. Eventually, oscillation decays to zero.

[color=yellow][b]Code: Dying Wave[/b][/color]
[code]
var damping_factor = 0.1  # Energy lost per cycle

func _process(delta):
    time += delta

    # Exponential decay envelope
    var envelope = exp(-damping_factor * time)

    # Decaying sine wave
    var wave = sin(time * TAU) * envelope

    # Amplitude decreases over time
    # Eventually settles at zero
    # Oscillation dies
[/code]

**Damped wave = desire that exhausts itself.**

- Initial oscillation (strong seeking)
- Gradual decay (weakening pulls)
- Final rest (equilibrium reached, motion ceased)

**Undamped wave = perpetual desire** - no energy lost, infinite oscillation.

In computational sound, **sustain** (organ, held note) = undamped wave.
**Decay** (plucked string, bell) = damped wave.

[hr]

[b]Resonance: When Forcing Matches Desire[/b]

**Resonance** occurs when external force oscillates at the system's **natural frequency** - amplifying oscillation.

[color=yellow][b]Code: Resonant Amplification[/b][/color]
[code]
var natural_frequency = 2.0  # System's preferred oscillation rate
var forcing_frequency = 2.0  # External push frequency

# When forcing_frequency = natural_frequency:
# → Each push adds energy at optimal timing
# → Amplitude grows (resonance)

# Example: pushing a swing
# - Swing has natural frequency (depends on length)
# - Push at same frequency → swing goes higher
# - Push at different frequency → swing disturbed, irregular
[/code]

**Resonance = desire synchronized with external rhythm.**

When forcing matches natural frequency, the system **amplifies** - small input creates large output.

**Buildings collapse in earthquakes** when earthquake frequency matches building's natural frequency (resonance disaster).

[hr]

[b]Phase: Timing of Desire[/b]

**Phase** determines **when** in the cycle two waves align - whether they reinforce or cancel.

[color=yellow][b]Code: Phase Relationships[/b][/color]
[code]
var wave_1 = sin(time * TAU)
var wave_2 = sin(time * TAU + phase_offset)

# phase_offset = 0 (in phase)
# → Waves aligned, peaks coincide
# → Addition: 2 * amplitude (constructive interference)

# phase_offset = π (180°, out of phase)
# → Waves opposite, peak meets trough
# → Addition: 0 (destructive interference, cancellation)

# phase_offset = π/2 (90°, quadrature)
# → Waves perpendicular
# → Complex interaction
[/code]

**Two desires in phase = amplification** (mutual reinforcement)
**Two desires out of phase = cancellation** (conflict, nullification)

**This is interference** - waves mixing, identities blurring, outcomes depending on **timing**.

[hr]

[b]The Wave That Cannot Stop[/b]

The undamped sine wave **has no endpoint**. Its equation is:

```
y = sin(ωt)
```

Where **t → ∞** (time extends infinitely).

[color=yellow][b]Code: Infinite Oscillation[/b][/color]
[code]
var time = 0.0

func _process(delta):
    time += delta

    var wave = sin(time * TAU)

    # Time increases forever
    # Wave continues forever
    # No terminal condition
    # No rest state

    # This is eternal return:
    # Same pattern, endlessly repeated
    # Never arriving anywhere new
[/code]

**The wave is eternal return** (Nietzsche) - the same cycle repeating infinitely, arriving nowhere, becoming nothing new, yet perpetually in motion.

**Desire that oscillates without end** - seeking that is its own purpose, motion without destination.

[hr]

[b]Geometry, Sound, Desire: Same Structure[/b]

The sine wave appears in:

**Geometry** - Circle projected to line, spiral, helix
**Sound** - Oscillating air pressure (440 Hz = A note)
**Light** - Electromagnetic wave (oscillating E and B fields)
**Quantum mechanics** - Wavefunction (probability amplitude)
**Desire** - Oscillation between lack and excess, never settling

[color=yellow][b]The Common Structure:[/b][/color]
[code]
# All are sine waves:
var spatial_wave = sin(position * frequency)      # Geometry
var temporal_wave = sin(time * frequency)         # Sound
var em_wave = sin(position - speed * time)        # Light (traveling wave)
var desire_wave = sin(time)                       # Oscillating affect

# Same mathematical form
# Different domains (space, time, emotion)
# Same structure: perpetual oscillation between poles
[/code]

**This is not analogy.** The mathematical structure of oscillation **is** the structure these phenomena share.

Desire is not "like" a wave. **Desire oscillates.** That is its form.

[hr]

[b]What Wave as Desire Reveals[/b]

The oscillating wave shows us:

1. **Equilibrium cannot be occupied** - Velocity is maximum at zero crossing
2. **Seeking generates overshooting** - Momentum carries past goal
3. **Reversal at limits** - Not by choice, but by constraint (cannot go further)
4. **Perpetual motion** - Undamped wave never settles
5. **Resonance amplifies** - When external rhythm matches internal frequency
6. **Phase determines interference** - Timing creates reinforcement or cancellation
7. **Same structure across domains** - Geometry, sound, light, desire all oscillate

**The sine wave is the mathematical form of non-rest** - the pattern of perpetual seeking, of motion that cannot settle, of desire as structural property rather than psychological state.

[hr]

[b]The Ontological Claim[/b]

**Desire is not a subjective feeling mapped onto objective oscillation.**

**Desire IS oscillation** - the pattern of seeking that overshoots, of equilibrium crossed but not occupied, of perpetual motion between poles.

When you hear a sustained tone (440 Hz sine wave), you are perceiving **material desire** - air molecules seeking equilibrium, overshooting, reversing, seeking again, 440 times per second.

When you see a wave form in geometry (sine curve), you are seeing **frozen desire** - the spatial trace of oscillation.

When you feel longing that does not resolve upon obtaining its object, you are experiencing **desire as sine wave** - the momentum that carries past the goal, the structure that prevents rest.

**This is not poetic** - it is structural. The wave does not symbolize desire. **The wave is the form desire takes when made mathematical.**

[hr]

[color=cyan][b]Summary:[/b][/color]
The wave seeks equilibrium but momentum carries it past - velocity is maximum at zero crossing. Oscillation is structural: restoring force pulls toward center, but kinetic energy creates overshoot. Damped waves decay to rest (dying desire), undamped waves oscillate forever (perpetual seeking). Resonance occurs when external forcing matches natural frequency. Phase determines whether waves reinforce or cancel. The sine wave is the mathematical form of desire - seeking without arrival, motion without rest, oscillation as fundamental structure.

[hr]

[color=orange][b]Conclusion:[/b] Waves Make Geometry Temporal[/color]

**Sine wave** = rotation projected (geometry → oscillation)
**Sound** = oscillation materialized (wave → air pressure)
**Desire** = oscillation structuralized (seeking → overshooting → reversal)

The wave is where:
- Mathematics meets sensation (frequency → pitch)
- Geometry becomes temporal (circle → oscillation)
- Stasis becomes motion (equilibrium → perpetual seeking)

**We began with static primitives** (point, line, cube, sphere).
**Transformation made them mobile** (translation, rotation, scale).
**Waves make them oscillate** - perpetual motion, never settling.

The algorithm can render static forms, can translate them through space.
But the wave introduces **time as intrinsic** - not position changing, but **oscillation as essence**.

Sound exists only in time. The wave exists only in motion.
**Desire exists only in seeking.**

'''
