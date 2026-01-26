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

func _setup_progress_indicator() -> void:
	# Create progress indicator as world-space element (not child of grab point)
	var progress_shader = load("res://commons/scenes/main_menu/components/linear_progress.gdshader")
	if not progress_shader:
		push_warning("DrawDot: Could not load progress shader")
		return

	_progress_indicator = MeshInstance3D.new()
	_progress_indicator.name = "ProgressIndicator"

	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.2, 0.04)
	_progress_indicator.mesh = quad_mesh

	var material = ShaderMaterial.new()
	material.render_priority = 100
	material.shader = progress_shader
	material.set_shader_parameter("progress", 0.0)
	material.set_shader_parameter("color", unlock_progress_color)
	_progress_indicator.material_override = material

	# Make it world-space so it doesn't follow the hand
	_progress_indicator.set_as_top_level(true)
	_progress_indicator.visible = false

	add_child(_progress_indicator)

func _update_progress_indicator_position() -> void:
	if not _progress_indicator or _trail_points.is_empty():
		return

	# Position above the first trail point (start of drawing)
	var start_pos = _trail_points[0]
	_progress_indicator.global_position = start_pos + Vector3(0, progress_bar_height_offset, 0)

func _setup_data_table() -> void:
	if not show_data_table:
		return

	_data_table_label = Label3D.new()
	_data_table_label.name = "DataTable"
	_data_table_label.font_size = data_table_font_size
	_data_table_label.pixel_size = 0.001  # Sharper text
	_data_table_label.modulate = data_table_color
	_data_table_label.outline_size = 2
	_data_table_label.outline_modulate = Color(0.1, 0.1, 0.2, 0.9)

	# NOT billboard - fixed orientation
	_data_table_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_data_table_label.fixed_size = false

	# World-space positioning
	_data_table_label.set_as_top_level(true)
	_data_table_label.visible = false

	# Horizontal alignment
	_data_table_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Rotate 90° in X (parallel to ground) and 180° in Y
	_data_table_label.rotation_degrees.x = -90
	_data_table_label.rotation_degrees.y = 180

	# Scale for sharper text
	_data_table_label.scale = Vector3(1.0, 1.0, 1.0)

	add_child(_data_table_label)

func _update_data_table() -> void:
	if not _data_table_label or _trail_points.is_empty():
		return

	var current_pos = _draw_sphere.global_position if _draw_sphere else Vector3.ZERO
	var trail_length = _total_movement
	var point_count = _trail_points.size()
	var dist_from_origin = current_pos.length()

	# Build table text with last 10 points
	var table_text = "TRACE DATA\n"
	table_text += "─────────────────\n"
	table_text += "Points: %d  Length: %.2f m\n" % [point_count, trail_length]
	table_text += "─────────────────\n"
	table_text += "LAST 10 POSITIONS\n"

	# Show last 10 points (or fewer if less than 10 exist)
	var start_idx = max(0, _trail_points.size() - 10)
	for i in range(start_idx, _trail_points.size()):
		var pt = _trail_points[i]
		var idx = i - start_idx + 1
		table_text += "%2d: (%.2f, %.2f, %.2f)\n" % [idx, pt.x, pt.y, pt.z]

	_data_table_label.text = table_text
	_data_table_label.visible = true

	# Position near trail start, offset to the side and forward
	var start_pos = _trail_points[0]
	_data_table_label.global_position = start_pos + Vector3(0.15, data_table_height_offset - 0.1, 0.2)

@export var fade_trail: bool = false
@export var fade_duration: float = 2.0
@export var progress_bar_height_offset: float = 0.15  # Height above trail start point

# Data Table Display
@export_group("Data Table")
@export var show_data_table: bool = true
@export var data_table_height_offset: float = -0.35  # Height relative to trail start
@export var data_table_color: Color = Color(0.9, 0.95, 1.0, 1.0)
@export var data_table_font_size: int = 20
@export var data_table_update_interval: float = 0.15  # Seconds between updates

var _data_table_label: Label3D
var _data_table_timer: float = 0.0


# Tag System
@export_group("Tag System")
@export var trigger_tag: String = ""
@export var trigger_action: String = "shrink_and_remove"
@export var movement_threshold: float = 6.0 # Meters of drawing movement required (trail length)
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

	# Setup progress indicator as world-space (not child of grab point)
	_setup_progress_indicator()

	# Setup data table display
	_setup_data_table()

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
			
			# Hide progress indicator and data table when not grabbed
			if _progress_indicator:
				_progress_indicator.visible = false
			if _data_table_label:
				_data_table_label.visible = false

			return
	
	# Calculate movement since last frame
	var dist = current_global.distance_to(_last_global_position)

	if dist < min_segment_distance:
		if fade_trail:
			_cleanup_old_points()
			_rebuild_trail()
		return

	_last_global_position = current_global
	# Use global position for the trail points since the mesh is top_level
	_trail_points.append(current_global)

	# Only count movement when actually drawing (adding trail points)
	_total_movement += dist
	_check_unlock_progress()

	# Position progress indicator above trail start point
	_update_progress_indicator_position()

	# Update data table (throttled)
	_data_table_timer += delta
	if _data_table_timer >= data_table_update_interval:
		_data_table_timer = 0.0
		_update_data_table()

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
