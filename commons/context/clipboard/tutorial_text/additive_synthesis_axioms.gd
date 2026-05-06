extends Node

var text = '''[center][font_size=28][b]Additive Synthesis[/b][/font_size][/center]
[center][i]Building Sounds from Sine Waves[/i][/center]

**Additive synthesis = creating complex sounds by adding simple sine waves together.**

**Core principle:** Start with silence. Add sine wave 1. Add sine wave 2. Add sine wave 3... Result: Complex, musical waveform.

**This is Fourier synthesis in practice** - the inverse of Fourier analysis.

**Fourier analysis:** Complex wave → component frequencies (decomposition)
**Fourier synthesis:** Component frequencies → complex wave (composition)

[hr]

[b]The Fundamental Idea[/b]

**Any periodic sound = sum of sine waves at specific frequencies and amplitudes.**

[color=yellow][b]General Formula:[/b][/color]
[code]
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
[/code]

**In practice:** You control A (amplitude) and f (frequency) to shape the sound. Phase φ is usually 0 or ignored.

[hr]

[b]Two Types of Additive Synthesis[/b]

**1. Harmonic Additive Synthesis:**

Frequencies are **integer multiples** of fundamental (harmonic series):
[code]
f₁ = f₀ × 1  (fundamental)
f₂ = f₀ × 2  (octave)
f₃ = f₀ × 3  (fifth)
f₄ = f₀ × 4  (two octaves)
...

Example: f₀ = 220 Hz
Components: 220, 440, 660, 880, 1100, 1320, ...
[/code]

**Result:** Musical, pitched sounds (instruments, voices)
**Use:** Creating instrument timbres, musical tones
**Demo:** Harmonic Builder uses this!

**2. Inharmonic Additive Synthesis:**

Frequencies are **NOT integer multiples** (arbitrary frequencies):
[code]
f₁ = 200 Hz
f₂ = 315 Hz  (not 2× f₁)
f₃ = 547 Hz  (not 3× f₁)
f₄ = 823 Hz  (not 4× f₁)
...
[/code]

**Result:** Bell-like, gong-like, metallic, unpitched sounds
**Use:** Percussion, bells, special effects
**Demo:** Beat Frequencies uses inharmonic (non-harmonic) components!

[hr]

[b]Interactive Demos[/b]

**Harmonic Additive Synthesis:**
[color=cyan]res://algorithms/wavefunctions/harmonic_builder/HarmonicBuilder.tscn[/color]

- 8 harmonics (1× through 8× fundamental)
- Control amplitude of each harmonic
- Hear how timbre changes with harmonic balance

**Inharmonic Additive (Beat Frequencies):**
[color=cyan]res://algorithms/wavefunctions/beat_frequencies/BeatFrequencies.tscn[/color]

- 2 arbitrary frequencies (not harmonically related)
- Hear beating (amplitude modulation)
- Shows inharmonic interaction

[hr]

[b]Implementation: Harmonic Synthesis[/b]

[color=yellow][b]Code: Real-Time Additive Synthesis[/b][/color]
[code]
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
        var amplitude = harmonic_amplitudes[n]

        # Generate sine wave for this harmonic
        var sine_value = sin(harmonic_phases[n])
        sample += sine_value * amplitude

        # Update phase for next sample
        harmonic_phases[n] += freq * TAU / SAMPLE_RATE

        # Wrap phase to prevent overflow
        if harmonic_phases[n] > TAU:
            harmonic_phases[n] -= TAU

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
[/code]

**This generates one audio sample.** Call this 44100 times per second for real-time audio.

[hr]

[b]Classic Waveforms via Additive Synthesis[/b]

**Square Wave:**
[code]
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
[/code]

**Sawtooth Wave:**
[code]
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
[/code]

**Triangle Wave:**
[code]
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
[/code]

**Try these in the Harmonic Builder demo!**

[hr]

[b]Advantages of Additive Synthesis[/b]

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

[hr]

[b]Disadvantages of Additive Synthesis[/b]

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

[hr]

[b]Additive vs Other Synthesis Methods[/b]

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
- One oscillator modulates another's frequency
- Complex harmonics from simple algorithm
- CPU: Low
- Example: Yamaha DX7 electric piano

**Wavetable:**
- Store pre-computed waveforms, interpolate
- Fast, flexible
- CPU: Very Low
- Example: Serum, Massive

**Granular:**
- Chop sound into tiny grains, rearrange
- Textural, experimental
- CPU: High
- Example: Cloud textures, time-stretching

[hr]

[b]Historical Context[/b]

**1960s: First Additive Synthesizers**
- Huge mainframe computers
- Too slow for real-time
- Used to pre-compute sounds

**1970s: Real-Time Additive Synths**
- Fairlight CMI (1979) - first commercial sampling workstation
- Used additive resynthesis
- Still very expensive

**1980s: Digital Additive**
- Kawai K5 (1987) - first affordable additive synth
- 64 harmonics per voice
- Complex but powerful

**1990s-2000s: Software Additive**
- Native Instruments Razor (subtractive-additive hybrid)
- Harmor (FL Studio) - additive/subtractive
- Image-Line Harmless

**Today:**
- Plugin-based (Razor, Harmor, Absynth)
- Real-time control via MIDI
- Visual editing (draw harmonic spectra)

**Our demo is a simplified, educational version** - real synths have many more features!

[hr]

[b]Time-Varying Additive Synthesis[/b]

**Real instruments have harmonic amplitudes that change over time:**

[color=yellow][b]Piano Note:[/b][/color]
[code]
# Attack (0-50ms):
All harmonics strong, especially high ones
→ Bright, percussive attack

# Decay (50-500ms):
Upper harmonics fade faster than lower
→ Sound becomes duller

# Sustain (500ms-release):
Mostly fundamental + low harmonics remain
→ Mellow, warm tone

# Release:
All harmonics fade together
→ Natural decay
[/code]

**To implement this, each harmonic needs an envelope:**
[code]
func generate_sample(time_in_note: float) -> float:
    var sample = 0.0

    for n in range(NUM_HARMONICS):
        var amplitude = harmonic_base_amplitude[n]
        var envelope = calculate_envelope(time_in_note, n)

        # Upper harmonics decay faster
        var decay_rate = 1.0 + (n * 0.3)  # Higher harmonics decay 30% faster each
        envelope *= exp(-decay_rate * time_in_note)

        sample += sin(phase[n]) * amplitude * envelope

    return sample
[/code]

**Our demo uses static amplitudes** (no envelopes) for simplicity.

[hr]

[b]Additive Resynthesis[/b]

**Reverse process: Analyze real sound → extract harmonics → resynthesize**

[color=yellow][b]Process:[/b][/color]
[code]
1. Record real instrument (e.g., violin note)
2. Perform FFT at many time slices
3. Extract harmonic amplitudes over time
4. Store as envelope data
5. Resynthesize using additive synthesis

Result: Reconstructed sound from harmonic data
[/code]

**Applications:**
- Sound morphing (crossfade between two instruments)
- Time-stretching without pitch change
- Pitch-shifting without time change
- Spectral processing (boost/cut specific harmonics)

**Used in:**
- Melodyne (pitch correction)
- Auto-Tune
- Some vocoders

[hr]

[b]Game Audio: Using Additive Synthesis[/b]

**Advantages for games:**

**1. Small File Size:**
- No audio files needed
- Just harmonic amplitude data
- 8 harmonics × 4 bytes = 32 bytes per preset!
- vs WAV file = ~100 KB

**2. Runtime Variation:**
- Change pitch in real-time
- Morph between timbres
- Procedural variation

**3. Interactive:**
- Player actions affect sound
- Sliders, wheels control timbre
- Educational value

**Example Use Cases:**
[code]
# Different pickups = different harmonic profiles
var coin_sound = [1.0, 0, 0.33, 0, 0.2, 0, 0.14, 0]  # Square wave
var gem_sound = [1.0, 0.7, 0.8, 0.5, 0.6, 0.3, 0.4, 0.2]  # Brass
var power_up = [1.0, 0.2, 0.05, 0.02, 0.01, 0, 0, 0]  # Flute

# Player health affects timbre
var health_percent = 0.3  # 30% health
for n in range(NUM_HARMONICS):
    harmonic_amps[n] *= health_percent  # Duller sound at low health
[/code]

[hr]

[b]Exercises with Harmonic Builder[/b]

**1. Recreate Square Wave:**
- Set sliders: [1.0, 0, 0.33, 0, 0.2, 0, 0.14, 0]
- Hear hollow, 8-bit sound
- See waveform become square-ish

**2. Brightness Experiment:**
- Start with only fundamental (slider 1 = 100%, rest = 0%)
- Gradually add slider 2, then 3, then 4...
- Hear sound become brighter with each harmonic
- This is "opening a filter" in subtractive synth

**3. Odd vs Even Harmonics:**
- Odd only: [1.0, 0, 0.5, 0, 0.3, 0, 0.2, 0] → hollow
- Even only: [0, 1.0, 0, 0.5, 0, 0.3, 0, 0.2] → octave-doubled
- Notice difference in timbre

**4. Build Your Own Instrument:**
- Experiment with slider combinations
- Find a sound you like
- Save it as custom preset
- Use in your game!

[hr]

[color=cyan][b]Summary:[/b][/color]
Additive synthesis = building sounds by adding sine waves. Harmonic synthesis = components at integer multiples (1×, 2×, 3×). Inharmonic = arbitrary frequencies. Control amplitude of each component to shape timbre. Classic waveforms (square, saw, triangle) are specific harmonic recipes. Advantages: intuitive, complete control, musical. Used in Harmonic Builder demo. Real instruments have time-varying harmonics (envelopes). Additive resynthesis = analyze → extract harmonics → resynthesize. Game audio: small file size, runtime variation, interactive control.

[hr]

[color=orange][b]Try Both Demos:[/b][/color]

**Harmonic (Musical):**
[color=cyan]res://algorithms/wavefunctions/harmonic_builder/HarmonicBuilder.tscn[/color]

**Inharmonic (Beating):**
[color=cyan]res://algorithms/wavefunctions/beat_frequencies/BeatFrequencies.tscn[/color]

**Understand additive synthesis by hearing it, seeing it, controlling it.**

**This is how every sound can be built - from pure mathematics to music!**

'''
