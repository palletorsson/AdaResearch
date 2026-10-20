# The Void

Playable rooftop + two floors of the unfinished tower. Launch the project (F5),
then choose **The Void** in the main menu. This uses the normal XR staging path.
For desktop-only iteration, open `void.tscn` and run the scene (F6).

## Controls

| Action | VR | Desktop |
| --- | --- | --- |
| Move | Left stick | WASD / arrows |
| Look / turn | Head + right stick (30° snap) | Mouse |
| Jump | Right A or trigger, once per press | Space |
| Retry saved floor | Right B | R |
| Restart on roof | Left Y | T |
| Main menu | Left X | M |
| Release mouse | — | Escape; click to capture again |

Land safely on a main floor to save it (0.18 seconds grounded). Temporary shaft
ledges do not save progress. Passing a floor's height does not save it either.
Falling outside the structure, below its bottom, or landing at 9.8 m/s or faster
causes death. Recovery fades out, moves the player to a safe position on the
saved floor, clears velocity, then fades in. Checkpoints last for this visit;
returning to the menu and entering again begins on the roof.

Shaft A has two staggered timber ledges per storey (two-metre drops). Shaft B
has one wide suspended platform (three-metre drops). Both descend to the same
main floors. A direct six-metre fall is fatal. The final floor completes this
prototype; another floor has not been built yet.

## Sources

- `layout.json`, `architecture.gd`: shared permanent frame, slabs, shafts,
  services and temporary landings. Roof rails have colliders; service pipes
  and braces remain visual details.
- `void.tscn`, `game.gd`: playable XRToolsSceneBase, scene-local checkpoints,
  death and recovery; no changes to museum progress/saves.
- `jump.gd`: edge-triggered jump provider. Uses the real XRTools body, direct
  movement and snap-turn providers. No grab/tools/flight in this prototype.
- `walker.gd`: desktop companion controller.
- `layout_viewer.tscn`: original architectural viewer, without game rules.

VR comes through the project's existing XR setup. Standalone Quest testing
requires exporting/installing the current project; no APK is built by the test.

## Verification

`python tools/test_void_game.py --package --capture --menu`

Real Godot 4.6 / Jolt collisions; synthetic XR trackers feed the real XRTools
body and controller providers. Traverses both routes, checks rail collision,
fatal impacts, repeated checkpoint recovery, tracking preservation and input.
The package test runs a Windows PCK with the Android preset's exclusions, from
an empty runtime directory. It is not an Android/headset performance test.

Menu integration runs the actual menu callback through a staging fixture,
plus initialization in the full project. The package also checks the typed
XRToolsSceneBase assignment required by the real staging loader. The menu's
existing null-material cleanup messages reproduce in a menu-only baseline;
they are recorded separately in the report rather than hidden.

Report: `doc/book/iterations/2026-10-18-the-void-playable/index.html`.
Physical headset comfort/reach and Quest performance still need playtesting.
