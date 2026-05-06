# Genre Synthesis Reference

**Source**: Research files at `ada_the_research/music_tracks/*.md`

Quick reference for what makes each genre sonically distinct with **exact parameters** from research.

---

## Quick Reference Matrix

| Genre | BPM | Kick | Bass | Pad | Effects |
|-------|-----|------|------|-----|---------|
| **Ambient Works** | 90-120 | Lo-fi break | 303: 800Hz, res 0.8, LFO 2Hz | 5 voice, 8¢ | 12-bit, tape sat |
| **Detroit Techno** | 120-130 | 909 punch | Sub: 150Hz cutoff | ZERO detune | Clean, +2dB high |
| **Synthwave** | 80-118 | LinnDrum gated | 2 voice, 5¢, 600Hz | 7 voice, 15¢ | Gated reverb 1.5s |
| **Rave** | 140-160 | Breakbeat | Hoover: **40¢ detune** | 4 voice, 25¢ | Distortion 0.3 |
| **French Touch** | 110-130 | Disco 4/4 | 400Hz, LFO 0.25Hz | Vocoder | **Sidechain** |
| **Boards of Canada** | 80-110 | Lo-fi hip-hop | 400Hz, 4% drift | 4v, **15¢, 12% drift** | **10-bit**, -4dB shelf |
| **Burial** | 130 | 2-step (**not quantized**) | **120Hz MONO +6dB** | 3v, 8¢, long reverb | **Vinyl crackle** always |
| **Kraftwerk** | 110 | Electronic clean | 600Hz, **2¢ only** | Vocoder 16 bands | **ZERO distortion** |
| **Supersaw Trance** | 138-145 | Trance punch | **Sub only 120Hz +6dB** | **8 voice, 25¢** | Reverb 4s |
| **Reese Jungle** | 160-180 | Amen break | **35¢ detune**, LFO 0.25Hz | Ambient | Light distort |
| **Lo-Fi House** | 115-125 | 12-bit dusty | Juno DCO, 500Hz, 3¢ | 4v, 5¢, chorus 0.5 | Tape sat, -3dB shelf |

---

## Detailed Specs from Research

### Detroit Techno
**Source**: `detroit_techno.md`

> "Detroit techno is like George Clinton and Kraftwerk caught in an elevator." — Derrick May

**Digital Pad**:
- 4-voice unison
- **Zero detune** - clean and precise
- **Zero drift** - stable pitch
- Filter: 3500Hz
- Attack: 0.5s, Sustain: 0.7
- Reverb: 0.4 mix
- Stereo: 1.1x

**808 Sub Bass**:
- Cutoff: **150Hz**
- Attack: 0.001s
- Decay: 0.3s
- Sustain: 0.5
- Sub level: **+3dB**

**Chord Stab**:
- Attack: **0.001s**
- Decay: **0.08s**
- Sustain: **0** (purely percussive)
- Filter: 2000Hz
- Resonance: 0.5

**909 Drums**:
- High shelf: **+2dB** for brightness
- Tight, quantized
- "Machine funk" programming

---

### Burial
**Source**: `burial.md`

> "I know when I'm happy with my drums because they look like a nice fishbone." — Burial

**UK Garage Sub Bass**:
- Cutoff: **120Hz**
- **MONO** - sub should be centered
- Sub level: **+6dB**
- Attack: 0.01s
- Decay: 0.4s
- Sustain: 0.5
- Character: "Distorted and heavy, yet warm"

**Dark Atmosphere Pad**:
- 3-voice, 8 cent detune
- Filter: 1500Hz
- Resonance: 0.15 (not aggressive)
- Attack: **1.5s** (very slow)
- Release: **3.0s**
- Reverb: **0.7 mix, 6s decay**, predelay 0.08s
- High shelf: -3dB

**Pitched Vocals**:
- Pitch shift: **-5 semitones**
- Bit crushing: **14-bit**
- Heavy reverb: 0.5 mix
- Delay: 0.5s, 30% mix

**Vinyl Crackle**:
- **Always present**
- Pink noise at **-15dB**
- Pop density: 0.4%

**2-Step Drums**:
- **NOT quantized** - "minute hesitations and slippages"
- "Fishbone" waveform look
- Snares/hats: "covered in fuzz and phaser, like cobwebs"

---

### Ambient Works (Aphex Twin)
**Source**: `ambient_works.md`

> "Tracks my mates like to chill out to." — Richard D. James

**FM Keys**:
- Filter: 2000Hz
- Attack: 0.01s
- Decay: 0.3s
- Tape saturation: **0.15**
- Oscillator drift: 0.05
- Reverb: 0.3 mix

**Warm Pad**:
- **5-voice** unison
- Detune: **8 cents**
- Filter: 1500Hz
- Attack: **1.5s**
- Release: **2.0s**
- Chorus: **0.4**
- Reverb: 0.5 mix
- Stereo: 1.2x

**303 Acid Bass**:
- Filter type: **Ladder**
- Cutoff: **800Hz**
- Resonance: **0.8** (high!)
- Attack: 0.001s
- Decay: 0.15s
- Sustain: 0.3
- Filter LFO: **2Hz rate, 0.4 depth**
- Distortion: 0.25

**Lo-Fi Drums**:
- Bit depth: **12-bit**
- Distortion: 0.1
- High-shelf: **-3dB**

---

### Boards of Canada
**Source**: `boards_of_canada.md`

> "Sounding as though produced on malfunctioning equipment excavated from the ruins of an early-'70s computer lab."

**Warbly Tape-Degraded Pad**:
- **4-voice** unison
- Detune: **15 cents** (heavy)
- Pitch drift: **12%** (heavy oscillator instability)
- Filter: 800Hz (warm)
- Resonance: 0.2
- Attack: 0.8s
- Release: 2.0s
- **LFO: 0.15Hz at 8% depth** (very slow wow/flutter)
- Tape saturation: 0.2
- Chorus: 0.15
- High shelf: **-4dB** (rolled off highs)
- Stereo: 0.8x (slightly narrow)

**Melodic Sequence**:
- Mono, 8% drift
- Filter: 1200Hz
- Tape distortion: 0.15
- **Dotted eighth delay: 0.333s**, 35% mix
- High shelf: **-6dB**

**Warm Bass**:
- Filter: 400Hz
- Drift: **4%**
- Light distortion: 0.1

**Texture/Noise**:
- **10-bit** crushing
- Distortion: 0.25
- VHS/cassette crackle

**Lo-Fi Drums**:
- **12-bit**
- Distortion: 0.2
- High shelf: -3dB
- Hip-hop influenced (~100 BPM)

---

### Rave
**Source**: `rave.md`

**Hoover Bass (Mentasm)**:
- Source: Roland Alpha Juno "What The" preset
- **3-voice** minimum
- **EXTREME detune: 40 cents** (!)
- PWM modulation
- Filter: 800Hz
- Resonance: 0.5
- Filter LFO: 3Hz, depth 0.3
- Distortion: **0.3** (heavy)

**Mentasm Chord Stab**:
- 4-voice
- Detune: **25 cents**
- Filter: 2500Hz
- Resonance: 0.4
- Attack: 0.001s
- Decay: 0.15s
- Sustain: 0.3

**Drums**:
- Breakbeat foundation
- Tempo: **140-160 BPM**
- Distortion: 0.15
- Heavy compression

---

### Kraftwerk
**Source**: `kraftwerk.md`

> "We are not artists, we are workers." — Ralf Hütter

**Minimoog Bass**:
- Dual detuned sawtooth
- Filter: **600Hz** (ladder)
- Resonance: 0.35
- Drift: **2 cents only** (minimal analog character)
- Distortion: **0** (clean!)

**Sequencer Lines**:
- Square wave
- Filter: 2000Hz with resonance
- Attack: 0.001s
- Decay: 0.08s
- **ZERO modulation** - precise!
- **ZERO drift** - stable pitch

**Vocoder Pad**:
- 6-voice
- **16 vocoder bands**
- Filter: 3000Hz
- Resonance: 0.4
- Subtle chorus for width

**Lead Melody**:
- Filter: 3500Hz (bright)
- Vibrato: **5Hz at 0.008 depth** (very subtle)
- Drift: 1.5 cents

**Electric Percussion**:
- Pitch envelope on hit
- Decay: 0.15s
- **Zero distortion** - clean

---

### Synthwave
**Source**: `synthwave.md`

**Arpeggio (Juno-60 Style)**:
- 4-voice
- Detune: **12 cents**
- Filter: 3000Hz
- Resonance: 0.3
- **Chorus: 0.4** (essential Juno sound)
- Delay: **0.375s (dotted eighth)**, 25% mix

**Saw Bass**:
- 2-voice
- Detune: **5 cents**
- Filter: 600Hz
- Resonance: 0.4

**Supersaw Lead**:
- **7-voice** (like JP-8000)
- Detune: **15 cents**
- Filter: 4500Hz
- Vibrato: **5.5Hz at 0.02 depth**
- Delay: 0.35s, 35% mix
- Reverb: 0.4 mix
- Stereo: **1.4x**

**LinnDrum / Gated Reverb**:
- Reverb: **0.6 mix**
- Decay: **1.5s** (then gated)
- 80s character

---

### French Touch
**Source**: `french_touch.md`

**Filter Disco Bass**:
- Cutoff: **400Hz**
- Resonance: **0.6**
- LFO: **0.25Hz, depth 0.5**
- Distortion: 0.2

**Duck/Quack Lead** (Daft Punk signature):
- **BANDPASS filter** (not lowpass!)
- Cutoff: **1500Hz**
- Resonance: **0.8** (creates "wah")
- Attack: 0.001s
- Decay: **0.05s**
- Sustain: 0.2

**Chiff (Wavetable)**:
- Filter: 5000Hz
- Attack: 0.001s
- Decay: **0.08s**
- Sustain: **0** (purely percussive)

**Drums**:
- Four-on-the-floor
- Tempo: **120 BPM** (classic)
- **Sidechain compression** essential

---

### Supersaw Trance
**Source**: `supersaw_trance.md`

> "The Supersaw was the reason why the JP-8000 was particularly successful in the dance music market."

**Supersaw Pad**:
- **8-voice** unison
- Detune: **25 cents**
- Filter: 6000Hz (very bright)
- Resonance: 0.2
- Attack: **0.3s**
- Sustain: 0.9
- Release: **2.0s**
- Reverb: **0.5 mix, 4s decay**
- Stereo: **1.5x**

**Supersaw Lead**:
- 7-voice
- Detune: 18 cents
- Filter: 8000Hz

**Trance Sub Bass**:
- **Pure sub** (sine)
- Cutoff: **120Hz**
- Sub level: **+6dB**

**Arp**:
- 3-voice
- 8 cent detune
- Delay: **0.1875s** (dotted 16th), 40% mix

**Drums**:
- Tempo: **138-145 BPM**
- "Driving" pattern

---

### Reese Jungle
**Source**: `reese_jungle.md`

**Reese Bass**:
- **2-voice**
- Detune: **35 cents** (heavy!)
- Filter: 600Hz
- Resonance: 0.4
- LFO: **0.25Hz, depth 0.3** on filter
- Sub: **+3dB**
- Distortion: 0.2

**Amen Break**:
- Tempo: **170 BPM**
- Timestretched
- Light distortion: 0.1

**Bitcrushed Stab**:
- **10-bit**
- Filter: 3000Hz

**Ambient Pad**:
- Filter: 2000Hz
- Attack: 1.0s
- Reverb: 0.7 mix, 5s decay

---

### Lo-Fi House
**Source**: `lofi_house.md`

**Juno DCO Bass**:
- Saw + Square blend
- PWM modulation
- Filter: **500Hz**
- Resonance: 0.5
- Attack: 0.001s
- Decay: 0.15s
- Sustain: 0.3
- Drift: **3 cents**
- Tape saturation: 0.1

**Juno Chorused Pad**:
- 4-voice
- Detune: **5 cents**
- Filter: 1800Hz
- **Chorus: 0.5 depth, 0.8 rate** (BBD emulation)
- Drift: 2 cents

**Dusty Drums**:
- Tempo: **118 BPM**
- **12-bit** bitcrush
- Distortion: **0.15**
- High shelf: **-3dB**

---

## Implementation Checklist

When implementing a genre, verify these EXACT parameters from research:

### Drums
- [ ] Detroit: +2dB high shelf, tight/quantized
- [ ] Burial: NOT quantized, fuzz/phaser on hats
- [ ] Synthwave: Gated reverb 1.5s decay
- [ ] BoC: 12-bit, -3dB high shelf
- [ ] Kraftwerk: ZERO distortion

### Bass
- [ ] 303 Acid: 800Hz cutoff, 0.8 resonance, 2Hz LFO
- [ ] Reese: 35 cent detune, 0.25Hz filter LFO
- [ ] Hoover: 40 cent detune (!), 3Hz LFO
- [ ] Burial sub: 120Hz, MONO, +6dB
- [ ] Kraftwerk: Only 2 cent drift

### Pads
- [ ] Supersaw: 8 voices, 25 cent detune
- [ ] BoC: 15 cent detune, 12% pitch drift, 0.15Hz LFO
- [ ] Detroit: ZERO detune, ZERO drift
- [ ] Synthwave: 7 voices, 15 cent, 5.5Hz vibrato

### Effects
- [ ] Burial: Vinyl crackle always, -15dB pink noise
- [ ] BoC: 10-bit crushing, -4dB high shelf
- [ ] Kraftwerk: Clean (no distortion)
- [ ] French Touch: Sidechain pumping

---

## References

- Research files: `ada_the_research/music_tracks/*.md`
- SynthConfigRegistry.gd - Parameter configurations
- GenreDSP.gd - Exact implementation
