# Disco Lights

A sphere rendered with a custom shader that produces animated, multi-colored disco lighting effects, demonstrating how GPU shaders transform simple geometry into dynamic color displays.

## How It Works

The scene places a standard sphere mesh and applies a ShaderMaterial driven by the `discoLights.gdshader`. The shader animates color patterns over time using parameters for speed, base color, and intensity. The result is a pulsating, multi-hued light ball that illustrates how fragment shaders compute per-pixel color from mathematical functions of time and surface coordinates.

## Parameters

Shader parameters (set on the ShaderMaterial):

| Parameter | Type | Default |
|-----------|------|---------|
| `time_speed` | float | 4.846 |
| `base_color` | Vector3 | (0.5, 0.5, 0.5) |
| `intensity_factor` | float | 1.867 |

## Features

- GPU-driven animated color patterns
- Configurable speed and intensity
- Single mesh with no GDScript needed -- entirely shader-based

## Files

- `disco_lights.tscn` -- Scene file (references `discoLights.gdshader`)
