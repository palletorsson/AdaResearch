# Genome — genes as files

A study kit for chapter 17 of the Godot course, *Genes as files: a family saved, a body recalled*. A creature's five genes are a custom `Resource`. A builder turns the resource into a body of primitive meshes. A chosen specimen is saved as a `.tres` file in `user://` and comes back after a restart. The lesson is [TUTORIAL.md](TUTORIAL.md); the kit's own field note is [FIELD_NOTE.md](FIELD_NOTE.md).

This is a small Godot 4.6 project of its own. In the Project Manager choose **Import**, open this folder's `project.godot`, and press Play (F5): `cabinet.tscn` is the main scene.

## What you see

Five lime creatures in a row on a dark sheet, over the plates 0, 2, 4, 6 and 12: one genome copied five times, with the gene `limb_count` set to each value. A sixth creature on a dark square marked *specimen*: the genome recalled from `user://specimen.tres`, or a new one if there is no file yet. A cyan walker.

| key | what it does |
| --- | --- |
| W A S D, or the arrows | walk |
| Space | keep the creature nearest to the walker: its genome is saved to the file and a copy of it stands on the square |
| the right mouse button, or V, held | look around |
| J | jump |
| C | change between the walker's eyes and the fixed camera |

The Output panel prints where the file is. On Windows it is `C:/Users/<you>/AppData/Roaming/Godot/app_userdata/Genome/specimen.tres`. Delete that file to start again from a new genome.

## What is in the folder

Built in the lesson (the download holds the finished versions):

- `guests/genome/genes.gd`: the genome. A `Resource` with five exported genes (`segments`, `limb_count`, `limb_angle`, `colour`, `body_seed`) and `mutate(gene, value)`, which sets a gene by its name and sends the resource's `changed` signal.
- `guests/genome/creature.gd`: the builder, on the first node of `genome.tscn`. It listens to its genome and builds the body again whenever the genome changes. Handed no genome, it recalls `specimen.tres` from its own folder.
- `cabinet.gd`: recalls a parent from the file, breeds the row from copies of it, keeps the one the walker chooses.

Supplied with this kit, not typed:

- `cabinet.tscn`: inherits `supplied/base.tscn`; adds `Sheet` (the supplied `sweep_sheet.gd` with a paper for five), `Place` and `Walker`.
- `place.gd`: the dark square. No contract: it paints itself in SHADE and writes one word.
- `guests/genome/genome.tscn`: a `Node3D` named `Creature` with `Parts`, where the builder puts what it builds, and `Trunk`, a `StaticBody3D` with a cylinder of 0.2 m radius and 0.8 m height.
- `guests/genome/specimen.tres`: the kit's own specimen, six limbs. Seven lines of text.
- `supplied/`: the base's 15 files, byte for byte. See `../kit-base/README.md` for every signature.

`guests/genome/` is the guest: the one body this kit hands to the room. It names nothing outside its folder and declares no `class_name`. The genome and the builder live in that folder because a saved genome names its script by path, and this is the path that exists in the kit and in the room alike.

There is no `class_name` anywhere in the kit. The course outline asked for `class_name Genome`; the scripts are used by `preload()` instead, so that a fresh copy runs with no import step and the guest can stand in a room beside other guests. The gene the outline called `seed` is `body_seed`: a variable named `seed` gets a warning from Godot, because `seed()` is one of its functions.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 70 checks and writes `verification.json`. Its exit code is the number of checks that failed. It needs no import. It took 15 seconds here, because the walker walks in real time, and about one second with `--fixed-fps 60` added, with the same result. It starts a second Godot on the project to check the restart. If you have a `user://specimen.tres` it is put aside while the checks run and put back at the end. Where `../kit-base/` stands beside this folder, as it does in the course, `supplied/` is compared with the base's byte for byte; in a copy that stands alone only the 15 names are checked.

`sheet.gd` needs a window, so it is run without `--headless`; it closes its window by itself after about twenty seconds. It writes `sheet.png`, `process.png`, `sheet.json` and 54 stills in `stills/`. Its last two printed lines are `ERROR: Texture with GL ID of …: leaked 349524 bytes.` The base's own `sheet.gd` prints the same two as it quits; the pictures and the numbers are whole.

## What was and was not checked

Checked, headless, by `verify.gd`, on a fresh copy with no `.godot/` (70 of 70, with and without `--fixed-fps 60`), and in this folder: the project, its nine actions and that `supplied/` is the base's; no `class_name`, tabs in every script; the five genes, their types and defaults; `mutate()` and its one `changed`; what `set()` does with a wrong name, a decimal number and a text; the scene; the body built from a new genome, its paint, that it stands on the ground and fits a place at its widest; the parts for 0, 2, 4, 6 and 12 limbs; the limbs' directions and lift; the seed; 1 and 5 segments; a genome asking for −3 limbs; what `save()` returns and writes, line by line; that a default gene is not written; `load()`, that it hands out one object for one path, and that it goes on doing so after another save; a file with an unknown gene, with a text or a decimal number for a whole one, with a script that is not there, with a script whose default differs; a missing file, and what a `recall()` without `exists()` prints; a save as `.txt`; the planted fault (five bodies, one genome, twelve limbs each) and Godot's silence about it; the repair; `duplicate()` against `duplicate(true)`; the collision shape shared by five instances; the cabinet running 180 frames, its printed lines, the row, the specimen, the exported axis; the walker walked to the creature of six and Space pressed; the file; the specimen as a copy; the walker stopped by the trunk and not by a limb; the marble on the trunk and through a limb; that no gene moves the trunk's cylinder; the row saved as five files; a second Godot process reading the file; the cabinet built again; a row along `limb_angle`; a classmate's file written by hand; the guest's folder, its file, and the guest standing alone.

Checked, with a window, by `sheet.gd`, and each picture looked at: `sheet.png` (1616 × 510: the five creatures from above and from the side) and `process.png` (1616 × 266: five steps, in the sheet's plain studio). `sheet.json` holds every pair of the five from both standpoints and a series of every count from 0 to 12. The stills are 960 × 720, on an NVIDIA GeForce RTX 3070 with the Compatibility renderer. The pair numbers were the same in every run we made.

Every code block of `TUTORIAL.md` was applied in page order to a scratch copy, the study was run after each step, and what Godot printed was compared with the page; the last state equals the three shipped scripts byte for byte.

Negative tests, in scratch copies, one fault at a time; each of the eleven made `verify.gd` fail: the row handed the parent itself (12 checks failed); `recall()` without `exists()` (7); an axis the genome does not have (11); the specimen not copied (1); `mutate()` without `emit_changed()` (10); a creature that does not listen (8); a creature that does not recall its own file (1); the guest's file naming a script outside its folder (3); the guest using `supplied/look.gd` (1); a `class_name` in `genes.gd` (4); the file saved under a name ending in `.txt` (6).

The room: in a scratch copy of `../my-room/`, with `guests/genome/` copied in and its line added to `GUESTS`, `guest_trial.gd` passed 8 of 8. The creature stood at place 2, and the walker, sent at it, was stopped 0.50 m from the middle of the place. In a second scratch run with a window the guest had six limbs and nine parts.

While this kit was being built the base's look was given a second sky: three files of `supplied/` were replaced here from the base (`look.gd`, `base_look.gd`, `sheet_tools.gd`), the sheet was made again, and its numbers did not change.

A second pass, the same day, ran all of it again from this folder as it is shipped: the checks on a fresh copy, the eleven faults, the lesson's code blocks in page order, the sheet, and the room trial. Every number came out as before. One thing was changed. At 1280 by 720 the fixed camera cut the last letter of the word *specimen* on the place, so `place.gd` now writes the word 22 cm left of the square's middle. `process.png` was made again; its measurements did not change.

Not checked. Nothing here was run in a headset, and nothing was picked up by a hand: "carry" is a key, and "leave the room" is a restart. The walker was walked by its autopilot and Space was pressed from the script, not by a hand on a keyboard. The editor's windows were not watched: Open User Data Folder, the Inspector's view of a `.tres`, the Output panel. No person looked at the stills to say which two creatures look alike: every "alike" here is a count of pixels. The kit was not exported, so "an exported game cannot write to `res://`" is Godot's documentation and not our run. A `.tres` from a stranger with a script inside was not tried. No learner has used any of it.
