# Optimal Wavefunction Tutorial Sequence

Based on the pedagogical philosophy in `CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md`, this document maps out the optimal learning sequence for the wavefunctions educational path.

## Pedagogical Framework

Following the dual-structure pattern:
1. **Introduce** (poetic/philosophical)
2. **Teach** (technical/code)
3. **Critique** (queer theory perspective)
4. **Embody** (VR interaction)

Four narrative arcs building from foundations to universality.

---

## Complete Sequence (12 tutorials)

### Arc 1: Foundations - What Are Waves? (0-3)

| Order | Tutorial ID | Status | Interactive Demo | Type | Description |
|-------|------------|--------|------------------|------|-------------|
| **0.0** | `sine_wave_axioms` | ✓ Exists | - | Technical | Circular motion → sine projection. Frequency, amplitude, phase. The ur-form of oscillation. |
| **1.0** | `unitcircle_axioms` | ✓ Exists (currently 3.0) | - | Geometric | Unit circle as wave generator. Sine/cosine as projections. Rotation and wave are one. |
| **2.0** | `sound_axioms` | ✓ Exists (currently 1.0) | - | Technical | Frequency → pitch. Amplitude → loudness. Waves as sensation in audio domain. |
| **3.0** | `wave_desire_axioms` | ✓ Exists (currently 2.0) | - | Critical | Oscillation as perpetual seeking. Equilibrium crossed, never occupied. Wave as structure of desire (Lacan). |

**Changes needed:**
- Update `unitcircle_axioms`: change order from 3.0 → 1.0
- Update `sound_axioms`: change order from 1.0 → 2.0
- Update `wave_desire_axioms`: change order from 2.0 → 3.0

---

### Arc 2: Form & Space - How Waves Become Geometry (4-6)

| Order | Tutorial ID | Status | Interactive Demo | Type | Description |
|-------|------------|--------|------------------|------|-------------|
| **4.0** | `wavefunction_form_axioms` | ✓ File exists, **needs registration** | - | Technical | Geometry IS wavefunction. Circle, spiral, helix from sine/cosine. Parametric equations. |
| **5.0** | `oscillating_wave_axioms` | ✓ Exists (currently 4.0) | ✓ `OscillatingWave.gd` | Embodied | Vertical oscillation traces sine curve. Position → frequency/amplitude. See sine create curves. |
| **6.0** | `spherical_harmonics_axioms` | ✓ Exists (currently 5.0) | ✓ `SphericalHarmonics.gd` | Embodied | Pythagorean music of spheres. Orbital position → sound. Hear the geometry. |

**Changes needed:**
- **ADD** `wavefunction_form_axioms` to tutorial_text.json (order 4.0)
- Update `oscillating_wave_axioms`: change order from 4.0 → 5.0
- Update `spherical_harmonics_axioms`: change order from 5.0 → 6.0

---

### Arc 3: Composition - How Waves Combine (7-10)

| Order | Tutorial ID | Status | Interactive Demo | Type | Description |
|-------|------------|--------|------------------|------|-------------|
| **7.0** | `harmonic_series_axioms` | ✓ File exists, **needs registration** | - | Technical | Integer multiples. Physics of standing waves. Harmonics determine timbre. Foundation of musical sound. |
| **8.0** | `harmonic_builder_axioms` | ⚠️ **NEEDS CREATION** | ✓ `HarmonicBuilder.gd` | Embodied | 8-harmonic interactive synthesizer. Presets: sine, square, saw, triangle, organ, clarinet, brass, flute. Build your own timbre. |
| **9.0** | `beat_frequencies_axioms` | ✓ File exists, **needs registration** | - | Technical | Wave interference. \|f1 - f2\| = beat frequency. Constructive/destructive interference. Used for tuning instruments. |
| **10.0** | `beat_frequencies_demo_axioms` | ⚠️ **NEEDS CREATION** | ✓ `BeatFrequencies.gd` | Embodied | Two-slider frequency control. Visual waveform + beat envelope. Hear interference. Slow beats = in tune. |

**Changes needed:**
- **ADD** `harmonic_series_axioms` to tutorial_text.json (order 7.0)
- **CREATE** new tutorial file: `harmonic_builder_axioms.gd` (order 8.0)
  - Links to `algorithms/wavefunctions/harmonic_builder/`
  - Explains 8-harmonic synthesis, timbre control, musical presets
- **ADD** `beat_frequencies_axioms` to tutorial_text.json (order 9.0)
- **CREATE** new tutorial file: `beat_frequencies_demo_axioms.gd` (order 10.0)
  - Links to `algorithms/wavefunctions/beat_frequencies/`
  - Explains interactive demo, tuning application

---

### Arc 4: Universality - The Fourier Truth (11-12)

| Order | Tutorial ID | Status | Interactive Demo | Type | Description |
|-------|------------|--------|------------------|------|-------------|
| **11.0** | `fourier_synthesis_axioms` | ✓ File exists, **needs registration** | - | Technical | ANY curve = sum of sines. Fourier series/transform. Mathematical profound truth. Everything is waves. |
| **12.0** | `fourier_analysis_critique_axioms` | ⚠️ **FUTURE CREATION** | - | Critical | What does Fourier decomposition erase? Critique of frequency domain. Non-decomposable experiences. |

**Changes needed:**
- **ADD** `fourier_synthesis_axioms` to tutorial_text.json (order 11.0)
- **FUTURE**: Create critical perspective on Fourier analysis (order 12.0)

---

## Summary of Required Actions

### 1. Update Existing Entries (6 changes)

```json
// Change these order values in tutorial_text.json:

"unitcircle_axioms": { "order": 3.0 } → { "order": 1.0 }
"sound_axioms": { "order": 1.0 } → { "order": 2.0 }
"wave_desire_axioms": { "order": 2.0 } → { "order": 3.0 }
"oscillating_wave_axioms": { "order": 4.0 } → { "order": 5.0 }
"spherical_harmonics_axioms": { "order": 5.0 } → { "order": 6.0 }
```

### 2. Add Existing Files to JSON (4 additions)

```json
// Add these entries to tutorial_text.json (files exist, just not registered):

"wavefunction_form_axioms": {
	"content_file": "res://commons/context/clipboard/tutorial_text/wavefunction_form_axioms.gd",
	"order": 4.0,
	"sequence": "wavefunctions"
},
"harmonic_series_axioms": {
	"content_file": "res://commons/context/clipboard/tutorial_text/harmonic_series_axioms.gd",
	"order": 7.0,
	"sequence": "wavefunctions"
},
"beat_frequencies_axioms": {
	"content_file": "res://commons/context/clipboard/tutorial_text/beat_frequencies_axioms.gd",
	"order": 9.0,
	"sequence": "wavefunctions"
},
"fourier_synthesis_axioms": {
	"content_file": "res://commons/context/clipboard/tutorial_text/fourier_synthesis_axioms.gd",
	"order": 11.0,
	"sequence": "wavefunctions"
}
```

### 3. Create New Tutorial Files (2 creations)

**File 1:** `commons/context/clipboard/tutorial_text/harmonic_builder_axioms.gd`
- Content: Explains the HarmonicBuilder interactive demo
- Links to: `algorithms/wavefunctions/harmonic_builder/HarmonicBuilder.gd`
- Topics: 8-harmonic synthesis, timbre crafting, musical presets

**File 2:** `commons/context/clipboard/tutorial_text/beat_frequencies_demo_axioms.gd`
- Content: Explains the BeatFrequencies interactive demo
- Links to: `algorithms/wavefunctions/beat_frequencies/BeatFrequencies.gd`
- Topics: Interference visualization, tuning instruments, beating perception

---

## Narrative Arc Summary

**Act I: Foundations (0-3)**
- What is oscillation? (sine wave)
- Where does it come from? (unit circle)
- How do we experience it? (sound)
- What does it mean? (desire)

**Act II: Form (4-6)**
- Waves create geometry (spirals, helixes)
- Motion becomes visible curve (oscillating wave) 🎮
- Geometry becomes audible (spherical harmonics) 🎮

**Act III: Composition (7-10)**
- Harmonics build timbre (harmonic series)
- Build your own sound (harmonic builder) 🎮
- Waves interfere (beat frequencies)
- Hear interference (beat demo) 🎮

**Act IV: Universality (11-12)**
- All curves are sums of sines (Fourier)
- What does this erase? (critique)

🎮 = Interactive VR demo available

---

## Pedagogical Rationale

### Why This Order?

1. **Build from sensation to abstraction**
   - Start with visceral oscillation (sine wave)
   - Ground in geometry (unit circle)
   - Connect to experience (sound)
   - Reflect philosophically (desire)

2. **Alternate technical ↔ critical**
   - Follows guide's dual-structure pattern
   - Every 2-3 technical tutorials → 1 critical reflection
   - Prevents either mode from dominating

3. **Place interactives strategically**
   - Arc 2: Form demos (oscillating, spherical) after establishing foundations
   - Arc 3: Synthesis demos (harmonic builder, beat frequencies) after explaining composition
   - Each interactive comes AFTER its conceptual tutorial

4. **Build toward Fourier revelation**
   - Sequence culminates in profound mathematical truth
   - "ANY curve = sum of sines" is earned through journey
   - Critique follows revelation (what does decomposition erase?)

### Alignment with Project Philosophy

From `CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md`:

> "The project teaches through **oscillation** between two modes:
> - Technical (Orthodox): Concrete code, "How to implement X"
> - Critical (Queer Theory): Philosophical questions, "What does X erase?"

This sequence embodies that oscillation:
- 0 (technical) → 1 (geometric) → 2 (technical) → 3 (critical)
- 4 (technical) → 5 (embodied) → 6 (embodied+philosophical)
- 7 (technical) → 8 (embodied) → 9 (technical) → 10 (embodied)
- 11 (technical) → 12 (critical)

> "Watch for this pattern:
> 1. **Introduce** concept (poetic/philosophical)
> 2. **Teach** implementation (technical/code)
> 3. **Critique** what was just taught (queer theory)
> 4. **Embody** through VR interaction (physical)"

Each arc follows this pattern:
- Arc 1: Introduce oscillation → teach sine/sound → critique as desire
- Arc 2: Introduce form-from-waves → embody in oscillating wave → embody in spherical harmonics
- Arc 3: Introduce harmonics → embody in builder → introduce beats → embody in beat demo
- Arc 4: Teach Fourier → critique decomposition

---

## Connection to Map Sequences

From `commons/maps/map_sequences.json`, the wavefunctions sequence currently has:

```json
"maps": [
	"WaveFunctions_Mario_Sound",
	"Wavefunctions_Bernini",
	"WaveFunctions_Sine_Space",
]
```

### Recommended Map Sequence Expansion

To match the 4-arc tutorial structure, maps should follow similar progression:

**Suggested map order:**
1. **Sine_Space** - Foundational sine wave space (Arc 1)
2. **Unit_Circle_Gallery** - Geometric foundation (Arc 1) [CREATE]
3. **Wave_Desire_Space** - Philosophical reflection space (Arc 1) [CREATE]
4. **Oscillating_Wave_Demo** - Interactive motion→form (Arc 2) [CREATE]
5. **Spherical_Harmonics_Demo** - Music of spheres (Arc 2) [CREATE]
6. **Harmonic_Builder_Demo** - Synthesis workshop (Arc 3) [CREATE]
7. **Beat_Frequencies_Demo** - Interference gallery (Arc 3) [CREATE]
8. **Bernini** - Architectural/artistic synthesis (Arc 4)
9. **Fourier_Revelation** - Final mathematical truth (Arc 4) [CREATE]

Maps marked [CREATE] need to be built with appropriate grid layouts and interactables.

---

## Implementation Priority

### Phase 1: Register Existing (Immediate)
✅ Update order numbers in tutorial_text.json (6 changes)
✅ Add 4 existing tutorial files to JSON (wavefunction_form, harmonic_series, beat_frequencies, fourier_synthesis)

### Phase 2: Create Missing Tutorials (High Priority)
- Create `harmonic_builder_axioms.gd` (~3000 words)
- Create `beat_frequencies_demo_axioms.gd` (~3000 words)

### Phase 3: Create Maps (Medium Priority)
- Design grid layouts for each interactive demo
- Place interactables (code_displays with tutorials + actual demos)
- Follow "Simple → Context" map pairing pattern from guide

### Phase 4: Critical Completion (Future)
- Create `fourier_analysis_critique_axioms.gd`
- Add other critical perspectives as needed
- Ensure technical ↔ critical balance maintained

---

## Files Referenced

**Guides:**
- `CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md` - Pedagogical philosophy
- `algorithms/wavefunctions/INTEGRATION_GUIDE.md` - Technical integration
- `algorithms/wavefunctions/AUDIO_DOMAIN_WAVE_CONCEPTS.md` - Audio concepts

**Interactive Demos:**
- `algorithms/wavefunctions/oscillating_wave/OscillatingWave.gd`
- `algorithms/wavefunctions/spherical_harmonics/SphericalHarmonics.gd`
- `algorithms/wavefunctions/harmonic_builder/HarmonicBuilder.gd`
- `algorithms/wavefunctions/beat_frequencies/BeatFrequencies.gd`

**Tutorial Files:**
- All in `commons/context/clipboard/tutorial_text/`
- Registered in `commons/context/clipboard/tutorial_text.json`

**Map System:**
- `commons/maps/map_sequences.json` - Sequence definitions
- `commons/maps/{MapName}/map_data.json` - Individual map layouts

---

*This document provides the complete roadmap for the optimal wavefunction educational sequence, balancing technical depth, philosophical critique, and embodied interaction.*
