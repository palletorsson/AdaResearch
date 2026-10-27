extends "res://commons/artifacts/randomness_space/removal_arena.gd"
## The original museum arena recognises both native Void locomotion rigs.
func is_player(body: Node) -> bool:
	return body.is_in_group("player_body") or super.is_player(body)
