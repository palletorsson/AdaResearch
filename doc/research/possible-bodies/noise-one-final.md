# What does a value become?

<!-- @noisetorus -->

Two rings rest above a bench. One wears its variation as small folds. The other keeps a round outline while colour travels across it. The columns behind us asked where change enters a body. Here the question becomes more intimate: could these two surfaces be receiving the same thing?

Watch a bright patch arrive. Then press FREEZE. The rings hold that moment; the museum carries on. Two pale markers indicate matching coordinates. SAMPLE moves them together around the rings. Before reading the plate, look for a place where the folded ring turns inward and its coloured neighbour goes dark.

The plate gives a signed value. A negative number can become an inward movement. What would negative brightness look like?

At first this colour rule makes every negative sample black. Values that differ on the plate share the same darkness. Their differences have reached the display and been folded together there.

Press REMAP. Some of the dark surface returns. The number at the marker does not change. Neither does the relief. A different reading has made room for something that was already being computed.

```gdscript
func colour_of(value: float) -> float:
	return (value + 1.0) * 0.5 if _remap else maxf(value, 0.0)
```

Read the two invitations inside that line. `maxf(value, 0.0)` gives every negative value the same destination. `(value + 1.0) * 0.5` carries the interval from minus one to one into the interval from zero to one. Minus one becomes black, zero becomes halfway, and one becomes full brightness. The colour channel had room for the difference once we changed its address.

This is a small freedom with a specific mechanism. No hidden body has been rescued whole. We have changed what the display distinguishes. Lighting, the changing hue, screen precision and our eyes will still mediate what becomes visible. The plate reports the brightness factor before those further encounters.

Keep the clock held and try AMPLITUDE. The folds deepen or retreat. At zero they leave a plain ring. The coloured ring keeps its pattern, and the sampled value stays where it was.

```gdscript
func relief_of(value: float) -> float:
	return value * float(PAIR_AMPS[_amp_i])
```

A multiplication is enough to change the force of an appearance. It is not a force calculation. In the vertex shader, the result moves each vertex along its normal, the direction facing away from the surface at that vertex. The two rings have no collision shapes. The bench supports the instrument; its pictured folds will not catch a falling object.

Now change FREQUENCY. Keep watching the same marker. The value itself may change. We have moved the coordinate at which the field is consulted.

```gdscript
var scale: float = float(PAIR_FREQS[_freq_i])
var off: float = fmod(t, 3600.0) * noise_speed
return _noise2(Vector2(x * scale + off, z * scale + off))
```

The field is sampled through the ring's local `x` and `z`. Multiplying those coordinates makes more or less of the field pass across the same small body. Adding the time offset moves the sampling window diagonally. Release FREEZE and that addition resumes from the held moment. A wave of apparent change can come from travelling through values that are already determined by their coordinates.

There is a quiet omission in the expression: no `y`. Two places above and below one another, sharing the same local `x` and `z`, consult the same value. The ring is three-dimensional; this field is addressed in two dimensions. Its normals still point in different directions. One value can therefore move two parts of the body differently.

Look at the rings again. We began by treating their appearances as separate events. We can now follow a shared computation into different recipients. Yet the two views are not identical measurements: relief is evaluated at mesh vertices, while colour is evaluated across rendered fragments. The smooth skin and the bright skin spend different sampling budgets.

The marker is a coordinate probe just outside the surface. The plate rounds its field value to three decimals. Neither is a promise of infinite resolution. The little counters from our first drawn line have reached the ring with us.

<!-- @noiselayers -->

Walk around to the landscape basin. The room's opening now holds a small violet terrain within a pale coordinate frame. Come to its southern edge, where four buttons offer SUM, LOW, MIDDLE and HIGH.

Start with the whole. Choose a ridge to remember. Then press LOW. What survives? Try MIDDLE and HIGH before returning to SUM. One contribution may look modest beside another. Modest does not mean absent: addition has no obligation to give each ingredient an equally dramatic silhouette.

The earlier arrays have become a sheet of addresses. At each address, three existing noise resources supply three weighted numbers.

```gdscript
var low_freq_height = low_freq_noise.get_noise_2d(world_x, world_z) * low_freq_amplitude
var med_freq_height = med_freq_noise.get_noise_2d(world_x, world_z) * med_freq_amplitude
var high_freq_height = high_freq_noise.get_noise_2d(world_x, world_z) * high_freq_amplitude
```

```gdscript
var combined_height = low_freq_height + med_freq_height + high_freq_height
```

The weights are twelve, six and one-and-a-half. The names suggest a tidy progression, but the first two resources have almost equal base frequencies: 0.0056 and 0.0057. They also differ in algorithm, seed and octave count. These are three authored ingredients, not three pure frequency bands. A name can help us enter a construction while still needing inspection.

Each button isolates a contribution before the same further processing. The code calls that processing erosion. Look at what it actually does: in three passes, it lowers samples whose estimated slope exceeds a threshold. No water carries the removed amount elsewhere. The name lends the calculation a landscape story; the implementation gives us a more limited operation to examine.

Because the lowering happens after combination, the displayed SUM need not equal the displayed LOW, MIDDLE and HIGH added together. Combining, then modifying, can differ from modifying, then combining. Transformation taught us to ask about order. It matters here too.

The model keeps 101 by 101 sample points. Its original 200-unit width is shown at one-fiftieth scale, four metres across. The terrain has a collision mesh made from its visible triangles, unlike the shader folds on the rings. That makes a different kind of surface available to the simulation, without making this basin a full-size hiking course.

Keep the violet colour in mind. The geometry code also computes grass, rock and snow vertex colours, but the scene's material wears its own colour instead. A calculation can exist without being selected for display. A mountain can wear violet without its heights changing. The pleasure of dressing a body has arrived inside the terrain pipeline.

<!-- @dark_sphere -->

Near the exit, the dark orb continues its pulse. Leave the rings held and the terrain on HIGH. The orb still has somewhere else to be in time.

```gdscript
var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
_sphere_material.emission_energy_multiplier = lerpf(pulse_min * _emit_mul, pulse_max * _emit_mul, pulse_t)
```

Another scalar finds a surface through a brightness rule. This one comes from the familiar sine and the orb's own clock. It need not imitate the landscape to belong in the room. It lets us compare a periodic source with a sampled field, and makes the boundary of FREEZE visible again.

Three works remain three works. Across them, we can follow values into displaced vertices, colour, an added height, a collision surface and a pulse. The shared numerical form permits these crossings. It does not decide which crossings we build, or what each one can support.

Noise_Voxel waits beyond the door. There the field meets another demand: decide whether something occupies a cell. Take the dark patch with you. When a rule says that nothing is there, we now have a reason to ask how it read the value.
