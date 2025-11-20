extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]The Sine Wave[/b][/font_size][/center]
[center][i]Circular Motion Projected to Line[/i][/center]

The sine wave is the most fundamental oscillation. It is the pattern of **circular motion** seen from the side - rotation projected onto a line.

Every point traveling in a circle traces a sine wave when you watch only its vertical position over time.

**The wave is frozen rotation. Rotation is time-collapsed wave.**

This is the ur-form of oscillation - from planetary orbits to sound waves to quantum mechanics. The sine wave is the shape of **perpetual motion between poles**.

[hr]

[b]The Unit Circle: Origin of Sine[/b]

A point rotating around a circle of radius 1 (the **unit circle**) creates sine and cosine through **projection**.

[color=yellow][b]Code: Rotation Creates Wave[/b][/color]
[code]
var angle = 0.0  # Starting angle (radians)
var radius = 1.0  # Unit circle

# As angle increases (rotation)
for t in range(360):
    angle = deg_to_rad(t)

    # Position on circle
    var x = cos(angle) * radius  # Horizontal position
    var y = sin(angle) * radius  # Vertical position

    # x-coordinate traces COSINE wave over time
    # y-coordinate traces SINE wave over time

    # The wave IS the projection of circular motion
[/code]

**Sine = vertical projection of rotation**
**Cosine = horizontal projection of rotation**

One rotation (360°) = one complete wave cycle (0° → 360° → back to 0°).

[hr]

[b]The Wave as Oscillation Between Poles[/b]

The sine wave oscillates between **-1 and +1** - eternally swinging between minimum and maximum, never settling.

[color=yellow][b]Code: The Perpetual Swing[/b][/color]
[code]
var time = 0.0

func _process(delta):
    time += delta

    # Sine oscillates between -1 and +1
    var wave_value = sin(time)

    # At time=0:      sin(0) = 0      (middle)
    # At time=π/2:    sin(π/2) = 1    (peak)
    # At time=π:      sin(π) = 0      (middle again)
    # At time=3π/2:   sin(3π/2) = -1  (trough)
    # At time=2π:     sin(2π) = 0     (back to start)

    # Then repeats forever
    # Never stops, never settles
[/code]

**The wave never rests.** It crosses zero (equilibrium) twice per cycle but **never stops there** - always moving toward the opposite extreme.

This is **oscillation** - perpetual motion between poles, seeking but never reaching stable equilibrium.

[hr]

[b]Frequency: How Fast It Oscillates[/b]

**Frequency** determines how many cycles occur per second (measured in Hertz - Hz).

[color=yellow][b]Code: Faster Oscillation[/b][/color]
[code]
var time = 0.0
var frequency = 2.0  # 2 cycles per second (2 Hz)

func _process(delta):
    time += delta

    # Multiply angle by frequency
    var wave = sin(time * frequency * TAU)

    # TAU = 2π (one complete rotation)
    # frequency=1 → 1 cycle per second
    # frequency=2 → 2 cycles per second
    # frequency=440 → 440 cycles per second (A note, musical pitch)
[/code]

**Higher frequency = faster oscillation = shorter wavelength**

- 1 Hz = very slow (one cycle per second)
- 60 Hz = visible flicker (monitor refresh)
- 440 Hz = musical note A (concert pitch)
- 20,000 Hz = upper limit of human hearing

**Frequency is the speed of desire** - how quickly the wave seeks its opposite pole.

[hr]

[b]Amplitude: How Far It Swings[/b]

**Amplitude** is the maximum displacement from center - how far the wave reaches toward its extremes.

[color=yellow][b]Code: Larger Swings[/b][/color]
[code]
var amplitude = 3.0  # Swing from -3 to +3 (instead of -1 to +1)
var frequency = 1.0

func _process(delta):
    time += delta

    # Multiply sine output by amplitude
    var wave = sin(time * frequency * TAU) * amplitude

    # Now oscillates between -3 and +3
    # Larger swings, same frequency
[/code]

**Amplitude = intensity of oscillation**

For sound:
- Large amplitude = loud
- Small amplitude = quiet

For light:
- Large amplitude = bright
- Small amplitude = dim

**Amplitude is the magnitude of desire** - how far the wave reaches from equilibrium toward its extremes.

[hr]

[b]Phase: Where in the Cycle You Start[/b]

**Phase** is the offset - where in the oscillation cycle you begin.

[color=yellow][b]Code: Starting at Different Points[/b][/color]
[code]
var phase_offset = PI / 2  # Start 90° into cycle

func _process(delta):
    time += delta

    # Add phase to angle
    var wave = sin(time * TAU + phase_offset)

    # phase_offset = 0     → starts at 0 (middle, rising)
    # phase_offset = π/2   → starts at 1 (peak)
    # phase_offset = π     → starts at 0 (middle, falling)
    # phase_offset = 3π/2  → starts at -1 (trough)
[/code]

**Phase determines relationship between waves:**

Two waves with **same frequency, different phase** will be **out of sync**.

- Phase difference = 0 → waves aligned (in phase)
- Phase difference = π → waves opposite (out of phase, 180°)

**Phase is the timing of desire** - when does the seeking begin in the cycle?

[hr]

[b]The Wave Equation: Complete Form[/b]

Combining amplitude, frequency, and phase:

[color=yellow][b]Code: General Sine Wave[/b][/color]
[code]
var amplitude = 2.0     # How far (magnitude)
var frequency = 3.0     # How fast (speed)
var phase = PI / 4      # Where starts (offset)
var time = 0.0

func _process(delta):
    time += delta

    # Complete wave equation
    var wave = amplitude * sin(frequency * time * TAU + phase)

    # Three parameters define any sine wave:
    # - Amplitude: vertical scale
    # - Frequency: horizontal compression
    # - Phase: horizontal shift
[/code]

**Every sine wave is defined by three numbers** - amplitude, frequency, phase.

These three parameters generate infinite variety of oscillations.

[hr]

[b]The Wave in Space vs Time[/b]

Sine can describe **oscillation over time** OR **oscillation through space**.

[color=yellow][b]Time Domain (Sound):[/b][/color]
[code]
# Value changes over time at fixed position
var time = 0.0
func _process(delta):
    time += delta
    var value = sin(time * frequency * TAU)
    # Point oscillates up/down as time passes
[/code]

[color=yellow][b]Space Domain (Geometry):[/b][/color]
[code]
# Value changes over position at fixed time
for x in range(100):
    var value = sin(x * 0.1)  # Oscillates along X axis
    # Creates wave-shaped curve in space
[/code]

**Sound = oscillation over time** (air pressure rising/falling at your ear)
**Wave geometry = oscillation over space** (curve undulating through coordinates)

Same mathematical form, different domain.

[hr]

[b>Sine and Cosine: 90° Apart[/b]

**Cosine** is sine shifted by 90° (π/2 radians).

[color=yellow][b]Code: The Phase Relationship[/b][/color]
[code]
# These are identical:
var sine_wave = sin(time)
var cosine_as_sine = sin(time + PI/2)

# And:
var cosine_wave = cos(time)
var sine_as_cosine = cos(time - PI/2)

# Sine and cosine are the SAME wave
# Just starting at different phase
[/code]

**Why both exist:**
- **Sine** starts at 0 (middle, rising)
- **Cosine** starts at 1 (peak)

On the unit circle:
- **sin(angle)** = Y coordinate
- **cos(angle)** = X coordinate

They are perpendicular projections of the same rotation.

[hr]

[b]What the Sine Wave Cannot Represent[/b]

The sine wave is **perfectly smooth** - infinitely differentiable, no sharp edges, no discontinuities.

It cannot represent:
- **Square waves** - instant jumps (requires infinite frequencies)
- **Saw waves** - sharp reversals (requires harmonics)
- **Noise** - random, non-periodic
- **Impulses** - instant spikes (Dirac delta)

But **Fourier's theorem** says: any periodic wave can be built by **adding sine waves** of different frequencies.

**Complex waves = many sines combined.**

[hr]

[b]The Sine Wave as Fundamental[/b]

Why is sine special?

1. **Emerges from rotation** - Circular motion is fundamental (planetary orbits, electron orbitals)
2. **Smooth and simple** - Least complex oscillation (single frequency)
3. **Fourier basis** - All waves decomposable into sines/cosines
4. **Harmonic oscillator** - Solution to differential equation (springs, pendulums, quantum)
5. **Natural resonance** - Strings, air columns, electromagnetic fields oscillate as sines

**The sine wave is the atomic unit of oscillation** - the simplest repeating pattern.

[hr]

[b]Sine as the Shape of Seeking[/b]

The wave never settles. It crosses equilibrium (zero) but **momentum carries it past** toward the opposite extreme.

At peak (+1): velocity is zero, but **acceleration pulls downward**
At trough (-1): velocity is zero, but **acceleration pulls upward**
At zero: velocity is maximum, **passing through** toward opposite pole

**This is the pattern of desire:**
- Never at rest
- Always moving toward opposite
- Crossing equilibrium without stopping
- Perpetual oscillation between poles

The wave **seeks equilibrium but its own motion prevents arrival.**

[hr]

[b]What the Sine Wave Reveals[/b]

The sine wave shows us:

1. **Rotation and oscillation are the same** - Circle seen from edge is wave
2. **Motion is perpetual** - Wave never settles at equilibrium
3. **Three parameters define oscillation** - Amplitude, frequency, phase
4. **Smooth is fundamental** - All complex waves built from sines
5. **Time and space interchangeable** - Same pattern in different domains
6. **Seeking creates form** - Perpetual motion between poles generates geometry

**The sine wave is the mathematical form of non-rest** - the pattern that emerges when something cannot stop, must oscillate, perpetually seeks but never arrives.

[hr]

[color=cyan][b]Summary:[/b][/color]
The sine wave is circular motion projected to a line - rotation creates oscillation. Defined by amplitude (magnitude), frequency (speed), and phase (offset). Oscillates perpetually between -1 and +1, never settling. Sine and cosine are 90° apart (same wave, different starting phase). Can describe oscillation over time (sound) or space (geometry). The fundamental smooth oscillation from which complex waves are built.

[hr]

[color=orange][b]Next:[/b] Sound as Wave[/color]
If sine is abstract oscillation, sound is **material wave** - air pressure oscillating.
When frequency = 440 Hz, you hear the note A.
Audio samples are wave values stored in arrays.
Sound is the wave made audible, geometry made temporal, desire made physical.

'''
