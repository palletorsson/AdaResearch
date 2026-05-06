# Audio Configs

JSON track configuration examples for the composition system.

## Files

- `dark_ambient_track.json` — Dark ambient atmosphere
- `dark_game_track.json` — Dark game music (full config)
- `dark_game_track_simple.json` — Simplified dark game track
- `simple_beat.json` — Minimal beat setup
- `trap_sequencer_example.json` — Trap sequencer configuration

See `README_JSON_Config.md` for the configuration format and `TrackConfigLoader` pattern.

## Usage

Loaded by `compositions/systems/TrackConfigLoader.gd` to configure `EnhancedTrackSystem` at runtime. Each JSON defines layers, patterns, effects, and automation.
