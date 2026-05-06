# Harmonic Motion Demo

Interactive demonstration of simple harmonic motion using the equation x = A*sin(omega*t + phi), with VR sliders for amplitude, frequency, phase, and damping that update the oscillation in real time.

## How It Works

Each frame, the current displacement is computed as x = A*sin(2*pi*f*t + phi), with optional exponential damping that multiplies the amplitude by e^(-gamma*t). A cyan sphere oscillates along the x-axis at the computed position. A trailing line strip records the oscillator's position history, fading from transparent to opaque, while a reference sine curve is drawn as a separate ImmediateMesh to show the full waveform shape. Labels display the current formula, parameter values (A, omega, phi), and instantaneous position.

## Features

- Four VR sliders: amplitude (0.1-2.0), frequency (0.2-4.0 Hz), phase (0-360 degrees), damping (0-1)
- Animated oscillating sphere with motion trail
- Reference sine curve overlay showing the full waveform
- Live formula and parameter value display
- Automatic reset when damping reduces amplitude below threshold
- Public API for programmatic control and position queries

## Files

- `harmonic_motion_demo.gd` -- Main script
- `harmonic_motion_demo.tscn` -- Scene file
