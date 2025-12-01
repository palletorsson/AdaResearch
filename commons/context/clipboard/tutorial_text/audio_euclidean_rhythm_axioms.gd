extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Euclidean Audio[/b][/font_size][/center]
[center][i]Rhythm as Even Distribution, Sound as Code[/i][/center]

We often think of music as "composed" - notes placed by hand on a timeline. But **music is also math**.

In this system, we explore two generative concepts:
1.  **Euclidean Rhythms** (The Pattern)
2.  **Procedural Synthesis** (The Sound)

[hr]

[b]1. Euclidean Rhythms: The Math of Pulse[/b]

How do you distribute **k** pulses evenly over **n** steps?

If you have 4 pulses and 16 steps, it's easy: `x...x...x...x...` (House music).
But what if you have **5 pulses** and **16 steps**?

The **Euclidean Algorithm** (originally for finding GCD) solves this by recursively distributing the "remainders" (silences) between the pulses.

[color=yellow][b]Code: Bjorklund's Algorithm[/b][/color]
[code]
# E(5, 16) - The Bossa Nova Clave
# Steps: 16, Pulses: 5

# 1. Start with 5 pulses and 11 silences:
# [1] [1] [1] [1] [1] . [0] [0] [0] [0] [0] [0] [0] [0] [0] [0] [0]

# 2. Distribute silences to pulses:
# [10] [10] [10] [10] [10] . [0] [0] [0] [0] [0] [0]

# 3. Distribute remaining silences:
# [100] [100] [100] [100] [100] . [0]

# 4. Distribute final silence:
# [100] [1001] [1001] [100] [100]

# Result: x..x..x..x..x...
[/code]

This algorithm generates standard rhythms found in **West African drumming**, **Brazilian Bossa Nova**, and **Cuban Clave**. It is "maximum evenness" - the most balanced way to be uneven.

[hr]

[b]2. Procedural Synthesis: The Code of Sound[/b]

The "Kick Drum" you hear is not a recording. It is generated in real-time by code manipulating raw bytes.

[color=yellow][b]Code: Synthesizing a Kick[/b][/color]
[code]
func _generate_kick_wav():
    # 1. Pitch Sweep (Drop from 120Hz to 35Hz)
    var pitch_env = pow(1.0 - t, 6.0) 
    var freq = lerp(35.0, 120.0, pitch_env)

    # 2. Sine Wave Generation
    phase += freq / sample_rate
    var raw = sin(TAU * phase)

    # 3. Amplitude Envelope (Hard Decay)
    var amp = pow(1.0 - t, 4.0)
    raw *= amp

    # 4. Distortion (The "Industrial" Sound)
    raw = clamp(raw * 3.0, -0.9, 0.9) # Hard clipping
[/code]

We build the sound atom by atom.
-   **Pitch Envelope:** Gives the "punch" (thud).
-   **Amplitude Envelope:** Gives the "shape" (short vs long).
-   **Distortion:** Gives the "texture" (warm vs harsh).

[hr]

[b]3. The Auto-DJ: Generative Composition[/b]

The system doesn't just loop. It **evolves**.

[color=yellow][b]Code: Algorithmic Mutation[/b][/color]
[code]
func _apply_humanization():
    # Base: E(4, 16) - Standard Techno
    
    if bar % 4 == 3:
        # Every 4th bar: Variation
        # Add a "Double Tap" (ghost note)
        pattern[14] = true 
    elif bar % 4 == 1:
        # Shift the accent
        pattern[12] = false
        pattern[11] = true
[/code]

By mixing **Deterministic Math** (Euclidean Base) with **Stochastic Variation** (Humanization), we create a "Living Loop" that never feels stale.

[hr]

[color=cyan][b]Summary:[/b][/color]
**Euclidean Rhythms** use GCD math to distribute pulses evenly (e.g., E(5,16) = Bossa Nova). **Procedural Synthesis** builds audio waveforms from scratch (Pitch Sweep + Sine + Distortion = Kick). **Generative Composition** automates the evolution of patterns (Base -> Variation -> Base). Together, they form a **Generative Music Engine** capable of endless, coherent, industrial techno without using a single sample file.

[hr]

[color=orange][b]Next:[/b] Vector Torque[/color]
We return to physics. Motion isn't just linear (velocity) - it's **rotational**.
Torque is "rotational force".
Cross Product is the math of rotation.
'''

