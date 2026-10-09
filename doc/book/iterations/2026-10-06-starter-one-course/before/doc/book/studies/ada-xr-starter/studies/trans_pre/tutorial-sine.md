# A different way to arrive

The cube rises at a steady speed and reverses at the top. What changes if it slows before turning back?

In `studies/trans_pre/motion.gd`, set `stage` to `1`. Replace the line that calculates `t` with:

```gdscript
    var t := (sin(TAU * elapsed / (2.0 * leg_seconds)) + 1.0) / 2.0
```

Run again. The cube has the same lower and upper heights. It reaches them at the same times. Between them, its speed changes: fastest through the middle, slowing to zero at each end.

`sin()` returns the sine of an angle in radians, a value between −1 and 1. `TAU` is a full turn. The expression inside `sin()` advances one turn over `2.0 * leg_seconds`, which is three seconds here. Adding 1 and dividing by 2 changes the output range to 0–1, ready for our existing `lerp`.

Set `leg_seconds` to `3.0`. The complete cycle takes six seconds. The height range stays fixed. Restore `1.5`, then set `travel` to `0.4`. The movement reaches farther, but its cycle still takes three seconds.

We can use a periodic function before studying how it relates to a circle, other waves or sound. Here we have learned to change its duration and extent. The later Wave Functions sequence returns to its structure.

The museum's Trans_Pre cubes keep the linear version. This is a comparison you can make in the student study. Restore the `pingpong` line before continuing the main lesson, or retain the sine version in a separate saved copy.
