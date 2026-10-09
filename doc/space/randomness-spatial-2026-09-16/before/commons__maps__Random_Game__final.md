# Told, or finding out

In the mushroom bed, a draw helped decide which body appeared. Here it helps decide whether a body will still be there when yours arrives.

<!-- @r_c -->

Three cyan stones cross a rectangular pit. Their tops stand a little above the museum floor. Beyond them, a prism carries a five-digit number. Watch the middle stone before stepping onto it. When it leaves, what would you be standing on?

The stone turns orange and sinks. The bed below remains. Then green, a rise, cyan again. Watch a second cycle. The order may already feel familiar while the pauses refuse to settle into a beat.

The stele at the lip names four states: IT STANDS, IT LEAVES, IT IS GONE, IT RETURNS. The procedure follows that order. A draw supplies the standing wait:

```gdscript
var visible_wait: float = _next_random_wait()
_note_step("stands", visible_wait)
await get_tree().create_timer(visible_wait).timeout
```

Inside the function, the interval becomes a number:

```gdscript
return _rng.randf_range(min_wait, max_wait)
```

For this crossing, the standing wait lies between 2.4 and 4.6 seconds; the hidden wait between 1.1 and 2.2. Sinking, rising and the short collider delays take additional time. Knowing those bands does not name the next draw.

Look at the tablet beside the pit. Each stone has a line: its present state, the last drawn wait and the time left of that wait. Now you can know something that watching cyan alone withheld. The current pause has already been chosen. The next one has not yet been drawn.

```gdscript
_step_wait = wait_seconds
_step_until_ms = Time.get_ticks_msec() + int(round(wait_seconds * 1000.0))
```

The counter reads the stored deadline. It does not keep asking for another duration. During LEAVES and RETURNS, the tablet retains the preceding draw at zero remaining time: it is an account of a wait, not a new measurement of movement.

Try the first stone when it stands. Its top is 22 centimetres above the hall floor, approached by a ramp and short landing; the spaces between stones are twelve centimetres. A stone can leave while you are on it. The pit has a bed 1.02 metres below the hall floor and a ramp up its west side. The corridor east of the pit also reaches the far lip. Crossing is one way to investigate this room; going around is another.

Watch the gold rings. They light during the final 1.2 seconds of a standing wait. Press CUE and try observing without them. Each stone still has a small beacon that lights during its movement. The tablet still shows its deadline. This experiment changes the notice carried by the stones; it does not remove every way to anticipate them.

Neither cue draws another wait. Yet the same next event becomes available to you differently: a ring before movement, a beacon during it, a number on a surface you must turn toward. Before describing a missed step as poor timing, ask where its warning was readable.

There is another separation under your feet:

```gdscript
_set_collision_enabled(false)
_set_state(CycleState.HIDDEN)
```

The collider remains enabled through the sink and its short delay. It is disabled while the stone is hidden, then enabled before the rise. Appearance, movement and support have separate instructions. A dim shape below you is not necessarily something the collision system will hold you on. The bed supplies the recovery surface.

REPLAY returns all three stones to their standing positions and restarts their seeded waits. Try it after a stone has begun moving. A repeated seed would mean little if an earlier motion kept pulling that stone down. Restarting must also cancel the old motion and restore support.

The prism names this local construction. NEW SEED chooses a different current number; an older number may eventually return. REPLAY does not rewind the other artifacts or the visitor. You bring knowledge from the previous attempt into a crossing whose first waits have been restored.

<!-- @cube_projectile_spawner -->

Further into the hall, cubes arrive from above. Watch from the edge before entering their space. Does the interval between arrivals vary in the way the stones' pauses did?

At the housed panel, press RUN / STOP. Wait. Some cubes continue moving. Press CLEAR and compare what disappears. Stopping the source did not recall what it had already released. Clearing the flights leaves the source's running state as it was, so stop it first when you want an empty field that stays empty.

Here the timer attempts a launch every half-second. It skips the attempt if 24 projectiles are already active. The irregularity begins elsewhere:

```gdscript
var spawn_pos = field_origin + Vector3(
    _rng.randf_range(-half_w, half_w),
    field_spawn_height,
    _rng.randf_range(-half_d, half_d)
)
```

Two draws choose x and z in an eight-metre square. Height is fixed at eight metres above the field origin. The floor lines mark that region of initial centres. They are neither walls nor a forecast of every place a cube may reach.

Another draw gives an initial downward speed between 1.6 and 2.6 metres per second. Small sideways velocities and later changes let the bodies drift. The projectile carries its own generator. A seed that repeats its launch position does not, by itself, repeat those later changes or its collisions.

The crossing drew a duration. This machine draws positions and velocities on a regular launch clock. Both are called random, but the word cannot tell you where to look. Keep track of which encounter supplied your evidence: a sampled wait at the crossing, or a sampled launch in the field.

<!-- @ -->

The room leaves a more specific question than whether a world is predictable. Which decisions are already made, which are still to come, and what tells us the difference? In Noise Types we will carry that question between neighbouring places. A choice can be uncertain and still have a relation to the choice beside it.
