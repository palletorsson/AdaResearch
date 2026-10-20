# Museum Runner

A runner made from Endless Museum material, now played as four finite maps. Main menu → **Museum Runner**, or F6 on `museum_runner.tscn`.

The black point leaves its plinth. Choose one of three lanes, shoot marked cubes, jump pink beams and collect golden cubes. Reach the finish to win a map and save the next one. The same centred viewing rig and black sphere continue between maps.

| Map scene | Distance | Visual material |
|---|---:|---|
| `maps/point_line.tscn` | 108 m | Lines, frames, cubes and resolution columns |
| `maps/face_body.tscn` | 144 m | Triangular faces and marked tetrahedra |
| `maps/transformation.tscn` | 144 m | Angled cube targets and framed passages |
| `maps/array_colour.tscn` | 180 m | Repeated tiles and a coloured canopy |

Each scene supplies its own seed, length, starting speed and visual family. The scenes use the shared `runner_map.gd` builder. They replace one another inside the existing XR rig, so level transitions do not move the viewer or replace controller bindings.

## Win, fail and resume

- Crossing the finish saves the **next map and cumulative earned score**. Space or A/X then starts that map.
- A collision stops the attempt. Space, R or A/X restores the saved start of the current map, with its original layout and banked score. Cubes collected during the failed attempt are discarded.
- Closing and reopening resumes at the saved map, waiting for a deliberate start. Closing on the win screen keeps the next map unlocked.
- Finishing map four saves completion and offers a return to the museum; the sequence does not silently wrap around.
- Save writes use a temporary file followed by replacement. If that fails, the finish screen offers **Retry save** and does not claim that the next map was saved.

Checkpoints are runner-specific, in `user://museum-runner/best.cfg`. Existing best-only records migrate to the first map and retain the best score. Map IDs, rather than their display titles, identify saved progress. Museum/tutorial completion records are separate.

## Controls

- Desktop: A/D or Left/Right change lanes; Space/Up starts, jumps, retries or continues after a win. Aim with the mouse and hold left click to shoot. P/Escape pauses; R restores the saved checkpoint; M returns to the museum menu.
- VR: either joystick steers, repeating every 0.26 seconds while held. Aim either controller and hold its trigger to shoot. A/X starts, jumps, retries or advances after a win; B/Y pauses/resumes; Menu returns. The tracked viewer stays at a centred overlook, with natural head tracking. Physical steering was confirmed on the preceding build; the new map/checkpoint flow has separate test evidence.

## Selected targets

Mint diamonds mark breakable lane cubes, side cubes and tetrahedra. Each shot ray stops at the first floor, hazard or selected target. One hit hides a marked object and removes its collision immediately, so it can open a running lane. Pink beams remain obstacles; gold cubes remain collectibles. The columns and overhead frames remain scenery.

Each controller can fire once per 0.22 seconds. An aiming line and dot show where the shot will land; they turn mint over a selected target. A flash and eight short-lived cube fragments mark a hit. Effects are capped at 16 and cleared on retry. Broken bodies remain inert until their section is recycled. Breaks are counted separately; score remains distance plus pickups. Release, pause and collision stop held fire.

Score is banked points from completed maps plus this attempt's metres and 25 per golden cube. Best score is kept independently, even after a shorter failed attempt. A failure cannot inflate the checkpoint score.

## Museum material, precisely

- Sphere geometry comes from the actual tutorial PointBody, scaled for legibility. The game supplies a CharacterBody3D and sphere collider. This is a new running behaviour, not XR pickup attached to the moving sphere.
- Tutorial BoxBody supplies tiles, obstacles, pickups, plinths and side sculptures.
- Tutorial LineSkin supplies triangle outlines, lane boundaries and the short trail left by the sphere.
- Tutorial FaceBody supplies the tetrahedra in the Face / Body section.
- The museum's actual resolution_totem generator supplies columns with 4, 6, 8, 12 and 16 radial segments, varying profiles and height. Its original source is unchanged.
- Existing XRTools staging and controller nodes supply scene entry and hand input. The global mushroom-throwing hand is suspended only while this mode owns the trigger and restored on exit.

The four lesson builders are packaged under `commons/museum_runner/forms/`.
They are exact source copies with hashes and original paths in
`forms/provenance.json`. The runtime must not preload from `doc/`: that folder is
ignored by Godot and excluded from the Quest export. This fixes the missing
PointBody/LineSkin parse errors and the resulting staging scene-type failure.

The course makes those forms playable; it is not a claim that completing a run teaches their algorithms. Visual chapter names indicate reused material, not a replacement curriculum. The existing SpineRunner, museum route, tutorials and Shadow Game crossing remain available.

## Course and physics

`course.gd` generates three obstacle rows per 36-metre section from a seed and section index. Every row leaves at least one lane clear; its chosen clear lane changes by at most one lane within a section. At maximum speed, row spacing still allows crossing two lanes, including at section boundaries. Pickups follow the clear route. Optional beam jumps provide another choice.

The sphere moves horizontally and jumps under gravity using real floor collision. The course scrolls towards it. `cast_motion` checks the actual sphere against box colliders using relative motion, so a narrow beam cannot pass through between physics ticks. Pickup queries use separate Area3D shapes. Decorative columns and overhead frames do not collide with the runner.

At most five section nodes and 32 trace segments remain active in these maps. Old sections are freed; streaming stops at the current map’s finish. Tiles use MultiMesh instances. Nothing accumulates a full run-length world coordinate: visible geometry remains near the origin. Total distance is retained separately for scoring and the seed recipe.

## Verification

Run `python tools/test_museum_runner.py --render`. The added level suite checks win, retry, exact checkpoint scores, migration, invalid saves, real write failure/retry, reload into a fresh runner, finish/collision ordering and final completion. Use `--levels-only` to run that focused suite. The native harness checks generated-route constraints, real collision, jump/landing, pickup, pause, seed/retry, saved best score, streaming bounds and the menu callback. It also tests synthetic XRServer trackers through the actual XRController3D nodes and live physics loop (both sticks, reversal, release, drift, disconnection and pause), joystick repeat, real controller-signal shooting, target collision removal, protected obstructions, tetrahedra, fire rate, release and bounded effects. Test storage is isolated in `ada_run/museum-runner-test/`.

Also run `python tools/test_museum_runner_package.py`. It verifies the lesson
copies, exports a small Windows PCK with the Android preset's documentation
exclusions and script mode, then runs it in a directory containing no loose
source files. It checks the actual runner, all four visual chapters, controller
signals, the live XR steering test at 90 physics ticks per second, and the typed assignment required by XR staging. It also instantiates
Shadow Game's real encounter and checks the three shared bodies, bridge action,
trace and completion with documentation absent. It does not export an
APK or verify a headset. Early loose-file tests alone missed this packaging bug.

Current results and actual Godot captures: `doc/book/iterations/2026-10-18-runner-levels/`. The earlier `2026-10-17-museum-runner` report preserves the initial endless mode and physical steering diagnosis. Read the report for exact test counts and engine warnings. Synthetic input and a rule-following pilot are not a human playtest or evidence of headset comfort.

## Quest input diagnosis (18 October)

The original report was that A/X starts the course but neither physical stick steers.
After installing revision `2026-10-18-origin-input-2`, the user confirmed that the
ball changes lanes with the viewpoint centred. The retained headset log records
physical right-stick input and ball movement through all three lanes, with the
runner's XR origin current throughout. The left stick is idle in those samples;
both sticks pass the automated tests. See the report's `headset-input.json` and
`headset-build.json`. The diagnostic marker was removed after capture, so the
readout and logging stop on the next runner entry without interrupting play.
Scene entry now calls XRTools' inherited `scene_loaded` to transfer the current
XR origin from staging as well as center the viewer. A regression reproduces the
previous missing transfer. This omission alone is not proven to explain the sticks.

For a debug APK, create `files/museum-runner/input-debug.on` through
`adb shell run-as com.example.adaresearchzeroone touch files/museum-runner/input-debug.on`.
Reenter the runner. Its HUD then shows left/right stick X and the ball's lane.
`files/museum-runner/input-debug.json` retains the last 120 one-second samples:
raw tracker values, controller values, per-second peak X, game state, lane,
ball position, button evidence and the active-origin flag. The same samples are
printed with `[museum-runner-input]` in `files/logs/godot.log`.
The steering diagnostic build was `2026-10-18-origin-input-2`; the level build is `2026-10-18-level-checkpoints-1`. Remove the marker
and reenter to stop logging. No poses or museum saves are recorded or changed.

## Next useful step

Play through the four saved maps. Then add one museum operation that changes the decisions: for example a visibly timed translating obstacle or a rotating gate. Keep one reachable route, preserve same-seed retry and verify the new collider behaviour before increasing speed or density.
