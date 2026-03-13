# White Noise -- Noise Color Spectrum Visualization and Audio

A dual-artifact set that visualizes and sonifies the **spectral properties of different noise colors** -- White, Pink, Brown, Blue, and Violet. The artifacts teach how the same underlying randomness, filtered differently in the frequency domain, produces signals with fundamentally different characters -- from the flat spectrum of white noise to the bass-heavy roll of Brownian motion.

## How It Works

### Visual Spectrum (`white_noise_spectrum.gd`)

Generates a 50x50 grid of thin vertical lines using MultiMesh, where each line's height is a random value scaled by `max_height`. Lines are colored via an optional gradient mapped to their random value. This creates a 3D "frequency spectrum" landscape where uniform randomness appears as a field of uncorrelated heights.

### Noise Spectrum 3D (`noise_spectrum_3d.gd`)

Extends the concept by computing **spectral power density** for five noise types and rendering 200 frequency bins as vertical bars. Each noise type's power curve follows its mathematical definition:

| Noise Type | Power Law | Character |
|-----------|-----------|-----------|
| White | Flat (1.0) | Equal power at all frequencies |
| Pink | 1/f | Natural, perceptually balanced |
| Brown | 1/f^2 | Deep rumble, Brownian motion |
| Blue | f | Hissy, high-frequency emphasis |
| Violet | f^2 | Even more high-frequency emphasis |

A `show_all_types` mode renders all five spectra side by side with Z-axis spacing for comparison.

### Audio Preview (both scripts)

Both scripts include a real-time audio synthesis system using `AudioStreamGenerator` and `AudioStreamPlayer3D`. VR push buttons let the user switch between noise types and hear each one. The Pink noise filter uses the Paul Kellet approximation (seven-coefficient IIR filter). Brown noise integrates white noise with clamping. Blue noise subtracts a lowpass-filtered signal. Violet noise takes the first difference of white noise.

## Parameters

| Export | Script | Default | Description |
|--------|--------|---------|-------------|
| `grid_size` | white_noise_spectrum | (50, 50) | Grid dimensions |
| `spacing` | both | 0.2 / 0.05 | Distance between bars |
| `max_height` | both | 2.0 / 3.0 | Maximum bar height |
| `line_thickness` | both | 0.02 | Bar cross-section width |
| `seed_value` | both | 0 | RNG seed (0 = randomize) |
| `frequency_bins` | noise_spectrum_3d | 200 | Number of frequency samples |
| `noise_type` | noise_spectrum_3d | WHITE | Active noise type |
| `show_all_types` | noise_spectrum_3d | false | Show all 5 types side by side |
| `audio_gain` | both | 0.16 | Audio output volume |
| `audio_mix_rate` | both | 44100 | Audio sample rate |

## Features

- MultiMesh-based rendering for efficient high-count bar visualization
- Five noise color types with mathematically accurate spectral power curves
- Real-time audio synthesis with Paul Kellet pink noise filter
- VR push-button control panel with per-type color-coded buttons
- 3D spatialized audio via AudioStreamPlayer3D
- Editor tool support for in-editor preview

## Files

- `white_noise_spectrum.gd` -- 2D grid white noise field with audio preview
- `noise_spectrum_3d.gd` -- Spectral power density visualization for all 5 noise colors
