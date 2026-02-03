# Soundbank Architecture — Genre-Isolated Procedural Music

## The Problem

All procedural tracks sounded similar because they shared the same:
- Synthesis primitives (same kick formula, same bass formula)
- Arrangement patterns (4-on-floor for everything)
- Dynamics (same velocity, same feel)
- Processing (parameters differed but code was shared)

It was easy to accidentally use "synthwave supersaw" in a "detroit techno" track because they pulled from the same code.

**Result**: Tracks had different timbres but the same *identity*.

---

## The Solution: Isolated Soundbanks

**Each genre gets its own soundbank — no sharing, no contamination.**

A Detroit Techno generator literally *cannot* use a rave hoover because that sound doesn't exist in its soundbank. The isolation is architectural, not just parametric.

---

## What Makes a Genre Sound Like Itself?

We identified multiple dimensions that create genre identity:

### 1. Sound Design (Timbre)
The actual synthesis — what oscillators, filters, effects.

| Genre | Key Sounds |
|-------|------------|
| Detroit Techno | 909 drums, 808 sub, **ZERO detune** digital pads |
| Synthwave | LinnDrum, **gated reverb** snare, JP-8000 **supersaw** (15¢ detune) |
| Burial | 2-step drums, **vinyl crackle**, mono sub, **-5 semitone** vocals |
| Boards of Canada | **Tape wow** (0.15Hz LFO), **15¢ detune**, **10-bit** crush |
| Rave | **Hoover** (40¢ detune!), mentasm stabs, **heavy distortion** |
| Kraftwerk | **ZERO modulation**, vocoder, **only 2¢** drift |

### 2. Drum Patterns (Rhythm)
The actual beat — where kicks, snares, hats land.

| Genre | Pattern Type |
|-------|--------------|
| Detroit Techno | 4-on-floor, kick on every beat |
| Burial | **2-step** — kick avoids beat 1! |
| Rave | Pounding 8th-note kicks |
| Kraftwerk | Motorik — steady pulse, driving 8th hats |
| BoC | Hip-hop influenced, lazy, sparse |

### 3. Velocity/Dynamics (Feel)
How loud each hit is, how much variation.

| Genre | Character |
|-------|-----------|
| Rave | **Everything 100%**, no dynamics (crushed) |
| Kraftwerk | **All hits same level** — robotic consistency |
| Burial | Soft with **ghost notes** at 25% |
| BoC | Very soft, **20% random variation** |

### 4. Swing (Groove)
Whether off-beats are delayed.

| Genre | Swing |
|-------|-------|
| Kraftwerk | 0% — machine precision |
| Burial | 12% — UK garage shuffle |
| BoC | 18% — lazy hip-hop |

### 5. Bass Patterns (Low-End Rhythm)
Not just "bass plays" but *when* and *how*.

| Genre | Pattern |
|-------|---------|
| Detroit | Locked to kick, sustained |
| Burial | Offbeat hits, sparse |
| Rave | Continuous drone/slide |
| Kraftwerk | Staccato, short notes |

### 6. Song Structure (Arrangement)
Section order, lengths, energy arc.

| Genre | Structure |
|-------|-----------|
| Synthwave | intro → verse → **chorus** → verse → **chorus** → outro |
| Rave | intro → build → **drop** → breakdown → **drop** → outro |
| BoC | intro → main → **interlude** → main → outro |

### 7. Harmonic Progression (Chords)
What chords, how they move.

| Genre | Character |
|-------|-----------|
| Kraftwerk | i - V - i - V (minimal, hypnotic) |
| BoC | i - iii - VI - i (dreamy, nostalgic) |
| Rave | i - i - VI - VI (simple, aggressive) |

### 8. Humanization (Timing Jitter)
Random timing variation per hit.

| Genre | Humanization |
|-------|--------------|
| Kraftwerk | 0ms — perfect machine |
| Burial | 15ms — human, loose |
| BoC | 10ms — slightly wobbly |

---

## Architecture

```
commons/audio/soundbanks/
├── SoundbankLoader.gd           # Loads and validates soundbanks
├── README.md                    # User documentation
│
├── detroit_techno/
│   ├── brief.json               # Identity, patterns, forbidden elements
│   ├── kick.gd                  # TR-909 style
│   ├── snare.gd                 # TR-909 snappy
│   ├── hihat.gd                 # Metallic 909
│   ├── bass.gd                  # 808 sub
│   ├── pad.gd                   # Clean digital (ZERO detune!)
│   └── stab.gd                  # Chord stab
│
├── synthwave/
│   ├── brief.json
│   ├── kick.gd                  # LinnDrum
│   ├── snare.gd                 # GATED REVERB
│   ├── supersaw.gd              # JP-8000 (15¢ detune, 7 voices)
│   └── ...
│
├── burial/
│   ├── brief.json
│   ├── kick.gd                  # 2-step (avoids beat 1)
│   ├── crackle.gd               # ALWAYS PRESENT vinyl noise
│   ├── sub.gd                   # Mono, +6dB
│   └── ...
│
└── ... (rave, kraftwerk, boards_of_canada)
```

### Generator

```
commons/audio/generators/
└── SoundbankGenerator.gd        # Uses soundbanks + patterns to generate songs
```

The generator:
1. Loads the soundbank for the requested genre
2. Gets genre-specific patterns (drums, bass, velocity, swing)
3. Generates section by section using ONLY sounds from that soundbank
4. Applies genre-specific humanization and dynamics

---

## brief.json Structure

Each genre has a `brief.json` that defines its identity:

```json
{
  "meta": {
    "id": "burial",
    "name": "Burial",
    "bpm": { "min": 125, "max": 140, "typical": 130 },
    "lambda": 0.5
  },

  "identity": {
    "token": "Vinyl crackle + 2-step + mono sub",
    "two_second_test": "What you hear immediately",
    "emotional_truth": "South London rain, night bus"
  },

  "soundbank": ["kick", "snare", "hihat", "sub", "atmosphere", "crackle", "vocal"],

  "forbidden": [
    "supersaw",
    "gated_reverb",
    "quantized_drums",
    "bright_highs"
  ],

  "rhythm": {
    "quantize": "loose",
    "humanize_ms": 15,
    "pattern": "2step_garage"
  },

  "sections": {
    "intro": ["crackle", "atmosphere"],
    "main": ["kick", "snare", "hihat", "sub", "atmosphere", "crackle", "vocal"],
    "outro": ["crackle", "atmosphere"]
  }
}
```

---

## Pattern Definitions (in Generator)

Patterns are 16-step arrays (one bar of 16th notes):

```gdscript
const PATTERNS = {
    "burial": {
        # 2-STEP - kick avoids beat 1!
        "kick":  [0,0,1,0, 0,0,0,0, 0,0,1,0, 0,0.5,0,0],
        "snare": [0,0,0,0, 1,0,0,0.5, 0,0,0,0, 1,0,0,0],
        "hihat": [0.5,1,0,0.5, 0,1,0.5,0, 0.5,0,1,0.5, 0,1,0,0.5],
    },
    "kraftwerk": {
        # Motorik - steady, robotic
        "kick":  [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],
        "snare": [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],
        "hihat": [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0],
    },
}
```

Values:
- `0` = silent
- `1` = normal velocity
- `2` = accent (louder)
- `0.5` = ghost note (quiet)

---

## Velocity Configuration

```gdscript
const VELOCITY = {
    "rave": {
        "base": 1.0,       # LOUD
        "accent": 1.0,     # Everything maxed
        "ghost": 0.7,
        "variation": 0.0,  # Crushed, no dynamics
    },
    "boards_of_canada": {
        "base": 0.55,      # Soft, lo-fi
        "accent": 0.75,
        "ghost": 0.2,      # Very quiet ghosts
        "variation": 0.2,  # Most variation
    },
}
```

---

## Testing

Run `commons/audio/catalog/SongDevTools.tscn`

Look for "(Soundbank)" buttons:
- 🔩 Detroit (Soundbank)
- 🌆 Synthwave (Soundbank)
- 🌧️ Burial (Soundbank)
- 📼 BoC (Soundbank)
- ⚡ Rave (Soundbank)
- 🤖 Kraftwerk (Soundbank)

Compare with the original implementations (without "Soundbank" suffix).

---

## Research Sources

All synthesis parameters come from detailed research docs:

```
ada_the_research/music_tracks/
├── detroit_techno.md
├── synthwave.md
├── burial.md
├── boards_of_canada.md
├── rave.md
├── kraftwerk.md
└── ... (17 total)
```

Each doc contains:
- Historical context and key artists
- Equipment lists (synths, drum machines)
- Exact synthesis parameters (detune in cents, filter cutoffs in Hz, attack times)
- Production philosophy
- Recreation tips

---

## Future Work

Additional dimensions that could be added:

1. **Melodic contours** — How melodies move (stepwise vs arpeggiated vs random)
2. **Filter movement** — Per-section filter sweeps
3. **Note lengths** — Staccato vs legato
4. **Octave ranges** — Where sounds sit in frequency
5. **Layer density** — How many sounds play at once
6. **Fills/variations** — Pattern breaks every N bars
7. **Space/reverb character** — Wet vs dry, decay times

---

## Philosophy

The goal is not to perfectly recreate genres — it's to capture what makes them *recognizable*.

When you hear 2 seconds of a track, you should know:
- "That's Detroit" (cold, clean, 909)
- "That's Burial" (crackle, ghost, melancholy)
- "That's Kraftwerk" (robot, precise, motorik)

The "two second test" is the measure of success.

---

*"Each genre is a constrained vocabulary. The constraints create identity."*
