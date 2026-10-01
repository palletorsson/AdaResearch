# Shader skin — study kit

The kit of the chapter *The pixel's colour circle: shaders*. One member of the sphere family gets a skin that is computed: a spatial shader that draws stripes from the body's UV, clouds them with noise asked for every pixel, and lights the body's edge from the angle between its surface and the eye. A script hands the shader its colours and numbers as uniforms. The lesson is [TUTORIAL.md](TUTORIAL.md); the kit's own field note is [FIELD_NOTE.md](FIELD_NOTE.md).

## Open it

In the Project Manager of Godot 4.6 choose **Import** and open this folder's `project.godot`. Press Play (F5): `shader_skin.tscn` is the main scene. Nothing has to be imported first: no script here declares a `class_name`.

| key | what it does |
| --- | --- |
| Space | the next rim exponent of 0.5, 1, 3, 8 |
| W A S D, or the arrows | walk |
| V, or the right mouse button, held | move the mouse to look |
| C | your eyes or the fixed camera |
| J | jump |

## What is in the folder

Built in the lesson, by the learner:

- `skin.gdshader`: the skin. Eight uniforms, three functions for noise, a `fragment()` of six lines.
- `shader_skin.gd`: builds the member, puts the shader on it, hands over three colours of the palette and two numbers, steps the exponent on Space.

Supplied with this kit:

- `shader_skin.tscn`: the scene. It inherits `supplied/base.tscn` and adds `Skin` (runs `shader_skin.gd`), `Walker` and `Readout`.
- `parts/member.gd`: borrowed from Families. `make(segments)` returns one sphere of the family: 1 m across, standing on the ground, with a sphere collider and no material, turned so that the seam of its UV is at the back.
- `parts/readout.gd`: the words in the air. It reads `rim_power` from `Skin` and changes nothing.
- `steps/`: the shader as it is after each step of the lesson, `1_uv` to `5_picture`. The last state is `skin.gdshader` itself. `sheet.gd` builds the process strip from these files, and the lesson's code blocks were checked against them.
- `guests/shader-skin/`: the body this kit hands to the room: `shader-skin.tscn`, `shader-skin.gd` and its own copy of `skin.gdshader`. It names nothing outside its folder and declares no `class_name`.
- `supplied/`: the base's fifteen files, unchanged. See `../kit-base/README.md` for every signature.
- `verify.gd`, `sheet.gd`, and what they wrote: `verification.json`, `sheet.json`, `sheet.png`, `process.png`, `place.png`.

The colours are the palette's: the skin is BODY, its stripes SHADE, its rim SECOND, handed to the shader by the script. Two colours on the page are not the palette's and are named there: the red and green of the step that draws UV as a colour, and the white of the planted bug.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 48 checks and writes `verification.json`; its exit code is the number of checks that failed. It takes about 13 seconds, because the walker walks in real time, and under a second with `--fixed-fps 60` added, with the same result.

`sheet.gd` needs a window, so it is run without `--headless`. It writes `sheet.png`, `process.png`, `place.png`, `sheet.json` and the single stills in `stills/`, and closes its window by itself after about 20 seconds. Run four times, it wrote the three pictures the same to the byte each time, before and after the base's look got its filter: every still is made in the sheet's plain studio. Two numbers in `sheet.json` depend on the clock and moved a little: how long the CPU's noise took to make (3.8 to 5.2 ms) and on how much two stills a second apart differ while the stripes crawl (8.47% to 8.50%).

## What was checked

By `verify.gd`, headless, on a fresh copy with no `.godot/` (48 of 48): the project and the Space key; the fifteen supplied files; no `class_name`; tabs and LF in every script and shader; that the shader language accepts `skin.gdshader` and the five states in `steps/`, with the uniforms each declares; the borrowed member; the scene running 180 frames with no error and no warning; the three colours and two numbers read back from the material; that no sampler is left unbound; Space stepping the exponent; four bodies made at the four exponents; the three faults of the lesson, each made and seen (a `6` for `6.0` refused with its message, a sampler nobody bound reading back null in silence, a misspelt uniform name kept in silence); the walker round the body and stopped by it from four sides; the marble on its top with the grain at 0 and at 1; the guest standing on its own.

A headless run draws no frame, so no check there looks at a pixel. It does read the shader: Godot 4.6 logs the same `SHADER ERROR` without a graphics card.

By `sheet.gd`, with a window, each picture looked at: the four exponents on our skin and on a dark body, from 2 m and from 5 m, every pair; how much of the body the rim changes and where it begins; the left half's brightness against the right; exponents 3 to 7 against 8; the eight stills of the strip; the planted bug (the body 100.00% white, nothing logged); two colours nobody set; the refused shader (the body drawn grey); the body through the walker's eyes from four sides; the seam from behind and from in front; two stills a second apart with the stripes crawling and held; a rim in the sky's colour. The stills are 960 by 720, made on an NVIDIA GeForce RTX 3070 with the Compatibility renderer.

In scratch copies: every code block of the lesson applied in page order, the scene run after each step, the last state equal to `shader_skin.gd` and `skin.gdshader` byte for byte, and the error block equal to what a windowed run logged. Nine faults planted one at a time each failed `verify.gd`: a whole number in the shader, a sampler nobody bound, colours nobody set, a misspelt uniform name, the exponent not handed over, a guest that loads the kit's shader, a member without a collider, a guest with a `class_name`, spaces for tabs. The guest was copied into a copy of `../my-room/` and passed the room's `guest_trial.gd` (8 of 8): place 2, 180 frames with no error, the walker blocked 0.80 m from the middle of the place. The room task was done in a second copy: the rim in the sky's colour, and the skin on the example guest; both passed the room's trial, and one still of that room was looked at. The base and the room got the look's filter while this kit was being built; the checks, the sheet and both room trials were run again after it, with the same results.

## What was not checked

Nothing was run in a headset. The walker was walked by its autopilot and by actions pressed from a script, not by a hand on the keys. The editor's windows, the Shader Editor and the Inspector's sliders among them, were not watched. No person looked at the stills to say which two look alike: every "alike" is a count of pixels. Everything was measured on one machine and one graphics card; `hash()` depends on how a card computes a sine of a large number, and another card may draw other clouds. No learner has used any of it.
