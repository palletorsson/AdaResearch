# Pure Randomness

A particle-based visualization that demonstrates pure, unconstrained randomness -- the most fundamental form of stochastic behavior. Particles receive random forces each frame with no structure or correlation, creating chaotic motion that nevertheless reveals emergent visual patterns to the human eye.

## Concept Taught

Pure randomness is the baseline against which all other forms of structured randomness are compared. This artifact teaches that even completely random systems are not featureless -- our brains find shapes in clouds, constellations in scattered stars, and patterns in noise. It also introduces core ideas like velocity damping, boundary containment, and how speed can be mapped to visual properties like color and emission. Understanding pure randomness is essential before appreciating how algorithms like Perlin noise or procedural generation impose structure on chaos.

## How It Works

This scene uses the shared `extrem_randomness.gd` script with `forced_demo = 0` to lock the visualization to the pure randomness demonstration.

1. **Scattered initialization** -- All 100 particles begin at fully random positions within a 10-unit cube centered at the origin.
2. **Random force accumulation** -- Each frame, every particle receives a random directional force (uniformly distributed across all three axes). This force is added to the particle's current velocity, simulating a continuous random walk in velocity space.
3. **Velocity damping** -- A 0.99 damping factor is applied each frame, preventing velocities from growing unbounded and keeping the system visually manageable.
4. **Boundary enforcement** -- Particles that drift beyond a radius of 7 units are bounced back with a velocity reflection and 0.8 energy retention, keeping the cloud contained.
5. **Speed-to-color mapping** -- Each particle's material emission color and energy are driven by its current speed. Faster particles glow more intensely with a purple-shifted hue, giving an immediate visual read on the kinetic state of the system.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `num_particles` | int | 100 | Number of particles in the visualization |
| `display_time` | float | 1000000.0 | Time before switching demos (set very high to stay on this demo) |
| `enable_narration` | bool | true | Whether narration text is displayed |
| `forced_demo` | int | 0 | Locks the scene to the pure randomness demo |

## Features

- Fully unconstrained random motion with velocity accumulation
- Damping prevents runaway speeds while preserving organic feel
- Boundary reflection with energy loss simulates a contained system
- Emission glow intensity and color tied to particle speed
- Explanatory title and description labels in 3D space
- Serves as the conceptual baseline for all other randomness demos

## Files

| File | Description |
|------|-------------|
| `pure_randomness.tscn` | Scene file -- sets `forced_demo = 0` and long `display_time` |
| `../extrem_randomness.gd` | Shared script with all five randomness demos (pure randomness is demo index 0) |
