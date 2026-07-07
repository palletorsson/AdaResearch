# ISO FlatTerrain — Artifacts
*Isosurfaces: Implicit to Explicit · F_order · 3 artifacts*

> Two terrains. Same algorithm, different noise. The flat landscape rolls gently — marching cubes tracing where density crosses zero, converting a scalar field into walkable ground. The overhang landscape breaks the contract. Rock juts sideways, canopies form from nothing, gravity loses its vote. Same threshold, same 256-case lookup, but the noise field now curves back on itself.

The map, read through what it holds — its artifacts in the order you meet them:

## mc_flat_landscape
![mc_flat_landscape](/scene-catalog/mc_flat_landscape.png)

GPU flat terrain — marching cubes landscape with gentle noise.

`mc_flat_landscape`

## mc_overhang_landscape
![mc_overhang_landscape](/scene-catalog/mc_overhang_landscape.png)

GPU overhang terrain — landscape with overhanging rock formations.

`mc_overhang_landscape`

## mc_terrain_demo
![mc_terrain_demo](/scene-catalog/mc_terrain_demo.png)

CPU terrain generation demo — marching cubes terrain with configurable noise parameters.

`mc_terrain_demo`
