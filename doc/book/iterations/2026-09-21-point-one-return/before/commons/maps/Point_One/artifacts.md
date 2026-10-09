# Point One — Artifacts
*Primitives: Points Build Worlds · F_order · 9 artifacts*

> Before the point, infrastructure. The origin is not a point but a prerequisite — coordinate systems, render loops, the void made addressable. Point_One is the first mark: position without extension, existence without duration. You arrive late. The system was running.

The map, read through what it holds — its artifacts in the order you meet them:

## Point Zero
![Point Zero](/scene-catalog/origin.png)

(0, 0, 0) — the reference from which all coordinates are measured

`origin`

## Lab Room
![Lab Room](/scene-catalog/lab_room.png)

Procedurally-generated Half-Life-style modern test chamber that frames a workbench. White tile floor, observation glass, accent-colored strip naming the QFEP phase, signage like 'TEST CHAMBER λ-S'. Takes a mounted_artifact_scene path and instantiates that workbench at the central plinth. The room IS the staging — same script, different DNA = different chamber.

`lab_room`

## Folding Past
![Folding Past](/scene-catalog/folding_past.png)

Animated accordion fold representing time/the past collapsing into the present.

`folding_past`

## grid_lines
![grid_lines](/scene-catalog/grid_lines.png)

grid = {x=i*step, z=j*step : i,j ∈ ℤ} — the XZ plane made legible as a lattice of lines

`grid_lines`

## frame_counter_display
![frame_counter_display](/scene-catalog/frame_counter_display.png)

label.text = Engine.get_process_frames() — a live counter of rendered frames since startup

`frame_counter_display`

## You Are Here
![You Are Here](/scene-catalog/you_are_here.png)

A text decal on the floor - YOU ARE HERE lying flat underfoot, the wayfinding locator. A flat indexical inscription you stand ON. TextMesh. pride_gradient reclaims the corporate blue dot.

`you_are_here`

## Fontana Puncture
![Fontana Puncture](/scene-catalog/fontana_puncture.png)

A solid cube with an oversized sphere subtracted (CSG, baked) so the void breaches every face - Fontana's Concetto Spaziale in 3D. A luminous point floats at the centre.

`fontana_puncture`

## Floating Sphere Field
![Floating Sphere Field](/scene-catalog/floating_sphere_field.png)

A sparse field of soft glowing spheres drifting in the void on a single GPUParticles3D. The subtle successor to the Kusama dot-grid biome layer — presence-by-scarcity instead of overwhelming repetition. Ambient atmosphere for the void around the player.

`floating_sphere_field`

## CoordinateSystem3M
![CoordinateSystem3M](/scene-catalog/CoordinateSystem3M.png)

FEEL orientation as embodied direction by standing inside the coordinate frame

`CoordinateSystem3M`
