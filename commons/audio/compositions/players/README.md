# Composition Players

Genre-specific track player scripts that configure the composition system for particular styles.

## Files

| Script | Style |
|--------|-------|
| `DarkGameTrackPlayer.gd` | Dark ambient game music |
| `DarkGameTrackPlayerJSON.gd` | JSON-configured variant of the dark game track |
| `DarkBladeRunner128TrackPlayer.gd` | Blade Runner-inspired 128 BPM track |
| `PolymeterTrackPlayer.gd` | Polymetric rhythm patterns |
| `StructuredTrackPlayer.gd` | Standard structured composition |
| `SyncopatedTrackPlayer.gd` | Syncopation-focused rhythms |

## Usage

Each player is attached to a corresponding scene in `../scenes/` and drives the `EnhancedTrackSystem` from `../systems/` with genre-appropriate parameters, patterns, and layer configurations.
