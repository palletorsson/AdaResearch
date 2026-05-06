# Tesla Sparks

Interactive electrical spark effect between two grabbable spheres.

## Key Files
- `tesla_sparks.gd` — Extends Node3D; generates electrical spark lines between two nodes using ImmediateMesh; randomized path with configurable segments, line_width, sphere_scale
- `tesla_grab.gd` — Extends XRToolsPickable; handles grab interactions for tesla sphere; tracks controller state; updates TaskManagerController progress on grab
- `tesla_sparks.tscn` — Two RigidBody3D tesla spheres (Low/High) with grab interaction, yellow emission material, Label3D debug, Camera3D
- `tesla_sphere.tscn` — Single grabbable tesla coil end piece
