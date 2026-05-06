# Profile Cartridges

Algorithm cartridges for the Profile substrate. Each extends `ProfileCartridge` and implements `step()` to fill one or more `PackedFloat32Array` trace buffers displayed as continuous curves on an oscilloscope-style renderer.

## How It Works

A cartridge writes normalized values into trace buffers each step. The renderer draws these as ribbon strips over a procedural grid background. Cartridges specify trace colors and whether the display scrolls continuously or builds up incrementally. Vertical markers can highlight specific points.

## Files

### Basic Waveforms
- `cartridge_sine_wave.gd` -- Pure sine wave. Phosphor green, continuous scroll.
- `cartridge_saw_wave.gd` -- Sawtooth wave with sharp resets.
- `cartridge_square_wave.gd` -- Square wave with hard transitions.
- `cartridge_triangle_wave.gd` -- Triangle wave, linear ramps up and down.

### Composite and Modulated
- `cartridge_fourier_series.gd` -- Fourier series building a square wave term by term.
- `cartridge_beat_frequencies.gd` -- Two close frequencies producing audible beats.
- `cartridge_lissajous_1d.gd` -- Lissajous figure projected onto a 1D trace.

### Physics and Dynamics
- `cartridge_spring_mass.gd` -- Damped spring-mass oscillation.
- `cartridge_damped_oscillation.gd` -- Exponentially decaying oscillation.
- `cartridge_gradient_descent.gd` -- Gradient descent on a loss landscape, showing convergence.

### Noise and Stochastic
- `cartridge_noise_1d.gd` -- 1D Perlin noise profile.
- `cartridge_noise_octaves.gd` -- Layered noise octaves (fBm) with increasing detail.
- `cartridge_random_walk_1d.gd` -- Brownian random walk trace.
- `cartridge_brownian_bridge.gd` -- Brownian bridge pinned at both endpoints.

### Mathematical
- `cartridge_logistic_map.gd` -- Logistic map iteration showing period-doubling route to chaos.
- `cartridge_bell_curve.gd` -- Gaussian bell curve built from accumulated random samples.
