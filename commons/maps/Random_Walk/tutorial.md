# Random Walk — draw, fold, keep

The primary is `random_walk_terrarium:90#stand:logbook` at map cell (4,1). Read the final passage as the encounter; use this chapter to follow the implementation. All GDScript excerpts are from `commons/artifacts/random_walk_terrarium/random_walk_terrarium.gd`.

## What the previous rooms supply

Coordinates locate the bead, a vector proposes its displacement, an array keeps sampled positions, and repeated addition accumulates movement. Random Remove asked which addresses a draw could choose. This room asks what follows when the choice changes a position and the enclosure then corrects it.

## Try the rule before naming it

Follow red under ONE. Predict a direction, then compare 2D and 3D. Move around a suspected crossing. Try LEVY last. The cabinet has no pause control; mode changes and RESET restart the run. The logbook wing offers ONE, ALL and NEW SEED.

## Draw a heading

```gdscript
		WalkMode.WALK_2D:
			var angle = _rand() * TAU
			return Vector3(cos(angle), 0, sin(angle)) * step_size
```

One draw chooses an angle in the xz plane. The proposed length is 0.015 m and the y increment is zero. In 3D two draws produce a uniformly sampled direction on the sphere:

```gdscript
			var theta = _rand() * TAU
			var phi = acos(2.0 * _rand() - 1.0)
			return Vector3(
				sin(phi) * cos(theta),
				sin(phi) * sin(theta),
				cos(phi)
			) * step_size
```

Here theta is the xy azimuth and z is the polar coordinate. Do not describe this as adding a y component to an unchanged 2D path. The draw consumption also changes: one, two or three draws per walker per step in 2D, 3D or LEVY. All five walkers share this private generator in a fixed order.

LEVY uses the same 3D direction construction, then draws a length:

```gdscript
			var u = _rand()
			var levy_step = step_size * pow(u + LEVY_OFFSET, LEVY_EXPONENT)
			levy_step = minf(levy_step, step_size * LEVY_STEP_CAP)
			return direction * levy_step
```

With offset 0.01 and exponent −0.5, the proposed lengths range from approximately 0.01493 to 0.15 m. The power already bounds the maximum at ten base steps. Under an ideal uniform draw, length > 0.10 m corresponds to u < 0.0125: about one in eighty. This is a bounded power-law rule; it does not instantiate an unbounded Lévy process or a full physical model of Brownian motion.

## The enclosure participates

```gdscript
	if pos.x < -half.x: pos.x = -half.x + (-half.x - pos.x)
	if pos.x > half.x: pos.x = half.x - (pos.x - half.x)
```

The box spans x,z = −0.25..0.25 and y = 0..0.4. An endpoint past a wall folds back by its overshoot. Under 2D, y is pinned to 0.2. With these defaults, even the 0.15 m maximum proposal is shorter than the smallest half-extent, so the single reflection per side suffices. Arbitrary larger configuration values would need a separate boundary review.

The accepted increment may differ from the proposal. The connected trail is a chord between accepted samples, not a collision path that includes the wall-contact point. After reflection, even fixed-length proposals can yield shorter displayed segments.

## Keep an ordered window

```gdscript
		_walker_trails[i].append(_walker_positions[i])
		if _walker_trails[i].size() > trail_length:
			_walker_trails[i] = _walker_trails[i].slice(1)

		_walker_positions[i] = new_pos
```

The default trail keeps 200 positions before their updates. At step N it contains positions max(0,N−200)..N−1; the bead is at N. No trail term appears in the generator or boundary rule. A controlled test can delete this history and continue the same positions. That is an internal test, not an eraser control offered to the visitor.

## Distinguish step time from frame time

```gdscript
	var interval = 1.0 / maxf(steps_per_second, 0.001)
	_step_timer = minf(_step_timer + delta, interval * MAX_CATCHUP_STEPS)

	while _step_timer >= interval:
		_step_timer -= interval
		_step_all_walkers()
```

The cadence is 30 step batches per second, with five walkers advanced in each batch. A two-second frame accepts five batches and discards the excess time. The logbook's frame clock still gains two seconds; the simulation-time field gains 5/30 seconds. No backlog remains to be recovered in later frames.

## Replay a procedure

```gdscript
	if walk_seed >= 0:
		if _rng == null:
			_rng = RandomNumberGenerator.new()
		_rng.seed = walk_seed
```

RESET restores the centre positions, clears trails and counters, and re-seeds this room's generator. It does not clear the residual step timer or logbook refresh accumulator. Compare equal step counts rather than assuming identical timestamps after reset. The generator implementation, mode, population and draw order must also agree.

NEW SEED explicitly rejects the immediately current number, but can revisit an earlier one. ONE/ALL affects visual emphasis only. The unconfigured artifact uses `walk_seed = -1` and the global stream; resetting it does not rewind that stream. The room's named private seed makes a stronger replay promise.

## Read the measurement

MSD is the average of five squared distances from (0,0.2,0), in square metres. It can rise or fall. The finite box gives bounds of 0.125 m² in 2D and 0.165 m² in 3D/LEVY; these are geometric upper bounds, not promised plateaus. It measures neither total distance travelled nor the complexity of the line.

Next: Random Gaussian. Keep the distinction between a draw, an accumulation and the way a display gathers its evidence.


## Spatial staging — 16 September 2026

The map keeps a reachable instrument alongside its spatial applications. `map_data.json` is authoritative for placements. `#controls:compact` gathers the existing Rack panels, preserving their callbacks, into an 80 cm console. `#glass_width` opts into an enclosure with open entrances; its grid marks are not floor colliders.

### Gallery, basin, field

Following Transformation staging, a 2.5 m basin separates the existing glass field from the gallery. The source floor cuts the moat; it is not a dark decal. Two bridges and the inner apron stay at gallery level. Outer glass rails border the gap, with openings at the bridges. The field retains its existing walk and raised-cell behaviour.
