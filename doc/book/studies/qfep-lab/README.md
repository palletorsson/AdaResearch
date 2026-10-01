# The QFEP laboratory — order toward entropy

The study kit of chapter 40 of the Godot course. A small Godot 4.6 project with two bodies in it. A row of 200 seeded symbols, each a bar with a height and a colour, which a tween sorts four ways while its Shannon entropy is counted and stays the same. And a prediction log, read from a JSON file and stood on the floor as sixteen plates, each as high as that chapter's prediction was wrong: a line to walk along. The lesson is [TUTORIAL.md](TUTORIAL.md). The kit's own field note is [FIELD_NOTE.md](FIELD_NOTE.md).

## Open it

In the Project Manager of Godot 4.6 choose **Import** and open this folder's `project.godot`. Press Play (F5): `lab.tscn` is the main scene.

Keys: Space glides the row into its next arrangement (as drawn, sorted by value, sorted by colour, sorted in reverse). W A S D or the arrows walk the walker; C changes between the camera over the floor and the walker's eyes; hold V or the right mouse button and move the mouse to look; J jumps.

## What is in the folder

Built in the lesson (the learner's two scripts):

- `row.gd`: the row. Exported: `arrangement`, `seed_value` (40), `count` (200), `glide` (seconds). `tally()` counts the symbols in a dictionary, `entropy()` gives the Shannon entropy of their shares in bits, `arrange(how, seconds)` sorts with `sort_custom()` and starts the tween.
- `f_curve.gd`: the log. Exported: `log_file`, `rise` (metres of height for one point of F). It reads the log, gives every entry its F = |predicted − observed|, ranks them, and stands a plate, a label and a piece of the line for each.
- `steps/`: the two scripts as they are after each step of the making, seven of `row.gd` and two of `f_curve.gd`. They are recovery points: copy one's contents into the script. The last of each is the script itself. `row-6-orders.gd` is the script at **Stop here**, before the planted bug's two lines.

Supplied:

- `lab.tscn`: the scene. It inherits `supplied/base.tscn`, moves the camera back, and adds `Row`, `Curve` and the walker.
- `sketchbook.json`: the log the kit ships with. See *The log*, below.
- `supplied/`: the kit base's parts, unchanged, byte for byte.
- `guests/qfep-lab/`: the body this kit hands to the room: the log as a relief 1.5 m wide. Its script, its scene and a `sketchbook.json` of its own are in the folder; it names nothing outside it.
- `verify.gd`, `sheet.gd`: the checks and the stills.

Colours: the bars take the look's `BODIES` in order, by `value % 4`; the plates are BODY, the line LINE, the words INK, the walker SECOND, the floor GROUND. In the guest the plate of the largest F is SECOND. No colour in this kit is its own. The bars are a `MultiMesh` with a colour for each instance; read back from a still, their front faces are `#bdf735`, `#1bd0f7`, `#f78218` and `#ece7dd`, within one step of 255 of what the kit base measured for a painted box. The row has one collider, a box as large as the row can be, so it is a body and not a ghost; what that box costs is measured in the lesson. The scene runs in the look with its filter; every measured still was made in `sheet_tools`' plain studio.

## The log

`sketchbook.json` is not a student's sketchbook. It holds the course's own predictions: for sixteen chapters whose kits had a finished sheet on 1 October 2026, the pair the course's outline named as the closest (for the organism, the pair the lesson itself expected) and what the kit's sheet measured. `predicted` is the difference measured for the named pair, `observed` the difference of the closest pair, both in percent of a still. The numbers were read from the kits' `sheet.json` files; nothing of those kits was run again here, and several were still being finished that day. If one of those sheets changes, this log is stale.

| chapter | standpoint read | named | predicted | closest | observed | F |
| --- | --- | --- | --- | --- | --- | --- |
| organism | top | the end and one third | 1.94 | one third and the centre | 1.27 | 0.67 |
| chessboard | study camera | chessboard and stripes | 14.26 | every cell alike and stripes | 11.12 | 3.14 |
| family | level | 16 and 64 | 0.85 | the same | 0.85 | 0 |
| collage | level | by hand and drafted | 0.00 | the same | 0.00 | 0 |
| extrude | side | 1.0 and 0.6 | 12.33 | 0.2 and 0.0 | 3.36 | 8.97 |
| family-editor | level | corner and beyond | 3.64 | centred and edge | 0.49 | 3.15 |
| bullet | stills, velocity first | 1/60 and 1/240 | 1.19 | 1/10 and 1/30 | 0.49 | 0.70 |
| legs | level | 3 and 6 parts | 3.03 | the same | 3.03 | 0 |
| spiral-stair | side | 0.10 and 0.18 | 5.21 | the same | 5.21 | 0 |
| sound | level | 2:1 and 3:2 | 5.97 | 1:1 and 2:1 | 3.43 | 2.54 |
| disturbed-order | plan | 0 and 5 degrees | 1.81 | the same | 1.81 | 0 |
| shader-skin | our skin at 2 m | p 3 and p 8 | 9.06 | the same | 9.06 | 0 |
| cellular | level | rule 90 and rule 250 | 4.83 | the same | 4.83 | 0 |
| genome | above | 6 and 12 limbs | 8.23 | 0 and 2 limbs | 2.74 | 5.49 |
| soft-body | ours | 16 and 64 passes | 3.02 | the same | 3.02 | 0 |
| combine | front right | the first two orders | 12.12 | the same | 12.12 | 0 |

The rule that turns a prediction into a number is ours, and it is one of several possible. It gives 0 to a pair named for a reason that did not hold, and it cannot hold a prediction that was not about a closest pair. The sixteen numbers are not added up anywhere in this kit: F is not a score.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 77 checks and writes `verification.json`; its exit code is the number of checks that failed. It needs no import step. It takes about 16 seconds, because the walker walks and the row glides in real time, and under a second with `--fixed-fps 60` added. Between the two, two of the entries of `measured` differed in our runs: `glide_seconds_by_the_clock` (1.47 or 1.48, and 0.01) and the walker's feet on one plate (0.122 and 0.121 m). Two runs in real time differed in that clock reading and in nothing else. The run provokes four errors on purpose (a missing log, a missing comma, a missing key, a name with a comma in it), so red lines in its output are expected; its last check counts them. For its trials of other logs it writes three small files to `user://` and removes them before it ends.

`sheet.gd` needs a window, so it is run without `--headless`; it closes its window by itself after about eight seconds. It writes `sheet.png` (four arrangements, from the side and from above), `process.png` (the strip), `sheet.json` (the measurements) and the single stills in `stills/`. Two runs on fresh copies gave the same three files byte for byte. As it exits, Godot prints two lines `ERROR: Texture with GL ID of ... leaked 349524 bytes`; they come after `sheet.json written`, the exit code is 0, and we did not find out which texture it is.

## The guest and the room

Copy `guests/qfep-lab/` into the `guests/` folder of your room project and add `"res://guests/qfep-lab/qfep-lab.tscn",` to `GUESTS` in the room's `room.gd`. To make the guest yours, replace the entries of the `sketchbook.json` in the guest's folder in your room. The lesson's last section says the rest.

The room's own trial was run once, in a scratch copy of `my-room` with this guest copied in and its line added. `guest_trial.json` here is its result: 8 checks, none failed; the room ran 180 frames with no error; the guest stood at place 2 and printed `QFEP lab: 16 chapters; most wrong: extrude, F = 8.97`; the walker reached the aisle in front of it, walked at it and the walk ended "blocked", 0.50 m from the middle of the place, its feet at 0.00 m. Sixteen plates of 0.094 m with different heights give the walker's foot no level place: it does not step onto this guest. With a log of three chapters in the guest's folder the plates are 0.5 m wide; the same trial then ended "arrived", 0.08 m from the middle, the walker's feet at 0.30 m, on the highest plate.

## What was and was not checked

Checked, headless, by `verify.gd` (77 of 77 on a fresh copy with no `.godot/`, with and without `--fixed-fps 60`): the project's name and main scene; the 15 files of `supplied/`; tabs, LF and no `class_name` in the kit's scripts; the log's form; the scene running 180 frames with no error; the 200 draws of seed 40, their counts, the order of the dictionary's keys, the entropy and its ceiling; the same seed and another seed; the `MultiMesh` and the row's collider; the four arrangements, each holding the same symbols, each in the order it promises, equal symbols in the order drawn; the four entropies equal to the last bit; runs; Space, the tween starting and ending, Space during a glide; the planted bug compiled from `row.gd` with its two lines taken out, its printed line, its silence, and the same fault hidden at 200 symbols; ties answered `false`; the refused `@export_enum` name; the sum taken in the order met; the entropy by colour; the rows of seeds 1 to 100; the log's sixteen entries, their ranking, the plates, their colliders, the line and the labels; another log; a missing log, a missing comma and a missing key, each with Godot's own message; the walker along the log plate by plate, off its end, at the row, and along a log with `rise` at 0.1; a marble on the row's box; the guest standing on its own, fitting its box, stopping a walker, with another log and with none; the recovery points.

Checked, with a window, by `sheet.gd`, and each picture looked at: `sheet.png` (1292 × 510), `process.png` (1940 × 266). The stills measured 960 × 720 on an NVIDIA GeForce RTX 3070 with the Compatibility renderer. A headless run cannot read a `MultiMesh` back, so what the bars do on screen is checked here: the place and height of one bar read back from the `MultiMesh` in all four arrangements, 194 of 200 bars standing between two places at 0.37 of a glide, a tween under way after 0.3 s, and every bar on its place 0.5 s later.

Every code block of the lesson, nineteen of them, was applied in page order to a fresh copy and each of eleven states run; the printed lines are the ones the lesson quotes, and the last states equal `row.gd` and `f_curve.gd` byte for byte. The nine files of `steps/` were written by that run.

Negative tests, each in a scratch copy with one fault planted, each failing `verify.gd`: the planted bug, the two lines of the skip taken out (4 checks failed); a comma out of `sketchbook.json` (9); `"observed"` out of an entry (9); `"sorted by value, reversed"` as a name (5); ties answered `false` (3); the sum taken in the order met (5); `rise` at 0.1 (7); plates with no collider (5); the row with no box (4); a reverse that does not reverse (3); the seed not set (16 in our last run, 15 and 14 in runs before it: an unseeded generator draws another row every time); a guest that preloads `supplied/look.gd` (1); a guest with a `class_name` (2); a guest whose log is not the kit's (1); a last step that is not the script (1).

Not checked: nothing was run in a headset. Nobody walked with their hands on the keys: the walker was driven by its autopilot, and Space was pressed from the script. The editor's windows were not watched: the FileSystem dock, the Play button, the Output panel and the Inspector are described from knowledge of the editor, and the Inspector step is marked *(editor)* in the lesson. No eye was asked which rows look alike; "look alike" is a count of pixels. The sixteen entries of the log were read from other kits' sheets and not run again. The last digits of the entropy were measured on one machine; `log()` may round otherwise on another processor, and then the sum taken in the order met may differ at another row or at none. No export was made, so whether `sketchbook.json` travels in an exported build was not tried. No learner has used the kit.

Two things to know. `sort_custom()` here sorts the numbers of the draws, not the symbols; which of two equal symbols comes first is decided by the last line of `before()`, and without it by Godot. And the walker is wider than a plate: on six of the sixteen plates it stands on a higher neighbour, not on the plate it was sent to.
