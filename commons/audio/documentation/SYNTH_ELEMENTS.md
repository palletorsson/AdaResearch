# Synth Elements - Deep Technical Reference

This document covers the actual circuit behavior and synthesis techniques for each sound element.
Used by AdaResearch's procedural audio system to create authentic sounds.

---

## TB-303 Bass Line

### Overview
The Roland TB-303 Bass Line (1982) is a monophonic bass synthesizer with a unique sound caused by:
- Single VCO (sawtooth or square wave)
- 18dB/octave lowpass filter (3-pole, not 4-pole like Moog)
- Diode ladder filter design with soft clipping
- Decay-only envelope on filter (no attack)
- Accent circuit that boosts envelope AND resonance
- Slide (portamento) with specific time constant

### Circuit Details

#### VCO Section
- **Waveforms**: Sawtooth or Square (selectable)
- **Frequency Range**: 32.7 Hz - 523.2 Hz (approximately)
- **Tuning**: ±1 octave via tune knob
- **CV Response**: 1V/octave (not perfectly linear)

#### VCF Section (The Soul of the 303)
- **Filter Type**: 3-pole (18dB/octave) lowpass
- **Topology**: Diode ladder (not transistor)
- **Cutoff Range**: ~60 Hz to ~2.5 kHz
- **Resonance**: Can self-oscillate above ~75%
- **Unique Behavior**: At high resonance, the filter "screams" - the diodes soft-clip

```
Filter response:
                 ___________
                /           \ ← Resonance peak
               /             \
______________/               \________________
             fc               
             ↑
        Cutoff freq (18dB/oct rolloff)
```

#### Envelope Section
- **Type**: Decay-only (triggered by gate)
- **Decay Time**: ~30ms to ~3s
- **Envelope Mod**: Controls how much envelope affects filter cutoff
- **Accent Effect**: Shorter decay, higher peak, increased resonance

#### Accent Behavior
When accent is triggered:
1. Filter envelope amount increases by ~30-50%
2. Filter resonance increases by ~20-30%
3. Decay time shortens by ~50%
4. VCA level increases by ~20%

```gdscript
# 303 Accent implementation
func apply_accent(base_env_mod: float, base_resonance: float, base_decay: float) -> Dictionary:
    return {
        "env_mod": base_env_mod * 1.4,      # 40% boost
        "resonance": base_resonance + 0.25,  # Absolute boost
        "decay": base_decay * 0.5,           # Half the decay time
        "vca_boost": 1.2                     # 20% louder
    }
```

#### Slide (Portamento)
- **Time Constant**: ~60ms (fixed in original)
- **Behavior**: Exponential glide between notes
- **Triggered By**: Slide switch per step in sequencer

```gdscript
# 303 Slide implementation
var slide_time = 0.06  # 60ms
var current_freq = 0.0
var target_freq = 0.0

func update_slide(delta: float):
    var slide_factor = 1.0 - exp(-delta / slide_time)
    current_freq = lerp(current_freq, target_freq, slide_factor)
```

### Implementation Parameters

| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| `waveform` | saw/square | saw | VCO waveform |
| `tuning` | -12..+12 | 0 | Semitones |
| `cutoff` | 60..2500 | 400 | Filter cutoff Hz |
| `resonance` | 0..1 | 0.5 | Filter resonance (0.85+ = screaming) |
| `env_mod` | 0..1 | 0.6 | Envelope to cutoff amount |
| `decay` | 0.03..3 | 0.3 | Envelope decay time |
| `accent` | 0..1 | 0.5 | Accent intensity |
| `slide_time` | 0.03..0.2 | 0.06 | Portamento time |
| `distortion` | 0..1 | 0.2 | Diode soft-clipping amount |

### Acid Line Formulas

**Rule 1: Accent + Slide + Octave Jump = Maximum Squelch**
```
Step:   1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16
Note:   C2 -  C2 C3 C2 -  C2 C2 C3 -  C2 C2 C2 C3 -  C2
Slide:  -  -  -  ↗  -  -  -  -  ↗  -  -  -  -  ↗  -  -
Accent: ●  -  -  ●  ●  -  -  ●  -  -  ●  -  -  -  ●  -
```

---

## TR-909 Kick Drum

### Overview
The Roland TR-909 (1984) kick uses a hybrid analog/digital design:
- Analog VCO for the body
- Analog VCA for envelope
- Simple pitch envelope for the "punch"

### Circuit Details

#### Body Generation
- **Oscillator**: Bridged-T network (similar to sine)
- **Base Frequency**: ~50-60 Hz
- **Pitch Envelope**: Starts ~150-200 Hz, drops to base in ~20ms

```gdscript
# 909 Kick pitch envelope
var pitch_start = 150.0  # Hz
var pitch_end = 55.0     # Hz  
var pitch_decay = 0.02   # seconds

func get_pitch(t: float) -> float:
    var env = exp(-t / pitch_decay)
    return pitch_end + (pitch_start - pitch_end) * env
```

#### Attack Click
- **Source**: Short burst of high-frequency content
- **Frequency**: ~2-6 kHz
- **Duration**: ~2-5 ms
- **Mix**: ~10-20% of total

#### Amplitude Envelope
- **Attack**: Instant (~0.5ms)
- **Decay**: Adjustable ~100ms - 500ms
- **Shape**: Exponential decay

### Implementation Parameters

| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| `tune` | 40..100 | 55 | Base pitch Hz |
| `pitch_start` | 100..300 | 150 | Pitch envelope start |
| `pitch_decay` | 0.01..0.05 | 0.02 | Pitch envelope time |
| `attack_level` | 0..1 | 0.3 | Click attack amount |
| `attack_freq` | 2000..6000 | 3000 | Click frequency |
| `decay` | 0.1..0.5 | 0.25 | Amplitude decay |
| `punch` | 0..1 | 0.5 | Overall punch (compresses transient) |

---

## TR-909 Snare Drum

### Overview
The 909 snare combines analog tone generation with sampled noise.

### Circuit Details

#### Body (Tone)
- **Oscillators**: Two bridged-T oscillators
- **Frequencies**: ~180 Hz and ~330 Hz
- **Mix**: Adjustable via Tone knob

#### Snares (Noise)
- **Source**: 6-bit sample (stored in EPROM)
- **Character**: Band-limited white noise
- **Filter**: Highpass ~500 Hz, lowpass ~8 kHz

#### Envelope
- **Tone Decay**: ~50-150ms
- **Snare Decay**: ~100-300ms (longer than tone)

### Implementation Parameters

| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| `tune` | 150..300 | 200 | Body frequency |
| `tone` | 0..1 | 0.5 | Tone vs noise balance |
| `snappy` | 0..1 | 0.5 | Snare decay/brightness |
| `tone_decay` | 0.03..0.2 | 0.08 | Tone envelope |
| `noise_decay` | 0.05..0.3 | 0.15 | Noise envelope |

---

## TR-909 Hi-Hats

### Overview
The 909 hi-hats use a mix of metallic square wave oscillators.

### Circuit Details

#### Metallic Tone
- **Oscillators**: 6 square waves at non-harmonic ratios
- **Frequencies**: 204, 298, 366, 522, 540, 598 Hz (approximate)
- **Combined**: Creates inharmonic "metallic" timbre

```gdscript
# 909 metallic hi-hat oscillators
var hat_freqs = [204.0, 298.0, 366.0, 522.0, 540.0, 598.0]

func generate_metallic(t: float) -> float:
    var output = 0.0
    for freq in hat_freqs:
        output += sign(sin(2.0 * PI * freq * t))  # Square wave
    return output / 6.0
```

#### High-Pass Filter
- **Cutoff**: ~8 kHz (adjustable in some models)
- **Type**: Simple RC high-pass

#### Envelope
- **Closed Hat**: ~20-80ms decay
- **Open Hat**: ~200-800ms decay

### Implementation Parameters

| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| `decay` | 0.02..0.8 | 0.05 | Envelope decay (closed=short, open=long) |
| `tone` | 6000..16000 | 10000 | High-pass cutoff Hz |
| `metallic` | 0..1 | 0.7 | Square wave vs noise mix |

---

## TR-808 Kick Drum

### Overview
The TR-808 (1980) kick has a distinctive "boom" - deeper and longer than the 909.

### Circuit Details

#### Oscillator
- **Type**: Bridged-T oscillator (sine-like)
- **Frequency**: ~40-60 Hz
- **Pitch Envelope**: Drops from ~150 Hz very quickly

#### Characteristics
- **Long Decay**: Can sustain ~1-2 seconds
- **Sub Bass**: Strong fundamental with few harmonics
- **Click**: Minimal compared to 909

### Implementation Parameters

| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| `tune` | 30..80 | 50 | Base frequency |
| `decay` | 0.2..2.0 | 0.8 | Long decay time |
| `tone` | 0..1 | 0.5 | Brightness (affects harmonics) |
| `click` | 0..1 | 0.1 | Attack click amount |

---

## Minimoog Bass

### Overview
The Minimoog (1970) bass sound comes from:
- 3 oscillators (detuned for thickness)
- 24dB/octave transistor ladder filter
- Warm saturation throughout signal path

### Circuit Details

#### Oscillators
- **Count**: 3 VCOs
- **Waveforms**: Sawtooth, Triangle, Square (selectable per osc)
- **Detuning**: Oscillators naturally drift ~1-5 cents
- **Sub Oscillator**: OSC 3 often set -1 octave

```gdscript
# Minimoog oscillator detuning
var osc_detunes = [1.0, 0.998, 1.003]  # Slight detune
var osc_octaves = [0, 0, -1]  # OSC 3 is sub
```

#### Filter (24dB Ladder)
- **Type**: 4-pole lowpass (24dB/octave)
- **Topology**: Transistor ladder
- **Resonance**: Can self-oscillate
- **Character**: "Creamy", round bottom end

#### Unique Characteristics
- **Warmth**: Transistor saturation throughout
- **Drift**: Oscillators slowly drift (adds life)
- **Key Tracking**: Filter follows pitch

### Implementation Parameters

| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| `osc1_level` | 0..1 | 0.8 | Oscillator 1 volume |
| `osc2_level` | 0..1 | 0.7 | Oscillator 2 volume |
| `osc3_level` | 0..1 | 0.6 | Oscillator 3 (sub) volume |
| `osc2_detune` | -0.05..0.05 | 0.003 | OSC 2 detune ratio |
| `osc3_detune` | -0.05..0.05 | -0.002 | OSC 3 detune ratio |
| `cutoff` | 50..8000 | 800 | Filter cutoff |
| `resonance` | 0..1 | 0.3 | Filter resonance |
| `env_amount` | 0..1 | 0.5 | Filter envelope amount |
| `attack` | 0.001..2 | 0.01 | Amp attack |
| `decay` | 0.01..3 | 0.3 | Amp decay |
| `sustain` | 0..1 | 0.7 | Amp sustain |
| `release` | 0.01..5 | 0.5 | Amp release |
| `saturation` | 0..1 | 0.3 | Tube-like saturation |
| `drift` | 0..1 | 0.1 | Oscillator drift amount |

---

## Juno-106 Chorus Pad

### Overview
The Roland Juno-106 (1984) is famous for its lush chorus pad sounds:
- Single DCO per voice (digitally controlled oscillator)
- 24dB lowpass filter
- Built-in BBD (bucket brigade) chorus

### Chorus Circuit
The Juno chorus uses two BBD (bucket brigade delay) lines with LFO modulation:
- **Chorus I**: Single BBD, subtle
- **Chorus II**: Single BBD, deeper modulation
- **Chorus I+II**: Both BBDs, maximum width

```gdscript
# Juno-106 style BBD chorus
func juno_chorus(input: float, t: float, mode: int) -> float:
    var lfo1 = sin(2.0 * PI * 0.5 * t)  # ~0.5 Hz
    var lfo2 = sin(2.0 * PI * 0.8 * t)  # ~0.8 Hz (slightly different)
    
    var delay1 = 0.003 + lfo1 * 0.002  # 1-5ms modulated delay
    var delay2 = 0.004 + lfo2 * 0.002
    
    match mode:
        1:  # Chorus I
            return (input + delay_line(input, delay1)) * 0.5
        2:  # Chorus II
            return (input + delay_line(input, delay2)) * 0.5
        3:  # Chorus I+II
            return (input + delay_line(input, delay1) + delay_line(input, delay2)) / 3.0
    return input
```

### Implementation Parameters

| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| `osc_waveform` | saw/pulse/both | saw | Oscillator waveform |
| `pulse_width` | 0..1 | 0.5 | PWM width |
| `pwm_rate` | 0..10 | 0.5 | PWM LFO rate |
| `sub_osc` | 0..1 | 0.3 | Sub oscillator level |
| `cutoff` | 50..8000 | 2000 | Filter cutoff |
| `resonance` | 0..1 | 0.2 | Filter resonance |
| `env_amount` | 0..1 | 0.3 | Filter envelope |
| `chorus_mode` | 0/1/2/3 | 3 | Off/I/II/I+II |
| `chorus_depth` | 0..1 | 0.5 | Modulation depth |

---

## DX7 FM Electric Piano

### Overview
The Yamaha DX7 (1983) FM synthesis creates complex timbres through frequency modulation.
The famous "E.Piano 1" patch uses specific operator ratios.

### FM Fundamentals

```
Modulator (M) ──┐
                ├──► Carrier (C) ──► Output
                │
    M modulates C's frequency
    
Result: Carrier + sidebands at C ± M, C ± 2M, C ± 3M, etc.
```

#### E.Piano 1 Algorithm
- **6 operators** in specific configuration
- **Algorithm 5**: Operators 1-2 stacked, 3-4 stacked, 5-6 parallel

Simplified 2-operator version:
```gdscript
func fm_epiano(t: float, freq: float) -> float:
    var mod_ratio = 1.0    # Modulator at same frequency
    var mod_index = 3.5    # Modulation depth
    
    # Modulator envelope (fast decay for "tine" attack)
    var mod_env = exp(-t * 15.0)
    
    # Carrier envelope (longer for sustain)
    var car_env = exp(-t * 2.0) * 0.7 + 0.3 * exp(-t * 0.5)
    
    # FM synthesis
    var modulator = sin(2.0 * PI * freq * mod_ratio * t) * mod_index * mod_env
    var carrier = sin(2.0 * PI * freq * t + modulator)
    
    return carrier * car_env
```

### Implementation Parameters

| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| `mod_ratio` | 0.5..8 | 1.0 | Modulator frequency ratio |
| `mod_index` | 0..10 | 3.5 | FM modulation depth |
| `mod_decay` | 0.5..30 | 15 | Modulator envelope decay rate |
| `car_decay` | 0.5..10 | 2 | Carrier envelope decay rate |
| `brightness` | 0..1 | 0.5 | Overall brightness (affects mod_index) |
| `velocity_sens` | 0..1 | 0.7 | Velocity to mod_index sensitivity |

---

## Hoover / Rave Stab

### Overview
The "Hoover" sound (named after the vacuum cleaner) originated from the Roland Alpha Juno / Korg M1.
Used extensively in rave/hardcore music (1990s).

### Characteristics
- Sawtooth + PWM oscillators
- Heavy portamento (slide)
- Resonant filter sweep
- Often layered with detuned copies

### Implementation

```gdscript
func hoover_stab(t: float, freq: float) -> float:
    # Multiple detuned sawtooths
    var saw1 = sawtooth(freq * 0.995 * t)
    var saw2 = sawtooth(freq * 1.0 * t)
    var saw3 = sawtooth(freq * 1.005 * t)
    
    # PWM oscillator
    var pwm_width = 0.3 + sin(t * 4.0) * 0.2
    var pulse = sign(sin(2.0 * PI * freq * t) - (pwm_width * 2 - 1))
    
    # Mix
    var osc_mix = (saw1 + saw2 + saw3) * 0.25 + pulse * 0.25
    
    # Resonant filter with sweep
    var filter_env = exp(-t * 3.0)
    var cutoff = 500 + filter_env * 3000
    var filtered = lowpass_resonant(osc_mix, cutoff, 0.7)
    
    return tanh(filtered * 1.5)  # Soft saturation
```

### Implementation Parameters

| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| `voices` | 1..5 | 3 | Number of detuned voices |
| `detune` | 0..0.02 | 0.005 | Detune spread |
| `pwm_depth` | 0..0.4 | 0.2 | Pulse width modulation |
| `pwm_rate` | 1..10 | 4 | PWM LFO rate |
| `portamento` | 0..0.5 | 0.1 | Slide time |
| `cutoff` | 200..4000 | 500 | Base filter cutoff |
| `filter_env` | 0..1 | 0.8 | Filter envelope amount |
| `resonance` | 0..1 | 0.7 | Filter resonance |
| `saturation` | 0..1 | 0.5 | Output saturation |

---

## Supersaw (JP-8000 Style)

### Overview
The Roland JP-8000 (1996) introduced the "Supersaw" - 7 detuned sawtooth oscillators.

### Implementation

```gdscript
const SUPERSAW_VOICES = 7
const SUPERSAW_DETUNE_SPREAD = [-0.11, -0.06, -0.02, 0.0, 0.02, 0.06, 0.11]
const SUPERSAW_LEVELS = [0.5, 0.7, 0.9, 1.0, 0.9, 0.7, 0.5]  # Center loudest

func supersaw(t: float, freq: float, detune_amount: float = 1.0) -> float:
    var output = 0.0
    for i in range(SUPERSAW_VOICES):
        var detune = 1.0 + SUPERSAW_DETUNE_SPREAD[i] * detune_amount * 0.1
        var level = SUPERSAW_LEVELS[i]
        output += sawtooth(freq * detune * t) * level
    return output / SUPERSAW_VOICES
```

### Implementation Parameters

| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| `voices` | 1..7 | 7 | Number of voices |
| `detune` | 0..1 | 0.5 | Detune spread amount |
| `mix` | 0..1 | 0.5 | Center vs side voices balance |

---

## Effects

### Chorus (BBD Style)

```gdscript
class BBDChorus:
    var buffer: PackedFloat32Array
    var write_pos: int = 0
    var lfo_phase: float = 0.0
    
    func process(input: float, rate: float, depth: float, mix: float) -> float:
        # LFO for modulation
        lfo_phase += rate / SAMPLE_RATE
        var lfo = sin(2.0 * PI * lfo_phase)
        
        # Variable delay (1-10ms typical)
        var delay_ms = 5.0 + lfo * depth * 4.0
        var delay_samples = int(delay_ms * SAMPLE_RATE / 1000.0)
        
        # Read from delay line
        var read_pos = (write_pos - delay_samples + buffer.size()) % buffer.size()
        var delayed = buffer[read_pos]
        
        # Write to delay line
        buffer[write_pos] = input
        write_pos = (write_pos + 1) % buffer.size()
        
        return input * (1 - mix) + delayed * mix
```

### Reverb (Schroeder Algorithm)

```gdscript
# Simple Schroeder reverb with 4 comb filters + 2 allpass
const COMB_DELAYS = [1557, 1617, 1491, 1422]  # samples at 44.1kHz
const ALLPASS_DELAYS = [225, 556]

func reverb(input: float, decay: float) -> float:
    var comb_out = 0.0
    for i in range(4):
        comb_out += comb_filter(input, COMB_DELAYS[i], decay)
    comb_out /= 4.0
    
    var output = comb_out
    for delay in ALLPASS_DELAYS:
        output = allpass_filter(output, delay, 0.5)
    
    return output
```

### Distortion Types

```gdscript
# Soft clipping (tube-like)
func soft_clip(x: float, drive: float) -> float:
    return tanh(x * (1.0 + drive * 3.0))

# Hard clipping (transistor-like)
func hard_clip(x: float, threshold: float) -> float:
    return clamp(x, -threshold, threshold)

# Diode clipping (303-style)
func diode_clip(x: float) -> float:
    # Asymmetric soft clipping
    if x > 0:
        return 1.0 - exp(-x)
    else:
        return -1.0 + exp(x)

# Bitcrusher
func bitcrush(x: float, bits: int) -> float:
    var levels = pow(2, bits)
    return floor(x * levels) / levels
```

---

## Filter Implementations

### 1-Pole Lowpass (6dB/octave)
```gdscript
var lp_z1 = 0.0

func lowpass_1pole(input: float, cutoff: float) -> float:
    var w = tan(PI * cutoff / SAMPLE_RATE)
    var a = w / (1.0 + w)
    var output = a * input + a * lp_z1 + (1 - 2*a) * lp_z1
    lp_z1 = output
    return output
```

### Moog Ladder (24dB/octave)
```gdscript
var moog_stage = [0.0, 0.0, 0.0, 0.0]

func moog_ladder(input: float, cutoff: float, resonance: float) -> float:
    var f = cutoff / SAMPLE_RATE
    var k = resonance * 4.0  # 0-4 range
    
    # Feedback
    var feedback = k * moog_stage[3]
    var x = input - feedback
    x = tanh(x)  # Soft clip
    
    # 4 cascaded 1-pole filters
    for i in range(4):
        moog_stage[i] += f * (x - moog_stage[i])
        x = moog_stage[i]
    
    return moog_stage[3]
```

### State Variable Filter (12dB, multimode)
```gdscript
var svf_low = 0.0
var svf_band = 0.0

func svf_filter(input: float, cutoff: float, resonance: float) -> Dictionary:
    var f = 2.0 * sin(PI * cutoff / SAMPLE_RATE)
    var q = 1.0 / resonance
    
    var high = input - svf_low - q * svf_band
    svf_band += f * high
    svf_low += f * svf_band
    var notch = high + svf_low
    
    return {
        "lowpass": svf_low,
        "highpass": high,
        "bandpass": svf_band,
        "notch": notch
    }
```

---

## Envelope Generators

### ADSR
```gdscript
enum EnvStage { ATTACK, DECAY, SUSTAIN, RELEASE, IDLE }

class ADSR:
    var stage = EnvStage.IDLE
    var level = 0.0
    var attack = 0.01
    var decay = 0.1
    var sustain = 0.7
    var release = 0.3
    
    func trigger():
        stage = EnvStage.ATTACK
        
    func release_note():
        stage = EnvStage.RELEASE
        
    func process(delta: float) -> float:
        match stage:
            EnvStage.ATTACK:
                level += delta / attack
                if level >= 1.0:
                    level = 1.0
                    stage = EnvStage.DECAY
            EnvStage.DECAY:
                level -= delta / decay * (1.0 - sustain)
                if level <= sustain:
                    level = sustain
                    stage = EnvStage.SUSTAIN
            EnvStage.SUSTAIN:
                level = sustain
            EnvStage.RELEASE:
                level -= delta / release * level
                if level <= 0.001:
                    level = 0.0
                    stage = EnvStage.IDLE
        return level
```

### AR (Attack-Release only, for 303)
```gdscript
func ar_envelope(t: float, decay: float, accent: bool = false) -> float:
    var d = decay * (0.5 if accent else 1.0)
    return exp(-t / d)
```

---

*Last Updated: 2026-02-03*
