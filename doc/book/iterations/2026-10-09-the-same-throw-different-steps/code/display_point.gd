extends "res://doc/book/studies/forces-point-lineage/point_body.gd"
## The earlier sphere projects a calculated state, including while paused.
var apparatus: Node3D
var lane := 0
func _ready() -> void:
	super._ready(); process_physics_priority=101
func _physics_process(_delta: float) -> void:
	if apparatus==null: return
	var p: Vector3=apparatus.model.reference_at(apparatus.model.time()) if lane==0 else apparatus.model.position
	global_position=apparatus.to_global(apparatus.display(p,lane))
	# At the shared start, show one point rather than two coincident surfaces.
	visible=lane==1 or apparatus.model.tick>0
	linear_velocity=Vector3.ZERO; angular_velocity=Vector3.ZERO
