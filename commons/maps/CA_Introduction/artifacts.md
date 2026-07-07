# CA Introduction — Artifacts
*Cellular Automata: Local Rules, Global Patterns · lambda_edge · 4 artifacts*

> A grid of cells. Each cell looks at its neighbors and decides: alive or dead, on or off. Simple rules, applied everywhere simultaneously. One generation becomes the next. From trivial local logic, global patterns emerge. This is cellular automata — computation distributed across space.

The map, read through what it holds — its artifacts in the order you meet them:

## Dark Sphere
![Dark Sphere](/scene-catalog/dark_sphere.png)

USE a neutral sphere as a reference for scale, silhouette, and atmospheric change.

`dark_sphere`

## Persian Rug
![Persian Rug](/scene-catalog/persian_rug.png)

Persian Rug Cellular Automata.

`persian_rug`

## Grid Substrate Runner
![Grid Substrate Runner](/scene-catalog/grid_substrate_runner.png)

Integrated substrate component — single-cell artifact that mounts visibility (and optionally colour) mutators on the MAP'S existing GridMultiMesh. Same integration shape as gridcolorizer: doesn't build its own multimesh, finds the floor that's already there. Cycles Wolfram CA, fractal, and BFS-frontier expressions on the actual cubes the player walks. Floor-plan SPAWN_LARGEST keeps reachability honest.

`grid_substrate_runner`

## Line Network CA
![Line Network CA](/scene-catalog/line_network_ca.png)

Base class visualization for line-based cellular automata.

`line_network_ca`
