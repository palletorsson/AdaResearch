# Walking Sphere -- GPU Sphere Deformation Modes

A procedural sphere that is deformed in real time through seven different algorithmic modes, all driven by a GPU shader. The artifact teaches how **different classes of randomness and growth rules** produce radically different geometric outcomes from the same starting shape -- ordered vs. random spikes, random walks vs. hill-seeking, Gaussian bumps vs. noise fields vs. cellular automata.

## How It Works

The script generates a subdivided sphere mesh (`SphereMesh` converted to `ArrayMesh`), applies a custom `.gdshader`, and then iteratively advances the shader's `iteration` uniform. Each step updates shader parameters to reflect the current mode and intensity, causing the GPU to deform vertices according to one of seven algorithms:

1. **Ordered Spikes** -- Evenly distributed protrusions at fixed angular intervals.
2. **Random Spikes** -- Protrusions placed at random positions on the surface.
3. **Random Walk** -- Vertices drift outward in a step-by-step random walk with configurable chaos.
4. **Hill Seeking** -- Vertices are attracted toward a set of randomly placed attractor points on the sphere.
5. **Gaussian Bumps** -- Smooth bell-curve bumps placed at random locations with controllable width and amplitude.
6. **Noise Deformation** -- Multi-octave procedural noise displaces vertices along their normals.
7. **Cellular Automata** -- Growth/decay rules based on neighbor vertex states.

A demo mode cycles through all seven algorithms automatically, running each for the configured number of iterations before advancing.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `modifier_mode` | enum | 0 (Ordered Spikes) | Active deformation algorithm |
| `sphere_subdivisions` | int | 3 | Mesh subdivision level |
| `iterations` | int | 20 | Steps per mode |
| `auto_evolve` | bool | false | Auto-advance iterations |
| `evolution_speed` | float | 2.0 | Steps per second |
| `intensity` | float | 0.3 | Global deformation strength |
| `smoothing` | float | 0.1 | Smoothing factor |
| `spike_count` | int | 12 | Number of spikes (ordered/random) |
| `spike_length` | float | 0.5 | Spike protrusion distance |
| `walk_step_size` | float | 0.05 | Random walk step size |
| `hill_count` | int | 5 | Number of attractor hills |
| `gaussian_count` | int | 8 | Number of Gaussian bumps |
| `noise_frequency` | float | 2.0 | Noise deformation frequency |
| `noise_octaves` | int | 3 | Noise fractal octaves |
| `ca_neighbor_threshold` | int | 3 | Cellular automata neighbor threshold |

## Features

- Seven distinct deformation algorithms on one mesh
- GPU-driven deformation via shader uniforms (no CPU vertex manipulation after init)
- Real-time volume and average displacement measurement
- Color-coded mode visualization with progress labels
- Demo mode cycling through all seven algorithms
- Keyboard controls for stepping, mode switching, intensity adjustment

## Files

- `walkingsphere.gd` -- Main controller (mode selection, shader parameter updates, demo system)
- `shperemod.gdshader` -- GPU shader implementing all seven deformation modes
