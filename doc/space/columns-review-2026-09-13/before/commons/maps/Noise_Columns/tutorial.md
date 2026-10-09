# Noise Columns

Two ways to make a shape move, and one function they both go through. Every line below is from `algorithms/proceduralgeneration/hybrid_complex/berninicolumns/MeltingBerniniColumns.gd`, the artifact the map places as `MeltingBerniniScene`.

Ask each driver for a phase.

```gdscript
func driver_phase(kind: String, t: float) -> float:
	match kind:
		"periodic":
			return sin(t * melt_speed) * 0.5 + 0.5          # the shipped driver
		"field":
			return clampf(_noise.get_noise_2d(t * 0.55, 0.0) * 0.5 + 0.5, 0.0, 1.0)
		_:
			return TRIO_BASE_PHASE
```

Three answers, one shape of answer: a number between zero and one. The sine is the melt this artifact shipped with. The field is `FastNoiseLite`, seeded by the room and sampled along time, added for this room and the first coherent field the file has ever contained.

Spend the phase in one place.

```gdscript
func mapped_drop(phase: float) -> float:
	return 2.0 * melt_strength * phase
```

The phase goes into the same mesh call for every column, and this is what it costs: the height the top loses. Because both drivers hand the same function the same kind of number, the displacement range is shared exactly, and the only difference left between two columns is what proposed the phase.

Deal the drivers from the seed.

```gdscript
	for i in range(_order.size() - 1, 0, -1):
		var j: int = deal.randi_range(0, i)
		var tmp = _order[i]; _order[i] = _order[j]; _order[j] = tmp
```

One number names the field and decides which column is which. The arrangement is reproducible and not learnable, and the plates read a question mark until somebody presses REVEAL.

Scale the amplitudes to the body.

```gdscript
	var k: float = TRIO_H / 10.0
	_amp_scale = k
	spiral_density = 1.0            # one turn over the height: a spiral column, not a corkscrew
	sine_amplitude = 0.30 * k
```

Every deformation amplitude in this file is in metres and they were tuned for a column four times this tall. Unscaled, a 2.55 m column photographs as flying shards. `_amp_scale` is 1.0 by default and reaches the three wobbles hardcoded inside the mesh generator, so the shipped mesh is unchanged to the vertex.

Bound the rebuild.

```gdscript
	if not _frozen and time >= _next_rebuild:
		_next_rebuild = time + 1.0 / TRIO_HZ
		for data in _trio:
			if str(data.get("driver")) == "baseline":
				continue
			_rebuild_column(data, driver_phase(str(data.get("driver")), time))
```

Twelve meshes a second for the two that move, none for the one that does not, and none at all while frozen. The shipped ring rebuilt nine full meshes every frame.

Time what it costs.

```gdscript
	var t0: int = Time.get_ticks_usec()
	shaft.mesh = generate_spiral_column_mesh(phase)
	var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0
```

About 3.5 ms a mesh at forty by sixteen segments, printed on the plate beside the drivers, because a room that rebuilds geometry should say what that costs.

Make the shape answerable.

```gdscript
func rebuild_at(slot: int, t: float) -> Dictionary:
	var phase: float = driver_phase(str(data.get("driver")), t)
	_rebuild_column(data, phase)
```

Rebuild one column at a named time and return a checksum over its vertices. The same time twice gives the same mesh; another time gives a different one; turning the column changes neither. That is how a probe, or a visitor with FREEZE and SPIN, establishes that the geometry is a function of the driver and the time and of nothing else.

Stage it in a map.

```
MeltingBerniniScene:180#stand:trio#speed:0.9
```

`stand:trio` builds the three columns, the plinths, the blank plates, the instrument and FREEZE, REVEAL, SPIN and MARBLE; `seed` names the field; `speed` sets the sine rate, and 0.9 puts a full period inside a look. The `180` turns the instrument toward the hall's north door. Without the token the artifact is what it always was: a ring of thirteen columns melting on a sine.
