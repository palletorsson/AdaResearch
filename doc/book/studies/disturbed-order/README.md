# Disturbed order — chance enters the grid

The study kit of chapter 11 of the Godot course. A small Godot 4.6 project in which a floor of sixty cubes is turned and slid by a seeded random number generator, more with every column (Georg Nees's *Schotter*, lying down), and a maze is made from one draw of two for each cell (10 PRINT). The lesson is [TUTORIAL.md](TUTORIAL.md). The kit's own field note is [FIELD_NOTE.md](FIELD_NOTE.md).

## Open it

In the Project Manager of Godot 4.6 choose **Import** and open this folder's `project.godot`. Press Play (F5): `schotter.tscn` is the main scene. `maze.tscn` is the second scene; open it and run it with **Run Current Scene** (F6).

Keys: W A S D or the arrows walk the walker; C changes between the camera above the floor and the walker's eyes; hold V or the right mouse button and move the mouse to look; J jumps. In `schotter.tscn` Space builds the floor of the next seed.

## What is in the folder

Built in the lesson (the learner's two scripts):

- `schotter.gd`: the floor. Two exported fields, `amplitude` (degrees, the most a cube of the last column may turn) and `seed_value`.
- `maze.gd`: the maze. One exported field, `seed_value`; `leans` keeps which way each wall leans.
- `steps/`: `schotter.gd` as it is after each of the five steps of the making. They are recovery points: copy one's contents into `schotter.gd`. The last is `schotter.gd` itself.

Supplied:

- `schotter.tscn`, `maze.tscn`: the two scenes. Each inherits `supplied/base.tscn`, raises its camera, and adds one empty `Node3D` that runs the learner's script, and the walker.
- `supplied/`: the kit base's parts, unchanged: the base scene, the look, the walker, the check and still tools.
- `borrowed/cube_part.tscn`: from The Chessboard (and A Body of Parts before it). Contract: a cube of 0.5 m built round its own middle, a `MeshInstance3D` with a `StaticBody3D` named `Body` and a box shape; no script and no colour of its own.
- `guests/disturbed-order/`: the body this kit hands to the room. A patch of Schotter floor, 25 cubes of 0.2 m, 1.24 m square in order, with `amplitude` and `seed_value` exported. It has its script in its own folder, writes its colour out, and names nothing outside the folder.
- `verify.gd`, `sheet.gd`: the checks and the stills.

Colours: every body is BODY, the walker SECOND, the floor GROUND, from `supplied/look.gd`. No colour in this kit is its own. The light and the sky are the look's. The two scenes run in the look with its filter, and their cameras look down steeply, so the running view shows lime on violet and no horizon; press C for the walker's eyes and the sky is there. Every measured still was made in `sheet_tools`' plain studio.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 66 checks and writes `verification.json`; its exit code is the number of checks that failed. It needs no import step. It takes about a minute, because the walker walks in real time, and about two seconds with `--fixed-fps 60` added, with the same measurements. Two entries of `measured` are different in every run, and that is what they record: `two_builds_without_a_seed` and `two_builds_with_randomize_under_the_seed_line`.

`sheet.gd` needs a window, so it is run without `--headless`; it closes its window by itself after about ten seconds. It writes `sheet.png` (four amplitudes, in plan and from a raised standpoint), `process.png` (the strip), `maze.png` (the maze in plan at seeds 1982 and 2010), `sheet.json` (the measurements) and the single stills in `stills/`.

## The guest and the room

Copy `guests/disturbed-order/` into the `guests/` folder of your room project and add `"res://guests/disturbed-order/disturbed-order.tscn",` to `GUESTS` in the room's `room.gd`. The lesson's last section says the rest.

The room's own trial was run once, in a scratch copy of `my-room` with this guest copied in. `guest_trial.json` here is its result: 8 checks, none failed; the room ran 180 frames with no error; the guest stood at place 2; the walker reached the aisle in front of it, walked at it and the walk ended "arrived", 0.10 m from the middle of the place, its feet at 0.22 m: it stepped onto the patch.

A turned cube of the guest dips under the ground by up to 7 cm, as the cubes of the lesson's floor do: a cube turns about its own middle. The first column stands on the ground in order.

## What was and was not checked

Checked, headless, by `verify.gd` (66 of 66 on a fresh copy with no `.godot/`, with and without `--fixed-fps 60`): the project's name and main scene; the 15 files of `supplied/`; tabs and no `class_name` in the kit's scripts; the borrowed part; the floor's sixty cubes, their shared material, the limits of every turn and slide, the first column in order, the colliders standing exactly as their meshes; the same seed giving the same floor, another seed another, `build()` twice, Space; that amplitude 20 is amplitude 5 times four at one seed; two builds without a seed; the planted bug and three silent faults, each compiled from `schotter.gd` with one thing changed; how many cubes reach over the middle of a gap at each amplitude, and at which amplitude the first does under ten seeds; the walker crossing the floor at four amplitudes and five seeds, with gaps of 0.3 m, and without its step; the maze's walls, its corridors followed by rule, the walker stopped by a wall, led along two corridors, and which of 100 seeds can be crossed; Space printing the line of seed 1969; the guest standing on its own, fitting its box, saying its seed at 1968 and at 2026, and stepped onto; the five recovery points.

Checked, with a window, by `sheet.gd`, and each picture looked at: `sheet.png` (1292 × 510), `process.png` (1616 × 266), `maze.png` (644 × 266). The stills measured 960 × 720 on an NVIDIA GeForce RTX 3070 with the Compatibility renderer.

Every code block of the lesson was applied in page order to a fresh copy and each state run; the last states equal `schotter.gd` and `maze.gd` byte for byte, and the five states of the making equal the files in `steps/`.

Negative tests, each in a scratch copy with one fault planted, each failing `verify.gd`: `rng.randomize()` under the seed line (10 checks failed in our last run, 11 and 12 in runs before it; the number depends on the floors that run happens to make); the seed line moved into the inner loop (13); one unused draw under the seed line (6); `float()` taken away (7); `randomize()` in the maze (6 in our last run, 5 in the one before); a guest that preloads `supplied/look.gd` (1); a guest with a `class_name` (2).

The kit was built by one session and finished by a second, which ran all of the above again from a fresh copy: `sheet.gd` wrote the same three pictures and the same `sheet.json`, byte for byte, and the room's trial gave the same `guest_trial.json`.

Not checked: nothing was run in a headset. Nobody walked with their hands on the keys: the walker was driven by its autopilot, and Space was pressed from the script. The editor's windows were not watched: the Inspector, Run Current Scene and the Output panel are described from knowledge of the editor, and marked *(editor)* in the lesson. No eye was asked which floors look alike; "look alike" is a count of pixels. Older versions of Godot were not run. No learner has used the kit.

Two things to know about the walker on this floor. It takes each gap of 0.1 m as a step, and a step carries it 0.32 m forward at once, so it crosses the floor in order in about half the time 2 m/s would need; its speed over the cubes is no measure of anything. And whether it crosses a floor of rubble depends on the seed: the lesson gives counts over five seeds, not a rule.
