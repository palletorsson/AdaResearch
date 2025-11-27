# Harmonic Series Builder - Interactive Synthesizer

## Overview
Build musical sounds by adding harmonics - a hands-on demonstration of **Fourier synthesis** and **additive synthesis**.

## Core Concept
**ANY periodic sound = sum of harmonics (sine waves at integer multiples)**

- **Fundamental (1×):** Base pitch (e.g., 220 Hz = A3)
- **2nd Harmonic (2×):** Octave above (440 Hz)
- **3rd Harmonic (3×):** Perfect fifth above octave (660 Hz)
- **4th Harmonic (4×):** Two octaves above (880 Hz)
- ... and so on

Different **harmonic balances** = different **timbres** (why a flute sounds different from a trumpet)

## Controls

### VR Interactables
- **8 Vertical Sliders:** Control amplitude of each harmonic (1× through 8×)
- **Wheel:** Change fundamental frequency (110-880 Hz, A2-A5)
- **8 Preset Buttons:**
  - **Sine:** Pure tone (only fundamental)
  - **Square:** Video game sound (odd harmonics: 1, 3, 5, 7)
  - **Sawtooth:** Bright, buzzy (all harmonics: 1, 2, 3, 4, 5, 6, 7, 8)
  - **Triangle:** Mellow (odd harmonics squared: 1, 1/9, 1/25, 1/49)
  - **Organ:** Rich harmonic content
  - **Clarinet:** Hollow sound (odd harmonics only)
  - **Brass:** Bright, strong harmonics
  - **Flute:** Pure, weak upper harmonics

### Visual Feedback
- **8 Colored Bars:** Height shows harmonic amplitude
- **Waveform Display:** Shows resulting wave shape (128 points)
- **Frequency Label:** Current fundamental frequency and note name (e.g., "220.0 Hz (A3)")
- **Harmonic Labels:** Shows which multiple (1×, 2×, 3×, etc.)

## Educational Value

### What You Learn
1. **Fourier Synthesis** - Build complex waves from simple sines
2. **Harmonics** - Integer multiples create musical relationships
3. **Timbre** - Why instruments sound different
4. **Additive Synthesis** - Core synthesis technique
5. **Musical Intervals** - 2× = octave, 3× = fifth, 4× = double octave

### Real-World Applications
- **Synthesizers** - Additive synths work this way
- **Musical acoustics** - Instruments produce harmonics naturally
- **Sound design** - Create custom tones for any purpose
- **Audio analysis** - Understanding frequency content

## Musical/Game Use

### Sound Design Categories

#### **Pure/Mellow (Weak Upper Harmonics)**
- Flute preset
- Sine wave
- Use for: Soft pads, ambient sounds, meditation

#### **Bright/Aggressive (Strong Upper Harmonics)**
- Brass preset
- Sawtooth wave
- Use for: Leads, bass, aggressive sounds

#### **Hollow/Woody (Odd Harmonics Only)**
- Clarinet preset
- Square wave
- Use for: Retro game sounds, hollow tones

#### **Rich/Full (Balanced Harmonics)**
- Organ preset
- Use for: Pads, chords, full sounds

### Game Audio Applications
- **Synth leads** - Bright, cutting sounds (sawtooth/brass)
- **Bass** - Fundamental + low harmonics
- **Pads** - Organ preset, slow attack
- **UI sounds** - Square wave for retro feel
- **Ambient drones** - Sine with subtle harmonics
- **Musical pickups** - Different harmonic profiles = different item types

## Presets Explained

### Sine Wave
```
Harmonics: [1.0, 0, 0, 0, 0, 0, 0, 0]
Sound: Pure tone, no overtones
Use: Tuning fork, reference pitch, meditation
```

### Square Wave
```
Harmonics: [1.0, 0, 0.333, 0, 0.2, 0, 0.143, 0]
Sound: Hollow, video-game-like
Math: Odd harmonics with 1/n amplitude
Use: 8-bit game sounds, clarinet-like tones
```

### Sawtooth Wave
```
Harmonics: [1.0, 0.5, 0.333, 0.25, 0.2, 0.167, 0.143, 0.125]
Sound: Bright, buzzy, rich
Math: All harmonics with 1/n amplitude
Use: Synth leads, bass, string section
```

### Triangle Wave
```
Harmonics: [1.0, 0, 0.111, 0, 0.04, 0, 0.02, 0]
Sound: Mellow, soft
Math: Odd harmonics with 1/n² amplitude
Use: Soft pads, flute-like sounds
```

### Organ
```
Harmonics: [1.0, 0.3, 0.5, 0.2, 0.4, 0.15, 0.25, 0.1]
Sound: Rich, full, church-like
Use: Sustained pads, pipe organ emulation
```

### Clarinet
```
Harmonics: [1.0, 0, 0.75, 0, 0.5, 0, 0.14, 0]
Sound: Hollow, woody
Math: Strong odd harmonics
Use: Woodwind-like tones, hollow effects
```

### Brass
```
Harmonics: [1.0, 0.7, 0.8, 0.5, 0.6, 0.3, 0.4, 0.2]
Sound: Bright, aggressive, fanfare-like
Math: Strong harmonics across the board
Use: Trumpet, horn, bright leads
```

### Flute
```
Harmonics: [1.0, 0.2, 0.05, 0.02, 0.01, 0, 0, 0]
Sound: Pure, breathy, soft
Math: Very weak upper harmonics
Use: Soft leads, ambient, meditation
```

## Parameters

### Saved to JSON
```json
{
  "fundamental_freq": 220.0,
  "harmonic_amplitudes": [1.0, 0.5, 0.333, 0.25, 0.2, 0.167, 0.143, 0.125],
  "freq_min": 110.0,
  "freq_max": 880.0,
  "num_harmonics": 8
}
```

### Compatible with
- `commons/audio/generators/CustomSoundGenerator.gd`
- `commons/audio/parameters/synthesizers/`

## Usage Examples

### Creating a Custom Bass Sound
1. Set fundamental to 110 Hz (A2)
2. Slider 1 (1×) → 100% (strong fundamental)
3. Slider 2 (2×) → 40% (octave punch)
4. Slider 3 (3×) → 20% (harmonic color)
5. Sliders 4-8 → 0-10% (subtle overtones)
6. Result: Punchy, harmonic-rich bass

### Creating a Soft Pad
1. Set fundamental to 220 Hz (A3)
2. Apply Organ preset
3. Reduce sliders 6-8 to 0% (remove harsh highs)
4. Result: Warm, full pad sound

### Creating a Retro Game Sound
1. Set fundamental to 440 Hz (A4)
2. Apply Square preset
3. Wheel up/down to vary pitch
4. Result: Classic 8-bit pickup sound

## Technical Details

### Audio Generation
- **Sample Rate:** 44100 Hz
- **Harmonics:** 8 simultaneous
- **Normalization:** Divided by √(active_count) to prevent clipping
- **Waveform:** Sum of sine waves

### Signal Formula
```
output(t) = Σ(amplitude[n] × sin(2π × n × f0 × t)) / √(active_harmonics)

Where:
- n = harmonic number (1-8)
- f0 = fundamental frequency
- amplitude[n] = slider value for harmonic n
- active_harmonics = count of harmonics with amplitude > 0.001
```

### Note Frequency Conversion
Based on A440 tuning:
```
f = 440 × 2^((n-69)/12)

Where n = MIDI note number
- A2 = 110 Hz (MIDI 45)
- A3 = 220 Hz (MIDI 57)
- A4 = 440 Hz (MIDI 69)
- A5 = 880 Hz (MIDI 81)
```

## Physics Behind It

### Fourier's Theorem
**ANY periodic function can be expressed as a sum of sine/cosine waves**

This synthesizer demonstrates **additive synthesis**:
- Start with silence
- Add sine waves at harmonic frequencies
- Each with specific amplitude
- Result: Complex, musical waveform

### Why Harmonics Sound Musical
Harmonics are integer multiples of the fundamental:
- **2× = octave** (perfect consonance)
- **3× = perfect fifth above octave**
- **4× = two octaves**
- **5× = major third**

These create **musical intervals** naturally found in:
- Vibrating strings (guitar, piano)
- Air columns (flute, organ pipes)
- Human voice

### Timbre = Harmonic Recipe
Two instruments playing the same note (e.g., A3 = 220 Hz) sound different because:
- **Same fundamental frequency** (220 Hz)
- **Different harmonic amplitudes** (flute has weak harmonics, trumpet has strong)
- **Different attack/decay** (not modeled here, but important)

**This synthesizer lets you design custom timbres by adjusting the harmonic recipe!**

## Advanced Techniques

### Creating Evolving Sounds
1. Start with one preset
2. Slowly adjust individual sliders
3. Morph between timbres (e.g., flute → clarinet → brass)

### Harmonic Emphasis
- Boost **odd harmonics** (1, 3, 5, 7) → hollow, square-like
- Boost **even harmonics** (2, 4, 6, 8) → octave-rich, full
- Boost **high harmonics** (5-8) → bright, aggressive
- Reduce **high harmonics** (5-8) → soft, mellow

### Musical Applications
- **Power chords:** Strong 1st and 2nd harmonics
- **Warm pads:** Balanced harmonics with soft highs
- **Cutting leads:** Strong high harmonics for presence
- **Sub bass:** Only fundamental + weak 2nd harmonic

## See Also
- `fourier_synthesis_axioms.gd` - Mathematical theory
- `AdditiveSynthesis.gd` - Visual harmonic demonstration
- `commons/audio/parameters/synthesizers/` - Pre-made synth sounds
- Beat Frequencies demo - Related wave interference concept
