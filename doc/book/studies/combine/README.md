# Combine — union, subtraction, intersection (assemblage VI)

The study kit of chapter 44. A body is carved with three verbs: two members of the Families class are united, the implicit body's tunnel is taken from them, and what is left is intersected with a found body's skin. The result is baked to a mesh with a collider, and the supplied walker walks into it. The lesson is [TUTORIAL.md](TUTORIAL.md); the kit's own field note is [FIELD_NOTE.md](FIELD_NOTE.md).

It is a new Godot 4.6 project. Import `project.godot` in the Project Manager and press Play: `combine.tscn` is the main scene. Nothing here has a `class_name`, so no import step is needed before the commands below.

## What is in the folder

- `combine.tscn`: the scene. It inherits `supplied/base.tscn` and adds `Carved`, a `Node3D` that runs `combine.gd`, and `Walker`, the supplied walker, at (1.6, 0, 2.6).
- `combine.gd`: the learner's script, 104 lines. The lesson builds it step by step; its last state is this file byte for byte.
- `borrowed/`: three parts from earlier chapters, each in a small version with its contract in its first lines.
- `guests/combine/`: the body handed to the room.
- `supplied/`: the kit base's 15 files, unchanged.
- `verify.gd`, `sheet.gd`, and what they wrote: `verification.json`, `sheet.json`, `sheet.png`, `process.png`.

## Borrowed parts

| file | from | contract |
| --- | --- | --- |
| `borrowed/member.gd` | Families (chapter 14) | `Member.make(segments)`: a `SphereMesh` 1 m across with `segments` cuts around and half as many rings, kept between 4 and 64. The Families kit has the whole class `Globe`. |
| `borrowed/tunnel.gd` | Implicit bodies (chapter 36) | `Tunnel.value(p)`: below 0 inside a tunnel 0.8 m wide, 2.1 m high and 2.4 m long with a level floor at height 0. `Tunnel.make(spokes)`: its skin as a closed mesh, found by asking `value()` along spokes. A small version, not that chapter's mesher: it asks along spokes, which is enough for a body every spoke leaves once. |
| `borrowed/scan.gd` | Collage (chapter 18) | `Scan.make(closed)`: a lumpy skin 2.85 m high and 1.58 m wide, standing on the ground; a shell with an open foot, or closed. A stand-in made by this script. Nothing was scanned and nothing was downloaded. |

## What is built

`combine.gd` makes a `CSGCombiner3D` with four `CSGMesh3D` operands: A, the member of 16 segments, in BODY; B, the member of 4, in SECOND; C, the tunnel, in THIRD; S, the scan, in BONE. `order` (0 to 3) puts A, B and C in one of four orders, the fourth with a combiner inside the combiner; S is intersected last in all four. `baked` (on) turns the result into a `MeshInstance3D` with a `StaticBody3D` and frees the combiner. `b_x` is where B stands. `keep()`, on the `pause` action (Space), saves the baked mesh to `guests/combine/carved.tres` with the line of verbs and the operands' triangle count written onto it as metadata.

The colours are the palette's four BODIES, one for each operand, and every face of the result wears the paint of the operand it came from. No colour here is our own.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 71 checks and writes `verification.json`; its exit code is the number that failed. A fresh copy with no `.godot/` passed 71 of 71 in 43 seconds, and in 2 seconds with `--fixed-fps 60`, with the same measurements. Neither run wrote a `.godot/` folder or a `.uid` file. `sheet.gd` needs a window: it took 10 seconds, wrote `sheet.png` (1292 × 754), `process.png` (2264 × 266), `sheet.json` and the stills in `stills/`, and closed its window by itself. At exit it logged two `Texture ... leaked` lines; its exit code was 0.

## What Godot 4.6 does

Measured here, each as a check in `verify.gd`.

- **A combiner works its result out after the frame.** `bake_static_mesh()` in the frame an operand was added returns `null`; one frame later it returns the mesh.
- **Child order is operand order.** A, union B, minus C: 392 triangles. A, minus C, union B: 364. Minus C first: 296, the union of A and B with no tunnel, and no message.
- **An operand that is not closed is nothing, in silence.** This is the lesson's planted bug. The scan as a shell (340 triangles, 20 edges that belong to one triangle only) intersected with the body gives a result of 0 triangles. Godot logged no error and no warning. United with A or taken from A, the shell changed nothing: 256 triangles, A alone. The course outline names no planted bug for this chapter; this is the one the build met.
- **A face keeps its operand's material.** The baked mesh has four surfaces: 172 triangles in BODY, 101 in SECOND, 81 in THIRD, 220 in BONE.
- **A CSG body has no collider.** Not baked, the walker walked through the walls and stood with its feet at 0.00 m, 0.30 m under the tunnel's floor; put on that floor it fell through it; a marble came to rest at 0.10 m.
- **`use_collision` holds a body but is not a `StaticBody3D`.** A walker put in the hollow stayed at 0.30 m and the marble rested at 0.40 m. The supplied walker steps only onto a `StaticBody3D`, so sent in from outside it was blocked at the door, 0.80 m in front of the middle.

## Triangles before and after baking

The four operands list 768 triangles: 288, 24, 96 and 360. The baked body has 574, and its collider the same 574. After each verb the result had 256, 296, 392 and 574. Triangles under one square centimetre: 0, 4, 16 and 26; the smallest of the baked body is 0.016 cm². The tunnel's wall lists 48 triangles and is 81 in the result. The kept file `carved.tres` is 66,196 bytes and names no operand, no verb and no other file.

## The argument

Axis: the order of the same operands and verbs. Each order baked, alone in the studio, from the front along the tunnel, from the front right and from above. Share of the still on which two orders differ:

| pair | front | front right | above |
| --- | --- | --- | --- |
| (A union B) minus C, (A minus C) union B | 14.50% | 12.12% | 0.42% |
| (A union B) minus C, (A intersect B) minus C | 16.15% | 26.33% | 13.58% |
| (A union B) minus C, A minus (B union C) | 10.26% | 17.24% | 9.23% |
| (A minus C) union B, (A intersect B) minus C | 24.30% | 27.33% | 13.84% |
| (A minus C) union B, A minus (B union C) | 17.75% | 23.66% | 9.52% |
| (A intersect B) minus C, A minus (B union C) | 9.06% | 14.96% | 8.67% |

The outline predicted the first two as the closest pair. They are from the front right and from above, and not from the front, where the last two are. Counted against the pixels that either body covers, and not against the whole still, the last two differ on 100.0% from every standpoint (they share no pixel), and the first two are the closest pair from all three: 59.5%, 44.2% and 2.9%; from the front the first and the fourth follow at 60.7%. Triangles: 574, 544, 150, 422. Volumes: 1.859, 3.239, 0.196 and 0.793 m³; the third keeps 10.5% of the first, as the outline expected. The walker sent to the middle: arrived at 0.30 m; blocked at the door; arrived at 0.30 m on a slab of floor; arrived on the ground at 0.00 m. With B at `b_x` 0.95, clear of the tunnel, the first two orders are one body: 576 triangles each, 1.5763 m³, the same 292 corners and the same triangles, 0.00% of the still. The two meshes list their surfaces in the order of the children, 207, 58, 65 and 246 triangles against 207, 65, 58 and 246, so their lists of corners are not equal as lists.

The baked mesh and the combiner's own picture differ on 0.00% of the still.

## The guest

`guests/combine/` holds `combine.tscn`, `carved_body.gd` and `carved.tres`. The script loads the mesh, gives it a `StaticBody3D` with a collider made from its triangles, and hangs the mesh's line of verbs and its two counts over the door as a `Label3D`. With its plate the guest is 1.39 m wide, 1.42 m deep and 2.85 m high and stands on the ground at its origin. It names nothing outside its folder and declares no `class_name`.

The room test, run once in a scratch copy of `my-room` with the folder copied in and its line added to `GUESTS`:

```
My room: place 1 is res://guests/example/example.tscn
My room: place 2 is res://guests/combine/combine.tscn
PASS the room ran 180 frames with this guest in its list and Godot logged no error: []
PASS the guest stands in the room: res://guests/combine/combine.tscn is at place 2 of 2 taken
PASS the walker reached the aisle in front of place 2: "arrived"
PASS then it walked at the guest and the walk ended "arrived", 0.08 m from the middle of the place, its feet at 0.30 m
PASS and Godot logged no error to the end: []
```

Eight checks, none failed. The walker stepped up at the guest's door and stood in its hollow. `verify.gd` does not run the room; it carries these numbers into `verification.json` as `room_trial_record`, marked as a record.

## What was and was not checked

Checked, headless, by `verify.gd` (71 checks): the project; the base's 15 supplied files, no `class_name`, tabs; the three borrowed parts against their contracts; what the combiner does, verb after verb, and the two silences; the scene running more than 180 frames with no error and printing its two lines; the body not baked, baked and with `use_collision` under the walker and the marble, on the autopilot and by the actions the keys give (`move_right`, `move_left`, `move_backward`, `move_forward`, held from the script); the four orders by triangles, volume, closed skin and walker; B clear of the tunnel; union and subtraction with the operands changed round; `keep()`; a body of our own with `b_x` at 0.3; the guest.

Checked with a window, by `sheet.gd`, and both pictures looked at: `sheet.png` and `process.png`. The stills measured 960 × 720 on an NVIDIA GeForce RTX 3070 with the Compatibility renderer, in the sheet's plain studio.

Every `gdscript` block of the lesson was extracted and applied in page order, 14 blocks; each of the 16 states it describes was run headless and printed what the page says; the last state equals `combine.gd` byte for byte. A still of the running scene was taken in each state and looked at.

Negative tests, each fault planted in a scratch copy, each failing `verify.gd`: the shell (23 checks failed); the tunnel put first (19); C above B in the first order (17); nothing baked (5); the `await` line taken out (22); `use_collision` in place of the bake (12); a bake with no collider (14); a scan that never gets its foot (28); a tunnel with no level floor (20); a guest that uses `supplied/look.gd` (1); a guest with a `class_name` (2); a stale `carved.tres` (2); a guest with no collider (2); a line indented with spaces (`Parse Error: Could not preload resource script "res://combine.gd"`, exit code 1, no check made). The kit with nothing planted passed 71 of 71 in the same harness.

The kit was built in one session and finished in a second, which ran all of the above again on fresh copies: `verify.gd` (71 of 71, with and without `--fixed-fps 60`), `sheet.gd` (`sheet.json`, `sheet.png` and `process.png` came out byte for byte the same), the lesson's blocks and states, the stills of the states, the negative tests, the Space key (the kept `carved.tres` came out byte for byte the shipped one) and the room trial.

Not checked. Nothing was run in a headset. Nobody had their hands on the keys: every walk is the autopilot or an action held from a script, and the Space key was pressed by a script as the action `pause`, in a scratch copy and not by `verify.gd`. The editor's windows were not watched: the Inspector, the Scene dock, and whether the editor marks an operand that is not closed. Nothing was run with the debugger attached. The triangle counts were measured on one machine with Godot 4.6.stable.official; another build may cut the seams differently. No frame time was measured, for the combiner or for the baked body. No export was made. No learner has used the kit.

## Where it departs from the course outline

- The outline's process ends with a material step. Here every operand brings its paint from the first step, and the baked body keeps all four; nothing is painted after the bake.
- The verbs are written over the guest's door, not on a plinth: a guest's place is 1.6 m wide and deep and the body fills it, and a plinth under it would lift the tunnel's floor above the walker's step.
- The outline asks for the seam to be found by a classmate. No person looked; the seams are counted as triangles under one square centimetre.
- The implicit body and the scanned body are small stand-ins made in this kit, not the bodies of chapters 36 and 18.
- The outline names no planted bug for this chapter. The lesson's is the one the build met: an operand that is not a closed skin is nothing, in silence.
- No frame time was measured, though the outline lists profiling among the ideas that return; the cost of baking is counted in triangles.
