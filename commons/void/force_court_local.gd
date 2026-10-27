extends "res://commons/artifacts/force_capability_lab/force_capability_lab.gd"
## Keep the original court; resolve the visitor through the Void host.
func _ready() -> void:
	super._ready()
	add_to_group("void_controlled_carry")
	add_to_group("void_floor_extension")

func visitor() -> CharacterBody3D:
	var host = get_tree().get_first_node_in_group("void_game")
	return host.body if host != null else null

func contains_visitor(at: Vector3) -> bool:
	return can_process() and _point_inside(at)
