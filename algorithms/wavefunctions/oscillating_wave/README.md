# Oscillating Wave

Sine creates curves. A sphere oscillates, tracing waveform in space, driving sound in real-time.

## QFEP Connection

This is **oscillation made literal**: the back-and-forth motion (F ↔ E) creates visible curve and audible tone simultaneously. Position becomes frequency, amplitude becomes volume, phase becomes timbre. The wave is not abstract — you see it, hear it, feel it.

## Concept

```
Motion (oscillation) → Form (sine curve) → Sound (synthesis)
```

A sphere moves in simple harmonic motion:
- **Vertical position (y)**: Amplitude of oscillation
- **Horizontal position (x)**: Maps to sound frequency (pitch)
- **Wave phase**: Controls harmonic content (timbre)

As the sphere oscillates, it leaves a trail — the sine wave emerges as physical trace in 3D space.

## Sound Mapping

| Position | Sound Parameter | Range |
|----------|-----------------|-------|
| x = -5 to +5 | Frequency | 110 Hz (A2) → 880 Hz (A5) |
| y (height) | Volume | -12 dB → 0 dB |
| phase | Harmonic balance | Timbral variation |

## Features

- **Real-time synthesis**: 6 harmonics, additive synthesis
- **Visual trail**: MultiMesh optimized (1 draw call for 200 points)
- **Reference curve**: Faint sine wave showing expected path
- **Pulsing sphere**: Size responds to sound intensity
- **Color variation**: Hue shifts with frequency

## Parameters

```gdscript
# Oscillation
set_oscillation_frequency(1.5)   # Hz (0.1 - 5.0)
set_oscillation_amplitude(2.0)   # Vertical range (0.5 - 3.0)
set_horizontal_speed(1.0)        # Forward motion (0.1 - 3.0)

# Visual
toggle_reference_curve()         # Show/hide reference sine
```

## Technical

- Uses `WavefunctionResources` for shared materials and fast sine lookup
- `AudioStreamGenerator` for real-time synthesis at 44.1 kHz
- MultiMesh rendering: 200 trail points + 100 reference points in 2 draw calls
- Harmonic amplitudes modulated by phase for evolving timbre

## Files

- `OscillatingWave.gd` — Main script with synthesis and visualization
- `OscillatingWave.tscn` — Scene setup
