# Extrude — the plane is pulled into a solid

A study kit of the Godot course, chapter 45, part 1: after *Plane*, before the cube. A walked outline is pulled up into a solid by one function of the learner's own, `extrude(outline, rise, top)`, which returns a mesh; a taper narrows the top; a collider made from the same mesh lets a marble and a walker meet it.

This is a new project: import this folder's `project.godot` in the Project Manager of Godot 4.6. `extrude.tscn` is the main scene. Follow [TUTORIAL.md](TUTORIAL.md). The kit starts from the kit base and holds nothing of another chapter.

## What is in the folder

- `extrude.tscn` inherits `supplied/base.tscn` (floor, sky, light, camera) and adds `Solid` (an empty `MeshInstance3D` with `Body`, a `StaticBody3D`, and `Shape`, an empty `CollisionShape3D`, under it), the supplied `Marble` and `Walker`, and a `Readout`. Its root runs `extrude.gd`.
- `extrude.gd` is the learner's: the walk as a list of eight corners, three exported fields (`height` 0.8, `taper` 1.0, `spire` false), `_ready()`, `_process()` (M drops the marble over the walk's centre), `centre_of()` and `extrude()`. The tutorial rebuilds it in eleven code blocks.
- `supplied/` is the kit base's folder, unchanged: the same 15 files as in `../kit-base/` and `../my-room/`.
- `borrowed/walk.tscn`, `borrowed/walk.gd`: the recorder of Trace and Plane, made small and changed for the keys. Contract: walk the Hand with the four move keys; Space closes the walk and prints it as one line of code, `var walk: Array[Vector3] = [...]`, the corners on the floor, clockwise seen from above whichever way it was walked, rounded to centimetres. It keeps the places where the Hand starts, turns and stops, not a position every few centimetres. The Hand cannot leave a square of 1.6 m. The walk the kit ships is what this recorder printed for seven legs held as actions from a script.
- `borrowed/grammar_extrude.gd`: a small version of what the project's MeshGrammar does with `MeshData.from_array_mesh()` and `ExtrudeFaceOp` (`commons/mesh_grammar/` in the Ada Research repository). Contract: `extrude_up(mesh, distance, scale) -> ArrayMesh` pushes every triangle that faces up (within 60 degrees) out along its normal and scales it toward its own middle. It keeps the project's floors (0.01 m², an edge ratio of 0.05), welds corners in one place, and turns every triangle over on the way in and out, because MeshGrammar winds counter-clockwise and Godot's renderer clockwise.
- `guests/extrude/`: the body the kit hands to the room. `extrude.tscn` and `plinth.gd`: a plinth extruded from the walk, height 0.8, taper 0.8, with a collider and a plate that says its height and taper. It names nothing outside its folder, writes its colours out, declares no `class_name`, and carries its own copy of `extrude()`.
- `verify.gd`, `sheet.gd`, `verification.json`, `sheet.json`, `sheet.png`, `process.png`, `FIELD_NOTE.md`.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 56 checks and writes `verification.json`; its exit code is the number that failed. A fresh copy with no `.godot/` passed 56 of 56 with no import step, in about 55 seconds (the walker walks in real time) and in a few seconds with `--fixed-fps 60`, with the same lines. `sheet.gd` needs a window: it takes about 16 seconds, writes `sheet.png`, `process.png`, `sheet.json` and the stills in `stills/`, and closes by itself.

## The planted fault

The outline names no planted bug for this chapter. The lesson uses the one the code itself produces. Written as Plane taught it, with `generate_normals()` and nothing else, the solid comes out shaded round: `SurfaceTool` averages the normals of all vertices that stand in one place, unless its smooth group is set to -1. The top's first normal reads `(-0.18654, 0.903099, -0.386801)` where (0, 1, 0) is meant; none of the 28 triangles keeps its own normal; Godot logs nothing. With `surface.set_smooth_group(-1)` it reads `(0.0, 1.0, -0.000015)` from the mesh, and `SurfaceTool` held exactly (0, 1, 0) before the mesh packed it. From the side the two solids differ on 18.98% of the still, all inside the outline. In Plane the fault could not show: one flat face.

Two more faults stand under *Try*. The walk in the other order gives a solid with every front facing in: the marble falls through the top to the floor inside (0.098 m), the walker is stopped by the wall all the same, and nothing is logged. `walk[i + 1]` in the edge loop gives `Out of bounds get index '8' (on base: 'Array[Vector3]')`.

## What the checks cover

The project, its nine actions, the 15 supplied files, tabs, no named class. The walk: 8 corners, on the floor, inside the square, clockwise, 1.015 m². `extrude()`: 84 vertices, 28 triangles; walls level and outward; caps up and down; every triangle its own normal; closed (every edge shared by two triangles running opposite ways); volume 0.8117 m³, the area times the height; 16 places; indexed, 59 vertices and not 48, because the bottom's normals differ in the sign of a zero; its box. The taper at 1.0, 0.6, 0.2 and 0.0: the top's area, the volume (0.8117, 0.5303, 0.3355, 0.2706 m³), the pyramid's nine places. The smooth default, as Godot does it. The borrowed extrude: what it welds, what "up" is, six spires for six triangles, each about its own middle; closed and outward; the counts at four tapers against the numbers the project's own code gave. The scene: 180 frames with no error, its printed line, the segments on the edges, the collider, the exported fields. The marble on each taper, 1 cm off the pyramid's point, and through the mesh with the collider taken away. The walker against 0.8 m, onto 0.3 m, up a pyramid of 0.3 m. The walk in the other order. The loud index. The scene with `spire` ticked. The recorder: our seven legs give the shipped walk within 5 cm; a loop walked the other way comes out clockwise; a straight run in two goes is one edge; the Hand stops at 0.75 m. The guest: nothing outside its folder, no class name, on the ground, inside the place, the same mesh as the kit's function, its plate, a marble on it. The room task with another walk and a rider.

## Negative tests

Eleven faults were planted, one at a time, in fresh scratch copies; each failed `verify.gd`. The number is the checks that failed: no `set_smooth_group(-1)` (6); the walk reversed in `_ready()` (11); `walk[i]`, `walk[i + 1]` (16, with the script error named); no collider line (11); no bottom cap (15); one wall triangle wound the other way (13); the taper about the origin instead of the centre (4); the guest using `supplied/look.gd` (1); the guest's copy of `extrude()` without the smooth-group line (1); the borrowed part not turning triangles over, so that "up" is the bottom (5); the recorder not turning a walk clockwise (2).

## The sheet

Each solid alone in the plain studio, the eye 2.5 m from the middle (side and above) and at (1.9, 1.5, 2.1) for the corner, shadows off, stills of 960 × 720 on an NVIDIA GeForce RTX 3070 with the Compatibility renderer. Share of the still on which two tapers differ:

| pair | side | above | corner |
| --- | --- | --- | --- |
| 1.0, 0.6 | 12.33% | 17.91% | 9.67% |
| 1.0, 0.2 | 30.34% | 23.50% | 18.35% |
| 1.0, 0.0 | 28.95% | 23.86% | 17.39% |
| 0.6, 0.2 | 8.30% | 6.59% | 7.48% |
| 0.6, 0.0 | 12.07% | 7.72% | 8.73% |
| 0.2, 0.0 | 3.36% | 2.84% | 2.05% |

The closest pair is 0.2 and 0.0 from all three. The outline predicted 1.0 and 0.6, and 0.0 as the odd one: false on both counts. Six equal steps of 0.2, from the side, each against the next: 8.19, 6.32, 4.26, 3.79, 3.36%. `sheet.png` is 1292 × 754 pixels, 42,192 bytes.

The strip, `process.png` (2588 × 266, 51,603 bytes), has eight tiles: the walked outline; a wall for every edge; the top: the fan; the bottom: the fan reversed; one normal for each triangle; taper 0.6; a collider: the marble stays; extruded again: six spires. Each differs from the one before on 12.81, 12.43, 5.52, 8.70, 9.02, 0.58 and 5.77% of the tile. Tiles 2 to 4 are made by `stage()` in `sheet.gd`, with the normals smoothed as the lesson has them at that point; `stage()` with every part on gives the same vertices and normals as `extrude()`, and the sheet says so.

After `sheet.json written` the run prints two lines, `ERROR: Texture with GL ID of 23: leaked 349524 bytes` and the same for 24, and exits with code 0. They come as the window closes, after the supplied sheet tools have put the plain studio sky in place of the look's sky. The running scene and `verify.gd` do not print them.

## The room

Run once in a scratch copy of `../my-room/`, with `guests/extrude/` copied in and its line added to `GUESTS`: `guest_trial.gd -- extrude` passed 8 of 8. The room ran 180 frames with no error, the plinth stood at place 2, and the walker, sent at it, ended "blocked" 0.80 m from the middle of the place with its feet on the floor. The lesson's room task was done in a second scratch copy: another walk pasted in (seven corners), height 1.0, taper 0.7, and the example guest loaded on top by three lines in `plinth.gd`. The rider stood with its feet at 1.00 m and a marble dropped over it rested at 1.598 m. With those three lines the plinth names `res://guests/example/`, and the room's trial then fails its check "names nothing outside itself": the lesson says so.

## What was run, and what was not

Every code block of TUTORIAL.md before *In your room* was extracted and applied in page order: eleven states, each run headless with no error, the last equal to `extrude.gd` byte for byte. The in-text edits were run as well: taper 0.6 and 0.0, M before the collider line (0.10 m) and after it (0.90 m), `spire` true, height 0.3, the reversed walk, the index past the end. Stills of the running scene were looked at for every "Run it"; the measured stills are the studio's.

The borrowed extrude was compared with the project's real `MeshData`, `MeshSelector` and `ExtrudeFaceOp` in a scratch project holding copies of those four files: on the kit's solid at tapers 1.0, 0.6, 0.2 and 0.0, both gave the same set of triangles. Handed the solid as Godot winds it, not turned over, the real code chose the six triangles of the bottom as "up".

Not checked. No headset was used and no XR node is here. The walker was walked by its autopilot and by actions pressed from scripts, not by a hand on the keys; the recorder likewise. The editor's windows were not watched: F5, F6, the Inspector, the Output panel and the pause on a script error are described. Copying the printed line out of the Output panel was not done by hand. No person judged which solids look alike: every likeness is a count of pixels. No concave walk was extruded. The halls were read from `commons/maps/Primitives_Polythedra/map_data.json`, `commons/maps/Gallery_MeshGrammar/map_data.json`, the artifact registry, `prism_block.gd` and the halls' `final.md`, not walked.

Unexplained. On the lid of taper 0.6 the marble rolled 0.20 m before it lay still; on the lid of 1.0 it stayed where it landed. Both lids are level. By arithmetic on the walk, not by measurement, the landing point lies about a centimetre from an inner edge of the lid's fan in both; that this edge moves the marble is a guess. And an inside-out wall stopped the walker while an inside-out lid let the marble through.

## Departures from the outline

- The prediction of the outline was false as measured, and the lesson says so.
- "Rolls off the pyramid" holds 1 cm off the point and not on it: dropped exactly over the point the marble stays there.
- "A spire" is six spires: the project's extrude works triangle by triangle and the lid is a fan of six.
- The function's parameters are `rise` and `top`, not `height` and `taper`, so that they do not shadow the exported fields of the same script.
- The strip has eight steps, one more than the outline's seven: "one normal for each triangle" is a step of its own.
- "Each wall carries four vertices of its own": in the mesh as built each wall carries six, and with `index()` four.
