"""Publish the runner's real native captures and bounded evidence."""
import hashlib
import html
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
checks = json.loads((HERE / 'checks.json').read_text(encoding='utf-8'))
process = json.loads((HERE / 'process.json').read_text(encoding='utf-8'))
assert checks['passed'] and process['clean_exit'], 'Native checks must pass before publishing.'
passed = sum(c['passed'] for c in checks['checks'])
count = len(checks['checks'])
package = json.loads((HERE / 'package-receipt.json').read_text(encoding='utf-8'))
assert package['passed'], 'Do not publish a failed package check as a verified fix.'
package_count = len(package['native']['checks'])
paths = list((ROOT / 'commons/museum_runner').glob('*.gd')) + [ROOT / 'commons/museum_runner/museum_runner.tscn', ROOT / 'commons/museum_runner/README.md', ROOT / 'tools/test_museum_runner.py']
paths += list((ROOT / 'commons/museum_runner/forms').glob('*'))
paths += [ROOT / 'tools/test_museum_runner_package.py', ROOT / 'tools/probes/museum_runner_package_probe.gd', ROOT / 'tools/probes/museum_runner_xr_input.gd']
paths += [ROOT / 'commons/shadow_game' / name for name in ['encounter.gd', 'point.gd', 'piece.gd']]
paths += [ROOT / p for p in ['commons/scenes/main_menu/MainMenu3D.gd', 'commons/scenes/main_menu/MainMenu3D.tscn', 'commons/artifacts/resolution_colonnade/resolution_totem.gd', 'doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Lines/point_body.gd', 'doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Lines/line_skin.gd', 'doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Triangle_Context/face_body.gd', 'doc/book/iterations/2026-10-16-scale-carried-frame/complete/box_body.gd']]
links = []
hashes = {}
for path in paths:
    relative = path.relative_to(ROOT).as_posix()
    hashes[relative] = hashlib.sha256(path.read_bytes()).hexdigest()
    target = HERE / 'sources' / (relative + '.txt')
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(path.read_bytes())
    links.append(f'<li><a href="sources/{html.escape(relative)}.txt">{html.escape(path.name)}</a></li>')
log = (HERE / 'stdout.log').read_text(encoding='utf-8',errors='replace')
receipt = {'status':'Quest ball steering confirmed by wearer and recorded physical input','updated':'2026-10-18','checks':checks,'process':process,'sources':hashes,'renderer_null_material_warnings':log.count('Parameter "material" is null.'),'physical_headset_tested':True,'menu_scope':'Real menu button/callback with a test staging host; full app transition not rerun.'}
receipt['package_verification'] = package
receipt['headset_observation'] = 'User confirmed ball lane changes after installing revision 2026-10-18-origin-input-2. The headset log records right-stick input, all three lanes and the active runner origin. Left-stick physical input, shooting and comfort are outside this captured check.'
headset_receipt = HERE / 'headset-build.json'
if headset_receipt.exists():
    receipt['headset_build'] = json.loads(headset_receipt.read_text(encoding='utf-8'))
(HERE / 'receipt.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
report = f'''# Museum Runner — a point leaves its plinth

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

**{passed}/{count} assertions passed. Native process exit: {process['exit_code']}.** See `checks.json`, `process.json`, `stdout.log` and `receipt.json`.

**Packaging repair: {package_count}/{package_count} exported-runtime assertions passed.** The runner originally preloaded four lesson scripts from `doc/`, which the Quest preset excludes. That caused missing-resource parse errors (including failed inference of `segment`) and left a plain Node3D where staging requires XRToolsSceneBase. Earlier native tests could read the loose documentation files, so did not detect this. The runtime now includes byte-identical lesson sources under `commons/museum_runner/forms/`, with recorded provenance. No game rules or staging types were weakened.

The regression exports a small Windows PCK using the Android preset's include/exclude filters and compiled-script mode. A separate runtime folder contains only the package, with no source tree to fall back to. Checks verify that documentation is absent, the scene retains the required staging type, every visual chapter builds, the sphere grounds correctly, controller signals start/pause play, and a controller shot destroys a real target. Hash checks confirm the four form sources still match their recorded lessons. See `package-receipt.json` and `package-checks.json`. This is a runner dependency package, not a full museum APK or physical headset test.

The package regression now also includes Shadow Game's actual encounter. The same excluded lesson dependencies had prevented `Encounter.new()` in its `world.gd:44`. Shadow Game now shares the runtime form builders. Eight additional checks cover encounter construction, three pickable bodies, real buttons, the shared point class, cube placement, held-stick bridge opening, visible trace and crossing completion. These are part of the packaged-runtime count above. Shadow Game's full world is checked separately by its native harness.

Checks cover 6,000 generated rows, stable/changing seeds, lane bounds, real grounded state, keyboard and XR input adapters, collision versus jumping, jump re-entry prevention, one-time collection, swept thin-beam detection, pause, retry, score storage, live steering and bounded streaming over 200 additional sections (7.2 km). Shooting checks cover both controller signals, joystick repeat/deadzone, real ray hits, collision removal, first-hit obstruction, tetrahedra, fire rate/release, HUD mouse release, pause and bounded feedback. A rule-following synthetic pilot survived over 65 metres of the actual movement loop. The long-distance recycling test advances section state directly; it is not a claim that a human played 7.2 km.

Menu verification uses the actual main-menu scene, signal and routing callback with a lightweight test staging host. It verifies the requested path and return callback; it does not repeat a full application launch. Releasing that existing menu produces {receipt['renderer_null_material_warnings']} renderer null-material messages in this run. The runner checks complete, but these messages remain a menu teardown issue. ObjectDB leak warnings are also retained in the log. No GDScript error is intentionally suppressed.

Initial checks found a duplicate jump request accepted before the next physics tick. The grounded jump now also checks upward velocity. The pilot originally turned out of a safe lane before its current obstacle had passed; its test driver now keeps the lane through the whole obstacle. Score assertions were corrected to test a retained maximum rather than equality with a shorter run.

All images are native Godot compatibility-renderer captures. Arrival shows the ready screen; jump is a controlled beam fixture; running is the live pilot run. Aiming/shooting use a synthetic controller pose and a real target; simulation pauses briefly to capture the short effect. The four chapter previews are placed at each section boundary by the harness and do not represent earned progress. No generated or retouched images are used as implementation evidence.

Not tested: human difficulty/readability, independent physical left-stick input, headset shooting and comfort, Quest performance, full-project regressions or long-session frame-time stability. The streaming bound is tested; a VR performance budget has not yet been established.

## Next useful change

Play the current loop before adding density. A timed moving obstacle would give Transformation a new decision. A repeatable construction rule could distinguish Arrays. Add one mechanic at a time while retaining the clear-route invariant and testing at maximum speed.
'''
if headset_receipt.exists():
    report += '\n## Android delivery\n\n' + receipt['headset_build']['status'] + '. See [build and installation receipt](headset-build.json). The wearer confirmation and recorded physical input establish the steering result; installation alone would not.\n'
(HERE / 'REPORT.md').write_text(report,encoding='utf-8')
gallery = ''.join(f'<figure><img loading="lazy" src="chapter-{i}.png" alt="Native generated view: {title}"><figcaption>{i+1:02} / {title}</figcaption></figure>' for i,title in enumerate(['Point / Line','Face / Body','Transformation','Array / Colour']))
page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Museum Runner — the point leaves its plinth</title><style>
:root{color-scheme:dark;--ink:#eee9e0;--rose:#efb2cf}*{box-sizing:border-box}body{margin:0;background:#171b2b;color:var(--ink);font:17px/1.65 system-ui,sans-serif}main{max-width:1240px;margin:auto;padding:48px 30px 90px}nav{display:flex;gap:25px;flex-wrap:wrap;font-size:14px;margin-bottom:42px}a{color:var(--rose)}.eyebrow{font-size:12px;letter-spacing:.18em;text-transform:uppercase;color:#b6bad5}h1{font-size:clamp(48px,7vw,91px);line-height:1.03;letter-spacing:-.05em;font-weight:500;margin:20px 0 26px}.lead{font-size:24px;color:#c2c7da;max-width:850px}h2{font-size:30px;line-height:1.2;font-weight:500;margin-top:52px}img{width:100%;display:block;border:1px solid #45485c}figure{margin:0}figcaption,.caption{font-size:14px;color:#b8bfd1;margin:12px 0 25px}.row{display:grid;grid-template-columns:repeat(3,1fr);gap:24px;margin:30px 0}.row article{border-top:2px solid #b995b3;padding-top:16px}.row h3{font-size:23px;font-weight:500;margin:0 0 12px}.row p{color:#bec4d4}.controls{background:#242a3d;padding:24px;border-left:3px solid #efb2cf}.gallery{display:grid;grid-template-columns:1fr 1fr;gap:24px}.files{columns:2}.files li{padding:4px}.small{font-size:14px;color:#b8bfd1}code{overflow-wrap:anywhere}strong{font-weight:600}@media(max-width:720px){main{padding:24px 18px}.row,.gallery{grid-template-columns:1fr}.files{columns:1}.lead{font-size:20px}}</style>
<main><nav><a href="#play">Play</a><a href="#material">Museum material</a><a href="#course">Four sections</a><a href="#evidence">Tests &amp; files</a></nav><div class="eyebrow">Endless Museum / joystick &amp; shooting update / 18 October 2026</div><h1>The point leaves<br>its plinth.</h1><p class="lead">Museum Runner. A black sphere, three lanes, and a world assembled from things we have already made.</p><img src="arrival.png" alt="A shiny black sphere at the start of a three-lane course, with pale columns, pink beams and triangle gates"><p class="caption">Actual Godot scene. Open the existing main menu → <strong>Museum Runner</strong>.</p>
<section id="play"><h2>Choose a line. Keep going.</h2><div class="row"><article><h3>Shoot a way through.</h3><p>Mint diamonds mark cubes and selected sculptures. Aim, shoot, and their collision disappears. You can still steer around them.</p></article><article><h3>Jump the beams.</h3><p>A low pink line can stop the sphere—or pass underneath a jump.</p></article><article><h3>Collect the small cubes.</h3><p>Gold cubes add points. A collision ends the run. Try again with the same seed and learn its arrangement.</p></article></div><div class="controls"><strong>Desktop</strong><br>A / D or arrows: lanes · Space: start / jump / retry · Mouse: aim and hold left click to shoot · P: pause · R: retry · N: new course · M: menu.<br><br><strong>VR</strong><br>Either joystick: steer (hold to cross another lane) · Aim either controller and hold trigger: shoot · A / X: start / jump / retry · B / Y: pause · Menu: leave. Your viewpoint stays at an overlook; the sphere runs.<br><span class="small">Ball steering confirmed on Quest; centred viewing position retained.</span></div><h2>Aim at the marked form.</h2><div class="gallery"><figure><img loading="lazy" src="aiming.png" alt="Native controller aiming line reaches a mint-marked cube"><figcaption>Before: a cube with its real collider, marked as a target.</figcaption></figure><figure><img loading="lazy" src="shooting.png" alt="Native ray and fragments after the selected cube is shot"><figcaption>After: the target disappears; the ray and fragments mark the hit. Its collider is removed too.</figcaption></figure></div><p>Lane cubes, side cubes and tetrahedra can break. Pink beams still stop a shot and must be jumped or dodged. Gold cubes remain collectibles. The screenshots use a controlled target and controller pose; the checks also verify running through the cleared space.</p><h2>The same beam, another possibility.</h2><img loading="lazy" src="jump.png" alt="The sphere jumps above a pink beam and leaves a pink trace"><p class="caption">Native collision-test capture. Grounded contact stops the run; this jump clears the same beam.</p></section>
<section id="material"><h2>The museum becomes a vocabulary for play.</h2><p>The sphere comes from PointBody. BoxBody supplies blocks and repeated tiles. LineSkin supplies rails, gates and the trail. FaceBody supplies tetrahedra. The columns use the museum's own profile generator, varying through 4, 6, 8, 12 and 16 sides.</p><p>These sources return with new game behaviours: movement, collision, collection, scoring and retry. Later sections can add new decisions to this small vocabulary.</p></section>
<section id="course"><h2>Four sections, then another return.</h2><p>Every 108 metres, a different family of forms appears. Speed rises gradually to a cap; sections are rebuilt ahead and released behind.</p><div class="gallery">__GALLERY__</div><p class="small">Native chapter previews positioned by the test harness. The first version changes the visual material and lane pattern; chapter-specific mechanics are a next step.</p></section>
<section id="evidence"><h2>What has actually been checked?</h2><div class="controls"><strong>Quest ball steering confirmed.</strong><br>After installing the updated build, the wearer confirmed that the black ball changes lanes with the view centred. The Quest log records right-stick input, movement through all three lanes and the active runner origin. <a href="headset-input.json">Physical input evidence</a>. Both sticks also pass automated checks, including at 90 Hz in the exported package. The retained physical samples contain no left-stick movement. The diagnostic marker has been removed; the temporary readout stops on the next entry.</div><div class="controls"><strong>Missing-script launch error fixed.</strong><br>The four form builders now ship with the game. <strong>__PACKAGE_COUNT__ packaged-runtime checks passed</strong> with the documentation folder absent, including the staging scene type and all four sections. <a href="package-receipt.json">Packaging evidence</a>.<br><span class="small">Use revision 2026-10-18-origin-input-2 for the scene-entry repair and optional input readout. Physical ball steering is now confirmed.</span></div><p><strong>__PASSED__/__COUNT__ native assertions passed.</strong> Joystick steering, both trigger signals, target destruction, protected obstacles, firing limits, physics collision and jumping, same-seed retry, pickups, pause, score retention, a live steering run and bounded generation. At most seven sections and 32 trail segments stay alive.</p><p class="small">The menu callback works with a test staging host. Existing menu teardown emits renderer warnings. Physical steering is confirmed; headset shooting, comfort and performance remain outside this check. <a href="REPORT.md">Read the complete report</a> · <a href="checks.json">Assertions</a> · <a href="receipt.json">Source receipt</a>.</p><ul class="files">__FILES__</ul></section></main></html>'''
page = page.replace('__PACKAGE_COUNT__',str(package_count)).replace('__GALLERY__',gallery).replace('__PASSED__',str(passed)).replace('__COUNT__',str(count)).replace('__FILES__',''.join(links))
if headset_receipt.exists():
    delivery = '<div class="controls">' + html.escape(receipt['headset_build']['status']) + '. <a href="headset-build.json">Build and installation receipt</a>.</div>'
    page = page.replace('<section id="evidence">', '<section id="evidence">' + delivery)
(HERE / 'index.html').write_text(page,encoding='utf-8')
print(HERE / 'index.html')
