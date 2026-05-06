# Random Rotate Random XYZ

Randomly rotates MultiMesh cube instances on all three axes (X, Y, Z) each frame, with three selection modes that determine which instances are chosen for rotation: uniform random, Gaussian bell curve centered on a point, or Perlin noise-driven probability fields.

## Concept Taught

**Probability distributions and selection bias.** This artifact teaches how different probability distributions change the spatial pattern of a random process. In uniform mode, every instance has an equal chance of being rotated -- pure equiprobability. In bell curve mode, instances near a center point are far more likely to be selected, following a Gaussian falloff -- demonstrating how a normal distribution concentrates activity around a mean. In noise mode, a scrolling Perlin noise field determines each instance's selection probability -- showing how spatially correlated randomness creates coherent regions of activity and calm. Students see the same rotation operation produce wildly different visual results depending on which distribution governs selection.

## How It Works

1. On ready, the script finds a MultiMeshInstance3D (by path or recursive search) and applies a small random initial rotation to every instance.
2. Each frame, it attempts to select one instance for rotation using the chosen selection mode:
   - **Uniform**: any random index is accepted immediately.
   - **Center Bell**: a Gaussian probability is computed from the instance's distance to `bell_center`, using `exp(-d^2 / 2*sigma^2)`. The instance is accepted via rejection sampling (random roll < probability).
   - **Noise**: a FastNoiseLite sample at the instance's position (scaled and scrolled over time) maps to a 0-1 probability. Values below `noise_threshold` are rejected.
3. Up to 20 attempts are made per frame. If no instance passes the probability check, the frame is skipped.
4. The selected instance receives a small random rotation step on all three axes.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `multimesh_path` | NodePath | "../GridMultiMesh" | Path to the MultiMeshInstance3D |
| `selection_mode` | SelectionMode | UNIFORM | How instances are chosen: UNIFORM, CENTER_BELL, or NOISE |
| `bell_center` | Vector3 | (0,0,0) | Center point for bell curve mode (auto-detects if zero) |
| `bell_radius` | float | 10.0 | Standard deviation (sigma) of the bell curve |
| `noise_source` | FastNoiseLite | null | Noise generator (auto-created if missing) |
| `noise_scale` | float | 1.0 | Scale factor for noise sampling positions |
| `noise_threshold` | float | 0.0 | Minimum probability cutoff for noise mode |
| `noise_scroll_speed` | Vector3 | (0.1, 0.1, 0.1) | Speed at which the noise field scrolls over time |
| `min_degrees` / `max_degrees` | float | -2.01 / 2.01 | Initial rotation range (applied once) |
| `min_step` / `max_step` | float | -2.0 / 2.0 | Per-frame rotation step range in degrees |

## Features

- Three selection modes: uniform, Gaussian bell curve, and Perlin noise field
- Rejection sampling implements non-uniform probability distributions
- Gaussian mode auto-centers on the MultiMesh bounding box if center is unset
- Noise mode supports scrolling for time-varying probability landscapes
- Initial random rotation applied to all instances at startup
- Per-frame incremental rotation on X, Y, and Z axes
- Automatic MultiMeshInstance3D discovery via recursive node search

## Files

| File | Purpose |
|------|---------|
| `RandomRotateRandomXYZ.gd` | Selection mode logic, rejection sampling, initial and per-frame rotation of MultiMesh instances |
