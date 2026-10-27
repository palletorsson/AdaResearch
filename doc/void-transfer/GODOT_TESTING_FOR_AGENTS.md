# Godot screenshots and transfer checks for Claude and Codex

Verified against this checkout and installed Godot 4.6 on 21 October 2026. Start in `C:/Users/palle/Documents/GitHub/AdaResearch_46`. This is the current **Void transfer** workflow; the older museum capture guide remains useful for examining the source museum.

## Quick route

Use existing tools before writing another capture harness. Run these **one at a time**, after the assigned floor fragments have been integrated and the coordinator has released the Godot slot:

```powershell
Set-Location C:/Users/palle/Documents/GitHub/AdaResearch_46
$env:GODOT_EXE = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
$env:PYTHONIOENCODING = 'utf-8'

python tools/audit_void_transfer.py wavefunctions_02
python tools/test_transfer_native.py wavefunctions_02
python tools/export_void_trial.py wavefunctions_02
node tools/test_void_transfer_editor.cjs wavefunctions_02
```

Replace `wavefunctions_02` with the registered trial ID. These are not arbitrary map-name commands. The trial needs its inventory, layout, rooms, scene and a `probe.gd`. The editor test additionally needs the encyclopedia server on port 3003 and a fresh exported manifest. It makes a temporary saved edit, checks the project and Desktop mirror, then restores the original arrangement using revision checks. Run it without concurrent user editing of that trial.

The native test and export runners now acquire the same OS file lock before
staging or launching Godot (`tools/void_native_slot.py`). Concurrent invocations
queue for up to twenty minutes. A crashed process releases the lock automatically;
do not delete `ada_run/void-native.lock`. The batch slot note still coordinates
ownership, but the file lock prevents overlap between back-to-back jobs. Manual
Godot launches and old runner processes started before this change do not use it.

- **Source audit:** IDs, configs, registered scene paths and hashes of inventoried sources. It does not prove fit or interaction, and does not independently compare every scale/height value: review those against the original token too.
- **Native test:** actual Void game, desktop input and synthetic XR trackers, screenshots, live bounds, residency and retry. Read the focused checks to know which controls are covered.
- **Export:** real built geometry and labels to `../ada_encyclopedia/public/void-trials/<trial>/manifest.json`. These are static web previews; native Godot retains interaction and shader behaviour.
- **Editor test:** independent move/copy/rotation and save/reload to the native JSON and `C:/Users/palle/Desktop/Ada Void/trials/<trial>/rooms.json`, including stale-save rejection.

Do not run those tools against a colleague's half-integrated trial. Until integration, review your owned `floor-N.json` and supply a proposed probe/check list.

## True headless is for checks; screenshots require a renderer

The installed executable's `--help` reports `--headless` as the headless display driver plus Dummy audio, with a **dummy rendering driver**. It is suitable for parsing and non-rendering checks. Do not expect useful viewport screenshots from it, or wait indefinitely for `RenderingServer.frame_post_draw` in a no-render process.

Our current native runner uses a real **Mobile renderer**, `--xr-mode off`, `--fixed-fps 60`, and a rendered viewport. It also passes the legacy `--no-window` argument, which this installed build does **not list in its help**. Do not rely on that argument to guarantee an invisible window. `CREATE_NO_WINDOW` suppresses a console, not proof that a GPU-rendered window cannot appear. Treat this as unattended rendering and coordinate focus with the user and other agents.

The working runner command is assembled in `tools/test_transfer_native.py`:

```text
Godot_v4.6-stable_win64.exe --no-window --path <isolated-stage>
  --rendering-method mobile --xr-mode off --fixed-fps 60
  --script res://commons/void/trials/<trial>/probe.gd
  -- --no-bridges --capture --out=<trial-evidence-directory>
```

Engine flags go before `--`; probe arguments go after it. Use the Python wrapper: it creates the proper staged project, captures the log, removes an old receipt, has a bounded subprocess timeout, and rejects runtime errors even when Godot exits zero. Do not launch this probe directly against the live project save identity.

The exporter currently defaults to `gl_compatibility`. That makes its material previews approximate; a GLB snapshot is not a renderer-parity test. Do not change the game's renderer merely to get an export.

For a small parse check, here is a bounded Python call from PowerShell. It runs no scene and takes no screenshot:

```powershell
@'
import os, subprocess
cmd = [os.environ['GODOT_EXE'], '--headless', '--path', '.',
       '--xr-mode', 'off', '--script', 'res://commons/testing/check_compile.gd',
       '--', '--files=res://commons/void/pendulum_wave_local.gd,res://commons/void/oscillation_curve_local.gd']
p = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8',
                   errors='replace', timeout=45, creationflags=subprocess.CREATE_NO_WINDOW)
print(p.stdout)
print(p.stderr)
bad = p.returncode != 0 or 'SCRIPT ERROR' in p.stdout+p.stderr or any(
    line.startswith('ERROR:') for line in (p.stdout+p.stderr).splitlines())
raise SystemExit(1 if bad else 0)
'@ | python -
```

`check_compile.gd` checks `can_instantiate()`, not just whether `load()` returns an object. A parse pass still does not prove runtime behaviour.

## Reuse the screenshot and input helpers

### Debug one interaction before repeating acceptance

The runner now supports named diagnostic cases and one input mode:

```powershell
python tools/test_transfer_native.py wavefunctions_04 --focus gallery --mode xr
python tools/test_transfer_native.py wavefunctions_04 --focus metallophone --mode desktop
```

These cases are implemented by `wavefunctions_04/probe.gd`. Other probes opt in by
overriding `debug_cases()` (case name to floor number) and `run_debug_case(name, tag)`.
Unknown cases fail. A diagnostic starts the real trial, visits the named floor and
runs only that interaction. It skips screenshots, descent, retry and unrelated
checks. Some neighbouring floors still load normally: this is a shorter test, not
an isolated replacement for the game.

Results go to `evidence/debug/<case>-<mode>/`, with `acceptance: false`, the exact
scope, engine errors and elapsed seconds. They never replace `evidence/checks.json`
or its screenshots. Before a rerun, a failed receipt and its engine log are copied
to that output directory's `failures/<timestamp>/`. `--mode` without `--focus` is rejected. After the diagnostic
passes, run the ordinary command with no filters for full desktop **and** synthetic
XR acceptance. Export/editor checks follow when the geometry/layout changes.

Use this loop: parse → diagnose one failure → rerun that case → full acceptance.
Do not repeatedly run every floor just to inspect the same hand-position error.

### Shared real-input helpers

All transfer probes inherit these from `tools/probes/void_transfer_probe.gd`:

| Helper | What it does |
|---|---|
| `input_aim_camera(world, frames)` | Reapplies desktop aim during settling; the last aim is immediately before input. |
| `input_palm_at(world)` | Moves the synthetic tracker while compensating for the real palm/aim offset. |
| `input_grab_preflight(body, shape)` | Reads the active mode's grab mask, body layer, pickup methods and collider. Does not repair the object. |
| `input_grab(label, body, shape, lift, hover)` | Real mouse/grip pickup; logs hit/closest object and movement, requires the named target. XR lifts, crosses above the display and stops within grab range above the collider. Defaults: 0.5 m lift, 0.2 m hover. |
| `input_tip_to(tip, target)` | Aims an already-held tool. Desktop solves the camera-relative tip offset and hold distance; XR moves its tracker. Unreachable desktop geometry fails explicitly. |

Use the actual `CollisionShape3D`, not the enclosing scene's origin. Pass a
different lift/hover where an exhibit requires it. The helper does not disable
collisions, teleport an artifact, invoke `pick_up()` or trigger an instrument
directly. Tool-tip steering still uses the desktop hold-distance setting and
synthetic trackers; assert the resulting strike/action separately. The full
`wavefunctions_04` probe is the reference consumer; do not copy its old aim loops.

Read `tools/probes/void_transfer_probe.gd` and a recent concrete probe, such as `commons/void/trials/wavefunctions_02/probe.gd`. Reuse the shared start/visit/report helpers rather than copying a large game implementation. The shared probe already loads the real trial, sets a stable sky time, makes synthetic trackers, visits floors and restores the visitor camera.

A concrete probe's `capture_floor()` can call:

```gdscript
var y: float = game.building.spec.levels[level]
await photo("01-encounter", Vector3(-1, y + 2.6, 10), Vector3(-9, y + 1.4, 4))
```

Those coordinates are an example, not universal framing. Use the real floor elevation and measured artifact bounds. For an artifact-local view, transform both camera position and target through the actual script-bearing artifact, not an outer placement wrapper. Add an eye-height view when access matters; elevated overview photos cannot establish reachability.

The underlying `photograph()` creates a temporary `Camera3D`, uses the game's environment, waits several frames and `RenderingServer.frame_post_draw`, saves the viewport PNG, and restores the game camera. If writing a new helper, also fail on a missing/empty image or failed `save_png()` return. Confirm the PNG exists, has nonzero dimensions and visually shows the intended exhibit.

Wait for **actual readiness**, with a bound: expected children/body count, constructed controls, populated MultiMesh, and completed deferred setup. Physics frames alone do not guarantee enough process frames. Batch 22's colour balls spawned one body per process frame; native rendering worked while early exports contained zero meshes. The exporter now waits for that construction to finish.

For controls, use the existing mouse/XR input helpers and assert a resulting state change. A direct method call or slider API check can be useful, but label it as such. Animation alone does not establish grabbing, collision, rider transport or reachable controls. Synthetic XR is **not** a physical-headset test.

## What makes a stronger transfer handoff

For each original placement, answer: what scene and source token is this; what does it actually do; where is its supported interaction; what support or external provider does it depend on; what did you measure or run? Keep original configs, scales and exported scene settings. A script adapter must preserve the scene's overrides, not silently reset them to script defaults.

Check these seams before saying a floor is ready:

1. **Local versus world:** floors are below world zero. Respawn thresholds, projected trails, world-origin fields and `global_position` assumptions need checking. Test after moving/rotating the placement, not only at the source origin.
2. **Complete bounds:** include children, collision, animated sweep and guide geometry, not only the main mesh. Compare against the slab, upper slab, pillars, shafts and neighbouring works. Shaft-centre ray checks do not prove the whole opening is clear.
3. **Support and access:** preserve token height, then report a missing plinth, ramp or grid support. A 1.1 m raised deck needs an access route; a photo from above is not evidence of one. Keep the standard floor size and flag unavoidable conflicts.
4. **Dependencies:** inspect config readers and autoloads, scene cameras/lights, providers, MultiMeshes, materials and asynchronous construction. Loading a scene is not proof its intended configuration is consumed.
5. **Honest missing content:** do not invent an instrument to fill an empty original. Batch 22's BigPipeSystem ignores its `path` token and has `auto_build` off; it is preserved with an explicit editor marker. Call that a marker, not a completed pipe.
6. **Source meaning:** preserve the original artifact, but distinguish a scripted demonstration from a solver. Forge's target interpolation and its sine-driven Q display are not emergent optimization.

Specific corrections to Claude's last handoff: the Unit Circle colour-ball adapter was not active until coordinator review; the wave pool's 13 m deck bounds excluded additional waveguide rings. These are useful examples of why source-reading conclusions should be labelled **static inference** until verified in the running trial.

Deliver a small table: placement ID | action or animation | evidence | fit/dependency | remaining work. Include exact files changed, source counts/hashes, original scale/height comparison, screenshot paths, command and result, error log, and untested claims. Separate "placed", "native verified", "editor verified" and "curated". Never call a floor curated just because it loads.

## Shared-machine discipline

### Known traps from batch 23

| Symptom | Check before changing the artifact |
|---|---|
| A ray hits the mesh/body, but grab finds nothing | Compare the **actual grab mask** with the body's layers. An all-layer ray is not equivalent. Desktop and XR masks differ; layer 1 alone is not a grab layer. |
| XR picks a neighbour or pushes the target away | Log the live collider, body displacement and `closest_object` before grip. Lift clear, cross above, stop within pickup radius. Driving the physical hand into a lightweight object is not a neutral test. |
| Long held tool misses despite more waiting | Solve the grip-to-tip offset; check reach. Standing too close can make the requested tip pose geometrically impossible. Check tip error and overlapping strike bodies before diagnosing the instrument. |
| Desktop aim changes between frames | Live mouse motion can still reach a captured test window. Re-aim and log the actual pointer result; avoid native UI automation while that test owns focus. |
| XR Tools fails before the test starts | An early static XR Tools class reference can pull in a script before its autoload is available. In CLI probe discovery use `has_method()` or load after startup; do not disable XR to hide the error. |
| Jolt rejects a bar with all six axes locked | A stationary table bar should use a scoped static/frozen-body adapter. Preserve its strike areas, tuning and audio. Do not change global physics settings to silence the error. |
| Correct config token, wrong apparatus | Trace the token into the property actually consumed during `_ready`; `config` metadata alone did not select GlassRack's `config_file`. |
| Slider moves, but sound does not change | Check signal argument count, callback execution and the actual voice players. Changing a parent player's volume need not change its child synth voices. |

Classify a failure before rerunning: **probe geometry/input**, **source/host
compatibility**, **readiness**, or **external input**. Preserve the failed log and
write the observation that distinguishes them. A green check on a different
neighbouring object does not establish that the intended one can be grabbed.

Coordinate one Godot job at a time; do not steal focus during another worker's desktop-input check. Parallelize source inspection and owned floor fragments, then serialize native rendering and mutable editor-save tests. The stage isolates the save identity (`Ada Void Trial Test`), but its source folders and imports are shared through junctions: it is not a separate checkout.

`ada_run/void-trial-runtime` contains many junction-backed stages. Do not recursively scan or delete it, and do not broadly walk ignored files from the repository root. Use explicit paths. See forum thread `261021-ymsk3`; stage lifecycle cleanup is a separate unresolved issue, not fixed by this guide.

The native suite has a 420-second overall timeout, export 300 seconds. These are existing bounded suite limits, not permission for an unbounded capture. For a new one-off capture use `tools/godot_watchdog.py --expect=<fresh-output-file-or-directory> -- <command>`; its defaults are 45 seconds to first output and 16 seconds of stalled output. Report a timeout, retain its log and diagnose before repeating. The current full-suite runner does not use that per-output watchdog, so do not claim that it does.

Keep writes inside the assigned files. Shared catalog, adapters, merged `rooms.json`, export and final acceptance have an explicit owner. No broad stashes, resets or commits over other agents' work. Current scope is transfer first: leave chapter texts and curation for later.

## Evidence and follow-up

The original guide used batch 22 evidence in `commons/void/trials/formfinding_03/evidence/` and `commons/void/trials/wavefunctions_02/evidence/`: 324 source checks, 254 native checks and 38 editor checks.

The batch 23 helper follow-up ran fresh checks on `wavefunctions_04`: gallery XR
diagnostic **10 checks / 18.62 seconds**, metallophone desktop diagnostic
**10 checks / 21.06 seconds**, then full desktop and synthetic XR acceptance
**145 checks / 77.67 seconds**, exit 0 and no engine errors. These are measured
native-run times on this machine, not promises for other floors; stage creation
is outside that timer. Focused runs left the prior full receipt unchanged.
The full run adds four grab preflight checks to the previous 141; it does not
represent four new artifacts or newly tested gameplay features.

Runner guards were also exercised: an unknown case was rejected twice; its
first failed receipt/log were archived before the retry; the full acceptance
receipt remained byte-identical. CLI rejects `--mode` without `--focus` and
path-like focus names before launching Godot. Guard evidence:
`doc/void-transfer/2026-10-21-batch-23/input-helper-guards.json`.

Both shared scripts passed the headless compile check. Artifact geometry and
layout were unchanged, so this follow-up did not repeat export/editor-save tests.
The existing staircase/slab conflict and headset limitations remain. The XR hand
can still move lightweight bodies during approach (the wrapped surface moved
0.67 m in full acceptance); the helper records this rather than concealing it.
Read `checks.json` and `engine.log`, not just the last terminal line.

- Review: http://localhost:3003/book-review/doc/book/iterations/2026-10-21-void-transfer-batch-22/index.html
- Source-museum guide: `doc/book/handoffs/claude-museum-screenshots.md`. It explains actual museum assembly versus isolated/catalog previews; some older command advice must be read in light of the renderer distinction above.
- Read the forum at session start: `python tools/forum.py open`. Reply to the guide thread with measured failures or corrections so the next agent benefits.
