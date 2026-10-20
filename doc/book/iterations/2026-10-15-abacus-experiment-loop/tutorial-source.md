# Touch and be moved

<!-- @random_touch -->

Five one-metre rods sit before a pale recording wall. A dark bead waits at each centre. Touch starts movement: one virtual hand follows the bead, and circles accumulate behind it. Rows 1–4 share an X path at ½×, 1×, 2× and 4× speed. Row 5 adds Y at 1×. Can the same path make a different encounter while leaving the same ink?

In VR, contact or grabbing starts movement. Withdraw the physical controller more than 20 centimetres from the contact position to release. Only the contacting virtual hand follows; the tracked controller, head, body and other hand remain unchanged. On desktop, right-click grabs or releases; the camera stays still. After release, the bead returns alone. REPLAY clears paths and paper, then waits for contact.

## What stays the same

Bring positions, vectors and elapsed time from the earlier movement studies. X is sideways in the installation; Y is vertical. A **pseudorandom generator** is a calculation with changing internal state. Each request advances it. A **seed** sets its beginning; repeating the seed and request procedure repeats the sequence.

The abacus stores 48 coordinate pairs: the resting centre and 47 generated targets. X stays within ±0.44 metres, Y within ±0.12. Separate generators supply X and Y, so adding Y never consumes another X draw. The targets are uniform: equal-width intervals have equal probability. Saving the actual targets also preserves the path if a later generator implementation changes.

Random Definition starts its instruments from the saved hall seed **435**. Each owns a private stream, so playing the slots does not advance the Geiger. The abacus uses 435 for X and 436 for Y. A seed is not the whole experiment: request order, bounds, mapping and timing also matter.

The window permits explicit seed choices and SEED +1. RESET 435 recalls the saved starting receipt. Loading a retained record can also change the shared seed. Keep 435 throughout this comparison. The frame study cannot reseed the hall; MOVE / KEEP is currently removed from the saved room and is not a required step.

## Time becomes a path and then a mark

Rows 1–4 traverse 0.4, 0.8, 1.6 and 3.2 target segments per second; row 5 uses 0.8. Each clock starts with contact. Idle waiting advances none. Between targets, the fraction `u` becomes `u * u * (3 - 2 * u)`: **interpolation** that slows near each endpoint. After the last target, the path returns to the first.

For targets −0.2 and +0.2, the midpoint is zero. Row 2 reaches it 0.625 seconds into that segment; row 3 takes 0.3125. More generally, row 2 at `t` matches rows 1, 3 and 4 at `2t`, `t/2` and `t/4`. Row 5 shares row 2's X at equal times.

The wall stamps twelve circles at equal time fractions of each segment. Equal numbers of steps produce identical X marks at all four speeds; equal durations need not. Waiting and the empty return add none. Each row keeps its latest 576 marks. Dark patches record overlapping interpolated positions, not a histogram of generated targets or evidence of true randomness.

## Build a copy we can investigate

Work inside this AdaResearch project. Save the five complete files below together in a new study folder. Create an upright, unit-scale Node3D named `Abacus`, attach `random_touch.gd`, and add a child Node named `Notebook` with `experiment_notebook.gd`. Save the scene and instance it in a practice scene with the inherited museum player, camera, lights and XR Tools. Place its origin on the floor with the front accessible; allow about 1.3 metres width and 0.55 metres depth.

The four apparatus files reproduce the current artifact. Their `res://` dependencies are inherited project components: the [path-preserving point](../../artifacts/random_return/ride_point.gd), [stage helpers](../../artifacts/randomness_space/museum_exhibit_stage.gd), [hall seed controller](../../artifacts/randomness_space/hall_seed.gd) and rectangular button. The hand follower temporarily replaces XR Tools' hand target; it cannot move the physical hand. Read `make_record()` and `offset()` first, then `advance()` and `_sync_hand()`.

The fifth file supplies desktop/operator recording shortcuts for this reconstruction. The installed room still has only REPLAY. Before running, enter the notebook's `condition`, `question` and `prediction` in the Inspector. While running, select Notebook in Godot's **Remote** scene tree to edit those fields. Keep the game window focused for shortcuts; a VR trial can use an operator at the keyboard.

## One complete experiment

1. **Baseline.** Set `condition` to `baseline-row-2`. Confirm seed 435, uniform targets and empty paper. Touch row 2. Aim for eight steps: 96 marks, about ten seconds. Predict what doubling the speed will preserve.
2. **Keep the moment.** While it is moving, press **Ctrl+Shift+K**. This saves without stopping it. Release afterward. Copy the full file path printed in Godot's Output. Open that JSON and fill `observation` and `next_change`; leave `record` and `record_bytes` untouched. Include what drew attention, felt unclear, or made no difference. The stored seconds expose any overshoot beyond the intended eight steps.
3. **Change one condition.** Release and press REPLAY. Change the notebook condition to `comparison-row-3`, then touch row 3 for eight steps, about five seconds. Save again. Seed, targets, X range, smoothing and mark spacing stay fixed; only rate changes. Compare equal prefixes of the recorded ink if stopping times differ. Does faster arrival change the encounter despite matching marks?
4. **Reopen.** Stop and restart the practice scene. Set Notebook's `load_path` to either saved file, then press **Ctrl+Shift+L**. Release held instruments first. Targets, rates, times, offsets and ink return **paused**; no hand attaches. Check the stored seconds and mark count against the restored scene before continuing.
5. **Resume or replay.** **Ctrl+Shift+P** resumes a loaded state; touch the bead to continue its stored phase. A snapshot taken during an empty return completes that return first. To repeat from the beginning instead, release and press **REPLAY**: targets stay, but times and paper clear. Compare at the same elapsed phase. Ctrl+Shift+P also pauses a running trial, releasing its hand.
6. **Reconstruct independently.** Give another person this chapter, the five files, both recordings and the project revision. Ask them to build a fresh scene and load each file. Compare targets, phase, offsets and ink before asking whether the encounter feels similar. Replaying stored data establishes reproducibility, not newly unpredictable randomness or identical sensation.
7. **Let the observation change the next trial.** If speed changes the encounter but the paper hides that difference, ask what another recording procedure would retain. Or compare rows 2 and 5 at equal elapsed time, changing only the available axes. Record the proposed change, prediction and subsequent observation—even if nothing interesting happens.

Each save creates a new file. Its notebook envelope retains the question and observation separately from the `random-touch/4` record. `record` is the readable view; `record_bytes` packs the same state without losing numeric bits and supplies restoration. Godot's JSON reader can slightly round the readable decimals. Preserve the five source files, engine version and project revision alongside it. An incompatible record is refused. The recording retains prescribed bead state and ink, not physical gestures, actual hand trajectories or feelings. In the shared hall, restoring a seed also resets other participating instruments, so use the practice copy for this comparison.

## Complete files

### motion_record.gd

<!-- student-code:motion_record.gd -->

{{MOTION_CODE}}

### random_touch.gd

<!-- student-code:random_touch.gd -->

{{SCENE_CODE}}

### hand_follower.gd

<!-- student-code:hand_follower.gd -->

{{HAND_CODE}}

### ink_wall.gd

<!-- student-code:ink_wall.gd -->

{{INK_CODE}}

### experiment_notebook.gd

<!-- student-code:experiment_notebook.gd -->

{{NOTEBOOK_CODE}}

## What counts as learning here

Check release and scene removal separately: normal tracking returns, and the head, body, controller and other hand stay unchanged. Those are interaction checks; headset comfort and an independent reconstruction still need observations.

The experiment earns another round through an observable difference, a meaningful question, or a reason to rebuild its apparatus. A mismatch between felt pace and matching ink is a candidate, not a required discovery. Either this tutorial or the final text can propose the next experiment; carry the resulting observation back to both.

The **48-value seed bench remains the first research pilot**: its 48 scalar values become colour, bars, size and rotation. This abacus lesson uses 48 coordinate pairs and does not replace that pilot. At RAND, compare holding one group of digits with retaining this movement record. The [colour-grid reconstruction](seed-picture-extension.md) remains optional. Carry explicit samples and their recording conditions into [Random Entropy](../Random_Entropy/tutorial.md).

<!-- @ -->
