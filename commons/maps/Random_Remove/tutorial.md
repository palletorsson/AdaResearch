# The set before the choice

Random Definition gave us a procedure that can return. Random Entropy showed what counting leaves out. At this bench, look first for a cube whose chance of removal is zero.

## Find the boundary before drawing

Sixteen amber cubes form a 4×4 range, columns 2–5 and rows 2–5. Forty-eight grey cubes stand outside it. Read the set on the cased plate to the left. Use REMOVE ONE on the right: one candidate becomes red for 0.3 seconds, then disappears while its address plate remains.

Follow a grey cube through several removals. Its exclusion comes from the filter in `algorithms/randomness/RemoveRandom.gd`:

```gdscript
	match selection_mode:
		"All": return true
		"Column": return is_equal_approx(pos.x, float(target_column))
		"Row": return is_equal_approx(pos.z, float(target_row))
		"Range":
			return pos.x >= x_min and pos.x <= x_max and pos.y >= y_min and pos.y <= y_max and pos.z >= z_min and pos.z <= z_max
```

These coordinates belong to the explicit grid. Its instances sit at integer x/z addresses, then the whole MultiMesh is scaled by 0.14 and placed on the table. Row 3 stays row 3 when the museum turns the bench.

The candidate list keeps the permitted indices, skipping earlier removals:

```gdscript
		if _removed.has(i):
			continue
		var included := _should_include_instance(_original[i].origin)
		if included:
			active_instances.append(i)
```

## Draw within the remaining set

Only the remaining candidates reach the draw:

```gdscript
	var offset := _rng.randi_range(0, active_instances.size() - 1)
	var index := active_instances[offset]
```

On the first RANGE draw there are sixteen possible offsets. Next time there are fifteen. A cube that survives has a changing chance on the next press: 1/16 initially, then 1/15 if it remains. The forty-eight excluded cubes keep chance zero throughout this run. Exhausting the set removes every candidate exactly once, so randomness determines the order while the initial range determines the final empty shape.

The selected cube goes red. After the delay, a valid pending operation scales its transform to zero and removes its index from the candidate list:

```gdscript
	transform.basis = Basis().scaled(Vector3.ZERO)
	multimesh.set_instance_transform(index, transform)
	_removed[index] = true
	active_instances.remove_at(offset)
```

The slot plate and board remain. This operation does not remove museum floor or create a traversable pit. The original transforms remain in memory for RESET.

## Replay a procedure, then change a rule

RESET restores all transforms and, on this bench, resets the private removal generator:

```gdscript
	if replay_on_reset:
		_rng.seed = run_seed
```

Compare ROW and COLUMN under the same seed. Both start with eight candidates, so they use equal bounds on every draw and choose equal offsets in their respective lists. One set runs across row 3; the other down column 3. Their counts agree while their available places differ.

RANGE and ALL have sixteen and sixty-four candidates. The draw bounds now differ, so the same seed is insufficient to claim the same offsets. NEW SEED picks a five-digit value through the fixture and resets. A repeated seed is possible. The bench exposes the chosen value but has no seed-entry control.

## What waits, and what is cancelled?

There is no START or STOP button on this fixture. The remover has a timer API; this bench uses one press per removal. Waiting between completed removals does not consume removal draws. During the red highlight a second REMOVE ONE press is ignored. RESET or a mode change invalidates the pending operation:

```gdscript
	if generation != _generation or not is_inside_tree():
		return
```

The older draw cannot return from its delay and erase a cube in the new run. That small guard is part of what makes a reset mean a beginning.

Keep an unfinished pattern before resetting. Its visible gaps preserve some of the history that a completely emptied range would lose. Random Walk will make each choice alter where a body goes and which choices are available next.


## Spatial staging — 16 September 2026

The map keeps a reachable instrument alongside its spatial applications. `map_data.json` is authoritative for placements. `#controls:compact` gathers the existing Rack panels, preserving their callbacks, into an 80 cm console. `#glass_width` opts into an enclosure with open entrances; its grid marks are not floor colliders.

`random_removal_arena` uses the existing owned-set `RemoveRandom` algorithm and one collider per cell. Entry and accumulated walking request draws; a reset restores both drawings and support. The basin fire uses the museum death/respawn path.
