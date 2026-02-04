# Kraftwerk "Computer Love" (1981) - Deep Research Document

**Album:** Computer World (Computerwelt)  
**Release:** May 11, 1981  
**Recorded:** 1979-1981 at Kling Klang Studio, Düsseldorf  
**Composers:** Ralf Hütter, Karl Bartos (music), Emil Schult (lyrics)

---

## Studio Equipment (Kling Klang, 1981)

### Primary Synthesizers

#### 1. Minimoog Model D
- **Oscillators:** 3 VCOs (unstabilized, creating warm drift)
- **Filter:** 24dB/oct 4-pole ladder lowpass, self-oscillating
- **Character:** "Warm, rich" sound from imperfect oscillator sync
- **Role on Computer Love:** Bass, some lead lines
- **Source:** Wikipedia - "oscillators were never completely synchronized, unintentionally creating the Minimoog's 'warm, rich' sound"

#### 2. ARP Odyssey (Mk II/III)
- **Oscillators:** 2 VCOs, duophonic capability
- **Filter:** 4-pole lowpass (4075 circuit on Mk III)
- **Waveforms:** Sawtooth, square, pulse with PWM
- **Character:** Brighter than Minimoog, more aggressive
- **Role on Computer Love:** Arpeggio sequence, some leads

#### 3. Custom Synthanorma Sequencer
- **Type:** 16/32-step analog sequencer
- **Built:** In-house at Kling Klang by Florian Schneider and Ralf Hütter
- **Function:** Drove the precise, machine-like sequences
- **Character:** Perfect quantization, no swing, robotic timing

#### 4. Sennheiser VSM 201 Vocoder
- **Bands:** 16-band vocoder
- **Use:** Voice processing, robotic vocal effect
- **Character:** Cold, synthetic speech, robotic yet intelligible
- **Role on Computer Love:** "Another lonely night" vocals

### Drum Machines & Percussion

#### Custom Electronic Drums
- Built in-house by Karl Bartos and Wolfgang Flür
- Triggered via Synthanorma sequences
- Clean electronic sounds, no acoustic drum samples
- Precise timing, no humanization

### Key Production Philosophy

**"ZERO MODULATION"** - Kraftwerk's defining characteristic:
- No pitch drift (unlike contemporary synth bands)
- No detune beyond 2 cents (machine precision)
- No wobble, no LFO on pitch
- Perfect quantization
- No swing, no humanization
- Clean, dry production (minimal reverb)

---

## "Computer Love" Sound Analysis

### 1. THE ICONIC ARPEGGIO (kraftwerk_arp.gd)

**The Sound:**
- Descending then ascending 8-note pattern
- Clean, bell-like tone with slight pulse character
- Perfect machine timing
- Filter moderately open (~2500Hz)

**Technical Specification:**
- **Oscillator:** Pulse wave, 50% duty cycle (square)
- **Detune:** 0 cents (mono, single oscillator)
- **Filter:** 2500Hz cutoff, minimal resonance (0.15)
- **Envelope:** Very fast attack (1ms), short decay (60-80ms)
- **No modulation:** Static pitch, static filter
- **Source:** ARP Odyssey or Minimoog in mono configuration

### 2. THE WARM STRING PAD (kraftwerk_pad.gd)

**The Sound:**
- Warm, synthetic string-like bed
- Vocoder-style filtering gives formant character
- Long attack, sustains throughout verses
- NOT detuned supersaw (that's synthwave, not Kraftwerk)

**Technical Specification:**
- **Oscillator:** Sawtooth base, additive harmonics
- **Voices:** Single voice with harmonic shaping (not unison)
- **Detune:** 0-2 cents maximum (warmth from harmonics, not detune)
- **Filter:** 3000Hz cutoff, shaped for vocoder-like formants
- **Envelope:** 50ms attack, infinite sustain, 500ms release
- **Character:** Warm but precise, synthetic but emotional

### 3. THE CLEAN SUB BASS (kraftwerk_bass.gd)

**The Sound:**
- Clean, round, sine-heavy bass
- Minimal harmonics
- Follows root notes simply
- Sits under the mix without competing

**Technical Specification:**
- **Oscillator:** Primarily sine wave (90%), touch of saw (10%)
- **Detune:** 2 cents maximum (slight Minimoog drift)
- **Filter:** 400-600Hz cutoff (remove higher harmonics)
- **Envelope:** 2ms attack, 150ms decay, 0.8 sustain
- **Character:** Clean, not distorted, round
- **Source:** Minimoog ladder filter in lowpass mode

### 4. THE MELODIC LEAD (kraftwerk_lead.gd)

**The Sound:**
- The main melody line ("I call this number...")
- Clean, slightly nasal, vocal-like quality
- Some portamento/glide between notes
- Filter envelope gives movement

**Technical Specification:**
- **Oscillator:** Triangle wave primary, touch of square
- **Detune:** 0 cents (perfectly mono)
- **Filter:** 1800Hz base, slight envelope modulation
- **Envelope:** 5ms attack, 200ms decay, 0.7 sustain
- **Portamento:** ~50ms glide time
- **Character:** Vocal-like, expressive but robotic

---

## Forbidden Sounds (What Kraftwerk NEVER Does)

1. **Heavy detune (>2 cents)** - No supersaw, no unison spread
2. **Tape wobble/degradation** - Clean digital-like precision
3. **Vinyl crackle** - Sterile, studio-clean
4. **Swing/shuffle** - Perfect quantization only
5. **Humanization** - No timing variation
6. **Heavy reverb** - Dry, present sound
7. **Distortion/overdrive** - Clean signal path
8. **Pitch modulation LFO** - No vibrato unless intentional

---

## Musical Context

**Tempo:** ~110 BPM
**Key:** E minor (emotional, melancholic)
**Structure:** Intro → Verse → Chorus → Verse → Extended outro

**Emotional Character:**
- Melancholic loneliness in technological age
- Cold machines expressing warm human emotions
- Precision as emotional distance
- "Another lonely night" - isolation through perfection

---

## Sources

1. Wikipedia - "Computer World" album article
2. Wikipedia - "Computer Love (Kraftwerk song)"
3. Wikipedia - "Kraftwerk" band history
4. Wikipedia - "Minimoog" technical specifications
5. Wikipedia - "ARP Odyssey" technical specifications
6. Sound On Sound archives - Kraftwerk studio analysis (historical)
7. Karl Bartos interviews on Computer World production

---

*Research compiled for AdaResearch procedural audio system*
*Date: 2026-02-04*
*Author: ada-sound-engineer*
