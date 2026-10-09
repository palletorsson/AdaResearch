extends RefCounted
## Learner's score: addresses stay; the same values change neighbours.
const COLUMNS := 16
const ROWS := 256
const COUNT := COLUMNS * ROWS
const NAMES := ["Repeat", "Shuffle rows", "Shuffle cells"]

static func make_values(mode: int, seed_value: int) -> PackedByteArray:
	var ordered := PackedByteArray()
	ordered.resize(COUNT)
	for row in ROWS:
		for column in COLUMNS:
			ordered[row * COLUMNS + column] = (int(row / 2) + int(column / 8)) % 2
	if mode == 0:
		return ordered
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var order: Array[int] = []
	var count := ROWS if mode == 1 else COUNT
	for index in count:
		order.append(index)
	# Fisher-Yates: each swap is drawn from the portion not yet placed.
	for index in range(count - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var held := order[index]
		order[index] = order[other]
		order[other] = held
	var result := ordered.duplicate()
	for index in COUNT:
		var source := order[index] if mode == 2 else order[int(index / COLUMNS)] * COLUMNS + index % COLUMNS
		result[index] = ordered[source]
	return result

static func neighbour_changes(values: PackedByteArray) -> int:
	var changes := 0
	for row in ROWS:
		for column in COLUMNS:
			var index := row * COLUMNS + column
			if column + 1 < COLUMNS and values[index] != values[index + 1]:
				changes += 1
			if row + 1 < ROWS and values[index] != values[index + COLUMNS]:
				changes += 1
	return changes
