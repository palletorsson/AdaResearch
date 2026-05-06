# Wavefunction Sequence - Quick Reference

## Current State → Optimal State

| Order | Current Tutorial | → | Optimal Tutorial | Status |
|-------|-----------------|---|------------------|--------|
| 0.0 | sine_wave_axioms | ✓ | sine_wave_axioms | Keep |
| 1.0 | sound_axioms | → | **unitcircle_axioms** | Move from 3.0 |
| 2.0 | wave_desire_axioms | → | **sound_axioms** | Move from 1.0 |
| 3.0 | unitcircle_axioms | → | **wave_desire_axioms** | Move from 2.0 |
| 4.0 | oscillating_wave_axioms | → | **wavefunction_form_axioms** | ADD (file exists) |
| 5.0 | spherical_harmonics_axioms | → | **oscillating_wave_axioms** | Move from 4.0 |
| 6.0 | — | → | **spherical_harmonics_axioms** | Move from 5.0 |
| 7.0 | — | → | **harmonic_series_axioms** | ADD (file exists) |
| 8.0 | — | → | **harmonic_builder_axioms** | CREATE NEW |
| 9.0 | — | → | **beat_frequencies_axioms** | ADD (file exists) |
| 10.0 | — | → | **beat_frequencies_demo_axioms** | CREATE NEW |
| 11.0 | — | → | **fourier_synthesis_axioms** | ADD (file exists) |

---

## Four Narrative Arcs

**Arc 1: Foundations (0-3)** - What are waves?
- Sine wave → Unit circle → Sound → Desire

**Arc 2: Form & Space (4-6)** - How waves create geometry
- Wavefunction form → Oscillating wave 🎮 → Spherical harmonics 🎮

**Arc 3: Composition (7-10)** - How waves combine
- Harmonic series → Harmonic builder 🎮 → Beat frequencies → Beat demo 🎮

**Arc 4: Universality (11+)** - The Fourier truth
- Fourier synthesis → [Future: Critical perspective]

🎮 = Interactive VR demo

---

## Immediate Actions Required

### 1. Update tutorial_text.json (6 order changes)
```
unitcircle_axioms: 3.0 → 1.0
sound_axioms: 1.0 → 2.0
wave_desire_axioms: 2.0 → 3.0
oscillating_wave_axioms: 4.0 → 5.0
spherical_harmonics_axioms: 5.0 → 6.0
```

### 2. Add to tutorial_text.json (4 registrations)
```
wavefunction_form_axioms (order 4.0) - file exists ✓
harmonic_series_axioms (order 7.0) - file exists ✓
beat_frequencies_axioms (order 9.0) - file exists ✓
fourier_synthesis_axioms (order 11.0) - file exists ✓
```

### 3. Create new tutorial files (2 files)
```
harmonic_builder_axioms.gd (order 8.0)
beat_frequencies_demo_axioms.gd (order 10.0)
```

---

## Pedagogical Pattern

Follows CLAUDE_GUIDE pattern:
1. **Introduce** (poetic) → 2. **Teach** (technical) → 3. **Critique** (theory) → 4. **Embody** (VR)

Each arc cycles through: Technical → Critical → Embodied

---

## Interactive Demo Mapping

| Demo | Tutorial Order | Links To |
|------|---------------|----------|
| OscillatingWave.gd | 5.0 | oscillating_wave_axioms |
| SphericalHarmonics.gd | 6.0 | spherical_harmonics_axioms |
| HarmonicBuilder.gd | 8.0 | harmonic_builder_axioms (NEW) |
| BeatFrequencies.gd | 10.0 | beat_frequencies_demo_axioms (NEW) |

All demos in: `algorithms/wavefunctions/{demo_name}/`

---

See `OPTIMAL_SEQUENCE_MAP.md` for complete details and rationale.
