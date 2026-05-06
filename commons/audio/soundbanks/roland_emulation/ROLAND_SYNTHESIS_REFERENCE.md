# Roland Synthesis Emulation Reference

A guide to recreating classic Roland synthesizer characteristics through software synthesis.

---

## Juno-60 / Juno-106 (1982-1984)

The Juno series defined the "analog polysynth" sound. Warm, immediate, and that *chorus*.

### Architecture
- **Oscillator**: Single DCO per voice (digitally controlled analog)
- **Waveforms**: Saw, Pulse (with PWM), Sub oscillator (square, -1 or -2 octaves)
- **Filter**: 4-pole lowpass (24dB/oct), non-resonant self-oscillation
- **Chorus**: The secret sauce — BBD (bucket brigade delay) stereo chorus

### Key Characteristics
| Parameter | Juno Value | Emulation Approach |
|-----------|------------|-------------------|
| Oscillator drift | Subtle, ~2-5 cents | Random LFO on pitch, very slow (0.1Hz) |
| Filter character | Warm, not aggressive | Gentle resonance curve, slight saturation |
| PWM range | 0-99% | LFO modulating pulse width, rate 0.5-2Hz |
| Chorus I | Subtle stereo widening | Delay 1-3ms, mod depth 0.5ms, rate 0.5Hz |
| Chorus II | Thicker, more movement | Delay 3-6ms, mod depth 1.5ms, rate 0.8Hz |
| Chorus I+II | Massive, ensemble-like | Both combined, creates complex modulation |

### Signature Patches to Emulate
1. **"Juno Strings"** — Saw + sub, filter ~60%, chorus II, slow attack
2. **"Juno Bass"** — Square + sub, filter ~40%, short decay, no chorus
3. **"Juno Pad"** — PWM pulse, filter ~50%, chorus I+II, long attack/release
4. **"Hoover/Mentasm"** — Saw, pitch bend down, heavy portamento (Juno-106 + sampler)

---

## Roland D-50 (1987)

Linear Arithmetic synthesis — short PCM attack samples + sustained synthesis.

### Architecture
- **Partials**: 2 per tone, each has PCM attack OR synth waveform
- **PCM Attacks**: Short samples (piano hammer, breath, pick) that add realism
- **Synthesis**: Digital waveforms shaped by TVA (amp) and TVF (filter)
- **Effects**: Built-in reverb and chorus (revolutionary for 1987)

### Key Characteristics
| Parameter | D-50 Value | Emulation Approach |
|-----------|------------|-------------------|
| PCM attacks | 100+ short samples | Layer short noise/transient at note start |
| Waveforms | Saw, square, + complex | Use wavetables or layered oscillators |
| Filter | Digital, clean | Less warmth than analog, precise |
| Reverb | Lush, long | Hall reverb, 2-4 second decay |
| Stereo | Wide panning per partial | Pan layers L/R for width |

### Signature Patches to Emulate
1. **"Digital Native Dance"** — Breathy attack + saw pad, heavy reverb
2. **"Fantasia"** — Bell attack + strings, the quintessential D-50 sound
3. **"Staccato Heaven"** — Short PCM + quick decay, orchestral stabs
4. **"Glass Voices"** — Breath noise + high-passed pad, ethereal

### LA Synthesis Recipe
```
Layer 1: Short noise burst (10-50ms) for attack
Layer 2: Sustained pad with slow attack (100-300ms)
Mix: Layer 1 at 30-40%, Layer 2 at 60-70%
Apply: Hall reverb, wide stereo
```

---

## Roland JV-1080 / JV-2080 (1994-1997)

The 90s workhorse. Used on countless R&B, pop, hip-hop, and electronic tracks.

### Architecture
- **Sample + Synthesis**: High-quality PCM samples with subtractive synthesis
- **Patches**: 4 tones per patch, each with own filter/amp/LFO
- **Expansion**: SR-JV80 boards (world, keyboards, orchestral, etc.)
- **Effects**: Extensive — 40+ algorithms, 3 simultaneous

### Key Characteristics
| Parameter | JV Value | Emulation Approach |
|-----------|----------|-------------------|
| Sample quality | 16-bit, clean | High-quality samples or wavetables |
| Filter | Smooth digital, -12 or -24dB | Clean lowpass, moderate resonance |
| Attack transients | Punchy, defined | Short amp attack with slight bump |
| Velocity response | Expressive | Map velocity to filter + amp |
| Pad movement | LFO on filter/pitch | Slow LFO (0.2-1Hz), subtle depth |

### Signature Patches to Emulate
1. **"JV Strings"** — Lush ensemble, moderate attack, wide stereo
2. **"JV Piano"** — Rhodes-like EP, velocity-sensitive, warm
3. **"Analog Pad" (SR-JV80-04)** — Saw + PWM, Juno-like but cleaner
4. **"JV Choir"** — Breathy "ahh", heavy reverb, slow attack
5. **"Pop Brass"** — Punchy stabs, tight filter envelope

### 90s R&B JV Recipe
```
Rhodes: Velocity → filter cutoff (50-80%), tremolo 4-6Hz
Strings: Slow attack (200-400ms), hall reverb, wide pan
Bass: Saw + sub, tight filter envelope, slight saturation
Pads: PWM or detuned saws, chorus, long release
```

---

## TR-808 (1980)

The bass drum that launched a thousand genres.

### Drum Synthesis
| Sound | Synthesis Method |
|-------|-----------------|
| Kick | Sine wave, pitch envelope (start ~150Hz, end ~50Hz), long decay (400-800ms) |
| Snare | Noise burst + two sine tones (~180Hz, ~330Hz), short decay |
| Clap | Noise burst × 4, staggered timing (creates "spread"), reverb |
| Hi-hat (closed) | High-passed noise (8-12kHz), 50ms decay |
| Hi-hat (open) | High-passed noise, 200-400ms decay |
| Cowbell | Two square waves (~540Hz, ~800Hz), ring mod character |
| Clave | Short sine click (~2500Hz), 10ms decay |
| Rimshot | Noise + sine (~1700Hz), 30ms decay |
| Tom | Sine wave, pitch envelope, adjustable decay |
| Conga | Sine wave (~200-400Hz), pitch envelope, 100-200ms decay |
| Maracas | High-frequency noise burst, very short |

### 808 Kick Deep Dive
```
Oscillator: Sine wave
Pitch start: 150-300Hz (controls "click")
Pitch end: 45-60Hz (the sub weight)
Pitch decay: 30-80ms (exponential)
Amp decay: 400-1000ms
Overdrive: Subtle saturation for punch
```

---

## TR-909 (1983)

The kick and hi-hats that defined house and techno.

### Drum Synthesis
| Sound | Synthesis Method |
|-------|-----------------|
| Kick | Sine + noise click, pitch envelope, tighter than 808 (200-400ms decay) |
| Snare | Noise + two tones, punchier than 808, "crack" character |
| Clap | Similar to 808 but snappier, more reverb options |
| Hi-hat (closed) | Metallic noise (6 oscillators "ringing"), 30-60ms decay |
| Hi-hat (open) | Same source, 200-500ms decay |
| Ride | Complex metallic, multiple detuned oscillators |
| Crash | Noise + metallic ring, long decay |
| Tom | Sine wave, tighter pitch envelope than 808 |

### 909 Kick Recipe
```
Oscillator 1: Sine wave (main body)
Oscillator 2: Short noise burst (click, 5ms)
Pitch start: 200-350Hz
Pitch end: 50-70Hz  
Pitch decay: 20-50ms (faster than 808)
Amp decay: 200-400ms (tighter than 808)
Character: More "punch", less "boom"
```

### 909 Hi-Hat Recipe
```
Oscillators: 6 square waves, detuned (creates metallic ring)
Frequencies: ~200Hz, ~260Hz, ~310Hz, ~365Hz, ~415Hz, ~580Hz
Mix: Through bandpass filter (6-10kHz center)
Decay: 30ms (closed), 200-500ms (open)
Character: Metallic "tsss" vs 808's pure noise "shhh"
```

---

## General Emulation Principles

### Analog vs Digital Character
| Aspect | Analog (Juno, 808) | Digital (D-50, JV) |
|--------|-------------------|-------------------|
| Oscillator | Slight drift, warmth | Stable, precise |
| Filter | Soft saturation, organic | Clean, defined |
| Noise floor | Subtle hiss | Silent |
| Stereo | Mono + effects | Native stereo samples |

### Adding "Analog" Character to Digital Synthesis
1. **Pitch drift**: Very slow random LFO (0.05-0.2Hz) on pitch, ±2-5 cents
2. **Filter saturation**: Soft clip before filter, subtle
3. **Noise floor**: Add -60dB pink noise
4. **Chorus**: BBD-style modulated delay for stereo width
5. **Detune**: Multiple oscillators, ±3-8 cents
6. **DC offset**: Subtle asymmetry in waveforms

### The "Roland Filter" Sound
Roland's filters across eras have a specific character:
- **Juno/Jupiter**: Warm, musical resonance, doesn't scream
- **D-50/JV**: Clean, precise, less "analog" but smooth
- **Emulation**: Use 4-pole (-24dB) lowpass, moderate resonance (never harsh), slight pre-filter saturation

---

## Implementation Notes for Godot

When implementing in GDScript AudioStreamGenerator:

```gdscript
# Juno-style chorus (simplified)
var chorus_delay_l = 0.003  # 3ms base delay
var chorus_delay_r = 0.004  # Slightly different for stereo
var chorus_mod_depth = 0.001  # 1ms modulation depth
var chorus_rate = 0.6  # Hz

# 808 kick pitch envelope
func get_808_kick_pitch(time_since_trigger: float) -> float:
    var pitch_start = 150.0
    var pitch_end = 50.0
    var pitch_decay = 0.05  # 50ms
    var t = clamp(time_since_trigger / pitch_decay, 0.0, 1.0)
    return lerp(pitch_start, pitch_end, t * t)  # Exponential curve

# PWM (pulse width modulation)
func get_pwm_value(phase: float, pw: float) -> float:
    return 1.0 if phase < pw else -1.0
```

---

*Reference compiled for AdaResearch procedural audio system.*
