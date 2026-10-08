extends "res://commons/artifacts/distribution_sampler/distribution_sampler.gd"
var injected: Array[float] = []
var input_index: int = 0
func _rand() -> float:
	var value: float = injected[input_index % injected.size()]
	input_index += 1
	return value
