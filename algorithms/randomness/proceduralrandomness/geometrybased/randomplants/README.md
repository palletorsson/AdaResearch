# Random Plants -- Procedural Plant Variety Generator

A procedural ecosystem generator that creates diverse plant life by randomizing type, size, shape, color, and rotation. This artifact teaches the concept of **probability-weighted random selection** -- how adjusting probability sliders for different categories (trees, bushes, flowers, grass) controls the distribution of a procedural system while maintaining natural-looking variety.

## How It Works

1. **Type selection** -- Each plant is assigned a type using weighted probabilities. The four type probabilities (tree, bush, flower, grass) are normalized to sum to 1.0, then a uniform random value selects the type.

2. **Tree generation** -- Three crown styles are randomly chosen:
   - Sphere crown (single CSGSphere3D)
   - Cone crown (CSGCylinder3D with `cone = true`) for pine-like trees
   - Multi-sphere crown (3--5 overlapping spheres) for oak-like canopies
   - Each tree has a cylindrical trunk with randomized height and color variation.

3. **Bush generation** -- Two styles: rounded (single sphere) or irregular (2--4 overlapping spheres). 30% of bushes sprout small colored flower spheres on their surface.

4. **Flower generation** -- Three styles:
   - Basic (single colored sphere on a stem)
   - Daisy-like (yellow center with 5--12 white petals arranged radially)
   - Complex (main bloom with 2--4 additional parts and exotic colors)
   - 70% of flowers grow leaves (flattened spheres) on their stems.

5. **Grass generation** -- Clumps of 5--14 thin cylinders in short/medium/tall varieties, with directional tilt. 20% of taller grass clumps include tiny flower spheres.

6. All elements receive randomized rotation, scale, and color variation controlled by the export parameters.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `number_of_plants` | 100 | Total plant count before density filtering |
| `area_size` | 20.0 | Side length of the square planting area |
| `plant_density` | 0.8 | Fraction of plants actually placed (0.0--1.0) |
| `tree_probability` | 0.2 | Relative weight for trees |
| `bush_probability` | 0.3 | Relative weight for bushes |
| `flower_probability` | 0.3 | Relative weight for flowers |
| `grass_probability` | 0.2 | Relative weight for grass |
| `size_variation` | 0.5 | How much size can vary (0.0--1.0) |
| `color_variation` | 0.6 | How much color can vary (0.0--1.0) |
| `rotation_variation` | 0.2 | How much tilt can vary (0.0--1.0) |
| `leaf_density_variation` | 0.4 | Variation in leaf/foliage density (0.0--1.0) |

## Features

- Probability-weighted type selection with normalization
- Three distinct tree crown archetypes (sphere, cone, multi-sphere)
- Daisy-style radial petal arrangement using trigonometric placement
- Grass clumps with directional tilt and height-dependent color shifts
- Cascading variation: global parameters multiply with per-instance randomness
- CSG-based geometry for interactive use in Godot editor

## Files

| File | Description |
|------|-------------|
| `random_plants.gd` | Plant variety generator with weighted random selection |
| `random_plants.tscn` | Scene file for the plant generator |
