# Music Production Brief for Ada Skills

**For:** ada-sound-engineer, ada-music-producer, ada-top-liner, ada-beat-maker

This document explains how to create new songs and soundbanks for AdaResearch's procedural audio system.

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                      SONG GENERATION FLOW                            │
└─────────────────────────────────────────────────────────────────────┘

    ┌──────────────────┐      ┌──────────────────┐
    │   brief.json     │      │   sound.gd       │
    │   (identity)     │      │   (synthesis)    │
    └────────┬─────────┘      └────────┬─────────┘
             │                         │
             └──────────┬──────────────┘
                        ▼
              ┌──────────────────┐
              │ SoundbankLoader  │  Loads genre, validates sounds
              └────────┬─────────┘
                       ▼
              ┌──────────────────┐
              │SoundbankGenerator│  Builds sections, patterns, songs
              └────────┬─────────┘
                       ▼
              ┌──────────────────┐
              │AudioStreamInter- │  Playable multi-section song
              │     active       │
              └──────────────────┘
```

---

## File Structure

```
commons/audio/
├── soundbanks/                     # GENRE DEFINITIONS
│   ├── {genre}/
│   │   ├── brief.json              # Identity, sections, forbidden
│   │   ├── kick.gd                 # Individual sound scripts
│   │   ├── snare.gd
│   │   ├── bass.gd
│   │   ├── pad.gd
│   │   └── ...
│   └── README.md
│
├── generators/
│   ├── SoundbankGenerator.gd       # Main song builder (PATTERNS, STRUCTURES, HYBRIDS)
│   ├── SoundbankLoader.gd          # Loads and validates soundbanks
│   ├── AudioSynthesizer.gd         # Low-level synthesis
│   └── ...
│
├── catalog/
│   ├── SongDevTools.gd             # Interactive song testing UI
│   ├── SongPreviewDesktop.gd       # Simpler preview UI
│   └── ui/
│       └── SongTimeline.gd         # Timeline with layer display
│
├── parameters/songs/               # Song configuration JSONs
│   └── {genre}_{song_name}.json
│
└── documentation/
    └── SYNTH_ELEMENTS.md           # Deep synthesis reference
```

---

## Current Soundbanks

| Genre | Key Sounds | Character | λ |
|-------|------------|-----------|---|
| `ada_theme` | pad, bass, drums | Warm, supportive, space for vocal | 0.5 |
| `aphex_twin` | kick, snare, hihat, bass, pad, sequence, texture | Detuned, lo-fi breaks, tape warmth | 0.55 |
| `boards_of_canada` | texture, sequence, pad, bass, drums | Nostalgic, wobbly, degraded | 0.55 |
| `burial` | kick, snare, hihat, sub, crackle, atmosphere, vocal | Dark, 2-step, vinyl noise | 0.5 |
| `detroit_techno` | kick, snare, hihat, clap, bass, pad, stab | Cold, precise, machine funk | 0.2 |
| `gypsy_woman_house` | kick, snare, hihat, clap, bass, piano, organ, pad | Bouncy, soulful, offbeat piano | 0.4 |
| `kraftwerk` | kick, snare, hihat, bass, sequence, vocoder | Robotic, precise, minimal | 0.15 |
| `madonna_80s` | kick, snare, hihat, bass, pad, arp, lead | Pop, gated reverb, bright | 0.35 |
| `moroder_disco` | kick, snare, hihat, clap, bass, sequence, strings | Hypnotic, sequenced, euphoric | 0.3 |
| `rave` | kick, snare, hihat, bass, hoover, stab | Aggressive, hoover bass, breakbeats | 0.45 |
| `synthwave` | kick, snare, hihat, bass, pad, arp, lead | 80s, supersaw, gated reverb | 0.3 |
| `vangelis_cs80` | pad (vp330, prophet, cs80), brass, strings, arp | Cinematic, lush, Blade Runner | 0.35 |

---

## Creating a New Soundbank

### Step 1: Create Folder Structure

```bash
commons/audio/soundbanks/{your_genre}/
├── brief.json
├── kick.gd
├── snare.gd
├── hihat.gd
├── bass.gd
├── pad.gd
└── ... (other sounds)
```

### Step 2: Write brief.json

```json
{
  "meta": {
    "id": "your_genre",
    "name": "Display Name",
    "lineage": "Key artists - Influence description",
    "era": "Time period",
    "bpm": { "min": 100, "max": 130, "typical": 120 },
    "lambda": 0.4
  },

  "identity": {
    "token": "The signature sound (what makes it recognizable in 2 seconds)",
    "two_second_test": "What you hear immediately when the track starts",
    "emotional_truth": "What it makes you feel"
  },

  "soundbank": ["kick", "snare", "hihat", "bass", "pad"],

  "forbidden": [
    "sound_that_would_contaminate_identity",
    "another_forbidden_sound"
  ],

  "rhythm": {
    "quantize": "strict",
    "humanize_ms": 0,
    "swing_pct": 0
  },

  "harmony": {
    "scales": ["minor", "dorian"],
    "voicings": "style_description"
  },

  "fx": {
    "sidechain": false,
    "reverb_style": "plate"
  },

  "transitions": {
    "crossfade_s": 2.0
  },

  "sections": {
    "intro": ["pad"],
    "build": ["pad", "bass", "hihat"],
    "main": ["kick", "snare", "hihat", "bass", "pad"],
    "breakdown": ["pad"],
    "outro": ["pad"]
  }
}
```

### Step 3: Write Sound Scripts

Each sound is a GDScript class:

```gdscript
# your_genre/kick.gd
# Character: Description of the sound
# Source: Hardware/technique reference (e.g., "TR-909", "LinnDrum")
# Processing: Effects chain description

extends RefCounted

const SAMPLE_RATE = 44100.0

# Parameters (document research source)
const PUNCH_HZ = 150.0      # From detroit_techno.md
const BODY_HZ = 50.0
const ATTACK_MS = 3.0
const DECAY_MS = 200.0

static func generate(t: float, freq: float = 0.0, params: Dictionary = {}) -> float:
    var sample = 0.0
    
    # Attack transient (punch)
    var attack_env = exp(-t / (ATTACK_MS / 1000.0))
    sample += sin(TAU * PUNCH_HZ * t) * attack_env
    
    # Body (sub)
    var body_env = exp(-t / (DECAY_MS / 1000.0))
    sample += sin(TAU * BODY_HZ * t) * body_env * 0.8
    
    return clamp(sample, -1.0, 1.0)

static func get_duration() -> float:
    return 0.3  # seconds
```

---

## Adding to SoundbankGenerator

After creating the soundbank, add support in `SoundbankGenerator.gd`:

### 1. Add Drum Pattern

```gdscript
# In PATTERNS constant (around line 50)
"your_genre": {
    "kick":  [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],
    "snare": [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],
    "hihat": [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0],
}
```

### 2. Add Bass Pattern

```gdscript
# In BASS_PATTERNS constant
"your_genre": {
    "pattern": [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],
    "style": "sustained",  # or "short", "continuous"
}
```

### 3. Add Swing Amount

```gdscript
# In SWING constant
"your_genre": 0.0,  # 0-20, percentage
```

### 4. Add Velocity Curve

```gdscript
# In VELOCITY constant
"your_genre": {
    "base": 0.8,
    "accent": 1.0,
    "ghost": 0.4,
    "variation": 0.1,
}
```

### 5. Add Structure

```gdscript
# In STRUCTURES constant
"your_genre": {
    "sections": ["intro", "build", "main", "breakdown", "main", "outro"],
    "bars": [8, 8, 16, 8, 16, 8],
}
```

---

## Creating Hybrid Songs

Hybrid songs combine sounds from multiple soundbanks:

```gdscript
# In HYBRID_CONFIGS constant (around line 470)
"your_hybrid": {
    "primary_bank": "genre_a",
    "secondary_bank": "genre_b",
    "bpm": 120,
    "description": "Genre A × Genre B - conceptual description",
    "sound_sources": {
        "piano": "genre_a",
        "pad": "genre_a",
        "kick": "genre_b",
        "hihat": "genre_b",
        "sequence": "genre_b",
    },
    "section_sounds": {
        "intro": ["pad", "piano"],
        "verse": ["kick", "hihat", "pad", "piano"],
        "main": ["kick", "hihat", "sequence", "pad"],
        "outro": ["pad"],
    },
}
```

---

## Adding to UI (SongDevTools / SongPreviewDesktop)

### 1. Add to Song List

In `SongDevTools.gd` around line 1530, add your song to the match statement:

```gdscript
"your_genre":
    stream = SoundbankGenerator.generate_song("your_genre", {})

# Or for hybrids:
"your_hybrid":
    stream = SoundbankGenerator.generate_hybrid_song("your_hybrid", {})
```

### 2. Add Layer Descriptions (for timeline display)

In `SongDevTools.gd` function `_get_layers_for_song()`:

```gdscript
"your_genre":
    return {
        "intro": [
            {"name": "Warm Pad", "type": "pad", "params": "voices: 5 | detune: ±8 cents"},
        ],
        "main": [
            {"name": "Kick", "type": "drums", "params": "909 style | punchy"},
            {"name": "Snare", "type": "drums", "params": "2 & 4"},
            {"name": "Bass", "type": "bass", "params": "sub | following root"},
            {"name": "Pad", "type": "pad", "params": "warm bed"},
        ],
        "default": [{"name": "Your Genre", "type": "mix", "params": "BPM | key"}]
    }
```

Same for `SongPreviewDesktop.gd` in `_get_layers_for_song()`.

---

## Testing Your Song

### Using SongDevTools

1. Open `commons/audio/catalog/SongDevTools.tscn` in Godot
2. Select your song from the dropdown
3. Click Play
4. Watch the timeline for section transitions
5. Check console for generation logs

### Verification Checklist

- [ ] All sounds in soundbank array have corresponding `.gd` files
- [ ] `brief.json` is valid JSON
- [ ] Section names in brief.json match STRUCTURES
- [ ] No forbidden sounds are used
- [ ] Pattern arrays are 16 elements (one bar of 16th notes)
- [ ] Passes the "two-second test" - sounds like the genre immediately

---

## Synthesis Quick Reference

### Oscillator Types

| Type | Character | Use For |
|------|-----------|---------|
| Sine | Pure, clean | Sub bass, pads |
| Saw | Bright, aggressive | Leads, basses, pads |
| Square | Hollow, punchy | Chiptune, basses |
| Triangle | Soft, mellow | Subtle leads |
| Noise | Texture | Percussion, atmosphere |

### Key Parameters

| Parameter | Unit | Typical Range | Effect |
|-----------|------|---------------|--------|
| Detune | cents | 0-50 | Width/thickness |
| Filter cutoff | Hz | 200-10000 | Brightness |
| Resonance | 0-1 | 0-0.8 | Peak at cutoff |
| Attack | ms | 1-500 | How fast sound starts |
| Decay | ms | 10-2000 | Drop to sustain |
| Release | ms | 10-2000 | Fade after release |

### Genre Detune Reference

| Genre | Detune | Character |
|-------|--------|-----------|
| Kraftwerk | 0-2¢ | Mono, precise |
| Detroit Techno | 0¢ | Clean digital |
| Synthwave | 15¢ | Wide, lush |
| Boards of Canada | 15¢ + wow | Wobbly, nostalgic |
| Rave (Hoover) | 40¢ | Aggressive, swarming |

---

## File References

- **Soundbanks:** `commons/audio/soundbanks/`
- **Generator:** `commons/audio/generators/SoundbankGenerator.gd`
- **Loader:** `commons/audio/generators/SoundbankLoader.gd`
- **Dev Tools:** `commons/audio/catalog/SongDevTools.gd`
- **Preview:** `commons/audio/catalog/SongPreviewDesktop.gd`
- **Synth Reference:** `commons/audio/documentation/SYNTH_ELEMENTS.md`

---

## Quick Start: New Song in 5 Steps

1. **Create soundbank folder** with `brief.json` + sound `.gd` files
2. **Add patterns** to `SoundbankGenerator.gd` (PATTERNS, BASS_PATTERNS, SWING, VELOCITY, STRUCTURES)
3. **Add match case** in `SongDevTools.gd` `_generate_and_play()`
4. **Add layer descriptions** in `_get_layers_for_song()`
5. **Test** via SongDevTools scene

---

*Last updated: 2026-02-04*
