# The same everything else

What must stay the same before a difference can be attributed to a rule?

Two fields of small cubes stand on the floor, one to the left of the aisle and one to the right, each with a panel in front of it and a line of text floating above the panel. Walk between them and point at a difference. A ridge on one side with nothing facing it on the other; a hollow that the other field fills. Now ask what you have isolated. Two pictures made by two different rules would differ like this. So would two pictures made by the same rule from two different seeds, or sampled at two different scales, or coloured by two different ramps.

<!-- @simplex_noise -->

Read the text above the left panel. It names the basis the field is drawn from, the seed, the octave count, the frequency and the gain, and then it gives two numbers: the field's value at (-1, 0.5) and at (1, -1). These coordinates lie within the displayed patch. Press REGEN and look for changes in the field and the numbers. Press REPLAY to restore this room's starting seed, frequency and octave count. The field is repeatable: a named seed and a fixed procedure reconstruct it, which is what the previous sequence taught you to expect.

Move the FREQ slider a little. The features shrink or spread; the numbers move. Press REPLAY to return the dial and the field to their starting condition before comparing the two sides.

<!-- @perlin_noise -->

Read the text above the right panel and compare the settings with the left. The seed, octaves, frequency and gain match. Both fields also use the same amplitude, spacing, colour ramp and reflective finish. The two sample addresses match; their values need not. With those conditions held still, a difference can begin to tell us something about the basis.

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

The last branch is a quiet trap: the display can be named Perlin while its default still selects simplex. That was the mismatch in this room. The placement now supplies `generator:perlin`, and both readouts check their generators. A name can travel through a project longer than the condition that would make it true.

Both fields sample their generator the same way, at the same coordinates:

```gdscript
func generate_noise_at(x: float, z: float) -> float:
	return noise_generator.get_noise_2d(x * frequency, z * frequency)
```

Each cube is one sample, half a metre apart, lifted to its value and coloured by the one ramp both displays now share. Nothing about the sampling, the spacing, the height or the colour belongs to either basis.

<!-- @ -->

The same seed in two bases does not establish a correspondence between their ridges. What you can compare is the character of the variation: how a ridge turns, whether features lean along the room's axes, what happens when you change frequency on just one side. Each field has its own controls. Perlin uses a square lattice of gradients; Godot's simplex setting uses OpenSimplex2, with a different underlying lattice. Whether you can distinguish their signatures at this scale, with this many octaves, is a question to put to the fields rather than to their names.

Behind the fields a small terrain shows the same kind of sampling turned into ground, and the door in the corner marked optional leads to a side room; the main route continues ahead.

The next hall keeps a grid of cells too, but its values are not sampled from a field. Each one is updated from the values of its neighbours, step after step, and the picture that forms belongs to the stored states rather than to any function you could evaluate at a coordinate. Carry the distinction with you: a field you sample, and a neighbourhood you update.
