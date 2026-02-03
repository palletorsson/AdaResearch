# Soundbanks

Genre-isolated sound definitions for procedural music generation.

## Philosophy

**Each genre has its own soundbank. No sharing. No contamination.**

Instead of shared generators with different parameters, each genre gets:
- Its own folder with dedicated sound scripts
- A `brief.json` defining identity, vocabulary, and forbidden elements
- Complete isolation from other genres

A Detroit Techno generator literally cannot use a synthwave supersaw because that sound doesn't exist in Detroit's soundbank.

## Structure

```
soundbanks/
├── SoundbankLoader.gd          # Loads and validates soundbanks
├── README.md                   # This file
│
├── detroit_techno/
│   ├── brief.json              # Identity, BPM, sections, forbidden
│   ├── kick.gd                 # TR-909 style kick
│   ├── snare.gd                # TR-909 snappy snare
│   ├── hihat.gd                # Metallic 909 hat
│   ├── clap.gd                 # Layered 909 clap
│   ├── bass.gd                 # 808 sub bass
│   ├── pad.gd                  # Clean digital pad (ZERO detune)
│   └── stab.gd                 # Chord stab
│
├── synthwave/                  # (TODO)
│   ├── brief.json
│   ├── kick.gd                 # LinnDrum kick
│   ├── snare.gd                # Gated reverb snare
│   ├── supersaw.gd             # JP-8000 lead
│   ├── arp.gd                  # Juno arpeggio
│   └── ...
│
├── burial/                     # (TODO)
│   ├── brief.json
│   ├── kick.gd                 # UK garage kick
│   ├── sub.gd                  # Mono sub (+6dB)
│   ├── atmosphere.gd           # Dark pad
│   ├── crackle.gd              # Vinyl noise (always present)
│   └── ...
│
└── ...
```

## brief.json Format

```json
{
  "meta": {
    "id": "genre_id",
    "name": "Display Name",
    "lineage": "Key artists/influences",
    "era": "Time period",
    "bpm": { "min": 120, "max": 130, "typical": 128 },
    "lambda": 0.3
  },

  "identity": {
    "token": "The recognizable-in-2-seconds signature",
    "two_second_test": "What you hear immediately",
    "emotional_truth": "What it feels like"
  },

  "soundbank": ["kick", "snare", "hihat", "bass", "pad"],

  "forbidden": [
    "element_from_other_genre",
    "another_forbidden_element"
  ],

  "rhythm": {
    "quantize": "strict|loose",
    "humanize_ms": 0,
    "swing_pct": 0
  },

  "sections": {
    "intro": ["pad"],
    "main": ["kick", "snare", "hihat", "bass", "pad"],
    "outro": ["pad"]
  },

  "transitions": {
    "crossfade_s": 2.0
  }
}
```

## Sound Script Format

Each sound is a GDScript class with static methods:

```gdscript
# example_sound.gd
class_name GenreSound
extends RefCounted

const SAMPLE_RATE = 44100.0

# Document source and character
# Character: Description of the sound
# Source: Hardware/technique reference
# Processing: What effects are applied

# Parameters from research (with citations)
const SOME_PARAM = 0.5  # From research doc

static func generate(t: float, ...) -> float:
    # Generate sample at time t
    return sample

static func get_duration() -> float:
    return 0.5
```

## Usage

```gdscript
# Load a soundbank
var bank = SoundbankLoader.load_genre("detroit_techno")

# Check what's available
print(bank.get_available_sounds())  # ["kick", "snare", "hihat", ...]

# Validate (prevents contamination)
if bank.is_forbidden("supersaw"):
    push_error("Supersaw not allowed in Detroit Techno!")

# Generate a song
var song = SoundbankGenerator.generate_song("detroit_techno")
```

## Adding a New Genre

1. Create folder: `soundbanks/your_genre/`
2. Create `brief.json` with identity and soundbank list
3. Create sound scripts (one per sound)
4. Each script should document its research source
5. Test via SongDevTools

## Isolation Guarantees

- Generators can ONLY use sounds in their soundbank
- `forbidden` list explicitly blocks cross-contamination
- Each sound script is self-contained
- No shared primitives between genres

## Research Sources

Sound parameters come from `ada_the_research/music_tracks/*.md`:
- Detailed specs per genre (detune cents, filter Hz, attack times)
- Hardware lineage and signal chain
- Production philosophy
- Recreation tips

## λ (Lambda) Values

From QFEP theory - order↔chaos balance:

| Genre | λ | Character |
|-------|---|-----------|
| Kraftwerk | 0.15 | Maximum order, mechanical precision |
| Detroit Techno | 0.2 | Clean, quantized, machine funk |
| Synthwave | 0.3 | Controlled, nostalgic |
| House | 0.4 | Balanced groove |
| Burial | 0.5 | Structured chaos, humanized |
| BoC | 0.55 | Drifting, lo-fi |
| Rave | 0.45 | Energetic but structured |
