# Noise Mixer

Generates layered procedural noise textures using fractal Brownian motion (fBm), with interactive VR sliders for octaves, lacunarity, and persistence. Teaches how simple sine waves combine into complex terrain-like patterns through octave stacking.

## How It Works

The artifact computes fractal Brownian motion by summing multiple octaves of sin-based pseudo-noise. Each octave doubles in frequency (controlled by lacunarity) and halves in amplitude (controlled by persistence), following the formula: total = sum of persistence^i * noise(frequency * lacunarity^i * position). The raw noise values are normalized to [0, 1] and mapped through a 9-stop earth-tone color ramp (deep water to snow peaks) to produce a 128x128 procedural texture displayed on a floor quad.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `quad_size` | Vector2 | (0.8, 0.8) |
| `octaves` | int | 4 |
| `lacunarity` | float | 2.0 |
| `persistence` | float | 0.5 |
| `base_frequency` | float | 4.0 |
| `seed_value` | int | 42 |

## Features

- Real-time fBm texture generation with adjustable parameters
- VR sliders for octaves (1-8), lacunarity (1.5-3.0), and persistence (0.3-0.7)
- Randomize seed button for new noise patterns
- Earth-tone color ramp from deep water blue to snow-white peaks
- Formula display showing the current fBm equation with live parameter values
- Grid config integration for map-driven parameter overrides

## Files

- `noise_mixer.gd` — Main script
- `noise_mixer.tscn` — Scene file
