# Noise Voxel

A value, a line, and a decision with two states. Every line below is from `commons/artifacts/perlin_terrain_sculptor/perlin_terrain_sculptor.gd` and `algorithms/randomness/voxelnoise/voxelnoise.gd`, the two artifacts this hall places.

Write the sampler down once.

```gdscript
static func contract_noise(seed_value: int, scale: float, octaves: int) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_PERLIN
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.frequency = scale * 0.1
	n.fractal_octaves = octaves
	n.seed = seed_value
	return n
```

One basis, made one way, from a named number. Before this pass the bench and the terrain each made their own, and the link between them passed settings rather than samples.

Ask at a normalised place.

```gdscript
static func contract_value(n: FastNoiseLite, u: float, v: float, w: float) -> float:
	return n.get_noise_3d(u * CONTRACT_SPAN, v * CONTRACT_SPAN, w * CONTRACT_SPAN)
```

`u`, `v` and `w` are where you are INSIDE the display, from 0 to 1. That is the whole of the scale relationship: a 24-cell model and a 32-cell terrain hand the same numbers to the same field, so one is a magnified reading of the other rather than a lookalike.

Keep the bias, and name it.

```gdscript
static func contract_bias(v: float) -> float:
	return (v - 0.5) * CONTRACT_BIAS_SCALE
```

Higher cells are hindered and lower ones helped. This is what makes a terrain rather than a cloud, and it is part of the predicate, so it belongs on the plate beside the value.

Then the line.

```gdscript
static func contract_occupied(value: float, v: float, threshold: float) -> bool:
	return value - contract_bias(v) > threshold
```

Greater-than, and nothing else. Two consequences follow from that one symbol: the answer has exactly two states however finely the value varies, and raising the threshold can only ever take cells away.

Let the receiver use the same four.

```gdscript
				if _contract:
					var u := float(x) / float(maxi(1, chunk_size - 1))
					var v := float(y - 1) / float(maxi(1, world_height - 1))
					var w := float(z) / float(maxi(1, chunk_size - 1))
					val = PerlinTerrainSculptor.contract_value(noise, u, v, w)
					occupied = PerlinTerrainSculptor.contract_occupied(val, v, iso)
				else:
					val = noise.get_noise_3d(p.x, p.y, p.z)
					occupied = val > iso
```

The `else` is the shipped path, kept: without a staged bench handing over the contract, the terrain samples its own coordinates exactly as before.

Count the pieces, and say what that is worth.

```gdscript
				var queue: Array = [k]
				seen[k] = true
				while not queue.is_empty():
					var cur: Vector3i = queue.pop_back()
					size += 1
```

A flood fill over faces gives the number of separate pieces of the occupied set and the size of the largest. It is a fact about cells touching, and the plate follows it with the sentence that matters: connected is not walkable.

Speak only to your own hall.

```gdscript
	var hall: Node = _hall_ancestor()
	for r in get_tree().get_nodes_in_group("voxelnoise_receivers"):
		if hall != null and not hall.is_ancestor_of(r):
			continue
```

`call_group` reaches every receiver in the tree. In a museum that streams several halls at once, that meant a visitor turning this threshold retuned a terrain in a room nobody was standing in.

Stage it in a map.

```
perlin_terrain_sculptor:180:0.5:1#mount:shelf#stand:lattice
```

`stand:lattice` names a five-digit seed, takes the contract, and stands the cage, the plate and THRESHOLD, CELL, SEED and CUT. Without the token the bench is what it always was: its own noise at its own coordinates, seeded by `randi()`, with the sliders it shipped with.
