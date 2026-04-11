# Vertical Wave Lines

A GPU-driven wave visualisation that teaches **wave functions as scalar fields** by rendering a grid of vertical lines whose heights are modulated by a shader-computed wave equation. The result is a 3D surface that ripples and flows, demonstrating how a wave function assigns an amplitude to every point in 2D space.

## How It Works

A `MultiMesh` of thin box columns is laid out in a rectangular grid. Each box has a base height of 1.0 and is positioned so it grows upward from the floor. The actual wave animation happens entirely in a custom vertex shader (`wave_lines.gdshader`), which modifies each instance's Y scale and colour based on its XZ world position and the current time.

The shader computes wave height using the instance's position and Godot's built-in `TIME` uniform, applying `wave_frequency` and `wave_amplitude` parameters to create propagating ripple patterns. Columns are coloured by interpolating between `base_color` and `wave_color` based on their current height, creating a heatmap effect that makes wave peaks visually distinct from troughs.

All exports use setter functions that immediately update the grid or shader uniforms, enabling live tuning in the editor (the script is `@tool`-enabled). The grid rebuilds when size or spacing changes; the shader parameters update without rebuilding geometry.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `grid_size` | Vector2i | (32, 32) | Number of columns in X and Z |
| `spacing` | float | 0.5 | Distance between adjacent columns |
| `line_thickness` | float | 0.05 | Width of each column (X and Z) |
| `line_height` | float | 3.0 | Maximum column height |
| `base_color` | Color | dark blue | Colour at wave troughs |
| `wave_color` | Color | light blue | Colour at wave peaks |
| `speed` | float | 2.0 | Wave propagation speed |
| `frequency` | float | 0.5 | Spatial frequency of the wave |
| `amplitude` | float | 3.0 | Maximum wave height |

## Features

- GPU-accelerated wave animation via custom vertex shader
- `MultiMesh` instancing for efficient rendering of 1000+ columns
- `@tool` support with live parameter editing
- Setter functions for immediate visual feedback
- Colour interpolation between base and wave colours
- Grid auto-centering around the origin
- Columns grow from floor level (Y-offset compensated)

## Files

| File | Description |
|------|-------------|
| `vertical_wave_lines.gd` | Grid setup, MultiMesh management, and shader uniform control |
| `wave_lines.gdshader` | Vertex shader for wave height and colour computation |
| `vertical_wave_lines.tscn` | Scene file with MultiMeshInstance3D |
