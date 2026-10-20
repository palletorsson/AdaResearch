# Touch and be moved

<!-- @random_touch -->

Three bare horizontal lines hang in space, each two metres long, one metre apart in depth. A dark sphere waits at the centre of each. Touch the first and your avatar travels sideways with it. Withdraw your hand to stop. The second reads the same targets twice as fast, changing direction more frequently. The third combines the first ride's sideways movement with vertical movement. Compare what changes in the encounter; no particular feeling is required.

In VR, hand contact starts the ride without a grip button. Grabbing also works. On desktop, right-click holds or releases a sphere. The player moves through the museum's collision system. A wall can block the journey. After release the unoccupied sphere settles back to its line, ready for another touch.

## What you bring and what is new

Bring positions, vectors and elapsed time from the earlier movement and Wavefunctions studies. X is the installation's sideways direction; Y is vertical. Turning the installation rotates its sideways axis in the room. Keep the existing museum player, camera, lights and XR Tools.

We inherit the [PointBody](../../artifacts/ignorance_gallery/point_body.gd) through the [path-preserving point](../../artifacts/random_return/ride_point.gd). Holding this point preserves its scripted path instead of pulling it toward the controller. We also inherit the [player-carry adapter](../../artifacts/force_field_zone/field_carry_provider.gd) used by Out / Back. It passes a desired velocity to the XR player's collision-aware movement. The desktop museum uses the same carry interface. This is movement of the avatar, not physical resistance against a hand.

A **pseudorandom generator** is a calculation with changing internal state. Each request advances that state. A **seed** sets its beginning. Repeating the seed and request procedure repeats the sequence; speed, axes and smoothing are additional choices.

Our record has 48 coordinate pairs: the resting centre, then 47 generated targets. X ranges from −1 to +1 metres. Y ranges from zero to one metre above the entry height, allowing the third ride to descend again without asking it to go below the starting floor. Separate generators produce X and Y, so adding Y never consumes an extra X draw. The record retains actual targets as well as the seed.

## A path starts when it meets a rider

The slow rides read 0.8 target segments per second; the fast ride reads 1.6. Each has its own elapsed ride time. Idle waiting advances none of them. Compare positions at equal time since contact, not at the same wall-clock instant.

For successive X targets −0.2 and +0.2, the midpoint is zero. The slow ride reaches it after 0.625 seconds within that segment; the fast ride takes 0.3125 seconds. We smooth the fraction `u` using `u * u * (3 - 2 * u)`, slowing near each target. The faster ride retains this smoothing and changes the rate. The last target connects to the resting centre, closing the finite loop.

Predict these comparisons: fast X at `t / 2` matches slow X at `t`; the third ride's X matches the first at equal elapsed ride times. These describe prescribed sphere positions. A player's actual journey also depends on collisions and release.

## Reconstruct the apparatus

Save the two complete files below together, and attach `random_touch.gd` to an upright Node3D at unit scale in the museum. It builds three lines, spheres, contact areas, labels and a small control board. Use the current placement in Random Definition's map; the wall remains editable. The installation needs room around its two-metre lines for a player to ride and approach the next one.

The `res://` dependencies are supplied project components. Read `make_record()` and `offset()` first. Then follow `_sync_rider()`, which identifies contact or a grab; `advance()`, which advances only the active ride; and `carry_velocity()`, which asks the player's movement controller to follow the sphere while retaining collisions. Only one ride carries this player at a time.

REPLAY resets the stored paths to their centres and waits for contact. PAUSE stops the ride. KEEP stores the targets, settings, individual elapsed times, positions and any unoccupied return in progress. LOAD restores that saved state paused, without attaching or teleporting a player. Unpause and touch to continue a held pose; a saved return settles before the sphere is ready. Replay and load are refused while someone is riding.

Records use `random-touch/2` and `user://random-touch-lines-001.json`. Earlier autonomous-study records are rejected because their range and time model differ.

### motion_record.gd

<!-- student-code:motion_record.gd -->

{{MOTION_CODE}}

### random_touch.gd

<!-- student-code:random_touch.gd -->

{{SCENE_CODE}}

## Compare, keep, reconstruct

First check that all three spheres wait. Ride the first, release, then try the faster line. Keep the targets fixed. Finally try X plus Y. Record which ride, elapsed moment and observation you want to investigate. Have someone reconstruct the scene and compare the retained data before comparing sensations.

Check release independently: withdraw a VR hand or drop the desktop grab. Carry must stop, and the sphere returns alone. A wall must remain solid during the ride. This confirms interaction rules; it cannot establish whether the movement is interesting or comfortable in a headset.

For a further experiment, change only the fast rate from 1.6 to 1.2. The corresponding comparison time becomes `t * 0.8 / 1.2`. Preserve the changed recipe separately and update its schema identifier; the validator deliberately rejects mismatched rate recipes.

At the RAND page, hold one group of digits and compare selecting that group with retaining a whole movement record. The [colour-grid reconstruction](seed-picture-extension.md) remains optional. The 48-value bench remains the first research pilot. Carry the explicit target array and the distinction between a value and its assigned consequence onward to Random Entropy.

<!-- @ -->
