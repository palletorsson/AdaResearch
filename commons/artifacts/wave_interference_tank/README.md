# Wave Interference Tank

Simulates two-source wave interference in a virtual water tank, showing constructive and destructive interference patterns. Teaches the principle of superposition -- that waves combine by adding their displacements, and that stable interference patterns emerge from phase relationships between coherent sources.

## How It Works

Two point sources emit circular waves defined by A * sin(k*r - omega*t + phi), where k is the wave number, omega is the angular frequency, and phi is an optional phase offset. At each grid cell the heights from both sources are summed (superposition), producing the characteristic interference pattern. Edge damping smoothly attenuates wave amplitude near the tank walls. The surface is rebuilt every frame as an ImmediateMesh with vertex colors interpolated between trough and peak colors based on displacement. Glowing sphere markers indicate the two source positions.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `tank_size` | float (0.2-2.0) | 0.8 |
| `tank_depth` | float (0.02-0.3) | 0.08 |
| `wave_frequency` | float (0.5-10.0) | 3.0 |
| `wave_amplitude` | float (0.001-0.1) | 0.02 |
| `wave_speed` | float (0.05-2.0) | 0.3 |
| `source_separation` | float (0.1-0.8) | 0.4 |
| `phase_difference` | float (0.0-6.283) | 0.0 |
| `color_peak` | Color | Blue (0.2, 0.6, 1.0) |
| `color_trough` | Color | Dark blue (0.1, 0.1, 0.2) |
| `color_source` | Color | Orange (1.0, 0.4, 0.2) |

## Features

- Two-source superposition with adjustable phase difference
- VR sliders for frequency and source separation
- Phase preset buttons: In Phase (0), Opposite (pi), Quarter (pi/2), Eighth (pi/4)
- Transparent glass tank walls built with MultiMesh for efficient rendering
- Edge damping to reduce boundary reflections
- Live info label with wavelength and phase difference
- Keyboard shortcuts for quick parameter changes

## Files

- `wave_interference_tank.gd` -- Main script
- `wave_interference_tank.tscn` -- Scene file
