# Touch and be moved

<!-- @random_touch -->

Three bare horizontal lines hang in space, each two metres long, two metres apart in depth. A dark sphere waits at the centre of each. Touch the first and the contacting virtual hand follows it sideways. Withdraw the tracked hand to stop. The second reads the same targets twice as fast, changing direction more frequently. The third combines the first path's sideways movement with vertical movement. Compare what changes in the encounter; no particular feeling is required.

In VR, hand contact starts movement without a grip button. Grabbing also works. Only the contacting virtual hand follows; the tracked controller, viewpoint, body and other hand remain unchanged. Move the physical controller more than 20 centimetres from the contact position to release. On desktop, right-click runs or releases the sphere without moving the camera. After release the unoccupied sphere settles back to its line, ready for another touch.

## What you bring and what is new

Bring positions, vectors and elapsed time from the earlier movement and Wavefunctions studies. X is the installation's sideways direction; Y is vertical. Turning the installation rotates its sideways axis in the room. Keep the existing museum player, camera, lights and XR Tools.

We inherit the [PointBody](../../artifacts/ignorance_gallery/point_body.gd) through the [path-preserving point](../../artifacts/random_return/ride_point.gd). Holding this point preserves its scripted path instead of pulling it toward the controller. XR Tools lets a hand follow a temporary target: a node whose position and orientation replace the usual tracking target. Our hand follower supplies that target for the contacting collision and visible hand. It adds the sphere's displacement to the tracked controller pose, then restores normal tracking on release. It cannot move the physical hand.

A **pseudorandom generator** is a calculation with changing internal state. Each request advances that state. A **seed** sets its beginning. Repeating the seed and request procedure repeats the sequence; speed, axes and smoothing are additional choices.

Our record has 48 coordinate pairs: the resting centre, then 47 generated targets. X ranges from −1 to +1 metres. Y ranges from zero to one metre above the entry height, allowing the third sphere to descend again without going below its starting line. Separate generators produce X and Y, so adding Y never consumes an extra X draw. The record retains actual targets as well as the seed.

In Random Definition, every random-generating instrument starts from the saved hall seed **435**. Each owns a private stream: using the slot machine does not advance the window or the Geiger. The shared [hall seed controller](../../artifacts/randomness_space/hall_seed.gd) supplies the same starting number, while each instrument retains its generator, request order and mapping. For the opening paths, Y uses a derived seed (`hall seed + 1`) so adding Y leaves X unchanged.

Choose a different number explicitly at the window, use SEED +1, restore a kept record, or complete a MOVE / KEEP recording to change the hall’s seed. RESET 435 recalls the original receipt; it does not request another atmospheric sample. The frame study measures timing but cannot reseed this hall. A gesture supplies input to deterministic generation; it does not establish true randomness.

## A path starts when it meets a hand

The slow paths read 0.8 target segments per second; the fast path reads 1.6. Each has its own elapsed time. Idle waiting advances none of them. Compare positions at equal time since contact, not at the same wall-clock instant.

For successive X targets −0.2 and +0.2, the midpoint is zero. The slow path reaches it after 0.625 seconds within that segment; the fast path takes 0.3125 seconds. We smooth the fraction `u` using `u * u * (3 - 2 * u)`, slowing near each target. The faster path retains this smoothing and changes the rate. The last target connects to the resting centre, closing the finite loop.

Predict these comparisons: fast X at `t / 2` matches slow X at `t`; the third path's X matches the first at equal elapsed times. These describe prescribed sphere positions. The hand target also includes actual controller movement, up to the withdrawal threshold.

## Reconstruct the apparatus

Save the three complete files below together, and attach `random_touch.gd` to an upright Node3D at unit scale in the museum. It builds three lines, spheres, contact areas, labels and a small control board. Use the current placement in Random Definition's map; the wall remains editable. Leave room around the lines to approach and withdraw, with two metres between line centres.

The `res://` dependencies, including the shared hall seed controller linked above, are supplied project components. Read `make_record()` and `offset()` first. Then follow `_sync_hand()`, which identifies contact or a grab; `advance()`, which advances only the active path; and the follower's `update_target()`, which offsets the hand. One hand can follow one sphere at a time. The scene updates before the XR hand nodes so they use the current target.

REPLAY resets the stored paths to their centres and waits for contact. PAUSE releases the hand. KEEP stores the targets, settings, individual elapsed times, positions and any unoccupied return in progress. LOAD restores that saved state paused, without attaching a hand. Unpause and touch to continue a held pose; a saved return settles before the sphere is ready. Replay and load are refused during an active interaction.

Records use `random-touch/2` and `user://random-touch-lines-001.json`. Earlier autonomous-study records are rejected because their range and time model differ.

### motion_record.gd

<!-- student-code:motion_record.gd -->

{{MOTION_CODE}}

### random_touch.gd

<!-- student-code:random_touch.gd -->

{{SCENE_CODE}}

### hand_follower.gd

<!-- student-code:hand_follower.gd -->

{{HAND_CODE}}

## Compare, keep, reconstruct

First check that all three spheres wait. Touch the first, withdraw, then try the faster line. Keep the targets fixed. Finally try X plus Y. Record which path, elapsed moment and observation you want to investigate. Have someone reconstruct the scene and compare the retained data before comparing sensations.

Check release independently: withdraw a VR hand or drop the desktop grab. Normal hand tracking must resume, and the sphere returns alone. Verify that the head, body, controller and other hand stay unchanged, including during pause or scene removal. This confirms interaction rules; it cannot establish whether the movement is interesting or comfortable in a headset.

For a further experiment, change only the fast rate from 1.6 to 1.2. The corresponding comparison time becomes `t * 0.8 / 1.2`. Preserve the changed recipe separately and update its schema identifier; the validator deliberately rejects mismatched rate recipes.

At the RAND page, hold one group of digits and compare selecting that group with retaining a whole movement record. The [colour-grid reconstruction](seed-picture-extension.md) remains optional. The 48-value bench remains the first research pilot. Carry the explicit target array and the distinction between a value and its assigned consequence onward to Random Entropy.

<!-- @ -->
