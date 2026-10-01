# The bullet — study kit

A small Godot 4.6 project for chapter 22 of the course, *The bullet: a curve made of steps*. A ball is thrown and moved by two lines of our own (`velocity += pull() * dt`, `at += velocity * dt`), its path is kept in an array and drawn as a line and a row of dots, and the same throw is compared at four lengths of step. The lesson is [TUTORIAL.md](TUTORIAL.md); the kit's own field note is [FIELD_NOTE.md](FIELD_NOTE.md).

## Open it

In the Project Manager of Godot 4.6 choose **Import** and open this folder's `project.godot`. Press Play (F5): `launch.tscn` is the main scene.

| key | what it does |
| --- | --- |
| Space | fires the bullet again |
| M | takes the next of 4, 10, 30, 60 and 240 steps a second, and fires |
| W A S D, or the arrows | walk the Walker |
| the right mouse button, or V, held | turn the Walker with the mouse |
| J, C | the Walker jumps; change between its eyes and the fixed camera |

The Output panel says what happened: `dt 1/60 s: 73 steps, landed 4.867 m from the launch`, and `hit at step …` when a step of the ball is inside the Walker.

## What is in the folder

Built in the lesson:

- `bullet.gd`: the learner's script. The lesson takes it apart and builds it again in five steps; the file here is the finished one.
- `orbit.gd`: twelve lines, typed in the lesson: the same body with a pull towards a centre.

Supplied with this kit:

- `launch.tscn`: the base, the `Bullet`, the `Mark` and the `Walker`.
- `bullet.tscn`: a `Node3D` with a `Ball` (a sphere of 0.1 m radius) and a `Path` (a `MeshInstance3D` that gets its mesh from the script).
- `orbit.tscn`: the base, a `Centre`, and an instance of `bullet.tscn` that runs `orbit.gd`.
- `mark.gd`: the lavender disc on the floor, where the formula 2 × 4 × 6 / 9.8 puts the landing: 4.898 m from the Bullet. It does not follow `launch`.
- `verify.gd`, `sheet.gd`: the checks and the stills.
- `guests/bullet/`: the body this kit hands to the room.

From the kit base, unchanged, byte for byte: `supplied/` (15 files), `.gitignore`, `export_presets.cfg`. No script in the kit declares a `class_name`, so nothing needs an import.

Outputs, made by the two commands below: `verification.json`, `sheet.json`, `sheet.png`, `orbit.png`, `process.png`. `room_trial.json` is the room's own test of the guest, run once in a scratch copy of `my-room`.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 53 checks and writes `verification.json`. Its exit code is the number of checks that failed. It takes about 35 seconds, because the flights in the running scene and the Walker's walks take the time they take; with `--fixed-fps 60` added it takes about two seconds and passes the same 53.

`sheet.gd` needs a window, so it is run without `--headless`. It writes `sheet.png`, `orbit.png`, `process.png`, `sheet.json` and the stills in `stills/`, and closes its window by itself after about twelve seconds. As it exits Godot prints two lines, `ERROR: Texture with GL ID of … leaked 349524 bytes`. They come from the caption font of the supplied `compose()`: the kit base's own `sheet.gd` prints the same two, and the files are whole.

The room's test of the guest, in a copy of `../my-room/` with `guests/bullet/` copied into its `guests/` and its line added to `GUESTS` in `room.gd`:

```
godot --headless --path . --xr-mode off --script res://guest_trial.gd -- bullet
```

## The look

Every colour is a role of `supplied/look.gd`: the ball is BODY, the path and its dots LINE, the Mark GHOST, the orbit's centre THIRD, the Walker SECOND as supplied. The formula's curve in `sheet.png` is GHOST. The guest writes BODY and LINE out as hex values, because a guest names nothing outside its folder. The light and the sky are the base's, unchanged. The base has two skies: a scene that runs shows a sky from violet down to a pink horizon, and the studio of `sheet.gd` is flat pink, so that a still measures the body and not the sky. Every measured still here was made in the studio.

## What was measured

All of it is in `verification.json` or `sheet.json`.

- **The axis.** At 1/10, 1/30, 1/60 and 1/240 s the flight takes 12, 36, 73 and 293 steps, lands 4.800, 4.800, 4.867 and 4.883 m from the launch (the formula: 4.898 m), rises to 1.642, 1.838, 1.887 and 1.924 m (the formula: 1.937 m), and is at most 53.9, 19.1, 9.8 and 2.5 cm under the formula's ball of the same moment.
- **The pairs.** By the stills' pixels the closest pair is 1/10 and 1/30 (0.49% of the still) and the farthest 1/30 and 1/240 (1.40%); 1/60 and 1/240 differ on 1.19%. By the landing the closest pair is also 1/10 and 1/30 (the same spot). By the highest place it is 1/60 and 1/240 (3.7 cm). The course outline's prediction held for the third of these only.
- **The planted bug.** With the two lines swapped the flights land 5.600, 5.067, 5.000 and 4.917 m from the launch, and Godot logs nothing. The outline expected the swap to make an orbit spiral outward. It does not: swapped, the orbit stayed between 0.984 and 1.017 m from its centre for 60 s, as it does in the right order. With both lines reading the state from before the step (explicit Euler) it is 1.377 m out after one turn and on the floor after 7.98 s; at 240 steps a second, after 25.97 s.
- **The engine.** The supplied marble, a `RigidBody3D`, thrown with the same launch and no damping, rises to 1.887, 1.642, 1.838 and 1.924 m at 60, 10, 30 and 240 physics ticks a second: the bullet's own heights. As shipped (`default_linear_damp` 0.1) it rises to 1.814 m at 60.
- **A body.** The Walker, sent by its autopilot to the formula's landing point, stood 4.84 m from the launch and was hit 0.69, 0.60, 0.42 and 0.10 m above its feet at 1/240, 1/60, 1/30 and 1/10 s, and not at all at 1/4 s, which lands 0.9 m short. Standing 3.57 m from the launch it was hit at 1/60 and 1/10 s and stepped over at 1/4 s. Nothing pushed it.
- **By the frame.** Five flights stepped once for each drawn frame, with the frame's own length as `dt`, took 74, 73, 73, 73 and 73 steps and landed 4.8708, 4.8695, 4.8339, 4.8667 and 4.8667 m from the launch. These five numbers are different in every run of `sheet.gd`.

## What was and was not checked

Checked, headless, by `verify.gd` (53 checks; 53 of 53 on a fresh copy with no `.godot/`, with and without `--fixed-fps 60`): the project and its supplied files; the body and its materials; one step and three, to the millimetre; the four flights and three more; the swap, and that nothing is logged; the running scene stepped by its clock, Space, M, the Mark; the orbit stepped three ways at three rates, and running; the marble at four tick rates, with and without damping; the Walker hit, missed and stepped over; the guest alone, its two printed lines, its place; no error and no warning in the whole run.

Checked, with a window, by `sheet.gd`, and each picture looked at: `sheet.png` (1292 × 536: the four steps, and under them the four with the lines swapped, each with the formula's curve), `orbit.png` (968 × 266: two closed rings and a spiral that ends on the floor), `process.png` (2264 × 266, seven steps). The stills measured 960 × 720 on an NVIDIA GeForce RTX 3070 with the Compatibility renderer, on a screen of 59.95 Hz.

Every code block of the lesson was extracted and run in page order, headless and as the running project in a window. The last state equals `bullet.gd` and `orbit.gd` byte for byte.

Negative tests, in scratch copies, one fault at a time; each failed `verify.gd`: the two lines swapped; both lines from the old state; the frame's delta as the step; one material for line and dots; the landed ball not put on the floor; `launch` changed and the Mark not moved; no node named Walker; a hit that is never recorded; a guest that uses the kit's look; a guest thrown wider than its place; the guest's two lines swapped; an orbit that pulls away from its centre; spaces for tabs.

The room: in a scratch copy of `my-room` the guest stood at place 2, the room ran 180 frames with no error, and the walker's autopilot walked at the guest and arrived 0.07 m from the middle of the place, its feet on the floor: the guest has no collider. The same test passed with the two lines of the lesson's room task changed.

Not checked:

- Nothing was run in a headset, and no XR node is in the kit.
- The Walker was walked by its autopilot, and Space and M were pressed from the script, not by a hand on the keys.
- The editor's windows were not watched: Play, Stop, Run Current Scene, the Project Settings.
- No eye was asked which two flights look alike. "Look alike" here is a count of pixels, and the lesson says why that count is a poor ruler for dots.
- No energy was computed for the orbit; the distance from the centre was measured.
- The intervention the lesson offers under **Decide**, moving the ball by the average of the old and the new velocity, was not run.
- One machine, one graphics card, one screen at 60 Hz. On a faster screen the frames are shorter, and the flights stepped by the frame would be others.
- No learner has used the kit.
