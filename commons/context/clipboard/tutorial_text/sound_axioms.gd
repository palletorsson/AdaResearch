extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Sound[/b][/font_size][/center]
[center][i]Wave Made Material, Air Made Temporal[/i][/center]

Sound is **oscillating air pressure** - waves of compression and rarefaction traveling through material medium.

When air molecules vibrate at **440 cycles per second** (440 Hz), you hear the musical note **A**.

**Sound is the sine wave made audible.** Abstract oscillation becomes physical vibration becomes perceived tone.

This is where geometry becomes temporal, where mathematics becomes sensation.

[hr]

[b]Sound as Pressure Wave[/b]

Sound is not "in the air" as a substance - it is the **oscillation of air pressure** over time.

[color=yellow][b]The Physical Process:[/b][/color]
[code]
# Speaker cone moves forward
→ Pushes air molecules together
→ Creates HIGH PRESSURE region (compression)

# Speaker cone moves backward
→ Pulls air molecules apart
→ Creates LOW PRESSURE region (rarefaction)

# Cone oscillates (sine wave motion)
→ Alternating compression and rarefaction
→ Pressure wave travels outward at speed of sound (~343 m/s)

# Wave reaches your ear
→ Eardrum vibrates at same frequency
→ Nerve signals to brain
→ Perceived as TONE
[/code]

**Sound = material oscillation propagating through medium**

No air (vacuum) = no sound. The wave requires matter to carry it.

[hr]

[b]Frequency as Pitch[/b]

The **frequency** of oscillation determines **pitch** - how high or low the tone sounds.

[color=yellow][b]Code: Frequency → Pitch[/b][/color]
[code]
# Musical note frequencies (Hz)
var C4 = 261.63   # Middle C
var A4 = 440.00   # Concert pitch A (tuning standard)
var C5 = 523.25   # C one octave above middle C

# Generate tone at frequency
func generate_tone(frequency: float, duration: float):
    var sample_rate = 44100  # Samples per second
    var samples = []

    for i in range(int(duration * sample_rate)):
        var time = i / float(sample_rate)

        # Sine wave at given frequency
        var sample_value = sin(time * frequency * TAU)
        samples.append(sample_value)

    return samples

# Higher frequency = higher pitch
# Lower frequency = lower pitch
[/code]

**Human hearing range:** ~20 Hz to 20,000 Hz

- **20 Hz** - Very low rumble (barely audible)
- **440 Hz** - Musical note A
- **4,000 Hz** - Bright, piercing (human voice range)
- **20,000 Hz** - Upper limit (only children/young adults hear this high)

**Pitch is the speed of oscillation made perceptual.**

[hr]

[b]Amplitude as Volume[/b]

The **amplitude** of the pressure wave determines **loudness** - how much the air pressure varies.

[color=yellow][b]Code: Amplitude → Volume[/b][/color]
[code]
var frequency = 440.0  # A note
var amplitude = 0.5    # Volume (0.0 to 1.0)

func generate_tone_with_volume(freq, amp, duration):
    var samples = []
    for i in range(int(duration * 44100)):
        var time = i / 44100.0

        # Amplitude scales the wave
        var sample = sin(time * freq * TAU) * amp

        samples.append(sample)
    return samples

# amplitude = 0.0  → silence
# amplitude = 0.5  → moderate volume
# amplitude = 1.0  → maximum (before clipping)
[/code]

**Amplitude = magnitude of air pressure variation**

- Small amplitude → quiet (gentle vibration)
- Large amplitude → loud (violent vibration)

**Volume is the magnitude of oscillation made perceptual.**

[hr]

[b]The Sample: Discretizing the Wave[/b]

Digital audio stores sound as **arrays of sample values** - the wave discretized into snapshots taken at regular intervals.

[color=yellow][b]Code: Continuous Wave → Discrete Samples[/b][/color]
[code]
var sample_rate = 44100  # Standard CD quality (44,100 samples/second)

# One second of 440 Hz sine wave
var audio_buffer = []

for i in range(sample_rate):
    var time = i / float(sample_rate)  # Time in seconds

    # Sample the continuous sine wave at this instant
    var sample_value = sin(time * 440.0 * TAU)

    audio_buffer.append(sample_value)

# Result: 44,100 numbers representing one second of sound
# Each number = air pressure at that instant
# Play back at 44,100 samples/second → hear 440 Hz tone
[/code]

**Sample rate** determines **temporal resolution**:
- 44,100 Hz (CD quality) - 44,100 samples per second
- 48,000 Hz (professional audio) - slightly higher resolution
- 8,000 Hz (telephone) - low quality, but sufficient for speech

**The sample is the audio equivalent of the pixel** - discrete unit approximating continuous reality.

[hr]

[b]Nyquist Limit: Maximum Frequency[/b]

You can only capture frequencies up to **half the sample rate** (Nyquist frequency).

[color=yellow][b]Code: The Sampling Limit[/b][/color]
[code]
var sample_rate = 44100  # Samples per second

# Maximum capturable frequency
var nyquist_frequency = sample_rate / 2.0  # 22,050 Hz

# Why? Need at least 2 samples per wave cycle
# If wave oscillates faster than half sample rate:
# - Not enough samples to capture it
# - Creates ALIASING (false lower frequencies)

# This is why 44.1 kHz can capture up to ~20 kHz
# (which covers human hearing range: 20 Hz - 20 kHz)
[/code]

**Nyquist theorem:** To capture frequency F, you must sample at **at least 2F**.

Violate this → **aliasing** - high frequencies appear as false low frequencies (artifact).

[hr]

[b]Audio as Array: Lists Made Temporal[/b]

An audio file is just a **very long array** of sample values.

[color=yellow][b]Code: Sound as Sequential Data[/b][/color]
[code]
# One second of audio at 44.1 kHz
var audio_samples = []  # Will hold 44,100 values

for i in range(44100):
    var time = i / 44100.0
    var sample = sin(time * 440.0 * TAU)  # 440 Hz tone
    audio_samples.append(sample)

# To play:
# - Send samples to audio hardware sequentially
# - At rate of 44,100 samples/second
# - Hardware converts to analog voltage
# - Voltage drives speaker cone
# - Cone creates pressure wave
# - You hear tone

# The array becomes time when played back
[/code]

**This connects to list_axioms:** Sound is an array traversed at specific speed (sample rate). The index becomes time.

[hr]

[b]Waveforms: Shapes of Timbre[/b]

Different wave shapes create different **timbres** (tone colors), even at same pitch.

[color=yellow][b]Code: Four Basic Waveforms[/b][/color]
[code]
var time = 0.0
var frequency = 440.0

# Sine wave - pure tone, smooth
var sine = sin(time * frequency * TAU)

# Square wave - hollow, clarinet-like
var square = 1.0 if sin(time * frequency * TAU) > 0 else -1.0

# Sawtooth - bright, buzzy, string-like
var sawtooth = 2.0 * (fmod(time * frequency, 1.0)) - 1.0

# Triangle - mellow, flute-like
var triangle = abs(sawtooth) * 2.0 - 1.0
[/code]

**Same frequency (440 Hz), different waveshapes:**
- **Sine** - Pure, fundamental only (no harmonics)
- **Square** - Hollow (odd harmonics: 440 Hz, 1320 Hz, 2200 Hz...)
- **Sawtooth** - Bright (all harmonics: 440, 880, 1320, 1760...)
- **Triangle** - Soft (odd harmonics, quieter than square)

**Timbre = harmonic content** - which frequencies are present beyond the fundamental.

[hr]

[b]Harmonics: Waves Within Waves[/b]

Complex tones contain **harmonics** - integer multiples of the fundamental frequency.

[color=yellow][b]Code: Building Rich Tone[/b][/color]
[code]
var fundamental = 440.0  # Base frequency (A note)

func generate_rich_tone(time):
    var sample = 0.0

    # Add fundamental
    sample += sin(time * fundamental * TAU) * 1.0

    # Add 2nd harmonic (octave: 880 Hz)
    sample += sin(time * fundamental * 2 * TAU) * 0.5

    # Add 3rd harmonic (perfect fifth: 1320 Hz)
    sample += sin(time * fundamental * 3 * TAU) * 0.25

    # Add 4th harmonic (two octaves: 1760 Hz)
    sample += sin(time * fundamental * 4 * TAU) * 0.125

    # Normalize
    return sample / 2.0

# Each harmonic quieter than previous (1, 0.5, 0.25, 0.125)
# Creates richer, more complex tone
# This is additive synthesis
[/code]

**Natural instruments produce harmonics:**
- Violin string vibrates at fundamental + harmonics
- Human voice has fundamental (pitch) + formants (harmonics creating vowel sounds)

**Harmonics = why instruments sound different even at same note.**

[hr]

[b]Sound as Time Made Audible[/b]

Sound exists **only in time** - it has no spatial form (until we visualize waveforms).

[color=yellow][b]Comparison:[/b][/color]
[code]
# Geometry exists in SPACE
var point = Vector3(x, y, z)  # Spatial coordinates
# Can see it all at once (if small enough)

# Sound exists in TIME
var audio = [sample_0, sample_1, sample_2, ...]  # Temporal sequence
# Must experience it sequentially
# Cannot perceive "all at once"
[/code]

**You cannot see a sound - only its past** (waveform visualization is retrospective, not real-time perception).

Sound is **irreversibly temporal** - it unfolds, cannot be grasped simultaneously.

**This connects to the_trace:** Sound is duration made material, sequence made perceptible.

[hr]

[b]The Sine Tone: Atomic Unit of Sound[/b]

A **pure sine tone** (single frequency, no harmonics) is the simplest possible sound.

[color=yellow][b]Code: The Fundamental[/b][/color]
[code]
# 440 Hz pure sine wave
func _process(delta):
    time += delta
    var sample = sin(time * 440.0 * TAU)

    # This is the ATOMIC sound
    # Single frequency
    # No harmonics
    # Smooth, pure

    # Sounds "electronic," "synthetic"
    # Natural sounds always have harmonics
[/code]

**Fourier's theorem:** Any periodic sound can be decomposed into sum of sine waves.

**Every sound = combination of sine tones** at different frequencies and amplitudes.

The sine wave is the **atomic unit of audio** - the irreducible oscillation from which all sound is built.

[hr]

[b]What Sound Reveals[/b]

Sound shows us:

1. **Waves become material** - Abstract sine = oscillating air pressure
2. **Geometry becomes temporal** - Spatial oscillation → temporal vibration
3. **Frequency = perception** - 440 Hz → "A note" (physics → qualia)
4. **Arrays become time** - Sequential samples played at rate = duration
5. **Sampling discretizes** - Continuous wave → finite list (like pixels for images)
6. **Harmonics create timbre** - Same pitch, different character (violin vs flute)
7. **Time is irreversible** - Sound unfolds sequentially, cannot be grasped simultaneously

**Sound is where mathematics meets sensation** - sine function becomes perceived pitch, amplitude becomes loudness, waveform becomes timbre.

[hr]

[color=cyan][b]Summary:[/b][/color]
Sound is oscillating air pressure - compression and rarefaction waves traveling through medium. Frequency determines pitch (440 Hz = A note), amplitude determines volume. Digital audio samples continuous waves at regular intervals (44,100/second standard). Nyquist limit = half sample rate (max ~22 kHz for CD quality). Different waveforms (sine, square, saw, triangle) create different timbres through harmonic content. Sound exists purely in time - sequential, temporal, cannot be grasped simultaneously.

[hr]

[color=orange][b]Next:[/b] Wave as Desire[/color]
The wave never settles - perpetual oscillation between poles.
Seeking equilibrium but momentum carries past.
This is the pattern of desire: motion without rest, seeking without arrival.
Geometry, sound, and longing share the same mathematical form.

'''
