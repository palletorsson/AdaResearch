# Tiles Explained -- Step-by-Step Tiling Pattern Decomposition

A five-stage visual walkthrough that teaches how **tiling patterns are built from UV coordinates** through progressive transformation. Each stage is displayed on a separate panel, showing one layer of the construction so the learner can see exactly how a complex repeating pattern emerges from simple operations.

## How It Works

The script creates a horizontal row of five `BoxMesh` panels, each with a different `.gdshader` applied via `ShaderMaterial`. A `Label3D` above each panel names the stage. The stages progress as follows:

1. **UV Mapping** -- Raw UV coordinates visualized as color (red = U, green = V). Shows the 0-to-1 coordinate space that all subsequent operations build on.

2. **Tiling** -- `fract(uv * n)` repeats the UV space into an n-by-n grid. Demonstrates how the fractional part of scaled coordinates creates repetition.

3. **Rotation** -- A 2D rotation matrix (`mat2(cos,-sin,sin,cos)`) is applied to the tiled UVs. Shows how matrix multiplication transforms coordinate spaces.

4. **Rotate Tile Pattern** -- Combines tiling and rotation to create rotated shapes within each tile cell. Demonstrates the interaction between repetition and transformation.

5. **Final Pattern** -- The complete pattern with all operations composed: UV mapping, tiling, rotation, and shape rendering produce a complex geometric design from simple math.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `box_spacing` | float | 3.0 | Horizontal spacing between stage panels |

## Features

- Five progressive stages from raw UVs to complete tiling pattern
- Each stage is an independent shader isolating one concept
- Billboard labels for stage identification
- Clean side-by-side comparison layout
- No interactive controls -- pure visual explanation

## Files

- `TilesExplained.gd` -- Panel layout and shader assignment
- `stage1_uv.gdshader` -- Raw UV coordinate visualization
- `stage2_tile.gdshader` -- fract()-based tiling
- `stage3_rotate.gdshader` -- 2D rotation matrix
- `stage4_rotate_pattern.gdshader` -- Combined tiling + rotation
- `stage5_final.gdshader` -- Complete composed pattern
