extends "res://commons/artifacts/spore_mushroom/spore_mushroom.gd"
## Same mushroom consumption interface, scoped to this station.
func _plant(at: Vector3) -> void:
	super._plant(at)
	remove_from_group(BAIT_GROUP)
