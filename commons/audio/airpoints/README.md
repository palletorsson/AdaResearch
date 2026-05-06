# Air Points Audio System
**Systems Music for XR - Inspired by Teropa's JavaScript Systems Music (2016)**

## 🎵 Overview

The Air Points Audio System generates procedural music from moving points in 3D space, following the principles of **Systems Music** pioneered by Steve Reich and Brian Eno. All sounds are **100% synthesized** - no audio samples are used.

This implementation is based on [Teropa's JavaScript Systems Music guide](https://teropa.info/blog/2016/07/28/javascript-systems-music.html), specifically the **Discreet Music** (1975) synthesis approach.

---

## 🏗️ Architecture

### Signal Flow
```
Air Points (3D Space)
    ↓
AirPointListener (Node3D)
    ↓ (modulation signals)
AirPointSynth (AudioStreamPlayer)
    ↓
Audio Bus → Master
```

### Components

#### 1. **AirPointListener.gd**
Tracks spatial data from Air Points:
- **Position** → Distance, Direction
- **Velocity** → Speed, Acceleration  
- **Outputs**: Modulation parameters at 60 Hz

#### 2. **AirPointSynth.gd** (Teropa-Style DuoSynth)
Dual-oscillator synthesizer:
- **Voice 1**: Sawtooth wave (harmonically rich)
- **Voice 2**: Sine wave (pure fundamental)
- **Low-Pass Filter**: 200 Hz base, 2 octaves range
- **ADSR Envelope**: Attack 0.1s, Release 4s (linear)
- **Vibrato LFO**: 0.5 Hz rate, 0.1 depth
- **Stereo Panning**: Based on X position

#### 3. **AirPointOscillator.gd** (Simple Mode)
Basic oscillator for comparison:
- Single waveform (Sine/Triangle/Sawtooth/Square)
- Distance → Frequency mapping
- Proximity → Amplitude mapping

---

## 🎹 Synthesis Details

### Teropa's Discreet Music Approach

Our implementation follows Brian Eno's **Discreet Music** (1975) synthesis:

```gdscript
# Voice 1: Sawtooth (harmonically rich)
sawtooth = 2.0 * (phase - floor(phase)) - 1.0

# Voice 2: Sine (pure tone)
sine = sin(phase * TAU)

# Mix voices (0 = all sawtooth, 1 = all sine)
mixed = lerp(sawtooth, sine, voice_mix)

# Low-pass filter (warm synth washes)
filter_cutoff = 200 Hz * 2^(2 octaves) = ~800 Hz

# ADSR Envelope
attack: 0.1s   # Soft fade-in
release: 4.0s  # Long fade-out (linear curve)

# Vibrato (pitch modulation)
vibrato = sin(lfo_phase * TAU) * 0.1
frequency = base_frequency * (1.0 + vibrato)
```

### Parameter Mapping

| Air Point Property | → | Audio Parameter |
|-------------------|---|-----------------|
| `distance` | → | Frequency (880-110 Hz, inverse) |
| `proximity_factor` | → | Amplitude (0-0.7) |
| `position.x` | → | Stereo Pan (-1 to 1) |
| `position.y` | → | Filter Cutoff (±200 Hz) |
| `velocity.length()` | → | Vibrato Rate (0.3-0.8 Hz) |
| `direction_vector.y` | → | Harmonicity (0.8-1.2) |

---

## 🎮 Test Scenes

### AirPointSynthTest.tscn
**Teropa-style DuoSynth test**

**Controls:**
- **Arrow Keys**: Move Air Point (X/Z plane)
- **Q/E**: Move Air Point (Y axis)
- **Space**: Reset to starting position
- **V**: Toggle voice mix (Sawtooth ↔ Mixed ↔ Sine)
- **H**: Cycle harmonicity (1.0, 1.5, 2.0, 0.5, 1.25)
- **+/-**: Adjust movement speed

**What to Listen For:**
- **Distance**: Pitch changes (far = low, close = high)
- **Movement**: Vibrato rate modulates with speed
- **Vertical Position**: Filter cutoff shifts timbre
- **Horizontal Position**: Stereo panning follows X axis
- **Voice Mix**: Sawtooth = bright, Sine = pure, Mixed = warm

### AirPointAudioTest.tscn
**Simple oscillator test (comparison)**

**Controls:**
- **Arrow Keys**: Move Air Point
- **1-4**: Change waveform (Sine, Triangle, Sawtooth, Square)
- **Space**: Reset position

---

## 🎼 Systems Music Principles

Following Teropa's implementation of Reich and Eno's techniques:

### 1. **Minimal Rules, Emergent Complexity**
- Simple spatial relationships drive all parameters
- Complex musical patterns emerge from movement
- No pre-composed melodies

### 2. **No Central Clock**
- Each Air Point operates independently
- Timing determined by spatial relationships
- Phasing creates evolving patterns

### 3. **Continuous Modulation**
- All parameters smoothly interpolated
- No discrete events (except note triggers)
- Movement creates timbral evolution

### 4. **Generative Duration**
- System can run indefinitely
- Patterns never exactly repeat
- Emergent musical structures

---

## 🔧 Technical Implementation

### Real-Time Synthesis
All audio is generated in real-time using Godot's `AudioStreamGenerator`:

```gdscript
const SAMPLE_RATE = 44100
const BUFFER_SIZE = 2048

func _fill_buffer():
    for i in range(frames_to_fill):
        var sample = _generate_sample()
        _playback.push_frame(Vector2(sample, sample))
```

### Smooth Parameter Transitions
Exponential moving average prevents clicks:

```gdscript
var smoothing = 0.95
_current_frequency = lerp(_current_frequency, _target_frequency, 1.0 - smoothing)
```

### Low-Pass Filter
Simple one-pole filter for warm tones:

```gdscript
var alpha = (cutoff_hz / SAMPLE_RATE) * TAU
_filter_state = _filter_state + alpha * (input - _filter_state)
```

### ADSR Envelope
Linear release curve (as per Teropa):

```gdscript
# Attack phase
_envelope_value = _envelope_time / attack_time

# Release phase (linear)
_envelope_value = sustain_level * (1.0 - release_progress)
```

---

## 📊 Performance

- **Sample Rate**: 44,100 Hz
- **Buffer Size**: 2,048 samples (~46ms latency)
- **Update Rate**: 60 Hz (modulation parameters)
- **CPU Usage**: ~2-5% per synth instance (single core)

---

## 🚀 Future Enhancements (Phase 3+)

### Phasing Loop System
Multiple Air Points with different loop durations:
- Left loop: 34 measures (~68 seconds)
- Right loop: 37 measures (~74 seconds)
- Creates ~41 minutes of unique music before sync

### Melodic Phrases
7 pre-defined phrases (like Teropa's implementation):
1. C5 → D5 (1:2 duration)
2. D5 → C5 (1:0 duration)
3. F5 (0:2 duration)
4. E5 → D5 (1:2 duration)
5. G5 (0:2 duration)
6. F5 → E5 (1:2 duration)
7. A5 → G5 (1:2 duration)

### Echo/Delay Effect
Tape delay (Frippertronics-style):
- Delay time: 3-5 seconds
- Feedback: 0.6-0.7
- Modulated by Air Point movement

### Granular Synthesis
Velocity-based grain generation:
- Grain density: map(speed, 0-5, 1-50 grains/sec)
- Grain pitch: map(direction.y, -1 to 1, -12 to +12 semitones)

### Spatial Harmonizer
Harmonic series based on Air Point count:
- Each point = one harmonic
- Amplitude per harmonic: inverse distance
- Creates rich, evolving chords

---

## 📚 References

1. **Teropa's JavaScript Systems Music** (2016)
   - https://teropa.info/blog/2016/07/28/javascript-systems-music.html
   - Comprehensive guide to implementing Reich and Eno's techniques

2. **Brian Eno - Discreet Music** (1975)
   - EMS Synthi AKS synthesizer
   - Generative ambient music pioneer

3. **Steve Reich - It's Gonna Rain** (1965)
   - Phase music technique
   - Tape loop phasing

4. **Web Audio API**
   - OscillatorNode, BiquadFilterNode
   - Tone.js library (MonoSynth, DuoSynth)

---

## 🎯 IACP Protocol Status

**Agent A (Sound Architect)**: Architecture designed ✅  
**Agent B (Synthesis Engineer)**: Phase 1 & 2 implemented ✅

**Completed Tasks:**
- ✅ Task 019: Define Audio System Architecture
- ✅ Task 020: Implement AirPoint Listener Node
- ✅ Task 021: Prototype Sound Generator (Simple Oscillator)
- ✅ Task 023: Create AirPointSynth (DuoSynth-style)

**Pending Tasks:**
- ⏳ Task 024: Phasing Loop System
- ⏳ Task 025: Echo/Delay Effect

---

## 🎨 Creative Applications

This system enables:
- **Interactive XR Music**: Hand/controller movements create music
- **Spatial Composition**: Choreograph sound in 3D space
- **Generative Soundscapes**: Autonomous musical agents
- **Educational Tools**: Visualize synthesis and spatial audio
- **Performance Instruments**: Real-time expressive control

---

**All sounds are synthesized. No samples. Pure procedural audio.**

*Inspired by the pioneers of systems music and generative composition.*
