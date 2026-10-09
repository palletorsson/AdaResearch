extends "res://commons/primitives/point/draw_dot.gd"


# @identity
# essence: trace(t) = (x(t), y(t), z_origin - v_z * t) — position history as frozen trail
# desire: Grab a point in VR and see your hand movements recorded as a time-domain waveform
# critical_parameter: time_axis_speed — controls how fast history recedes along the Z axis
# triggers: continuous sampling of draw sphere position at sample_interval creates the trace
# emerges: hand gestures become visible waveforms — the body as oscillator made legible
# needs: VR grab on draw sphere [has], trail rendering [has]
# relationships: extends draw_dot base; contrasts with OscillationCurve (manual vs algorithmic wave drawing); unlocks gesture-to-waveform
# truth: Every motion is a signal; recording it in time reveals the wave hidden in movement.

@export var time_axis_speed: float = 0.6
@export var sample_interval: float = 0.05
@export var lock_origin_on_ready: bool = true

var _sample_timer: float = 0.0
var _time_origin: Vector3 = Vector3.ZERO
var _origin_set: bool = false

## This recorder admits stationary samples on a clock and puts time on Z;
## the inherited movement threshold and free-space grid do not gate its samples.
func _sampling_contract_text() -> String:
	var gate: String = ">= " + String.num(sample_interval, 3) + " s" if sample_interval > 0.0 else "every frame"
	var fading: String = String.num(fade_duration, 3) + " s" if fade_trail else "off"
	return "Sample gate: " + gate + " | Z drift: " + String.num(time_axis_speed, 3) + " m/s\nFade: " + fading


func _ready() -> void:
	if str(get_meta("config_gallery", "")) == "open":
		fade_duration = 10.0
		data_table_mount = "plinth"
		get_node("GrabPoint").position = Vector3(-0.45,0.15,-0.35)
		var title := Label3D.new()
		title.text = "YOUR HAND / TIME\nGrab the point. Move across the record."
		title.font_size = 26
		title.pixel_size = 0.0018
		title.position = Vector3(0,1.15,0)
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(title)
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
			_hide_data_table()
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

	if _trail_points.size() > trail_max_points:
		var remove_count = _trail_points.size() - trail_max_points
		for i in range(remove_count):
			_trail_points.pop_front()
			if fade_trail and _trail_times.size() > 0:
				_trail_times.pop_front()

	if fade_trail:
		_cleanup_old_points()

	_rebuild_trail()
	# The inherited count describes the retained buffer after cap and fade.
	_data_table_timer += delta
	_refresh_data_table_if_due()
