extends Node
## Collectibles belong to this floor's encounter, not the museum save.
var score := 0

func add_points(amount: int, _where := Vector3.ZERO) -> void:
	score += amount
	var game := get_tree().get_first_node_in_group("void_game")
	if game != null:
		game._notice("%d cubes collected\nR or B: restart this floor" % score)
