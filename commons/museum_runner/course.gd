extends RefCounted
## A reproducible lane grammar. One clear route is retained in every row.
const LENGTH := 36.0
const LANE_WIDTH := 2.1
const TITLES := ["POINT / LINE", "FACE / BODY", "TRANSFORMATION", "ARRAY / COLOUR"]

static func chapter(index: int) -> int:
	return posmod(index / 3, TITLES.size())

static func rows(seed_value: int, index: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + index * 104729
	var result: Array[Dictionary] = []
	var clear_lane := rng.randi_range(-1, 1)
	for row in range(3):
		clear_lane = clampi(clear_lane + rng.randi_range(-1, 1), -1, 1)
		var blocked: Array[Dictionary] = []
		for lane in [-1, 0, 1]:
			if lane == clear_lane: continue
			# The first section offers single obstacles before paired decisions.
			if index == 0 and blocked.size() == 1: continue
			blocked.append({"lane":lane, "kind":"beam" if rng.randf() < 0.4 else "cube"})
		result.append({"z":-12.0-row*9.0, "clear":clear_lane, "hazards":blocked})
	return result
