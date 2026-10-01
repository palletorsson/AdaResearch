# Implicit — a field, a grid that asks it, and a thread that does the asking

The study kit of the chapter *A body with no vertices until you ask: implicit bodies*. This is a new project: import this folder's `project.godot` in the Project Manager of Godot 4.6 and press Play. `implicit.tscn` is the main scene. Follow [TUTORIAL.md](TUTORIAL.md). The lesson takes two sessions; the first ends at *Stop here*.

## What is in it

`implicit.tscn` inherits `supplied/base.tscn` (the floor, the sky, the light) and moves its fixed camera back to (0, 2.3, 6.9), because the body is 3.8 m high. It adds three nodes. `Body`, a `MeshInstance3D` at the origin, runs `field_body.gd`. `Walker` is the supplied walker, at (−3.2, 0, 1.9). `Readout` is a line of text over the scene. The root runs `implicit.gd`.

One script is the learner's.

- `field_body.gd` (124 lines) is the body. `value_at()` is the field: three sources of reach 0.95 m, each a bell that adds 1 at its centre, plus noise of 0.08, less whatever has been carved. `build()` asks the field at the 68,921 corners of a grid of 40 cells in a box of 5 m, marches through the 64,000 cells with the borrowed table, and makes a mesh with `SurfaceTool`. `rebuild()` gives `build()` to a thread of `WorkerThreadPool`, or calls it itself when `threaded` is off. `show_mesh()` is the hand-back, always on the main thread: the mesh, a wall of the same triangles for a walker to meet, the count of bodies, the cost, the signal `built`. `carve()` adds a standing hole to the field and waits for a running build before it does. `_exit_tree()` waits for the thread.

Given, and read in the lesson:

- `implicit.gd` joins the parts. Space (`pause`) steps the threshold through 0.2, 0.4, 0.6 and 0.8. M (`drop`) carves 0.6 m ahead of the walker. It writes the line over the scene and, from a key until two frames after the new skin is on, keeps the longest frame. It asks the body only for what the body has, so it runs with every stage of the lesson.
- `mc_table.gd` is the **borrowed part**: the marching-cubes lookup table of the Ada project, from `algorithms/spacetopology/marchingcubes/core/MarchingCubesLookupTables.gd`. Contract: `TRIANGLE_TABLE[k]` lists, three by three, the edges of a cell whose crossings are the corners of the triangles of case `k`; `EDGE_CONNECTIONS[e]` is the two corners edge `e` joins; `CUBE_VERTICES[i]` is where corner `i` sits. The four lists are Ada's number for number and its comments word for word; its `class_name`, its four `get_` functions and its `interpolate_vertex()` are left out. The file was made from Ada's by a script kept in the build's scratch folder.
- `pieces.gd` counts what a skin of triangles is made of: `count()`, `sizes()`, `open_edges()`, `flat()`, `outward()`.
- `table_station.tscn` with `table_station.gd` is the code-critique station: it tests the borrowed table against itself and prints three lines. Run it with F6.

`supplied/` is the kit base's folder, unchanged: 15 files, the same in every kit and in the room. Nothing here declares a `class_name`, so a fresh copy needs no import.

`guests/implicit/` is the body this kit hands to the room: `implicit.tscn`, a `MeshInstance3D` with `implicit.gd`, and the folder's own copy of `mc_table.gd`. It is `field_body.gd` at 0.3 of the size, made to stand alone: it writes its colour out and finds who is near through an `Area3D` it makes, 2.5 m in radius. Alone it is three bodies at threshold 0.6, 1.15 m wide, 0.44 m deep and 0.99 m high, one of them in the air. With a walker or a loose body near, the threshold falls to 0.3 in six builds and the three are one body, 1.38 m wide, 0.66 m deep and 1.12 m high. Each skin is built on a worker thread, and it builds nothing while its threshold is where it should be.

## The planted fault, and what Godot does

The course outline planned: "add_child() called from the worker thread errors or crashes until the node is handed back with call_deferred()". In Godot 4.6.stable it errors and does not crash. With the last line of `build()` written `show_mesh(made, count, ...)` in place of `show_mesh.call_deferred(made, count, ...)`, every build logs four errors, in this order:

```
ERROR: /root/Implicit/Body: The caller thread can't call the function `update_gizmos()` on this node. Use `call_deferred()` or `call_deferred_thread_group()` instead.
ERROR: /root/Implicit/Body: The caller thread can't call the function `emit_signalp()` on this node. Use `call_deferred()` or `call_deferred_thread_group()` instead.
ERROR: Adding children to a node inside the SceneTree is only allowed from the main thread. Use call_deferred("add_child",node).
ERROR: /root/Implicit/Body: The caller thread can't call the function `emit_signalp()` on this node. Use `call_deferred()` or `call_deferred_thread_group()` instead.
```

The first two come from `mesh = made`, the third from `add_child(wall)`, the fourth from `built.emit()`. The scene goes on running. The skin is on all the same; the wall is not in the scene, so a walker sent at the body walks through it and arrives; the line over the scene stays empty, because nobody heard `built`. At exit Godot adds `1 RID allocations of type 'P11GodotBody3D' were leaked` and the same for a shape: the wall that never entered the scene. How the editor's Debugger panel shows the four was not watched.

One more thing the fault does, which the lesson does not walk into: a body with this fault that is freed in the middle of a build hung the program. `verify.gd` met this in a scratch copy with the fault planted: no frame and no line for 75 seconds, until the watchdog ended it. We take it that the main thread waits for the task in `_exit_tree()` while the task, inside `show_mesh()`, waits for the main thread; that was not proven. `verify.gd` now does not try that step once an error has been logged.

A second fault is part of the making, not planted: the comparison `at[i] < level`, which is the one Ada's generator and the hall's reading use, turns every triangle inward in Godot. No error is printed.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 84 checks and writes `verification.json`. Its exit code is the number of checks that failed. It took about 50 seconds here; the walker walks in real time and the grid of 80 cells is built fifteen times. With `--fixed-fps 60` added it took about 29 seconds and gave the same result: the same 84 lines, every count and every distance the same, and only the times different. It does not get faster than that, because a build takes real time whatever the clock. The checks cover: the project, the 15 supplied files, tabs, no `class_name`, no `.uid` or `.import` left; the borrowed table against itself, and the station's three printed lines; the field at three places and the 68,921 samples; the skin at 0.4 (which way it faces, its normals, whether it is closed, its rim on the ground, its triangles without area, how far its points are from the threshold, its wall); the four thresholds, the count in hundredths from 0.40 to 0.60, the same without noise and with the sources further apart; four grids from 10 to 80 cells and a box too small; the thread (the longest frame with and without it, the hand-back alone, a second wish while a build runs, carving while a build runs, a body freed in the middle of a build, a field with no skin); the planted bug and the comparison turned round, each run from the text of `field_body.gd` with one piece changed; the scene as the learner runs it, with Space and M pressed by the script, a marble dropped on the skin and one beside it, the walker stopped, two holes, the walker through and then standing inside; the guest alone, with a walker coming and leaving, fused and carved.

`sheet.gd` needs a window, so it is run without `--headless`. It writes `sheet.png` (1292 × 536 pixels, 141,255 bytes), `process.png` (1940 × 266 pixels, 59,966 bytes), `sheet.json` and the stills in `stills/`, and closes its window by itself, after about 17 seconds here. Two runs gave the same fourteen stills to the last byte. When its window closes Godot prints two lines, `ERROR: Texture with GL ID of 23: leaked 349524 bytes.` and the same for 24; the exit code is 0. The Soft body kit's sheet prints the same two lines; they were not looked into.

## What was measured

The sheet. Each body alone in the plain studio, seen level from the front, 6.5 m from the point (0, 2, 0), in stills of 960 × 720 on an NVIDIA GeForce RTX 3070 with the Compatibility renderer. On the grid of 40 cells:

| threshold | bodies | triangles of each | wide | high | lowest point | covers |
| --- | --- | --- | --- | --- | --- | --- |
| 0.2 | 1 | 8,296 | 4.73 m | 4.12 m | 0 m | 50.57% of the still |
| 0.4 | 1 | 6,282 | 4.16 m | 3.83 m | 0 m | 33.99% |
| 0.6 | 3 | 1,220, 1,184, 1,184 | 3.69 m | 3.60 m | 0.217 m | 16.40% |
| 0.8 | 3 | 520, 496, 492 | 3.24 m | 3.36 m | 0.456 m | 6.77% |

Two bodies differ on: 0.2 and 0.4, 27.02% of the still; 0.2 and 0.6, 40.05%; 0.2 and 0.8, 47.16%; 0.4 and 0.6, 22.12%; 0.4 and 0.8, 30.47%; 0.6 and 0.8, 12.14%, of which 9.62% is outline. The closest pair is 0.6 and 0.8. On the grid of 10 cells the counts are the same (534, 364, 224 and 64 triangles) and the pairs 26.17, 41.61, 48.10, 23.12, 30.53 and 12.25%: the same closest pair.

The outline predicted: "0.4 and 0.6 will look most alike: both show separate blobs, one set fatter. At 0.2 the blobs fuse into one body; at 0.8 they shrink into beads." The closest pair is 0.6 and 0.8. 0.4 is one body and 0.6 is three, so they are not two sets of blobs. The ends held: one body at 0.2, three small ones at 0.8.

Where one becomes three, in `verify.gd`: one body up to 0.48, two at 0.49, three from 0.50. Without the noise: one up to 0.47, three from 0.48, never two. With the three sources 2.83 radii apart in place of 2.42: 1, 3, 3 and 3 bodies at the four thresholds.

The grid, the same field at 0.4:

| cells | a cell | triangles | one body up to | three bodies from | a build |
| --- | --- | --- | --- | --- | --- |
| 10 | 50 cm | 364 | 0.46 | above 0.52 | 2.7 ms |
| 20 | 25 cm | 1,548 | 0.47 | 0.51 | 14.4 ms |
| 40 | 12.5 cm | 6,282 | 0.48 | 0.50 | 92.9 ms |
| 80 | 6.25 cm | 25,264 | 0.48 | 0.51 | 664.2 ms |

At 0.43 and at 0.47 the grid of 80 finds a piece of 8 triangles beside the body; no coarser grid does. At 0.2 in a box of 4.4 m the skin is cut open at the wall: 92 open edges above the ground; in the box of 5 m, none.

The skin at 0.4: 18,846 points, 6,282 triangles, every triangle with an area facing outward, every point with a normal that points to where the field is lower, no open edge above the ground, a rim of 29 edges on the ground, 5 triangles with two corners in one place, no point further than 0.0114 from the threshold in the field's own units. At 0.6 the 3,588 triangles meet in 1,800 places, which is what three closed skins have.

The thread. In a window (`sheet.json`), the running scene, three builds each way; a usual frame is 16.68 ms:

| cells | a build | the longest frame, on the main thread | with a worker |
| --- | --- | --- | --- |
| 40 | 93 to 97 ms | 107 to 108 ms | 26 to 28 ms |
| 80 | 651 to 665 ms | 700 to 711 ms | 62 to 63 ms |

Without a window (`verification.json`, the command as given), at 40 cells: 102 to 104 ms on the main thread and 16 ms with a worker; with `--fixed-fps 60` the worker's longest frame was 9 to 12 ms, since a frame there does not wait for the clock; `show_mesh()` alone took 7.81 ms. Asking the 68,921 samples from the checks' own loop took 56.1 ms; a whole build took 100.1 ms. All of these are times of one machine with other programs running, and they move from run to run.

The place. The walker, on its autopilot, was `blocked` 0.71 m in front of the body's middle, carved, was `blocked` again at −0.19 m, carved, and `arrived` on the far side. Two holes; one body still, of 6,330 triangles; no point of the skin within 0.5 m of a hole's middle line and 2,649 between 0.5 and 0.6 m; 4.16 m wide and 3.83 m high as before. It then walked back in and stood under the third source. A marble dropped from 4.6 m over the top source was 3.68 m up one second later; the same drop beside the body was at 0.10 m.

The process strip, six tiles from one standpoint: three sources asked on 10 cells; a grid of 40 cells; noise in the field; the threshold falls to 0.4; two holes carved; a walker stands in it. Bodies: 3, 3, 3, 1, 1, 1. Each differs from the one before on 3.26, 1.72, 15.86, 2.88 and 2.37% of the tile.

The borrowed table. 256 rows and 820 triangles in the triangle table, and every row uses exactly the edges its corner bits say are crossed. The edge table disagrees with the corner bits in 32 rows, 48 to 63 and 192 to 207, and rows 62, 63, 192 and 193 name a thirteenth edge. `field_body.gd` never reads the edge table. The same numbers stand in Ada's own file; this kit changed none.

## What was checked

Every code block of TUTORIAL.md was taken from the page in order and applied as the page says, by a script kept in the build's scratch folder: 23 blocks, of which 20 build `field_body.gd` and three are lines for the room. The last state equals the shipped `field_body.gd` byte for byte. Each state the page says *Run it* on was run in a fresh copy of the kit, without a window: after *A field*, *Ask it on a grid*, *March*, *Inside out*, *The hand-back*, *A worker thread* and *Place*, and the planted bug, with the lines the page gives. Five of them were also run in a window and their stills looked at: the body inside out, the body turned, the line on the main thread, the line with a worker, and the planted bug.

`verify.gd` passed 84 of 84 in this folder, and in fresh copies with no `.godot/`: three times with the command above and six times with `--fixed-fps 60` added. In both clocks the walker is `blocked` 0.97 m from the guest's middle with its feet at 0.00 m, the guest has built 7 times when the three are one and 13 when they are three again, and then it rests.

That was not so at first. A build runs on a worker thread and takes real time; under `--fixed-fps` a step of the physics takes almost none. The guest's checks used to wait a count of steps for its builds: 60 after the walker came, 90 after it left. In real time that passed. With `--fixed-fps 60` an independent check on a fresh copy saw *the walker leaves* fail in four runs of four, with 8 or 7 builds where 13 are demanded, and found that the walker had reached the guest before the guest had come together: stopped 0.77 m from its middle and standing 0.42 m up on the skin. Our own run of that state gave 8 builds and 0.77 m. Now those checks ask the guest. `come_to()` waits until its threshold is where it should be and no build is running. `rests()` says that in the next 60 or 120 steps no build ended and none is running, which holds or fails in the same way in either clock. And the walker comes in two walks: it stands 2 m from the guest's middle, inside the reach of 2.5 m, until the three are one, and then walks on into the one body. What the first version met stays true of the guest: a walker that outruns the builds meets three bodies.

Negative tests, one fault at a time in a fresh copy, each run in both clocks with the same count of failed checks in both:

- the two the lesson names as faults, each failing the run: the hand-back called straight from the thread (22 checks failed, the first of them with Godot's four errors in it); the comparison turned round (8);
- in `field_body.gd`, each failing the run: `carve()` not waiting for the thread (1); a second wish forgotten (2); the wall never added (7); no `_exit_tree()` (1: a body freed in the middle of a build, and Godot's `Bad address index` and then `Invalid call. Nonexistent function 'value_at' in base 'previously freed'`; with `--fixed-fps 60` only the first of the two had come when the check looked); `threaded` off by default (8); no normals (1); spaces for a tab (`verify.gd` could not load the script: 12 failed);
- in `mc_table.gd`: one number changed in row 1 (11);
- in the guest: `supplied/look.gd` used (1); a `class_name` declared (2); a guest that never comes together (3); a guest that never rests (5);
- **not caught**: `wait_for_task_completion()` taken out of `show_mesh()`. All 84 checks passed and Godot exited with code 0. The lesson says so.

The outputs are kept in the build's scratch folder, not in this kit.

The room. In a scratch copy of `my-room`, with `guests/implicit/` copied in and its line added to `GUESTS`, `guest_trial.gd -- implicit` passed 8 checks of 8: the room ran 180 frames with no error, the guest stood at place 2, the walker reached the aisle (`arrived`) and then walked at the guest, and the walk ended `blocked`, 0.64 m from the middle of the place, its feet at 0.00 m. The room's command has no `--fixed-fps`; run once with it, the trial passed 8 of 8 as well and the walk ended `blocked` 0.63 m from the middle, a centimetre nearer; we take it that the walker came before the guest's last builds, and did not look. A probe then watched the guest: one build and no more while the walker stood 4.5 m away; with the walker in the aisle, 2 m from it, threshold 0.3 after seven builds in all, 1,420 triangles; the walker gone, threshold 0.6 again after thirteen, and then no more. These numbers are recorded in `verification.json` under `room_trial_recorded`; `verify.gd` does not measure them again. The room task was done on the guest in `verify.gd`: fused with a fourth source at (0, 0.36, 0), one body at 0.6; carved with a hole at (0, 0, 0), at 0.3 one body of 1,614 triangles where there were 1,420, 419 points on the hole's wall and none inside. Each of the two lines was also written into the guest's `_ready()`, above `rebuild()`, as the page says, in a scratch copy of the room: both passed the room's trial 8 of 8, the walker `blocked` 0.68 m and 0.64 m from the middle of the place.

`supplied/` was compared with `../kit-base/supplied/` by `diff -r`: no difference.

## What was not checked

Nothing was run in a headset, and no XR node is in the kit. The spec's place asks for a hand that sculpts the field; here the walker carves from where it stands, with a key, and in the checks the keys were pressed by the script. No hand was on a keyboard. The editor's windows were not watched: the Inspector's **Threaded** box, the Debugger panel with the four errors, F6 on the station. No person judged which bodies look alike: every likeness is a count of pixels. The times are of one machine. The halls were read from their files and not walked. No learner has used any of it. What Godot does with a task that is never waited for was not found: the binary's `--doctool` dump has no descriptions, and no run here showed a difference.

## Unexplained

- **The crumbs.** At 0.43 and 0.47 the grid of 80 cells finds a separate piece of 8 triangles. The lesson takes it for a bump of the noise near the skin. Nobody looked at where it is.
- **The hand-back in a window.** With a worker the longest frame is about 10 ms longer than a usual one at 40 cells and 46 ms longer at 80. Without a window `show_mesh()` alone took 7.81 ms at 40 cells. What the rest is, the upload of the mesh or the wall, was not taken apart.
- **Ada's edge table.** 32 of its 256 rows are wrong. Which of Ada's generators read it, and what their meshes do in those cases, was not looked at; this kit touched nothing outside its folder.
- **The turned comparison on a coarse grid.** With `<` in place of `>` the grid of 10 cells kept one body up to 0.52 where `>` keeps it up to 0.46. The table's rows for a case and for its opposite are not mirror images in the cases where a face has two inside corners on a diagonal. This was seen in a negative test and not followed.

## Lineage

A mesh written point by point (Plane, Cube) → a mesh made again at every step (Soft body) → here: no points until a field is asked, a table that turns eight answers into triangles, and a thread. The method is marching cubes, Lorensen and Cline, 1987; the table is the Ada project's copy. The halls read for it, from their files and not walked: `ISO_Introduction`, `ISO_Metaballs`, `ISO_LookupTable` and `ISO_Sculpting`.
