# Composition Systems

Core engine for modular track composition — layers, patterns, effects, and configuration.

## Files

| Script | Purpose |
|--------|---------|
| `EnhancedTrackSystem.gd` | Main composition engine — manages layers (drums, bass, synths, fx), integrates pattern sequencer and effects rack |
| `TrackLayer.gd` | Individual track layer with sound generation and mixing |
| `PatternSequencer.gd` | Pattern-based sequencing (16/32/64/128-beat patterns) |
| `EffectsRack.gd` | Audio effects chain management |
| `TrackConfigLoader.gd` | Loads track configuration from JSON files |
| `TrackConfigExample.gd` | Example configuration setup |
| `EnhancedDarkTrack.gd` | Pre-configured dark ambient track |
| `EnhancedTrackExample.gd` | Example track demonstrating the system |

## Architecture

`EnhancedTrackSystem` is the coordinator. It owns `TrackLayer` instances (one per instrument role), a `PatternSequencer` for timing, and an `EffectsRack` for processing. Configuration can be loaded from JSON via `TrackConfigLoader` — see `../../configs/` for examples.
