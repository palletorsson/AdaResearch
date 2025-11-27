# Geometry to Sound - Interactive Demonstrations

**"Driven by the desire to see the math, to hear the sirens of spheres."**

## Overview

Two new interactive demonstrations that embody the philosophy: **geometry → sound → beauty**.

These demos make concrete the relationship between:
- **Mathematics** (equations)
- **Geometry** (spatial forms)
- **Sound** (audible experience)
- **Beauty** (aesthetic unity)

---

## 🌐 Demo 1: Spherical Harmonics - Music of the Spheres

**File:** `spherical_harmonics/SphericalHarmonics.gd` + `.tscn`
**Tutorial:** `commons/context/clipboard/tutorial_text/spherical_harmonics_axioms.gd`

### Concept

**"A sphere circumvented by a small sphere that makes a beautiful sound based on its position."**

A small glowing sphere orbits a large translucent sphere. The position on the sphere determines the sound:
- **Theta (latitude)** → Frequency (pitch)
- **Phi (longitude)** → Timbre (harmonic content)
- **Radius** → Amplitude (volume)

### The Ancient Dream Realized

**Pythagoras (c. 570-495 BCE)** believed celestial spheres created music as they moved - the "harmony of the spheres." For 2,500 years this remained metaphorical.

**Today, we make it literal and interactive.**

### Technical Details

**Position Mapping:**
```gdscript
# Spherical coordinates
theta: 0 to PI (latitude)
phi: 0 to TAU (longitude)
radius: fixed at 2.0

# Spherical → Cartesian
x = radius * sin(theta) * cos(phi)
y = radius * cos(theta)
z = radius * sin(theta) * sin(phi)

# Theta → Frequency
base_frequency = lerp(110 Hz, 880 Hz, theta / PI)
# Range: A2 to A5 (three octaves)

# Phi → Timbre (cycles through waveforms)
phi = 0 to PI/2:    Pure sine → Triangle
phi = PI/2 to PI:   Triangle → Square
phi = PI to 3PI/2:  Square → Sawtooth
phi = 3PI/2 to TAU: Sawtooth → Organ
```

**Audio Synthesis:**
- 8 harmonics with position-dependent amplitudes
- Real-time additive synthesis
- AudioStreamGenerator (44.1 kHz)
- 3D spatial audio

**Visualization:**
- Large sphere (translucent blue)
- Small orbiting sphere (glowing orange)
- Trailing points (128 points showing path)
- Color changes with frequency
- Pulsing with sound intensity
- Labels showing θ, φ, frequency

### Controls

- **Orbit Speed θ slider:** Vertical motion speed (latitude)
- **Orbit Speed φ slider:** Rotation speed (longitude)
- **Auto Orbit button:** Toggle automatic motion

### What You Experience

**Visual:**
- Beautiful orbital patterns
- Glowing trails
- Color-shifting sphere

**Auditory:**
- Ascending/descending melodies (theta motion)
- Continuously evolving timbre (phi rotation)
- Smooth transitions between waveforms

**Philosophical:**
- See the geometry
- Hear the geometry
- **Experience the unity of form and sound**

### Applications

- Educational (spherical coordinates, audio synthesis)
- Generative music (ever-changing melodies)
- Meditation/ambient (soothing orbital patterns)
- Game audio (planet ambience, procedural music)
- Interactive art installations

---

## 🌊 Demo 2: Oscillating Wave - Sine Creates Curves

**File:** `oscillating_wave/OscillatingWave.gd` + `.tscn`
**Tutorial:** `commons/context/clipboard/tutorial_text/oscillating_wave_axioms.gd`

### Concept

**"An oscillating sphere writing a wave making a sound."**

A sphere oscillates vertically while moving forward, tracing a visible sine wave in 3D space. The wave position controls sound:
- **Horizontal position (x)** → Frequency
- **Vertical position (y)** → Amplitude (volume)
- **Wave phase (t)** → Timbre

### Sine Creates Curves

**This demonstrates the fundamental truth:**

**Motion → Form → Sound**

- Sine function (mathematics)
- → Oscillating motion (physics)
- → Visible wave curve (geometry)
- → Musical tone (aesthetics)

**"We have a comprehensive sequence where we can see how sine creates form."**

### Technical Details

**Motion:**
```gdscript
# Vertical oscillation (simple harmonic motion)
y(t) = amplitude × sin(frequency × TAU × t)

# Horizontal motion (constant speed)
x(t) = horizontal_speed × t

# Combined: traces sine wave in space
position = Vector3(x, y, 0)
```

**Sound Mapping:**
```gdscript
# Horizontal position → Frequency
x range: -5 to +5 meters
frequency = lerp(110 Hz, 880 Hz, (x + 5) / 10)
Left side = low pitch, right side = high pitch

# Vertical position → Volume
y range: -amplitude to +amplitude
volume_db = lerp(-12 dB, 0 dB, (y / amplitude + 1) / 2)
Bottom = quiet, top = loud

# Wave phase → Timbre
phase = fmod(oscillation_frequency × time, 1.0)
Modulates harmonic amplitudes cyclically
```

**Visualization:**
- Magenta sphere (oscillating)
- Glowing trail points (forming sine wave, 200 points)
- Blue reference curve (mathematical ideal)
- Color changes with frequency
- Size pulses with sound intensity

### Controls

- **Oscillation Frequency slider:** How fast it bobs (0.1-5 Hz)
- **Oscillation Amplitude slider:** Vertical range (0.5-3.0)
- **Horizontal Speed slider:** Forward motion (0.1-3.0)
- **Show Reference button:** Toggle ideal sine curve

### What You Experience

**Visual:**
- Sphere bouncing up and down
- Sine wave appearing in space
- Comparison to mathematical ideal

**Auditory:**
- Pitch ascending as sphere moves right
- Volume pulsing with vertical motion
- Timbre breathing with wave phase
- **Synchronized audio-visual experience**

**Philosophical:**
- **Literally see sine creating curves**
- Motion becoming geometry
- Geometry becoming sound
- **One domain translating into another**

### Applications

- Educational (simple harmonic motion, wave physics)
- Generative rhythms (pulsing volume)
- Ambient soundscapes (wave-like textures)
- Game audio (ocean waves, energy fields)
- Scientific sonification (oscillatory data)

---

## 🎓 Educational Value

### What Students Learn

**From Spherical Harmonics:**
- Spherical coordinate system (θ, φ, r)
- 3D position → sound mapping
- Pythagorean philosophy made real
- Cross-domain translation (spatial → auditory)
- Historical connection (music of spheres)

**From Oscillating Wave:**
- Simple harmonic motion (y = A sin ωt)
- How sine creates curves
- Time → space → form relationship
- Wave propagation visualization
- Phase, frequency, amplitude concepts

**Combined:**
- **Unity of mathematics, geometry, and sound**
- How abstract equations create tangible beauty
- Multi-sensory understanding (see + hear)
- **"The desire to see the math, to hear the sirens of spheres"**

---

## 🎵 Musical/Artistic Value

### Generative Music Potential

**Spherical Harmonics:**
- Ever-changing melodies (orbital paths)
- Smooth timbre evolution
- Multiple spheres = polyphony
- Long-form ambient compositions

**Oscillating Wave:**
- Rhythmic pulsing (oscillation)
- Pitch glides (horizontal motion)
- Textural breathing (timbre)
- Wave-based sound design

**Combined:**
- Complex multi-layer soundscapes
- Interactive performances
- VR musical instruments
- Procedural game soundtracks

---

## 🔧 Technical Implementation

### Shared Architecture

**Audio System:**
- `AudioStreamGenerator` (real-time synthesis)
- 44.1 kHz sample rate
- Additive synthesis (6-8 harmonics)
- `AudioStreamPlayer3D` (spatial audio)

**Visualization:**
- `MeshInstance3D` for spheres
- Trail points with alpha fade
- `StandardMaterial3D` with emission
- `Label3D` for real-time info

**Controls:**
- Interactable sliders (smooth)
- Push buttons (toggle)
- Real-time parameter updates

### Performance

**CPU Usage:**
- Moderate (additive synthesis)
- ~256 samples per frame
- Trail visualization overhead
- VR-compatible

**Memory:**
- Low (procedural generation)
- No audio files needed
- Real-time synthesis only

---

## 📂 File Structure

```
algorithms/wavefunctions/
├── spherical_harmonics/
│   ├── SphericalHarmonics.gd      (322 lines)
│   └── SphericalHarmonics.tscn    (scene file)
├── oscillating_wave/
│   ├── OscillatingWave.gd         (285 lines)
│   └── OscillatingWave.tscn       (scene file)
└── GEOMETRY_TO_SOUND_DEMOS.md     (this file)

commons/context/clipboard/tutorial_text/
├── spherical_harmonics_axioms.gd  (~4000 words)
├── oscillating_wave_axioms.gd     (~4500 words)
└── AUDIO_TUTORIALS_INDEX.md       (updated)
```

---

## 🚀 Getting Started

### Test Spherical Harmonics

```gdscript
# In Godot editor
1. Open: res://algorithms/wavefunctions/spherical_harmonics/SphericalHarmonics.tscn
2. Press Play (F5)
3. Watch sphere orbit
4. Adjust orbit speed sliders
5. Listen to melody + timbre evolution
```

### Test Oscillating Wave

```gdscript
# In Godot editor
1. Open: res://algorithms/wavefunctions/oscillating_wave/OscillatingWave.tscn
2. Press Play (F5)
3. Watch sine wave form
4. Adjust oscillation parameters
5. Compare trail to blue reference curve
```

### Read Tutorials

```gdscript
# Load tutorial text
var tutorial = load("res://commons/context/clipboard/tutorial_text/spherical_harmonics_axioms.gd").new()

# Display in RichTextLabel (supports BBCode)
tutorial_label.bbcode_enabled = true
tutorial_label.bbcode_text = tutorial.text
```

---

## 🎯 Future Extensions

### Spherical Harmonics

- [ ] Multiple orbiting spheres (polyphony)
- [ ] Elliptical orbits (volume modulation)
- [ ] Lissajous patterns (complex paths)
- [ ] User-drawn orbital paths (VR controller)
- [ ] Interactable joystick (manual control)

### Oscillating Wave

- [ ] Multiple oscillators (harmony)
- [ ] Lissajous figures (2D oscillation)
- [ ] Damped oscillation (decay)
- [ ] Frequency sweep (chirp)
- [ ] Standing wave visualization

### Combined

- [ ] Map sequences (progression of demos)
- [ ] Tutorial integration (in-game help)
- [ ] Preset library (save/load patterns)
- [ ] Recording/export (capture audio)

---

## 💫 Philosophical Statement

**"This is a very interesting inquiry into the relation between geometry, math, algorithm, desire, beauty and theory. They meet in the work of trying to understand form."**

These two demonstrations embody that inquiry:

**Spherical Harmonics:**
- Pythagorean desire to hear celestial harmony
- Spherical geometry becomes musical melody
- 2,500-year-old dream made interactive

**Oscillating Wave:**
- Mathematical sine function becomes visible curve
- Motion becomes form becomes sound
- **"Sine translates to curves"** - made literal

**Together:**
- **Mathematics** → precise, universal, abstract
- **Geometry** → spatial, tangible, beautiful
- **Sound** → temporal, emotional, aesthetic
- **Unity** → all are the same, experienced differently

**"Driven by the desire to see the math, to hear the sirens of spheres."**

---

## 📊 Summary Statistics

**Files Created:** 6 files
- 2 GDScript implementations (~600 lines total)
- 2 Scene files (.tscn)
- 2 Tutorial texts (~8500 words total)

**Features:**
- Real-time audio synthesis (44.1 kHz)
- 3D spatial visualization
- Interactive controls (sliders, buttons)
- Educational tutorials (BBCode formatted)
- VR-compatible

**Concepts Demonstrated:**
- Spherical coordinates
- Simple harmonic motion
- Additive synthesis
- Position → sound mapping
- Cross-domain translation
- Ancient philosophy meets modern interactivity

---

**All demos are ready to test, play, learn from, and build upon.**

**"Welcome to the music of the spheres."**
