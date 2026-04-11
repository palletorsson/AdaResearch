# Randomize Cubes Over Z

Applies increasing randomness to MultiMesh instances along the Z axis. Objects at the front of the grid remain nearly uniform, while objects toward the back receive progressively more random rotation, position jitter, scale variation, and color noise. The effect is a visual gradient from order to chaos.

## Concept Taught

**Gradient of randomness and the spectrum between order and disorder.** This artifact teaches that randomness is not binary -- it exists on a continuum. By mapping the Z position of each instance to a randomness intensity (using a quadratic curve), the artifact creates a spatial gradient where the front is perfectly ordered and the back is heavily randomized. Students see how the same objects can look completely different depending on how much randomness is applied, and how a smooth transition between order and disorder reveals the tipping point where structure breaks down.

## How It Works

1. On ready, the script finds a MultiMeshInstance3D and reads all instance transforms.
2. It scans every instance to find the minimum and maximum Z positions, establishing the Z range.
3. For each instance, a normalized Z factor (0 at the front, 1 at the back) is computed. This is squared (`pow(z_factor, 2.0)`) and multiplied by `randomness_scale_factor` to produce a `randomness` value.
4. Four types of randomization are applied, each scaled by the `randomness` value:
   - **Position jitter**: random offset in X, Y, and Z within `max_position_jitter * randomness`.
   - **Rotation**: random rotation on all three axes within `max_rotation_deg * randomness` degrees.
   - **Scale**: uniform scale interpolated between `min_scale` and `max_scale` based on randomness.
   - **Color** (optional): base gray color is lerped toward a fully random color by the randomness factor.
5. All changes are applied in a single pass at startup.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `multimesh_path` | NodePath | "../GridMultiMesh" | Path to the MultiMeshInstance3D |
| `randomness_scale_factor` | float | 1.0 | Global multiplier for all randomness |
| `max_rotation_deg` | float | 10.0 | Maximum rotation in degrees at full randomness |
| `max_position_jitter` | float | 0.2 | Maximum position offset at full randomness |
| `min_scale` | float | 0.8 | Minimum scale factor |
| `max_scale` | float | 1.6 | Maximum scale factor at full randomness |
| `apply_color_randomness` | bool | true | Whether to randomize instance colors |

## Features

- Quadratic randomness curve concentrates strong randomness toward the back
- Four independent randomization channels: position, rotation, scale, and color
- Color randomness requires `use_colors` enabled on the MultiMesh
- Single-pass application at startup for efficient one-time setup
- Automatic MultiMesh discovery via recursive node search
- Configurable scale factor controls the overall intensity of the gradient

## Files

| File | Purpose |
|------|---------|
| `RandomizeCubesOverZ.gd` | Z-axis randomness gradient applied to MultiMesh instance transforms and colors |
