extends "res://commons/primitives/point/draw_dot.gd"
## Keep the production sampler/line renderer, but keep this experiment out of TraceData.
signal record_kept(points: Array[Vector3])

func _on_grab_point_dropped(_pickable) -> void:
	if _trail_points.size() >= 2:
		record_kept.emit(_trail_points.duplicate())

func _check_unlock_progress() -> void:
	pass # No TagSystem unlocks, XP or progression changes in the test map.
