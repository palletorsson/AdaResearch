# The same everything else

What must stay the same before a difference can be attributed to a rule?

Two fields of small cubes stand on the floor, one to the left of the aisle and one to the right, each with a panel in front of it and a line of text floating above the panel. Walk between them and point at a difference. A ridge on one side with nothing facing it on the other; a hollow that the other field fills. Now ask what you have isolated. Two pictures made by two different rules would differ like this. So would two pictures made by the same rule from two different seeds, or sampled at two different scales, or coloured by two different ramps.

<!-- @simplex_noise -->

Read the text above the left panel. It names the basis the field is drawn from, the seed, the octave count, the frequency and the gain, and then it gives two numbers: the field's value at (0, 0) and at (2.5, 2.5). Press REGEN and the seed changes, the field changes, and the two numbers change. Press REPLAY and all three come back. The field is repeatable: a named seed and a fixed procedure reconstruct it exactly, which is what the previous sequence taught you to expect.

Move the FREQ slider a little. The features shrink or spread; the numbers move. Move it back.

<!-- @perlin_noise -->

Read the text above the right panel and compare it line by line with the left. Every word is the same except the first: the seed is the same integer, the octaves, the frequency and the gain are the same, the two coordinates are the same. Only the basis differs, and so do the two values. That is the whole comparison, and it took four things held still to make it one.

The basis is chosen in one place:

```gdscript
func _noise_type_for(name_in: String) -> int:
	match name_in:
		"perlin":
			return FastNoiseLite.TYPE_PERLIN
		"value":
			return FastNoiseLite.TYPE_VALUE
		"cellular":
			return FastNoiseLite.TYPE_CELLULAR
		_:
			return FastNoiseLite.TYPE_SIMPLEX
```

Until today the display named Perlin was never given the word, and the default at the bottom of that match is simplex. It drew simplex noise for a year under the other name, and nothing on it could tell you so. Now it is placed with `generator:perlin`, and the readout reports the basis from the generator itself rather than from the label.

Both fields sample their generator the same way, at the same coordinates:

```gdscript
func generate_noise_at(x: float, z: float) -> float:
	return noise_generator.get_noise_2d(x * frequency, z * frequency)
```

Each cube is one sample, half a metre apart, lifted to its value and coloured by the one ramp both displays now share. Nothing about the sampling, the spacing, the height or the colour belongs to either basis.

<!-- @ -->

The same seed in two bases is not the same field twice. The integer puts each generator into a repeatable state, but the states are not related, and no feature on the left corresponds to a feature on the right. What you can compare is the character of the variation: how a ridge turns, whether the features lean along the room's axes, how quickly the two values at the same coordinate drift apart when you turn one shared dial. Perlin's gradients hang on a square lattice and simplex's on a triangular one, and the lattice signs the result. Whether you can see the signature at this scale, with this many octaves, is a question the two dials let you put to the fields rather than to their names.

Behind the fields a small terrain shows the same kind of sampling turned into ground, and the door in the corner marked optional leads to a side room; the main route continues ahead.

The next hall keeps a grid of cells too, but its values are not sampled from a field. Each one is updated from the values of its neighbours, step after step, and the picture that forms belongs to the stored states rather than to any function you could evaluate at a coordinate. Carry the distinction with you: a field you sample, and a neighbourhood you update.
