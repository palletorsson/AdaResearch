# Read a population by changing one rule

Build on Random_Gaussian's distinction between a value and the account made from it. Here draws are assigned to construction tasks. Use the six-metre specimen bed and its five buttons; there is no mean/variance slider or live shape morphing control.

1. Choose two apparently related mushrooms. SHOW cycles template 0–5, marks that disc and its field copies. Zero copies is a possible observation. SHOW returns KIND to template selection.
2. Press SIZE. Follow the same instances. Their positions, templates, groups, yaw and ground should remain; their transform scales become 1. Distinct templates retain distinct dimensions. Press again to restore the sampled scales.
3. Press REGROW under the displayed seed. Compare specific instances, not only total count. NEW SEED changes the current seed; earlier numbers may recur.
4. KIND cycles scattered → rings → clusters → rejected → template. Read the current label rather than assuming a fixed number of presses. Accepted plus rejected counts only the eighty scattered candidates. Ring and cluster members are added separately.
5. Inspect the edible mushrooms from the west and south margins. Their pickable/eating behaviour belongs to a separate scene. Headset eating depends on holding one within 0.25 m of the active camera. Desktop carrying does not reach that distance by itself.

## The scale comparison

The scattered-body code evaluates the draw before calling `_size`:

```gdscript
		var scale_factor = _size(0.7 + _rf() * 0.6)  # 0.7 to 1.3
		mushroom.scale = Vector3(scale_factor, scale_factor, scale_factor)
```

```gdscript
func _size(v: float) -> float:
	return v if size_variation else 1.0
```

Taking the draw out would change subsequent generator state. Keeping it and replacing its use preserves the comparison. The ranges differ by construction routine: scattered 0.7–1.3, rings 0.8–1.2, clusters 0.5–1.2. These scale draws are uniform within their respective ranges; the room does not use Gaussian sizing.

## More than one source of draws

```gdscript
func _rf() -> float:
	return _pop_rng.randf() if _pop_rng != null else randf()

func _ri() -> int:
	return _pop_rng.randi() if _pop_rng != null else randi()
```

These helpers serve the templates, placement routines and ground cover. A separate `ground_rng` produces vertex heights, seeded by population seed + 1 unless an explicit ground seed overrides it. NEW SEED uses another temporary generator to choose a seed. `_rf` is not the file's only random call.

## Candidate selection and explicit arrangement

```gdscript
		var pos_x = _rf() * meadow_size - meadow_size / 2
		var pos_z = _rf() * meadow_size - meadow_size / 2
```

These draw candidates in a square. A fixed-count sample filtered by a noise threshold is not a spatial Poisson point process. The `density` parameter multiplies the requested count; the computed `area` variable is unused, so it does not maintain a number per square metre as bed size changes.

```gdscript
	var ring_count = int(meadow_size / 5)
```

```gdscript
	var cluster_count = int(meadow_size / 3)
```

Six metres gives one ring and two clusters. Their members are generated separately, rejected outside the square, and permitted to overlap existing bodies. The plate reports placed membership; requested ring/cluster counts are available in source inspection and the review data.

```gdscript
		var angle = _rf() * PI * 2
		var distance = _rf() * cluster_size
```

Uniform radius is not uniform area: equal-width radial bands receive equal probability while outer bands contain more area. That choice can thicken a cluster near its centre without any attraction between mushrooms.

## Carry the question forward

Template selection is discrete, while scale and yaw vary numerically. SIZE does not interpolate between templates. A proposed future experiment could replace one discrete choice with a shape parameter, but it would need its own implementation and comparison. Random_Game takes the next step in the active route: sampled choices with consequences for an encounter.


## Spatial staging — 16 September 2026

The map keeps a reachable instrument alongside its spatial applications. `map_data.json` is authoritative for placements. `#controls:compact` gathers the existing Rack panels, preserving their callbacks, into an 80 cm console. `#glass_width` opts into an enclosure with open entrances; its grid marks are not floor colliders.

### Arrival stage

`silhouette_arrivals` samples six distinct places without replacement. AUTO waits a seeded 1.5–3.5 seconds between arrivals; ARRIVE advances manually. REPLAY clears the population and restores the placement/timing stream. DRESS changes a separate wardrobe seed, retaining occupied places. The figures use the existing silhouette generator plus sampled collars, hems and pleats. They are non-colliding billboard visitors, not autonomous walking agents. Appearance does not determine hostility. The compact console retains all five touch callbacks.

FORMS toggles `repertoire` between 0 (tailored) and 1 (tailored plus branches). It retains both seeds, arrival RNG state and occupied slots. Branches are drawn after the original garment parameters are sampled, so adding that rule preserves the earlier choices. Switching back recovers the earlier texture. REPLAY retains dress and repertoire while restarting arrivals.

### DNA comparison

Three dream_couture_beast instances use seeds 41,42,43 and head=hare. GARMENT cycles sheath, crinoline, quilted, bloom and fringe with seeds retained. NEXT SEED advances all by three. RESET restores the starting trio. Controls share the compact console.
