# Keep the run

**Optional sampling companion · Randomness_Examples_of_Randomness · 9 October 2026**

At the existing dartboard, press REPLAY, then FILL. Turn BUDGET from 500 to 2000 and fill again. The dial restarts the same seed: the first 500 samples recur before the new ones arrive. Now press NEXT SEED and FILL. The rule and budget stay fixed; the sampled positions change. Press 8 SEEDS to compare eight runs without disturbing yours.

**Learning elements:** local random stream; retained sample list; circle membership; count and ratio; replay; sample budget; variability across seeds.

This companion inspects the installed estimator. The museum board, markers, dial and buttons are supplied. The code below is its complete sampling core, with a small executable check. It creates data, not another board. The hall's [main tutorial](../../../../commons/maps/Randomness_Examples_of_Randomness/tutorial.md) separately reconstructs a small learner board with the carried PointBody. Its scene and interaction code are not prerequisites for running this core.

Two uniform draws place a sample inside the unit square. The circle has centre (0.5, 0.5) and radius 0.5. Squared distance at most 0.25 means inside, including the boundary. Its area is π/4 of the square, so `4.0 * inside / total` estimates π. Before any samples, there is no estimate; `NAN` records that absence. The display shows a dash.

The seed chooses a repeatable local stream in this engine build. Reset must rewind that stream as well as clear the points. `snapshot()` copies the list so replay cannot erase the saved record. Comparing seeds constructs separate samplers; it neither consumes nor reseeds the current run or the museum's global generator. Repeatability across future engine versions is not promised.

Save this first file as **sample_run.gd** in a small Godot project's root. It is the same core used by the installed artifact.

```gdscript
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
```

`next_sample()` adds one record. `estimate()` reads every retained record's classification. The 8000-sample cap bounds this study; callers must stop before the next sample would exceed it. `compare_seeds()` repeats the same operation under each seed and returns signed differences from Godot's `PI` constant. It supplies no confidence interval.

Save **sample_check.gd** beside it. Run with the Godot executable: `godot --headless --path <project-folder> --script res://sample_check.gd`. No `.tscn`, scene-path lookup, headset or add-on is required for this data check. Return to the existing museum for the spatial interaction.

```gdscript
extends SceneTree
const SampleRun = preload("res://sample_run.gd")

func _initialize() -> void:
	var run = SampleRun.new(1847)
	assert(is_nan(run.estimate()))
	assert(SampleRun.in_circle(Vector2(1, .5)))
	assert(not SampleRun.in_circle(Vector2.ONE))
	for i in 100:
		run.next_sample()
	var saved: Dictionary = run.snapshot()
	assert(saved.total == 100)
	assert(is_equal_approx(run.estimate(), 4.0 * run.inside / 100))
	run.reset(1847)
	for i in 100:
		run.next_sample()
	assert(run.points == saved.points)
	var state: int = run.rng.state
	var rows: Array = run.compare_seeds(1847, 500)
	assert(rows.size() == 8 and rows[7].seed == 1854)
	assert(run.rng.state == state and run.points == saved.points)
	print("SAMPLE COMPANION: 8 assertions passed")
	quit()
```

The check asks whether a known boundary is included, an empty run has no estimate, the ratio uses the count, replay recovers the same positions, and comparison preserves the active run. It does not assert that every new sample improves the estimate: that would be the wrong contract.

**Try independently:** use seed 1850, keep a snapshot at 200 samples, then continue to 500. Reset and draw 500 again. Check that the first 200 positions match the saved list. Compare the two estimates; either can be closer to π in an individual run. Explain why unchanged sample order and improved accuracy are different claims.

**Back at the board:** all samples contribute to the count, but only the newest 300 markers stay visible. The console states both quantities. A display budget is not a sample budget. What travels onward is a retained record and a declared interpretation of it.
