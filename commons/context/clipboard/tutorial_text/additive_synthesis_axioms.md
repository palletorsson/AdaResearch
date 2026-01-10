**Additive Synthesis**
Building Sounds from Sine Waves

**Additive synthesis = creating complex sounds by adding simple sine waves together.**

**Core principle:** Start with silence. Add sine wave 1. Add sine wave 2. Add sine wave 3... Result: Complex, musical waveform.

**This is Fourier synthesis in practice** - the inverse of Fourier analysis.

**Fourier analysis:** Complex wave → component frequencies (decomposition)
**Fourier synthesis:** Component frequencies → complex wave (composition)

---

## The Fundamental Idea

**Any periodic sound = sum of sine waves at specific frequencies and amplitudes.**

**General Formula:**

```
y(t) = A₁·sin(2π·f₁·t + φ₁)
     + A₂·sin(2π·f₂·t + φ₂)
     + A₃·sin(2π·f₃·t + φ₃)
     + A₄·sin(2π·f₄·t + φ₄)
     + ...

Where:
- A = amplitude of each component
- f = frequency of each component
- φ = phase offset of each component
- t = time
```

**In practice:** You control A (amplitude) and f (frequency) to shape the sound. Phase φ is usually 0 or ignored.

---

## Two Types of Additive Synthesis

**1. Harmonic Additive Synthesis:**

Frequencies are **integer multiples** of fundamental (harmonic series):

```
f₁ = f₀ × 1  (fundamental)
f₂ = f₀ × 2  (octave)
f₃ = f₀ × 3  (fifth)
f₄ = f₀ × 4  (two octaves)
...

Example: f₀ = 220 Hz
Components: 220, 440, 660, 880, 1100, 1320, ...
```

**Result:** Musical, pitched sounds (instruments, voices)
**Use:** Creating instrument timbres, musical tones
**Demo:** Harmonic Builder uses this!

**2. Inharmonic Additive Synthesis:**

Frequencies are **NOT integer multiples** (arbitrary frequencies):

```
f₁ = 200 Hz
f₂ = 315 Hz  (not 2× f₁)
f₃ = 547 Hz  (not 3× f₁)
f₄ = 823 Hz  (not 4× f₁)
...
```

**Result:** Bell-like, gong-like, metallic, unpitched sounds
**Use:** Percussion, bells, special effects
**Demo:** Beat Frequencies uses inharmonic (non-harmonic) components!

---

## Interactive Demos

**Harmonic Additive Synthesis:**
res://algorithms/wavefunctions/harmonic_builder/HarmonicBuilder.tscn

- 8 harmonics (1× through 8× fundamental)
- Control amplitude of each harmonic
- Hear how timbre changes with harmonic balance

**Inharmonic Additive (Beat Frequencies):**
res://algorithms/wavefunctions/beat_frequencies/BeatFrequencies.tscn

- 2 arbitrary frequencies (not harmonically related)
- Hear beating (amplitude modulation)
- Shows inharmonic interaction

---

## Implementation: Harmonic Synthesis

**Code: Real-Time Additive Synthesis**

```
const NUM_HARMONICS = 8
var fundamental_freq = 220.0  # A3
var harmonic_amplitudes = [1.0, 0.5, 0.33, 0.25, 0.2, 0.17, 0.14, 0.13]
var harmonic_phases = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
const SAMPLE_RATE = 44100.0

func generate_audio_sample() -> float:
    var sample = 0.0

    # Add each harmonic
    for n in range(NUM_HARMONICS):
        var harmonic_number = n + 1  # 1, 2, 3, 4, ...
        var freq = fundamental_freq * harmonic_number
        var amplitude = harmonic_amplitudes

        # Generate sine wave for this harmonic
        var sine_value = sin(harmonic_phases)
        sample += sine_value * amplitude

        # Update phase for next sample
        harmonic_phases += freq * TAU / SAMPLE_RATE

        # Wrap phase to prevent overflow
        if harmonic_phases > TAU:
            harmonic_phases -= TAU

    # Normalize to prevent clipping
    var active_harmonics = count_active_harmonics()
    if active_harmonics > 0:
        sample = sample / sqrt(active_harmonics)

    # Clamp to valid audio range
    return clamp(sample, -1.0, 1.0)

func count_active_harmonics() -> int:
    var count = 0
    for amp in harmonic_amplitudes:
        if amp > 0.001:
            count += 1
    return count
```

**This generates one audio sample.** Call this 44100 times per second for real-time audio.

---

## Classic Waveforms via Additive Synthesis

**Square Wave:**

```
# Fourier series: only odd harmonics, amplitude = 1/n
harmonics = [
    1.0,      # H1 (100%)
    0.0,      # H2 (absent - even)
    0.333,    # H3 (33% = 1/3)
    0.0,      # H4 (absent - even)
    0.2,      # H5 (20% = 1/5)
    0.0,      # H6 (absent - even)
    0.143,    # H7 (14% = 1/7)
    0.0       # H8 (absent - even)
]

Result: Hollow, video-game sound
```

**Sawtooth Wave:**

```
# All harmonics, amplitude = 1/n
harmonics = [
    1.0,      # H1 (100%)
    0.5,      # H2 (50% = 1/2)
    0.333,    # H3 (33% = 1/3)
    0.25,     # H4 (25% = 1/4)
    0.2,      # H5 (20% = 1/5)
    0.167,    # H6 (17% = 1/6)
    0.143,    # H7 (14% = 1/7)
    0.125     # H8 (13% = 1/8)
]

Result: Bright, buzzy, rich synth sound
```

**Triangle Wave:**

```
# Odd harmonics only, amplitude = 1/n²
harmonics = [
    1.0,      # H1 (100%)
    0.0,      # H2 (absent)
    0.111,    # H3 (11% = 1/9)
    0.0,      # H4 (absent)
    0.04,     # H5 (4% = 1/25)
    0.0,      # H6 (absent)
    0.02,     # H7 (2% = 1/49)
    0.0       # H8 (absent)
]

Result: Mellow, soft, gentle
```

**Try these in the Harmonic Builder demo!**

---

## Advantages of Additive Synthesis

**1. Complete Control:**
- Adjust each harmonic individually
- Precise timbre sculpting
- No limitations on what sounds you can create

**2. Intuitive:**
- Visual: See harmonic spectrum as bars
- Audible: Hear immediate result
- Educational: Understand timbre construction

**3. Efficient:**
- Simple math (just sine waves + addition)
- Low CPU usage
- Scalable (use as many harmonics as needed)

**4. Musical:**
- Harmonic series sounds natural
- Creates pitched, musical tones
- Good for instrument emulation

---

## Disadvantages of Additive Synthesis

**1. Many Parameters:**
- 8 harmonics = 8 sliders to control
- Complex sounds need many harmonics (16, 32, 64+)
- Can be overwhelming

**2. Static Without Modulation:**
- Fixed harmonic amplitudes = static timbre
- Real instruments have time-varying harmonics
- Needs envelopes, LFOs for movement

**3. Hard to Create Non-Harmonic Sounds:**
- Noise, breath, attack transients difficult
- Bell/gong sounds need inharmonic partials
- Some timbres require many components

**4. CPU Intensive for Many Harmonics:**
- Each harmonic = one sine oscillator
- 64 harmonics = 64 oscillators
- Can add up for polyphonic synthesis

---

## Additive vs Other Synthesis Methods

**Additive:**
- Build from ground up (add sines)
- Intuitive control
- CPU: Medium
- Example: Harmonic Builder

**Subtractive:**
- Start with rich waveform, filter it down
- Classic analog synths (Moog, ARP)
- CPU: Low
- Example: Filter sweeps (not yet implemented)

**FM (Frequency Modulation):**
- One oscillator modulates another