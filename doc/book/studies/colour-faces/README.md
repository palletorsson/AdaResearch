# Colour faces — the kit of "A colour has many faces"

A small Godot 4.6 project for chapter 29 of the course. It builds a wall of nine steps between two opposite colours, four times, in four mixing spaces: RGB, HSV, linear light and OKLab. A lamp carried by the walker changes what the painted steps look like, and a ray repaints them. The lesson is [TUTORIAL.md](TUTORIAL.md); the kit's own field note is [FIELD_NOTE.md](FIELD_NOTE.md).

The kit starts from `kit-base` and holds nothing of another chapter.

## Open it

In the Project Manager of Godot 4.6 choose **Import** and open this folder's `project.godot`. Press Play (F5): `faces.tscn` is the main scene. The editor's own view shows a white floor under Godot's preview light; the look is put on by a script when the scene runs.

| key | what it does |
| --- | --- |
| A, D (or the arrows) | walk along the wall; W and S walk towards it and away |
| C | change between the fixed camera and the walker's eyes |
| Space | the lamp's next colour: white, the wall's first colour, its second |
| M | paint: the step the lamp points at goes half way to the lamp's colour |
| right mouse button or V, held | look around |

## What is in the folder

Ours, built in the lesson:

- `faces.tscn`: the scene. It inherits `supplied/base.tscn` and adds the supplied walker at (−2, 0, 1.6).
- `faces.gd`: stands one wall for each name in `spaces`, makes the lamp (a `SpotLight3D`) and its ray (a `RayCast3D`), moves the lamp with the walker, hears Space and M.
- `wall.gd`: the class. Exported fields `space`, `steps`, `size`, `first`, `second`; `mix(t)` with one branch for each space; `build()`. It has no `class_name`: use it by `preload("res://wall.gd")`.

Supplied here, lent:

- `oklab.gd`: OKLab. `Oklab.mix(a, b, t)` returns the colour `t` of the way from `a` to `b` on a straight line in OKLab. Also `from_srgb()`, `to_srgb()`, `cut()`, `apart()`. The numbers are Björn Ottosson's (2020).
- `guests/colour-faces/`: the body handed to the room. `colour-faces.tscn` with `colour_faces.gd` is a wall of steps 1.44 m wide, 1 m high and 0.2 m deep, with a collider. Its colours come from `palette.tres`, a Resource whose script is `palette.gd`: `first`, `second`, `space`, `steps`, `because`, and `mix(t)`. The folder names nothing outside itself and declares no `class_name`; OKLab is written out again inside `palette.gd` for that reason.
- `sheet.gd`, `verify.gd`: the stills and the checks.

Supplied by the base, unchanged: everything in `supplied/` (the base scene, the look, the walker, the marble, the tools).

Colours. Colour is this chapter's subject, so the kit writes colours of its own. They are: the complement of BODY, `#3900c2`, which is computed (`Look.BODY.inverted()`) and typed nowhere in the lesson; every step between the two ends; red and cyan, for the control row of the sheet; and the lamp's white. Everything else is on the look's palette. The guest writes `c6ff3d`, `3900c2`, `ffffff` and `0d0620` out, because a guest cannot use `look.gd`.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 63 checks and writes `verification.json`. Its exit code is the number of checks that failed. It needs no import step. It takes about ten seconds, because the walker walks in real time, and about one with `--fixed-fps 60` added, with the same result.

`sheet.gd` needs a window, so it is run without `--headless`. It writes `sheet.png`, `lamp.png`, `process.png`, `sheet.json` and the single stills in `stills/`, and closes its window by itself after about six seconds. Every still is made in the sheet's plain studio, not in the running scene, so the look's filter (the gradient sky, the tinted light) is in none of the measurements. For the lamp, `faces.gd` itself stands in the studio with a marker node named `Walker` where the walker would be.

## What was and was not checked

Checked, headless, by `verify.gd` (63 of 63 on a fresh copy with no `.godot/`, with and without `--fixed-fps 60`): the project and its supplied files; `lerp()` and `lerpf()` on numbers; the weight from a whole-number division (eight zeros and a one); `var h := lerp(a, b, t)` refused by the parser, with the message the lesson quotes; the pair and its grey middle; the planted bug (hue lerped plainly from SKY to THIRD puts 7 of 9 steps between yellow and violet) and its repair; that the hue difference of the two complements is 0.50000004, so that the wrap fires and the HSV wall goes by red; the wall class in all four spaces, its ends, its nine different steps, its four middles and its least saturated step; linear light with and without the way back; red and cyan as a control pair; the complement taken in linear light; how even each wall is by two rulers; an unknown space (nine error lines, nine black steps; in the scene, with `rgb, hsl`, ten lines and `hsl: the middle is 000000`); a wall asked for one step; OKLab against published values, there and back; the scene running 180 frames with no error; the lamp following the walker on the autopilot and on the key D; Space; M and what it prints; the walker stopped by the wall; a ray that meets nothing; a marble resting on the wall at 1.90 m; the guest standing alone, its size, its palette, its `mix()` against the wall's for 4 pairs, 4 spaces and 33 weights, the row of eight squares the room task makes from pink and orange in HSV, a walker stopped by it and a marble resting on it.

Checked, with a window, by `sheet.gd`, and each picture looked at: `sheet.png` (1292 × 510, four walls for each of two pairs), `lamp.png` (1292 × 266), `process.png` (2588 × 266, eight steps). It also measures how two lights add on a grey wall: in this renderer as screen numbers (244.8 of 255 measured, 244.3 by adding numbers, 211.2 by adding light). Two runs gave the same three pictures and the same `sheet.json`, byte for byte. Stills are 960 × 720, made on an NVIDIA GeForce RTX 3070 with the Compatibility renderer.

Every code block of the lesson was extracted and run in page order: nine states were run headless for 60 frames each, the 22 lines of output the page quotes were found in the logs, and the last state equals `faces.gd` and `wall.gd` byte for byte. Each state was also run with a window and its still looked at. The page's four variations (the whole-number division, plain `lerp()` with `:=`, the space `hsl`, linear light without the way back) were run one by one, and each is now a check in `verify.gd` as well.

Negative tests, in scratch copies, one fault at a time: sixteen planted faults each made `verify.gd` fail. In `wall.gd`: the hue lerped with no wrap; `t` cut to a whole number; an unknown space falling back to RGB in silence; linear light with no way back; a wall of one step allowed; steps with no body. In `faces.gd`: the lamp never moved; the lamp never changing colour; the ray painting the lamp's colour outright. In the guest: a `preload` of `supplied/look.gd`; a `class_name`; its `mix()` without the wrap; a wall 1.8 m wide; no collider; a script indented with spaces. In `oklab.gd`: one digit changed. A seventeenth was not caught: `faces.gd` first told the ray to ignore the walker with `add_exception()`, and `verify.gd` passed without that line, because a ray that starts inside a body does not report that body here. The line was taken out.

The room: in a scratch copy of `my-room`, with the guest's folder copied in and the lesson's line added to `GUESTS`, `guest_trial.gd` passed 8 of 8: the room ran 180 frames with no error, the guest stood at place 2, the walker reached the aisle and was stopped by the guest 0.40 m from the middle of the place. With the lesson's two lines added to `room.gd`, the 40 squares ran from the palette's first colour to its second in each row, with no error, and again after `palette.tres` was edited as text.

The kit was built in two sessions on one day. The first was cut off before it reported; the second ran everything in this section again from fresh copies (the checks, the sheet, the lesson's blocks and variations, the sixteen faults, the room) and looked at every picture. The sheet's three pictures and `sheet.json` came out byte for byte as the first session left them.

Not checked. Nothing was run in a headset, and nobody held the keys: the walker was walked by its autopilot and by actions pressed from the script. No eye was asked which walls look alike: every "alike" is a distance between pixels, by two rulers, and OKLab's ruler is the one the fourth wall was built with. The editor's windows were not watched: the Inspector on `palette.tres` is described, not seen. The look of the running scene was looked at in stills and not measured. Everything was rendered on one machine. At its end the windowed run prints two lines, `ERROR: Texture with GL ID of … leaked 349524 bytes`, and exits with code 0; they began when the look got its gradient sky, and we did not find out which texture it is. The lesson's history, the seventeen observers of 1931 and the Shirley cards, is from memory of the literature and was not checked against a source in this build. The halls were read from files and not walked; the essay of Color_Walls was being rewritten on the day of the build and is quoted as it stood that evening.
