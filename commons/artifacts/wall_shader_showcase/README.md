# Wall Shader Showcase

Replaces the GridMultiMesh material with GPU shaders from the shader library, cycling through different visual effects on a timer or displaying a specific shader.

## How It Works

The showcase finds the scene's GridMultiMesh and replaces its material override with a ShaderMaterial loaded from the shader library at `res://commons/resourses/shaders/`. When multiple shaders are configured in a list, it cycles through them at a configurable interval. The original material is restored when the node exits the tree.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `shader_name` | String | "voronoiShader" |
| `cycle_interval` | float | 6.0 |
| `emission_strength` | float | 0.8 |

## Features

- Applies any shader from the shader library to the grid's MultiMesh
- Cycles through a configurable comma-separated list of shaders
- Default library includes voronoi, tartan, Rothko, Truchet, reaction diffusion, wallpaper tile, slime, disco grid, pearlescent, and coffee swirl
- Automatically sets emission and tile scale parameters when supported
- Restores original material on exit
- Supports `apply_grid_config()` with `shader`, `shader_list`, `cycle_interval`, and `emission_strength` keys

## Files

- `wall_shader_showcase.gd` -- Shader loader and cycling controller
- `wall_shader_showcase.tscn` -- Scene file
