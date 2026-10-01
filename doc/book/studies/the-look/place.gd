extends Node3D
## Supplied with this kit: the place. It stands the_look.tscn, which your look.gd
## dresses, in one scene with the supplied walker and the supplied marble.
## One contract: the action `drop` (the key M) drops the marble one metre in
## front of the walker, from above its head. C changes between the walker's eyes
## and the scene's camera; W A S D walk; hold V or the right mouse button to look.
## It uses a condition, `if`, a word the course brings soon after this lesson.

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("drop"):
		$Marble.drop($Walker.global_position - $Walker.global_basis.z + Vector3(0.0, 2.2, 0.0))
