# Generative Music Systems

Algorithmic and generative approaches to music creation — systems music, graph-based composition, and dynamic soundscapes.

## Root Files

| Script | Purpose |
|--------|---------|
| `IntensityController.gd` | Dynamic intensity management — scales audio parameters with gameplay intensity |
| `SciFiLoFiSoundscape.gd` | Sci-fi lo-fi ambient soundscape generator |

## Subsystems

| Directory | Approach |
|-----------|----------|
| `air_points/` | Systems Music (Eno/Reich-inspired) — 3D point movement mapped to audio parameters |
| `discreet_music/` | Discreet music looper and synth (Eno-inspired tape delay systems) |
| `graph_music/` | Graph-based composition — circle of fifths, music graph agents |
| `cellular_automata/` | Cellular automata sonification (stubs only — `.uid` files) |

## Design Philosophy

These systems generate music from rules and spatial relationships rather than fixed sequences. They complement the pattern-based composition system in `../compositions/` by providing open-ended, non-repeating audio.
