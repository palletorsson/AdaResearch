# Compositions

Advanced track composition system with layers, pattern sequencing, and effects processing.

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `systems/` | Core composition engine — track layers, pattern sequencer, effects rack, config loader |
| `players/` | Genre-specific track player scripts |
| `scenes/` | Ready-to-use composition scenes |
| `configs/` | Track configuration data (currently empty — see `../configs/` for JSON examples) |

## Architecture

The composition system builds on `EnhancedTrackSystem` which manages layers (drums, bass, synths, fx), a pattern sequencer, and an effects rack. Track players in `players/` configure the system for specific genres and styles.
