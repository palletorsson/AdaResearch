# Random Walk

A position, a step, a drawing. Every excerpt below is from `commons/artifacts/random_walk_terrarium/random_walk_terrarium.gd`, the tank on the cabinet.

Draw one number. Everything the walk decides comes through this function, from the global stream by default or from a private generator once a seed is named:

```gdscript
func _rand() -> float:
	if walk_seed < 0:
		return randf()
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = walk_seed
	return _rng.randf()
```

Turn the number into a step. In 2D the length is fixed and only the heading is drawn:

```gdscript
		WalkMode.WALK_2D:
			var angle = _rand() * TAU
			return Vector3(cos(angle), 0, sin(angle)) * step_size
```

In 3D two draws pick a direction on the sphere; the length stays fixed. LEVY keeps the direction and draws a length as well:

```gdscript
			var u = _rand()
			var levy_step = step_size * pow(u + LEVY_OFFSET, LEVY_EXPONENT)
			levy_step = minf(levy_step, step_size * LEVY_STEP_CAP)
			return direction * levy_step
```

With the offset at 0.01 and the exponent at −0.5 the power never exceeds ten, so the cap of ten step-lengths is reached, not overrun.

Add the step, fold it back at the glass, and record the position before it changes:

```gdscript
		var step = _generate_step()
		var new_pos = _walker_positions[i] + step

		# Boundary reflection
		new_pos = _reflect_boundaries(new_pos)

		# Record trail
		_walker_trails[i].append(_walker_positions[i])
		if _walker_trails[i].size() > trail_length:
			_walker_trails[i] = _walker_trails[i].slice(1)
```

The trail keeps `trail_length` positions, two hundred here; the walker keeps one. Nothing the step does reads the trail.

Fold at the wall. An overshoot comes back by the distance it overshot; in 2D the height is pinned to the middle plane:

```gdscript
	if pos.x < -half.x: pos.x = -half.x + (-half.x - pos.x)
	if pos.x > half.x: pos.x = half.x - (pos.x - half.x)
```

```gdscript
	else:
		pos.y = terrarium_size.y / 2.0
```

Pace the steps. Frame time is accumulated and spent in whole steps, and a long frame is capped so it cannot dump a second of steps into one jump:

```gdscript
	var interval = 1.0 / maxf(steps_per_second, 0.001)
	_step_timer = minf(_step_timer + delta, interval * MAX_CATCHUP_STEPS)

	while _step_timer >= interval:
		_step_timer -= interval
		_step_all_walkers()
```

Simulation time is steps over the cadence, thirty a second. The wing's plate prints both clocks so you can watch them drift apart.

Decide what RESET means. Without a seed the stream simply continues and a reset is a new walk. With a seed the generator is re-seeded first, and the same walk returns:

```gdscript
	if walk_seed >= 0:
		if _rng == null:
			_rng = RandomNumberGenerator.new()
		_rng.seed = walk_seed
```

The logbook names a five-digit seed on its plate; NEW SEED draws another from a private generator, never from the global stream. Press 2D, then 3D, under one seed: the first draw is the heading in the plane in one and the azimuth on the sphere in the other. The same number, another rule, another place.

The next room, Random Gaussian, gathers many draws into a distribution.
