# Claude handoff: taking images inside the actual Ada museum

Prepared 17 September 2026. Repository: `C:/Users/palle/Documents/GitHub/AdaResearch_46`.

This explains the method used for our inside-museum review images. The examples below were checked against the current capture scripts and their saved logs/reports. This documentation pass did not launch a new museum or take a fresh screenshot.

## 1. What we are photographing

Load `res://commons/scenes/endless_museum.tscn` through a small temporary scene, let the museum assemble the requested hall, find the artifact that the museum actually placed, and photograph it with a temporary `Camera3D`. Save the rendered viewport directly as a PNG.

This retains the museum's placement, walls, floor, neighbouring works, light and staging. An isolated artifact render is useful for another purpose, but cannot tell us whether a panel faces the visitor, another object blocks it, or the exhibit fits its hall.

Use these distinctions in the report:

| Image | What it establishes |
| --- | --- |
| Actual museum capture | How the assembled museum renders under the recorded capture settings |
| Artifact-only preview | How an instantiated artifact renders in a separate scene |
| Map catalogue capture | How the catalogue builds and shows a grid map |
| Plan/diagram | An interpretation of source data |
| Headset view | Only claim this when a real headset run supplied the evidence |

Our ordinary screenshots are desktop engine renders. A camera placed at eye height does not by itself establish that the player can reach that position or operate the controls.

## 2. Start from the working examples

All paths in this guide are relative to the repository unless they start with `res://` or a drive letter. `res://` means the Godot project root, which is the repository above.

### A. Point_Lines: the four filmed line studies

- Runnable scene: `ada_run/line_workshop_museum_check.tscn`
- Script: `ada_run/line_workshop_museum_check.gd`
- Saved image: `ada_run/line-workshop-museum.png`
- Saved report: `ada_run/line-workshop-museum-report.json`
- Saved render log: `ada_run/line-screen-museum-final.log`

The saved 15 September report finds the artifact at world position `(16.5, 0, 16.5)`, scale `(1, 1, 1)`. The log records the actual artifact facing approximately 180 degrees. These are evidence from that run, not permanent coordinates to hard-code for every future capture.

The existing script takes a PNG only when `--capture` appears after the engine's `--` argument separator. It uses a 1.65 m artifact-local camera height and a wide, horizontal 88-degree field of view to include the four monitors. That wide framing is specific to this installation.

### B. Trans_Rotation: an embedded simulation grid

- Runnable scene: `ada_run/rotation_compact_museum_capture.tscn`
- Script: `ada_run/rotation_compact_museum_capture.gd`
- Output directory: `doc/space/transformation-refresh-2026-09-16/`
- Report: `doc/space/transformation-refresh-2026-09-16/rotation-museum-capture.json`

This script loads the actual museum, finds `SimGrid_Trans_Rotation`, and photographs overview, blades, arrays, gallery and eye-level views. Its existing report records the grid's world origin as `(5.5, -0.5, 5.5)`. This is why raw grid coordinates must be transformed before positioning a world-space camera.

It also sets the rotating blades to a particular crossing pose. Describe those images as staged captures of the real installation. The script contains checks for the room's dimensions and artifact counts on that date; review those checks before reusing it after further room edits.

### C. Examples with more interaction evidence

`ada_run/ca_intro_probe_base.gd` shows hall lookup through `_segments`, artifact lookup through `_edit_records`, and matched shots. It is a base for a larger probe, not a universal standalone screenshot command.

`ada_run/rotation_body_museum_capture.gd` captures different phases of an actual running body comparison. It records results and temporarily pauses that comparison while photographing it. This is useful when a single still cannot show the consequence of an operation.

## 3. Why the helper is a .tscn scene

The normal helper is a small scene whose root has a script extending `Node3D` or `Node`. Launch it as the project scene, with the project path supplied, so normal project startup and autoloads are available.

The line example's entire scene wrapper is:

```ini
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://ada_run/line_workshop_museum_check.gd" id="1"]
[node name="LineWorkshopMuseumCheck" type="Node3D"]
script = ExtResource("1")
```

Do not substitute a bare `--script` SceneTree probe without checking its startup assumptions. Some of our artifact dependencies need the project's singleton and XRTools environment even when XR itself is disabled.

For a new job, make a small wrapper with a unique name under `ada_run/<job>/`. Load the production museum script; do not duplicate its large implementation into the wrapper. A copied museum implementation quickly becomes an obsolete version of the game.

## 4. Select the hall before adding the museum to the tree

The working line helper does this before `add_child(em)` triggers museum startup:

```gdscript
var em = load("res://commons/scenes/endless_museum.tscn").instantiate()
var control := "res://ada_run/line-workshop-control.json"
var f := FileAccess.open(control, FileAccess.WRITE)
f.store_string(JSON.stringify({
    "first_chapter": "primitives",
    "first_map": "Point_Lines",
    "grid_pack": 1,
    "dollhouse": 0
}))
f.close()
em.set("EM_CONTROL", control)
em.set("_overrides_path", control + ".unused")
em.set("_cartridge_read_enabled", false)
em.set("start_chapter", "primitives")
em.set("start_map", "Point_Lines")
var layout: Dictionary = JSON.parse_string(
    FileAccess.get_file_as_string("res://commons/data/em_layout.json")
)
layout.get_or_add("stream", {})["bodies"] = 1
em.set("_layout", layout)
add_child(em)
```

For a new job, create the output directory first, use its own control filename, and handle failed file opens/JSON parsing. Use the exact chapter ID from `commons/maps/sequences/` and the exact map folder name. Set both chapter and map explicitly: the scene's current Inspector defaults are not a reliable selection for your task.

These private museum properties are the current project's capture hooks, not a stable Godot API. Recheck them if the museum implementation changes.

### Decide which saved state the capture should include

The line example deliberately disables cartridge replay, lowers the streamed body count in memory, and uses a nonexistent overrides file. It still uses the default saved placement hand. This is an isolated diagnostic configuration of the real museum, not an exact reproduction of every setting in an already-open user session.

For each new run, record the choice:

- **Current saved arrangement:** retain the applicable plan, placement hand and overrides. A job-local byte-for-byte snapshot can preserve the selected input while avoiding edits to its live source. Record the original paths and hashes.
- **Authored-layout investigation:** deliberately omit the saved hand and/or overrides to inspect generated placement. Label the omission. A difference from the live arrangement may be precisely the problem being investigated.
- **Changed-pose comparison:** preserve the arrangement, but set a specific simulation pose. Record the operation and pose.

Relevant sources/hooks are `ada_run/em_plan.json` (`plan_file` / `_plan_path`), `ada_run/necklace_hand.json` (`_hand_path`), `ada_run/em_overrides.json` (`_overrides_path`), and `commons/data/em_layout.json` (`_layout`). Do not overwrite the user's `ada_run/em_control.json` to select your capture room. Use a private control file.

Museum startup can still refresh shared diagnostic files under `ada_run/`. A separate process is not total filesystem isolation. Run captures serially and do not restore an old copy over another worker's newer edits.

## 5. Wait for the hall and find the actual artifact

Older examples wait two or three seconds. For a new helper, use a bounded readiness loop: look for the target hall and target artifact, wait more frames while they are absent, and fail with their names when the deadline expires. An arbitrary timer is not proof that construction completed.

For an ordinary hall, find its segment:

```gdscript
var segment: Node3D
for record: Dictionary in em.get("_segments"):
    var node := record.get("node") as Node3D
    if is_instance_valid(node) and node.get_meta("em_map", "") == MAP:
        segment = node
        break
```

Then inspect `em.get("_edit_records")`, match the artifact token, and verify that its node belongs to that segment. If the same token occurs several times, select a particular instance using its placement and record that choice. Do not silently accept the first matching artifact from another hall.

For an embedded simulation, find the actual `SimGrid_<MapName>` node beneath the museum. For instance, the rotation helper finds `SimGrid_Trans_Rotation`. Artifact discovery inside that grid can then use the actual script resource path.

**The important wrapper trap:** an edit record's `node` can be a placement wrapper. The actual exhibit below it can have an additional rotation, scale or offset. Check the candidate's script first, then search its descendants for the expected production script:

```gdscript
const WORKSHOP_SCRIPT := "res://commons/artifacts/line_space_workshop/line_space_workshop.gd"
# `candidate` is the placed Node3D already selected in the correct hall.
var workshop: Node3D = candidate
if not workshop.get_script() or workshop.get_script().resource_path != WORKSHOP_SCRIPT:
    workshop = null
    for child in candidate.find_children("*", "Node3D", true, false):
        if child.get_script() and child.get_script().resource_path == WORKSHOP_SCRIPT:
            workshop = child
            break
# Fail explicitly if workshop is still null.
```

We previously photographed from the wrong side of the line workshop by using its wrapper's facing direction. Resolving the real script-bearing child fixed that. The actual artwork did not need to be rotated for the photograph.

## 6. Position the camera in the right coordinate system

For a known artifact-local front, transform both the eye position and target through that actual artifact:

```gdscript
var camera := Camera3D.new()
add_child(camera)
camera.global_position = workshop.to_global(Vector3(0, 1.65, 2.7))
camera.look_at(workshop.to_global(Vector3(0, 1.25, 0)))
camera.keep_aspect = Camera3D.KEEP_WIDTH
camera.fov = 88
```

For the simulation grid example:

```gdscript
camera.global_position = grid.to_global(Vector3(12, 2.1, 22))
camera.look_at(grid.to_global(Vector3(19, 2.1, 34)))
camera.make_current()
```

These are examples for specific compositions, not universal visitor positions. Godot cameras look along their local negative Z; `look_at()` calculates that orientation for you. Never assume that world positive Z is every artifact's front.

Also distinguish:

- Map cell indices from metre coordinates and cell centres.
- Grid-local position from museum world position.
- Segment-local position from map position: existing probes sometimes add `VESTIBULE_H` to Z because the segment includes an entry section. Do not add that offset again when using artifact-local coordinates or a simulation grid's own transform.
- Artifact-local eye height from world eye height: `to_global()` includes scale. A 1.65 m local offset on a 10x-scaled object is not a human eye height. For bodily review, determine the actual supporting surface and add the intended world-space eye height.

Start ordinary approach views with a moderate field of view; go wider only when necessary and report it. Keep field of view, aspect ratio and position identical for before/after comparisons. A flattering wide angle can hide reach and distance problems.

## 7. Keep control of the camera, then wait for rendering

In the temporary museum instance, the existing helpers stop the museum's own processing after the target is built. They also stop timers under its walker camera so it does not reclaim the view:

```gdscript
em.set_process(false)
em.set_physics_process(false)
var walker_camera: Camera3D = em.get("_cam")
if is_instance_valid(walker_camera):
    for child in walker_camera.get_children():
        if child is Timer:
            child.stop()
```

If necessary, stop the temporary instance's player processing too. Do this only in your helper's museum instance. Leave the user's running game alone.

Stopping the parent museum does not freeze all child artifacts. If you need a known animated pose, set or pause that specific artifact and record it. Let ordinary animations continue when the purpose is to observe their current behaviour. Preserve the running-counter and invisible-point decisions: do not change those artifacts to make a convenient image.

After setting the camera:

```gdscript
for i in 25:
    camera.make_current()
    await get_tree().process_frame
await RenderingServer.frame_post_draw
var image := get_viewport().get_texture().get_image()
var result := image.save_png("res://ada_run/my-job/approach.png")
if result != OK:
    push_error("Could not save capture: %s" % result)
    get_tree().quit(1)
    return
```

Creating the camera and saving in the same frame can capture the previous camera, an unready image or incomplete textures. `frame_post_draw` waits for a rendered frame; it is not a substitute for first waiting for the room to build.

For monitors displaying SubViewports, let the real monitor/camera system update while it is visible. The line workshop now has separate filmed source geometry; use the current `ada_run/line_camera_check.gd` if checking its feeds. The older `line_camera_render_check.gd` assumes an earlier shared-world design and must not be treated as the current contract. A museum image of the monitors and a raw monitor-feed image answer different questions.

## 8. Windows launch example: the existing line helper

Use Godot 4.6 at `C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe` on this machine. The historical render log identifies the Compatibility renderer and an RTX 3070. A rendered capture requires a working graphics context; **omit `--headless`**. A successful headless logic run does not certify an image. Do not rely on an old script comment calling its capture “headless.”

The following PowerShell example launches the existing scene, uses a hidden helper window, bounds its runtime and rejects stale output. It overwrites that helper's existing PNG and JSON output; copy/adapt the helper into a unique job directory when you need to retain a baseline.

```powershell
$ErrorActionPreference = 'Stop'
$captureRepo = 'C:\Users\palle\Documents\GitHub\AdaResearch_46'
$captureExe = 'C:\Users\palle\Desktop\Godot_v4.6-stable_win64.exe'
$capturePng = Join-Path $captureRepo 'ada_run\line-workshop-museum.png'
$captureReport = Join-Path $captureRepo 'ada_run\line-workshop-museum-report.json'
$captureLog = Join-Path $captureRepo 'ada_run\claude-line-museum-capture.log'

# Fail closed if the process inventory itself fails.
# Keep any open editor; investigate existing game/probe processes before launching.
$captureInventory = @(Get-CimInstance Win32_Process -Filter "Name LIKE 'Godot%'" -ErrorAction Stop)
$captureRunning = @($captureInventory | Where-Object {
    $_.CommandLine -notmatch '(?:^|\s)--editor(?:\s|$)'
})
if ($captureRunning.Count -gt 0) {
    $captureRunning | Select-Object ProcessId, Name, CommandLine | Format-List
    throw 'Existing Godot runtime or unclassified process: resolve capture concurrency first.'
}

$captureArgs = @(
    '--path', ('"{0}"' -f $captureRepo),
    '--xr-mode', 'off', '--audio-driver', 'Dummy',
    '--rendering-method', 'gl_compatibility',
    '--windowed', '--resolution', '1600x1000',
    '--log-file', ('"{0}"' -f $captureLog),
    '--quit-after', '1800',
    'res://ada_run/line_workshop_museum_check.tscn',
    '--', '--capture'
)
$captureStarted = [DateTime]::UtcNow
$captureProc = Start-Process -FilePath $captureExe -ArgumentList $captureArgs `
    -WorkingDirectory $captureRepo -WindowStyle Hidden -PassThru
$captureDeadline = [DateTime]::UtcNow.AddSeconds(90)
while (-not $captureProc.WaitForExit(1000)) {
    if ([DateTime]::UtcNow -ge $captureDeadline) {
        # Stop only the process launched above. Never kill all Godot processes.
        $captureProc.Kill()
        $captureProc.WaitForExit()
        throw 'Capture timed out; inspect its log before retrying.'
    }
}
$captureProc.Refresh()
if ($captureProc.ExitCode -ne 0) {
    throw "Capture exited with code $($captureProc.ExitCode). Inspect $captureLog"
}
foreach ($captureFile in @($capturePng, $captureReport)) {
    if (-not (Test-Path -LiteralPath $captureFile)) { throw "Missing $captureFile" }
    if ((Get-Item -LiteralPath $captureFile).LastWriteTimeUtc -lt $captureStarted) {
        throw "Stale output: $captureFile"
    }
}
$captureEvidence = Get-Content -LiteralPath $captureReport -Raw | ConvertFrom-Json
if (-not $captureEvidence.artifact_found) { throw 'Expected workshop was not found.' }
Select-String -LiteralPath $captureLog -Pattern 'SCRIPT ERROR|Parse Error|ERROR:'
Write-Output $capturePng
```

The engine's `--quit-after` counts iterations, not wall-clock seconds; the external deadline matters. Exit code zero is also insufficient if the output is stale or the engine exited before the helper saved it. Inspect errors and the image before reporting success.

The repository also has `tools/godot_watchdog.py`, which watches fresh output and terminates the process tree it launched on a stall. It is another bounded-run option. As currently written it does not perform a preflight process inventory or explicitly hide its child window, so do not assume the watchdog alone supplies those parts of the workflow.

Do not terminate an existing user session to make a capture slot. If graphics-context creation fails on a remote session, report that rendering limitation; do not relabel a headless check or an older image as a fresh capture.

## 9. Inspect the PNG; inspect the evidence

Open the image using the available local-image viewer. In Codex, `view_image` takes the PNG's absolute filesystem path. Claude should use its own image-reading capability for the same file. A filesystem listing or an image filename is not visual inspection.

Look for the actual exhibit, correct facing, the floor and wall relationship, readable controls, occlusions, and an intelligible consequence. Check that all expected live screens contain an image. A blank or wrong image means revise camera/readiness, then capture again; it does not justify deleting surrounding works to obtain a clean shot.

For a hall review, usually provide:

1. **Approach:** what is visible as the visitor arrives.
2. **Operating position:** what can be seen while using the controls.
3. **Consequence:** the meaningful changed state, ideally at matched framing.
4. **Context/plan, when useful:** a clearly labelled elevated diagnostic view showing the room arrangement.

The first three should use positions appropriate to the encounter. If you have not tested reachability, state that. Free-camera inspection, direct method calls, synthetic desktop pointer input, real player movement and tracked headset interaction are different levels of evidence.

Record at least: date, map/chapter, helper and scene, artifact token and actual script/node, selected instance, configuration inputs/overrides, camera world position/target/FOV/aspect, renderer/resolution, any forced animation state, output paths, run outcome and `headset_verified: false` when appropriate. Include fresh hashes of relevant source files for a reproducible review; a Git commit alone misses uncommitted work.

The line helper's historical JSON is intentionally minimal. Do not infer route or interaction checks that it does not record. Extend a job-specific report when the task requires stronger evidence.

## 10. Frequent mistakes

| Symptom | What to inspect |
| --- | --- |
| Back of a panel, wrong exhibit in front | Placement wrapper versus real artifact transform; selected instance; camera position |
| Correct artifact, wrong hall arrangement | Saved hand/overrides, generated plan, cartridge mode, explicit chapter and map |
| Empty/black PNG or no PNG | Headless mode, graphics startup failure, missing output directory, absent `--capture`, capture before draw |
| View jumps to the walker | Timers/processes reclaiming the current camera; repeat `make_current()` during settling |
| Embedded grid seems shifted or sunk | Use `grid.to_global()` for both eye and target; check the actual support height |
| Dynamic screens are blank | Visibility-driven SubViewport updates, insufficient rendered frames, wrong/currently obsolete feed assumptions |
| Exit zero but unchanged image | Timestamp/hash check; stale PNG left by an earlier run; early engine quit |
| Artifact is huge or tiny | Instance scale and wrapper transforms; do not auto-rescale the production scene to fit a photo |
| Scene works but controls are absent | Normal project startup/autoloads, construction logs, actual input path; a still is not an interaction test |
| “Class ... hides a global script class” | Duplicate `class_name` declarations in backup scripts; keep source archives under the existing `doc/book/iterations/.gdignore` boundary |

Avoid `tools/capture_spine_research.py` for an inside-museum artifact review: its current capture flags explicitly disable artifacts and it uses the map catalogue. `commons/testing/capture_multi_angle.gd` also uses catalogue scenes. Both can serve catalogue/geometry work, but their images do not substitute for an endless-museum encounter capture.

Do not add extra lights, remove walls, hide clutter or alter the artifact to improve a screenshot without reporting the change and its purpose. A diagnostic image is useful precisely because it can reveal a problem in the room.

## 11. What to hand back

Return the actual PNGs, helper paths, log, report, and a short account of what you saw and what you could not establish. If the room needs a fix, give matched before/after views after the fix. Keep capture work separate from any unrequested prose revision or sequence rearrangement.

Example caption:

> Point_Lines, line_space_workshop. Actual endless-museum desktop render; temporary camera positioned from the placed artifact's transform. Capture settings omit saved em_overrides and disable cartridge replay. Live monitor images visible. Headset reach, comfort and performance not tested.

If images are copied into the encyclopedia, use the relevant page's existing asset directory, preserve the original PNG and report, and follow the destination's filesystem permissions. Opening a local page is not permission to publish externally.

The deliverable is a reviewable view of the encounter: what the visitor approaches, what they can see while acting, and what the action changes.
