extends RefCounted
## One local uniform stream. Counts retain every sample; displays may retain fewer.
const LIMIT := 8000
var run_seed: int = 1847
var rng := RandomNumberGenerator.new()
var points: Array[Vector2] = []
var inside: int = 0

func _init(seed_value: int = 1847) -> void:
	reset(seed_value)

func reset(seed_value: int) -> void:
	run_seed = seed_value
	rng.seed = run_seed
	points.clear()
	inside = 0

static func in_circle(point: Vector2) -> bool:
	return point.distance_squared_to(Vector2(.5,.5)) <= .25

func next_sample() -> Vector2:
	assert(points.size() < LIMIT, "Sample budget exhausted")
	var point := Vector2(rng.randf(), rng.randf())
	points.append(point)
	if in_circle(point): inside += 1
	return point

func estimate() -> float:
	return 4.0 * inside / points.size() if not points.is_empty() else NAN

func snapshot() -> Dictionary:
	return {"seed": run_seed, "total": points.size(), "inside": inside,
		"estimate": estimate(), "points": points.duplicate()}

func compare_seeds(first_seed: int, budget: int, trials: int = 8) -> Array[Dictionary]:
	assert(budget > 0 and budget <= LIMIT and trials > 0 and trials <= 32)
	var rows: Array[Dictionary] = []
	for seed_value in range(first_seed, first_seed + trials):
		# Each comparison owns another stream. The visitor's run is untouched.
		var other = get_script().new(seed_value)
		for i in budget: other.next_sample()
		rows.append({"seed": seed_value, "total": budget, "inside": other.inside,
			"estimate": other.estimate(), "error": other.estimate() - PI})
	return rows
