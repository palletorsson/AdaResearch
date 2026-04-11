# Metamerism Lab

A visual demonstration of metamerism -- the phenomenon where two physically different light sources can produce the same perceived color, revealing how human color vision is a reconstruction rather than a direct measurement of wavelength.

## How It Works

The scene splits into two sides. On the left, a single yellow wave (simulating monochromatic 580nm light) flows from a source box down to a result sphere. On the right, separate red and green waves (simulating 650nm + 540nm) travel simultaneously and combine to produce the exact same yellow at the result sphere. Both result spheres display identical colors despite having fundamentally different spectral compositions. An animation cycle moves the wave dots along sinusoidal paths at different frequencies to show the wavelength differences. This teaches that our eyes have only three cone types and cannot distinguish a pure spectral yellow from a red-green mixture.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `wave_speed` | float | 2.0 |
| `wave_amplitude` | float | 0.5 |

## Features

- Side-by-side comparison of monochromatic vs. mixed-wavelength light
- Animated wave dots with frequency-accurate motion
- Identical output colors proving metameric equivalence
- Tool mode support for in-editor preview

## Files

- `MetamerismLab.gd` -- Main script
- `MetamerismLab.tscn` -- Scene file
