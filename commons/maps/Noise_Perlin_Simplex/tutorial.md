# Noise Perlin / Simplex

Two fields, one aisle, and four things held still. The order below is the order of the encounter.

Walk between the fields and point at a difference. Then read the text above the left panel, and the text above the right one, line by line.

One format string prints both readouts, so the two are the same shape. The first line differs in exactly one word, its basis; the second line differs in every number it prints. That is the whole demonstration: the seed, the octaves, the frequency, the gain and the two coordinates are identical, so the numbers can only have moved because the word did.

Press REGEN on the left. The seed changes and the field is redrawn:

```gdscript
func regenerate_noise() -> void:
	current_seed = randi()
	noise_generator.seed = current_seed
	update_noise_field()
```

Press REPLAY. The declared seed is restored and the field, and its two values, come back:

```gdscript
func reseed(s: int) -> void:
	current_seed = s
	noise_generator.seed = s
	update_noise_field()
```

Move the FREQ slider on one side. The features change scale; the two values move. Move it back until the readouts match again.

Read where the basis is chosen. It is one match statement in the visualizer:

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

The default is simplex. The display named Perlin never received the word until it was placed with `generator:perlin`.

Read how both fields sample. The same line, at the same coordinates, half a metre apart:

```gdscript
func generate_noise_at(x: float, z: float) -> float:
	return noise_generator.get_noise_2d(x * frequency, z * frequency)
```

Set both OCTAVES sliders to one. With a single octave the basis is easiest to see; with six the detail buries it. Compare the character of the variation rather than any particular ridge: the same integer in two bases gives two unrelated fields.

Behind the pair, the small terrain turns the same sampling into ground. The corner door is labelled Lab Path and does nothing: its code looks for two ways to load a map and finds neither, so it is a door in the sense a painted door is. The hall after this one on the spine is CA_Introduction, which keeps a grid of cells whose values come from their neighbours, not from a function.
