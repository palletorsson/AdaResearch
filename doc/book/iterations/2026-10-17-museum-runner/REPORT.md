# Museum Runner — a point leaves its plinth

17 October 2026; controls and shooting updated 18 October. Playable endless-runner mode in the existing Endless Museum project.

## Play

Main menu → Museum Runner. Alternatively run `commons/museum_runner/museum_runner.tscn` with F6. A/D or arrows change lanes; Space jumps, starts or retries. Aim with the mouse and hold left click to shoot. P pauses; R retries the same seed; N gives a new course; M returns. Buttons work with the mouse without capturing lane keys.

In VR, either joystick is intended to steer left/right, repeating a lane change every 0.26 seconds while held. Aim either controller and hold its trigger to shoot. A/X starts, jumps or retries; B/Y pauses/resumes; Menu leaves. The sphere runs while the viewer remains centred at an overlook. The tracked camera is not driven by the runner: the headset still controls looking and leaning. The scenery moves; VR comfort has not been tested.

Tall pale cubes block until shot; low pink beams can be jumped or dodged; small golden cubes add 25 points. Metres add one point each. A collision ends the run, and best score is retained through retry, new course and reopening. It is stored separately from museum progression.

## Shooting selected forms

Mint diamonds mark lane cubes, side cubes and tetrahedra. An aiming line and dot turn mint over a breakable target. A shot stops at its first physical obstruction, so a pink beam protects an object behind it. One hit hides a marked form and removes its collision before the runner's swept collision check. Beams, pickups, columns and gates retain their existing roles.

The effect is a short ray flash and eight small cube fragments, not simulated mesh fracture. Each hand fires at most once per 0.22 seconds; holding the trigger repeats. Sixteen effects is the hard bound. Released input, pause and collision stop firing. Retry clears effects and counters. Broken bodies remain inert until their section is recycled, avoiding references to freed bodies. Breaks are shown separately from the unchanged distance/pickup score.

The new target script lives alongside the runner and works through its explicit type. There is no museum-wide destruction policy. The native harness initially caught a type-test failure despite a real ray hit; runtime instance checking now verifies the selected target class. The regression exercises the real collider removal and the runner passing through the cleared route.

## Joystick regression — 18 October

The earlier joystick checks called `steer_axis` directly. They did not prove that XR input reached that function. A new regression registers two XRControllerTracker instances with XRServer, sends the actual `primary` action through the scene's XRController3D nodes, and observes the running sphere's position.

Before the repair, right-stick input reached the node but could not steer: only the left stick was read. Either stick was also ignored when the startup rendering flag was false. The corrected physics loop reads both controllers independently of rendering mode. The larger horizontal deflection wins; left wins an exact tie, so opposing sticks cannot fight in one frame. No action map or global movement provider was changed.

Tests check both directions, held reversal, release, vertical input/drift, opposing sticks, pause and controller disconnection. They run at 60 Hz in the native harness and 90 Hz in the isolated exported package. Failing pre-fix evidence is retained in `joystick-before-checks.json`. These are synthetic XR inputs through real Godot nodes, not a physical thumbstick test. USB inspection confirmed that the connected Quest 3 runs the museum and initializes OpenXR, but the installed build's logs do not record joystick values; they cannot establish which failure the wearer experienced. The follow-up below records the later physical retest with the diagnostic build.

## Physical Quest follow-up — ball steering confirmed

The original report confirmed A/X starts the course and distance increases, ruling out the READY gate at start. After installing revision `2026-10-18-origin-input-2`, the wearer answered: “Yes—the ball changes lanes.” The retained Quest log contains 107 RUNNING samples: the right stick reaches 0.99988, the ball moves between X=-2.1 and X=2.1 through all three lanes, and the runner origin is current throughout. The left stick is idle in this retained window. See `headset-input.json` and `headset-build.json` for the scope and evidence. The installed Android `game.gdc` was extracted and tested separately with local dependency scripts: both synthetic hands move the ball to X=2.1, in either rendering-mode flag. `installed-script-check.json` records this limited check. That earlier installed game already included the two-stick steering logic; this isolated check did not establish physical controller behaviour.

A separate regression found that the runner override centered the camera without transferring the current XR origin from staging. Scene entry now calls the inherited XRTools handoff. `origin-before-checks.json` records its failure before the fix. This is a real lifecycle omission, but it has not been established as the cause of the physical input failure.

An opt-in diagnostic (`user://museum-runner/input-debug.on`) shows left/right stick X and the ball lane in the headset, and records raw tracker values alongside controller values, per-second peaks, state, distance, lane, ball X, buttons and the current-origin flag. The bounded log keeps 120 one-second samples in `user://museum-runner/input-debug.json`. The startup revision is `2026-10-18-origin-input-2`. Removing the marker and reopening the mode disables logging. Both the native and exported tests check that the recorded action values and running state match the synthetic controller input. After the physical capture, the diagnostic marker was removed; logging and the temporary readout stop on the next entry. The active play session was left running.

## How the museum becomes material

The protagonist takes its mesh from the tested PointBody lesson and receives a new CharacterBody3D running behaviour. Tutorial BoxBody becomes floor tiles, hazards and pickups. LineSkin becomes rails, triangle gates and a bounded movement trace. FaceBody makes the tetrahedra. The actual resolution_totem generator makes the columns, using 4/6/8/12/16 sides and varied profiles. Their source files were reused unchanged.

Every 108 metres the visual section changes: Point / Line → Face / Body → Transformation → Array / Colour. This is an application of the museum's material, not a new tutorial order or a claim that running through it teaches the algorithms. The first version changes scenery and layout across those sections; new chapter-specific mechanics remain future work.

The previous Shadow Game and existing walking SpineRunner remain separate. The runner shares the project's main menu and XR staging. Its small added input scope suspends the global mushroom-throwing system for this mode, then restores it.

## Generation and retained state

Each 36-metre section has three rows generated from a reproducible seed/index recipe. Every row leaves at least one lane clear. Clear lanes move at most one step within a section. Even at the 10 m/s speed cap, row spacing leaves enough movement time for a two-lane transition. This is a geometric reachability check, not a measured human reaction-time guarantee.

The sphere has a real floor collider and gravity-driven jump. Swept physics queries compare its shape with the moving course using relative motion; thin beams cannot simply be skipped between endpoints. Pickups use a separate collision layer. Tall cubes are too high for the configured jump; the low beams can be cleared.

Visible geometry remains near the origin. Retired section nodes are freed, and at most seven are retained. The trail is capped at 32 segments. High score is the persistent state; the full course and trace are not saved as a student artifact in this first runner.

## Evidence

**93/93 assertions passed. Native process exit: 0.** See `checks.json`, `process.json`, `stdout.log` and `receipt.json`.

**Packaging repair: 52/52 exported-runtime assertions passed.** The runner originally preloaded four lesson scripts from `doc/`, which the Quest preset excludes. That caused missing-resource parse errors (including failed inference of `segment`) and left a plain Node3D where staging requires XRToolsSceneBase. Earlier native tests could read the loose documentation files, so did not detect this. The runtime now includes byte-identical lesson sources under `commons/museum_runner/forms/`, with recorded provenance. No game rules or staging types were weakened.

The regression exports a small Windows PCK using the Android preset's include/exclude filters and compiled-script mode. A separate runtime folder contains only the package, with no source tree to fall back to. Checks verify that documentation is absent, the scene retains the required staging type, every visual chapter builds, the sphere grounds correctly, controller signals start/pause play, and a controller shot destroys a real target. Hash checks confirm the four form sources still match their recorded lessons. See `package-receipt.json` and `package-checks.json`. This is a runner dependency package, not a full museum APK or physical headset test.

The package regression now also includes Shadow Game's actual encounter. The same excluded lesson dependencies had prevented `Encounter.new()` in its `world.gd:44`. Shadow Game now shares the runtime form builders. Eight additional checks cover encounter construction, three pickable bodies, real buttons, the shared point class, cube placement, held-stick bridge opening, visible trace and crossing completion. These are part of the packaged-runtime count above. Shadow Game's full world is checked separately by its native harness.

Checks cover 6,000 generated rows, stable/changing seeds, lane bounds, real grounded state, keyboard and XR input adapters, collision versus jumping, jump re-entry prevention, one-time collection, swept thin-beam detection, pause, retry, score storage, live steering and bounded streaming over 200 additional sections (7.2 km). Shooting checks cover both controller signals, joystick repeat/deadzone, real ray hits, collision removal, first-hit obstruction, tetrahedra, fire rate/release, HUD mouse release, pause and bounded feedback. A rule-following synthetic pilot survived over 65 metres of the actual movement loop. The long-distance recycling test advances section state directly; it is not a claim that a human played 7.2 km.

Menu verification uses the actual main-menu scene, signal and routing callback with a lightweight test staging host. It verifies the requested path and return callback; it does not repeat a full application launch. Releasing that existing menu produces 40 renderer null-material messages in this run. The runner checks complete, but these messages remain a menu teardown issue. ObjectDB leak warnings are also retained in the log. No GDScript error is intentionally suppressed.

Initial checks found a duplicate jump request accepted before the next physics tick. The grounded jump now also checks upward velocity. The pilot originally turned out of a safe lane before its current obstacle had passed; its test driver now keeps the lane through the whole obstacle. Score assertions were corrected to test a retained maximum rather than equality with a shorter run.

All images are native Godot compatibility-renderer captures. Arrival shows the ready screen; jump is a controlled beam fixture; running is the live pilot run. Aiming/shooting use a synthetic controller pose and a real target; simulation pauses briefly to capture the short effect. The four chapter previews are placed at each section boundary by the harness and do not represent earned progress. No generated or retouched images are used as implementation evidence.

Not tested: human difficulty/readability, independent physical left-stick input, headset shooting and comfort, Quest performance, full-project regressions or long-session frame-time stability. The streaming bound is tested; a VR performance budget has not yet been established.

## Next useful change

Play the current loop before adding density. A timed moving obstacle would give Transformation a new decision. A repeatable construction rule could distinguish Arrays. Add one mechanic at a time while retaining the clear-route invariant and testing at maximum speed.

## Android delivery

Quest steering confirmed by the user; physical right-stick input and ball movement recorded across all three lanes. See [build and installation receipt](headset-build.json). The wearer confirmation and recorded physical input establish the steering result; installation alone would not.
