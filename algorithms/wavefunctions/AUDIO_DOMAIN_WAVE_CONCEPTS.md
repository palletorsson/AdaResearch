# Wave Concepts in the Audio Domain
## Interactive, Educational, and Musically Useful Demonstrations

This document maps the wave function concepts from the tutorials to **interactive audio demonstrations** that are:
1. **Audibly educational** - You hear the concept, not just see it
2. **Musically useful** - Sounds good enough for game audio
3. **Interactive** - Uses sliders, joysticks, wheels from `interactables/`
4. **Parameter-based** - Can save to JSON for reuse in game

---

## ✅ **Implemented Audio Demonstrations**

### 1. **Beat Frequencies** 🎵
**Location:** `algorithms/wavefunctions/beat_frequencies/BeatFrequencies.gd`

**Concept:** Interference between close frequencies creates periodic amplitude modulation (beats)

**Audio Manifestation:**
- Two sine waves at 440 Hz and 442 Hz → hear 2 beats per second (wah-wah-wah)
- Beat frequency = |f1 - f2|
- When frequencies match → beats disappear (perfect tuning)

**Interactive Controls:**
- **Slider 1:** Frequency 1 (400-500 Hz)
- **Slider 2:** Frequency 2 (400-500 Hz)
- **Push Button:** Toggle sound on/off

**Visual Feedback:**
- Red wave (frequency 1)
- Blue wave (frequency 2)
- Yellow combined wave (shows interference)
- Green envelope bars (show beat pattern)
- Real-time beat frequency display

**Musical Use Cases:**
- **Tuning instruments** - When beats slow, you're in tune
- **Chorus effect** - Slight detuning creates richness
- **Vibrato** - Periodic pitch modulation
- **Game audio:** Eerie drone sounds, sci-fi effects, tension music

**Saves to:** `commons/audio/parameters/educational/beat_frequencies.json`

---

### 2. **Harmonic Series Builder** 🎹
**Location:** `algorithms/wavefunctions/harmonic_builder/HarmonicBuilder.gd`

**Concept:** ANY periodic sound = sum of sine waves at integer multiples of fundamental (Fourier synthesis)

**Audio Manifestation:**
- Fundamental (220 Hz) = base pitch
- 2nd harmonic (440 Hz) = octave above
- 3rd harmonic (660 Hz) = perfect fifth
- Different harmonic balances = different timbres (flute vs brass vs clarinet)

**Interactive Controls:**
- **8 Vertical Sliders:** Amplitude of each harmonic (1× through 8×)
- **Wheel:** Change fundamental frequency (110-880 Hz)
- **8 Preset Buttons:**
  - Sine (pure tone)
  - Square wave (hollow, video game sound)
  - Sawtooth (bright, buzzy)
  - Triangle (mellow)
  - Organ (rich harmonics)
  - Clarinet (odd harmonics only)
  - Brass (strong harmonics, bright)
  - Flute (weak harmonics, pure)

**Visual Feedback:**
- 8 colored bars showing harmonic amplitudes
- Waveform display showing resulting wave shape
- Frequency and note name display (e.g., "220.0 Hz (A3)")

**Musical Use Cases:**
- **Additive synthesis** - Build custom instrument sounds
- **Understanding timbre** - Why instruments sound different
- **Sound design** - Create unique tones for game
- **Game audio:** Synth leads, bass, pads, effects

**Saves to:** `commons/audio/parameters/educational/harmonic_builder.json`

---

### 3. **Mario Sound Controller** (Existing)
**Location:** `algorithms/wavefunctions/mariocontrol/MarioSoundController.gd`

**Concept:** Frequency sweep with exponential decay (rising pitch + fading)

**Audio Manifestation:**
- Start frequency → End frequency (pitch rises)
- Exponential decay (volume fades)
- Square wave (retro 8-bit sound)

**Interactive Controls:**
- **3D Ball (ValueMapper3D):**
  - X axis: Start frequency
  - Y axis: End frequency
  - Z axis: Decay rate

**Musical Use Cases:**
- **Pickup sounds** - Coins, items, power-ups
- **UI feedback** - Button clicks, notifications
- **Game audio:** Retro game effects

**Already working!** ✓

---

## 🎯 **High-Priority Audio Implementations**

### 4. **Doppler Effect** 🚁
**Concept:** Moving sound source → frequency shift

**Implementation Plan:**
```gdscript
# Use joystick to control object velocity
# Left/Right = approach/recede
# Hear pitch rise when approaching, fall when receding

# Interactive Controls:
# - Joystick: Object velocity (-50 to +50 m/s)
# - Slider: Source frequency (200-1000 Hz)
# - Button: Toggle motion

# Formula: f_observed = f_source × (v_sound / (v_sound - v_source))
# Where v_sound = 343 m/s (speed of sound)
```

**Audio Example:**
- Ambulance siren at 800 Hz
- Approaching at 30 m/s → sounds like ~870 Hz (higher)
- Receding at 30 m/s → sounds like ~740 Hz (lower)

**Musical Use Cases:**
- **Fly-by effects** - Spaceships, cars, projectiles
- **Dynamic environments** - Moving sound sources
- **Game audio:** Racing games, aerial combat, passing objects

---

### 5. **Resonance & Filter Sweeps** 🔊
**Concept:** Resonant frequency emphasis (filter peak)

**Implementation Plan:**
```gdscript
# Use slider to sweep filter cutoff frequency
# Hear different harmonics emphasized as filter moves

# Interactive Controls:
# - Slider 1: Filter cutoff frequency (100-5000 Hz)
# - Slider 2: Resonance/Q factor (0.5-20)
# - Wheel: Source signal type (sawtooth/square/noise)
# - Button: Bypass filter

# This is how synthesizer filters work
```

**Audio Example:**
- White noise through resonant filter
- Sweep cutoff from 100 Hz → 5000 Hz
- Hear pitch-like quality emerge from noise
- High resonance → whistling, singing quality

**Musical Use Cases:**
- **Filter sweeps** - Classic synth sound (TB-303 acid bass)
- **Formant synthesis** - Vowel sounds (ah, ee, oo)
- **Sound design** - Evolving textures
- **Game audio:** Synth bass, leads, sci-fi effects

---

### 6. **AM (Amplitude Modulation) Synthesis** 📡
**Concept:** One wave modulates amplitude of another (creates sidebands)

**Implementation Plan:**
```gdscript
# Carrier frequency modulated by modulator frequency
# Creates sum and difference frequencies (sidebands)

# Interactive Controls:
# - Slider 1: Carrier frequency (200-1000 Hz)
# - Slider 2: Modulator frequency (0.1-500 Hz)
# - Slider 3: Modulation depth (0-100%)

# Low modulator freq (< 20 Hz) = tremolo (vibrato of volume)
# High modulator freq (> 20 Hz) = new frequencies (bell-like tones)
```

**Audio Example:**
- Carrier: 440 Hz
- Modulator: 100 Hz
- Result: Hear 440 Hz, 340 Hz (440-100), 540 Hz (440+100)
- Creates metallic, bell-like timbres

**Musical Use Cases:**
- **Bell sounds** - Church bells, chimes
- **Tremolo** - Amplitude vibrato
- **Metallic tones** - Synth sounds, SFX
- **Game audio:** Bells, alarms, robotic voices

---

### 7. **FM (Frequency Modulation) Synthesis** 🎛️
**Concept:** One wave modulates frequency of another (Yamaha DX7 technique)

**Implementation Plan:**
```gdscript
# One oscillator (modulator) changes pitch of another (carrier)
# Creates complex harmonics impossible with additive synthesis

# Interactive Controls:
# - Slider 1: Carrier frequency
# - Slider 2: Modulator frequency (C:M ratio)
# - Slider 3: Modulation index (amount of modulation)
# - Wheel: Algorithm (different routing topologies)

# Famous for electric piano, bass, bells
```

**Audio Example:**
- Carrier: 220 Hz
- Modulator: 220 Hz (1:1 ratio)
- Low index → slight harmonic color
- High index → bright, complex, metallic

**Musical Use Cases:**
- **DX7 electric piano** - Classic 80s sound
- **Bass** - Punchy, harmonic-rich
- **Bells** - Metallic, complex
- **Game audio:** Retro synths, electric piano, bass, bells

---

### 8. **Phase Cancellation** 🔇
**Concept:** Two identical waves 180° out of phase → silence

**Implementation Plan:**
```gdscript
# Two identical sine waves
# Slider controls phase offset (0° to 360°)
# At 180° → complete cancellation (silence)

# Interactive Controls:
# - Slider: Phase offset (0-360°)
# - Button: Invert phase of wave 2

# Visualize both waves + combined output
```

**Audio Example:**
- Wave 1: 440 Hz
- Wave 2: 440 Hz at 0° offset → double amplitude (loud)
- Wave 2: 440 Hz at 180° offset → silence
- Wave 2: 440 Hz at 90° offset → partial cancellation

**Musical Use Cases:**
- **Phase issues** - Why mic placement matters
- **Noise cancellation** - Anti-noise headphones
- **Stereo widening** - Phase tricks for width
- **Game audio:** Understanding phase problems in audio mix

---

## 🎨 **Creative/Advanced Audio Implementations**

### 9. **Waveshaping / Distortion** 🎸
**Concept:** Non-linear transfer function creates harmonics

```gdscript
# Pass sine wave through distortion curve
# Generates harmonics that weren't in original signal

# Transfer functions:
# - Soft clip: tanh(x)
# - Hard clip: clamp(x, -1, 1)
# - Foldback: fold(x)
# - Bit crushing: floor(x * bits) / bits
```

**Musical Use:** Guitar distortion, lo-fi effects, harsh digital sounds

---

### 10. **Granular Synthesis** 🌾
**Concept:** Sound broken into tiny grains, rearranged/overlapped

```gdscript
# Take sound buffer, chop into 10-100ms grains
# Play grains with random/controlled pitch, position, density

# Slider 1: Grain size (10-200 ms)
# Slider 2: Grain density (grains per second)
# Slider 3: Pitch randomness
# Slider 4: Position in source sound
```

**Musical Use:** Textural pads, time-stretching, glitch effects

---

### 11. **Standing Waves (Reverb)** 🏛️
**Concept:** Sound reflecting in enclosed space creates resonant frequencies

```gdscript
# Simple comb filter = delay + feedback
# Multiple delays = reverb

# Slider 1: Room size (delay time)
# Slider 2: Damping (high-frequency absorption)
# Slider 3: Diffusion (echo density)
```

**Musical Use:** Spatial effects, room simulation, echo

---

## 📊 **Mapping Wave Concepts to Audio Domain**

| Wave Concept | Can Demo in Audio? | Implementation | Priority |
|--------------|-------------------|----------------|----------|
| **Sine/Cosine Waves** | ✅ Yes | Pure tones | ✅ Done (Harmonic Builder) |
| **Frequency** | ✅ Yes | Pitch | ✅ Done (all demos) |
| **Amplitude** | ✅ Yes | Volume | ✅ Done (all demos) |
| **Phase** | ✅ Yes | Phase cancellation | ⚠️ TODO |
| **Superposition** | ✅ Yes | Mixing signals | ✅ Done (Beat Freq, Harmonics) |
| **Beat Frequencies** | ✅ Yes | Wah-wah sound | ✅ Done |
| **Fourier Synthesis** | ✅ Yes | Additive synth | ✅ Done (Harmonic Builder) |
| **Harmonics** | ✅ Yes | Overtones, timbre | ✅ Done (Harmonic Builder) |
| **Doppler Effect** | ✅ Yes | Pitch shift from motion | ⚠️ High Priority |
| **Standing Waves** | ✅ Yes | Resonance, reverb | ⚠️ Medium Priority |
| **Wave Interference** | ✅ Yes | Comb filtering | ⚠️ Medium Priority |
| **Damped Oscillation** | ✅ Yes | Decay envelopes | ✅ Done (Mario Sound) |
| **AM Synthesis** | ✅ Yes | Tremolo, sidebands | ⚠️ High Priority |
| **FM Synthesis** | ✅ Yes | DX7-style synth | ⚠️ High Priority |
| **Resonance** | ✅ Yes | Filter peaks | ⚠️ High Priority |
| **Waveshaping** | ✅ Yes | Distortion | ⚠️ Medium Priority |
| **EM Spectrum** | ❌ Not audio | Light/color only | N/A |
| **Quantum Wavefunctions** | ❌ Not audio | Visual only | N/A |
| **Lissajous Figures** | ⚠️ Partial | Stereo panning? | Low Priority |

---

## 🎮 **Integration with Game Audio System**

### Using These Sounds in Your Game

All demonstrations save parameters to JSON format compatible with your existing audio system:

```json
{
  "sound_type": "beat_frequencies",
  "parameters": {
    "freq1": { "value": 440.0, "min": 400.0, "max": 500.0 },
    "freq2": { "value": 442.0, "min": 400.0, "max": 500.0 },
    "beat_frequency": 2.0
  }
}
```

**Integration Points:**

1. **`commons/audio/generators/CustomSoundGenerator.gd`** - Can load these JSONs
2. **`commons/audio/parameters/educational/`** - Save location for educational presets
3. **`commons/scenes/mapobjects/pick_up_cube.gd`** - Use for pickup sounds
4. **Your game audio system** - Any procedural audio needs

### Example: Using Harmonic Builder for Pickup Sound

```gdscript
# Load harmonic builder preset
var harmonic_params = load_json("res://commons/audio/parameters/educational/bell_pickup.json")

# When player picks up item:
var sound_gen = CustomSoundGenerator.new()
sound_gen.set_parameters(harmonic_params)
var pickup_sound = sound_gen.generate_sound()
audio_player.stream = pickup_sound
audio_player.play()
```

---

## 🎓 **Educational Value Per Demo**

### **Beat Frequencies**
- **Teaches:** Interference, superposition, beating
- **Difficulty:** Beginner
- **Musical Relevance:** High (tuning instruments)
- **Game Audio Use:** Medium (drones, sci-fi effects)

### **Harmonic Series Builder**
- **Teaches:** Fourier synthesis, timbre, overtones
- **Difficulty:** Intermediate
- **Musical Relevance:** Very High (core of synthesis)
- **Game Audio Use:** Very High (any musical sound)

### **Doppler Effect** (TODO)
- **Teaches:** Frequency shift from motion
- **Difficulty:** Beginner
- **Musical Relevance:** Low (effects only)
- **Game Audio Use:** Very High (moving objects)

### **Resonance/Filter Sweeps** (TODO)
- **Teaches:** Resonant frequencies, filtering
- **Difficulty:** Intermediate
- **Musical Relevance:** Very High (subtractive synthesis)
- **Game Audio Use:** Very High (synth sounds)

### **AM/FM Synthesis** (TODO)
- **Teaches:** Modulation, sideband generation
- **Difficulty:** Advanced
- **Musical Relevance:** High (classic synth techniques)
- **Game Audio Use:** High (bells, electric piano, bass)

---

## 🛠️ **Implementation Template**

For each new audio concept demo, follow this structure:

```gdscript
extends Node3D

## [Concept Name] Interactive Demo
## [One-line description]
##
## Concept: [Explain the wave physics]
## Audio Manifestation: [How it sounds]
## Controls: [List interactables]
## Use Cases: [Musical/game applications]

# Audio synthesis
var audio_stream: AudioStreamGenerator
var audio_player: AudioStreamPlayer3D
const SAMPLE_RATE = 44100.0
var audio_phase: float = 0.0
var is_playing: bool = true

# Parameters (controlled by sliders/joysticks/etc.)
var param1: float = 0.0
var param2: float = 0.0

# Visualization
var visualization_nodes: Array = []

func _ready() -> void:
	_setup_audio()
	_create_visualizations()
	_setup_controls()

func _setup_audio() -> void:
	audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = SAMPLE_RATE
	audio_stream.buffer_length = 0.1
	audio_player.stream = audio_stream
	audio_player.play()

func _setup_controls() -> void:
	# Connect slider.value_changed signals
	# Connect button.pressed signals
	pass

func _create_visualizations() -> void:
	# Create visual feedback (waves, bars, labels)
	pass

func _process(delta: float) -> void:
	_generate_audio_samples()
	_update_visualizations()

func _generate_audio_samples() -> void:
	var playback = audio_player.get_stream_playback()
	if not playback:
		return

	var frames_available = playback.get_frames_available()
	var frames_to_fill = min(frames_available, 256)

	for _frame in range(frames_to_fill):
		# Generate sample based on current parameters
		var sample = sin(audio_phase) * 0.5
		audio_phase += param1 * TAU / SAMPLE_RATE

		sample = clamp(sample, -1.0, 1.0)
		playback.push_frame(Vector2(sample, sample))

func get_audio_parameters() -> Dictionary:
	return {"param1": param1, "param2": param2}

func save_to_json(file_path: String) -> void:
	var params = get_audio_parameters()
	var json_string = JSON.stringify(params, "\t")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
```

---

## 📝 **Next Steps**

1. ✅ **Created:**
   - Beat Frequencies demo
   - Harmonic Series Builder
   - Documentation

2. ⚠️ **High Priority (Create Next):**
   - Doppler Effect (moving objects)
   - Resonant Filter Sweep (TB-303 style)
   - AM Synthesis (bells, metallic tones)

3. ⚠️ **Medium Priority:**
   - FM Synthesis (DX7 electric piano)
   - Phase Cancellation (stereo phase)
   - Wave Interference (comb filtering)

4. 📦 **Polish Existing:**
   - Update AdditiveSynthesis.gd with better interactivity
   - Connect all demos to interactable_demo.tscn
   - Create preset library for each demo

5. 🎮 **Game Integration:**
   - Save best-sounding presets to `commons/audio/parameters/`
   - Document usage in pickup cubes, teleporters, etc.
   - Create "audio gallery" map sequence

---

## 🎵 **Sound Design Philosophy**

These demos should:
1. **Sound good first** - Not just educational beeps
2. **Be musically useful** - Usable in actual game
3. **Teach through doing** - Hands-on parameter exploration
4. **Save presets** - Reusable in game audio

**Remember:** The best way to understand waves is to **hear** them, **manipulate** them, and **create** with them.
