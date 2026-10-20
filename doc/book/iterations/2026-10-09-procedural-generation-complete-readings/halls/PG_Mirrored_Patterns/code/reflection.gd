extends RefCounted
const INCLUDE_AXES := false
var held: Array = []
var result: Array = []

func hold(field: Array) -> void:
	assert(not field.is_empty())
	for row in field: assert(row.size() == field.size())
	held = field.duplicate(true)
	original()

func original() -> void:
	result = held.duplicate(true)

func reflect() -> void:
	original()
	var n := held.size()
	var limit := n / 2
	if INCLUDE_AXES: limit += n % 2
	for y in range(limit):
		for x in range(limit):
			var value: int = held[y][x]
			result[y][n - 1 - x] = value
			result[n - 1 - y][x] = value
			result[n - 1 - y][n - 1 - x] = value
