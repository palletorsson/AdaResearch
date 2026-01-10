**The Sine Wave**
Circular Motion Projected to Line

The sine wave is the most fundamental oscillation. It is the pattern of **circular motion** seen from the side - rotation projected onto a line.

Every point traveling in a circle traces a sine wave when you watch only its vertical position over time.

**The wave is frozen rotation. Rotation is time-collapsed wave.**

This is the ur-form of oscillation - from planetary orbits to sound waves to quantum mechanics. The sine wave is the shape of **perpetual motion between poles**.

---

## The Unit Circle: Origin of Sine

A point rotating around a circle of radius 1 (the **unit circle**) creates sine and cosine through **projection**.

**Code: Rotation Creates Wave**

```
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
```

**Sine = vertical projection of rotation**
**Cosine = horizontal projection of rotation**

One rotation (360°) = one complete wave cycle (0° → 360° → back to 0°).

---

## The Wave as Oscillation Between Poles

The sine wave oscillates between **-1 and +1** - eternally swinging between minimum and maximum, never settling.

**Code: The Perpetual Swing**

```
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
```

**The wave never rests.** It crosses zero (equilibrium) twice per cycle but **never stops there** - always moving toward the opposite extreme.

This is **oscillation** - perpetual motion between poles, seeking but never reaching stable equilibrium.

---

## Frequency: How Fast It Oscillates

**Frequency** determines how many cycles occur per second (measured in Hertz - Hz).

**Code: Faster Oscillation**

```
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
```

**Higher frequency = faster oscillation = shorter wavelength**

- 1 Hz = very slow (one cycle per second)
- 60 Hz = visible flicker (monitor refresh)
- 440 Hz = musical note A (concert pitch)
- 20,000 Hz = upper limit of human hearing

**Frequency is the speed of desire** - how quickly the wave seeks its opposite pole.

---

## Amplitude: How Far It Swings

**Amplitude** is the maximum displacement from center - how far the wave reaches toward its extremes.

**Code: Larger Swings**

```
var amplitude = 3.0  # Swing from -3 to +3 (instead of -1 to +1)
var frequency = 1.0

func _process(delta):
    time += delta

    # Multiply sine output by amplitude
    var wave = sin(time * frequency * TAU) * amplitude

    # Now oscillates between -3 and +3
    # Larger swings, same frequency
```

**Amplitude = intensity of oscillation**

For sound:
- Large amplitude = loud
- Small amplitude = quiet

For light:
- Large amplitude = bright
- Small amplitude = dim

**Amplitude is the magnitude of desire** - how far the wave reaches from equilibrium toward its extremes.

---

## Phase: Where in the Cycle You Start

**Phase** is the offset - where in the oscillation cycle you begin.

**Code: Starting at Different Points**

```
var phase_offset = PI / 2  # Start 90° into cycle

func _process(delta):
    time += delta

    # Add phase to angle
    var wave = sin(time * TAU + phase_offset)

    # phase_offset = 0     → starts at 0 (middle, rising)
    # phase_offset = π/2   → starts at 1 (peak)
    # phase_offset = π     → starts at 0 (middle, falling)
    # phase_offset = 3π/2  → starts at -1 (trough)
```

**Phase determines relationship between waves:**

Two waves with **same frequency, different phase** will be **out of sync**.

- Phase difference = 0 → waves aligned (in phase)
- Phase difference = π → waves opposite (out of phase, 180°)

**Phase is the timing of desire** - when does the seeking begin in the cycle?

---

## The Wave Equation: Complete Form

Combining amplitude, frequency, and phase:

**Code: General Sine Wave**

```
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
```

**Every sine wave is defined by three numbers** - amplitude, frequency, phase.

These three parameters generate infinite variety of oscillations.

---

## The Wave in Space vs Time

Sine can describe **oscillation over time** OR **oscillation through space**.

**Time Domain (Sound):**

```
# Value changes over time at fixed position
var time = 0.0
func _process(delta):
    time += delta
    var value = sin(time * frequency * TAU)
    # Point oscillates up/down as time passes
```

**Space Domain (Geometry):**

```
# Value changes over position at fixed time
for x in range(100):
    var value = sin(x * 0.1)  # Oscillates along X axis
    # Creates wave-shaped curve in space
```

**Sound = oscillation over time** (air pressure rising/falling at your ear)
**Wave geometry = oscillation over space** (curve undulating through coordinates)

Same mathematical form, different domain.

---

[b>Sine and Cosine: 90° Apart

**Cosine** is sine shifted by 90° (π/2 radians).

**Code: The Phase Relationship**

```
# These are identical:
var sine_wave = sin(time)
var cosine_as_sine = sin(time + PI/2)

# And:
var cosine_wave = cos(time)
var sine_as_cosine = cos(time - PI/2)

# Sine and cosine are the SAME wave
# Just starting at different phase
```

**Why both exist:**
- **Sine** starts at 0 (middle, rising)
- **Cosine** starts at 1 (peak)

On the unit circle:
- **sin(angle)** = Y coordinate
- **cos(angle)** = X coordinate

They are perpendicular projections of the same rotation.

---

## What the Sine Wave Cannot Represent

The sine wave is **perfectly smooth** - infinitely differentiable, no sharp edges, no discontinuities.

It cannot represent:
- **Square waves** - instant jumps (requires infinite frequencies)
- **Saw waves** - sharp reversals (requires harmonics)
- **Noise** - random, non-periodic
- **Impulses** - instant spikes (Dirac delta)

But **Fourier