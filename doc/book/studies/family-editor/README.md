# The family in the editor — setters, @tool and the sheet opened

The study kit of chapter 15. A small Godot 4.6 project: a pyramid whose apex can walk off its base, written as a class with a setter that rebuilds the body and with `@tool`, so that the family changes while the scene runs and inside the editor; a sweep sheet written by the learner, which stands Ada's own pyramid once for each value of its `apex_stance`; and a rail on the floor that sets the family from where the walker stands.

This is a new project. Import this folder's `project.godot` in the Project Manager and press Play: `family_editor.tscn` is the main scene. Follow [TUTORIAL.md](TUTORIAL.md). The kit starts from `../kit-base/` and holds nothing of an earlier chapter.

## What is in the folder

Built in the lesson (the learner's):

- `guests/family-editor/spire.gd`: the class. `extends Node3D`, no `class_name`. One exported field, `lean` (0 to 1.6), with a setter that returns on an equal value, stores the value, and rebuilds once the node is ready. `_ready()` makes a mesh child and a collider child, which the scene does not own, and calls `rebuild()`. Methods `apex()`, `over_base()`, `rebuild()`. `@tool` on its first line; it prints one line for each rebuild when it runs in the editor.
- `family_editor.gd`: the scene's script, the learner's own sheet. It reads the values of `apex_stance` from the class (`values_of()`), sets each on a new member before `add_child()`, paints the members in `BODIES` order, reads the apex of each built mesh back (`built_apex()`), names it on a plate and prints what was asked beside what was built. In `_process()` it hands the rail's value to the spire while the walker stands on the rail.

Given with the kit:

- `family_editor.tscn`: the scene. It inherits `supplied/base.tscn` and adds `Spire` (an instance of the guest scene, at (−0.62, 0, 1.2)), `Wall` (an empty `Node3D` at (−2.1, 0, −1.6)), `Rail`, `Walker` (on the rail's high end) and `Readout` (a `Label3D`).
- `guests/family-editor/family-editor.tscn`: the body handed to the room, a `Node3D` with `spire.gd` and one stored value, `lean = 1.6`.
- `borrowed/ada_pyramid.gd`: Ada's pyramid, from `commons/primitives/pyramid/pyramid.gd`. Contract: set `apex_stance` or `base_sides` before `add_child()`; it builds once, in `_ready()`. Its two exports, `pyramid_height`, `base_size`, `_create_pyramid_vertices()`, `_base_ring()`, `_apex_position()` and `_create_pyramid_faces()` are Ada's, line for line. Ours: Ada paints with a grid shader and builds its mesh with a helper script; here a SurfaceTool builds it, lit flat, and it is painted in the look. Left out: `apply_grid_config()` and `set_pyramid_size()`.
- `borrowed/slider_rail.gd`: the slider rail, supplied with this kit. Contract: while the node named in `who` stands within `reach` of the rail, `held` is true and `value` is where it stands, from `low` at the rail's own place to `high`, `length` metres along its +x. Off the rail, `held` is false and `value` stays. `value` can be set: the knob follows.
- `supplied/`: the base's fifteen files, unchanged.
- `verify.gd`, `sheet.gd`, and their outputs `verification.json`, `sheet.json`, `sheet.png`, `process.png`; `guest_trial.json`, the room's trial of the guest; [FIELD_NOTE.md](FIELD_NOTE.md).
- `.gitignore` is the base's with one line more, `.editor_check/`, the folder `verify.gd` makes and removes.

## Keys

The base's Input Map, unchanged. W and S walk the walker along the rail (it faces away from the camera); A and D step off it; C changes between the fixed camera and the walker's eyes; the right mouse button, or V, held, turns it; J jumps.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 60 checks and writes `verification.json`; its exit code is the number that failed. It needs no import. It took 36 and 38 seconds on fresh copies, and 18 with `--fixed-fps 60` added, with the same result. Three times in the run it starts a second Godot: the editor, with no window, on a copy of the project in `.editor_check/`, with the scene open, for 300 frames. That is how the checks of `@tool` are made. The copy is removed at the end. Each of those editor runs logs `ERROR: Parameter "t" is null.` at the moment the stand-in script saves the scene; the scene is saved all the same. By its backtrace it comes from inside `EditorInterface.save_scene()`; a windowless editor has no renderer, and we did not find out what asks for the texture.

`sheet.gd` needs a window, so it is run without `--headless`. It takes about 22 seconds, writes `sheet.png`, `process.png`, `sheet.json` and the stills in `stills/`, and closes its window by itself. Since the look got its gradient sky it ends with two lines `ERROR: Texture with GL ID of 23: leaked 349524 bytes.` (and 24); the base's own `sheet.gd` prints the same two, and the exit code is 0.

## What was checked

**Headless, by `verify.gd`** (60 of 60 on a fresh copy without `.godot/`, with and without `--fixed-fps 60`): the project, the fifteen supplied files, no `class_name` anywhere, tabs. Ada's pyramid: its four stances read from its property list; each built with the apex where its code puts it; the distances between the apexes in plan; set after `add_child()` (the field changes, the body does not, nothing is logged); five words its `match` does not know (each builds the centred body, the field keeps the word, nothing is logged); `set()` with a wrong name. The spire: the stored value kept before the node is ready, the body built once from it, the body following a value set while it stands, nothing built for an equal value, the methods, the paint, the collider, the same five corners as Ada's pyramid at centred, corner and beyond, one rebuild timed (the fastest of five rounds of 200: 0.04 ms in the shipped run, 0.06 ms in another while other programs ran). The lesson's states, made from the shipped script: a plain field (field and body disagree), the planted bug (the exact error), a setter without the equal-value guard (180 builds for 180 equal values). The scene: its four printed lines, the row, the colours, the plates, `values_of()` on an enum, an `int` and a missing name, 180 frames with no error, the rail walked, stepped off and stepped on again. The keys, pressed as actions of the Input Map for 30 physics steps each: W (0.97 m along the rail, lean 1.6 to 0.77), S (back to 1.6), D (off the rail, lean kept). The walker at the spire at lean 0, 1 and 1.6 from two sides, and lean by lean from 0.5 to 1.0; the walker through a member of the wall. The guest: nothing named outside its folder, no `class_name`, alone on the ground inside 1.6 m. The editor without a window: with `@tool`, without it, with the planted bug, and the scene saved there.

**With a window, by `sheet.gd`**, and each picture looked at. `sheet.png` (1292 × 1076): Ada's pyramid at centred, edge, corner and beyond, each alone in the studio in BODY, from four standpoints 2 m from the middle: level, plan (straight down, orthographic), across and along the diagonal the apex walks. Stills of 960 × 720 on an NVIDIA GeForce RTX 3070, Compatibility renderer. Share of the still on which two members differ:

| pair | level | plan | across | along |
| --- | --- | --- | --- | --- |
| centred and edge | 0.49% | 2.07% | 4.42% | 6.35% |
| centred and corner | 5.98% | 3.98% | 11.25% | 0.79% |
| centred and beyond | 7.87% | 6.54% | 12.95% | 7.59% |
| edge and corner | 5.75% | 4.10% | 8.85% | 6.00% |
| edge and beyond | 7.58% | 6.54% | 11.04% | 10.27% |
| corner and beyond | 3.64% | 6.54% | 11.14% | 6.80% |

The closest pair is centred and edge from three standpoints and centred and corner from the fourth. The course outline predicted corner and beyond; that pair is closest only in metres (0.255 m between the apexes in plan, against 0.3 m). `sheet.json` also holds the spire at lean 0 to 1.6 in steps of 0.2 from the same four standpoints, and where the studio's sun stands: 88° from the diagonal the apex walks, with one face turning to it at lean 0.96. `process.png` (1616 × 266): five steps, made in the studio from its fixed camera with the scene's own floor, sky and light taken out; the steps changed 0.00, 2.48, 1.77, 3.79 and 7.19% of the tile.

**The lesson's code**, by a script kept in the builder's scratch folder: the page's code blocks were applied in page order to the two learner scripts, nine states in all, and each state was run headless as the project's main scene. Every block of printed output on the page was found in the log of the state before it; the two excerpts of `borrowed/ada_pyramid.gd` are in that file word for word; the last state equals `spire.gd` and `family_editor.gd` byte for byte. The room block of *In your room* was run in a copy of the room.

**Negative tests**, in scratch copies, one fault at a time, each failing `verify.gd`: the planted bug (13 checks failed); `lean` a plain field (12); the setter without the equal-value guard (10); no `@tool` (4); the sheet setting `apex_stance` after `add_child()` (8); the same sheet asking the field and not the mesh (7); four words typed and not read, `centre`, `side`, `corner`, `past` (3); the guest preloading `supplied/look.gd` (1); a `class_name` in the guest (2); spaces for tabs in `family_editor.gd` (9).

**The borrowed part against Ada's**, once, in a scratch project holding Ada's `pyramid.gd` and the three scripts it preloads: the four functions are the same text, and for five values of `base_sides` by four of `apex_stance` the corners and faces were equal in 20 of 20 cases. Ada's own class was not run in Ada's project for this.

**The room**, in a scratch copy of `../my-room/` with the guest's folder copied in and its line added: `guest_trial.gd` passed 8 of 8 (`guest_trial.json` here is its record). The room printed `My room: place 2 is res://guests/family-editor/family-editor.tscn`; it ran 180 frames with no error; the walker reached the aisle and, walked at the guest, was blocked 0.44 m from the middle of the place, feet at 0.00 m. The room task was run in a second copy with the spire standing in for the learner's body: a guest `my-sheet` (the page's script, a copy of `spire.gd`, a scene written by hand) put first in `GUESTS` stood at place 1, the trial passed 8 of 8, and the walker was blocked 0.30 m from the middle.

**Run twice.** The session that built the kit was cut off before it reported. A second session ran all of the above again on fresh copies: `sheet.json`, `sheet.png`, `process.png`, the stills and `guest_trial.json` came out byte for byte the same, the lesson's nine states ran as the page says, and the comparison with Ada's own class passed again. It added the three checks of the keys to `verify.gd`, which made 57 checks 60, and ran the ten negative tests against that; the numbers above are from that run.

## What Godot really did, where the outline said otherwise

- **The planted bug.** The outline: the setter calls the rebuild before the node is ready, "so errors fill the Output as soon as the scene opens". Measured: one script error for each value set before the node is ready, `Invalid assignment of property or key 'mesh' with value of type 'ArrayMesh' on a base object of type 'Nil'.`, and after it the scene runs and looks right, because `_ready()` builds from the stored value. Run without the editor's debugger the game does not stop. In the editor, with `@tool`, the same error is logged once as the scene opens.
- **The prediction.** False from all four standpoints; see the table.
- **The claim.** "The step that changes the category is not the largest step": in metres the step from corner to beyond is the shortest; in pixels it is the largest from three of four standpoints.
- **The body's own category.** For the walker the spire turns from a wall into a ramp between lean 0.8 and 0.9, before the apex leaves the base.
- **A mesh in the scene file.** A first version of the spire was itself a `MeshInstance3D`. In the windowless editor, after a value was set and the scene saved, `family_editor.tscn` grew from 1051 to 2873 bytes: it held the built `ArrayMesh` and the material. The shipped spire builds on children the scene does not own, and the saved scene holds `lean = 0.5` and no mesh.
- **`generate_normals()` smooths by default.** The first stills of the pyramid were shaded round. `set_smooth_group(-1)` lights every face flat, as Ada's own builder does with one normal for each face.
- **Exactly on the edge.** The apex of `edge` is written as 0.3. The mesh gives back 0.299999982119, Ada's `_apex_position()` 0.300000011921, and half the base as a `float` is 0.3: without a millimetre of slack the answer to "is it over its base" depends on which of the two is asked.

## Not checked

Nothing here was run in a headset, and no XR node is in it: "a supplied in-world slider changes the family while you hold the body" is the rail, worked by where the walker stands. The walker was walked by its autopilot and by actions pressed from the script, not by a hand on the keys. The editor's windows were not watched: the Inspector's slider, the Debugger panel and the editor's viewport are described from what a windowless editor logged and from what a script standing in for the Inspector did. A tool script that hangs or frees nodes in the editor was not tried. No larger body's rebuild was timed. The quarter turn under the sun that *Decide* offers was not run. No person judged which pyramids look alike: every likeness is a count of pixels. No learner has used the kit. The halls were read from `commons/maps/Primitives_Ignorance/`, `commons/maps/Color_Context_Placed/` and `commons/maps/Topology_Entropy_Morphogenesis/`, their scripts and the registry, not walked; that no map places a pyramid at another `apex_stance` than the default was found by searching every `map_data.json` for the word.
