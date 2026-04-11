# Audio Generators

Sound synthesis engines covering genres from cinematic to trap, plus utility generators for MIDI, export, and testing.

## Synthesis Generators

| Script | Purpose |
|--------|---------|
| `AudioSynthesizer.gd` | Core procedural synthesizer — 16-bit PCM WAV from math, BPM/bar-based, threading support |
| `RealtimeAudioSynthesizer.gd` | Real-time variant for live playback |
| `CustomSoundGenerator.gd` | User-defined synthesis with arbitrary parameters |
| `FMPianoGenerator.gd` | FM synthesis piano |
| `FourierSpaceGenerator.gd` | Fourier-series-based synthesis |
| `FractalSoundGenerator.gd` | Fractal and procedural sound generation |
| `DuoSynthGenerator.gd` | Dual oscillator synth |
| `GranularWindGenerator.gd` | Granular synthesis for wind and atmospheric sounds |
| `WavetableGenerator.gd` | Wavetable-based synthesis |
| `SingingVoiceGenerator.gd` | Vocal synthesis |

## Genre Generators

| Script | Genre |
|--------|-------|
| `CinematicMusicGenerator.gd` | Film score and cinematic |
| `CyberJazzGenerator.gd` | Cyber jazz |
| `DiscreetAudioGenerator.gd` | Systems music (Eno-inspired) |
| `GraphAudioGenerator.gd` | Graph-based generative music |
| `HouseDrumGenerator.gd` | House drum patterns |
| `SpaceDystopiaGenerator.gd` | Space dystopia ambient |
| `TechnoNoirGenerator.gd` | Tech noir atmospheres |
| `TrapBeatsGenerator.gd` | Trap beat patterns |
| `SciFiPreviewGenerator.gd` | Sci-fi sound previews |
| `GenreDSP.gd` | Shared genre DSP utilities |
| `MelodyGenerator.gd` | Melodic line generation |
| `SoundbankGenerator.gd` | Soundbank-based generation |

## Utilities

| Script | Purpose |
|--------|---------|
| `MidiCapture.gd` | MIDI input capture |
| `MidiExporter.gd` | Export to MIDI format |
| `MidiImporter.gd` | Import from MIDI |
| `SongExporter.gd` | Full song export pipeline |
| `SongStructureBuilder.gd` | Build song arrangements from sections |
| `create_default_parameters.gd` | Generate default parameter files |
| `test_parameter_connection.gd` | Parameter connection test utility |
| `RealtimeSynthesizerTest.gd` | Synthesis test harness |

## Usage

Generators are called by higher-level systems — `SoundBankSingleton`, composition players, and catalog tools. Each generator accepts a parameter dictionary (from `../parameters/`) and produces `AudioStreamWAV` data.
