# Audio System

> Procedural sound generation with hierarchical configuration

## Overview

The audio system provides centralized sound generation and ambient management through a singleton architecture. Sounds are defined in JSON parameter files and generated on-demand with caching.

## Architecture

```
┌─────────────────────────────────────┐
│  SoundBankSingleton (AutoLoad)      │
│  - Sound generation & caching       │
│  - Audio bus management             │
│  - Parameter file loading           │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  AmbientSoundController (per-scene) │
│  - Loads ambient presets            │
│  - Manages continuous layers        │
│  - Triggers random events           │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  GridAudioComponent (grid system)   │
│  - Connects maps to audio           │
└─────────────────────────────────────┘
```

## Structure

```
audio/
├── SoundBankSingleton.gd      # Core singleton (AutoLoad)
├── AmbientSoundController.gd  # Per-map ambient
├── AsyncAudioGenerator.gd     # Background thread generation
├── presets/                   # Ambient preset definitions
│   └── *.json
├── parameters/                # Sound parameter files (70+)
│   ├── basic/                 # Simple sounds
│   ├── drums/                 # Percussion
│   ├── synthesizers/          # Classic synths
│   ├── retro/                 # Chiptune
│   ├── experimental/          # Advanced synthesis
│   └── ambient/               # Atmospheric drones
├── generators/                # Synthesis engines
├── interfaces/                # Sound design tools
├── runtime/                   # Game runtime components
└── documentation/             # Guides
```

## Configuration Hierarchy

Audio configuration cascades from global to specific:

```
Global defaults (map_sequences.json → audio_defaults)
    │
    └──► Sequence overrides (sequences/*.json → audio)
            │
            └──► Map overrides (map_data.json → audio)
```

## Ambient Presets

Presets define layered soundscapes:

```json
{
  "name": "dark_ambient",
  "layers": [
    {"sound": "drone_low", "volume": -12, "continuous": true},
    {"sound": "wind", "volume": -18, "continuous": true}
  ],
  "events": [
    {"sound": "distant_thunder", "min_interval": 30, "max_interval": 120}
  ]
}
```

## Key Files

| File | Purpose |
|------|---------|
| `SoundBankSingleton.gd` | Core sound management |
| `AmbientSoundController.gd` | Per-map ambient |
| `SOUND_SYSTEM_GUIDE.md` | Complete integration guide |
| `presets_manifest.json` | Available preset list |

## Usage

### In Sequences

```json
{
  "sequence_name": {
    "audio": {
      "ambient_preset": "dark_ambient",
      "volume": -10.0
    }
  }
}
```

### Programmatically

```gdscript
# Get a sound
var sound = SoundBank.get_sound("pickup_coin")

# Set ambient
AmbientSoundController.set_preset("dark_ambient")
```

## Testing

- `interfaces/` — Sound design tools with real-time preview
- `testing/` — Validation scenes
- `catalog/SongPreviewDesktop.tscn` — Sound browser
