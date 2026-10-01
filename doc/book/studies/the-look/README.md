# The look — a sky, a light, a palette

A study kit of the Godot course: lesson L00, a workshop stop that sits right after Point One. It is a small Godot 4.6 project in which a learner dresses a bare scene, a floor, a box and a sphere, step by step: a sky, light with no sun, a sun, a colour for the ground and for each body, and a palette of ten names by role. That is the plain look, the one every sheet of the course is photographed in. Then the learner lays the filter over it that a running scene wears: a sky with a top and a horizon, a second light, a tinted ambient light, a shadow blur, a little saturation and contrast. The script they end with builds what `supplied/look.gd` and `supplied/base_look.gd` give every later kit's scene, property for property and pixel for pixel. The lesson is [TUTORIAL.md](TUTORIAL.md); the kit's own field note is [FIELD_NOTE.md](FIELD_NOTE.md).

Open it by importing `project.godot` in the Project Manager and pressing Play: `the_look.tscn` is the main scene. `place.tscn` is the same scene with a walker and a marble in it; open it and press F6.

## What is in the folder

Built in this lesson:

- `look.gd`: the learner's script, 71 lines, one function. The download holds the finished version; the lesson takes it apart and builds it again.
- `guests/the-look/`: the body this kit hands to the room. `the-look.tscn` is the box and the sphere with their colliders; `the-look.gd` paints them `BODY` and `SECOND`, the two colours written out. It names nothing outside its folder and declares no `class_name`.

Supplied by this kit:

- `the_look.tscn`: the scene. A floor of 8 m by 5 m, a box of 0.6 m, a sphere 0.6 m across, each with a collider, and a camera. It holds no light, no environment, no material and no colour. Its camera looks down 25.2 degrees: the top edge of its picture is 1.2 degrees under the horizon, so it shows the ground beyond the floor and no sky.
- `place.tscn`, `place.gd`: the place. `the_look.tscn` with `supplied/walker.tscn` and `supplied/marble.tscn`. One contract: the action `drop` (M) drops the marble one metre in front of the walker, from above its head.
- `steps/`: the fifteen states `look.gd` goes through on the page, `0_engine_grey.gd` to `14_saturation_contrast.gd`, made from TUTORIAL.md by its code blocks. `8_palette.gd` is the plain look; `14_saturation_contrast.gd` is `look.gd`. `sheet.gd` photographs them and `verify.gd` checks what each built. The editor does not show the folder (it has a `.gdignore`); a learner does not need it.
- `evidence/`: three records of runs that need another project or another renderer. See *The room* and *The shadow blur*, below.
- `verify.gd`, `sheet.gd`, and their results `verification.json`, `sheet.json`, `sheet.png`, `process.png`.

From the kit base, unchanged: `supplied/` (15 files, compared with `diff -r` against `../kit-base/supplied/`), `.gitignore`, `export_presets.cfg`. `project.godot` is the base's with the name, the main scene and one more change: it sets no clear colour, so that the first run of the lesson shows the engine's own grey.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 67 checks and writes `verification.json`. Its exit code is the number of checks that failed. It needs no import step. A fresh copy with no `.godot/` passed 67 of 67, in about 32 seconds, because the walker walks in real time, and in about one second with `--fixed-fps 60` added, with the same result. It passed again after an import.

`sheet.gd` needs a window, so it is run without `--headless`; run headless it says so and exits 1. It takes about 30 seconds and closes its window by itself. It writes `sheet.png` (1292 × 536), `process.png` (1616 × 806), `sheet.json` and the stills in `stills/`.

## Two looks, and which one is measured

- **The plain look** is the script at its palette step: a flat `SKY`, a white ambient light of 0.25, one sun. It is `Look.studio_environment()` and `Look.sun()`, and it is what `supplied/sheet_tools.gd` photographs every kit's sheet in. `sheet.png`, the four pairs of the argument, is made in it, by running `steps/8_palette.gd` with two lines written again. The sheet is, byte for byte, the sheet this kit had before the filter was added to the lesson.
- **The finished look** is `look.gd`: the plain look with the filter. It is what a learner sees when the scene runs, and what `place.tscn` and the last six tiles of `process.png` show. The strip's tiles are stills of the scene as it runs, because its steps change the scene's own sky and light.

The four pairs were also measured once under the filter (`sheet.json`, "pairs under the filter"), to show why the sheet is plain: there the grey box is seen whole (100%), where the plain look loses its shaded side (81.18%).

## What the lesson measures

All of it is in `sheet.json`, `verification.json` and `evidence/`; the lesson quotes nothing else.

- **The fifteen states**, one still each from the scene's own camera, with the colour of the picture's upper corner, its top edge, just above the floor's far edge, the floor in the sun and in a shadow, three faces of the box and two points of the sphere.
- **One line more, one line less**, on the plain look: the sky without `background_mode`; ambient light without its energy line; the turned sun without its shadow line; `sun.visible = false`; the same plain look asked of `supplied/look.gd` (our still, pixel for pixel); the sphere at three values of roughness.
- **The filter, line by line**: the finished look asked of `supplied/look.gd` (our still, pixel for pixel); the sky by degrees above the horizon, read by a level camera; the disc this sky draws for a light; the lines that change no pixel (`sky.background_color`, `gradient.sun_curve`, `gradient.ground_curve`, five values of `sun.shadow_blur`); the sky mirrored in the bodies, with and without `reflected_light_source` disabled; the second light at 0.5 and with the sun switched off, before and after it; saturation 2; and what was tried and left out: fog, glow, glow with bloom, and the Reinhard, filmic, ACES and AgX tonemaps.
- **The four pairs**: lime on violet, hot pink on violet, red on green, grey on grey, in the plain look and under the filter. For each: the box's pixels, how far they are from the bare ground as rendered and made grey, and the same with the sun switched off.
- **The place**, in the finished look: the marble in the sun and in the box's shadow, from above; the box through the walker's eyes from behind; the sky through the walker's eyes, level and looking up.

Three colours on the sheet are the kit's own and not the palette's, because the pair is the axis: a red `ff0000`, a green `009400` chosen to have the red's luminance, and the two greys `808080` and `4d4d4d`.

## The shadow blur

The base's look sets `sun.shadow_blur = 2.0` for "a softer shadow edge". In this project's renderer it draws nothing. `sheet.gd` runs `look.gd` with 0, 1, 2, 6 and 20: five stills with not one byte unlike, the shadow's edge 8 pixels wide in each. The same five values were run once in a scratch copy under Forward+ (`--rendering-method forward_plus`): there each differs from the still at 2, and the edge is 4, 13, 20, 60 and 134 pixels wide. Kept as `evidence/shadow_blur_two_renderers.json`. The lesson has the learner write the line, see that nothing changes, and keep it, so that the script equals the base's.

## The room

The guest was tried in a scratch copy of `../my-room/`, with its folder copied in and its line added to `GUESTS`:

```
godot --headless --path . --xr-mode off --script res://guest_trial.gd -- the-look
```

8 checks, 8 passed: the folder names nothing outside itself; it declares no `class_name`; the room ran 180 frames with no error; the guest stands at place 2 of 2; the walker reached the aisle in front of it ("arrived"); it walked at the guest and the walk ended "blocked", 0.54 m from the middle of the place, its feet at 0.00 m; no error to the end. The result is kept as `evidence/guest_trial.json`. The guest did not change when the lesson was extended; the trial was run again all the same, with the same result.

The lesson's room task, two roles changed in `room_look.gd` (`SKY` and `SHADE` exchanged), was run in the same copy with a window: no error, the sky read back `#0d0620` at the horizon and `#5a1fd6` overhead, a square `#ff2e93`, the edge of a number `#ff2e93`. Kept as `evidence/room_look_trial.json`. `verify.gd` reads the records; it does not run the room.

## What was and was not checked

Checked, headless, by `verify.gd` (67 checks): the project's name, main scene, renderer, that it sets no clear colour, and its nine actions; the 15 files of `supplied/`; no `class_name` anywhere and tabs in every script and every state; what Godot gives when nothing is said (a new `Environment`, `DirectionalLight3D` and `StandardMaterial3D`, and `Color("ff2e93")`); the scene undressed, and that its camera shows no sky; each of the fifteen states and what it built, among them the planted bug, a sun that travels along (0, 0, −1), and the sky whose ground nobody named, with Godot's `332b22` under it; that the last state is `look.gd` byte for byte; that the palette step is `studio_environment()` in all 101 stored properties and its sun `sun()` in 43; that `look.gd` names the supplied look's ten roles and the three colours of its filter with the same thirteen colours; that its environment is `environment()` in 124 stored properties, the sky and the sky's material among them, its sun the supplied one with the blur in 43, its second light `fill()` in 43, its materials `paint()` in 125; that `base.tscn`, dressed by `base_look.gd`, has that same environment and those two lights; the four pairs carried by two lines of the palette, the ground beyond the floor with them; the luminance of the red and the green; the switch's line; the place (180 frames, C, M, a walk round, a walk at the box, the walker and a marble where the box's shadow falls, a marble on and beside the top of the sphere); the guest; the three records in `evidence/`.

Checked, with a window, by `sheet.gd`, and each picture looked at: `sheet.png`, `process.png`, the stills of the fifteen states, of the switch, of the sky and its discs, of what was tried and left out, of the pairs made grey, and of the place.

Every code block of TUTORIAL.md was run in page order by a script kept in scratch: twenty-two changes to `look.gd`, each followed by a headless run of the project with no error, and the two changes to the room's files. The last state equals the shipped `look.gd` byte for byte, the fifteen named states equal the files in `steps/`, and the two output blocks on the page are what the runs printed.

Negative tests, in scratch copies, one fault at a time, 52 faults; each made `verify.gd` fail and the copy with no fault passed. The 21 of the plain look: the sun left unturned; the shadow line, the energy line, the ambient source line or the `background_mode` line left out; a body painted with a written colour and not its role; one material shared by two bodies; the switch's line left in; spaces for tabs; a palette value changed; a guest that uses `supplied/look.gd`, declares a `class_name` or has no collider; the planted bug repaired in `steps/`; a last state that is not `look.gd`; a clear colour in `project.godot`; the scene's box without a collider; a material in the scene file; a supplied file missing; the room trial's record missing; a misspelt name in `look.gd`. The 31 of the filter: the sky made and not switched on; the ground's colour or its horizon left unsaid; the `sky_curve`, `sun_angle_max`, `sun_curve` or old `background_color` line left out; `SKY_TOP` changed; the sky's top given `SKY`; no second light; a second light that casts shadows, is at 0.5, is unturned, is white, or is added before the sun; the ambient light left white or at 0.25; the `shadow_blur` line left out; the adjustment not switched on; saturation 2; the contrast line left out; the filmic tonemap, fog or glow left in; the palette step in `steps/` already tinted; the unsaid ground repaired in `steps/`; the second light or the blur missing from its state; the blur record missing, or saying a byte moved; a fourteenth name in `look.gd`.

Not checked: nothing was run in a headset. The walker was walked by its autopilot and by actions pressed from the script, not by a hand on a keyboard. The editor's windows were not watched: the Output panel, the FileSystem and Scene docks, F5 and F6, the editor's preview light and the Project Settings window are described from knowledge of the editor, and marked *(editor)* in the lesson. No eye was asked which box is hard to find, or whether the second light at 0.05 can be seen; the grey still is arithmetic and is not a test of colour vision. The filter was chosen by the builder of the kit base, by eye, from ten variants; this kit did not repeat that choice, it measured what each line does. The Forward+ run of the shadow blur was made once, in scratch, and is read from its record. Everything was measured on one machine, an NVIDIA GeForce RTX 3070. No learner has used it.

## Things that cost a run while building this

- **The base changed under the build, twice.** `supplied/look.gd` gained a filter while this kit was first being made, and the lesson then built only the plain look. The lesson was extended afterwards so that the learner builds the filter too.
- **This scene's camera cannot see the sky.** It looks down, and the top of its picture is under the horizon. So a gradient sky shows in it as the ground beyond the floor. With only the sky's top and horizon named, the area above the floor came out brown: `ProceduralSkyMaterial` has a ground half with Godot's own colours.
- **`shadow_blur` draws nothing in the Compatibility renderer.** See *The shadow blur*. `supplied/sheet_tools.gd` sets it back to 1.0 for the studio, which changes nothing either.
- **A sky draws a disc for every directional light**, in the light's colour and energy: a grey smudge for the sun at 0.28 and, in the finished look, a black one for the second light at 0.05. `sun_angle_max = 0` removes them; `sun_curve` then changes no pixel.
- **The sky is mirrored in the bodies.** With `BG_SKY` the top of the lime box went from `#cbff39` to `#ccff4e`; with `reflected_light_source` disabled it was `#cbff39` again.
- **Glow as it comes does almost nothing here, and the Reinhard tonemap nothing at all.** Glow moved no channel by more than 2 of 255; Reinhard, with its white at 1, gave the same still to the byte. The base's README says in one place that fog and glow washed the bodies out and in another that neither was tried; this kit ran both, on this scene, and reports what it saw.
- **One sheet run could not save `process.png`** (`Can't save PNG at path`), kept the old file, and still exited 0. The next run saved it. The cause was not found; look at the file's time after a run.
- **A scene with no environment is not grey.** Its bodies are black, `#000000`, under a grey background. The grey bodies appear only with an `Environment`, whose ambient light comes from its background unless told otherwise.
- **A marble's resting height depends on the drop.** Dropped from 0.6 m it rests with its middle at 0.090 m, from 1 m at 0.098 m. The checks drop from 1 m.
- **A marble put where the walker stands is thrown out of the scene.** `stand_at()` and then `drop()` in the same step left the marble inside the walker's capsule; it came to rest hundreds of metres away. Wait a few physics steps between the two.
- **A marble on a sphere.** Dropped exactly over the middle it stays; 5 cm off it rolls off and over the floor's edge. This floor has no rim.
- **`find_children()` does not return the node it is called on.** A box asked for its own mesh that way has none.
