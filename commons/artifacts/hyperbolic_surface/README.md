# Hyperbolic Surface

A procedurally generated saddle-shaped surface demonstrating negative Gaussian curvature. This teaches the concept of hyperbolic geometry, where the surface curves in opposite directions along perpendicular axes.

## How It Works

The surface is generated using the equation y = curvature * (x^2 - z^2) / 2, which produces a saddle (hyperbolic paraboloid). A SurfaceTool builds a triangle mesh by sampling a grid of points across the XZ plane, computing the height at each vertex, and generating normals for proper lighting. The curvature parameter controls how strongly the surface bends.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `size` | float | 0.5 |
| `resolution` | int | 20 |
| `curvature` | float | 1.0 |

## Features

- Procedural saddle mesh built with SurfaceTool and auto-generated normals
- Adjustable curvature strength and mesh resolution
- Label displaying surface type and Gaussian curvature sign (K < 0)

## Files

- `hyperbolic_surface.gd` -- Main script
- `hyperbolic_surface.tscn` -- Scene file
