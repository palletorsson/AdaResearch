# ISO Metaballs — Artifacts
*Isosurfaces: Implicit to Explicit · F_order · 4 artifacts*

> Each metaball is a point radiating influence. A distance field — strongest at center, fading outward. One sphere alone is trivial. But place two near each other and their fields sum. Where combined density crosses the threshold, a surface appears. Not two objects touching. One object, born from proximity.

The map, read through what it holds — its artifacts in the order you meet them:

## metaball_world
![metaball_world](/scene-catalog/metaball_world.png)

Full marching cubes metaball system — proper isosurface extraction from metaball field. Animated, with collision. The real deal.

`metaball_world`

## Metaballs
![Metaballs](/scene-catalog/metaballs.png)

Interactive metaball visualization demonstrating implicit surface modeling

`metaballs`

## Raymarched Metaballs
![Raymarched Metaballs](/scene-catalog/raymarched_metaballs.png)

Shader raymarched metaballs — 9 animated balls rendered via SDF raymarching on a cube mesh. Real-time implicit surface visualization.

`raymarched_metaballs`

## nakama_metaballs
![nakama_metaballs](/scene-catalog/nakama_metaballs.png)

Kouhei Nakama-inspired organic metaballs — 60 animated blobs with subsurface scattering shader. Approximated mesh via sphere deformation.

`nakama_metaballs`
