# Timbre Sculptor

An additive synthesis instrument that teaches how musical timbre is built from harmonic components. Eight vertical sliders control the amplitude of each harmonic (fundamental through 8th), while real-time audio playback and waveform/spectrum displays show the resulting sound and its frequency content.

## How It Works

Additive synthesis sums sine waves at integer multiples of a fundamental frequency, each with an independent amplitude. The artifact generates audio sample-by-sample using an AudioStreamGenerator, accumulating the contribution of each harmonic with phase tracking. Preset buttons morph the slider values toward known timbres (sine, square, sawtooth, triangle, and five vowel approximations) using per-frame linear interpolation, making the spectral transformation audible and visible in real time.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `fundamental_freq` | float | 220.0 |
| `volume_db` | float | -6.0 |
| `morph_speed` | float | 4.0 |

## Features

- 8 VR vertical sliders controlling individual harmonic amplitudes
- Real-time additive synthesis via AudioStreamGenerator at 44100 Hz
- 9 preset timbres: Sine, Square, Sawtooth, Triangle, and vowels A/E/I/O/U
- Smooth morphing between presets with configurable speed
- Waveform and spectrum display panels
- Keyboard fallback (F1-F9) for desktop testing
- Normalization to prevent clipping when multiple harmonics are active

## Files

- `timbre_sculptor.gd` -- Main script
- `timbre_sculptor.tscn` -- Scene file
