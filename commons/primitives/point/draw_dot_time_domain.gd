extends "res://commons/primitives/point/draw_dot.gd"

@export var time_axis_speed: float = 0.6
@export var sample_interval: float = 0.05
@export var lock_origin_on_ready: bool = true

var _sample_timer: float = 0.0
var _time_origin: Vector3 = Vector3.ZERO
var _origin_set: bool = false

func _ready() -> void:
	super._ready()
	if lock_origin_on_ready and is_instance_valid(_draw_sphere):
		_set_time_origin(_draw_sphere.global_position)

func _set_time_origin(pos: Vector3) -> void:
	_time_origin = pos
	_origin_set = true

func _process(delta: float) -> void:
	if not is_instance_valid(_draw_sphere):
		return

	_time_elapsed += delta

	# Advance existing points along +Z (time axis)
	if _trail_points.size() > 0:
		var z_offset = time_axis_speed * delta
		for i in range(_trail_points.size()):
			_trail_points[i].z += z_offset

	# Respect grab-only recording
	if record_only_when_grabbed and is_instance_valid(_grab_point) and _grab_point.has_method("is_picked_up"):
		if not _grab_point.is_picked_up():
			if fade_trail:
				_cleanup_old_points()
				_rebuild_trail()
			if _progress_indicator:
				_progress_indicator.visible = false
			if _data_table_label:
				_data_table_label.visible = false
			return

	if not _origin_set:
		_set_time_origin(_draw_sphere.global_position)

	_sample_timer += delta
	if _sample_timer >= sample_interval:
		_sample_timer = 0.0
		var current_global = _draw_sphere.global_position
		var trace_point = Vector3(current_global.x, current_global.y, _time_origin.z)
		_trail_points.append(trace_point)
		if fade_trail:
			_trail_times.append(_time_elapsed)

		if _trail_points.size() > 1:
			var prev = _trail_points[_trail_points.size() - 2]
			var delta_xy = Vector2(trace_point.x - prev.x, trace_point.y - prev.y)
			_total_movement += delta_xy.length()

		_check_unlock_progress()
		_update_progress_indicator_position()

	# Update data table (throttled)
	_data_table_timer += delta
	if _data_table_timer >= data_table_update_interval:
		_data_table_timer = 0.0
		_update_data_table()

	if _trail_points.size() > trail_max_points:
		var remove_count = _trail_points.size() - trail_max_points
		for i in range(remove_count):
			_trail_points.pop_front()
			if fade_trail and _trail_times.size() > 0:
				_trail_times.pop_front()

	if fade_trail:
		_cleanup_old_points()

	_rebuild_trail()
