extends "res://doc/book/studies/forces-point-lineage/point_body.gd"
## The existing point becomes a constrained release handle, not a thrown rigid body.
var apparatus: Node3D
var lane := 0

func _ready() -> void:
	super._ready()
	process_physics_priority = 100 # Project after XR Tools has moved the held point.

func _physics_process(_delta: float) -> void:
	if apparatus == null: return
	if is_picked_up(): apparatus.set_release_from_hand(lane, global_position)
	global_position = apparatus.bob_world(lane)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
