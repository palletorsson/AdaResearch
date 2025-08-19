extends Node
class_name NoiseHelper

static func setup_noise(seed: int = 0, frequency: float = 0.05) -> FastNoiseLite:
	"""
	Creates and configures a FastNoiseLite instance.
	- `seed`: Random seed for noise generation.
	- `frequency`: Controls the scale of the noise.
	"""
	var noise = FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = frequency
	return noise
