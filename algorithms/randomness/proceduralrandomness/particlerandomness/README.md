# Particle Randomness -- Beauty of Randomness Visualizer

A five-demo carousel that visualizes different categories of randomness through particle behavior. This artifact teaches the concept that **randomness is not a single thing** -- it spans a spectrum from pure chaos to constrained, structured, and even evolutionary forms, each with distinct visual signatures and real-world applications.

## How It Works

The script manages 100 particles (CSGSphere3D nodes) that are repositioned and recolored as the demo cycles through five modes every `display_time` seconds. Each particle stores velocity and original color as metadata.

### Demo 1: Pure Randomness

Each particle receives a random force every frame. Damping (0.99x) prevents runaway speeds. Particles bounce off a radius-7 boundary sphere. Emission color scales with speed -- faster particles glow brighter. This shows how fully random motion creates unpredictable but visually engaging patterns.

### Demo 2: Perlin Noise

Particles are placed in a grid and moved by a 3D flow field generated from a simplified noise function (`sin/cos` composition). Position and time are inputs, creating smooth, coherent motion. Colors cycle based on position and time using sine waves. This demonstrates structured randomness that mimics natural phenomena.

### Demo 3: Procedural Patterns

Particles are arranged in a circle and driven by spiral forces (tangential to their radial position) combined with sinusoidal oscillation. Particle size pulses based on distance from center. Colors shift with angle and distance. This shows how combining randomness with mathematical constraints produces ordered beauty.

### Demo 4: Emergent Behavior (Flocking)

Three classic boids rules plus a random force:
- **Separation** -- Repel from neighbors closer than 0.5 units.
- **Alignment** -- Steer toward the flock's average velocity.
- **Cohesion** -- Move toward the flock's center of mass.
- **Random** -- Small random perturbation each frame.
Speed is capped at 2.0. Colors reflect distance from the flock center. This demonstrates how simple local rules with randomness produce complex collective behavior.

### Demo 5: Evolutionary Algorithms

A moving target orbits in 3D space. Particles are sorted by distance to the target (fitness). The top 10% ("winners") chase the target directly with slight randomness and glow gold. The remaining particles pick a random winner to follow, with larger random mutations. Size and color encode fitness rank. This shows how selection pressure combined with random variation drives optimization.

### UI

Label3D nodes display the demo title and a multi-paragraph description for each mode. The description text explains the real-world significance of each randomness type.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `num_particles` | 100 | Number of particles in the system |
| `display_time` | 10.0 | Seconds per demo before cycling |
| `enable_narration` | true | Placeholder for audio narration |
| `forced_demo` | -1 | Lock to a single demo index (-1 = cycle) |

## Features

- Five distinct randomness paradigms in a single artifact
- Boids flocking with separation, alignment, cohesion, and noise
- Evolutionary selection with fitness ranking and mutation
- Perlin-like noise flow field (sin/cos approximation)
- Spiral procedural patterns with distance-based size pulsing
- Metadata-based velocity storage on CSG nodes
- Label3D explanatory text for educational context

## Files

| File | Description |
|------|-------------|
| `extrem_randomness.gd` | Five-demo randomness visualizer with particle system |
| `extrem_randomness.tscn` | Scene file for the full demo carousel |
