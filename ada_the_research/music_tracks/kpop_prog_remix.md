# K-Pop Prog Remix — Production Research

## Genre Collision Analysis

### Source: 70s Progressive Rock/Electronic
- **Artists:** ELP, Yes, Kraftwerk, Pink Floyd, Tangerine Dream
- **Era:** 1970-1978
- **BPM:** 80-140 (variable within track)
- **Duration:** 7-20 minutes
- **Character:** Cerebral, exploratory, virtuosic, epic

### Target: K-Pop (4th Generation)
- **Artists:** BTS, BLACKPINK, TWICE, Stray Kids, aespa, NewJeans
- **Era:** 2018-present
- **BPM:** 100-128 (fixed)
- **Duration:** 3:00-3:40
- **Character:** Hooky, maximalist, switch-ups, choreo-ready

---

## K-Pop Production Characteristics

### Structure (The Formula)
```
Intro (4-8 bars)     - Hook tease or sound design
Verse 1 (8 bars)     - Sparse production, rap or singing
Pre-Chorus (4 bars)  - BUILD tension, motorik/EDM elements
Chorus (8 bars)      - EVERYTHING, the hook, max energy
Post-Chorus (4 bars) - Optional "na na na" chant or dance break moment
Verse 2 (8 bars)     - Slightly fuller than V1
Pre-Chorus (4 bars)  - Same or intensified
Chorus (8 bars)      - Full power
Bridge (4 bars)      - Strip down, often key change prep
Dance Break (4 bars) - Genre switch-up, showcases
Final Chorus (8 bars)- Key change +1 semitone, maximum
Outro (4 bars)       - Hook callback or hard stop
```

### Key K-Pop Elements
1. **"Kill Parts"** — Iconic 2-4 bar moments assigned to specific members
2. **Switch-Ups** — Genre changes mid-song (verse = trap, chorus = pop)
3. **Chant Hooks** — Group shouts ("hey!", "oh!", made-up words)
4. **Dance Breaks** — Instrumental showcases for choreography
5. **Ad-libs** — Layered "yeah"s, "woo"s, breath sounds
6. **Post-Chorus** — The hook after the hook

### K-Pop Production Sound Palette
| Element | Character | Reference |
|---------|-----------|-----------|
| Kick | 808-style with sub, sidechained | Trap influence |
| Snare | Punchy + layered clap | Modern pop |
| Hi-hats | Trap rolls + rhythmic patterns | Hip-hop crossover |
| Bass | 808 sub + distorted growl | Future bass |
| Synth lead | Supersaw or pluck | EDM influence |
| Pads | Lush, wide, sidechained | Emotional lift |
| Brass/stabs | Punchy, often horn section | Impact |

---

## The Remix Concept: "Prog-Pop"

### What Stays from 70s Prog
1. **Moog lead timbre** — Screaming portamento lead becomes "Kill Part"
2. **Motorik drums** — Kraftwerk precision in Pre-Chorus
3. **Kraftwerk sequencer** — 16th-note pulse in Intro/Outro
4. **Modal harmony** — Dorian mode (E Dorian)
5. **Mellotron atmosphere** — Ghostly strings in Verse
6. **Complex rhythms** — Dance Break has prog-style syncopation

### What Transforms for K-Pop
| 70s Prog | → | K-Pop Remix |
|----------|---|-------------|
| 7+ minutes | → | 3:28 |
| Tempo changes | → | Fixed 118 BPM |
| Odd time sigs | → | 4/4 with fake-outs |
| Extended solos | → | 4-bar Kill Part |
| Cerebral | → | Catchy + cerebral |
| Album listening | → | Choreo-ready |

---

## Sound Design Specifications

### 1. Neo-Moog Lead (Kill Part Sound)
**Reference:** Keith Emerson's screaming Minimoog + modern brightness
```
Oscillators: 3x sawtooth
Detune: [0, +7, -7] cents (slight thickening, not supersaw)
Filter: 24dB lowpass, 2000Hz base, 0.7 resonance
Filter envelope: Attack 10ms, Decay 300ms, Sustain 0.4
Portamento: 80ms (ELP sliding between notes)
Processing: Light distortion, stereo widener
Character: Screaming prog lead, K-pop brightness
```

### 2. Modern Kraftwerk Sequence
**Reference:** "Autobahn" meets EDM build
```
Oscillators: 2x pulse, 50% width
Detune: 3 cents (Kraftwerk precision)
Filter: 1500Hz base, LFO 0.25Hz, depth 800Hz
Pattern: 16th notes, up-down arpeggio
Processing: Sidechain to kick, ping-pong delay (8th notes)
Character: Hypnotic motorik, tension builder
```

### 3. 808 Sub Bass
**Reference:** Modern K-pop/trap hybrid
```
Waveform: Sine
Freq start: 60Hz
Pitch drop: 0.3 octaves
Attack: 5ms, Decay: 400ms
Distortion: 0.2 (warmth)
Processing: Multiband compression, subtle saturation
Character: Clean sub with prog warmth
```

### 4. Supersaw Pad (Chorus Lift)
**Reference:** JP-8000 style, K-pop chorus power
```
Voices: 7
Waveform: Sawtooth
Detune: 25 cents (wide but controlled)
Unison spread: 0.8
Filter: 4000Hz, resonance 0.3
Processing: Hall reverb, sidechain to kick
Character: Anthemic lift, emotional release
```

### 5. Mellotron Pad (Verse Atmosphere)
**Reference:** Yes, Pink Floyd orchestral synth
```
Character: Ghostly strings
Waveform: Filtered noise + saw
Attack: 200ms (slow)
Release: 1000ms
Filter: 1800Hz
Wow/flutter: 8 cents at 0.2Hz (tape character)
Character: Nostalgic, atmospheric, prog DNA
```

---

## Drum Programming

### Verse Pattern (Trap-influenced, 118 BPM)
```
Kick:      [1,0,0,0, 0,0,0,0, 1,0,1,0, 0,0,0,0]
Snare:     [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0]
Hi-hat:    [1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1]
Open hat:  [0,0,0,0, 0,0,0,1, 0,0,0,0, 0,0,0,1]

Swing: 0% | Humanize: 2ms | Velocity variation: 15%
Character: Modern K-pop verse, space for vocals
```

### Pre-Chorus Pattern (Motorik Revival)
```
Kick:      [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0]
Snare:     [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0]
Hi-hat:    [0,0,1,0, 0,0,1,0, 0,0,1,0, 0,0,1,0]
Clap:      [0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1]

Swing: 0% | Humanize: 0ms | Velocity variation: 0%
Character: Kraftwerk precision = K-pop tension
```

### Chorus Pattern (Full Power)
```
Kick:      [1,0,0,0, 0,0,1,0, 1,0,0,0, 0,0,1,0]
Snare:     [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,1]
Clap:      [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0]
Hi-hat:    [1,0,1,1, 0,1,1,0, 1,0,1,1, 0,1,1,0]
808 sub:   [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,1]

Character: K-pop maximalist energy
```

### Dance Break Pattern (Prog Callback)
```
Kick:      [1,0,1,0, 0,1,0,0, 1,0,1,0, 0,1,0,1]
Snare:     [0,0,0,0, 1,0,0,1, 0,0,0,0, 1,0,1,0]
Hi-hat:    [1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1]

Character: 7/8 feel in 4/4 (prog syncopation homage)
```

---

## Harmonic Content

### Key: E minor (Dorian mode)
E Dorian = E F# G A B C# D (raised 6th = hope in darkness)

### Chord Progressions

**Verse (Modal Vamp):**
```
| Em7 | Em7 | Em7 | Em7 |
```
Character: Hypnotic repetition from prog, space for rap/vocals

**Pre-Chorus (Descending Drama):**
```
| Em | D | C | B7 |
  i   VII  VI   V
```
Character: Classic prog descending line, building tension

**Chorus (K-Pop Lift):**
```
| Em | G | D | C |
  i   III VII  VI
```
Character: Relative major movement, anthemic, uplifting

**Bridge (Prog Chromaticism):**
```
| Am | Em | F | G |
  iv   i   ♭II III
```
Character: Borrowed ♭II (Phrygian flavor), dramatic prog moment

### Melody Guidelines

**Verse melody:** Narrow range (E4-G4), rhythmic, rap-friendly
**Chorus hook:** Ascending to climax, B4→G4→A4→B4→D5→E5
**Chant hook:** "Moog-a-Moog-a" on Em chord hits (syncopated)

---

## Arrangement Blueprint

```
Section       | Bars | Elements                              | Energy
--------------+------+---------------------------------------+--------
Intro         | 8    | Kraftwerk sequence fade-in            | Low
Verse 1       | 8    | Trap drums + Mellotron + vocal        | Low-Med
Pre-Chorus    | 4    | Motorik + descending chords + build   | Building
Chorus        | 8    | Full drop + supersaw + hook           | HIGH
Verse 2       | 8    | +808 sub + fuller production          | Med
Pre-Chorus    | 4    | Harder build, filter sweep            | Building++
Chorus        | 8    | Full power                            | HIGH
Dance Break   | 4    | Moog solo (KILL PART) + prog rhythm   | Peak
Bridge        | 4    | Strip to Mellotron + vocal            | Low
Final Chorus  | 8    | Key change to F minor, maximum        | MAXIMUM
Outro         | 4    | Return to Kraftwerk sequence          | Fade
--------------+------+---------------------------------------+--------
Total         | 68   | @ 118 BPM = ~3:28                     |
```

---

## Technical Implementation

### File Locations
```
commons/audio/soundbanks/kpop_prog/
├── brief.json           # Soundbank definition
├── neomoog_lead.gd      # Kill part lead
├── kraftwerk_seq.gd     # Intro/outro sequence
├── kpop_808.gd          # Modern sub bass
├── supersaw_pad.gd      # Chorus lift
└── mellotron_pad.gd     # Verse atmosphere

commons/audio/generators/AudioSynthesizer.gd
└── generate_kpop_prog_song()  # Main generator function
    └── _generate_kpop_prog_section()  # Section renderer
```

### Integration
- Add to `SongPreviewDesktop.gd` song list
- Add to `SongDevTools.gd` for parameter tweaking
- JSON config: `parameters/songs/kpop_prog_remix.json`

---

## The Thesis

**Prog-Pop proves that 70s cerebral experimentation and K-pop's ruthless hookiness aren't opposites—they're the same impulse to push boundaries, just in different directions.**

The Moog scream becomes a kill part.
The motorik pulse becomes a pre-chorus build.
The 7-minute journey compresses into a 3:28 explosion.

Same energy. New grammar.

---

*Research compiled: 2026-02-08*
*Skills invoked: ada-music-producer, ada-beat-maker, ada-top-liner, ada-sound-engineer*
