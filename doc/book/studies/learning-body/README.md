# Bodies that learn — the study kit of chapter 38

A small Godot 4.6 project. Labelled places on a floor, read from a JSON file that records who labelled each one, and a rule that colours every cell of the floor by the labels nearest to it. Then a perceptron's line on the same data, the line's error as a floor a walker goes down, and two keys that add your own labels and save them. The lesson is [TUTORIAL.md](TUTORIAL.md); the kit's own field note is [FIELD_NOTE.md](FIELD_NOTE.md).

## Open it

In the Project Manager of Godot 4.6 choose **Import** and open this folder's `project.godot`. Press Play (F5): `learning_body.tscn` is the main scene. The editor's own view shows a white floor and Godot's preview light; the look is applied when the scene runs.

Keys: W A S D or the arrows walk, J jumps, C changes between the walker's eyes and the scene's camera, and the mouse turns the walker while the right button or V is held. **Space** labels the place you stand on *stay* and **M** labels it *pass*; both save at once to `my_samples.json`, which the kit does not ship and which is yours to delete.

## Nobody in the data is a person

The chapter asks for the learner's own walk traces and their classmates', labelled with consent. This kit was built at a desk by a session of Claude, with no class and no walk, so `samples.json` holds stand-ins and says so in its second line. `make_samples.gd` made the file and makes the same file again (seed 38).

- **the builder** (the value *one person*): 36 places along a figure-eight, labelled one by one by a session that built the kit, looking at a text plot of them. 13 stay, 23 pass.
- **classmate 1, 2, 3** (*the class*): 12 places each, along walks of their own. Each answers by a rule, stay where the floor is nearer the front than a line of its own, and each flips one answer in six.
- **nobody** (*a default dataset*): two round heaps of 18, pass on the left and stay on the right.
- **a coin** (*random labels*): the builder's 36 places, each label thrown by a seeded coin. 17 of the 36 differ from the builder's.

The file's `consent` list holds the builder and the three classmates. It holds no line for *nobody* or for *a coin*, and the script prints `not recorded` for them. A sample you add is labelled `you`, and `"you": true` is written under `consent` because you pressed the key.

Every number in the lesson about "the class" or "one person" is a number about these stand-ins.

## What is here

Built in the lesson:

- `learning_body.gd`, on the node `Field` of `learning_body.tscn`. Four exported fields: `file` (`res://samples.json`), `labelled_by` (one person, the class, a default dataset, random labels, you; 0 as shipped), `k` (1 to 9 in steps of 2; 3), `rule` (neighbours, a line, the error; 0). Fifteen functions. It prints who labelled the chosen samples and their consent, `painted 640 cells`, and how many of its own samples it is wrong about.

Supplied with the kit:

- `supplied/`, the same fifteen files as in every kit and in the room, unchanged.
- `samples.json` and `make_samples.gd`.
- `learning_body.tscn`: it inherits `supplied/base.tscn`, moves its camera back and up to (0, 3.2, 7.6), and adds `Field` and the supplied `Walker`. It changes neither the light nor the sky.
- `guests/learning-body/`: the body this kit hands to the room. `learning-body.tscn` is the kit's floor at 0.19 of its size, 1.52 m by 0.95 m, on a slab 0.10 m high with a collider; `portrait.gd` reads the `samples.json` beside it (the builder's 36 samples), paints the same vote, and says over the slab what it was trained on, whether the file records consent, and how often it is wrong: about its own samples, and about each sample when that one is left out. A walker on the slab is told the label it stands on. The folder names nothing outside itself and declares no `class_name`.
- `verify.gd`, `sheet.gd`, and what they wrote: `verification.json`, `sheet.json`, `sheet.png`, `k.png`, `process.png`. `room_trial.json` is the record of the room test.

Colours. The field is GROUND turned toward BODY (stay) or SECOND (pass) by three quarters of the vote's share, so each label has a bright and a dull colour. The error floor is GROUND turned toward THIRD. The line laid on the floor is LINE, the walker SECOND. The sample balls have no collider and are not GHOST: their colour is their label. No colour here is the kit's own.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
godot --headless --path . --xr-mode off --script res://make_samples.gd
```

`verify.gd` runs 128 checks and writes `verification.json`; its exit code is the number that failed. It needs no import step. It takes about twelve seconds, because the walker walks in real time, and about three with `--fixed-fps 60` added, with the same result. It saves its test labels under `user://` and removes them, so a `my_samples.json` of yours is left alone; but it checks that the kit ships none, so that check fails in a copy where you have labelled. Run without `--headless` it makes 129 checks: with a window it reads the texture back.

`sheet.gd` needs a window, so it is run without `--headless`. It writes `sheet.png`, `k.png`, `process.png`, `sheet.json` and the single stills in `stills/`, and closes its window by itself after about ten seconds.

`make_samples.gd` writes `samples.json` and the guest's `samples.json` again, the same bytes.

## What was checked

By `verify.gd`, headless, on a fresh copy of this folder with no `.godot/`, in real time and again with `--fixed-fps 60` (128 of 128 both times, the same lines):

- the project, the two actions that label, tabs and LF in every script, no `.uid`, `.import` or `.godot`;
- `samples.json`: that it parses, its 144 samples and six labellers, the consent list, that the coin labels the builder's own places and flips 17; and what Godot says when one comma is taken out;
- the script as shipped: its four exported values, that its `_ready()` runs to its end, no `class_name`;
- for each of the four labellers: the 36 chosen samples, a ball on each in its label's colour, the printed line with their consent; for *you*, nothing chosen and a bare floor; a value saved in a scene winning over the script's line;
- the vote, for four labellers and `k` of 1, 3 and 5: all 640 cells against the same vote written another way in `verify.gd`, label and share;
- the floor: the plane, the image, the material, every pixel's colour; that `paint_field()` hands the image to the texture;
- the lesson's planted fault, made by taking that one line out of the shipped script: the image is still painted, `painted 640 cells` is still printed, and Godot logs nothing;
- `wrong()` against the vote written another way, for four labellers and four values of `k`; which two samples one person's field is wrong about;
- the line: that it is the same line when trained twice, that it answers by side, its mistakes after 99 to 102 rounds for each labeller; XOR, by the trained line and by 360 directions and 61 offsets tried one by one; what a failed `assert` says, and that `_process()` then stays silent;
- the error: its value in the middle and at the walker's start against the sum written out, `walk_down()` step by step, the error floor's colours;
- the scene: 180 frames with no error and no warning; the readout; the walker's autopilot across the boundary and through a ball;
- your own labels: the two actions pressed from the script, the sample each adds, the saved file read back, the next start finding it;
- the rule at *the error*: the walker sent downhill by the field, where it stops, the readout there, the line laid on the floor;
- the guest: nothing named outside its folder, no `class_name`, its three files, its box, its two tests, its vote against the kit's on all 640 cells, a marble on its slab, a walker stepping onto it and told its label on both halves.

With a window, once: 129 of 129. The texture read back held the image's 640 pixels, and with the fault planted it was black on all 640.

By `sheet.gd`, with a window, in the plain studio of `sheet_tools.gd`, and each picture looked at: `sheet.png` (1292 by 536: the four labellers by three neighbours and by a line, from 8.6 m above), `k.png` (one person's field with 1, 3, 5 and 9 neighbours), `process.png` (six steps). Two runs gave the same three pictures and the same `sheet.json`, byte for byte. The stills are 960 by 720, made on an NVIDIA GeForce RTX 3070 with the Compatibility renderer.

Every code block of the lesson was applied in page order to an empty script and the states the page says to run were run, 19 runs in all; every quoted output was in what Godot printed, and the last state equals `learning_body.gd` byte for byte. The two things under *Try* were run as well.

Faults planted one at a time in scratch copies, each of which made `verify.gd` fail (the number of failed checks in brackets): `paint_field()` without `texture.update(image)` (2); one comma out of `samples.json` (1, and the run stops there); the `assert` turned round (2, and the run stops); `k` left at 1 (3); `labelled_by` left at 2 (1); `rule` left at 2 (1); `_process()` without its guard (1); the vote's list not sorted (43); `says()` never asking the line (23); `wrong()` counting the right answers (26); `_ready()` not training the line (2); `xor_wrong()` not putting the samples back (1); the texture filter left out (1); the cell's middle without its half (2); `walk_down()` stepping uphill (4); a new sample labelled as the builder's (9); consent not written (2); the file not written (6); the saved file not read at the next start (2); a line indented with spaces (2); a guest that uses `supplied/look.gd` (1); a guest with a `class_name` (1); a guest 1.92 m wide (1); a guest with no collider (2); a guest voting with another `k` (3); a `.uid` file left in the folder (1); a `my_samples.json` left in the kit (1); another main scene in `project.godot` (1).

The room test, once, in a scratch copy of `../my-room/` with this guest's folder copied in and its line added (`room_trial.json`): the room's `guest_trial.gd` passed 8 of 8; the guest stood at place 2; the room ran 180 frames with no error; the walker reached the aisle and then arrived on the guest, 0.08 m from the middle of the place with its feet at 0.10 m. A second run with the guest's `samples.json` replaced by a file holding two labels pressed by a script, and `trained_on` set to `"you"`, passed the same 8.

## What was not checked

- **No person labelled anything, and no class exists here.** See above. The lesson's passage *Your own labels* was run by pressing the two actions from a script, once each.
- **No headset**, and no hand on the keys: every walk is the walker's autopilot.
- **The editor's windows** were not watched: the Inspector, the Output panel, the Debugger panel, opening a JSON file in the script editor. The two error messages under *Try* were read from runs started in a terminal; what the editor's debugger does with them was not seen.
- **A release build.** `assert()` was only run in the editor's kind of build. The export preset is the base's and no export was made.
- **The AI assistant prompt** under *What the field owes* was not run.
- **"Most particular".** The outline's claim that one's own labels draw the most particular map has no measure here.
- At its exit `sheet.gd` logs two lines, `ERROR: Texture with GL ID of 24: leaked 349524 bytes`, after `sheet.json` is written; its exit code is 0. The base's own `sheet.gd` logs the same two lines in a scratch copy. Not explained.
