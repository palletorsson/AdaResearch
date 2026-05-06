extends Node

var text = '''[center][font_size=28][b]The Harmonic Series[/b][/font_size][/center]
[center][i]Integer Multiples Create Musical Sound[/i][/center]

**The harmonic series is the foundation of musical sound.**

**Harmonics = sine waves at integer multiples of a fundamental frequency:**
- 1× fundamental (f)
- 2× first overtone (2f) = octave
- 3× second overtone (3f) = perfect fifth above octave
- 4× third overtone (4f) = two octaves
- ... continues infinitely

**EVERY musical instrument produces harmonics.** The balance of harmonic amplitudes determines **timbre** (why a flute sounds different from a trumpet).

[hr]

[b]The Fundamental Concept[/b]

**Harmonic number × fundamental frequency = harmonic frequency**

[color=yellow][b]Example: A3 = 220 Hz[/b][/color]
[code]
Harmonic 1 (fundamental): 1 × 220 Hz = 220 Hz  (A3)
Harmonic 2 (octave):      2 × 220 Hz = 440 Hz  (A4)
Harmonic 3 (fifth):       3 × 220 Hz = 660 Hz  (E5)
Harmonic 4:               4 × 220 Hz = 880 Hz  (A5)
Harmonic 5:               5 × 220 Hz = 1100 Hz (C#6)
Harmonic 6:               6 × 220 Hz = 1320 Hz (E6)
Harmonic 7:               7 × 220 Hz = 1540 Hz (G6)
Harmonic 8:               8 × 220 Hz = 1760 Hz (A6)
[/code]

**These are the frequencies naturally produced when you pluck a string, blow into a tube, or sing a note.**

[hr]

[b]Why Integer Multiples?[/b]

**Physics of vibrating systems:**

**A guitar string vibrates in multiple modes simultaneously:**

[color=yellow][b]Fundamental (1st harmonic):[/b][/color]
[code]
|---------------|  One half-wavelength fits on string
     ↑     ↑
   Node   Node

Frequency: f = v / (2L)
Where v = wave speed, L = string length
[/code]

[color=yellow][b]2nd harmonic:[/b][/color]
[code]
|------|------|  Two half-wavelengths fit
   ↑   ↑   ↑
  Node Mid Node

Frequency: 2f (exactly double)
[/code]

[color=yellow][b]3rd harmonic:[/b][/color]
[code]
|---|---|---|  Three half-wavelengths fit
 ↑  ↑  ↑  ↑

Frequency: 3f (exactly triple)
[/code]

**Only integer multiples create standing waves** (wavelengths that fit evenly on the string).

**Non-integer multiples don't reinforce** → they cancel out → you don't hear them.

**This is why harmonics are integers, not arbitrary frequencies.**

[hr]

[b]Interactive Demo[/b]

**Try it yourself:**
[color=cyan]res://algorithms/wavefunctions/harmonic_builder/HarmonicBuilder.tscn[/color]

**Controls:**
- 8 vertical sliders: Amplitude of each harmonic (1× through 8×)
- Wheel: Fundamental frequency (110-880 Hz, A2-A5)
- 8 preset buttons: Different instrument timbres

**Experiment:**
1. Press "Sine" → Only fundamental (pure tone)
2. Press "Square" → Odd harmonics (1, 3, 5, 7) → hollow, 8-bit sound
3. Press "Brass" → Strong all harmonics → bright, aggressive
4. Press "Flute" → Weak upper harmonics → soft, pure
5. Adjust individual sliders → morph between sounds

**Visual feedback:**
- 8 colored bars show harmonic amplitudes
- Waveform display shows resulting wave shape
- Frequency label shows pitch (e.g., "220 Hz (A3)")

[hr]

[b]Timbre = Harmonic Recipe[/b]

**Why instruments sound different:**

[color=yellow][b]Flute:[/b][/color]
[code]
Harmonics: [1.0, 0.2, 0.05, 0.02, 0.01, 0, 0, 0]
           ↑    Weak upper harmonics

Sound: Pure, soft, breathy
Why: Air column in tube has weak upper modes
Result: Gentle, mellow timbre
[/code]

[color=yellow][b]Clarinet:[/b][/color]
[code]
Harmonics: [1.0, 0, 0.75, 0, 0.5, 0, 0.14, 0]
           ↑    Only odd harmonics (2nd, 4th, 6th, 8th are absent)

Sound: Hollow, woody
Why: Closed tube (one end closed) → only odd harmonics resonate
Result: Square-wave-like timbre
[/code]

[color=yellow][b]Brass (Trumpet):[/b][/color]
[code]
Harmonics: [1.0, 0.7, 0.8, 0.5, 0.6, 0.3, 0.4, 0.2]
           ↑    Strong all harmonics

Sound: Bright, aggressive, cutting
Why: Metal tube with complex bell shape → many modes
Result: Rich, full timbre with "edge"
[/code]

[color=yellow][b]Sawtooth (Synthesizer):[/b][/color]
[code]
Harmonics: [1.0, 0.5, 0.33, 0.25, 0.2, 0.17, 0.14, 0.13]
           ↑    All harmonics with 1/n amplitude

Sound: Bright, buzzy, rich
Why: Mathematical formula (Fourier series of sawtooth)
Result: Classic analog synth sound
[/code]

**Same fundamental frequency (e.g., 220 Hz), but different harmonic balances = different sounds.**

[hr]

[b]Musical Intervals from Harmonics[/b]

**Harmonics create musical intervals:**

[color=yellow][b]Harmonic Ratios:[/b][/color]
[code]
Harmonic 2 / Harmonic 1 = 2:1 → Octave
Harmonic 3 / Harmonic 2 = 3:2 → Perfect Fifth
Harmonic 4 / Harmonic 3 = 4:3 → Perfect Fourth
Harmonic 5 / Harmonic 4 = 5:4 → Major Third
Harmonic 6 / Harmonic 5 = 6:5 → Minor Third
[/code]

**This is why these intervals sound "natural"** - they're built into the harmonic series!

**Major chord = harmonics 4, 5, 6:**
[code]
Fundamental: 100 Hz
Harmonic 4:  400 Hz  (two octaves up)
Harmonic 5:  500 Hz  (major third above H4)
Harmonic 6:  600 Hz  (perfect fifth above H4)

Ratio 4:5:6 = Major triad
This is THE major chord, naturally occurring in harmonics
[/code]

**Western music theory is derived from the harmonic series.**

[hr]

[b]Fourier Synthesis = Adding Harmonics[/b]

**Additive synthesis** = building complex waves by adding sine waves at harmonic frequencies.

[color=yellow][b]Code: Generate Harmonic Sound[/b][/color]
[code]
var fundamental_freq = 220.0  # A3
var harmonic_amplitudes = [1.0, 0.5, 0.33, 0.25, 0.2, 0.17, 0.14, 0.13]
var phases = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var sample_rate = 44100.0

func generate_sample() -> float:
    var sample = 0.0

    # Add each harmonic
    for n in range(8):
        var harmonic_freq = fundamental_freq * (n + 1)  # 1×, 2×, 3×, ...
        var amplitude = harmonic_amplitudes[n]

        # Generate sine wave for this harmonic
        sample += sin(phases[n]) * amplitude

        # Update phase
        phases[n] += harmonic_freq * TAU / sample_rate
        if phases[n] > TAU:
            phases[n] -= TAU

    # Normalize to prevent clipping
    sample = sample / sqrt(count_active_harmonics())

    return clamp(sample, -1.0, 1.0)

# This creates a complex, musical waveform from simple sines!
[/code]

[hr]

[b]Square Wave from Harmonics[/b]

**Square wave = infinite odd harmonics with 1/n amplitude**

[color=yellow][b]Fourier Series of Square Wave:[/b][/color]
[code]
square(t) = (4/π) × [sin(ωt)/1 + sin(3ωt)/3 + sin(5ωt)/5 + sin(7ωt)/7 + ...]

Where ω = 2πf (angular frequency)

Simplified:
square(t) = Σ [(4/π) × sin((2n+1)ωt) / (2n+1)]
            n=0,1,2,3...
[/code]

**With limited harmonics:**
[code]
# Only 1st harmonic (fundamental):
Result: Pure sine wave (smooth)

# Add 3rd harmonic (1/3 amplitude):
Result: Starts to flatten top/bottom

# Add 5th harmonic (1/5 amplitude):
Result: Sharper edges forming

# Add 7th harmonic (1/7 amplitude):
Result: More square-like

# Add infinite odd harmonics:
Result: Perfect square wave (sharp edges)
[/code]

**Try this in the demo:**
1. Press "Square" preset
2. Watch waveform become square-ish
3. Adjust individual harmonics to see effect

[hr]

[b]Harmonic Amplitudes in Nature[/b]

**Different instruments have different decay rates for harmonics:**

[color=yellow][b]Piano:[/b][/color]
[code]
Time 0s:   All harmonics strong
Time 1s:   Upper harmonics fade faster
Time 2s:   Mostly fundamental remains
Result: Tone becomes "duller" over time
[/code]

**This is why piano sounds "bright" at attack, "mellow" during sustain.**

[color=yellow][b]Violin (bowed):[/b][/color]
[code]
Sustained: All harmonics remain steady
Result: Consistent timbre while bowing
[/code]

**In our demo, harmonics don't decay** - this is a simplified model.
Real instruments have time-varying harmonic content (envelopes).

[hr]

[b]Harmonic Series in Brass Instruments[/b]

**Trumpet, trombone, french horn can only play harmonic series notes** (without valves):

[color=yellow][b]Natural Harmonic Series (Bb trumpet, no valves):[/b][/color]
[code]
Fundamental: Bb1 (58.3 Hz) - too low, barely audible
Harmonic 2:  Bb2 (116.5 Hz) - pedal tone
Harmonic 3:  F3 (174.6 Hz) - perfect fifth above
Harmonic 4:  Bb3 (233.1 Hz) - octave above H2
Harmonic 5:  D4 (291.7 Hz) - major third
Harmonic 6:  F4 (349.2 Hz) - perfect fifth
Harmonic 7:  Ab4 (407.8 Hz) - flat seventh
Harmonic 8:  Bb4 (466.2 Hz) - octave above H4
Harmonic 9:  C5 (524.4 Hz) - major second
Harmonic 10: D5 (583.3 Hz) - major third
... and so on
[/code]

**Valves add extra tubing** → changes fundamental → different harmonic series available.

**Bugle (no valves) can only play these notes** → that's why military calls use limited pitches.

[hr]

[b]Inharmonicity[/b]

**Not all instruments have perfect harmonic series:**

[color=yellow][b]Piano strings are slightly inharmonic:[/b][/color]
[code]
# Theoretical harmonics:
H1: 220 Hz
H2: 440 Hz (exactly 2×)
H3: 660 Hz (exactly 3×)

# Actual piano harmonics (slightly sharp):
H1: 220 Hz
H2: 440.2 Hz (slightly > 2×)
H3: 660.8 Hz (slightly > 3×)
[/code]

**Why:** String stiffness causes higher modes to be sharper.
**Result:** Piano timbre has slight "zing" or "metallic" quality.

**Bells and gongs are very inharmonic** → partials are NOT integer multiples → creates complex, bell-like timbre.

[hr]

[b]Formants vs Harmonics[/b]

**Human voice has both:**

**Harmonics:** Determined by vocal cord vibration frequency
- Pitch = fundamental frequency
- Higher pitch = higher harmonics

**Formants:** Resonant frequencies of vocal tract (mouth, throat)
- Independent of pitch
- Create vowel sounds
- Stay constant even when pitch changes

[color=yellow][b]Example: Singing "Ah"[/b][/color]
[code]
Low note (A3 = 220 Hz):
Harmonics: 220, 440, 660, 880, 1100, 1320, ...
Formants: ~700 Hz (F1), ~1200 Hz (F2) ← vowel "ah"

High note (A4 = 440 Hz):
Harmonics: 440, 880, 1320, 1760, 2200, ...
Formants: Still ~700 Hz (F1), ~1200 Hz (F2) ← same vowel

Different pitch, same vowel sound!
[/code]

**Formants are like fixed filters** applied to the harmonic series.

[hr]

[b]Game Audio Applications[/b]

**Using the Harmonic Builder for game sounds:**

[color=yellow][b]Pickup Sound (8-bit style):[/b][/color]
[code]
Preset: Square
Fundamental: 523 Hz (C5)
Duration: 0.3 seconds
Result: Classic Mario-style coin pickup
[/code]

[color=yellow][b]Synth Lead Melody:[/b][/color]
[code]
Preset: Sawtooth or Brass
Fundamental: 440-880 Hz range
Add vibrato: Slightly modulate frequency
Result: Classic synth lead for game music
[/code]

[color=yellow][b]Bass Line:[/b][/color]
[code]
Preset: Sawtooth
Fundamental: 55-110 Hz (low A)
Strong H1, H2, weak upper harmonics
Result: Punchy bass for game soundtrack
[/code]

[color=yellow][b]Ambient Pad:[/b][/color]
[code]
Preset: Organ or Flute
Fundamental: 220 Hz (A3)
Reduce high harmonics for softness
Result: Ethereal background atmosphere
[/code]

[hr]

[b]Exercises[/b]

**Using the interactive demo:**

1. **Build a Square Wave:**
   - Set all sliders to 0
   - Slider 1 (1×) → 100%
   - Slider 3 (3×) → 33%
   - Slider 5 (5×) → 20%
   - Slider 7 (7×) → 14%
   - See waveform become square-ish!

2. **Hear Individual Harmonics:**
   - Set all sliders to 0
   - Raise slider 1 → hear fundamental
   - Lower slider 1, raise slider 2 → hear octave
   - Lower slider 2, raise slider 3 → hear fifth
   - Notice how higher harmonics sound "higher pitched"

3. **Morph Between Timbres:**
   - Press "Flute" (soft, pure)
   - Slowly raise sliders 2-8
   - Hear sound become brighter, richer
   - End at "Brass" (bright, aggressive)

4. **Discover Musical Intervals:**
   - Set fundamental to 220 Hz (A3)
   - Only slider 1 at 100% → hear A3
   - Add slider 2 at 50% → hear octave (A4)
   - Add slider 3 at 33% → hear fifth (E5)
   - This is a chord built from harmonics!

[hr]

[color=cyan][b]Summary:[/b][/color]
Harmonic series = integer multiples of fundamental (1×, 2×, 3×, ...). Natural in vibrating strings, air columns, all instruments. Timbre = harmonic amplitude recipe. Square wave = odd harmonics with 1/n amplitude. Musical intervals (octave, fifth) emerge from harmonic ratios. Additive synthesis = building sounds by adding harmonics. Interactive demo lets you shape timbre by controlling 8 harmonics. Different balances = different instruments (flute vs brass vs clarinet). Foundation of music theory and acoustics.

[hr]

[color=orange][b]Try It Now:[/b][/color]
Open [color=cyan]res://algorithms/wavefunctions/harmonic_builder/HarmonicBuilder.tscn[/color]

Press the preset buttons. Hear how different harmonic balances create different sounds.
Adjust sliders. Morph between timbres.
Turn the wheel. Change the pitch.

**You're doing Fourier synthesis - building complex sounds from simple sines!**

**This is how every musical instrument in the world works.**

'''
