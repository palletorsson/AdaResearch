extends Node3D

const ALPHABET := 10   # the symbols are the whole numbers 0 to 9

@export var seed_value := 40   # the row's name: the same number returns the same draws
@export var count := 200       # how many symbols are drawn

var values := PackedInt32Array()      # the symbols, in the order they were drawn

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in count:
		values.append(rng.randi_range(0, ALPHABET - 1))
	print(count, " symbols; the row begins ", values.slice(0, 12))
	print(tally(values))

## How many times each symbol occurs.
func tally(symbols: PackedInt32Array) -> Dictionary:
	var counts := {}
	for s in symbols:
		counts[s] = counts.get(s, 0) + 1
	return counts
