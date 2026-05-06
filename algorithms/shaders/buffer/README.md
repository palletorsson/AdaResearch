# Buffer Geometry Particles -- Custom GPU Particle System

A large-scale particle system built from raw buffer geometry (ArrayMesh quads) with a custom spatial shader, inspired by WebGL buffer geometry techniques. The artifact teaches how **per-vertex attributes stored in mesh buffers** can drive GPU animation -- positions, velocities, colors, sizes, and lifetimes are baked into the mesh data and then animated entirely in the shader.

## How It Works

The script generates `particle_count` (default 10,000) particles, each represented as a screen-facing quad (4 vertices, 2 triangles). For each particle, random initial data is computed:

- **Position**: Distributed in a spherical volume with power-law clustering toward the center.
- **Velocity**: Generally outward with random variation and upward bias.
- **Color**: HSV-mapped based on distance from center with configurable color variation.
- **Size**: Random within 0.1--0.8 range.
- **Lifetime**: Random offset for phase desynchronization.

All quads are packed into a single `ArrayMesh` with vertex colors. A custom spatial shader handles:

- **Billboard orientation**: Quads face the camera using cross-product alignment.
- **Lifetime animation**: Sinusoidal size and alpha curves create birth-grow-shrink-fade cycles.
- **Wave motion**: Sine/cosine displacement adds organic floating movement.
- **Sparkle effect**: Position-based sine modulation creates glinting highlights.

Tween-based animations pulse the `size_multiplier` and `animation_speed` shader parameters over time for dynamic variation.

Three alternate pattern generators are included:
- **Spiral**: 8-arm spiral with rainbow coloring
- **Explosion**: Center-origin burst with hot red/orange/yellow colors
- **Galaxy**: 3-arm spiral galaxy with orbital velocities and blue/white star colors

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `particle_count` | int | 10000 | Total particles |
| `animation_speed` | float | 1.0 | Base animation speed |
| `spread_radius` | float | 25.0 | Spherical distribution radius |
| `color_variation` | float | 1.0 | Hue spread amount |

## Features

- 10,000-particle system rendered as a single ArrayMesh draw call
- Custom spatial shader with billboard, lifetime curves, and sparkle effects
- Three alternate distribution patterns (spiral, explosion, galaxy)
- Tween-driven parameter animation for pulsing size and speed
- Space-themed environment with volumetric fog
- Per-vertex color encoding for GPU-side color access

## Files

- `buffergeometryparticles.gd` -- Particle data generation, mesh construction, shader, and animation
