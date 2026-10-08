extends "res://commons/artifacts/force_pad/force_pad.gd"
## Same pad; queue its launch in the court's velocity owner, so walking cannot erase it.
var court: Node3D

func _on_body_entered(body: Node3D) -> void:
	if _cooldown > 0.0 or not body is CharacterBody3D: return
	if court == null or not court._point_inside(body.global_position): return
	court.queue_launch(body, _launch_velocity())
	_cooldown = cooldown_time
	_flash()
