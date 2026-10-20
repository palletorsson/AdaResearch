extends "res://doc/book/studies/randomness-shelf/direct_randomness.gd"
## Museum adapter: the four introductory assignments stay in the learner script.
const HallSeed = preload("res://commons/artifacts/randomness_space/hall_seed.gd")
var sample_seed := SEED

func _ready() -> void:
	set_meta("em_keep_scale", true)
	set_meta("em_visibility_bounds", AABB(Vector3(-1.8, 0, -0.4), Vector3(3.6, 2.35, 1.2)))
	super._ready()
	HallSeed.bind(self)

func apply_grid_config(config: Dictionary) -> void:
	if config.has("hall_seed"):
		set_meta("config_hall_seed", config.hall_seed)

func get_sample_seed() -> int:
	return sample_seed

func accepts_sample_seed(number: int) -> bool:
	return number >= 0 and number <= 999

## Loading a kept study restores its beginning to the hall, respecting held objects.
func restore_sample_seed(number: int) -> bool:
	if HallSeed.enabled(self):
		return HallSeed.choose(self, number, {"provider":"saved_record", "seed":number})
	_apply_hall_seed(number, {})
	return true

func _apply_hall_seed(number: int, _receipt: Dictionary) -> void:
	sample_seed = number
	var rng := RandomNumberGenerator.new()
	rng.seed = number
	values.clear()
	for i in COUNT:
		values.append(rng.randf())
	replay()

func show_sample() -> void:
	super.show_sample()
	$Readout.text = "%d / %d   u = %.6f   seed %d" % [cursor + 1, values.size(), values[cursor], sample_seed]

