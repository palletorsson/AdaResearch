# Sine Space

A passage whose walls are a rule. Build one wall from a sum of sines, give the other wall the same rule shifted, and read the space between them. All code below is from `algorithms/wavefunctions/sine_wall/SineWallCorridor.gd`.

Add one sine.

```gdscript
offset += base_amplitude * amp_multiplier * amp_mul * sin((base_frequency * freq_multiplier * freq_mul) * z_norm * PI + phase_shift + phase_layer)
```

`z_norm` runs from -1 at one mouth to 1 at the other. `base_frequency` is therefore the number of crests along the length, 4.5 over seven metres here, not a rate in hertz. The caller passes the running phase as `phase_shift` for the left wall and phase plus offset for the right; `phase_layer` belongs to the layer. Each running phase enters the sum once.

Sum three of them.

```gdscript
	for layer in wave_layers:
		var freq_mul: float = float(layer.get("freq_mul", 1.0))
		var amp_mul: float = float(layer.get("amp_mul", 1.0))
		var phase_layer: float = float(layer.get("phase_shift", 0.0))
```

The second layer runs at 1.8 times the spatial frequency with 0.35 of the amplitude, the third at 2.6 times with 0.18. Together they put a finer ripple on the crests. The sum is still one number per column.

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

The right wall is the left wall's rule with `phase_offset_between_walls` added. At zero the walls agree and bulge in together. At half a turn every sine changes sign, so the right wall moves out by exactly what the left moves in, and the separation along local X is the width everywhere. Shortest or normal clearance around a bend is a different measurement.

Run the phase.

```gdscript
			phase += delta * animation_speed
```

0.35 radians per second in this placement. The whole sum repeats at a fixed position after about eighteen seconds. Each layer travels toward the -z mouth at its own speed because its spatial frequency differs. FREEZE stops this line from running and nothing else.

Read the gap.

```gdscript
	return corridor_width - float(d[0]) - float(d[1])
```

The width minus both inward displacements. The readout prints the narrowest and widest local-X separations along the length as x-gap.

Decide what the wall can do to a body.

```gdscript
	if not enable_collision:
		shape_node.shape = null
		return
```

This placement leaves wall collision off. The walls are drawn every frame and touch nothing; the passage floor is a 24 mm slab with a collider of its own, and that is what holds the body (and what tells the museum's walk map the passage is this body's ground, so nothing else is dealt into it). A wall that must stop a body needs a shape here, and a shape that is rebuilt as often as the mesh.

## The walk

Try the forecourt tray, then continue through the original antechamber. Turn west along its first row, and step into the corridor at its west mouth. Stand still and watch a crest come toward you. Press FREEZE and walk the same stretch. Slide PHASE to the top and read the gap; slide it to the bottom and read it again. Bring AMP up and walk into the pinch. Press RESET. Leave by the east mouth onto the bridge, and look down at the basin's floor of spheres on the way to the south door.

You have walked a rule laid along a passage. The next map, Effect Sound, puts one oscillation inside another and makes the offset audible.
<<</MAP>>>

Show the samples.

```gdscript
@export_enum("skin", "ribs", "strata", "lattice") var cut: String = "skin"
```

`ribs` keeps every sixteenth run of columns as a fin and lets you see the far wall through the near one; the relation between the walls becomes visible from outside the passage. Any placement can ask for it with `#cut:ribs`.


## The forecourt: give the sine a collision surface

Start with `sine_flow_tray` at (3,4). Predict what leaves, press RELEASE, then change only SIZE and repeat. RESET before changing RELIEF. RULE comes after the observation. This is a separate artifact from the recorded four-tray article apparatus; it has one stationary surface and a smaller control set.

```gdscript
samples.append(sin(TAU*0.9*x) * sin(TAU*0.9*z))
```

This expression fills a 21 by 33 vertex array across 2 by 3.2 metres. Min/max normalisation maps it into [0, relief]. Each of the 20 by 32 cells becomes two triangles. The collision shape is constructed from the resulting mesh:

```gdscript
collision.shape = mesh.create_trimesh_shape()
```

The surface is fixed at twenty degrees about local X. Every release creates 32 spheres in the same four-column, eight-row arrangement at local height 1.1 m. Radii are 0.045/0.075/0.105 m; mass remains 0.1 kg, so scaling does not preserve density. Explicit linear/angular damping is 0.05, sphere/terrain friction 0.45, bounce zero, gravity inherited from the project (9.8 m/s² in the checked run). Spheres collide with one another.

An outlet crossing occurs when a sphere centre passes local z=1.6 by more than its radius. Side, back and below-tray exits are classified separately before this test. Departed bodies freeze, stop colliding, and move to the collection display. At 12*physics_ticks_per_second the remaining bodies freeze too. The declared counter includes the activation tick; this is a finite observation window, not a settling detector. The full source is `commons/artifacts/sine_flow_tray/sine_flow_tray.gd`.

SIZE resets the batch without changing any height sample. RELIEF rebuilds the heightfield and resets the batch. RESET restores the declared middle radius/relief and hides RULE. RELEASE always replaces the previous batch, so at most 32 trial spheres are active. The side console sits at standing hand height; its tilted readout and transparent side guards keep the surface visible.
