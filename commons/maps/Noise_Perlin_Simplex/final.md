# What counts as the same

A hollow on one side of the aisle faces a ridge on the other. It is easy to call that the difference between Perlin and simplex. Walk a little further before deciding.

Two changes of seed could have made two different pictures too. So could a different scale of sampling. We need a way to ask the fields a narrower question.

<!-- @simplex_noise -->

Start at the left panel. Press REPLAY and choose a feature to recognise. Move FREQ a little, watch that feature change, then replay. The field returns to the declared setting. Its variation has a way back, as the colour grids did in Randomness.

This time the values have neighbours. The cube display gives each sampled coordinate a height and a colour. Across a short distance, changes in the underlying field are related; the cubes still present them as separate steps. The grid we see is one way of reading that relation.

The left visualizer asks for a value like this:

```gdscript
func generate_noise_at(x: float, z: float) -> float:
	return noise_generator.get_noise_2d(x * frequency, z * frequency)
```

The slider changes the coordinate multiplier. The display can keep the same cube positions while asking the field about a different scale. A ridge can change across an unmoving display.

<!-- @perlin_noise -->

Cross to the right panel and compare the readouts. Both begin with the same seed, octave count, frequency and gain. Their displays share amplitude, sample spacing and finish. The values printed at the two named coordinates need not agree.

The right visualizer chooses its Perlin basis in this branch of `_noise_type_for`:

```gdscript
"perlin":
	return FastNoiseLite.TYPE_PERLIN
```

The left uses the generator's simplex setting. A label gives us a claim about that choice; the source and the generator readout give us ways to check it. No amount of staring at the sign would make it sufficient evidence by itself.

Between the two panels there is a plate with no argument on it, only the two generators' own answers:

    read off the two generators, not off the tokens that asked for them
                           simplex     perlin
    seed                   20260910    20260910
    generator frequency    0.0500      0.0500
    fractal octaves        4           4
    fractal gain           0.500       0.500
    fractal lacunarity     2.000       2.000
    fractal type           1           1
    sample x,z multiplied  10.000      10.000
    sample offset added    0.000       0.000

    noise_type             0           3          <- the one term that differs

Those numbers are not read from the placements that asked for them. They are read from the two FastNoiseLite objects that drew the fields, after every control in the room has been pressed. A comparison is a claim about what was held still, and a claim nobody can check is a label with more syllables.

Choose one comparison to keep in view: the turn of a ridge, the spacing of hollows, or how much the field changes between two nearby samples. Resist trying to settle all of them from the first pair. The shared seed makes each field repeatable; it does not make a ridge on one side the partner of a ridge on the other.

Now alter FREQ on just one side. For a moment you have introduced a difference the comparison had worked to hold still. Watch how much that one setting changes what you might have attributed to the basis. Return it with REPLAY before continuing.

Matching these conditions costs us possibilities. The same finish helps compare shape, while withholding what a different colour treatment might reveal. Half-metre samples give the field a body we can inspect; variation between those addresses has no cube of its own. The comparison makes some distinctions easier to see by agreeing to leave others out.

<!-- @ -->

Look again at the hollow that first caught your attention. If you were choosing a landscape in which to hide, it might matter for a different reason than if you were looking for a clear view. The displayed fields do not choose that purpose. A rule can become useful to different bodies through what we ask of its variation.

There need not be a winner standing on either side of the aisle. Keep the ability to repeat a field, change a condition and recognise what the comparison can support. That gives you more to work with than a ranking.

Behind the pair, a small terrain gives sampled values another form. Ahead, the cells in Cellular Automata will keep states and update them from neighbours. We have been asking what a field returns at a coordinate. We are about to ask what a cell becomes after another step.
