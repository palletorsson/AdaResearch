# Sound — the swing heard

A study kit of the Godot course: chapter 27. A small Godot 4.6 project in which a chord is computed, not recorded: two tones written sample by sample into one second of 16-bit sound, played from a place in the room while a body stands in its reach, and drawn as a figure of beads from the same two sines. The lesson is [TUTORIAL.md](TUTORIAL.md).

## Open it

In the Project Manager of Godot 4.6 choose **Import** and open this folder's `project.godot`. Press Play (F5): `chord.tscn` is the main scene. You look through the walker's eyes at two chords. W, A, S and D walk, C changes the camera. Walk into a ring and that chord sounds, if your computer's sound is on.

## What is in the folder

Built in this chapter:

- `chord.gd`: the learner's script, 112 lines. The lesson takes it apart and builds it again in nine blocks.
- `chord.tscn`: the main scene. It inherits `supplied/base.tscn` and holds `Chord` (runs `chord.gd`, ratio 3:2), `Neighbour` (the guest, ratio 2:1, member 1) and `Walker` (the supplied walker, looking through its eyes).
- `guests/sound/sound.tscn`, `sound.gd`: the body the kit hands to the room. `sound.gd` is `chord.gd` with the look's colours written out, because a guest names nothing outside its folder. It declares no `class_name`.
- `verify.gd`, `sheet.gd`: the checks and the stills.
- `TUTORIAL.md`, `FIELD_NOTE.md`, this file.
- `sheet.png`, `process.png`, `scene.png`, `sheet.json`, `verification.json`: what the two scripts wrote.

Supplied, the same in every kit and unchanged here: everything in `supplied/` (the base scene and its look, the walker, the marble, the check and still tools, `check_guest.gd`), `export_presets.cfg`, `.gitignore`. Nothing from another chapter is borrowed as a file: the sine, the `Area3D` and the `MultiMesh` return as ideas.

No sound file is in the kit. Every sound is computed when the scene starts.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 52 checks and writes `verification.json`. Its exit code is the number of checks that failed. It needs no import step. It takes about 30 seconds: it listens to Godot's mixer in real time, so `--fixed-fps` does not shorten it.

`sheet.gd` needs a window, so it is run without `--headless`. It writes `sheet.png`, `process.png`, `scene.png`, `sheet.json` and the stills in `stills/`, and closes its window by itself after about eight seconds. For about a second, while the strip's walker stands in two reaches, two chords sound; add `--audio-driver Dummy` to keep it silent, as we did.

The room test, once, in a scratch copy of `../my-room/` with `guests/sound/` copied into its `guests/` and its line added to `GUESTS`:

```
godot --headless --path . --xr-mode off --script res://guest_trial.gd -- sound
```

## How a sound is checked without ears

Nobody listened. `verify.gd` knows two things about a sound. The numbers in the buffer: it decodes the samples and compares them with the two sines. And what reached Godot's mixer: an `AudioEffectCapture` on the Master bus keeps the mixed samples, and from them come the loudest level in dB and, by a Goertzel filter, how much of each tone (256, 360, 384, 512 Hz) is in the mix. Headless Godot mixes with its Dummy driver, so nothing reaches a loudspeaker and the mixer can still be read.

Headless Godot draws no frames and reads no bead back from a `MultiMesh` (bead 100 reads back as (0, 0, 0)). So the figure is checked twice: by its rule in `verify.gd`, and by reading every bead back in `sheet.gd`, with a window, where the bead farthest from the rule was 0 m from it for all four ratios.

## What was and was not checked

Checked, headless, by `verify.gd` (52 of 52 on a fresh copy with no `.godot/`): the project; the 15 files of `supplied/` and tabs in every script; one second of one tone as bytes; `render()` sample for sample; the stream's format, rate, length and loop; that the loop closes for the four ratios on 256 Hz and clicks on 261.63 Hz; the planted bug (every sample 0, `playing` true, the bus at −200 dB, no error and no warning in a run without the debugger); the repaired tone and the chord in the mixer; the sum that wraps without the two halves; a tone of 43,844 Hz against 256 Hz, and one of 22,050 Hz; the four figures by their rule; `chord.tscn` running 180 frames with no error; the walker by keys pressed from the script and by its autopilot through both reaches, with the mixer read at each stop; C moving the ears; the marble on the box and through the figure; who enters the reach at the start; the voice from 1, 2 and 4 m and from the side; the guest alone, its folder, its script against `chord.gd`; and the lesson's room task done to a copy of the guest's script.

Checked, with a window, by `sheet.gd`, and each picture looked at: `sheet.png` (the four ratios from the side and from above), `process.png` (six steps), `scene.png`, and every number of `sheet.json`. The stills measured 960 × 720 on an NVIDIA GeForce RTX 3070 with the Compatibility renderer.

Checked by hand in scratch copies: every code block of `TUTORIAL.md`, extracted and applied in page order, and each state the lesson runs was run; the last state equals `chord.gd` byte for byte. Fourteen faults were planted one at a time and `verify.gd` failed on each: the unscaled wave, `int(wave)`, the sum without its two halves, `low_hz` at 261.63, the `if` left out, `unit_size` left at 10, the loop left out, one bead in eight, the figure in BODY, a plain `AudioStreamPlayer`, the ratio without its colon, and a guest with a `class_name`, with `look.gd`, with another rule. The room test passed 8 of 8 with the guest at place 2: the walker was stopped by the box, 0.45 m from the middle of the place, and the room printed `Sound sounds`; it passed again after the lesson's room task was done to the copy in the room.

The kit was built in two sessions. The first was cut off before the field note; the second ran all of the above again, on a fresh copy, and `sheet.gd` wrote the same `sheet.json` and the same three pictures byte for byte. One thing is the first session's alone: the warning of the planted bug, and the absence of one on the repaired line, were read from runs of the main scene started with `-d`. The second session did not run with the debugger.

One number moves between runs: the lowest level of the swell in the room task (−17.4, −22.2, −22.2 and −15.6 dB over four runs), because six short listenings catch a swell where it happens to be. The lesson quotes the run that wrote `verification.json`.

Not checked: no ear heard anything. No loudspeaker was used; every level is the mixer's. Nothing was run in a headset, and no XR node is in the kit. The walker was walked by its autopilot and by actions pressed from the script, not by a hand on a keyboard. The editor's windows were not watched: the Inspector, the Output panel and the Debugger's Errors tab are described from what a run with `-d` printed. `int(wave)` was run without the debugger only: every sample 0 and no error; that it gives no warning is said of the repaired line, which also uses `int()`. With the ratio written without its colon the lesson says the editor pauses on line 20; our run, without the editor, logged the error and went on. `AudioStreamGenerator` is named in the lesson and was not run. No learner has used any of it.
