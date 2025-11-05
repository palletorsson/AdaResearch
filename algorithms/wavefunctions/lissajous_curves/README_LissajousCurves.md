# Lissajous Curve Generator

## Overview
Parametric curves formed by combining perpendicular harmonic motions. These beautiful mathematical patterns appear in physics, oscilloscope displays, and harmonograph drawings.

## Mathematics

### 2D Lissajous Curves
```
x(t) = A * sin(a*t + δ)
y(t) = B * sin(b*t)
```

### 3D Extension
```
x(t) = A * sin(a*t + δ)
y(t) = B * sin(b*t)
z(t) = C * sin(c*t)
```

Where:
- **A, B, C** = Amplitudes on each axis
- **a, b, c** = Frequency ratios
- **δ** (delta) = Phase shift
- **t** = Time parameter (0 to 2π)

### Frequency Ratio Effects
The ratio **a:b** determines the curve shape:
- **1:1** = Circle (with π/2 phase shift) or line (0 phase shift)
- **2:1** = Figure-eight (∞ symbol)
- **3:2** = Trefoil pattern
- **3:4** = Complex wave pattern
- **5:4** = Pentagram-like pattern

## Parameters

### Frequency Ratios
- **freq_ratio_x**: Horizontal oscillation frequency (a)
- **freq_ratio_y**: Vertical oscillation frequency (b)
- **freq_ratio_z**: Depth oscillation frequency (c) - for 3D curves

### Amplitudes
- **amplitude_x**: Horizontal extent
- **amplitude_y**: Vertical extent
- **amplitude_z**: Depth extent (3D)

### Phase
- **phase_shift**: Phase offset (δ) in radians
- **animate_phase**: Continuously change phase
- **phase_speed**: How fast phase changes

### Visualization
- **num_points**: Curve resolution (more = smoother)
- **trail_length**: Number of trailing points
- **show_particle**: Display moving point
- **rainbow_gradient**: Color curve by position

### Animation
- **animation_speed**: Particle speed along curve
- **auto_rotate**: Spin for better 3D viewing

## Presets

Use `set_preset(name)` to load famous patterns:

- **"circle"**: Perfect circle (1:1 with π/2 phase)
- **"figure_eight"**: Infinity symbol (2:1)
- **"trefoil"**: Three-lobed pattern (3:2)
- **"3d_knot"**: 3D knot pattern (3:2:1)
- **"pentagram"**: Five-pointed star (5:4)

## Physics Applications
- **Oscilloscope patterns**: Visualizing signal relationships
- **Harmonograph drawings**: Mechanical drawing devices
- **Planetary orbits**: When viewed from rotating reference frames
- **Coupled pendulums**: Trajectory of coupled oscillators
- **Crystal vibrations**: Normal modes in lattices

## Famous Examples
- **Blackburn pendulum**: Double pendulum creating Lissajous curves
- **Bowditch curves**: Named after Nathaniel Bowditch (1815)
- **Oscilloscope music**: Using audio signals to draw patterns

## Interactive Use
```gdscript
# Get current position
var pos = get_current_position()

# Get velocity
var vel = get_velocity()

# Load preset
set_preset("trefoil")
```
