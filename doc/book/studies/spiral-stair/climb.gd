extends Node3D

func _ready() -> void:
	$Walker.walk_ended.connect(_on_walk_ended)
	$Walker.walk_to($Stair.route())

func _on_walk_ended(how: String) -> void:
	print("the walker ", how, " with its feet at ", snappedf($Walker.global_position.y, 0.01), " m; the top is at ", $Stair.top(), " m")
