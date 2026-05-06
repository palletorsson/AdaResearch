# Emergent Behavior Demo

A standalone demo that isolates the emergent behavior (flocking/swarming) demonstration from the parent particle randomness visualizer. This artifact teaches the concept of **emergence** -- how complex, coordinated group behavior arises from simple individual rules combined with randomness, without any central coordinator.

## How It Works

This scene uses the same `extrem_randomness.gd` script from the parent `particlerandomness` directory, but configures it to lock on Demo 3 (Emergent Behavior) indefinitely:
- `forced_demo` is set to 3 in the scene file.
- `display_time` is set to 1,000,000 seconds to prevent cycling.

### The Flocking Algorithm

100 particles start clustered near the origin and follow four rules each frame:

1. **Separation** (weight 0.05) -- Each particle checks its distance to every other particle. If closer than 0.5 units, it steers away proportional to `1/distance`.

2. **Alignment** (weight 0.03) -- Each particle adjusts its velocity toward the flock's average velocity, creating coordinated directional movement.

3. **Cohesion** (weight 0.01) -- Each particle steers toward the flock's center of mass, keeping the group together.

4. **Random perturbation** (weight 0.01) -- A small random force prevents the flock from settling into a static state, maintaining liveliness.

Speed is capped at 2.0 units/second. Particle colors reflect distance from the flock center using sine-based hue shifting, making the group structure visible.

## Parameters

Inherited from `extrem_randomness.gd`:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `forced_demo` | 3 | Locks to emergent behavior demo |
| `display_time` | 1,000,000 | Prevents demo cycling |
| `num_particles` | 100 | Flock size |

## Features

- Classic boids algorithm (Reynolds, 1987) with four steering forces
- Random perturbation prevents convergence to equilibrium
- Distance-based coloring reveals flock density and structure
- Speed limiting for stable simulation
- Standalone scene for focused exploration of emergence

## Files

| File | Description |
|------|-------------|
| `emergent_behavior.tscn` | Scene file locking the parent script to the flocking demo |

The script `extrem_randomness.gd` is located in the parent `particlerandomness/` directory.
