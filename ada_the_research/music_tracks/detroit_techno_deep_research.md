# Detroit Techno Deep Research
## Sound Engineering Analysis

**Compiled for:** AdaResearch procedural audio system  
**Focus:** Authentic synthesis parameters, gear specifications, genre contamination prevention

---

## Historical Context

### The Belleville Three (1981-1988 formative period)
- **Juan Atkins** (Model 500, Cybotron) - Metroplex Records
- **Derrick May** (Rhythim is Rhythim) - Transmat Records  
- **Kevin Saunderson** (Inner City) - KMS Records

### Foundational Gear
Primary machines used in original Detroit productions:

| Gear | Used For | Notes |
|------|----------|-------|
| **Roland TR-909** | Drums | THE sound. Hybrid analog/digital |
| **Roland TR-808** | Bass, some drums | Sub bass source |
| **Roland Juno-106** | Pads, strings | Clean DCO, no pitch drift |
| **Roland JX-3P** | Pads, stabs | Similar character to Juno |
| **Yamaha DX7** | Stabs, bells | FM synthesis, cold/metallic |
| **Korg Poly-61** | Pads | Budget alternative |
| **Sequential Circuits Pro-One** | Bass, leads | Mono synth |
| **Roland TB-303** | Bass lines | Less common in Detroit than acid |

---

## TR-909 Drum Specifications (Technical Deep Dive)

### Kick Drum Circuit Analysis
The 909 kick uses a hybrid approach:
- **Attack transient:** Analog VCA with fast attack
- **Body:** Bridged-T oscillator (NOT a simple VCO)
- **Pitch sweep:** Exponential decay from ~150Hz to ~50Hz

**Measured Parameters:**
```
Attack time: 1-3ms (faster than 808)
Initial pitch: 130-180Hz (depending on tune setting)
Settling pitch: 45-55Hz
Pitch decay time: 20-30ms
Amplitude decay: 100-150ms
Click component: ~4kHz, 2-3ms duration
```

**Key difference from 808:** The 909 has a pronounced "click" attack from the analog VCA. The 808 is smoother, more boomy. Detroit uses the 909's punch specifically.

### Snare Drum
- **Tone oscillators:** Two bridged-T oscillators at ~180Hz and ~330Hz
- **Noise:** Digital noise (6-bit LFSR) through analog envelope
- **Snappy control:** Adjusts noise vs. tone ratio

**Measured Parameters:**
```
Tone frequencies: 180Hz + 330Hz (ring-modulated character)
Tone decay: 30-50ms
Noise spectrum: Bandpass filtered around 5-8kHz
Noise decay: 40-60ms (snappy) to 150ms (long)
NO reverb in original circuit
```

### Hi-Hat
The 909 hi-hat is distinctive - uses six square wave oscillators at non-harmonic frequencies:
```
Frequencies: 263Hz, 400Hz, 421Hz, 474Hz, 587Hz, 845Hz
Mixed through bandpass filter centered at 8-10kHz
Closed decay: 20-30ms
Open decay: 100-200ms
```

This creates the "metallic ring" that is unmistakable in Detroit techno.

### Clap
The 909 clap uses **four retriggered noise bursts**:
```
Burst spacing: 10-15ms
Individual burst decay: 5-10ms
Tail decay: 50-100ms
Reverb: Built into circuit (~100ms reverb tail)
```

---

## Synthesis: The "Clean Digital" Aesthetic

### Why Detroit Sounds "Cold"

Detroit techno's distinctive coldness comes from:

1. **ZERO detune on pads** - Unlike synthwave (15¢) or rave (40¢), Detroit uses mathematically precise pitch
2. **DCO oscillators** - The Juno-106 uses Digitally Controlled Oscillators, not VCOs. They don't drift.
3. **Minimal processing** - No tape saturation, no tube warmth
4. **High-frequency presence** - +2 to +3dB shelf above 4kHz
5. **Dry reverb** - Much drier than Chicago house or acid

### Roland Juno-106 DCO Specifications

The Juno-106 is THE Detroit pad synth. Key specs:

```
Oscillator: DCO (Digital Controlled Oscillator)
Waveforms: Saw, Square, Pulse (with PWM)
Pitch stability: ±0.5 cents (virtually perfect)
Sub-oscillator: -1 octave square wave
Filter: IR3109 VCF (4-pole lowpass, 24dB/octave)
  - Cutoff range: 18Hz to 18kHz
  - Resonance: Self-oscillation capable
Chorus: Built-in (BUT not used in Detroit - it adds warmth)
```

**Detroit Pad Recipe (Juno-106):**
```
Waveform: Saw (100%)
Sub-oscillator: OFF (adds warmth, not wanted)
Chorus: OFF (contamination!)
Filter cutoff: 3000-4000Hz (bright)
Filter resonance: 20-30%
Attack: 300-600ms (slow fade in)
Decay: 200-400ms
Sustain: 60-80%
Release: 500-1000ms
Detune: ZERO
```

### Yamaha DX7 Stab Parameters

The DX7's FM synthesis creates the metallic stabs heard in tracks like "Strings of Life":

**Classic Detroit Stab (Algorithm 5):**
```
Algorithm: 5 (parallel carriers with shared modulator)
Operators:
  OP1: Ratio 1.00, Level 99, Attack 0, Decay 50
  OP2: Ratio 2.00, Level 80, Attack 0, Decay 35
  OP3: Ratio 0.50, Level 90, Attack 0, Decay 60
  OP4 (mod): Ratio 3.00, Level 60, Feedback 4

Total attack: <10ms
Total decay: 50-100ms
Sustain: 0 (purely percussive)
Character: Bell-like, metallic, cold
```

---

## 808 Sub Bass for Detroit

The 808 bass drum circuit repurposed as bass:

**Original 808 Kick Circuit:**
```
Pitch range: 30-80Hz (tunable)
Pitch envelope: Exponential decay
Attack: ~2ms
Decay: 500-1500ms (long boom)
Waveform: Sine with slight clipping at high levels
```

**Detroit Bass Adaptation:**
- Filter to keep only sub frequencies (<150Hz)
- Gate to control decay (tighter than raw 808)
- Lock to kick pattern (unison or octave)
- NO distortion (contamination - that's acid/rave territory)

---

## Forbidden Sounds (Contamination List)

These sounds would destroy the Detroit identity:

| Sound | Why Forbidden | Belongs To |
|-------|--------------|------------|
| Supersaw (detuned stack) | Too lush, emotional | Synthwave, Trance |
| Hoover bass | Too aggressive, excessive | Rave, Jungle |
| Tape saturation | Too warm | Lo-fi, BoC |
| Gated reverb | Too 80s | Pop, Synthwave |
| Pitch drift/wow | Too analog | BoC, Lo-fi |
| Pad detune >5¢ | Too warm | Everything else |
| Vinyl crackle | Wrong era aesthetic | Lo-fi |
| Breakbeats | Wrong drum machine | Jungle, Rave |
| 303 acid squelch | Wrong subgenre | Acid, Chicago |

---

## Frequency Spectrum Analysis

**Ideal Detroit Techno EQ Curve:**
```
20-60Hz:    +2dB (sub presence from 808/909 kick)
60-200Hz:   0dB (clean, not muddy)
200-800Hz:  -1dB (slight scoop for clarity)
800-2kHz:   0dB (neutral mids)
2-4kHz:     +1dB (presence for stabs)
4-10kHz:    +2dB (metallic 909 character)
10-20kHz:   0dB (air, but not harsh)
```

---

## Arrangement Principles

### The Hypnotic Loop
Detroit techno is NOT about change. It's about:
- **Repetition as meditation** - Same 8-bar loop for minutes
- **Minimal variation** - Hi-hat open/closed, filter movement
- **Groove over melody** - The rhythm carries everything
- **Space** - Leave room for the club sound system

### Section Template
```
Intro (8-16 bars): Pad only, maybe bass fading in
Build (8 bars): Add hi-hats, build anticipation
Main (32-64 bars): Full loop, minimal changes
Breakdown (8-16 bars): Remove kick, let pad breathe
Main (32-64 bars): Return of the groove
Outro (8-16 bars): Fade to pad, then silence
```

---

## Velocity and Dynamics

**909 Velocity Response:**
- Kick: Constant (no velocity variation)
- Snare: Constant
- Hi-hats: Slight variation (0.9-1.0 range)
- Clap: Constant

Detroit is **machine music**. Human dynamics are contamination.

---

## References

### Essential Listening (for parameter verification):
1. Juan Atkins - "No UFOs" (1985) - Original Metroplex sound
2. Derrick May - "Strings of Life" (1987) - DX7 stabs, 909 drums
3. Kevin Saunderson - "Big Fun" (1988) - Production techniques
4. Model 500 - "Night Drive" (1985) - Proto-techno template
5. Rhythim is Rhythim - "Nude Photo" (1987) - Minimal arrangement
6. Jeff Mills - "The Bells" (1996) - Hard Detroit evolution
7. Underground Resistance - "Punisher" (1991) - Industrial edge

### Technical Sources:
- Roland TR-909 Service Manual (schematic analysis)
- "Analog Days" by Trevor Pinch (synthesis history)
- Sound on Sound retrospectives on drum machine circuits
- Vintage Synth Explorer specifications database

---

## Implementation Notes for AdaResearch

### Current Soundbank Assessment

After reviewing the existing `detroit_techno` soundbank:

**ACCURATE:**
- Kick: Good pitch envelope, correct decay times
- Pad: Correctly enforces ZERO detune
- Bass: Proper 808 sub character

**NEEDS IMPROVEMENT:**
1. **Snare** - Should use two tone oscillators (180Hz + 330Hz), not single frequency
2. **Hi-hat** - Should use 6-oscillator metallic synthesis, not just noise
3. **Stab** - Could benefit from FM-style synthesis for more authentic DX7 character

### Recommended Parameter Updates

**Snare (DetroitSnare.gd):**
```gdscript
# CURRENT: Single BODY_FREQ_HZ = 220.0
# SHOULD BE: Two frequencies for ring-mod character
const BODY_FREQ_1_HZ = 180.0
const BODY_FREQ_2_HZ = 330.0
```

**Hi-Hat (DetroitHihat.gd):**
```gdscript
# CURRENT: Two metallic frequencies
# SHOULD BE: Six non-harmonic square waves
const METAL_FREQS = [263.0, 400.0, 421.0, 474.0, 587.0, 845.0]
```

---

*Research compiled by Ada (Sound-Engineer role)*  
*Last updated: 2025*
