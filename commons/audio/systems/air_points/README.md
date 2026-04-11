# Air Points System

Systems Music implementation inspired by Teropa's work on Eno and Reich — maps 3D point movement to audio parameters. 100% synthesized, no samples.

## Files

| Script | Purpose |
|--------|---------|
| `AirPointListener.gd` | Receives spatial data from air points and converts to audio parameters |
| `AirPointOscillator.gd` | Oscillator driven by air point position — position maps to frequency, velocity to vibrato |
| `AirPointMover.gd` | Controls air point movement patterns |
| `AirPointTrigger.gd` | Triggers audio events when air points enter regions |
| `FMPianoSynth.gd` | FM synthesis piano for air point-driven melodies |
| `SystemsMusicLooper.gd` | Tape-delay style looper for layered generative music |
| `LoopVisualizer.gd` | Visual feedback for looper state |

## Scenes

- `AirPointAudioTest.tscn` — Test scene for air point audio
- `SystemsMusicTest.tscn` — Test scene for the full systems music setup

## Shaders

- `ArcRing.gdshader` — Arc ring visualization for oscillator state
- `SystemsMusicVisualizer.gdshader` — Visual display for systems music patterns

## Architecture

Air points exist as 3D positions that move through space. `AirPointListener` monitors their position and velocity, mapping spatial data to synthesis parameters. `AirPointOscillator` generates audio from these parameters. `SystemsMusicLooper` layers outputs with tape-delay-style accumulation.
