# Point Line Grid — Artifacts
*Primitives: Points Build Worlds · F_order · 5 artifacts*

> The grid quantizes. Continuous movement snaps to discrete positions. Your trace, once fluid, becomes a sequence of cells. This is how space becomes computable — and how the body's path becomes data.

The map, read through what it holds — its artifacts in the order you meet them:

## player_trace
![player_trace](/scene-catalog/player_trace.png)

SEE your own motion become a drawable path through time.

`player_trace`

## grid_lines
![grid_lines](/scene-catalog/grid_lines.png)

grid = {x=i*step, z=j*step : i,j ∈ ℤ} — the XZ plane made legible as a lattice of lines

`grid_lines`

## Floating Sphere Field
![Floating Sphere Field](/scene-catalog/floating_sphere_field.png)

A sparse field of soft glowing spheres drifting in the void on a single GPUParticles3D. The subtle successor to the Kusama dot-grid biome layer — presence-by-scarcity instead of overwhelming repetition. Ambient atmosphere for the void around the player.

`floating_sphere_field`

## grab_sphere_point_snap
![grab_sphere_point_snap](/scene-catalog/grab_sphere_point_snap.png)

snap(position) = round(position / grid_size) * grid_size — discretise continuous space

`grab_sphere_point_snap`

## Room Grammar
![Room Grammar](/scene-catalog/room_grammar.png)

Shape grammar for architectural floor plans â€” binary space partitioning recursively splits a rectangle into rooms, draws wall outlines, adds door gaps, and colors rooms by area. The algorithmic foundation behind roguelike dungeon generation.

`room_grammar`
