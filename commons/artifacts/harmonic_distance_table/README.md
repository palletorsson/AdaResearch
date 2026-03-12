# Harmonic Distance Table

Twelve chromatic pitch nodes arranged in circle-of-fifths order on a tabletop, teaching harmonic distance as an intuitive spatial relationship rather than an abstract interval calculation.

## How It Works

The 12 notes of the chromatic scale are positioned around a circle in circle-of-fifths order (C, G, D, A, ..., F), placing harmonically close keys adjacent to each other. Lines connecting node pairs represent shared overtone relationships, with thickness proportional to the number of shared harmonics in the first 16 partials. Touching a single node activates it as the tonal center, recoloring all other nodes by harmonic function (tonic=green, dominant=blue, subdominant=yellow, etc.) and highlighting connected overtone lines. Touching two nodes plays the interval between them via real-time AudioStreamGenerator synthesis with fundamental plus harmonics.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `circle_radius` | float | `0.35` |
| `node_radius` | float | `0.025` |
| `base_octave` | int | `4` |
| `tone_duration` | float | `1.5` |
| `volume_db` | float | `-6.0` |

## Features

- Circle-of-fifths spatial layout making harmonic proximity visible
- Overtone connection lines weighted by shared partial count
- Tonal center activation with harmonic function color mapping
- Real-time audio synthesis with smooth attack/release envelopes
- VR interaction via Area3D touch detection on note spheres
- Keyboard fallback (1-9, 0, -, =) for desktop testing
- Animated bobbing for selected nodes

## Files

- `harmonic_distance_table.gd` -- Main script
- `harmonic_distance_table.tscn` -- Scene file
