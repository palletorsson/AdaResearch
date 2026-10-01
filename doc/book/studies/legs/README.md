# Legs — the passive part drives

A study kit of the Godot course, chapter 21. It is a project of its own: import this folder's `project.godot` in the Project Manager of Godot 4.6. `legs.tscn` is the main scene. Follow [TUTORIAL.md](TUTORIAL.md). The lesson takes two sessions; the first ends at *Stop here*.

It starts from the kit base and holds nothing of another chapter. `supplied/` is the base's folder, unchanged, byte for byte.

## What is in it

**Built by the learner.** Two scripts, taken apart and built again in the lesson.

- `leg.gd`, on the root of `leg.tscn`: the hip. It builds a chain of `segments` parts, 0.8 m long in all. `follow(to)` is the follow loop, from the foot back to the hip, and then the hip holds: the chain is carried back to it. `find_ground()` sends the leg's `RayCast3D` straight down in the room's axes from the leg's rest place and takes the point it finds as the foot's `target`. `step(delta)` glides the foot to its target and calls `follow()`. `tip()` is where the chain ends.
- `creature.gd`, on `Creature` in `legs.tscn`: a trunk with a collider, `leg.tscn` instanced four times with each hip turned a quarter, and a `_physics_process()` in which one foot at a time finds the ground, the body is put `ride` metres above the middle of its four feet, and each leg takes its step. Exports: `segments`, `heading`, `lead`, `ride`, `beat`, `leash`, `ground`, `hand`.

**Scenes.** `legs.tscn` inherits `supplied/base.tscn` and adds `Terrain`, `Plank`, `Creature` and `Walker`. `carry.tscn` inherits the base and adds a post, one leg and a hand: the first session's scene, run with F6. `leg.tscn` is the hip with three nodes the script uses: `Ray` (a `RayCast3D`, left as it comes), `Mark` (a ball at the foot's target) and `Beam` (the supplied segment, which draws the ray).

**Borrowed.** `borrowed/terrain.gd`, from ch12, Noise, as a small version made here because that kit was not yet built. One contract: `height_at(x, z)` is the ground's height in metres at a place of the room; `_ready()` builds a mesh, a net of white bands and a collider from it. 4.4 by 3 m, at most 0.35 m high, on collision layer 1.

**Supplied with this kit.** `ghost_plank.gd`: a board with a collider on layer 2 and no other, painted GHOST. `carry.gd`: it hands the hand's place to the leg every frame and writes a readout. `sheet.gd`, `verify.gd`.

**Handed to the room.** `guests/legs/`: `legs.tscn`, `creature.gd`, `leg.tscn`, `leg.gd`. The two scripts are the kit's, with the colours written out, no beam, a lead of 6 cm and a leash of 5 cm, so that the creature paces on its place, and one export more, `rider`: a scene the legs carry on the trunk's back. The folder names nothing outside itself and declares no `class_name`.

The look is the base's. Trunk and legs are BODY, the foot marks SECOND, the rays LINE, the ground GROUND with a net in LINE, the plank and the post GHOST, the hand BONE. No colour is written in this kit outside the guest's folder, where the palette's values are written out.

## Commands

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

`verify.gd` runs 107 checks and writes `verification.json`; its exit code is the number that failed. It needs no import step. It takes about two minutes, because the creature and the walker walk in real time, and about three seconds with `--fixed-fps 60` added, with the same 107 checks and the same measures.

`sheet.gd` needs a window, so it is run without `--headless`. It writes `sheet.png`, `process.png`, `sheet.json` and the stills in `stills/`, and closes its window by itself after about a minute (66 seconds in our run). With `--fixed-fps 60 --disable-vsync` added it took 7 seconds. Three runs, one with those flags and two plain, gave the same share for every pair of the tables below and for every step of the strip. The two pictures differed by a few bytes from run to run, and in one plain run one number the lesson does not quote differed by 0.01 (the part of one pair's difference that lies inside both outlines). The files shipped are from the plain command. It ends with two lines `ERROR: Texture with GL ID of …: leaked 349524 bytes.` after `sheet.json written`; the kit base's own sheet printed the same two lines in a copy, and the files are whole.

## The planted bug, and what the outline had planned

The outline planned: "the ray's target_position left at its local default (0, -1, 0), so on a rotated hip it points sideways and the foot steps into the air". The first half is what happens. A new `RayCast3D` has `target_position` (0, −1, 0), counted in its own axes. On a hip turned a quarter about z it looks level: (0.71, 0, −0.71) in the room for the first leg. It finds nothing. The second half is not what happens. `get_collision_point()` on a ray that never had a hit returns (0, 0, 0), and the lesson's first `find_ground()` takes that point: all four feet are sent to the room's origin, the body glides to (0, 0.4, 0) and stays, with its feet in one point 0.18 m under the ground there. Godot logged no error and no warning. A ray that had a hit and now has none returns its last hit point. The repair is `ray.target_position = ray.to_local(ray.global_position + Vector3.DOWN * 2.0)` and an `if ray.is_colliding()` around the taking of the point.

One more message is named in the lesson: `look_at()` straight down with its default up logs `WARNING: Target and up vectors are colinear. This is not advised as it may cause unwanted rotation around local Z axis.` and goes on. The leg hands `look_at()` the hip's own z.

## The argument, as measured

Axis `segments`: 1, 2, 3 and 6 parts, the leg 0.8 m every time. The creature stands on the most uneven place of the ground (two feet on the floor, two at 0.15 and 0.22 m), photographed from the side, 0.5 m above its middle and 2.2 m away, and from straight above. A still is 960 × 720; two stills differ at a pixel when the three channels together are more than 25 of 255 apart.

| pair | from rest | on the flat floor | after a walk of 1.2 m | from above |
| --- | --- | --- | --- | --- |
| 1 and 2 | 6.55% | 6.55% | 5.72% | 2.80% |
| 1 and 3 | 6.66% | 6.80% | 5.56% | 2.84% |
| 1 and 6 | 6.59% | 6.84% | 5.09% | 2.47% |
| 2 and 3 | 5.44% | 4.74% | 4.67% | 1.53% |
| 2 and 6 | 4.76% | 4.42% | 4.64% | 1.40% |
| 3 and 6 | 3.03% | 1.94% | 4.61% | 0.50% |

The closest pair is 3 and 6 in all four, as the outline predicted; after a walk it is closest by 0.03 of a percent. The outline's reason, that both bend smoothly, did not hold: the sharpest bend from rest was 112.4° with 2 parts, 113.2° with 3 and 74.9° with 6, and after the walk 112.4°, 111.0° and 165.0°. A leg of one part ends 0.20 to 0.36 m past its foot's place, under the ground, and never above it. With 2, 3 and 6 parts every leg's end was on its place to the millimetre when standing. Walking over the uneven ground the ends were 0.339, 0.006, 0.008 and 0.005 m from their places on average. The creature walks equally far with all four.

## What was and was not checked

**Checked, headless, by `verify.gd`** (107 of 107 on a fresh copy with no `.godot/`, in real time and with `--fixed-fps 60`): the project's name and main scene; the 15 supplied files; no `class_name` and tabs in every script; the files of the kit; a leg of 1, 2, 3 and 6 parts, its length and its lay; `follow()` on a place within reach (within 1 mm after 2, 2 and 4 calls), with every part's length kept and the chain's upper end on the hip; one part, which ends 0.259 m past a place 0.541 m away; a place out of reach; a straight leg over a place 0.6 m under its hip, which does not bend and ends 0.200 m past it; the loop alone, which led the hip's end 1.64 m after a foot carried 2 m and laid it down; the warning of `look_at()`; `find_ground()` on a turned hip, with a lead, past the floor's edge, on a first look that finds nothing, and against `height_at()` (within 0.013 m: the mesh has a corner every 0.2 m); the unrepaired ray; the creature standing, walking 2.78 m in 8 seconds, each arrived foot on the ground under it, the body 0.4 m over its feet; the turn at the floor's end (it got to x = 3.45); the leash; the four values of the axis walking the uneven ground; the plank with `ground` 1 and 3; the walker on the ground, through the plank, against the creature, under a foot's ray; the marble through the plank and on the creature's back; the walker carrying a foot; `carry.tscn`; the guest alone, pacing, inside 1.6 m, with a marble on it and with a rider.

**Checked with a window, by `sheet.gd`,** and both pictures looked at: `sheet.png` (1292 × 754) and `process.png` (2264 × 266), on an NVIDIA GeForce RTX 3070 with the Compatibility renderer. Five stills of the scenes as they run were taken in a scratch copy and looked at, to check what the lesson says is seen: `legs.tscn` walking, the walker walked into the picture by a held D, the view through its eyes, `carry.tscn` with its readout, and the planted bug with its four level rays. They are not shipped.

**Every code block of TUTORIAL.md** was taken off the page by a script and applied in page order, each state run in a copy of the kit: one part follows (D held: the lowest part sits on the hand, the two above do not move), the loop (the leg leaves its post), the hip holds, the ray as it comes (on the unturned hip of `carry.tscn` it found the floor straight under the hip), four legs under one body (the knot at the room's middle), the `print` line (23 lines of `false (0.0, 0.0, 0.0)` in 5 seconds), the repair, and the two lines of *Place*. The last state equals `leg.gd` and `creature.gd` byte for byte.

**Negative tests,** in scratch copies, one fault at a time; each failed `verify.gd`, and a copy with nothing planted passed: the unrepaired `find_ground()` of the lesson (the planted bug, 14 checks failed); the point taken without `if ray.is_colliding()` (1); `follow()` without its last two lines (7); `look_at()` without its second argument (1); `segments` set after `add_child()` (4); a guest that preloads `res://supplied/look.gd` (1); a guest that declares a `class_name` (2).

**The room.** In a scratch copy of `my-room`, with `guests/legs/` copied in and its line added, the room's `guest_trial.gd` passed 8 of 8: the room ran 180 frames with no error, the guest stood at place 2, the walker reached the aisle and then walked at the guest and was stopped by its trunk, 0.54 m from the middle of the place. The two room tasks of the lesson were run in two more copies: with the example guest as `rider` a marble rested on it at 1.08 m and the walker was stopped; with the walker as `hand` the creature left its place and followed the walker 3 m.

**Not checked.** Nothing was run in a headset and no XR node is in the kit: "carry the foot" is done by the walker and, in `carry.tscn`, by the keys. Nobody walked the walker or carried the hand with their own hands on the keys: the autopilot and actions pressed from a script did. The editor's windows were not watched: the Inspector's row of layers for `ground`, the Scene dock, F5 and F6. The run with the debugger attached was not made, so "Godot logged nothing" means our headless runs. The hall was read from `commons/maps/VFM_09_Legs/map_data.json`, the walkers' scene files and the registry, not walked. No person judged which legs look alike: every likeness is a count of pixels. No learner has used this kit.

**Known and left.** A leg hanging straight over its foot's place never bends: the loop keeps a straight chain straight. The creature's turned hips avoid it, and the lesson says so under *What the leg owes*. The walker of `legs.tscn` starts outside the fixed camera's picture, at the front left, so that it does not stand in front of the creature; its shadow shows, and the lesson says how to walk it into view. The guest's foot marks are balls of 4 cm centred on the floor, so its lowest point is 4 cm under the ground. The creature's trunk stays level whatever its feet stand on, and it walks sideways and backwards without turning.
