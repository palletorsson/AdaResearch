# Noise Perlin Simplex — Artifacts

> **PREDATES THE 2026-09-10 REPAIR.** This file describes a six-body cast including
> `noise_terrain`, a 100 m footprint that used to be this hall's floor. It was removed on
> 2026-09-10 when the basin was floored, and the hall holds five bodies now: `simplex_noise`,
> `perlin_noise`, `perlin_noise_terrain`, `dark_sphere` and `configurable_portal`. Every
> measurement below was taken in the hall as it stood before that, and is kept as a record of
> it rather than corrected — hand-editing a generated clearance table would be inventing
> numbers. Read `field_notes.md` and `technical.md` for the hall as it is.

*Noise: Entropy with Memory · E_entropy · 6 artifacts*

> Perlin noise: the original coherent gradient noise, 1983. Simplex noise: Ken Perlin's improved version, 2001. Compare them side by side. Perlin has axis-aligned artifacts; Simplex is cleaner in higher dimensions. Evolution of an algorithm. Eighteen years of refinement in two functions (1983 to 2001; the registry's own blurb said thirty, corrected 2026-09-13).

The map, read through what it holds — its artifacts in the order you meet them:

## Simplex Noise
![Simplex Noise](/scene-catalog/simplex_noise.png)

Interactive Simplex noise generation and visualization for high-quality procedural content

`simplex_noise`

## Perlin Noise
![Perlin Noise](/scene-catalog/perlin_noise.png)

Interactive Perlin noise generation and visualization

`perlin_noise`

## Noise Terrain
![Noise Terrain](/scene-catalog/noise_terrain.png)

Interactive procedural terrain generation using various noise algorithms and height mapping

`noise_terrain`

## Dark Sphere
![Dark Sphere](/scene-catalog/dark_sphere.png)

USE a neutral sphere as a reference for scale, silhouette, and atmospheric change.

`dark_sphere`

## Perlin Noise Terrain
![Perlin Noise Terrain](/scene-catalog/perlin_noise_terrain.png)

Interactive 3D terrain generation using Perlin noise algorithms

`perlin_noise_terrain`

## Configurable Portal
![Configurable Portal](/scene-catalog/configurable_portal.png)

Fully configurable portal - any size, rotation, destination. Use: configurable_portal#width:2#height:3#dest_x:5#dest_y:1#dest_z:10 or configurable_portal#dest_map:Trans_RotationSpectacle

`configurable_portal`
