# Random Definition

Two grids from one seed, and one button that breaks the match. The order below is the order of the encounter.

Look before pressing. Find a patch of the left grid you could not have predicted. Check the same patch in the right grid.

Press REPLAY. Both grids are rebuilt from their seeds:

```gdscript
func _column_seeds() -> Array:
	match comparison:
		"replicas", "offset":
			return [_current_seed, _current_seed]
```

Under `comparison=replicas` the two columns share one seed, so they are the same grid built twice.

Read the colouring loop. It is the whole procedure:

```gdscript
_rng.seed = s
for mi in cubes:
	var mat: StandardMaterial3D = (mi as MeshInstance3D).material_override
	mat.albedo_color = Color(
		_rng.randf(),
		_rng.randf(),
		_rng.randf()
	)
```

Three draws per cell, row by row: 192 per grid, as the panel says.

Press RANDOM. A new seed is chosen from a generator that belongs to this artifact, so nothing else in the hall is disturbed:

```gdscript
func _randomize_seed() -> void:
	_current_seed = _pick.randi() % 1000
	_regenerate()
```

Move the slider to a seed of your own, then return it. The same seed reconstructs the same grid across an intervening change.

Press +1 DRAW. The right-hand grid asks the generator for one value and discards it before colouring:

```gdscript
if _extra_on and i == _columns.size() - 1:
	for k in range(extra_draws):
		_rng.randf()
```

Same seed, same cells, different picture. Press again to mend it. Reproducibility belongs to the seed, the generator and the draw order together.

Then turn the crank machine across the room, which advances a generator one state at a time, and read the true-versus-pseudo bench beside it.

The next room, Entropy, asks what a number can retain from a sequence.
