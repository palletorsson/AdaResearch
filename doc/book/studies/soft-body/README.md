# Soft body — a cloth of our own, beside Godot's

The study kit of the chapter *Soft bodies: the organism returns*. This is a new project: import this folder's `project.godot` in the Project Manager of Godot 4.6 and press Play. `soft_body.tscn` is the main scene. Follow [TUTORIAL.md](TUTORIAL.md). The lesson takes two sessions; the first ends at *Stop here*.

## What is in it

`soft_body.tscn` inherits `supplied/base.tscn` (the floor, the sky, the light, the fixed camera) and adds five nodes. `Cloth`, at (−1, 2, 0), runs `cloth.gd`. Its child `Hand`, a small white ball at the cloth's right top corner, runs the supplied `mover.gd`: the four move keys carry it. `SoftCloth`, at (1.2, 1.4, 0), is a `SoftBody3D` with a plane of 11 by 11 points and `soft_cloth.gd`. `Walker` is the supplied walker with its keys off. `Readout` is a line of text. The root runs `soft_body.gd`.

Two scripts are the learner's.

- `cloth.gd` (138 lines) is the cloth: two classes written inside it, `Particle` (two places and no speed; `step()`, `nudge()`, `push_out()`) and `PinnedParticle extends Particle` (a `holder`, an `_init()` that calls `super(at)`, and `step()` and `nudge()` written again); 121 particles and 220 links in a packed array; `iterations` passes of `relax()` in each step; `draw()`, which makes the mesh again from the particles; `report()`, the line the readout shows; `meet()`, by which the cloth is told about a body; and `let_go()`, which puts a new `Particle` in the place of the first pinned one.
- `soft_cloth.gd` (14 lines) pins the two top corners of Godot's soft body, points 110 and 120, and prints which.

`soft_body.gd` is given. Every step of the physics it tells the cloth where the floor and the walker are. Space (`pause`) sends the walker to its next stop: into the cloth, behind it, into it again, back to its start. M (`drop`) calls `let_go()`. It asks the cloth for nothing the cloth does not have yet, so it runs with every stage of the lesson.

`supplied/` is the kit base's folder, unchanged: 15 files, the same in every kit and in the room. Nothing here declares a `class_name`, so a fresh copy needs no import.

`guests/soft-body/` is the body this kit hands to the room: `soft-body.tscn`, a cloth hung between two posts 1.4 m apart, 1.48 m wide, 0.08 m deep and 2 m high. `soft-body.gd` stands the posts, which have colliders. `cloth.gd` in that folder is the lesson's cloth made to stand alone: it writes its colour out, finds the bodies near it through an `Area3D` it makes, and stops stepping after two seconds in which nothing moved and nobody was near. It can be copied alone into the folder of another guest, which is the room task of the lesson.

## The planted fault, and what Godot does

The course outline planned: "the subclass's _init forgets super(), so pinned particles have no position and the cloth hangs from the origin". In Godot 4.6.stable that is what happens, in silence. A child's `_init()` that does not call `super()` is run alone; the parent's is skipped, whether or not it takes arguments; the fields keep the values they were declared with; and Godot prints no error and no warning. A child with no `_init()` of its own is made by its parent's. `super()` with too few arguments does not load: `Parse Error: Too few arguments for "_init()" call. Expected at least 1 but received 0.`

In this kit the fault is half hidden, and the lesson says so: the corner with a holder is told its place at every step and recovers at the first; the nailed corner stays at the origin of the cloth, the middle of its own top edge. The readout then shows `lowest point 0.22 m, longest link 141% of its length`. The script editor's own view of the fault was not watched.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 59 checks and writes `verification.json`. Its exit code is the number of checks that failed. It took 111 seconds here, most of it the cloth stepped 1200 times at each count; with `--fixed-fps 60` added it took about 80, with the same lines. The checks cover: the project and the 15 supplied files; a particle's fall (0.537, 1.968 and 4.129 m after 20, 40 and 60 steps); what a `PinnedParticle` is, keeps and inherits; the forgotten `super()` and its silence; the build (121, 220, 200 triangles, the two pinned, the Hand); the cloth with no pass at all; two cloths alike to the last digit; the fault of the forgotten `super()` and the fault of the missing `nudge()` as the readout shows them; the cloth at rest at 1, 4, 16 and 64 passes, and which link is the longest; four things followed (grain, the whole top row pinned, another rule for a held link, the passes as four small steps); the carry, `let_go()` once and twice, the rope, and the cloth dragged over a standing capsule; the scene as the learner runs it, with S, Space and M pressed by the script; Godot's soft body alone at four counts, with a walker in it, and unpinned; the guest; and the numbers the lesson quotes from `sheet.json`. Our cloth is stepped by the script, so its numbers are the same on every run. The scene runs on the frame clock, so its own numbers can move a little from run to run; in the last two runs they agreed to the second decimal.

`sheet.gd` needs a window, so it is run without `--headless`. It writes `sheet.png` (1292 × 536 pixels, 21,564 bytes), `process.png` (2264 × 266 pixels, 26,722 bytes), `sheet.json` and the stills in `stills/`, and closes its window by itself, within a minute here; the run was not timed. Two runs gave the same pictures to the last byte. A third, later the same day in a scratch copy, differed from them in one still: Godot's soft body at precision 1, on 19 of its 691,200 pixels, which is one pixel of `sheet.png`. Its lowest point read 0.5730 m as before, and one outline share in `sheet.json` moved from 6.85 to 6.86. Every still of our cloth, the other three of Godot's and the strip were the same to the last byte. The pictures and the `sheet.json` in this folder are those of the first two runs. When its window closes Godot prints two lines, `ERROR: Texture with GL ID of 23: leaked 349524 bytes.` and the same for 24; the exit code is 0. They come with the supplied look's sky and were not looked into.

## What was measured

The sheet. Each cloth alone in the plain studio, seen from the front, 3.2 m from the point (0, 1.05, 0), in stills of 960 × 720 on an NVIDIA GeForce RTX 3070 with the Compatibility renderer. Ours after 1200 steps of 1/60 s:

| passes | lowest point | below taut (0.80 m) | longest link | mean error of a link | a step, in the sheet's run |
| --- | --- | --- | --- | --- | --- |
| 1 | 0.1162 m | 68.38 cm | 284.7% | 12.57% | 0.18 ms |
| 4 | 0.4264 m | 37.36 cm | 144.4% | 3.43% | 0.61 ms |
| 16 | 0.5603 m | 23.97 cm | 118.1% | 0.96% | 2.23 ms |
| 64 | 0.6465 m | 15.35 cm | 107.9% | 0.28% | 8.89 ms |

Two cloths differ on: 1 and 4, 7.10% of the still; 1 and 16, 10.93%; 1 and 64, 13.79%; 4 and 16, 4.07%; 4 and 64, 7.08%; 16 and 64, 3.02%, a band 16.27 pixels wide. All of it is outline. The closest pair is 16 and 64.

The outline predicted: "16 and 64 will look most alike: the cloth hangs taut, and the extra passes remove less than a centimetre of stretch. 1 sags like rubber." The pair held and the rubber held. The cloth is not taut at 64 passes, and from 16 to 64 its lowest point rises 8.62 cm.

Godot's soft body at Simulation Precision 1, 4, 16 and 64, Linear Stiffness 0.5, after 600 steps of the engine, in the sheet: lowest point at 0.5730, 0.7007, 0.7708 and 0.7952 m; pairs 3.91, 6.03, 6.86, 2.19, 3.04 and 0.86%. In `verify.gd`, without a window: 0.6432, 0.7505, 0.7872 and 0.7975 m. See *Unexplained*.

Followed, in `verify.gd`, after 600 steps each. The whole top row pinned: 0.6495, 0.7636, 0.7919 and 0.7988 m; from 16 to 64 it rises 0.69 cm. The free end of a held link takes the whole error: 0.2056, 0.4591, 0.5766 and 0.6575 m. A net of 6 by 6, 11 by 11 and 21 by 21 at 16 passes: 0.6739, 0.5603 and 0.4037 m, at 0.54, 2.08 and 8.07 ms a step. Sixteen passes as four steps of 1/240 s with four each: 0.6452 m, in 2.19 ms for 1/60 s, where 16 passes in one step took 2.08 ms and 64 took 8.29.

The place. The Hand carried 1.2 m toward us: the longest link 180.6% of its length. The walker in the cloth: `arrived`, the cloth pushed 0.29 m out of its plane; ten seconds after it walked on, 0.023 m. The walker in Godot's soft body: `arrived`, the soft body pushed 0.0000 m; unpinned, the soft body fell through the supplied floor, 25 m in three seconds. The nail let go: 100 particles in the air, none more than 0.013 m from the line under the Hand. Dragged over a capsule of the walker's size and let go: 76 particles above 0.5 m while held and none after, at 4 passes; 85 and none at 16.

The process strip, seven tiles from one standpoint: a sheet of particles; two are pinned; links, 1 pass a step; 16 passes a step; carried by a corner; a walker in it; the nail is pulled. Each differs from the one before on 3.58, 6.19, 5.10, 4.88, 11.41 and 9.99% of the tile. `course.json` lists no process for this chapter; these are the steps the lesson takes.

## What was checked

Every code block of TUTORIAL.md was taken from the page in order and applied as the page says, by a script kept in the build's scratch folder: 17 blocks, of which 15 build `cloth.gd`, one is `soft_cloth.gd` and one is the line for the room. The last state equals the shipped `cloth.gd` and `soft_cloth.gd` byte for byte. Each state the page says *Run it* on was run in a fresh copy of the kit: after *A point that falls*, *A sheet of particles*, *Two that stay*, *Links*, *What a step costs* and *Place*, and the three faults (`super(at)` deleted, `super()` empty, `nudge()` not overridden), with the lines and the numbers the page gives. Stills of four of those states as the running scene shows them were made and looked at.

`verify.gd` passed 59 of 59 in this folder, and in a fresh copy with no `.godot/` (that run with `--fixed-fps 60`). Negative tests, one fault at a time in a fresh copy, each failing the run:

- the three the lesson names: `super(at)` deleted from `PinnedParticle` (16 checks failed); `super()` with nothing in the brackets (`verify.gd` did not load, exit code 1); `PinnedParticle` without its `nudge()` (12);
- in `cloth.gd`: `relax()` left out of `step()` (14); `iterations` ignored (7); the corner not given to the Hand (3); a `push_out()` that does not stop the particle (1); a `let_go()` that lets go of both pins at once (3); a `meet()` without `to_local()` (5); spaces for a tab (`verify.gd` did not load, exit code 1);
- in `soft_cloth.gd`: nothing pinned (4); the two bottom corners pinned (4);
- in the guest: `supplied/look.gd` used (1); a `class_name` declared (2); a cloth that never rests (1); a cloth told about no body (1).

The copy with nothing planted passed 59 of 59. The outputs are kept in the build's scratch folder, not in this kit.

All of this was run a second time, by another session on the same day, from the kit as it stood: `verify.gd` in a fresh copy with no `.godot/` (59 of 59, 118 seconds without `--fixed-fps`), the 17 blocks of the page and each state it says *Run it* on, the 16 faults (each failed, with the counts above), `sheet.gd` with a window, the room's trial and the probe. Every number came out as written here, except the times of a step and the 19 pixels named under *Commands*. Stills of the running scene at rest, with the Hand carried, with the walker in the cloth and with the nail let go were made and looked at. The halls were read again from their files, and three sentences of the lesson were made more exact.

The room. In a scratch copy of `my-room`, with `guests/soft-body/` copied in and its line added to `GUESTS`, `guest_trial.gd -- soft-body` passed 8 checks of 8: the room ran 180 frames with no error, the guest stood at place 2, the walker reached the aisle and then walked at the guest, and the walk ended `arrived`, 0.07 m from the middle of the place, its feet at 0.00 m. A probe then measured the cloth: pushed 0.29 m out of its plane with the walker in it; the walker walked on through; 983 steps later the cloth rested again, 0.0006 m out of its plane. The room task was done on a copy of the example guest: the guest's `cloth.gd` copied into its folder and hung on its front as a node of 6 by 5 points, the scene file written by hand and not in the editor; the walker was `blocked` 0.56 m from the middle of the place and the flag pushed 0.13 m. That body passed `guest_trial.gd` too. These numbers are recorded in `verification.json` under `room_trial_recorded`; `verify.gd` does not measure them again.

## What was not checked

Nothing was run in a headset, and no XR node is in the kit. The corner is carried by the supplied keyboard hand, and in the checks the keys were pressed by the script. No hand was on a keyboard. The editor's windows were not watched: the Inspector's fields, the Profiler, adding a node and dragging a script onto it. No person judged which cloths look alike: every likeness is a count of pixels. The time of a frame was not measured, only the time of the cloth's own step, on one machine, with other programs running. No learner has used any of it.

## Unexplained

- **Godot's soft body does not rest at one height.** With the same mesh, pins and settings it rested at 0.7007 m in the sheet and at 0.7505 m in the checks (precision 4), each of those heights the same to four digits on every run of that script, though one of three runs of the sheet drew it 19 pixels differently. In scratch probes it rested in between, and what had stood in the scene before it changed where. The cause was not found.
- **It falls through the supplied floor** when nothing is pinned, and it is not moved by the walker. What it does collide with was not tried.
- **Its lean.** At rest its bottom edge stands 8 cm to one side at precision 1 and 0.2 cm at 64. The lesson guesses at the triangles' diagonals; that was not tested.
- **The strip's seventh tile** shows almost nothing. The cloth is there: with one corner held it folds into a line.

## Lineage

A class with two fields (Families) → a movement added in small steps → here: a class made from a class, a step that keeps no speed, links asked a counted number of times, and a mesh that follows. The step is Loup Verlet's (1967); the links relaxed in passes are Thomas Jakobsen's (2001). The halls read for it, from their files and not walked: `SoftBodies_Soft_Body_Deformation`, `FormFinding_Relaxation`, `Topology_Entropy_Morphogenesis` and `SoftBodies_Playground_of_Joy`.
