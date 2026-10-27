extends "res://commons/scenes/mapobjects/mario_cube_time_trace.gd"
## Record the existing animated visual in its own editable coordinate frame.
func _ready() -> void:
	target_path = NodePath("PickUpCube/CubeBaseMesh")
	trail_max_points = 200
	super._ready()
	_trail_instance.set_as_top_level(false)
	_trail_instance.transform = Transform3D.IDENTITY
	_origin_z = to_local(_target.global_position).z

func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		_target = null
		set_process(false)
		return
	_time_elapsed += delta
	for i in _trail_points.size(): _trail_points[i].z += time_axis_speed * delta
	_sample_timer += delta
	if _sample_timer >= sample_interval:
		_sample_timer = 0.0
		var local := to_local(_target.global_position)
		_trail_points.append(Vector3(local.x, local.y, _origin_z))
		if _trail_points.size() > trail_max_points: _trail_points.pop_front()
	_rebuild_trail()
