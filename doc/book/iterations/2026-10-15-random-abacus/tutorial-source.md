# Touch and be moved

<!-- @random_touch -->

Five one-metre rods sit one above another in an open abacus frame. A small dark bead waits at each centre. Touch a bead and the contacting virtual hand follows it. Rows 1–4 read the same X targets at ½×, 1×, 2× and 4× speed. The fifth returns to 1× speed and adds Y, moving above and below its resting rod. Compare what changes in the encounter; no particular feeling is required.

In VR, hand contact starts movement without a grip button. Grabbing also works. Only the contacting virtual hand follows; the tracked controller, viewpoint, body and other hand remain unchanged. Move the physical controller more than 20 centimetres from the contact position to release. On desktop, right-click runs or releases the sphere without moving the camera. After release the unoccupied sphere settles back to its line, ready for another touch.

## What you bring and what is new

Bring positions, vectors and elapsed time from the earlier movement and Wavefunctions studies. X is the installation's sideways direction; Y is vertical. Turning the installation rotates its sideways axis in the room. Keep the existing museum player, camera, lights and XR Tools.

We inherit the [PointBody](../../artifacts/ignorance_gallery/point_body.gd) through the [path-preserving point](../../artifacts/random_return/ride_point.gd). Holding this point preserves its scripted path instead of pulling it toward the controller. XR Tools lets a hand follow a temporary target: a node whose position and orientation replace the usual tracking target. Our hand follower supplies that target for the contacting collision and visible hand. It adds the sphere's displacement to the tracked controller pose, then restores normal tracking on release. It cannot move the physical hand.

A **pseudorandom generator** is a calculation with changing internal state. Each request advances that state. A **seed** sets its beginning. Repeating the seed and request procedure repeats the sequence; speed, axes and smoothing are additional choices.

Our record has 48 coordinate pairs: the resting centre, then 47 generated targets. X ranges from −0.44 to +0.44 metres, inside the rod's ends. Y ranges from −0.12 to +0.12 metres; the fifth row has extra clearance for this movement. Separate generators produce X and Y, so adding Y never consumes an extra X draw. The record retains actual targets as well as the seed.

In Random Definition, every random-generating instrument starts from the saved hall seed **435**. Each owns a private stream: using the slot machine does not advance the window or the Geiger. The shared [hall seed controller](../../artifacts/randomness_space/hall_seed.gd) supplies the same starting number, while each instrument retains its generator, request order and mapping. For the opening paths, Y uses a derived seed (`hall seed + 1`) so adding Y leaves X unchanged.

Choose a different number explicitly at the window, use SEED +1, restore a kept record, or complete a MOVE / KEEP recording to change the hall’s seed. RESET 435 recalls the original receipt; it does not request another atmospheric sample. The frame study measures timing but cannot reseed this hall. A gesture supplies input to deterministic generation; it does not establish true randomness.

## A path starts when it meets a hand

The four X rows read 0.4, 0.8, 1.6 and 3.2 target segments per second. The second row defines 1× speed; the fifth also uses 0.8. Each has its own elapsed time. Idle waiting advances none of them. Compare positions at equal time since contact, not at the same wall-clock instant.

For successive X targets −0.2 and +0.2, the midpoint is zero. Rows 1–4 reach it after 1.25, 0.625, 0.3125 and 0.15625 seconds within that segment. We smooth the fraction `u` using `u * u * (3 - 2 * u)`, slowing near each target. Every row retains this smoothing and changes only the rate or available axes. The last target connects to the resting centre, closing the finite loop.

Predict these comparisons: row 3 at `t / 2` and row 4 at `t / 4` match row 2 at `t`; row 1 needs `2 * t`. Row 5's X matches row 2 at equal elapsed times. These describe prescribed bead positions. The hand target also includes actual controller movement, up to the withdrawal threshold.

## Reconstruct the apparatus

Save the three complete files below together, and attach `random_touch.gd` to an upright Node3D at unit scale on the floor. It builds the open frame, five rods, small beads, contact areas, row labels and replay controls. Use the current placement in Random Definition's map; the wall remains editable. The complete stand occupies about 1.3 metres of width and 0.55 metres of depth. Keep the front accessible for touch and withdrawal.

The `res://` dependencies, including the shared hall seed controller linked above, are supplied project components. Read `make_record()` and `offset()` first. Then follow `_sync_hand()`, which identifies contact or a grab; `advance()`, which advances only the active path; and the follower's `update_target()`, which offsets the hand. One hand can follow one sphere at a time. The scene updates before the XR hand nodes so they use the current target.

REPLAY resets the stored paths to their centres and waits for contact. PAUSE releases the hand. KEEP stores the targets, settings, individual elapsed times, positions and any unoccupied return in progress. LOAD restores that saved state paused, without attaching a hand. Unpause and touch to continue a held pose; a saved return settles before the sphere is ready. Replay and load are refused during an active interaction.

Records use `random-touch/3` and `user://random-touch-abacus-001.json`. Earlier three-line recordings remain in their original file and are rejected by this apparatus because their dimensions, ranges and rates differ.

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

First check that all five beads wait. Touch each of the first four, withdrawing between rows, and compare the same targets at different speeds. Then compare rows 2 and 5 to isolate the added Y movement at 1× speed. Record which path, elapsed moment and observation you want to investigate. Have someone reconstruct the scene and compare the retained data before comparing sensations.

Check release independently: withdraw a VR hand or drop the desktop grab. Normal hand tracking must resume, and the sphere returns alone. Verify that the head, body, controller and other hand stay unchanged, including during pause or scene removal. This confirms interaction rules; it cannot establish whether the movement is interesting or comfortable in a headset.

For a further experiment, change only row 3's rate from 1.6 to 1.2. Its comparison time against row 2 becomes `t * 0.8 / 1.2`. Preserve the changed recipe separately and update its schema identifier; the validator deliberately rejects mismatched rate recipes.

At the RAND page, hold one group of digits and compare selecting that group with retaining a whole movement record. The [colour-grid reconstruction](seed-picture-extension.md) remains optional. The 48-value bench remains the first research pilot. Carry the explicit target array and the distinction between a value and its assigned consequence onward to Random Entropy.

<!-- @ -->
