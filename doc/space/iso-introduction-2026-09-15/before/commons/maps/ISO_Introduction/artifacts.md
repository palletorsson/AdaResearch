# ISO Introduction — Artifacts
*Isosurfaces: Implicit to Explicit · F_order · 2 artifacts*

> A 3D noise field fills invisible space with density values. Marching cubes walks the grid cube by cube — 256 possible configurations, one lookup table — and extracts geometry wherever density crosses a threshold. The algorithm doesn't know what it's building. It only knows inside from outside.

The map, read through what it holds — its artifacts in the order you meet them:

## Science Screen
![Science Screen](/scene-catalog/science_screen.png)

COMPARE a 3D artifact with its 2D abstraction and see what structure survives projection.

`science_screen`

## voxel_noise_demo
![voxel_noise_demo](/scene-catalog/voxel_noise_demo.png)

CPU marching cubes with 3D noise — the working cave/blob generator. Glass shader with wireframe overlay.

`voxel_noise_demo`
