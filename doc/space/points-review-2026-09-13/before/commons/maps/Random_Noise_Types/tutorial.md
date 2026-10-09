# Random Noise Types

Points proposed at random, and a rule that admits or refuses each one. Every line below is from `algorithms/randomness/randompoints/randompoints.gd`, the artifact the map places as `randompoints`.

Route every draw through one call.

```gdscript
func _rf(a: float, b: float) -> float:
	return _rng.randf_range(a, b) if _rng != null else randf_range(a, b)
```

With no seed `_rng` is null and the call falls through to the global stream — the same call in the same order as before, so an unseeded placement draws exactly what it always drew. Under a named seed every draw in the file comes from one generator, which is what makes a cloud repeatable.

Propose a point anywhere in the volume.

```gdscript
func _generate_uniform(count: int, extents: Vector3) -> Array:
	var pts = []
	for i in range(count):
		var pos = Vector3(
			_rf(-extents.x, extents.x),
			_rf(-extents.y, extents.y),
			_rf(-extents.z, extents.z)
		)
		pts.append(pos)
	return pts
```

Count in, count out. Nothing can refuse anything here, which is why the left-hand plate on the bench keeps every candidate it is offered.

Now ask one question before letting a candidate land.

```gdscript
			var min_dist = INF
			if pts.is_empty():
				min_dist = INF
			else:
				for existing in pts:
					var d = candidate.distance_to(existing)
					if d < min_dist:
						min_dist = d

			# Enforce minimum distance
			if min_dist >= blue_noise_min_dist:
				pts.append(candidate)
				placed = true
				break
```

Dart throwing: the candidate is compared with every point already admitted, and the nearest of those decides. This is the whole of the rule. Note what it is not — nothing is moved, nudged, relaxed or optimised, and no point already admitted is ever reconsidered.

Keep the refusals.

```gdscript
			if _rejected.size() < GHOST_CAP:
				_rejected.append(candidate)
```

A refusal is a candidate that fell inside somebody's excluded neighbourhood. The bench draws them where they fell, as grey specks, because a rule whose cost is invisible looks free.

And say what happens when the rule cannot be satisfied.

```gdscript
		if not placed:
			# Relax constraint slightly if we fail?
			# For now, just don't place the point (returns fewer points than requested)
			# This is characteristic of Blue Noise (packing limit)
			pass
```

That comment is the shipped code's own, and the answer it settled on is the honest one: the point is not placed, and the population comes back short. The readout says so in words when it happens. A system that had answered the question in the comment the other way — relaxing the distance to make the number — would report a full count and no longer be doing what it claims.

Set the rule's distance from the density, not by hand.

```gdscript
	if not _dist_asked:
		var mean_gap: float = pow(max(0.001, area_size.x * area_size.y * area_size.z) / float(max(1, num_points)), 1.0 / 3.0)
		blue_noise_min_dist = snappedf(0.8 * mean_gap, 0.005)
```

Eight tenths of the mean spacing the requested population implies in the volume given. Fixing it against the density rather than in metres keeps the packing limit in view at any count.

Draw the excluded neighbourhood.

```gdscript
	var s := SphereMesh.new()
	s.radius = blue_noise_min_dist * 0.5
```

Half the distance, and that is the exact geometry: if no two centres are closer than d, shells of radius d/2 can touch and never overlap. So the shells in the admitted plate kiss, and the ones in the proposed plate pass through each other.

Look, but do not enforce.

```gdscript
			if a.global_position.distance_to(b.global_position) < blue_noise_min_dist - 0.001:
				bad[i] = true
				bad[j] = true
```

Four times a second, over the admitted cloud only. It colours shells and counts pairs; it moves nothing. A point carried into a neighbour's shell stays there, because the distance was a condition of admission and never a force.

Put it back.

```gdscript
			if p is RigidBody3D:
				var rb: RigidBody3D = p
				rb.freeze = true
				rb.linear_velocity = Vector3.ZERO
				rb.angular_velocity = Vector3.ZERO
			(p as Node3D).position = (p as Node3D).get_meta("home")
```

Each point remembers the position it was generated at. A point that has been carried is a live body again, so it is frozen before it is placed, or physics puts it back where physics wants it.

Stage it in a map.

```
randompoints:180#stand:compare#count:24#size:0.9
```

`stand:compare` builds the bench: two matched volumes, the shells, the ghosts, the cased readout and REDRAW · NEW SEED · RULE · RESTORE. `count` is the requested population, `size` the square side of the sampled slab, `seed` pins the name, `radius` overrides the rule's distance, `mode` picks the shipped distribution. The `180` turns the bench's front toward the hall's north door, which is where the visitor arrives. Without the token the artifact is what it always was: one cloud of thirty points in a one-metre cube, on the global stream.
