extends "res://algorithms/wavefunctions/oscillation_driver/PendulumWave.gd"
## A strip needs two samples; a single sample remains a visible measurement mark.
func _draw_trail() -> void:
	if trail_points.size()!=1:
		super._draw_trail();return
	trail_mesh.clear_surfaces()
	if is_instance_valid(_floor_projection):_floor_projection.draw_record()
	_marks.multimesh.visible_instance_count=1
	var p:Vector3=trail_points[0]
	_marks.multimesh.set_instance_transform(0,Transform3D(Basis.IDENTITY,Vector3(p.x,p.y,-(time-p.z)*time_speed)))
