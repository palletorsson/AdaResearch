# What counts as the same

A hollow on one side of the aisle faces a ridge on the other. It is easy to call that the difference between Perlin and simplex. Walk a little further before deciding.

Two changes of seed could have made two different pictures too. So could a different scale of sampling. We need a way to ask the fields a narrower question.

<!-- @simplex_noise -->

Start at the Simplex panel. Press REPLAY and choose a feature to recognise. Move FREQ a little, watch that feature change, then replay. The field returns to the declared setting. Its variation has a way back, as the colour grids did in Randomness.

In the previous room a height change caught the walking body. Here the small cubes leave space for us to walk around their arrangement. Each sampled coordinate receives a height and a colour. The underlying field relates neighbouring values; the cubes present selected values as separate steps. The grid we see is one way of reading that relation.

The Simplex visualizer asks for a value like this:

```gdscript
func generate_noise_at(x: float, z: float) -> float:
	return noise_generator.get_noise_2d(x * frequency, z * frequency)
```

The slider changes the coordinate multiplier. The display can keep the same cube positions while asking the field about a different scale. A ridge can change across an unmoving grid.

Find the pink marker. Press SAMPLE on the shared instrument and watch it move to another cube. Across the aisle, another marker takes the same address. Their heights need not agree. The readout now gives the coordinate, each field's answer and their signed difference.

```gdscript
func sample_pair(p: Vector2) -> Vector2:
	return Vector2(pair[0].sample_at(p.x,p.y), pair[1].sample_at(p.x,p.y))
```

One question goes to two functions. The coordinate is shared. The answer belongs to the function that returns it. A positive difference on the display means the Perlin value exceeds the simplex value at this address; it does not award a point to either landscape.

<!-- @perlin_noise -->

Cross to the Perlin panel and compare the readouts. Both begin with the same seed, octave count, frequency and gain. Their displays share amplitude, sample spacing and finish. The Perlin visualizer chooses its basis in this branch of `_noise_type_for`:

```gdscript
"perlin":
	return FastNoiseLite.TYPE_PERLIN
```

The Simplex visualizer chooses `TYPE_SIMPLEX`, which this engine implements as OpenSimplex2. The plate reads the choices back from the instantiated generators. Names can help us find a work; here we also have a way to check what they claim.

Both belong to gradient noise: a local direction contributes through its relation to a displacement, and contributions are combined into the value at an address. Perlin's lattice and OpenSimplex2's construction organise those contributions differently. The dot product from Vectors is still in the toolbox. The library has folded a longer calculation into the small call above; the call has not made that calculation disappear. [The engine's noise definitions](https://docs.godotengine.org/en/4.6/classes/class_fastnoiselite.html#enumerations).

Choose one comparison to keep in view: the turn of a ridge, the spacing of hollows, or the difference between answers at one coordinate. The shared seed makes each field repeatable. It does not make a ridge on one side the partner of a ridge on the other.

Now alter FREQ on just one side. Look back at the central plate. Alongside the different bases, it reports another difference: the scale at which the field is sampled. That one adjustment changes what you might have attributed to the basis. MATCH returns both generators to the declared settings. REPLAY on either side returns that side alone.

Press VIEW. Keep following the pink markers as the relief is levelled at once into two flat arrangements. The colour retains the sampled values, unless REGEN has left the Simplex side on a new seed: VIEW also returns that field to its declared seed. Nothing has been flattened inside the noise function; the display has stopped spending its answer on height.

The cubes remain at half-metre intervals. Their square arrangement is still present whichever basis produced the values. It would be easy to mistake the grid of the display for the lattice inside the calculation. VIEW gives us another way to notice that two decisions have been folded together.

Return to relief. The same answers regain height. In Noise Space 10 we joined height to collision so a change could stop a foot. These cubes are a visual comparison with a walking aisle between them. A visible surface and a surface that carries us ask for different work from the implementation.

Matching conditions costs us possibilities. One shared finish helps compare shape while withholding what another colour treatment might reveal. Half-metre samples give the field a body we can inspect; variation between those addresses has no cube of its own. The comparison makes some distinctions easier to see by agreeing to leave others out.

<!-- @perlin_noise_terrain -->

Behind the pair, a small pink sheet stands above a low plinth. Stay with it for a moment. Its surface changes in steps even while the two larger fields wait for another action.

Its timer advances a third sampling coordinate:

```gdscript
func _on_timer_timeout() -> void:
	if not _is_truthy(animate):
		return
	time_offset += 0.5
	generate_terrain()
```

The mesh helper samples a three-dimensional field. The timer visits another slice every half-second. We have met a coordinate changing before; here the change keeps arriving without another gesture. It is neither an erosion calculation nor a memory of the sheet's previous shape.

The artifact is called `perlin_noise_terrain`, but its helper leaves the generator's basis at the engine default, OpenSimplex2S. This retained work makes the room's question recur inside its own collection. Its one-metre sheet samples in index coordinates, uses seed one and has its own clock. It cannot serve as a third matched surface simply because it stands near the pair.

<!-- @dark_sphere -->

The dark orb changes too. Its pulse gives the eye another rhythm to follow, independent of the small sheet's half-second steps. MATCH does not restart either work.

A return always has a scope. We recovered the two fields' parameters, while the other bodies continued. Even a careful comparison takes place in a world that has more going on than the question currently admits.

<!-- @ -->

Look again at the hollow that first caught your attention. If you were choosing a landscape in which to hide, it might matter for a different reason than if you wanted a clear view. There need not be a winner on either side of the aisle. Keep the ability to repeat a field, change a condition and recognise what the comparison supports.

The small sheet keeps changing. A little noise, and something begins to feel organic. Perhaps that is the body we wanted. Its swelling can carry pleasure, uncertainty or a queer promise of becoming. The ease of the operation is useful: we can put a similar gesture on many different objects.

After several rooms, that usefulness can become a mental algorithmic wall. The familiar answer arrives before we have worked out the next question. Different bodies acquire a family resemblance. We can call this tendency blob culture and begin investigating it here, among our own objects. Its cheapness is the ease with which we can add the filter; what someone makes of that gesture can still matter deeply.

Stay with the sheet and ask what else this body could do. Its changing slice has no record of what happened to the preceding surface. We could give it stored states, neighbours that affect its next move, something to exchange with another body. Each would require another decision and something further to learn. Noise can remain part of those constructions.

In the next chapter, Cellular Automata, a row waits for its first update. We will let a cell's next state depend on the states beside it. Bring the pleasure of the moving surface, and leave room for another form.
