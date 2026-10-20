extends Node
## A trial keeps score locally; it cannot change museum progress or saves.
var score := 0
func _ready() -> void:
	add_to_group("void_trial_score")
func add_points(amount: int, _where := Vector3.ZERO) -> void:
	score += amount
	var game := get_parent()
	game._notice("TRIAL / %d cubes collected\nR or B: reset the encounter" % score)
func reset() -> void:
	score = 0
