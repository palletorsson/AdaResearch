# Vitruvian Man

A real-time **Discrete Fourier Transform (DFT)** visualiser that teaches **Fourier analysis**, **epicyclic decomposition**, and **complex number rotation** by recording hand motion in VR and reconstructing it as a series of rotating circles (epicycles). Inspired by Da Vinci's Vitruvian Man and the mathematical insight that any closed path can be decomposed into a sum of circular orbits.

## How It Works

**VitruvianRecorder** samples the 3D position of a tracked node (typically a VR hand) at regular intervals, building a buffer of path points. In continuous mode, it maintains a rolling window of the last few seconds of motion.

When enough samples are collected, the recorder computes the **Discrete Fourier Transform** by treating each 2D point (X, Y) as a complex number. For each frequency `k` from `-max_harmonics` to `+max_harmonics`, it computes:
- `c_k = (1/N) * sum( z_n * e^(-2*pi*i*k*n/N) )`

This yields a set of Fourier descriptors, each with a frequency, radius (magnitude), and phase. The descriptors are sorted by radius so that the largest circles draw first.

**FourierBody** takes these descriptors and creates a chain of rotating circles (epicycles). Each circle rotates at its descriptor's frequency, with its arm (a thin cylinder) pointing from the circle's centre to the point on its circumference. The tip of the last arm traces the reconstructed path. An `ImmediateMesh` trail renders the traced curve with alpha fade on older points, using Le Corbusier's colour palette (dark grey, red, blue, yellow, white).

**VitruvianDemo** provides choreographed hand motion for demonstration when no VR controller is present. It simulates two hands performing Forsythe-inspired diagonal sweeps with cross-coupled energy perturbations -- each hand's wobble amplitude is driven by the other hand's kinetic energy, creating organic-looking dance-like motion.

**BodyConnection** draws a minimal stick-figure skeleton (arms and spine) connecting the two hand nodes using `ImmediateMesh` lines.

## Parameters

### VitruvianRecorder
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `recording_node_path` | NodePath | -- | Node whose position is sampled |
| `sample_rate` | float | 0.05 | Seconds between position samples |
| `max_harmonics` | int | 10 | Number of Fourier epicycles (frequencies -10 to +10) |
| `continuous_mode` | bool | true | Continuously update Fourier decomposition |
| `buffer_duration` | float | 3.0 | Seconds of motion history to keep |
| `update_interval` | float | 0.5 | Seconds between Fourier recomputations |

### VitruvianDemo
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `demo_mode` | bool | true | Enable automated choreography |
| `speed` | float | 1.0 | Speed of the demo motion |
| `radius` | float | 0.5 | Base motion radius |

### BodyConnection
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `left_hand_path` | NodePath | -- | Path to the left hand node |
| `right_hand_path` | NodePath | -- | Path to the right hand node |
| `spine_color` | Color | white (0.5 alpha) | Colour of the skeleton lines |

## Features

- Real-time DFT computation from hand motion samples
- Epicycle visualisation with rotating arm chains
- Continuous mode with rolling buffer and periodic recomputation
- ImmediateMesh trail with alpha-faded history
- Le Corbusier colour palette for the Modulor aesthetic
- Forsythe-inspired choreography demo with cross-coupled energy
- Minimal stick-figure body connection rendering
- Frequency descriptors sorted by magnitude for visual clarity
- Supports both VR tracked input and automated demonstration

## Files

| File | Description |
|------|-------------|
| `VitruvianRecorder.gd` | Motion sampling, DFT computation, and FourierBody spawning |
| `FourierBody.gd` | Epicycle chain visualisation with arm cylinders and trail rendering |
| `VitruvianDemo.gd` | Choreographed hand motion with cross-coupled energy perturbations |
| `BodyConnection.gd` | Stick-figure skeleton connecting hand nodes with ImmediateMesh lines |
| `FourierBody.tscn` | Scene file for the Fourier body node |
| `VitruvianMan.tscn` | Main scene assembling the full Vitruvian Man artifact |
