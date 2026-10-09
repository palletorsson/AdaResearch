# Random Game

A floor tile that leaves on drawn timing, and a crossing built out of three of them. Every line below is from `commons/primitives/cubes/random_cycle_cube.gd`, the artifact the map places as `r_c`.

The order is a loop, and the loop is the same every turn.

```gdscript
func _run_cycle_loop(ticket: int) -> void:
	while is_inside_tree() and ticket == _loop_ticket:
		var visible_wait: float = _next_random_wait()
		_note_step("stands", visible_wait)
		await get_tree().create_timer(visible_wait).timeout
```

Four states in a fixed sequence — IDLE, GOING_OUT, HIDDEN, COMING_IN — with a wait at the two ends of it. The `ticket` is how a restart kills the old loop: anything still awaiting a timer sees a number that is no longer current and returns.

Draw the wait, and only the wait.

```gdscript
func _next_random_wait(kind: String = "stands") -> float:
	var min_wait: float = max(0.1, wait_min_seconds)
	var max_wait: float = max(min_wait, wait_span_seconds)
	if kind == "gone" and hidden_span_seconds > 0.0:
		min_wait = max(0.1, hidden_min_seconds)
		max_wait = max(min_wait, hidden_span_seconds)
	if is_equal_approx(min_wait, max_wait):
		return min_wait
	return _rng.randf_range(min_wait, max_wait)
```

One band by default, for both ends of the cycle, exactly as the tile shipped. A second band exists only when something sets it: the crossing gives the gone-wait its own, shorter, because a stone that is absent as long as it is present is a coin toss with a one-metre penalty.

Write the deadline down once.

```gdscript
func _note_step(kind: String, wait_seconds: float) -> void:
	_step_kind = kind
	_step_wait = wait_seconds
	_step_until_ms = Time.get_ticks_msec() + int(round(wait_seconds * 1000.0))
```

Before this the drawn number lived inside the timer and nothing could ask how much of it was left. A countdown that re-draws each frame is not a countdown. Everything that reports time — the tablet's bar, the advance cue, a probe — reads `_step_until_ms`, and `step_state()` is the window:

```gdscript
func step_state() -> Dictionary:
	var left: float = max(0.0, float(_step_until_ms - Time.get_ticks_msec()) / 1000.0)
```

Switch the support with the state, not with the picture.

```gdscript
		_set_collision_enabled(false)
		_set_state(CycleState.HIDDEN)
```

```gdscript
func _set_collision_enabled(enabled: bool) -> void:
	if _collision_shape:
		_collision_shape.disabled = not enabled
```

The collider goes after `disable_collider_delay` and comes back before the rise, so the tile is briefly a picture without support and briefly support without having arrived. Those are two facts about one tile, and the room keeps them apart.

Say what is about to happen, or say what is happening.

```gdscript
	_crown.visible = advance_seconds > 0.0 and _step_kind == "stands" and left <= advance_seconds and left > -0.05
```

`advance_seconds` is 0 in every shipped placement, which leaves the tile its original signal: an emissive mote lit while the block moves. Above 0 it earns a crown ring, lit while the block still stands and the stored deadline is inside the window. The machine is identical either way; what differs is when a body may commit.

Stage the crossing.

```gdscript
func _pit_half() -> Vector2:
	var along: float = float(stone_count - 1) * CH_PITCH * 0.5 + 0.5 - CH_LAP
	return Vector2(max(1.5, pit_width * 0.5), along)
```

The pit is derived, not measured: the row's length sets how far it reaches along the crossing, and the end stones lap their lips by `CH_LAP`, which is the step a body takes onto the first one. The hall's own five-by-three hole is that size on purpose.

Lay what the museum does not.

```gdscript
	var bed_size := Vector3(pit.x * 2.0, 0.08, pit.y * 2.0)
	var bed_at := Vector3(0.0, CH_BED - 0.04, 0.0)
```

A `0` cell in a map is a hole the museum lays no floor on, so the bed, the cut sides and the way out are the artifact's own. The drop is one metre and two centimetres by construction, whatever is or is not underneath.

Deal the row from one number.

```gdscript
		stone.set("cycle_seed", _crossing_rng.randi_range(1, 1 << 30))
```

Each stone is another copy of this same scene, handed a seed drawn from the crossing's own generator before it enters the tree; its own `_ready` reads it. One five-digit number therefore fixes all three rhythms, which is what REPLAY replays and what is cut into the idol at the far lip.

Hold the apron still while the tile falls.

```gdscript
	_crossing.position.y = _crossing_base_y - (position.y - _base_position.y)
```

The staging is the tile's child, and the tile sinks by moving itself. Cancelling the sink out of the staging's offset is what keeps the floor betraying you from taking the room with it.

Stage it in a map.

```
r_c#stand:chasm#cue:advance
```

`stand:chasm` builds the crossing at the tile's cell, which must be the centre of the hall's pit; `cue` chooses between the shipped beacon and a genuine advance ring; `count` sets how many stones (odd, so this tile stays the middle); `size` the pit's width; `seed` pins the crossing's name. Without the token the tile is what it always was: one cube in a floor, on one band of drawn waits.
