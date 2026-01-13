extends Node3D

@export var grab_point_path: NodePath = NodePath("GrabPoint")
@export var draw_sphere_path: NodePath = NodePath("GrabPoint/DrawSphere")
@export var trail_color: Color = Color(1.0, 0.4, 0.9, 1.0)
@export var trail_max_points: int = 1024
@export var min_segment_distance: float = 0.01
@export var record_only_when_grabbed: bool = true
@export var auto_clear_on_drop: bool = false
@export var reference_frame_position: Vector3 = Vector3(0, 0, 0.2)
@export var reference_frame_size: float = 0.5
@export var show_reference_frame: bool = true

var _grab_point: Node3D
var _draw_sphere: Node3D
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _trail_points: Array[Vector3] = []
var _last_global_position: Vector3 = Vector3.ZERO
var _reference_frame: MeshInstance3D



func _setup_trail() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.name = "DrawTrail"
	_trail_instance.mesh = _trail_mesh

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = trail_color
	material.emission_enabled = true
	material.emission = trail_color
	material.emission_energy_multiplier = 1.25
	_trail_instance.material_override = material
	
	# Important: Trail should be in global space, not moving with the hand
	_trail_instance.set_as_top_level(true)

	add_child(_trail_instance)

func _setup_reference_frame() -> void:
	var frame_mesh := ImmediateMesh.new()
	_reference_frame = MeshInstance3D.new()
	_reference_frame.name = "ReferenceFrame"
	_reference_frame.mesh = frame_mesh
	_reference_frame.position = reference_frame_position
	
	# Reference frame moves with the object (it's a local guide)
	# So we don't set top_level here

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.7, 0.7, 0.7, 0.8)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_reference_frame.material_override = material

	var half_size := reference_frame_size / 2.0
	var horizon_half := half_size / 2.0

	frame_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Top edge
	frame_mesh.surface_add_vertex(Vector3(-half_size, half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(half_size, half_size, 0))

	# Bottom edge
	frame_mesh.surface_add_vertex(Vector3(-half_size, -half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(half_size, -half_size, 0))

	# Left edge
	frame_mesh.surface_add_vertex(Vector3(-half_size, -half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(-half_size, half_size, 0))

	# Right edge
	frame_mesh.surface_add_vertex(Vector3(half_size, -half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(half_size, half_size, 0))

	# Horizon line (thinner - half width in middle)
	frame_mesh.surface_add_vertex(Vector3(-horizon_half, 0, 0))
	frame_mesh.surface_add_vertex(Vector3(horizon_half, 0, 0))

	frame_mesh.surface_end()

	add_child(_reference_frame)

@export var fade_trail: bool = false
@export var fade_duration: float = 2.0


# Tag System
@export_group("Tag System")
@export var trigger_tag: String = ""
@export var trigger_action: String = "shrink_and_remove"
@export var movement_threshold: float = 2.0 # Meters of movement required
@export var unlock_progress_color: Color = Color(0.2, 1.0, 0.4) # Green when finished

@export var unlock_sound: AudioStream

var _trail_times: Array[float] = []
var _time_elapsed: float = 0.0

var _total_movement: float = 0.0
var _triggered: bool = false
var _original_color: Color

var _success_player: AudioStreamPlayer3D
var _progress_indicator: MeshInstance3D

func _ready() -> void:
	print("DrawDot: _ready called")
	var trace_data = get_node_or_null("/root/TraceData")
	print("DrawDot: TraceData status: " + str(trace_data))

	_grab_point = get_node_or_null(grab_point_path)
	_draw_sphere = get_node_or_null(draw_sphere_path)
	
	if _grab_point:
		_progress_indicator = _grab_point.get_node_or_null("ProgressIndicator")
		if _progress_indicator:
			_progress_indicator.visible = false
	
	if not _grab_point or not _draw_sphere:
		push_warning("DrawDot: Missing grab point or draw sphere in scene.")
		set_process(false)
		return

	_setup_trail()
	_setup_success_audio()
	if show_reference_frame:
		_setup_reference_frame()
	_last_global_position = _draw_sphere.global_position
	set_process(true)

	# Always connect to dropped to handle saving, regardless of auto-clear
	if _grab_point.has_signal("dropped"):
		if not _grab_point.is_connected("dropped", _on_grab_point_dropped):
			_grab_point.dropped.connect(_on_grab_point_dropped)
	
func _process(delta: float) -> void:
	if not is_instance_valid(_draw_sphere):
		return

	_time_elapsed += delta

	var current_global = _draw_sphere.global_position

	if record_only_when_grabbed and is_instance_valid(_grab_point) and _grab_point.has_method("is_picked_up"):
		if not _grab_point.is_picked_up():
			_last_global_position = current_global
			# If we are not recording, we should still process fading if enabled
			if fade_trail:
				_cleanup_old_points()
				_rebuild_trail()
			
			# Hide progress indicator when not grabbed
			if _progress_indicator:
				_progress_indicator.visible = false
				
			return
	
	# Calculate movement since last frame
	var dist = current_global.distance_to(_last_global_position)
	
	if dist > 0:
		_total_movement += dist
		_check_unlock_progress()

	if dist < min_segment_distance:
		if fade_trail:
			_cleanup_old_points()
			_rebuild_trail()
		return

	_last_global_position = current_global
	# Use global position for the trail points since the mesh is top_level
	_trail_points.append(current_global)

	if fade_trail:
		_trail_times.append(_time_elapsed)

	if _trail_points.size() > trail_max_points:
		_trail_points.pop_front()
		if fade_trail and _trail_times.size() > 0:
			_trail_times.pop_front()
			
	if fade_trail:
		_cleanup_old_points()

	_rebuild_trail()

func _check_unlock_progress() -> void:
	if _triggered or trigger_tag == "":
		return
		
	var progress = clamp(_total_movement / movement_threshold, 0.0, 1.0)
	
	# Update progress indicator
	if _progress_indicator:
		_progress_indicator.visible = true
		if _progress_indicator.material_override:
			_progress_indicator.material_override.set_shader_parameter("progress", progress)
	

	
	if progress >= 1.0:
		_trigger_unlock()

func _trigger_unlock() -> void:
	_triggered = true
	
	# Trigger sequence: Sound -> Wait -> Action
	if _success_player:
		_success_player.play()
	
	# Wait for 1 second
	await get_tree().create_timer(1.0).timeout
	
	print("DrawDot: Movement threshold reached! Triggering tag '%s' action '%s'" % [trigger_tag, trigger_action])
	
	# Trigger action on the tag (e.g. "remove")
	# Assuming TagSystem is a global class or autoload
	if TagSystem:
		# Safety: Ensure WE are not about to be removed if we accidentally share the tag
		if trigger_action == "remove" or trigger_action == "shrink_and_remove":
			TagSystem.unregister_tagged_node(trigger_tag, self)
			if _grab_point:
				TagSystem.unregister_tagged_node(trigger_tag, _grab_point)
			
		TagSystem.trigger_tag_action(trigger_tag, trigger_action)
	else:
		push_warning("DrawDot: TagSystem not found!")

func _setup_success_audio() -> void:
	_success_player = AudioStreamPlayer3D.new()
	_success_player.name = "SuccessPlayer"
	if unlock_sound:
		_success_player.stream = unlock_sound
	else:
		_success_player.stream = _build_default_success_stream()
	_success_player.unit_size = 5.0 # Hearable from distance
	add_child(_success_player)

func _build_default_success_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = true
	var duration := 0.5
	var length := int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(length * 4) # 16-bit stereo = 4 bytes per sample
	
	for i in length:
		var t: float = float(i) / stream.mix_rate
		# Simple "ding" - high pitch sine wave with decay
		var envelope: float = exp(-5.0 * t)
		var sample: float = sin(TAU * 1200.0 * t) * 0.5 * envelope
		# Add a harmonic
		sample += sin(TAU * 2400.0 * t) * 0.2 * envelope
		
		var int_sample: int = int(sample * 32767.0)
		# Stereo copy
		var low = int_sample & 0xFF
		var high = (int_sample >> 8) & 0xFF
		
		data[4 * i] = low
		data[4 * i + 1] = high
		data[4 * i + 2] = low
		data[4 * i + 3] = high
		
	stream.data = data
	return stream

func _cleanup_old_points() -> void:
	if _trail_times.is_empty():
		return
		
	var cutoff = _time_elapsed - fade_duration
	while _trail_times.size() > 0 and _trail_times[0] < cutoff:
		_trail_times.pop_front()
		_trail_points.pop_front()

func _rebuild_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return

	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	if fade_trail and _trail_times.size() == _trail_points.size():
		for i in range(_trail_points.size()):
			var age = _time_elapsed - _trail_times[i]
			var alpha = 1.0 - clamp(age / fade_duration, 0.0, 1.0)
			var color = trail_color
			color.a = alpha
			_trail_mesh.surface_set_color(color)
			_trail_mesh.surface_add_vertex(_trail_points[i])
	else:
		for point in _trail_points:
			_trail_mesh.surface_add_vertex(point)
	
	_trail_mesh.surface_end()


func clear_trail() -> void:
	_trail_points.clear()
	if _trail_mesh:
		_trail_mesh.clear_surfaces()
	if is_instance_valid(_draw_sphere):
		_last_global_position = _draw_sphere.global_position

func _on_grab_point_dropped(_pickable) -> void:
	var trace_data = get_node_or_null("/root/TraceData")
	if trace_data:
		trace_data.add_trace(_trail_points)
	
	if _progress_indicator:
		_progress_indicator.visible = false
		
	if auto_clear_on_drop:
		clear_trail()
