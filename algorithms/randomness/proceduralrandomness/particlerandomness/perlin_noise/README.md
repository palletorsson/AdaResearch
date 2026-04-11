# Perlin Noise

A particle-based visualization that demonstrates Perlin noise -- a type of gradient noise that produces smooth, natural-looking randomness. Unlike pure randomness, Perlin noise generates coherent patterns with gradual transitions, making it the foundation of procedural content generation in games, film, and simulations.

## Concept Taught

Perlin noise occupies the space between pure chaos and rigid order. Invented by Ken Perlin for the film Tron, it creates randomness that feels organic -- terrain that rolls naturally, clouds that drift convincingly, fire that flickers realistically. This artifact lets learners see how structured randomness differs from uniform randomness by watching particles flow through a Perlin noise field in real time.

## How It Works

This scene uses the shared `extrem_randomness.gd` script with `forced_demo = 1` to lock the visualization to the Perlin noise demonstration.

1. **Particle initialization** -- 100 particles are arranged in a grid layout, providing a structured starting configuration that makes the noise-driven motion easier to observe.
2. **Noise-based flow field** -- Each frame, every particle's position is sampled through a 3D noise function (`noise3`) using its current position and elapsed time as inputs. The resulting noise values determine a directional vector that pushes the particle along.
3. **Color mapping** -- Particle colors shift based on their spatial position and time, using sine wave functions to create smoothly transitioning hues that reinforce the visual coherence of Perlin noise.
4. **Boundary containment** -- Particles that drift beyond a radius of 7 units are clamped back, keeping the visualization compact.

The noise function itself is a simplified implementation using overlapping sine and cosine waves at different frequencies to approximate Perlin noise behavior.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `num_particles` | int | 100 | Number of particles in the visualization |
| `display_time` | float | 1000000.0 | Time before switching demos (set very high to stay on this demo) |
| `enable_narration` | bool | true | Whether narration text is displayed |
| `forced_demo` | int | 1 | Locks the scene to the Perlin noise demo |

## Features

- Smooth, flowing particle motion driven by a 3D noise field
- Time-varying noise creates evolving visual patterns
- Color gradients tied to spatial position reinforce coherence
- Explanatory title and description labels in 3D space
- Grid-based initial layout highlights the contrast between ordered starting positions and organic noise-driven drift

## Files

| File | Description |
|------|-------------|
| `perlin_noise.tscn` | Scene file -- sets `forced_demo = 1` and long `display_time` |
| `../extrem_randomness.gd` | Shared script with all five randomness demos (Perlin noise is demo index 1) |
