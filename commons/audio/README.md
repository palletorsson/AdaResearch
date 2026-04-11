# Audio System

Procedural audio engine for Ada Research — all sound is synthesized at runtime from math, no sample files.

## Architecture

The audio system has three main paths:

- **Runtime**: `SoundBankSingleton` (autoload) + `AmbientSoundController` handle per-map ambient sound with preset-based generation and crossfading
- **Authoring**: `catalog/` tools for sound design, song composition, and semantic sound control
- **Live**: `live/` performance environment combining rack state, engine, and UI

## Key Scripts

| Script | Purpose |
|--------|---------|
| `SoundBankSingleton.gd` | Global audio manager — generation, caching, preset loading, scene transitions |
| `AmbientSoundController.gd` | Per-map ambient playback with crossfading and async generation |
| `UniversalVRAudioController.gd` | VR modular synth rack brain — Ableton-style controls, monitors, jack routing |
| `AudioSynthesizer.gd` | Procedural 16-bit PCM WAV generation from math functions |
| `MixBusSetup.gd` | Audio bus routing and configuration |
| `PopInteractiveMusic.gd` | Interactive pop music system |
| `PopMusicTheory.gd` | Music theory utilities (scales, chords, progressions) |
| `RackLayoutCalculator.gd` | HP/layout calculations for modular rack interfaces |
| `AsyncAudioGenerator.gd` | Non-blocking threaded audio generation |
| `SoundCollection.gd` | Sound collection management |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `analysis/` | Track quality analysis and scoring |
| `cables/` | VR modular synth patch cable system |
| `catalog/` | Desktop sound design and song authoring tools |
| `collections/` | JSON sound collection definitions |
| `components/` | Modular UI components for audio control |
| `compositions/` | Advanced track composition and playback |
| `configs/` | JSON track configuration examples |
| `debug/` | Debug playback scenes |
| `engines/` | High-level domain synthesis engines |
| `eurorack_modules/` | Eurorack module emulation (experimental) |
| `generators/` | Sound synthesis engines by genre and purpose |
| `interfaces/` | VR and desktop audio visualization and controls |
| `live/` | Live performance environment |
| `parameters/` | JSON parameter libraries for all generators |
| `presets/` | Ambient sound preset definitions |
| `rack_configs/` | Modular rack layout configurations |
| `rack_controls/` | 2D rack control widgets (SVG-parity drawing) |
| `rack_presets/` | Saved rack state snapshots |
| `runtime/` | Lightweight in-game audio playback |
| `sequencer/` | Step sequencer and suite playback |
| `soundbanks/` | Genre-specific procedural sound script sets |
| `sync/` | Beat synchronization controller |
| `systems/` | Generative music systems (air points, graph, discreet) |
| `testing/` | Audio test scenes |

## Map Integration

1. Map JSON specifies audio preset name
2. `SoundBankSingleton` (autoload) manages global audio state
3. `AmbientSoundController` instantiated per map, loads preset via `load_preset()`
4. Optional async generation for non-blocking transitions between maps
