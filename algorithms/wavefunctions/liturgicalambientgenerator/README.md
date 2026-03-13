# Liturgical Ambient Generator

A procedural audio engine that teaches **additive synthesis**, **modal harmony**, and **spectral sound design** by generating an entire sacred soundscape from pure mathematics -- no audio files required. The system creates choral drones, pipe organ foundations, cathedral bells, and atmospheric textures using sine wave superposition, harmonic series, and Dorian mode frequency ratios.

## How It Works

On startup, a background thread generates 19 WAV audio streams (3 foundation layers + 2 variations each of 8 sacred sound types). Each stream is built sample-by-sample at 44.1 kHz by summing sine waves at harmonically related frequencies.

The **choral foundation** creates 16 virtual voices using Dorian mode ratios (1:1, 9:8, 32:27, 4:3, 3:2, 27:16, 16:9) across multiple octaves, each with independent vibrato and breathing envelopes. The **organ foundation** stacks 8 pipe harmonics (1x through 10x fundamental at 32.7 Hz) with tremulant modulation. The **string atmosphere** layers 5 orchestral frequencies with expressive vibrato.

Effect sounds include **Gregorian phrases** (stepped modal melodies), **cathedral bells** (inharmonic partials at ratios like 2.4, 3.56, 4.07), **pipe organ swells** (quadratic attack/release envelopes), **sacred whispers** (noise shaped by vocal formant resonances), **hymnal fragments** (diatonic patterns with major-third harmony), **divine breath** (sub-bass drones with wind noise), **prophetic thunder** (Gaussian envelope rumble with crack transients), and **angelic textures** (high-frequency shimmer with smoothstep envelopes).

A `ProgressVisualizer` displays a 3D progress bar during generation, positioned for VR comfort. Once complete, the three foundation layers loop continuously while effect sounds trigger at randomised contemplative intervals (8--25 seconds), with volume modulated by a slow-breathing spiritual intensity curve.

## Parameters

The generator uses internal constants rather than exports. Key configurable values:

| Constant | Value | Description |
|----------|-------|-------------|
| `sample_rate` | 44100.0 | Audio sample rate in Hz |
| `choral_voices` | 16 | Number of virtual choir voices |
| `num_effect_players` | 8 | Concurrent effect audio players |
| `sacred_sound_types` | 8 types | Gregorian, bell, organ, whisper, hymnal, breath, thunder, angelic |
| `current_liturgical_mode` | "dorian" | Modal scale for harmonic generation |

## Features

- Fully procedural audio -- no sample files needed
- Threaded generation with mutex-protected progress tracking
- Dorian mode harmonic system with golden-ratio-adjacent frequency ratios
- Realistic bell synthesis using inharmonic partial series
- 6 dedicated audio buses with cathedral reverb, chamber reverb, and distortion effects
- Stereo panning with slow sinusoidal drift
- VR-friendly 3D progress bar with smooth animation and fade-out
- Automatic sacred event triggering with contemplative timing
- Clean shutdown with thread join and player cleanup

## Files

| File | Description |
|------|-------------|
| `liturgicalambientgenerator.gd` | Core audio engine -- synthesis, threading, bus setup, playback |
| `progressvisualizer.gd` | 3D progress bar for VR with billboard text and color transitions |
