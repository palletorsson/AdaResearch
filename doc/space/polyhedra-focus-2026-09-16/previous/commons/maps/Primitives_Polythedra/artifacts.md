# Primitives Polythedra — Artifacts
*Primitives: Points Build Worlds · F_order · 11 artifacts*

> A trihedron is a geometric configuration where three triangular faces meet at a single vertex, forming a corner of space. It is not a closed solid by itself, but a spatial junction - an elementary expression of volume beginning to form.

The map, read through what it holds — its artifacts in the order you meet them:

## Lab Room
![Lab Room](/scene-catalog/lab_room.png)

Procedurally-generated Half-Life-style modern test chamber that frames a workbench. White tile floor, observation glass, accent-colored strip naming the QFEP phase, signage like 'TEST CHAMBER λ-S'. Takes a mounted_artifact_scene path and instantiates that workbench at the central plinth. The room IS the staging — same script, different DNA = different chamber.

`lab_room`

## Path Watchdog
![Path Watchdog](/scene-catalog/path_watchdog.png)

Runtime referee for the path-and-block game. BFS-checks every half-second whether a walkable route still exists from the player to the teleporter; draws it as a floor ribbon (green open / red blocked) and restarts the level if the path stays blocked past a grace window.

`path_watchdog`

## Path Game Controller
![Path Game Controller](/scene-catalog/path_game_controller.png)

Win/lose controller for the path-and-block game. Wins on reaching the teleporter OR befriending every foe; loses on the watchdog's blocked-path timeout. Pops a pixel thumb over a befriended foe and a pixel heart on a win.

`path_game_controller`

## 1.0.2 Interactive Point — Force Catalyst
![1.0.2 Interactive Point — Force Catalyst](/scene-catalog/interactive_point_origin_force.png)

Force-catalyst variant of interactive_point_origin. Starts as a plain point; on pickup a vertex shader morphs the surface into a pulsing 'force field' shell. While held with the morph engaged, nearby RigidBody3D objects feel an inverse-square pull toward the artifact. With both hands closed (the OrbGestureDetector two-hand gesture), the artifact spits a luminous projectile ball forward.

`interactive_point_origin_force`

## The Catalyst
![The Catalyst](/scene-catalog/becoming_catalyst.png)

An evolving hand force that grows alongside the player. Not a weapon of destruction but a tool of transformation, becoming, and boundary dissolution. Each Lab sequence unlocks a new expressive mode — from slow cubes to calming fields to swarm intelligence.

`becoming_catalyst`

## Snap Tetrahedron Puzzle
![Snap Tetrahedron Puzzle](/scene-catalog/snap_tetrahedron_puzzle.png)

Interactive puzzle where connecting 4 snap points forms a tetrahedron that spawns a cube.

`snap_tetrahedron_puzzle`

## Floating Sphere Field
![Floating Sphere Field](/scene-catalog/floating_sphere_field.png)

A sparse field of soft glowing spheres drifting in the void on a single GPUParticles3D. The subtle successor to the Kusama dot-grid biome layer — presence-by-scarcity instead of overwhelming repetition. Ambient atmosphere for the void around the player.

`floating_sphere_field`

## grab_trihedron
![grab_trihedron](/scene-catalog/grab_trihedron.png)

trihedron — 4 vertices, 3 triangular faces and 1 quad base: the wedge as 3D primitive

`grab_trihedron`

## Basic Cube Scene
![Basic Cube Scene](/scene-catalog/cube_scene.png)

TEST how cubes can split, snap, scale, and recombine while remaining the basic reference primitive.

`cube_scene`

## Tentacle Placer
![Tentacle Placer](/scene-catalog/tentacle_placer.png)

A 6-bone FABRIK3D tentacle on a pedestal (same IK family as octapod_crawler — steerable by target position). The cycle is: REST_INITIAL (hold upright 10s) → GRAB_UP (first sky reach) → DWELL_PRE → render cube in mid-air → DWELL_POST → DESCEND (carrying cube) → place pyramid → DWELL_PLACE → RISE (clean vertical lift above the just-placed pyramid) → TRANSIT (horizontal traverse at sky height to next placement) → REST → repeat. The RISE + TRANSIT split (instead of a diagonal cool-down) gives an unambiguous up-then-over silhouette. Defaults are slow (6s per travel phase) so the gesture reads as ritual. Wire `placed(index, world_position)` and `rendered(index, world_position)` signals.

`tentacle_placer`

## pyramid_edit
![pyramid_edit](/scene-catalog/pyramid_edit.png)

Interactive pyramid demo with grab handles to reshape the base and apex.

`pyramid_edit`
