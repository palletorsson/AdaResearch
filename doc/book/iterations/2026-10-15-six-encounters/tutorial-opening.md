# Follow the difference

<!-- @random_touch -->

Begin with the three moving spheres. Follow the left sphere with your hand, then the middle one. The middle travels through the same horizontal targets twice as fast. Finally follow the right sphere: its sideways motion matches the left, but it also moves up and down. What changed in your attention or ability to remain near it? Nothing requires the faster movement to feel better or worse.

This is also our first construction. We will keep the movement record and alter its use: first timing, then permitted axes. In VR, contact can produce vibration cues. Those cues signal proximity; they do not supply resistance. Desktop selection lets us inspect the moving points without pretending to reproduce that sensation. Neither mode carries the avatar in this opening study.

## What you bring and what is new

Bring positions, vectors and elapsed time from the earlier movement and Wavefunctions studies. A vector's X component moves sideways; Y moves vertically. Keep the existing museum player, camera, lights and XR Tools. We reuse the [PointBody](../../artifacts/ignorance_gallery/point_body.gd), through the [path-preserving point](../../artifacts/random_return/ride_point.gd). The latter keeps a point on its authored path during a grab rather than making it follow the controller. The existing stage and rectangular-button library supply the interface.

A **pseudorandom generator** is a calculation with a changing internal state. Each request advances that state. A **seed** establishes the starting state. Repeating the seed and request procedure repeats the sequence; it does not independently specify the object's speed, axes or smoothing.

The new operation makes 48 pairs of target coordinates inside a range of −0.38 to +0.38 metres. One generator produces X; another produces Y. Their separation matters: adding vertical movement must not consume additional requests from the horizontal generator and silently change the comparison. The record stores the actual targets as well as the seed, rates and current time. Replay uses that stored path.

## One target path, three readings

The first lane advances through 0.8 target segments each second. The second advances through 1.6. The third uses the first rate and its X coordinates, then adds the retained Y coordinates. Both horizontal spheres stay at their starting height.

For a simple trace, imagine successive X targets −0.2 and +0.2. Halfway through the segment, the sphere is at zero. The slow lane reaches that midpoint after 0.625 seconds; the fast lane after 0.3125 seconds. We smooth the fraction `u` with `u * u * (3 - 2 * u)` before mixing the endpoints. This slows the motion near each target; a randomly chosen target does not require a sudden jump. The final target connects back to the first, so this finite record loops.

Before running, predict two comparisons: the fast lane at time `t / 2` should match the slow lane at time `t`; the third lane's X coordinate should match the first at equal times. The added Y coordinate should never change either result.

## Reconstruct the apparatus

Create a study folder in this project. Save the two complete files below beside each other, then attach `random_touch.gd` to an empty upright Node3D at unit scale. It creates the three points, contact areas, labels and controls; there are no unnamed children to prepare. Use the established study bay in Random Definition, hall-local `(10.5, 0, 18.5)`, facing into the room with Y rotation −90 degrees. Keep access to the museum's player and interaction system.

The `res://` dependencies in the second file are supplied project components, not files to invent. The scene stores kept trials at `user://random-touch-001.json`. KEEP writes the targets and elapsed time; LOAD restores that moment paused. REPLAY starts the retained path from its beginning. PAUSE holds or resumes it. A rejected load leaves the current path available.

Read `make_record()` and `offset()` first. The validation code protects an imported comparison from missing or out-of-range data. The second file assembles the encounter and handles contact; it does not choose extra random targets during playback.

### motion_record.gd

<!-- student-code:motion_record.gd -->

{{MOTION_CODE}}

### random_touch.gd

<!-- student-code:random_touch.gd -->

{{SCENE_CODE}}

## Compare, keep, reconstruct

Run the scene, keep a moment, and write down which lane you followed and what you noticed. Load the moment and resume; then replay from the beginning. Retain the JSON file with your observation. Have another person reconstruct the study from these files and compare the saved targets and settings before comparing impressions. Technical agreement and agreement about a sensation are different outcomes.

For one further variation, change only the fast lane's rate from 1.6 to 1.2 in `RATES`, regenerate a record and preserve it separately. The corresponding matching time becomes `t * 0.8 / 1.2`. The validator intentionally rejects a record with another rate recipe; update the recipe identifier if keeping both versions in a continuing study. Do not silently compare a changed speed, range and random path at once.

The next question may concern holding a number rather than following it. Visit the RAND page, keep one group, and compare that act with saving the entire target record. The final follows this question through the six main room encounters. It does not require six new programming lessons here.

The [colour-grid reconstruction](seed-picture-extension.md) remains an optional worked extension: use draws as red, green and blue, then discard one draw and inspect the consequences. The 48-value bench remains the first research pilot; this movement opening is a new comparison, not a replacement of its evidence. For Random Entropy, carry forward the local generator, an explicit retained array and the distinction between a value and the job assigned to it. The next lesson creates a new record of countable symbols.

<!-- @ -->
