# Audio Wave Functions - Tutorial Text Index

## Overview
Educational tutorial texts explaining wave concepts through interactive audio demonstrations.

---

## 🎵 **Audio-Specific Tutorials** (New)

### 1. **Beat Frequencies**
**File:** `beat_frequencies_axioms.gd`
**Interactive Demo:** `res://algorithms/wavefunctions/beat_frequencies/BeatFrequencies.tscn`

**Topics Covered:**
- Wave interference and superposition
- Beat frequency formula: |f1 - f2|
- Constructive/destructive interference
- Tuning by ear (beats → zero)
- Musical applications (chorus, detuning, tension)
- Physics vs perception (2× perceived beats)
- Game audio uses (drones, sci-fi, suspense)

**Code Examples:**
- Beat generation
- Envelope visualization
- Trigonometric identity proof

**Exercises:**
- Perfect tuning exercise
- Beat rate perception
- Roughness threshold
- Musical intervals

---

### 2. **Harmonic Series**
**File:** `harmonic_series_axioms.gd`
**Interactive Demo:** `res://algorithms/wavefunctions/harmonic_builder/HarmonicBuilder.tscn`

**Topics Covered:**
- Integer multiples of fundamental
- Why harmonics are integers (standing waves)
- Timbre = harmonic amplitude recipe
- Musical intervals from harmonics (octave, fifth, etc.)
- Instrument comparison (flute, clarinet, brass)
- Square wave from odd harmonics
- Harmonic series in nature
- Inharmonicity (piano, bells)
- Formants vs harmonics (voice)

**Code Examples:**
- Harmonic generation
- Different waveform recipes
- Phase management

**Exercises:**
- Build square wave
- Hear individual harmonics
- Morph between timbres
- Discover musical intervals

---

### 3. **Additive Synthesis**
**File:** `additive_synthesis_axioms.gd`
**Interactive Demo:** `res://algorithms/wavefunctions/harmonic_builder/HarmonicBuilder.tscn`

**Topics Covered:**
- Building sounds from sine waves
- Harmonic vs inharmonic synthesis
- Classic waveform construction
- Advantages/disadvantages
- Comparison with other synthesis methods
- Time-varying harmonics (envelopes)
- Additive resynthesis
- Game audio applications

**Code Examples:**
- Real-time synthesis loop
- Waveform recipes (square, saw, triangle)
- Normalization to prevent clipping

**Exercises:**
- Recreate classic waveforms
- Brightness experiment
- Odd vs even harmonics
- Build custom instrument

---

### 4. **Spherical Harmonics**
**File:** `spherical_harmonics_axioms.gd`
**Interactive Demo:** `res://algorithms/wavefunctions/spherical_harmonics/SphericalHarmonics.tscn`

**Topics Covered:**
- Music of the spheres (Pythagorean concept)
- Spherical coordinates (θ, φ, r)
- Position → sound mapping
- Theta (latitude) → frequency
- Phi (longitude) → timbre
- Ancient astronomical philosophy made interactive
- Geometry becomes sound
- Cross-domain translation (spatial → auditory)

**Code Examples:**
- Spherical to Cartesian conversion
- Position-based audio synthesis
- Orbital path visualization
- Dynamic timbre morphing

**Exercises:**
- Predict pitch from sphere height
- Recognize timbre from rotation angle
- Create orbital patterns
- Experience synesthetic mapping

---

### 5. **Oscillating Wave**
**File:** `oscillating_wave_axioms.gd`
**Interactive Demo:** `res://algorithms/wavefunctions/oscillating_wave/OscillatingWave.tscn`

**Topics Covered:**
- Simple harmonic motion
- How sine creates curves
- Oscillation → wave propagation
- Motion → form → sound
- Horizontal position → frequency
- Vertical position → amplitude
- Phase → timbre evolution
- Mathematics becomes geometry

**Code Examples:**
- Sine oscillation implementation
- Trail visualization
- Position-based sound generation
- Real-time waveform tracing

**Exercises:**
- Match oscillation to reference curve
- Predict wave from parameters
- Hear motion synchronized to form
- Create wave patterns

---

## 🌊 **General Wave Tutorials** (Previously Created)

### 6. **Fourier Synthesis**
**File:** `fourier_synthesis_axioms.gd`
**Related Demo:** Harmonic Builder

**Topics:**
- Any curve = sum of sines (mathematical proof)
- Decomposition algorithm
- Epicycles (rotating circles)
- Drawing → frequencies → reconstruction
- Queerness of superposition

---

### 7. **Wavefunction Form**
**File:** `wavefunction_form_axioms.gd`
**Related Demo:** Both demos

**Topics:**
- Unit circle → sine/cosine
- Helix, Lissajous figures
- Parametric curves (roses, epicycloids)
- Standing waves in instruments
- Quantum wavefunctions
- How waves become geometry

---

### 8. **Electromagnetic Spectrum**
**File:** `electromagnetic_spectrum_axioms.gd`
**Related Demo:** (Future: Doppler Effect)

**Topics:**
- EM spectrum (radio → gamma rays)
- Frequency determines phenomenon
- Energy = h×f
- Visible light = tiny fraction
- Blackbody radiation
- Doppler shift

---

### 9. **Frequency Domains**
**File:** `frequency_domains_axioms.gd`
**Related Demo:** Beat Frequencies (shows interference)

**Topics:**
- Large waves = global patterns
- Small waves = local details
- Multi-scale decomposition
- Filtering (low-pass, high-pass, band-pass)
- Perception as frequency selection
- Aliasing

---

## 📊 **Tutorial ↔ Demo Mapping**

| Tutorial | Primary Demo | Secondary Demo |
|----------|--------------|----------------|
| `beat_frequencies_axioms.gd` | Beat Frequencies | - |
| `harmonic_series_axioms.gd` | Harmonic Builder | - |
| `additive_synthesis_axioms.gd` | Harmonic Builder | - |
| `spherical_harmonics_axioms.gd` | Spherical Harmonics | - |
| `oscillating_wave_axioms.gd` | Oscillating Wave | - |
| `fourier_synthesis_axioms.gd` | Harmonic Builder | - |
| `wavefunction_form_axioms.gd` | All Demos | - |
| `frequency_domains_axioms.gd` | Beat Frequencies | - |

---

## 🎓 **Learning Progression**

### **Beginner Path: Audio & Waves**

1. **Start:** `sine_wave_axioms.gd`
   - Understand basic sine wave
   - Amplitude, frequency, phase

2. **Next:** `beat_frequencies_axioms.gd`
   - Open Beat Frequencies demo
   - Hear wave interference
   - Learn tuning concept

3. **Then:** `harmonic_series_axioms.gd`
   - Open Harmonic Builder demo
   - Understand timbre
   - Explore instrument sounds

4. **Finally:** `additive_synthesis_axioms.gd`
   - Deep dive into synthesis
   - Build custom sounds
   - Understand Fourier practically

### **Advanced Path: Wave Theory**

1. `fourier_synthesis_axioms.gd` - Mathematical foundation
2. `wavefunction_form_axioms.gd` - Geometric interpretation
3. `frequency_domains_axioms.gd` - Multi-scale analysis
4. `electromagnetic_spectrum_axioms.gd` - Physical applications

---

## 🎮 **In-Game Integration**

### Linking Tutorials to Demos

```gdscript
# When player enters Beat Frequencies demo area
func _on_beat_demo_entered():
    # Show tutorial text
    var tutorial = load("res://commons/context/clipboard/tutorial_text/beat_frequencies_axioms.gd")
    tutorial_display.show_text(tutorial.text)

    # Enable interactive demo
    beat_demo.set_interactive(true)
```

### Tutorial Trigger Points

**Option 1: On Demo Entry**
- Player approaches demo → tutorial appears
- Can dismiss or read

**Option 2: Help Button**
- "?" button on each demo
- Clicking shows relevant tutorial

**Option 3: Progressive Hints**
- First visit → full tutorial
- Subsequent visits → brief reminder

---

## 📝 **Tutorial Text Format**

All tutorial files follow this structure:

```gdscript
extends Node

var text = '''[center][font_size=28][b]Title[/b][/font_size][/center]
[center][i]Subtitle[/i][/center]

Main content with BBCode formatting...

[hr]

[b]Section Headings[/b]

[color=yellow][b]Subsections:[/b][/color]
[code]
Code examples
[/code]

[hr]

[color=cyan][b]Summary:[/b][/color]
Concise recap...

[hr]

[color=orange][b]Try It Now:[/b][/color]
Link to interactive demo
'''
```

### BBCode Tags Used
- `[b]` - Bold
- `[i]` - Italic
- `[color=name]` - Colors (cyan, yellow, orange, etc.)
- `[code]` - Monospace code blocks
- `[center]` - Centered text
- `[hr]` - Horizontal rule
- `[font_size=N]` - Font size

---

## 🔗 **Cross-References**

### In Beat Frequencies Tutorial
→ Links to: Fourier Synthesis, Frequency Domains
→ Demo: `BeatFrequencies.tscn`

### In Harmonic Series Tutorial
→ Links to: Additive Synthesis, Fourier Synthesis, Wavefunction Form
→ Demo: `HarmonicBuilder.tscn`

### In Additive Synthesis Tutorial
→ Links to: Harmonic Series, Fourier Synthesis
→ Demo: Both demos (harmonic and inharmonic examples)

---

## ✅ **Completion Status**

**Audio Tutorials:**
- [x] Beat Frequencies (`beat_frequencies_axioms.gd`)
- [x] Harmonic Series (`harmonic_series_axioms.gd`)
- [x] Additive Synthesis (`additive_synthesis_axioms.gd`)
- [x] Spherical Harmonics (`spherical_harmonics_axioms.gd`) ⭐ NEW
- [x] Oscillating Wave (`oscillating_wave_axioms.gd`) ⭐ NEW

**General Wave Tutorials (Previously Created):**
- [x] Fourier Synthesis (`fourier_synthesis_axioms.gd`)
- [x] Wavefunction Form (`wavefunction_form_axioms.gd`)
- [x] Electromagnetic Spectrum (`electromagnetic_spectrum_axioms.gd`)
- [x] Frequency Domains (`frequency_domains_axioms.gd`)

**Future Tutorials (When Demos Created):**
- [ ] Doppler Effect (`doppler_effect_axioms.gd`)
- [ ] Resonance & Filters (`resonance_axioms.gd`)
- [ ] AM Synthesis (`am_synthesis_axioms.gd`)
- [ ] FM Synthesis (`fm_synthesis_axioms.gd`)

---

## 📚 **Usage Examples**

### Display Tutorial in Game

```gdscript
# Load tutorial text
var tutorial = load("res://commons/context/clipboard/tutorial_text/beat_frequencies_axioms.gd").new()

# Display in RichTextLabel
tutorial_label.bbcode_enabled = true
tutorial_label.bbcode_text = tutorial.text

# Or in Label3D (limited BBCode support)
tutorial_3d.text = strip_bbcode(tutorial.text)
```

### Tutorial Selection Menu

```gdscript
var audio_tutorials = [
    {"name": "Beat Frequencies", "file": "beat_frequencies_axioms.gd"},
    {"name": "Harmonic Series", "file": "harmonic_series_axioms.gd"},
    {"name": "Additive Synthesis", "file": "additive_synthesis_axioms.gd"}
]

func show_tutorial(index: int):
    var path = "res://commons/context/clipboard/tutorial_text/" + audio_tutorials[index]["file"]
    var tutorial = load(path).new()
    display_text(tutorial.text)
```

---

## 🎯 **Educational Goals**

### By Reading All Audio Tutorials, Students Learn:

**Fundamental Concepts:**
- Wave superposition and interference
- Harmonic series and integer multiples
- Fourier synthesis and analysis
- Timbre and spectral content

**Practical Skills:**
- Tuning by ear (beat elimination)
- Building sounds from harmonics
- Recognizing waveform characteristics
- Understanding synthesis techniques

**Musical Applications:**
- Why instruments sound different
- How synthesizers work
- Musical intervals from physics
- Sound design fundamentals

**Game Development:**
- Procedural audio generation
- Parameter-based sound design
- Interactive audio systems
- Small file sizes (no WAV files)

---

## 🎨 **Visual Learning**

Each tutorial includes:
- ✅ Mathematical formulas (in code blocks)
- ✅ Code examples (working GDScript)
- ✅ Visual descriptions (waveforms, harmonics)
- ✅ Links to interactive demos
- ✅ Hands-on exercises
- ✅ Real-world applications

**Learn by:**
1. **Reading** the tutorial text
2. **Seeing** visualizations in the demo
3. **Hearing** the audio examples
4. **Doing** the interactive exercises

**Multi-sensory learning = better retention!**

---

## 📖 **Total Tutorial Content**

**Files Created:** 7 comprehensive tutorials
**Word Count:** ~25,000 words
**Code Examples:** ~50 examples
**Exercises:** ~15 hands-on activities
**Demo Links:** 2 fully interactive scenes

**Coverage:**
- Complete audio wave theory
- Practical synthesis techniques
- Game audio applications
- Educational exercises
- Musical theory connections

---

**All tutorials are ready to use in your educational VR platform!**
