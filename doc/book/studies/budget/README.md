# Kit base — where every kit starts

A small Godot 4.6 project with nothing of a chapter in it: a floor, a sky, a light, a camera, and the parts every kit is given. A kit is a copy of this folder with the chapter's own scene put in the place of `base_demo.tscn`. The learner's room is another project, `../my-room/`, which holds the same `supplied/` folder, byte for byte.

Open it by importing `project.godot` in the Project Manager and pressing Play: `base_demo.tscn` shows every supplied part once.

## Starting a kit from it

1. Copy this folder, without `.godot/`, to `doc/book/studies/<your kit>/`.
2. In `project.godot` change `config/name` and `run/main_scene`.
3. Leave `supplied/` alone. Every file in it is the same in every kit and in the room.
4. Replace `base_demo.tscn`, `base_demo.gd`, `verify.gd`, `sheet.gd`, this README and the three pictures with the chapter's own. Keep the first line of `verify.gd` and of `sheet.gd`.
5. Make the body the kit hands to the room in `guests/<your kit>/`, and delete `guests/example/` or keep it as a pattern.

Your scene can inherit `supplied/base.tscn` (as `base_demo.tscn` does) and put its own script on the root: the look is made by a node of its own, `Look`, so a script on the root does not take it away.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 65 checks and writes `verification.json`. Its exit code is the number of checks that failed. It needs no import step: a fresh copy with no `.godot/` passed 65 of 65. It takes about 50 seconds, because the walker walks in real time, and about one second with `--fixed-fps 60` added, with the same result.

`sheet.gd` needs a window, so it is run without `--headless`; run headless it says so and exits 1. It writes `sheet.png`, `process.png`, `look.png`, `sheet.json` and the stills in `stills/`, and closes its window by itself, after about four seconds.

## The Input Map

Nine actions. The supplied parts ask for an action by its name, never for a key, so keys are changed in Project > Project Settings > Input Map and nowhere else.

| action | keys | who listens |
| --- | --- | --- |
| `move_left` | A, Left | `walker.gd`, `mover.gd` |
| `move_right` | D, Right | `walker.gd`, `mover.gd` |
| `move_forward` | W, Up | `walker.gd`, `mover.gd` |
| `move_backward` | S, Down | `walker.gd`, `mover.gd` |
| `jump` | J | `walker.gd` |
| `look` | V, held | `walker.gd`: the mouse turns the walker while V, or the right mouse button, is held |
| `switch_camera` | C | `walker.gd`: between the walker's Eyes and the scene's other camera |
| `drop` | M | no supplied part; `base_demo.gd` and the room drop the marble on it |
| `pause` | Space | no supplied part; `base_demo.gd` stops and starts its trace on it. It is yours |

Space is `pause`, as in the earlier kits, which is why `jump` is J. The walker and the mover listen to the same four moves: in one scene with both, tick `autopilot` on the mover or untick `keys` on the walker.

## The supplied parts

No file in `supplied/` has a `class_name`. Use a part by its path: `preload("res://supplied/segment.gd")`, `load("res://supplied/walker.tscn").instantiate()`. That is why a fresh copy needs no import.

**`base.tscn`** (with `base_look.gd`). A floor of 8 by 5 m with a collider, a fixed `Camera3D` at (0, 2, 4.7), and a node `Look` which, when the scene runs, makes `Look/Sky` (the environment) and `Look/Sun` (the light) and paints `Floor` in GROUND. The scene file holds no colour. The editor runs no script, so the editor's own view shows Godot's preview light and a white floor; the look is there when the scene runs.

**`look.gd`**. The palette, the light and the sky. See *The look*, below.

**`marble.tscn`**, `marble.gd`. The dropped test body: a ball of 0.1 m radius in BONE, frozen until it is dropped.
- `drop(at: Vector3) -> void`: puts it at `at` (a global position) with no speed and lets it fall. It meets collision shapes and never meshes: on the floor its middle rests at 0.10 m, on the example guest at 0.60 m, and it falls through a mesh with no collider.

**`mover.gd`**. The keyboard hand: attach it to any `Node3D`. It moves the node parallel to the floor at its own height.
- `speed := 1.2` (m/s), `area := Vector2(2.4, 1.5)` (furthest from the middle in x and z), `autopilot := false` (ticked: a slow figure-eight, and the keys are not heard).

**`segment.gd`**. A line between two points: attach it to a `MeshInstance3D`, or `preload("res://supplied/segment.gd").new()`.
- `show_between(a: Vector3, b: Vector3) -> void`: a cylinder of 12 mm radius in LINE from `a` to `b`, positions in the frame of the node's parent. Every segment has a cylinder of its own.

**`trace_strip.gd`**. A route as a line: attach it to a `MeshInstance3D`, or make one with `.new()`. It must be in the scene before the first call.
- `draw(points: Array) -> void`: the whole list of `Vector3` each time; a line strip in LINE, one pixel wide. Fewer than two points draw nothing.

**`sweep_sheet.tscn`**, `sweep_sheet.gd`. The wall a family hangs on.
- `hang(member: Node3D, title: String) -> void`: stands `member` next in the row, 1.2 m (`spacing`) from the one before, with `title` on a plate at its feet in INK. A member that is itself a mesh is lifted until its lowest point is on the ground and, if it has no material, gets the sheet's `paint` (BODY unless you set another). `hung` and `plates` list what it holds.

**`walker.tscn`**, `walker.gd` (150 lines). A desktop body with eyes: a `CharacterBody3D`, a capsule 1.8 m high and 0.6 m wide with its origin at its feet, `Eyes` (a camera) at 1.6 m, `Skin` (the capsule you see from another camera) in SECOND.
- Keys: the four moves walk it the way it faces, `jump` lifts it 0.85 m, `switch_camera` changes the view. The mouse turns it while the right button or `look` is held; the mouse is never captured.
- `walk_to(points: Array) -> void`: the autopilot. A list of `Vector3`; it walks to each in a straight line; only x and z count. The keys are not heard until the walk ends.
- `signal walk_ended(how: String)`: `"arrived"` (it stands on the last point), `"blocked"` (half a second without coming nearer or falling), `"fell"` (it went below `fall_limit` and was put back) or `"stopped"`. Every walk ends in one of the four.
- `stop() -> void`, `stand_at(at: Vector3) -> void` (puts it there, still; it returns there after a fall), `walking: bool`, `ended: String`.
- `speed := 2.0`, `jump_speed := 4.0`, `step_height := 0.35`, `look_speed := 0.003`, `keys := true`, `through_eyes := false`, `fall_limit := -10.0`.
- What a body does to it, measured: a `StaticBody3D` stops it (`"blocked"`, its middle 0.3 m from the face) and carries it; one no higher than `step_height` it steps onto (0.10, 0.18 and 0.30 m: arrived on top; 0.60 m: blocked; a stair of three steps of 0.18 m, 0.4 m deep: arrived on top). With `step_height` at 0 the capsule alone rolls up 5 cm and is stopped by 10 cm. A mesh with no collider does nothing to it: it walks through and falls through. A `RigidBody3D` in its way is kicked along. It takes its gravity from the place it is in, so an `Area3D` that changes gravity changes it for the walker too.

**`verify_tools.gd`**. The check harness. `verify.gd` begins with `extends "res://supplied/verify_tools.gd"` and writes one function, `run()`. Do not write `_initialize()`.
- `check(ok: bool, text: String) -> void`: one check; prints `PASS` or `FAIL` and the text.
- `measured: Dictionary`: yours; it goes into `verification.json`.
- `errors`, `warnings`, `printed` (each an `Array[String]`): every error, script error and shader error Godot logged since the run began, every warning, and every printed line. So "it ran 180 frames with no error" is a check you can make: `var before := errors.size()` … `check(errors.size() == before, …)`.
- `frames(count: int)`, `physics_frames(count: int)`: wait. `settle(body: RigidBody3D) -> Vector3`: wait until a dropped body lies still. `near(a, b, slack := 0.0005) -> bool`.
- `press(action: String)`, `hold(action: String, steps: int)`: an action of the Input Map, as a key would give it.
- `walk(walker: Node, points: Array) -> String`: `walk_to()` and wait for the end; returns `how`.
- `result_file := "res://verification.json"`, `write_result(path: String) -> int`, `finish()`.
- `await` every helper that waits: `frames`, `physics_frames`, `settle`, `press`, `hold`, `walk`.
- The result has a top-level `passed` and `checks`, a list of `{name, passed}`. The exit code is the number of failed checks; no check at all is exit code 1. 60 seconds without a new check and the harness adds a failed check and exits. A script error in `verify.gd` itself adds a failed check that names it.

**`sheet_tools.gd`**. The still-maker and the measures. Windowed only. `sheet.gd` begins with `extends "res://supplied/sheet_tools.gd"` and writes one function, `run()`.
- `stand(body: Node3D, held := true)`: the studio (a `base.tscn` of its own) with `body` alone in it. `held` stops the body's own `_process` so that two stills show one moment.
- `look(view: String, distance := 2.0, middle := Vector3(0, 0.5, 0))`: the eye from the side (`"level"`) or from straight above (`"above"`); the body casts no shadow. `look_from(from: Vector3, at: Vector3)`: the eye anywhere; shadows on. `shadows(on: bool)`.
- `shot(name := "") -> Image`: the still the window shows, cut to its middle 4:3 (960 by 720 here); with a name it is saved as `stills/<name>.png`. It photographs whatever is in the window, so it works for a scene of your own too.
- `portrait(body: Node3D, name := "") -> Array`: `[still, pixels]`; `pixels` has one byte for each pixel, 1 where the body is, found by a second still with the body in one flat colour. `photograph(body: Node3D, view: String, name: String, distance := 2.0) -> Array`: `stand`, `look` and `portrait` in one call: a subject alone from a standpoint, as a PNG.
- `differs(a: Image, b: Image) -> PackedByteArray`, `share(pixels) -> float` (percent), `differ_pct(a, b) -> float`. Two stills differ at a pixel when its three channels together are more than 25 of 255 apart: the threshold of the earlier kits.
- `compare(a, pixels_a, b, pixels_b) -> Dictionary`: `differ_pct`, `outline_pct`, `inside_pct`, `elsewhere_pct`, `outline_px`. `compare_all(names: Array, stills: Array, pixels: Array) -> Dictionary`: `{pairs, closest, farthest}`.
- `small(still: Image) -> Image`: a tile of 320 by 240. `compose(tiles: Array[Image], columns: int, names: Array, path: String) -> Dictionary`: rows of tiles with captions in INK on SHADE. `strip(tiles: Array[Image], names: Array, path := "res://process.png") -> Dictionary`: one row, and `{steps, changed_most, png}`.
- `parts(body) -> Array`, `box_of(body) -> AABB`, `report: Dictionary` (yours; written to `sheet.json` when `run()` returns), `studio`, `eye`, `subject`, `crop`.
- `await` every one that waits: `stand`, `shot`, `portrait`, `photograph`, `compose`, `strip`.
- 60 seconds without a new still and the window closes with exit code 1. A script error in `sheet.gd` gives exit code 1 as well.

**`check_guest.gd`**. `const CheckGuest := preload("res://supplied/check_guest.gd")`.
- `CheckGuest.outside(folder: String) -> Array[String]`: what the guest in `res://guests/<name>/` needs from outside its folder. Empty means it stands on its own. It reads every `.tscn`, `.gd`, `.tres`, `.gdshader` and `.gdshaderinc` of the folder as text and lists each `res://` path that is not inside the folder, a comment's too, and the script of each named class from outside that a `.gd` uses. A missing or broken scene is one line beginning `no scene` or `does not load`.
- `CheckGuest.class_names(folder: String) -> Array[String]`: the names the folder declares with `class_name`. See *The guest*.

## The look

One palette for every kit, named by role and not by hue:

| role | value | used for |
| --- | --- | --- |
| `SKY` | `#ff2e93` | the background |
| `GROUND` | `#32188a` | the floor |
| `BODY` | `#c6ff3d` | the made body |
| `SECOND` | `#22d9ff` | a second body; the walker |
| `THIRD` | `#ff8b1f` | a third |
| `BONE` | `#f4efe6` | the marble; a fourth |
| `LINE` | `#ffffff` | traces and segments |
| `GHOST` | `#9b7bff` | what is translucent or has no collider |
| `INK` | `#ffffff` | text |
| `SHADE` | `#0d0620` | what text stands on |

`BODIES` is `[BODY, SECOND, THIRD, BONE]`, the members of a family in order.

```gdscript
const Look := preload("res://supplied/look.gd")

body.material_override = Look.paint(Look.BODIES[i])
```

- `Look.paint(color: Color) -> StandardMaterial3D`: the one way a kit makes a body's material: roughness 0.8, no metal.
- `Look.ghost() -> StandardMaterial3D`: GHOST at alpha 0.45.
- `Look.environment() -> Environment`: the sky of a scene that RUNS: violet (`SKY_TOP`, `#5a1fd6`) above a pink horizon (`SKY`), the ground beyond the floor fading to GROUND, a faintly lavender ambient light, saturation 1.08 and contrast 1.04.
- `Look.studio_environment() -> Environment`: the plain sky of the sheet's studio: SKY flat, a white ambient light. `sheet_tools.gd` uses it.
- `Look.sun() -> DirectionalLight3D`, `Look.fill() -> DirectionalLight3D`: the sun, and a weak cyan light from the other side with no shadow. `base.tscn` calls `environment()`, `sun()` and `fill()` and softens the sun's shadow edge; a scene that does not start from `base.tscn` calls them itself.
- `Look.label(text: String) -> Label3D`: INK letters with a SHADE edge.

What the look uses of the Compatibility renderer: a background colour, a white ambient light of energy 0.25, one directional light with shadows, 43° above the horizon, and the linear tonemap, which leaves colours as they are. No glow and no fog: both were left out so that a still shows the body and nothing bleeds into the pixels beside it; neither was tried.

**Two skies, on purpose.** A scene that runs shows the look with its filter: the gradient sky, the tinted ambient light, the fill light, a softer shadow, a little more saturation and contrast. The sheet's studio is plain: `sheet_tools.gd` swaps in `studio_environment()`, removes the fill light and restores the hard shadow, so a still measures the body and not the sky. This was checked when the filter was added: `look.png`, `sheet.png` and `process.png` came out with 0 pixels different from before it. Ten variants were rendered to choose the filter. The gradient sky helped most. Fog and glow washed the bodies out and are left off; the filmic and AgX tonemaps turned lime toward yellow and are not used. The numbers below are of the plain studio.

**Measured.** `sheet.gd` puts five boxes of 0.5 m on the floor and photographs them from the fixed camera (`look.png`). The mean colour of each face in the still, its distance from the palette value (red, green and blue together, each of 255), and its contrast against the rendered floor, as (L1 + 0.05) / (L2 + 0.05):

| | palette | face to the sun | off by | against the floor | front face | off by | against the floor |
| --- | --- | --- | --- | --- | --- | --- | --- |
| BODY | `#c6ff3d` | `#ccff3a` | 6.5 | 11.49 : 1 | `#bdf735` | 14.5 | 10.59 : 1 |
| SECOND | `#22d9ff` | `#1ee0ff` | 8.2 | 8.44 : 1 | `#1ad0f7` | 14.4 | 7.31 : 1 |
| THIRD | `#ff8b1f` | `#ff8c1a` | 5.2 | 5.80 : 1 | `#f78217` | 14.5 | 5.23 : 1 |
| BONE | `#f4efe6` | `#fff9f0` | 17.9 | 12.89 : 1 | `#ece7de` | 13.9 | 10.93 : 1 |
| GHOST | `#9b7bff` | `#6143c0` | 102.3 | 1.97 : 1 | `#5b3ebc` | 111.5 | 1.82 : 1 |

The sky is rendered `#ff2e93`, exactly SKY. The floor in the sun is `#2d1388`, 7.3 from GROUND; in a box's shadow it is `#150548`, a contrast of 1.36 : 1 against the floor in the sun. The sky against the floor is 3.89 : 1. GHOST is far from its palette value because it is seen through, blended with the floor behind it; it casts no shadow.

Read these numbers with three things in mind.

- **The ground was made lighter so that shadows read.** The first GROUND, `#1b0f3b`, was so dark that a shadow on it was 1.10 : 1 against the lit floor. At `#32188a` it is 1.36 : 1, and the bodies still stand at 5.8 : 1 or more against it.
- **LINE is white.** It was first the colour of SKY, and a trace or a segment then vanished against the sky (1 : 1). White shows against the sky and against the floor.
- **The sun's energy is 0.28, not 1.** In this renderer a sun that casts shadows lit a face about three times as brightly as its energy says: with energy 1.0 the lime box was rendered `#ffff60` and the bone box pure white. And the same sun with `shadow_enabled` off lit a face less than half as brightly (the lime top went from `#ccff39` to `#8db62b`). So leave the sun's shadows on, and tell a body not to cast one instead: `sheet_tools.gd` does that in `look()`.

## The guest

A kit hands the room one body: the folder `guests/<kit>/` with the scene `<kit>.tscn` in it. `guests/example/` is the pattern. A guest

- has everything it needs in its own folder and names nothing outside it: not the kit's other files and not `supplied/`. So a guest cannot use `look.gd`: it writes its colours out, as `example.gd` does;
- stands on the ground at its own origin and fits in a box 1.6 m wide and deep;
- has a `Node3D`, or a kind of one, as its first node;
- declares no `class_name`. This is not in the builders' brief and it should be: tried in a copy of the room, a guest script that used its own class name did not compile before an import (`Identifier not found`), and after an import two guests that declared the same name gave `Class "Twin" hides a global script class` and one of them lost its script.

In the kit's `verify.gd`:

```gdscript
const CheckGuest := preload("res://supplied/check_guest.gd")

	var needs := CheckGuest.outside("res://guests/trial/")
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names("res://guests/trial/").is_empty(), "the guest declares no class_name")
```

The check exists because a run cannot see the fault: a guest that preloads `res://supplied/marble.gd` loads and runs in the kit and in the room, since both have `supplied/`, and `outside()` returns `["res://supplied/marble.gd"]`.

The real test, once, in scratch: copy `../my-room/` (without `.godot/`), copy your guest's folder into its `guests/`, add its line to `GUESTS` in `room.gd`, and run the room's own trial:

```
godot --headless --path . --xr-mode off --script res://guest_trial.gd -- <kit>
```

It runs the room 180 frames, finds the guest, walks the walker to it by the aisles and says what happened.

## Things that cost us a run while building this

- **A script error in `verify.gd` skips the rest of that function, in silence.** The run goes on and can pass with fewer checks. The harness now adds a failed check when it sees one; count your checks all the same.
- **`await walker.walk_ended` and then `free()` crashed Godot**: the code after the `await` runs inside the signal. Use `await walk(walker, points)`, which waits one frame more, or `queue_free()`.
- **A body is in the room from the step it is added.** A walker added at the origin and then moved knocked a marble off a box 0.9 m away. Set `position` before `add_child()`.
- **An `Area3D` takes a step to find a body.** A walker put into a region with no gravity fell for that step and kept the speed. Put it down again with `stand_at()` once it is inside.
- **A file is whole on the disk once it is closed.** `FileAccess.open(path, FileAccess.WRITE).store_string(text)` and then reading the file in the same function gave an empty file. Keep the file in a variable and call `close()`.
- **A list written as `[Vector3(1, 0, 0)]` is not an `Array[Vector3]`** when the function is reached through a node of unknown type: Godot refused it at run time. So `walk_to()` and `draw()` take a plain `Array`.
- **The editor and an export write `.uid` files** beside every script, in `supplied/` too. The repository ignores them; delete them from what you ship, or build in scratch. A headless run with `--script` on a fresh copy wrote none and made no `.godot/`.
- **The repository ignores `*.tres`.** The `.gitignore` here takes `guests/**/*.tres` back in; a `.tres` elsewhere in a kit needs a line of its own.

## What was and was not checked

Checked, headless, by `verify.gd` (65 checks; 65 of 65 on a fresh copy, with and without `--fixed-fps 60`, and again after an import): the project's name, main scene, renderer and nine actions with their keys; the 15 files of `supplied/`, none with a `class_name`, tabs in every script; the palette, `paint`, `ghost`, `environment`, `sun`, `label`; `base.tscn` running with SKY, GROUND, a sun and its fixed camera, and no colour in the file; the marble on the floor, on the example guest and through a mesh; the mover by key, at its limits and on autopilot; the segment and two segments not sharing a mesh; the trace strip; the sweep sheet; the walker standing, walking 6 m in 179 steps, two points, `stop()`, falling off the floor and coming back, an empty list, a wall with and without a collider, a step to stand on and a mesh to fall through, steps of 0.10 to 0.60 m, the bare capsule, a stair, the example guest, the marble, zero gravity, the keys, the jump, the cameras, the mouse, `keys` off, `through_eyes`; `check_guest` on the example, on a guest made in `user://` that preloads `res://supplied/marble.gd` (which also loads and runs), on its `class_name`, on a folder that is not there; the demonstration running 180 frames with no error; the harness catching an error, a warning and a printed line, and writing its result.

Checked, with a window, by `sheet.gd`, and each picture looked at: `sheet.png` (644 × 510, two boxes from the side and from above; they differ on 23.83% and 22.52% of the still), `process.png` (968 × 266, three steps; the walker changed the tile most, 8.54%), `look.png` and the table above. The stills measured 960 × 720 on an NVIDIA GeForce RTX 3070 with the Compatibility renderer.

Negative tests, in scratch copies, one fault at a time: a failing check (exit 1), three (exit 3), no check (exit 1), a script error in a function `run()` awaits (exit 1, named), a wait for a signal that never comes (exit 1 after 60 seconds); `sheet.gd` run headless (exit 1, one line) and with a script error (exit 1). Fourteen faults planted in this project each failed `verify.gd`: SKY changed, a shiny paint, the floor not painted, a walker that never moves, one with no gravity, one that does not step up, one that does not kick, one with no collider, a marble with no collider, a `class_name` in `supplied/`, a `check_guest` that sees nothing, an example guest that uses `look.gd`, one with no collider, spaces for tabs. One planted fault was not caught: the walker emitting `walk_ended` in the middle of its physics step, which `walk()` hides by waiting a frame.

Not checked: nothing here was run in a headset, and no XR node is in it. The walker was walked by its autopilot and by actions pressed from the script, not by a hand on a keyboard; the mouse look was checked with an event made in the script. The editor's windows were not watched. No learner has used any of it. The look was measured on one machine and one graphics card. Glow and fog were not tried. The export preset is the Collage kit's; an export was run for the room, not for this project.
