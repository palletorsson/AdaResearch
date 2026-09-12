# Random Mushrooms

A bed of mushrooms built from draws: six templates, eighty candidates gated by a noise field, a template, a facing and a size for each accepted one, then rings and clusters placed on purpose. Every line below is from `algorithms/proceduralgeneration/growth_systems/mushrooms/mushrooms.gd`.

Route every draw through one function.

```gdscript
func _rf() -> float:
	return _pop_rng.randf() if _pop_rng != null else randf()
```

With `population_seed` at its default of −1 the private generator is null and the call falls through to the global `randf()`, the same call in the same order as before. Under a seed, `_pop_rng` makes every draw, and the ground's generator takes the seed plus one.

```gdscript
	if population_seed >= 0:
		_pop_rng = RandomNumberGenerator.new()
		_pop_rng.seed = population_seed
		if ground_seed == 0:
			ground_rng.seed = population_seed + 1
```

Build the six templates once.

```gdscript
	for i in range(mushroom_variety):
		var template = create_mushroom_template(i)
		mushroom_types.append(template)
```

Five kinds by index, and a sixth if glowing mushrooms are on. The templates never enter the tree; the bed is made of their copies.

Scatter candidates and let a noise field refuse some.

```gdscript
	for _i in range(target_count):
		var pos_x = _rf() * meadow_size - meadow_size / 2
		var pos_z = _rf() * meadow_size - meadow_size / 2
		var noise_val = noise.get_noise_2d(pos_x * 2, pos_z * 2)
		if noise_val < -0.3:
			_rejected.append(Vector3(pos_x, get_ground_height(pos_x, pos_z), pos_z))
			continue
```

`target_count` is `mushroom_count * mushroom_density`, eighty with the shipped values. A candidate whose noise falls under −0.3 is recorded and skipped; the rest become positions on the ground.

Copy a template onto each accepted position.

```gdscript
		var type_index = _ri() % mushroom_types.size()
		var mushroom = mushroom_types[type_index].duplicate()
		mushroom.rotation_degrees.y = _rf() * 360
		var scale_factor = _size(0.7 + _rf() * 0.6)  # 0.7 to 1.3
		mushroom.scale = Vector3(scale_factor, scale_factor, scale_factor)
```

Three draws per mushroom: which template, which facing, how big. `_size` returns the draw as it is, or 1 when the size rule is off; the draw is made either way, so the rest of the population does not shift.

```gdscript
func _size(v: float) -> float:
	return v if size_variation else 1.0
```

Place a fairy ring on purpose.

```gdscript
	var radius = 1.0 + _rf() * 2.0
	var count = int(radius * 8)
	for i in range(count):
		var angle = (2.0 * PI / count) * i
		var pos_x = center_x + cos(angle) * radius
		var pos_z = center_z + sin(angle) * radius
```

A centre, a radius, one template for the whole ring, a count set by the radius, and members at equal angles. A member outside the bed is skipped, so a ring at the edge is an arc.

Throw a cluster.

```gdscript
	var count = 5 + _ri() % 10
	for _i in range(count):
		var angle = _rf() * PI * 2
		var distance = _rf() * cluster_size
```

Five to fourteen members at random angles and distances from a centre, one template, sizes 0.5 to 1.2.

Count what happened. Each mushroom carries its template and its kind as metadata, the rejected positions are kept, and every ring and cluster records what it requested and what it placed, so the specimen table's plate can print candidates, accepted, rejected, rings, clusters and templates, and its highlight can ring every instance of one template or one kind.

Grow it again.

```gdscript
func regrow() -> void:
	for nm in ["MushroomField", "Ground", "Grass", "Rocks", "FallenLeaves"]:
		var n: Node = get_node_or_null(nm)
		if n != null:
			remove_child(n)
			n.queue_free()
	mushrooms.clear()
	_free_templates()
	_seed_generators()
	create_ground()
	create_mushroom_templates()
	generate_mushroom_field()
```

The same order as the first build, so under a seed every instance and the ground come back where they were. NEW SEED draws another five-digit seed first; SIZE sets `size_variation` and regrows under the seed you have.

Stage it in a map.

```
mushrooms:180#stand:specimen#size:6
```

`stand:specimen` raises the bed clear of the museum's floor, boards it, and stands the table with the six specimens, the plate and SHOW · KIND · SIZE / REGROW · NEW SEED at the bed's edge; `size` is the bed's side in metres; `seed` pins the population. Without the token's config the meadow builds exactly as it shipped: ten metres, the global stream, no table.
