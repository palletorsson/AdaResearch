# Looking from inside the rehearsal

The prefab ghost now has an eye anchor inside its head. A monoscopic camera follows the anchor's actual position and orientation; an outside camera records the same live instrument. Both render the same Godot World3D. The visitor's camera stays active.

Open [the paired review](index.html). The four moments are before the first touch, separated parts, a different seed at the hybrid endpoint, and replay of the kept intermediate form. The review includes captures from the actual Random_Entropy hall as well as the isolated preview.

## Try the live comparison

Open `commons/artifacts/prefab_disorder/preview.tscn` in Godot and run it with F6. Turn on **COMPARE CAMERAS**, then **WATCH**. **SAVE BOTH VIEWS** captures an additional pair. **OPEN CAPTURES** opens the last successful capture folder. Turning comparison off stops continuous rendering of the two extra views.

In the museum, the optional prefab bench at Random_Entropy grid (13,3) records the same four pairs when WATCH runs. Takeover, stopping and private ghost saves retain their previous behavior. A pending unrendered observation is cancelled on takeover; it cannot delay the visitor's input.

## What each record contains

Automatic pairs live under `user://ghost-students/prefab/<session>/observations/`. Each pair has two 960 × 640 PNGs and a `ghost-view-pair/1` JSON receipt. The parent `rehearsal.json` indexes automatic observations. Manual pairs have their own folders.

- Head pose in world and bench coordinates; head-local pose and eye offset.
- Both camera transforms, vertical field of view, clipping planes, render masks and image size.
- Ghost body transform and local hand positions.
- Complete artifact state: seed, stage, raw draws, source signature, hybrid membership and target transforms; a hash also includes the rendered part transforms.
- Action, phase, process/render frame identifiers, time, image hashes and write status.

Transform arrays store basis X, Y and Z followed by origin, twelve components in total. `hybrid_recipe.gd` provides `pack` and `unpack` for that convention. `bench.restore(receipt.artifact_state)` reconstructs the captured arrangement in a compatible instrument. Set a camera from its stored bench-relative transform multiplied by the current bench transform to reconstruct that viewpoint. Head/body/hand poses are retained for further reenactment; there is no camera-replay browser button yet.

Capturing uses RenderingServer's [before- and after-draw signals](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html#signals): copy state and set both cameras immediately before one draw, then read both images after all viewports finish. Camera transform notifications are flushed explicitly. Without that flush, an early trial saved the correct metadata alongside an image from an older camera pose. A rendered marker test now detects that error.

Only the hologram's head shell and visor occupy visual layer 16 and are excluded from the eye camera. Its hands and torso remain visible. No physics layers change. The cameras are dormant except during a requested capture or the explicitly enabled desktop comparison. They use the live world, not another simulation.

## What the views make available

The outside view shows the ghost's body and the relation between both tables. The eye view follows a narrower attention: the control during a reach, then the right-hand arrangement. This exposes a useful limitation in the present choreography: looking at a hybrid does not guarantee that the whole-object comparison or every label is in view. A next trial could change only the gaze target or pause, then compare the evidence.

These are authored head poses and synthetic pointer actions. The images can establish what the camera rendered and help inspect sightlines, but do not establish reading, understanding, haptics, stereo depth, headset comfort or Quest performance. Hologram scanlines use engine time, so exact geometry/state replay does not promise pixel-identical animated screenshots. PNG capture can introduce a brief pause; continuous recording is not enabled in VR.

The six-stop room/final sequence remains unchanged. The 48-value seed bench remains the first research pilot. This extension supports inspecting the prefab rehearsal and deciding what to revise next.

## Verification

`python -X utf8 doc/book/iterations/2026-10-16-ghost-head-camera/run.py` checks paired captures, full-state reconstruction in fresh instruments, camera following under translation and rotation, actual pixel alignment, render enable/disable, failed writes, takeover and scene cleanup.

`python -X utf8 doc/book/iterations/2026-10-16-ghost-head-camera/regression.py` reruns the existing nine-action rehearsal suite into a separate evidence directory, preserving the earlier pilot's receipts.

Temporary reconstruction instruments are allowed three physics/process updates before disposal. Creating and removing their native controls before their first physics updates produced a shutdown access violation in an earlier test run, even though the assertions had passed. The runners now retain their exit codes, and publishing requires a clean exit as well as passing assertions.

`python -X utf8 tools/run_encounter_probe.py Random_Entropy --sequence randomness --render --no-bridges --output-tag ghost-head-camera --probe doc/book/iterations/2026-10-16-ghost-head-camera/museum_probe.gd` checks the same camera/capture behavior in the actual museum.
