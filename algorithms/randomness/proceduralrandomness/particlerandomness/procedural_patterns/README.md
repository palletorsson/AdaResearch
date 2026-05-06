# Procedural Patterns

A particle-based visualization that demonstrates how combining randomness with mathematical rules produces organized, repeating structures. Procedural patterns sit between pure chaos and rigid design -- they use constraints and equations to channel random values into coherent, aesthetically compelling arrangements.

## Concept Taught

Procedural generation is the engine behind infinite game worlds, generative art, and algorithmic music. This artifact teaches that randomness does not have to mean disorder. By applying mathematical constraints -- spirals, oscillations, periodic functions -- to random starting conditions, complex and beautiful patterns emerge. Every run produces a unique variation while maintaining overall coherence, illustrating how games generate endless content from compact rule sets.

## How It Works

This scene uses the shared `extrem_randomness.gd` script with `forced_demo = 2` to lock the visualization to the procedural patterns demonstration.

1. **Circular initialization** -- Particles begin in a circular arrangement with randomized radii, establishing a structured starting pattern.
2. **Spiral motion** -- Each frame, particles experience a tangential force computed from their angle and distance to the origin, creating a spiral flow. The force strength is inversely proportional to distance, producing tighter spirals near the center.
3. **Oscillation overlay** -- A secondary sine/cosine oscillation is added per particle (offset by particle index), introducing gentle variation that prevents rigid mechanical motion.
4. **Dynamic sizing** -- Particle radii pulse based on their distance from the center and elapsed time, using `sin(distance * 2 - time * 2)` to create a wave-like breathing effect across the pattern.
5. **Position-based coloring** -- Colors are determined by each particle's angle, distance, and time, producing a smoothly rotating palette that reinforces the spiral structure.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `num_particles` | int | 100 | Number of particles in the visualization |
| `display_time` | float | 1000000.0 | Time before switching demos (set very high to stay on this demo) |
| `enable_narration` | bool | true | Whether narration text is displayed |
| `forced_demo` | int | 2 | Locks the scene to the procedural patterns demo |

## Features

- Spiral particle dynamics driven by polar coordinate math
- Oscillating secondary motion adds organic variation
- Pulsing particle sizes create a wave-like visual rhythm
- HSV-style color cycling tied to spatial structure
- Explanatory title and description labels in 3D space

## Files

| File | Description |
|------|-------------|
| `procedural_patterns.tscn` | Scene file -- sets `forced_demo = 2` and long `display_time` |
| `../extrem_randomness.gd` | Shared script with all five randomness demos (procedural patterns is demo index 2) |
