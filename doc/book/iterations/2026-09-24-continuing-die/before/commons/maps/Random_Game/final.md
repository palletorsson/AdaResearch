# Told, or finding out

In the mushroom bed, a draw helped decide which body appeared. In the gallery it became paint, an estimate and a path. In the last room it shifted the layers of a texture. Here it helps decide whether a body will still be there when yours arrives.

<!-- @r_c -->

Three cyan stones cross a rectangular pit. Their tops stand a little above the museum floor. Beyond them, a lit prism stands on a plinth whose face carries a five-digit number. Watch the middle stone before stepping onto it. When it leaves, what would you be standing on?

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

Watch the gold ring on the middle stone. It lights during the final 1.2 seconds of that stone's standing wait. Press CUE and try observing without it. Each stone still has a small beacon that lights during its movement. The tablet still shows its deadline. This experiment changes the notice carried by the stones; it does not remove every way to anticipate them. Press CUE again and all three stones carry a ring.

Neither cue draws another wait. Yet the same next event becomes available to you differently: a ring before movement, a beacon during it, a number on a surface you must turn toward. Before describing a missed step as poor timing, ask where its warning was readable.

There is another separation under your feet:

```gdscript
_set_collision_enabled(false)
_set_state(CycleState.HIDDEN)
```

The collider remains enabled through the sink and its short delay. It is disabled while the stone is hidden, then enabled before the rise. Appearance, movement and support have separate instructions. A dim shape below you is not necessarily something the collision system will hold you on. The bed supplies the recovery surface.

REPLAY returns all three stones to their standing positions and restarts their seeded waits. Try it after a stone has begun moving. A repeated seed would mean little if an earlier motion kept pulling that stone down. Restarting must also cancel the old motion and restore support.

The plinth names this local construction. NEW SEED chooses a different current number; an older number may eventually return. REPLAY does not rewind the other artifacts or the visitor. You bring knowledge from the previous attempt into a crossing whose seeded waits have restarted: every REPLAY deals the same first waits, though the middle stone's are not the ones it began with when the hall was built.

<!-- @random_removal_arena -->

The next glass enclosure carries the removal rule under your feet. Here there are eighty-one cells. Entering selects one; walking farther asks for more. Red gives a short warning, then both the visible cell and its support disappear. The basin below burns. The dark apron remains a route around the changing set, and the console outside the entrance can restore it. This is a deliberate return to Random Remove: the floor you walked there, smaller now, stands between the crossing and the doors.

<!-- @random_doors -->

Beyond it, three doors face you. Stay at the console behind the amber line and choose one. A door lifts. It might remain a passage. It might announce fire, wait one second, then send a short jet toward the line. Watch before moving forward.

One door is assigned passage at the beginning of the round:

```gdscript
rng.seed = run_seed
safe_door = rng.randi_range(0, 2)
```

The other two are assigned fire. Pressing a button reveals an existing choice; it does not redraw the outcome. A jet reaches 2.7 metres and then stops. That door closes again. The passage stays open until reset. There is always one passage in this construction, because we wrote that guarantee before drawing its index.

REPLAY restores the same assignment. NEW SEED makes another seeded round, which may choose the same passage. The doors begin from the same seed each time the hall is built, so until someone presses NEW SEED the passage is the same door for every visitor. After looking once, your next attempt is different even when the doors are not. Memory belongs to the player as well as to the machine.

<!-- @cube_projectile_spawner -->

After the doors, cubes arrive from above. Watch from the edge before entering their space. Does the interval between arrivals vary in the way the stones' pauses did?

At the console in front of the field, press RUN / STOP. Wait. Some cubes continue moving. Press CLEAR and compare what disappears. Stopping the source did not recall what it had already released. Clearing the flights leaves the source's running state as it was, so stop it first when you want an empty field that stays empty.

Here the timer attempts a launch every half-second. It skips the attempt if 24 projectiles are already active. Each cube lasts ten seconds, so no more than about twenty are alive at once and that limit never binds here; the readout on the dark case beside the field shows the count. The irregularity begins elsewhere:

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

At the last podium, wait for a small wooden cube. It drops from three metres above the floor onto a two-metre-square surface. Another arrives at the other position. The positions alternate; after the first one-second wait, each new delay is drawn between 0.3 and 1.3 seconds. The places are dependable while the rhythm is not.

Pick one up. In a headset, arrivals wait while either cube is held; a desktop carry does not pause them. Release it and the waiting continues. There are at most two cubes: an arrival replaces the cube in its alternating slot. RUN / STOP holds the arrival clock, leaving released cubes to fall. REPLAY restores the arrival sequence, not the history of your hand or an identical physical landing.

Beside the podium, five cutout profiles recede into the room. Their uneven horizons sit around eye height, 1.7 metres. The nearest is dark; those behind grow lighter. Move sideways and watch one contour uncover another. A landscape appears between flat panels.

Each panel joins seventeen heights. The two ends are fixed; the interior samples vary, with smaller permitted deviations near the edges. PROFILE changes the contours. The nearest, darkest panel shares the podium's seed, so until you press PROFILE its fifteen interior heights trace the first fifteen drawn cube delays, the ones REPLAY brings back, flattened toward its ends. Read that ridge from the end nearest the podium: a point above the level of the fixed ends stands for a wait longer than 0.8 seconds. The panels behind it are separate draws, and so is every contour after PROFILE. Here you can look back and forth along the sequence. At the podium you had to wait through it. What did seeing the whole shape let you anticipate?

<!-- @ -->

The room leaves a more specific question than whether a world is predictable. Which decisions are already made, which are still to come, and what tells us the difference? In Noise Types we will carry that question between neighbouring places. A choice can be uncertain and still have a relation to the choice beside it.
