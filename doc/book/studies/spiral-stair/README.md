# Spiral stair — study kit

A small Godot 4.6 project for the chapter *The stair climber: a spiral you can walk*. One function places a spiral, `place(i, r)`; a stair of nine treads and a ramp are built from it; the supplied walker is sent up; a headless test says whether it reached the top. The lesson is [TUTORIAL.md](TUTORIAL.md). The kit's own field note is [FIELD_NOTE.md](FIELD_NOTE.md).

## Open it

In the Project Manager of Godot 4.6 choose **Import** and open this folder's `project.godot`. Press Play (F5): `spiral_stair.tscn` is the main scene. Nine lime treads climb round three quarters of a circle and the cyan walker climbs them. The Output panel reads `the walker arrived with its feet at 1.62 m; the top is at 1.62 m`.

The editor's own view of the scene shows a white floor, Godot's preview light and no stair: the look and the stair are made by scripts when the scene runs.

Keys, once the walk has ended: W A S D or the arrows walk, J jumps, C changes between the fixed camera and the walker's eyes, V or the right mouse button held turns the view with the mouse.

## What is in the folder

Built in the lesson (the learner's scripts; the download holds the finished versions):

- `stair.gd`: `place(i, r)`, the function; `tread(i)`, a `StaticBody3D` with a box as its mesh and as its collider; `slope()`, the ramp, one `SurfaceTool` surface with one `ConcavePolygonShape3D`; `route()` and `top()`. Exported: `treads` 9, `radius` 1.2, `turn_deg` 30, `rise` 0.18, `ramp` false.
- `climb.gd`: on the scene's root; sends the walker along `route()` and prints how the walk ended.
- `walk_test.gd`: the walk as a headless test with two checks. It writes `walk_test.json`.
- `spiral_stair.tscn`: the supplied base, a `Stair`, a `Walker` at (2.7, 0, 0).

Supplied, unchanged from the kit base: `supplied/` (15 files: the base scene, the look, the walker, the marble, the check harness, the still-maker, the guest check and the rest). The base's README has every signature.

Borrowed: `borrowed/trig_lines.gd`, four one-line functions that earlier chapters hand over closed and this chapter opens: `wave_height(x, z)` (*Noise*), `gap_to_circle(n)` and `catenoid(u, v)` (*The budget*), `base_ring(sides, radius)` (the pyramid in the hall of the cube lesson). They are small versions made for this kit, not copies of those kits' files.

Handed to the room: `guests/spiral-stair/`, the scene `spiral-stair.tscn` and its script. A stair of six treads, 0.30 m each, 1.80 m high, inside 1.6 m by 1.6 m, with a white plate at its foot: a body with a `walk_to()` that steps on the plate is handed the stair's route. It names nothing outside its folder and declares no `class_name`.

The kit's own: `verify.gd`, `sheet.gd`, and their results `verification.json`, `sheet.json`, `sheet.png`, `process.png`, `well.png`.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --headless --path . --xr-mode off --script res://walk_test.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 69 checks and writes `verification.json`; its exit code is the number of checks that failed. It needs no import step. The walker walks in real time and there are about forty walks, so it takes about two minutes (2 min 3 s to 2 min 6 s here); with `--fixed-fps 60` added it takes about two seconds and measures the same numbers (compared: the two results were equal, value for value).

`walk_test.gd` is the lesson's test: two checks, a few seconds, exit code 0, or 2 with the planted bug in.

`sheet.gd` needs a window, so it is run without `--headless`. It takes about 40 seconds, because the walker walks twelve times in it, and closes its window by itself. It writes `sheet.png`, `process.png`, `well.png`, `sheet.json` and the stills in `stills/`.

## What was measured

All of it is in `verification.json` and `sheet.json`.

- **The four rises, seen.** From the side, 9 m away: 0.10 and 0.18 differ on 5.21% of the still, the closest pair; 0.18 and 0.60 on 13.57%, the farthest. In plan, with no perspective, every pair differs on 0.00%; counted with no threshold, between 297 and 1,832 of 691,200 pixels differ, each by one step of 255 in one channel. Three pairs 0.08 m apart: 5.21%, 6.20%, 7.51%.
- **The four rises, walked.** 0.10, 0.18 and 0.30 m: `arrived`, feet at 0.90, 1.62 and 2.70 m. 0.60 m: `blocked`, feet at 0.00 m. The line: 0.35 m arrives, 0.36 m is blocked.
- **The ramp.** 0.10, 0.18, 0.30 m: `arrived` (0.91, 1.65, 2.69 m). 0.60 m: `blocked` at 0.23 m. Its two triangles are 12.3 and 25.6 degrees steep at 0.18 m, 36.0 and 58.0 at 0.60 m. Its limit for this walker is between 0.38 and 0.40 m.
- **A body that does not step** (`step_height` 0): stopped on the floor by the stair at every rise; reaches the top of the ramp at 0.10, 0.18 and 0.30 m; stopped by the ramp at 0.35 m, which the stepping walker climbs.
- **Headroom.** Sixteen treads at 0.18 m: stopped on the floor. At 0.20 m: one tread. At 0.21 m: the top, 3.36 m.
- **The planted bug.** Treads 81.1 degrees back from each other, 1.56 m apart; the walker `blocked` on the floor, 0.80 m short of the foot; no error and no warning.
- **Floor snap.** Down the ramp: off the floor in 0 of 221 steps with `floor_snap_length` 0.1, in 158 of 226 with 0.
- **The marble.** On the top tread it stays, at 1.71 m. On the ramp it rolls away.
- **The guest.** Six treads of 0.30 m: the walker `arrived`, feet at 1.80 m. A body that does not step: stopped on the floor. As a ramp: stopped at 0.09 m; as a ramp of 0.10 m a piece: `arrived` at 0.61 m. At a rise of 0.18 m: stopped on the floor, because, lifted 0.35 m and moved ahead, the walker would come down on the edge of the second tread (top at 0.36 m; the landing's normal has y = 0.85, and the walker asks for more than 0.9).

## What was and was not checked

Checked, headless, by `verify.gd` (69 of 69 on a fresh copy with no `.godot/`, in real time and again with `--fixed-fps 60`): the project and its main scene; the 15 supplied files; tabs and line feeds in the 18 scripts; no `class_name`; the trigonometry the lesson states; the four borrowed lines; the nine treads, their size, place, turn and colour; the route; the scene run to the walker's arrival and 180 frames more with no error; every walk named above; the guest's folder, its box, its colours, the plate, four variants of it, and the walker's own landing test repeated where the variant of 0.18 m stopped it.

Checked, with a window, by `sheet.gd`, and each picture looked at: `sheet.png` (1292 × 1076, four rises in four rows), `process.png` (1940 × 266, six steps; the planted bug changed the tile most, 26.72%), `well.png` (960 × 720, from the walker's eyes at the top). The stills were 960 × 720 on an NVIDIA GeForce RTX 3070 with the Compatibility renderer.

The lesson was replayed: every code block of `TUTORIAL.md` was applied in page order to a fresh copy and the study run after each step, 49 steps; what Godot printed matched what the page quotes, and the three learner scripts ended byte for byte equal to the shipped ones.

Negative tests, in scratch copies, one fault at a time; each of the 21 made `verify.gd` fail. The two the lesson names: degrees handed to `cos()` and `sin()` as radians (24 checks failed) and treads with no collider (16). And: a tread turned the wrong way; its middle, not its top, at `place(i)`; `sin` and `cos` swapped; a route not in the room's frame; the ramp without its last piece, drawn from one side, or wound the other way (the walker was then stopped on the floor); a rise of 0.36 m; `climb.gd` printing no height; `walk_test.gd` writing over the kit's result; spaces for tabs; a `class_name`; a wrong `gap_to_circle()`; and six faults in the guest (using the look, a `class_name`, too wide, no plate, the degrees bug, no scene).

The room test, once, in a scratch copy of `my-room` with the guest's folder copied in and its line added: `guest_trial.gd` ran 8 checks and all passed. The room ran 180 frames with no error, the guest stood at place 2, and the walker, walking at it from the aisle, stepped on the plate and ended `arrived`, 0.52 m from the middle of the place, with its feet at 1.80 m.

Not checked: nothing was run in a headset. No hand walked the stair: the walker went by its autopilot, and the plate of the guest was stepped on by the autopilot too. The editor's windows were not watched: the steps marked *(editor)* in the lesson were not done by anyone. No eye was asked which stairs look alike: the percentages are counts of pixels. No learner has used the kit. The stills were made on one machine. Some windowed runs of `sheet.gd` ended with two lines `Texture with GL ID of … leaked 349524 bytes` as the window closed, after everything was written, and some did not; the numbers were the same in every run. One still was not: of three runs compared, one had the walker that was stopped on the ramp of 0.60 m standing a little differently (328 of that still's 691,200 pixels), so `sheet.png` is not the same file byte for byte from run to run. `process.png` and `well.png` were.

Not explained: why a walker whose `floor_max_angle` is 60 degrees is stopped by a ramp whose steepest triangle is 58.0 degrees, while 61 degrees is enough. Why the plan stills differ at all: the pixels that do are on the lit tops of the treads, one step in the blue channel. And where the narrow guest's lowest rise lies: `verification.json` holds 0.18 m (stopped, with the landing test that says why) and 0.30 m (climbed); a scratch probe had it stopped at 0.20 m too and climbing at 0.22, 0.25 and 0.30 m, each step landing with a normal whose y was between 0.90 and 0.93, close to the 0.9 the walker asks for. On treads this narrow the guest's stair works by a small margin.

Two sessions made this kit. The first built it and was cut off during its last run. The second ran everything named above again on fresh copies (`verify.gd` in real time and with `--fixed-fps 60`, the replay of the lesson, the 21 negative tests, `sheet.gd`, the room test), found the first session's results reproduced, and added two measurements: the count with no threshold in `sheet.gd`, and the landing test in `verify.gd`.
