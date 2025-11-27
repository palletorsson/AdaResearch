extends Node

var text = '''[center][font_size=28][b]Beat Frequencies[/b][/font_size][/center]
[center][i]Interference Creates Periodic Pulsing[/i][/center]

**When two close frequencies combine, you hear periodic loudness variation (beats).**

**Beat Frequency = |f1 - f2|**

- 440 Hz + 442 Hz = 2 Hz beat (wah-wah-wah, 2 times per second)
- 440 Hz + 445 Hz = 5 Hz beat (faster pulsing)
- 440 Hz + 440 Hz = 0 Hz beat (no pulsing, pure tone)

**The closer the frequencies → the slower the beats → the more "in tune" they are.**

[hr]

[b]The Physics[/b]

**Two sine waves with slightly different frequencies:**

[color=yellow][b]Wave 1:[/b][/color]
[code]
y1(t) = sin(2π · f1 · t)
# Example: f1 = 440 Hz (A4 concert pitch)
[/code]

[color=yellow][b]Wave 2:[/b][/color]
[code]
y2(t) = sin(2π · f2 · t)
# Example: f2 = 442 Hz (slightly sharp)
[/code]

[color=yellow][b]Combined (Superposition):[/b][/color]
[code]
y_total(t) = y1(t) + y2(t)
            = sin(2π · 440 · t) + sin(2π · 442 · t)
[/code]

**Trigonometric identity reveals the beat:**
[code]
sin(A) + sin(B) = 2 · cos((A-B)/2) · sin((A+B)/2)

Result:
y_total(t) = 2 · cos(2π · 1 · t) · sin(2π · 441 · t)
              ↑                      ↑
         Beat envelope          Average frequency
         (1 Hz = |440-442|/2)   (441 Hz = (440+442)/2)
[/code]

**You hear:** Tone at 441 Hz with amplitude pulsing at 1 Hz (but perceived as 2 Hz because envelope has 2 peaks per cycle).

[hr]

[b]Why Beats Happen[/b]

**Think of two waves drifting in and out of phase:**

**At t=0:** Both waves start at zero (in phase)
→ Peaks align → **Constructive interference** → LOUD

**At t=0.25s:** One wave ahead of the other (partially out of phase)
→ Peaks misaligned → **Partial cancellation** → quieter

**At t=0.5s:** Waves opposite (180° out of phase)
→ Peak meets trough → **Destructive interference** → QUIET

**At t=0.75s:** Coming back into phase
→ Peaks realigning → **Getting louder**

**At t=1.0s:** Back in phase
→ **LOUD again** → One complete beat cycle

**Beat frequency = how fast they drift through one complete phase cycle = |f1 - f2|**

[hr]

[b]Interactive Demo[/b]

**Try it yourself:**
[color=cyan]res://algorithms/wavefunctions/beat_frequencies/BeatFrequencies.tscn[/color]

**Controls:**
- Left slider: Frequency 1 (400-500 Hz)
- Right slider: Frequency 2 (400-500 Hz)
- Button: Toggle sound on/off

**Experiment:**
1. Start with frequencies far apart (e.g., 400 Hz and 450 Hz)
2. Hear fast beating (50 beats per second = roughness)
3. Slowly move sliders closer together
4. Beats slow down (5 Hz, then 2 Hz, then 1 Hz)
5. When frequencies match exactly → beats disappear!

**Visual feedback:**
- Red wave = Frequency 1
- Blue wave = Frequency 2
- Yellow wave = Combined (interference pattern)
- Green bars = Beat envelope (amplitude modulation)

[hr]

[b]Hearing Beats[/b]

**Beat frequency perception:**

[color=yellow][b]Very Slow (< 1 Hz):[/b][/color]
- Individual pulses clearly separated
- "Wah... wah... wah..."
- Used in meditation music, ambient drones

[color=yellow][b]Slow (1-5 Hz):[/b][/color]
- Clear pulsing rhythm
- "Wah-wah-wah-wah-wah"
- This is tremolo effect
- Used for tension, eerie atmospheres

[color=yellow][b]Medium (5-15 Hz):[/b][/color]
- Fast vibrato
- "Wawawawawawa"
- Adds richness, chorus effect
- Used in synth pads, strings

[color=yellow][b]Fast (15-20 Hz):[/b][/color]
- Roughness, texture
- Individual beats blur together
- Perceived as timbral quality, not rhythm

[color=yellow][b]Very Fast (> 20 Hz):[/b][/color]
- No longer beats
- Perceived as separate pitches (dissonance)
- Creates new frequency components

[hr]

[b]Musical Applications[/b]

**Tuning Instruments:**
[code]
# Tuning a guitar to a reference pitch
Reference: 440 Hz (tuning fork)
Guitar string: 442 Hz (slightly sharp)
Beat frequency: 2 Hz (hear wah-wah)

Tighten string slightly → 441 Hz
Beat frequency: 1 Hz (slower wah-wah)

Tighten more → 440 Hz
Beat frequency: 0 Hz (beats disappear!)
→ Perfect tune!
[/code]

**This is how orchestras tune** - they listen for beat elimination when matching pitch.

**Chorus Effect:**
[code]
# Electronic chorus effect
Original signal: 440 Hz
Delayed copy: 440 Hz → modulated to 439-441 Hz (vibrato)
Result: Beating between original and modulated
→ Rich, shimmering sound
→ Classic 80s synth sound
[/code]

**Detuned Oscillators:**
[code]
# Analog synthesizers (Moog, ARP, etc.)
Oscillator 1: 440 Hz
Oscillator 2: 440.5 Hz (slightly detuned)
Beat frequency: 0.5 Hz
→ Slow pulsing adds warmth, movement
→ "Fat" analog synth sound
[/code]

[hr]

[b]Code: Generate Beating[/b]

[color=yellow][b]Implementation:[/b][/color]
[code]
var freq1 = 440.0  # First frequency
var freq2 = 442.0  # Second frequency (close to first)
var phase1 = 0.0
var phase2 = 0.0
var sample_rate = 44100.0

func generate_beat_sample(delta_time: float) -> float:
    # Generate two sine waves
    var sample1 = sin(phase1)
    var sample2 = sin(phase2)

    # Combine (superposition)
    var combined = (sample1 + sample2) * 0.5  # Scale to prevent clipping

    # Update phases
    phase1 += freq1 * TAU / sample_rate
    phase2 += freq2 * TAU / sample_rate

    # Wrap phases
    if phase1 > TAU:
        phase1 -= TAU
    if phase2 > TAU:
        phase2 -= TAU

    return combined

# Beat frequency = |440 - 442| = 2 Hz
# You'll hear: tone at 441 Hz pulsing 2 times per second
[/code]

**Visualizing the beat envelope:**
[code]
# Beat envelope amplitude
func beat_envelope(time: float, freq1: float, freq2: float) -> float:
    var beat_freq = abs(freq1 - freq2)
    # Envelope has 2 peaks per beat cycle (rectified cosine)
    return abs(cos(PI * beat_freq * time)) * 2.0

# Example:
# freq1 = 440 Hz, freq2 = 442 Hz
# beat_freq = 2 Hz
# Envelope oscillates at 2 Hz with 2 peaks per second
[/code]

[hr]

[b]Game Audio Uses[/b]

**Atmospheric Drones:**
[code]
# Low frequency beating for eerie ambience
freq1 = 110 Hz  # A2
freq2 = 112 Hz  # Slightly sharp
beat_freq = 2 Hz
→ Deep, pulsing drone
→ Haunted environments, alien worlds
[/code]

**Sci-Fi Effects:**
[code]
# Mid-range beating for tech sounds
freq1 = 300 Hz
freq2 = 305 Hz
beat_freq = 5 Hz
→ Pulsing, mechanical sound
→ Spaceship engines, force fields
[/code]

**Tension Music:**
[code]
# Slow beating for suspense
freq1 = 220 Hz  # A3
freq2 = 221 Hz
beat_freq = 1 Hz
→ Slow, ominous pulsing
→ Horror, thriller, suspense scenes
[/code]

**Warning Alarms:**
[code]
# Fast beating for urgency
freq1 = 800 Hz
freq2 = 815 Hz
beat_freq = 15 Hz
→ Rapid pulsing, urgent
→ Alert sounds, danger warnings
[/code]

[hr]

[b]Physics vs Perception[/b]

**Physical reality:**
- Beat frequency = |f1 - f2|
- Example: |440 - 442| = 2 Hz

**But you hear beats at 2× this rate** because envelope has 2 maxima per cycle:
- Cosine envelope goes: max → min → max in one period
- So 2 Hz envelope = 4 perceived beats per second

**Musical beats (tempo):**
- When we say "2 Hz beat" in music, we mean 2 pulses per second
- But in physics, the beat *frequency* is half the pulse rate

**Don't get confused:**
- Beat frequency (physics) = |f1 - f2|
- Perceived beat rate (music) = 2 × |f1 - f2|

[hr]

[b]Advanced: Beat Frequencies in Spectrum[/b]

**Fourier analysis of beating:**

Original frequencies: f1, f2
**Sum and difference frequencies appear:**
- Sum: f1 + f2 (too high to hear directly)
- Difference: |f1 - f2| (the beat frequency)
- Average: (f1 + f2)/2 (carrier frequency)

**Amplitude modulation (AM radio):**
[code]
# AM is exactly beating between carrier and modulator
Carrier: fc = 1000 Hz
Modulator: fm = 10 Hz
Result: Beating at 10 Hz
Spectrum shows: fc - fm (990 Hz), fc (1000 Hz), fc + fm (1010 Hz)
[/code]

**Beats create sidebands** - this is fundamental to AM synthesis, ring modulation, and radio transmission.

[hr]

[b]Historical Note[/b]

**Helmholtz (1863)** first explained beats mathematically in "On the Sensations of Tone."

He showed:
- Consonance (pleasant intervals) = no beats or very slow beats
- Dissonance (unpleasant intervals) = fast beats (roughness)

**Musical intervals and beats:**
- Perfect unison (1:1 ratio) = no beats → consonant
- Octave (2:1 ratio) = no beats between fundamental → consonant
- Perfect fifth (3:2 ratio) = no beats between harmonics → consonant
- Minor second (16:15 ratio) = fast beats → dissonant

**Beats explain why some intervals sound "good" and others "bad"** - it's physics, not just culture.

[hr]

[b]Exercises[/b]

**Using the interactive demo:**

1. **Perfect Tuning Exercise:**
   - Set left slider to 440 Hz
   - Adjust right slider until beats disappear
   - You've found 440 Hz by ear!

2. **Beat Rate Perception:**
   - Set frequencies to 440 Hz and 442 Hz (2 Hz beat)
   - Count the "wah-wah" pulses in 10 seconds
   - Should hear about 20-40 pulses (because envelope has 2 peaks)

3. **Roughness Threshold:**
   - Start with matched frequencies (no beats)
   - Slowly increase frequency difference
   - Notice when smooth tone becomes rough (around 15-20 Hz beat)

4. **Musical Intervals:**
   - Set freq1 to 440 Hz (A4)
   - Set freq2 to 880 Hz (A5, octave above)
   - No beats! (because 880 = 2 × 440, harmonically related)

[hr]

[color=cyan][b]Summary:[/b][/color]
Beat frequency = |f1 - f2| when two close frequencies combine. Superposition creates periodic amplitude modulation. Slow beats = tuning, fast beats = roughness. Used for: tuning instruments, chorus effects, atmospheric drones, tension music. Interactive demo lets you hear and see beats. Physics: constructive/destructive interference cycling. Perception: envelope has 2 peaks per beat cycle. Musical application: consonance vs dissonance explained by beat rate.

[hr]

[color=orange][b>Try It Now:[/b][/color]
Open [color=cyan]res://algorithms/wavefunctions/beat_frequencies/BeatFrequencies.tscn[/color]

Move the sliders. Hear the beating. Watch the interference pattern.
When beats slow down → you're getting closer to perfect tune.
When beats disappear → frequencies match perfectly!

**This is how musicians tune by ear.**

'''
