# The look — a sky, a light, a palette

A study kit of the Godot course: lesson L00, a workshop stop that sits right after Point One. It is a small Godot 4.6 project in which a learner dresses a bare scene, a floor, a box and a sphere, step by step: a sky, light with no sun, a sun, a colour for the ground and for each body, and a palette of ten names by role. The script they end with builds the plain look that `supplied/look.gd` gives every later kit. The lesson is [TUTORIAL.md](TUTORIAL.md); the kit's own field note is [FIELD_NOTE.md](FIELD_NOTE.md).

Open it by importing `project.godot` in the Project Manager and pressing Play: `the_look.tscn` is the main scene. `place.tscn` is the same scene with a walker and a marble in it; open it and press F6.

## What is in the folder

Built in this lesson:

- `look.gd`: the learner's script, 46 lines, one function. The download holds the finished version; the lesson takes it apart and builds it again.
- `guests/the-look/`: the body this kit hands to the room. `the-look.tscn` is the box and the sphere with their colliders; `the-look.gd` paints them `BODY` and `SECOND`, the two colours written out. It names nothing outside its folder and declares no `class_name`.

Supplied by this kit:

- `the_look.tscn`: the scene. A floor of 8 m by 5 m, a box of 0.6 m, a sphere 0.6 m across, each with a collider, and a camera. It holds no light, no environment, no material and no colour.
- `place.tscn`, `place.gd`: the place. `the_look.tscn` with `supplied/walker.tscn` and `supplied/marble.tscn`. One contract: the action `drop` (M) drops the marble one metre in front of the walker, from above its head.
- `steps/`: the nine states `look.gd` goes through on the page, `0_engine_grey.gd` to `8_palette.gd`, made from TUTORIAL.md by its code blocks. `sheet.gd` photographs them and `verify.gd` checks what each built. The editor does not show the folder (it has a `.gdignore`); a learner does not need it.
- `evidence/`: two records of runs that need another project, the room. See *The room*, below.
- `verify.gd`, `sheet.gd`, and their results `verification.json`, `sheet.json`, `sheet.png`, `process.png`.

From the kit base, unchanged: `supplied/` (15 files), `.gitignore`, `export_presets.cfg`. `project.godot` is the base's with the name, the main scene and one more change: it sets no clear colour, so that the first run of the lesson shows the engine's own grey.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 56 checks and writes `verification.json`. Its exit code is the number of checks that failed. It needs no import step. A fresh copy with no `.godot/` passed 56 of 56, in about 32 seconds, because the walker walks in real time, and in about one second with `--fixed-fps 60` added, with the same result. It passed again after an import.

`sheet.gd` needs a window, so it is run without `--headless`; run headless it says so and exits 1. It takes about 17 seconds and closes its window by itself. It writes `sheet.png` (1292 × 536), `process.png` (2912 × 266), `sheet.json` and the stills in `stills/`.

## What the lesson measures

All of it is in `sheet.json`; the lesson quotes nothing else.

- **The nine states**, one still each from the scene's own camera, with the colour of the sky, the floor in the sun and in a shadow, three faces of the box and two points of the sphere.
- **One line more, one line less**: the sky without `background_mode`; ambient light without its energy line; the turned sun without its shadow line; the finished look with `sun.visible = false`; the same plain look asked of `supplied/look.gd` (our still, pixel for pixel); the look with the base's filter; the sphere at three values of roughness.
- **The four pairs**: lime on violet, hot pink on violet, red on green, grey on grey. Each is `look.gd` with its two lines `const GROUND` and `const BODY` written again, as the lesson has the learner do it. For each: the box's pixels, how far they are from the bare ground as rendered and made grey, and the same with the sun switched off.
- **The place**: the marble in the sun and in the box's shadow, from above; the box through the walker's eyes from behind.

Three colours on the sheet are the kit's own and not the palette's, because the pair is the axis: a red `ff0000`, a green `009400` chosen to have the red's luminance, and the two greys `808080` and `4d4d4d`.

## The room

The guest was tried once in a scratch copy of `../my-room/`, with its folder copied in and its line added to `GUESTS`:

```
godot --headless --path . --xr-mode off --script res://guest_trial.gd -- the-look
```

8 checks, 8 passed: the folder names nothing outside itself; it declares no `class_name`; the room ran 180 frames with no error; the guest stands at place 2 of 2; the walker reached the aisle in front of it ("arrived"); it walked at the guest and the walk ended "blocked", 0.54 m from the middle of the place, its feet at 0.00 m; no error to the end. The result is kept as `evidence/guest_trial.json`.

The lesson's room task, two roles changed in `room_look.gd` (`SKY` and `SHADE` exchanged), was run in the same copy with a window: no error, the sky read back `#0d0620` at the horizon and `#5a1fd6` overhead, a square `#ff2e93`, the edge of a number `#ff2e93`. Kept as `evidence/room_look_trial.json`. `verify.gd` reads both records; it does not run the room.

## What was and was not checked

Checked, headless, by `verify.gd` (56 checks): the project's name, main scene, renderer, that it sets no clear colour, and its nine actions; the 15 files of `supplied/`; no `class_name` anywhere and tabs in every script and every state; what Godot gives when nothing is said (a new `Environment`, `DirectionalLight3D` and `StandardMaterial3D`, and `Color("ff2e93")`); the scene undressed; each of the nine states and what it built, among them the planted bug, a sun that travels along (0, 0, −1); that the last state is `look.gd` byte for byte; that `look.gd` names the supplied look's ten roles with its ten colours, that its environment is `studio_environment()` in all 101 stored properties, its sun `sun()` in 43 and its materials `paint()` in 125; that the supplied look lays a filter over that; the four pairs carried by two lines of the palette; the luminance of the red and the green; the switch's line; the place (180 frames, C, M, a walk round, a walk at the box, the walker and a marble where the box's shadow falls, a marble on and beside the top of the sphere); the guest; the two records of the room.

Checked, with a window, by `sheet.gd`, and each picture looked at: `sheet.png`, `process.png`, the stills of the states, of the switch, of the filter, of the pairs made grey, and of the place.

Every code block of TUTORIAL.md was run in page order by a script kept in scratch: thirteen changes to `look.gd`, each followed by a headless run of the project with no error, and the two changes to the room's files. The last state equals the shipped `look.gd` byte for byte, the nine named states equal the files in `steps/`, and the two output blocks on the page are what the runs printed.

Negative tests, in scratch copies, one fault at a time, 21 faults; each made `verify.gd` fail and the copy with no fault passed: the sun left unturned; the shadow line, the energy line, the ambient source line or the `background_mode` line left out; a body painted with a written colour and not its role; one material shared by two bodies; the switch's line left in; spaces for tabs; a palette value changed; a guest that uses `supplied/look.gd`, declares a `class_name` or has no collider; the planted bug repaired in `steps/`; a last state that is not `look.gd`; a clear colour in `project.godot`; the scene's box without a collider; a material in the scene file; a supplied file missing; the room trial's record missing; a misspelt name in `look.gd`.

Not checked: nothing was run in a headset. The walker was walked by its autopilot and by actions pressed from the script, not by a hand on a keyboard. The editor's windows were not watched: the Output panel, the FileSystem and Scene docks, F5 and F6, the editor's preview light and the Project Settings window are described from knowledge of the editor, and marked *(editor)* in the lesson. No eye was asked which box is hard to find; the grey still is arithmetic and is not a test of colour vision. The four pairs were measured in the plain look and not under the filter. Everything was measured on one machine, an NVIDIA GeForce RTX 3070 with the Compatibility renderer. No learner has used it.

## Things that cost a run while building this

- **The base changed under the build.** `supplied/look.gd` gained a filter (a gradient sky, a tinted ambient light, a fill light) while this kit was being made, and `environment()` stopped being the plain look. The lesson builds the plain one, which is now `studio_environment()`, and measures the filter once.
- **A scene with no environment is not grey.** Its bodies are black, `#000000`, under a grey background. The grey bodies appear only with an `Environment`, whose ambient light comes from its background unless told otherwise.
- **A marble's resting height depends on the drop.** Dropped from 0.6 m it rests with its middle at 0.090 m, from 1 m at 0.098 m. The checks drop from 1 m.
- **A marble put where the walker stands is thrown out of the scene.** `stand_at()` and then `drop()` in the same step left the marble inside the walker's capsule; it came to rest hundreds of metres away. Wait a few physics steps between the two.
- **A marble on a sphere.** Dropped exactly over the middle it stays; 5 cm off it rolls off and over the floor's edge. This floor has no rim.
- **`find_children()` does not return the node it is called on.** A box asked for its own mesh that way has none.
