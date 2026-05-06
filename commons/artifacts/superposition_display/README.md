# Superposition Display

A visual demonstration of quantum superposition, showing how a quantum state exists as a weighted combination of basis states until measurement. The artifact illustrates the formula |psi> = alpha|0> + beta|1>, where the probability amplitudes oscillate over time.

## How It Works

Three semi-transparent spheres represent the |0> state, the |1> state, and their superposition. The alpha and beta amplitudes oscillate sinusoidally, and each sphere's transparency changes in real time to reflect the current probability weight of that basis state. A VR slider controls the oscillation speed, letting users observe how faster dynamics affect the visual perception of superposition.

## Features

- Animated probability amplitudes with sinusoidal oscillation between |0> and |1>
- Semi-transparent, emissive spheres with alpha blending tied to state weights
- VR slider to control oscillation speed (0.5 to 8.0 Hz range)
- Labels showing Dirac notation for each basis state and the superposition formula

## Files

- `superposition_display.gd` -- Main script
- `superposition_display.tscn` -- Scene file
