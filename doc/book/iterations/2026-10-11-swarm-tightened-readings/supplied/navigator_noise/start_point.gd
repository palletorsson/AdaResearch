extends "res://doc/book/studies/forces-point-lineage/point_body.gd"
## Reuse the earlier point as a constrained starting-position handle.
var apparatus: Node3D
var lane := 0
func _ready() -> void:
	super._ready(); process_physics_priority=100
func _physics_process(_delta: float) -> void:
	if apparatus==null: return
	if lane==0 and is_picked_up(): apparatus.start_from_hand(global_position)
	global_position=apparatus.agent_world(lane)
	linear_velocity=Vector3.ZERO; angular_velocity=Vector3.ZERO
