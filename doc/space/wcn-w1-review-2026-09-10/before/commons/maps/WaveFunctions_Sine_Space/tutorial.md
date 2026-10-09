# Sine Space

A passage whose walls are a rule. Build one wall from a sum of sines, give the other wall the same rule shifted, and read the space between them. All code below is from `algorithms/wavefunctions/sine_wall/SineWallCorridor.gd`.

Add one sine.

```gdscript
offset += base_amplitude * amp_multiplier * amp_mul * sin((base_frequency * freq_multiplier * freq_mul) * z_norm * PI + phase + phase_shift + phase_layer)
```

`z_norm` runs from -1 at one mouth to 1 at the other. `base_frequency` is therefore the number of crests along the length, 5.2 over eight metres here, not a rate in hertz. `phase` is in radians; `phase_shift` is the wall's own offset; `phase_layer` belongs to the layer.

Sum three of them.

```gdscript
	for layer in wave_layers:
		var freq_mul: float = float(layer.get("freq_mul", 1.0))
		var amp_mul: float = float(layer.get("amp_mul", 1.0))
		var phase_layer: float = float(layer.get("phase_shift", 0.0))
```

The second layer runs at 1.8 times the spacing with 0.35 of the amplitude, the third at 2.6 times with 0.18. Together they put a finer ripple on the crests. The sum is still one number per column.

Place the wall.

```gdscript
			var base_x: float = side * half_width
			var x_pos: float = base_x - side * displacement
```

`side` is -1 for the left wall and 1 for the right, so a positive displacement moves either wall toward the middle. The displacement does not depend on height; every row of a column stands at the same x.

Give the right wall the offset.

```gdscript
	_right_wall.mesh = _create_wall_mesh(1, half_length, half_width, half_height, phase + phase_offset_between_walls, 1.0, 1.0)
```

The right wall is the left wall's rule with `phase_offset_between_walls` added. At zero the walls agree and bulge in together. At half a turn every sine changes sign, so the right wall moves out by exactly what the left moves in, and the gap is the width everywhere.

Run the phase.

```gdscript
			phase += delta * animation_speed
```

0.35 radians per second in this placement. The crests travel toward the -z mouth, the entrance, one crest every eighteen seconds or so. FREEZE stops this line from running and nothing else.

Read the gap.

```gdscript
	return corridor_width - float(d[0]) - float(d[1])
```

The width minus both inward displacements. The readout prints the narrowest and widest values along the length.

Decide what the wall can do to a body.

```gdscript
	if not enable_collision:
		shape_node.shape = null
		return
```

This placement leaves collision off. The walls are drawn every frame and touch nothing; the deck holds the body. A wall that must stop a body needs a shape here, and a shape that is rebuilt as often as the mesh.

## The walk

Enter from the north, turn west along the first row, and step into the corridor at its west mouth. Stand still and watch a crest come toward you. Press FREEZE and walk the same stretch. Slide PHASE to the top and read the gap; slide it to the bottom and read it again. Bring AMP up and walk into the pinch. Press RESET. Leave by the east mouth onto the bridge, and look down at the basin's floor of spheres on the way to the south door.

You have walked a rule laid along a passage. The next map, Effect Sound, puts one oscillation inside another and makes the offset audible.
<<</MAP>>>

Show the samples.

```gdscript
@export_enum("skin", "ribs", "strata", "lattice") var cut: String = "skin"
```

`ribs` keeps every sixteenth run of columns as a fin and lets you see the far wall through the near one; the relation between the walls becomes visible from outside the passage. Any placement can ask for it with `#cut:ribs`.
