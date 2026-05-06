# Attractor Sphere

A deformable sphere that bulges toward grabbable attractor points, demonstrating how Gaussian radial basis functions and vertex displacement shaders create organic morphogenesis-like surfaces.

## How It Works

The script creates a high-resolution sphere mesh and applies a custom vertex shader. Attractor points are distributed evenly on a larger surrounding sphere using the Fibonacci lattice algorithm (golden angle spacing). Each attractor is an interactive grab sphere that the user can move in VR. Every frame, the shader receives all attractor positions in object space and displaces each vertex outward along its normal by a sum of Gaussian falloff weights -- vertices close to an attractor get pushed outward, creating smooth bulges. The fragment shader reconstructs surface normals from the displaced geometry using screen-space derivatives (dFdx/dFdy) for correct lighting. Moving the grab spheres reshapes the blob in real time, teaching how scalar fields and distance-based weighting functions drive procedural surface deformation.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `sphere_radius` | float | 0.85 |
| `sphere_rings` | int | 128 |
| `sphere_radial_segments` | int | 192 |
| `attractor_count` | int | 8 |
| `blob_color` | Color | (0.85, 0.6, 0.95, 0.9) |
| `attractor_distance` | float | 1.35 |
| `pull_strength` | float | 1.2 |
| `pull_radius` | float | 0.35 |
| `max_displace` | float | 1.0 |

## Features

- Real-time vertex displacement via custom GLSL shader
- Fibonacci lattice for even attractor distribution
- Interactive VR grab spheres to reshape the surface
- Gaussian radial basis function falloff for smooth bulges
- Screen-space normal reconstruction for correct lighting

## Files

- `attractorsphere.gd` -- Main script (includes inline shader code)
- `attractorsphere.tscn` -- Scene file
