# Random Remove

Randomness deletes — but only from a set a rule chose first. Every excerpt below is from `algorithms/randomness/RemoveRandom.gd`, the room's remover, which with `#local_grid:true` builds its own eight-by-eight bench (`remove_random_fixture.gd`).

Decide who is eligible. One question, asked of every cube's own board position:

```gdscript
	match selection_mode:
		"All": return true
		"Column": return is_equal_approx(pos.x, float(target_column))
		"Row": return is_equal_approx(pos.z, float(target_row))
		"Range":
			return pos.x >= x_min and pos.x <= x_max and pos.y >= y_min and pos.y <= y_max and pos.z >= z_min and pos.z <= z_max
```

Collect the candidates, skipping cubes already gone, and colour every cube by the answer:

```gdscript
		if _removed.has(i):
			continue
		var included := _should_include_instance(_original[i].origin)
		if included:
			active_instances.append(i)
		if multimesh.use_colors:
			multimesh.set_instance_color(i, ELIGIBLE if included else EXCLUDED)
```

Draw one — an even choice among the remaining candidates and nothing else:

```gdscript
	var offset := _rng.randi_range(0, active_instances.size() - 1)
	var index := active_instances[offset]
```

Show it, then take it: the cube's own transform scaled to nothing, its slot plate kept:

```gdscript
	transform.basis = Basis().scaled(Vector3.ZERO)
	multimesh.set_instance_transform(index, transform)
	_removed[index] = true
	active_instances.remove_at(offset)
```

Put everything back, and on the bench put the generator back too, so the same order repeats:

```gdscript
	if replay_on_reset:
		_rng.seed = run_seed
```

Name a run's seed, or start another:

```gdscript
func set_random_seed(value: int) -> void:
	_rng.seed = value
	run_seed = value
```

## Try
1. Count the amber cubes before pressing anything. Find a grey one and keep it in mind.
2. REMOVE ONE, sixteen times. Watch the highlighted cube before each goes; read the column and row on the line above the board.
3. RESET and empty the square again: the same order. NEW SEED: another order, the same final square.
4. Keep a seed and change the rule: ROW, then COLUMN. The same draws, different cubes.
5. Ask what the grey cube's chance was in every one of these runs.

## Where it goes
Random_Walk, on the route: a walker takes its steps from draws like these, and the set of places it can reach is decided one step at a time.
