# Rules in time — the study kit of chapter 31

A small Godot 4.6 project. One row of cells, a rule of eight answers, and every row the rule makes kept as a step of a stair a walker can stand on. Then the same read-one-buffer, write-another step runs a second rule, reaction and diffusion, on a floor that moves under the walker. The lesson is [TUTORIAL.md](TUTORIAL.md); the kit's own field note is [FIELD_NOTE.md](FIELD_NOTE.md).

## Open it

In the Project Manager of Godot 4.6 choose **Import** and open this folder's `project.godot`. Press Play (F5): `cellular.tscn` is the main scene. The second scene, `diffusion.tscn`, is run with F6 while it is open. The editor's own view shows a white floor and Godot's preview light; the look is applied when a scene runs.

Keys: W A S D or the arrows walk, J jumps, C changes between the walker's eyes and the scene's camera, and the mouse turns the walker while the right button or V is held.

## What is here

Built in the lesson:

- `cellular.gd`, on the node `Automaton` of `cellular.tscn`. Seven exported fields: `rule` (0 to 255, 90 as shipped), `ring` (the two ends are neighbours; unticked, beyond an end is dead), `pace` (seconds from one row to the next; 0 lays every row at once), `n` (17 cells), `rows` (11), `cell` (0.4 m), `rise` (0.15 m). It prints each row as it lays it.
- `around()` and `step()` of `diffusion.gd`, on the node `Pool` of `diffusion.tscn`.

Supplied with the kit:

- `supplied/`, the same fifteen files as in every kit and in the room, unchanged.
- The rest of `diffusion.gd`: four buffers of 24 x 24 numbers, B drawn as tiles, and a `HeightMapShape3D` that gets one height for each cell. Exported: `feed` (0.055), `kill` (0.062), `pace` (steps in one frame; 4).
- `cellular.tscn` and `diffusion.tscn`. Both inherit `supplied/base.tscn` and move its camera back and up, low enough that the pink horizon stays in the picture; neither changes the light or the sky.
- `guests/cellular/`: the body this kit hands to the room. `cellular.tscn` there is a stair of 17 rows of Rule 90 with cells of 0.09 m, 1.53 m wide and deep and 0.68 m high, a row every 0.8 s. Its script is `cellular.gd` with the one colour written out, so the folder names nothing outside itself.
- `verify.gd`, `sheet.gd`, and what they wrote: `verification.json`, `sheet.json`, `sheet.png`, `process.png`, `pool.png`.

Colours: the stair is BODY, the walker SECOND, and the pool THIRD, because the walker stands on it and is SECOND itself. No colour here is the kit's own.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 70 checks and writes `verification.json`; its exit code is the number that failed. It needs no import step. It takes about half a minute, because the walker walks in real time, and about three seconds with `--fixed-fps 60` added, with the same result.

`sheet.gd` needs a window, so it is run without `--headless`. It writes `sheet.png`, `process.png`, `pool.png`, `sheet.json` and the single stills in `stills/`, and closes its window by itself after about ten seconds.

## What was checked

By `verify.gd`, headless, on a fresh copy of this folder with no `.godot/`, in real time and again with `--fixed-fps 60` (70 of 70 both times):

- each of the rules 30, 90, 110 and 250: the rows the script prints, and the cells its colliders cover, against the same rule written another way in `verify.gd`; one tile for each live cell; with `ring` unticked as well;
- that `now` and `next` are two buffers; that the ring joins cell 0 and cell 16; that Rule 30 gives the same rows twice;
- the lesson's planted fault, made by giving both names one buffer: the rows, the ten cells of row 1, 72 cells unlike their mirror, and that Godot logs nothing;
- the rows arriving one at a time, a quarter of a second apart, and stopping at eleven; where each row stands;
- one `StaticBody3D` for each row and one box for each run (33 boxes for the 37 tiles of Rule 90); a marble on the seed, through a gap of Rule 90, and on the tile Rule 250 has at the same place;
- the walker's autopilot up the middle of each of the four floors, up the left edge of Rule 90, and through a floor whose colliders were taken away; and the lesson's own way to the seed, D and then W, with the two actions pressed from the script;
- the pool: its buffers, its numbers after 1000 steps, a second pool with the same numbers, the heights handed to the collider, a walker standing on it for 600 steps and then walking out;
- the guest: nothing named outside its folder, no `class_name`, its script against `cellular.gd`, that it grows over time, its size, and a walker sent to it;
- both scenes running 180 frames with no error and no warning.

By `sheet.gd`, with a window, in the plain studio of `sheet_tools.gd`, and each picture looked at: `sheet.png` (the four rules from 9 m above and from 6.5 m in front), `process.png` (seven steps), `pool.png` (the pool after 0, 100, 300 and 1000 steps). Two runs gave the same `sheet.json` and the same three pictures, byte for byte. The stills are 960 by 720, made on an NVIDIA GeForce RTX 3070 with the Compatibility renderer.

Every code block of the lesson was applied in page order to a fresh copy and each state was run; the outputs the page quotes were in what Godot printed, and the last state equals `cellular.gd` and `diffusion.gd` byte for byte. The three things under *Try* that the page states a result for were run as well.

Faults planted one at a time in scratch copies, each of which made `verify.gd` fail: `step()` writing into the buffer it reads (25 checks failed); `next = now` (25); the swap left out (25); `lay_row()` without colliders (15); `ring` false by default (2); left and right exchanged in the index (7); `pace` 0 by default (3); the pool writing into the buffers it reads (3); the pool's swaps left out (2); a guest that uses `supplied/look.gd` (2); a guest with a `class_name` (3); a guest with cells of 0.12 m (2). A line indented with spaces makes `cellular.gd` fail to parse, so `verify.gd` does not load and Godot exits with code 1 before any check.

The room: in a scratch copy of `my-room` with this guest's folder copied in and its line added to `GUESTS`, `guest_trial.gd` passed 8 of 8. The guest stood at place 2, and the walker arrived 0.08 m from the middle of the place with its feet at 0.32 m. The same again with the guest's rule changed to 30.

## What was not checked

- Nothing was run in a headset, and no hand was on the keys: every walk is the walker's autopilot, or actions pressed from the script.
- The editor's windows were not watched: the Inspector's **Rule** field, F6 and the **Run Current Scene** button, and the Output panel are described from knowledge of the editor.
- No eye was asked which two floors look alike. "Differ" is a count of pixels above a threshold, and a count of cells.
- The stills were made on one machine and one graphics card. The two running scenes were photographed once each in the look with its filter and looked at; those pictures are not shipped and nothing was measured on them.
- The pool was run at one pair of numbers. The other pair the lesson offers under *Try* was not rendered.
- Rules 0, 255 and 184 were run for errors (none) and not looked at.
- A walk that starts at an angle to a tile can end "blocked" at its corner where a walk from straight ahead steps up. We met this once while making the strip and went round it; we did not chart it.
- `sheet.gd` ends with two lines `ERROR: Texture with GL ID of ...: leaked 349524 bytes`, after `sheet.json` is written, and exits with code 0. The kit base's own `sheet.gd` ends the same way. We did not find the cause.
- No learner has used any of it.
