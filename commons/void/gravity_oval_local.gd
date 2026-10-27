extends "res://commons/artifacts/gravity_oval/gravity_oval.gd"
## The original circulating field owns its visitor while outside the tower.
func _ready() -> void:
	super._ready()
	add_to_group("void_exterior_walk")
	add_to_group("void_floor_extension")
	add_to_group("void_controlled_carry")

func contains_visitor(world_position: Vector3) -> bool:
	return AABB(Vector3(-7,-0.3,-8),Vector3(14,12.8,16)).has_point(to_local(world_position))
