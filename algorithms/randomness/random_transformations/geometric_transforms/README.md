# Geometric Transforms

A 3D visualization that demonstrates random geometric transformations applied to primitive shapes. Original objects are shown alongside their randomly rotated, scaled, and translated counterparts, illustrating how stochastic perturbation of transform parameters reshapes geometry.

## Concept Taught

Geometric transformations -- rotation, scaling, and translation -- are the building blocks of computer graphics and spatial algorithms. This artifact teaches that applying random values to these operations creates visual variety from a small set of base shapes. The concept connects to procedural generation (placing trees with random rotations in a forest), physics simulation (random perturbation of initial conditions), and Monte Carlo methods (sampling transformation space). Seeing the original and transformed objects side by side makes the effect of each random parameter concrete and tangible.

## How It Works

This scene uses the shared `RandomTransformations.gd` script, which manages four sub-visualizations via named child nodes. This scene provides the `GeometricTransforms` child node.

1. **Base object creation** -- Four primitive shapes are defined: box, sphere, cylinder, and cone. Each is rendered twice -- once as a transparent blue "original" in the top row, once as an orange "transformed" copy in the bottom row.
2. **Random transformation** -- Each transformed copy receives:
   - **Random rotation** on all three axes within +/- `rotation_variance` (default PI/4 radians)
   - **Random uniform scale** between `1 - scale_variance` and `1 + scale_variance`
   - **Random translation offset** scaled by 0.3 of `translation_variance`
3. **Time-seeded RNG** -- The random number generator is seeded with `int(time * 10) + seed_offset`, so transformations evolve smoothly over time rather than flickering randomly.
4. **Connection lines** -- Vertical cylinders connect each original-transformed pair, visually linking the "before" and "after" states.
5. **Per-frame rebuild** -- The visualization clears and regenerates every frame, creating a continuously evolving display of random transformations.

## Parameters

The script uses internal variables rather than exports:

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `rotation_variance` | float | PI/4 | Maximum rotation offset per axis (radians) |
| `scale_variance` | float | 0.5 | Scale range: 0.5x to 1.5x |
| `translation_variance` | float | 2.0 | Maximum translation offset (scaled by 0.3) |

## Features

- Side-by-side comparison of original and randomly transformed shapes
- Four primitive types: box, sphere, cylinder, cone
- Time-evolving transformations with seeded RNG for smooth motion
- Transparent blue originals vs emissive orange transforms for clear visual contrast
- Vertical connection lines linking each original-transform pair
- Continuous per-frame regeneration

## Files

| File | Description |
|------|-------------|
| `geometric_transforms.tscn` | Scene file with camera, directional light, and `GeometricTransforms` child node |
| `../RandomTransformations.gd` | Shared script managing all four random transformation sub-demos |
