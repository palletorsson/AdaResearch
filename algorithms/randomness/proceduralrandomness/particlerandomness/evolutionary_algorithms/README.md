# Evolutionary Algorithms Demo

A standalone demo that isolates the evolutionary algorithms demonstration from the parent particle randomness visualizer. This artifact teaches the concept of **evolution as guided randomness** -- how random mutations combined with fitness-based selection can solve optimization problems, producing solutions that no purely random or purely deterministic approach would find alone.

## How It Works

This scene extends `extrem_randomness.gd` via `EvolutionaryAlgorithmsDemo.gd`, which locks the visualizer to Demo 4 (Evolutionary Algorithms) permanently.

### The Evolutionary Algorithm

1. **Fitness target** -- A point orbits in 3D space along a Lissajous curve: `(3*sin(t*0.5), 2*cos(t*0.7), sin(t))`. The fitness of each particle is its distance to this moving target.

2. **Selection** -- Every frame, all 100 particles are sorted by fitness (closest to target = most fit). The top 10% are designated "winners."

3. **Winner behavior** -- Winners move directly toward the target at speed 2.0 with a small random perturbation (+/-0.5 on each axis). They are visually marked:
   - Gold color with emissive glow
   - Enlarged radius (0.08 vs 0.05)

4. **Follower behavior** -- The remaining 90% of particles each pick a random winner to follow:
   - Velocity = 90% of current velocity + 50% toward the chosen winner's position
   - A larger random mutation (+/-1.0 on each axis, scaled by 0.3) is added
   - This high mutation rate ensures exploration of the search space

5. **Visual encoding** -- Rank is encoded in:
   - Color: high-fitness particles are brighter (warm tones), low-fitness are darker (cooler)
   - Size: particles shrink linearly with worse rank

The result is a swarm that tracks a moving target through a combination of selection pressure and random exploration -- directly analogous to biological evolution.

## Parameters

Inherited from `extrem_randomness.gd`:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `DEMO_INDEX` | 4 | Locks to evolutionary algorithms demo |
| `num_particles` | 100 | Population size |

## Features

- Fitness-proportional selection (top 10% elite)
- Random mutation with configurable magnitude
- Moving fitness target on a Lissajous orbit
- Visual encoding of fitness rank via color and size
- Extends parent script, overriding `_ready()` and `_process()` to lock demo mode
- Demonstrates exploration vs. exploitation tradeoff

## Files

| File | Description |
|------|-------------|
| `EvolutionaryAlgorithmsDemo.gd` | Script extending extrem_randomness.gd, locked to demo 4 |
| `evolutionary_algorithms.tscn` | Scene file for the standalone evolutionary demo |

The parent script `extrem_randomness.gd` is located in the `particlerandomness/` directory.
