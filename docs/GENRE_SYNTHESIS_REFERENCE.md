# Genre Synthesis Reference

Quick reference for what makes each genre sonically distinct. Use this when implementing procedural audio generators.

---

## Overview: The Problem & Solution

**Problem**: All tracks sound similar because generators use identical DSP - same kick, same hats, same bass synthesis.

**Solution**: Each genre has specific:
- **Drum machine identity** (808 vs 909 vs breakbeats vs LinnDrum)
- **Bass synthesis** (303 acid vs Moog ladder vs reese vs sub)
- **Pad character** (JP-8000 supersaw vs Juno chorus vs string machine)
- **Effects chain** (tape saturation vs digital clean vs vinyl crackle)
- **Tempo & groove** (swing vs quantized vs 2-step)

---

## Quick Reference Matrix

| Genre | BPM | Kick Style | Bass Type | Pad Type | Signature FX |
|-------|-----|------------|-----------|----------|--------------|
| **Ambient Works** | 85-95 | Lo-fi breakbeat | 303 acid | Warm Juno | Tape saturation |
| **Detroit Techno** | 125-138 | 909 punch | Sub square | Cold digital | Dry, minimal |
| **Moroder Disco** | 120-128 | Inside sequencer | Moog ladder | String machine | Phaser |
| **Synthwave** | 100-118 | LinnDrum gated | Saw + sub | Supersaw | Gated reverb |
| **Rave** | 140-160 | Breakbeat | Hoover (detuned saw) | Mentasm stabs | Distortion |
| **French Touch** | 118-125 | Disco 4-on-floor | Filter disco | Vocoder | Sidechain duck |
| **Gypsy Woman House** | 118-122 | 909 house | Octave bounce | Strings | Light reverb |
| **Boards of Canada** | 85-100 | Lo-fi hip-hop | Warm sub | Tape-warped | Bitcrush, wow |
| **Burial** | 125-140 | 2-step garage | UK sub | Dark reverb | Vinyl crackle |
| **Kraftwerk** | 100-120 | Electronic precise | Minimoog | Vocoder | Clean, robotic |
| **Supersaw Trance** | 135-145 | Punchy + offbeat | Sub sine | JP-8000 8-voice | Long reverb |
| **Reese Jungle** | 160-180 | Amen chopped | Reese (±7 cents) | Ambient | Bitcrush |
| **Prog Synth 70s** | 100-130 | Motorik | Minimoog fat | String machine | Analog drift |

---

## Detailed Genre Breakdowns

### 1. Ambient Works (Aphex Twin)
**Era**: Late 80s bedroom  
**Emotion**: Nostalgic warmth, dreamy, haunted

**Drums**: Lo-fi breakbeats
- Style: Sampled/synthesized breaks (not 909/808)
- Processing: Bitcrush (12-bit), tape saturation, high-shelf rolloff
- Tempo: 85-95 BPM, shuffled
- Pattern: Hip-hop influenced, sparse

**Bass**: 303 Acid
- Filter: Ladder lowpass, high resonance (0.6-0.8)
- Pattern: 8th notes with slides/accents
- Character: Squelchy, warm, resonant
- Envelope: Fast attack, medium decay

**Pads**: Warm Juno-style
- Oscillators: 3-5 voices, ±8 cent detune
- Filter: Lowpass 800-1500Hz
- LFO: 0.05-0.2Hz on filter (slow movement)
- Chorus: Essential (Juno ensemble effect)

**Effects**:
- Tape saturation: 15-25%
- High-shelf: -3dB
- Reverb: Moderate (0.3-0.5 mix)
- Bit depth: 10-12 bit simulation

**Signature DSP**:
```gdscript
# Tape drift on all oscillators
var drift = sin(2.0 * PI * 0.05 * t) * 0.05  # 5% pitch drift at 0.05Hz
```

---

### 2. Detroit Techno
**Era**: Early 90s Detroit/industrial  
**Emotion**: Relentless drive, cold, mechanical

**Drums**: TR-909
- Kick: 55Hz fundamental, tight punch at 150-200Hz, hard attack
- Snare: Snappy 909, high pitch, NO reverb
- Hi-hats: Relentless 16th notes, open hat on offbeat
- Pattern: 4-on-floor, quantized, no swing

**Bass**: Minimal sub square
- Waveform: Square wave
- Filter: Lowpass 400Hz, resonance 0.6
- Pattern: Single note pulse, minimal movement
- Character: Dark, driving

**Stabs**: Metallic hits
- Source: Detuned saw chord
- Filter: Bandpass 2000Hz
- Decay: 80ms
- Pattern: Offbeat, sparse

**Pads**: Cold digital (optional)
- No analog drift
- Clean filter
- Minimal reverb (0.2-0.4 mix)

**Effects**:
- Dry mix (minimal reverb)
- Heavy compression
- High cut at 12kHz
- Low end focus: 60Hz

**Signature DSP**:
```gdscript
# 909 kick with tight punch
var kick_freq = 55.0 + exp(-t * 35.0) * 80.0  # Fast pitch drop
var kick = sin(2.0 * PI * kick_freq * t) * exp(-t * 10.0)
```

---

### 3. Moroder Disco
**Era**: Late 70s Munich  
**Emotion**: Hypnotic, driving, futuristic

**Drums**: Inside the sequencer
- Kick: Part of 16th-note pulse, not separate
- Style: 4-on-floor implicit in sequencer pattern
- Tempo: 120-128 BPM

**Sequencer**: THE defining element
- Pattern: 16th notes, root-octave-fifth patterns
- Waveform: Saw through Moog filter
- Filter: Slow LFO sweep (0.25-0.5Hz)
- Character: Hypnotic, repetitive, pulsing

**Bass**: Moog ladder
- Filter type: 24dB/oct ladder
- Cutoff: 400-600Hz
- Character: Pulsing sub

**Strings**: String machine pad
- Oscillators: 6-8 voices
- Detune: 6 cents
- Chorus: Heavy (0.5)
- Character: Lush, wide

**Effects**:
- Phaser on strings
- Minimal individual processing
- Mix is mid-focused

**Signature DSP**:
```gdscript
# Moroder 16th-note sequencer as foundation
var step_duration = 60.0 / bpm / 4.0  # 16th notes
var step = int(t / step_duration) % 16
var pattern = [0, 12, 7, 12, 0, 12, 7, 12, 0, 12, 7, 12, 0, 12, 7, 12]
var seq_note = pattern[step]
```

---

### 4. Synthwave
**Era**: Retrofuture 80s (modern recreation)  
**Emotion**: Nostalgic cinema, neon, emotional

**Drums**: LinnDrum with gated reverb
- Snare: THE signature - big room reverb with sharp gate cutoff
- Gate time: 150ms, fast cutoff curve
- Kick: Punchy electronic
- Pattern: Simple 8th note hats

**Arpeggio**: 16th notes
- Delay: Dotted 8th (essential)
- Waveform: Saw + pulse (Juno-60)
- Detune: 12 cents
- Character: Driving, hypnotic

**Pads**: JP-8000 Supersaw
- Oscillators: 7 voices
- Detune: 15-25 cents
- Chorus: Yes
- Reverb: Heavy (0.4-0.5)
- Character: Massive, wide, emotional

**Bass**: Fat analog
- Layers: Saw (60%) + Sub (40%)
- Pattern: Root notes with occasional octave jumps
- Saturation: Light

**Lead**: Soaring, emotional
- Detuned oscillators
- Vibrato: Delayed onset
- Reverb + delay

**Effects**:
- GATED REVERB on drums (essential)
- Chorus on synths
- Long reverb on pads

**Signature DSP**:
```gdscript
# Gated reverb on snare
var gate_length = 0.15  # 150ms
var reverb_env = 0.0
if t < gate_length:
    reverb_env = (1.0 - exp(-t * 15.0)) * (1.0 - t / gate_length)
# Sharp cutoff at gate_length
```

---

### 5. Rave / Breakbeat Hardcore
**Era**: Early 90s UK warehouse  
**Emotion**: Euphoric chaos, raw energy

**Drums**: Chopped breakbeats
- Sources: Amen, Think, Funky Drummer (simulated)
- Processing: Timestretch artifacts, heavy distortion
- Pattern: Syncopated, off-grid energy
- Tempo: 140-160 BPM

**Hoover Bass**: THE signature sound
- Source: Roland Alpha Juno "What The" patch
- Oscillators: Saw + PWM (3 detuned voices)
- Detune: 30-50 cents (massive spread)
- PWM rate: 3Hz, depth 0.2
- Filter: Lowpass resonant 800-2000Hz
- Portamento: Essential for slides
- Distortion: Heavy (0.3-0.6)

**Stabs**: Mentasm/piano stabs
- Character: Offbeat, euphoric
- Processing: Reverb, slight delay
- Pattern: Syncopated

**Effects**:
- Distortion everywhere
- Heavy compression
- Delay throws on vocals

**Signature DSP**:
```gdscript
# Hoover bass - heavily detuned saws
var hoover = 0.0
for detune in [-0.03, 0.0, 0.03]:  # ±3% detune
    var saw = fmod(t * freq * (1.0 + detune), 1.0) * 2.0 - 1.0
    hoover += saw
hoover = tanh(hoover * 1.5)  # Distortion
```

---

### 6. French Touch (Daft Punk)
**Era**: Late 90s Paris  
**Emotion**: Disco filtered, groove, cool

**Drums**: Disco 4-on-floor
- Kick: Clean, punchy
- Open hat: Offbeats
- Pattern: Classic disco

**Bass**: Filter disco
- Character: Sidechained, pumping
- Filter: Heavy lowpass sweep
- LFO: 0.25Hz on filter
- Distortion: Light (0.2)

**Duck Lead**: THE signature "quack"
- Filter: Bandpass, HIGH resonance (0.8)
- Cutoff: 1200-1500Hz
- Envelope: Very fast (5ms attack, 50ms decay)
- Character: Resonant "duck" sound

**Chiff**: Wavetable double-hit
- Short percussive synth hits
- Decay: 80ms
- Character: Adds rhythm

**Vocoder Pad**: Warm, robotic
- Bands: 16+
- Character: Robot voice

**Effects**:
- SIDECHAIN pumping (essential)
- Filter automation
- Light reverb

**Signature DSP**:
```gdscript
# Sidechain ducking from kick
var beat_pos = fmod(t * bpm / 60.0, 1.0)
var sidechain = 1.0 - exp(-beat_pos * 8.0) * 0.6  # Duck on beat
```

---

### 7. Boards of Canada
**Era**: Late 90s Scottish lo-fi  
**Emotion**: Nostalgic, VHS childhood, haunted

**Drums**: Lo-fi hip-hop influenced
- Style: Sparse, humanized timing (±10ms)
- Processing: Bitcrush (10-12 bit), tape saturation
- Pattern: Simple boom-bap

**Bass**: Warm sub
- Filter: 400Hz lowpass
- Drift: 4-6% pitch variation
- Character: Deep, warm, unstable

**Pads**: Tape-warped poly
- Oscillators: 4+ voices
- Detune: 15 cents
- Drift: 8-12% (HEAVY pitch instability)
- LFO: 0.15Hz (very slow wow/flutter)
- High-shelf: -4dB (rolled off highs)

**Melody**: Simple, childlike
- Dotted 8th delay
- Pitch drift
- Lo-fi processing

**Texture**: Tape noise
- Bitcrush: 10-bit
- Random crackle
- Hiss layer

**Effects**:
- Bitcrush on EVERYTHING
- Tape saturation
- High-shelf rolloff
- Slow pitch drift

**Signature DSP**:
```gdscript
# Tape wow/flutter
var drift = sin(2.0 * PI * 0.15 * t) * 0.08  # 8% drift at 0.15Hz
var freq_drifted = freq * (1.0 + drift)
# Bitcrush
sample = floor(sample * 512.0) / 512.0  # ~10-bit
```

---

### 8. Burial
**Era**: Mid 00s South London  
**Emotion**: Melancholic urban, ghostly, rainy

**Drums**: 2-step garage
- Pattern: Shuffled, kick avoids beat 1
- Timing: "Minute hesitations" (±15ms humanize)
- Processing: Fuzzy, phased
- Style: Sparse, syncopated

**Bass**: UK garage sub
- Filter: 120Hz lowpass
- Character: "Warm and earthy, like underground train"
- Distortion: Light saturation
- Width: MONO

**Atmosphere**: Dark reverb wash
- Reverb: Very long (6+ seconds)
- Pre-delay: 80ms
- Character: Cavernous, dark

**Pitched Vocals**: Timestretched R&B
- Processing: Pitch-shifted down (-5 semitones typical)
- Bitcrush: Light
- Reverb: Heavy
- Character: Ghostly, ethereal

**Crackle**: Vinyl noise (constant)
- Density: 0.4% pops, 0.1% bigger pops
- Constant low hiss

**Effects**:
- Vinyl crackle throughout
- Long dark reverb
- Phaser on drums
- "Fuzz" via waveshaping

**Signature DSP**:
```gdscript
# Vinyl crackle
var crackle = (randf() - 0.5) * 0.01  # Constant hiss
if randf() < 0.004: crackle += (randf() - 0.5) * 0.12  # Pop
if randf() < 0.001: crackle += (randf() - 0.5) * 0.25  # Big pop
```

---

### 9. Kraftwerk
**Era**: Late 70s/80s Germany  
**Emotion**: Robotic, precise, futuristic

**Drums**: Electronic, precise
- Style: Quantized, NO swing
- Character: Clean, synthetic
- Pitch envelope: On hits

**Sequencer**: Precise, stable
- Modulation: ZERO
- Drift: ZERO (stable pitch)
- Pattern: Hypnotic 16th notes
- Filter: 2000Hz with resonance

**Bass**: Minimoog Model D
- Filter: 600Hz ladder
- Drift: Only 2% (slight analog)
- Character: Clean, stable

**Vocoder**: Essential
- Bands: 16
- Character: Robot voice

**Lead**: Minimoog
- Vibrato: 5Hz at 0.8% depth (subtle)
- Character: Clean, melodic

**Effects**:
- CLEAN (no distortion)
- Minimal reverb
- Precision is the aesthetic

**Signature DSP**:
```gdscript
# NO modulation, precise timing
var freq = target_freq  # No drift
var square = sign(sin(2.0 * PI * freq * t))
// Quantized timing - no humanization
```

---

### 10. Supersaw Trance
**Era**: Late 90s/early 00s  
**Emotion**: Uplifting, euphoric, massive

**Drums**: Punchy trance
- Kick: Sub + punch, tight
- Pattern: Offbeat hats essential

**Pads**: JP-8000 Supersaw
- Oscillators: 8 voices
- Detune: 25+ cents (MASSIVE spread)
- Attack: 0.3s (slow build)
- Release: 2s+ (long tail)
- Reverb: 4+ seconds
- Character: Wall of sound

**Bass**: Sub sine
- Filter: 120Hz
- Character: Pure sub, no harmonics
- Sidechain: Light

**Arp**: 16th notes
- Oscillators: 3 voices
- Delay: Essential

**Effects**:
- Long reverb on EVERYTHING
- Sidechain pumping
- Buildup FX (risers, sweeps)

**Signature DSP**:
```gdscript
# 8-voice supersaw
var detune_amounts = [-0.06, -0.04, -0.02, -0.01, 0.01, 0.02, 0.04, 0.06]
var supersaw = 0.0
for detune in detune_amounts:
    var detuned_freq = freq * (1.0 + detune * 0.1)
    supersaw += fmod(t * detuned_freq, 1.0) * 2.0 - 1.0
supersaw /= detune_amounts.size()
```

---

## Implementation Checklist

When implementing a genre, ensure:

1. **[ ] Kick character matches genre**
   - 808 long sub (hip-hop, trap)
   - 909 punch (house, techno)
   - Breakbeat (jungle, rave, ambient works)
   - LinnDrum gated (synthwave, 80s)
   - Minimal/soft (ambient techno)

2. **[ ] Bass synthesis matches genre**
   - 303 acid (ambient works, acid)
   - Moog ladder (prog, disco)
   - Reese (jungle, DnB)
   - Hoover (rave)
   - Sub sine (trance, modern EDM)
   - UK garage (burial)

3. **[ ] Pad character matches genre**
   - Supersaw JP-8000 (trance, synthwave)
   - Juno chorus (lo-fi house, ambient works)
   - String machine (disco, prog)
   - Tape-warped (BoC)
   - Dark reverb (burial)
   - Vocoder (Kraftwerk, French touch)

4. **[ ] Effects chain matches genre**
   - Tape saturation (lo-fi genres)
   - Digital clean (techno, Kraftwerk)
   - Vinyl crackle (Burial, BoC)
   - Gated reverb (synthwave, 80s pop)
   - Long reverb (trance, ambient)
   - Sidechain (French touch, modern EDM)

5. **[ ] Tempo & groove match**
   - Quantized (Kraftwerk, techno)
   - Shuffled (house, garage)
   - Humanized (Burial, BoC)
   - Breakbeat chopped (rave, jungle)

---

## References

- SYNTH_RESEARCH.md - Detailed synthesis techniques
- SynthConfigRegistry.gd - Parameter configurations per genre
- Song JSON files in parameters/songs/ - Full metadata
