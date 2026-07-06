extends Node3D

# @identity
# essence: path(t) — the sequence of positions YOUR body occupies over time, drawn as one growing line; and its derivative, speed, painted into the line's colour so the mark also carries HOW you moved, not only where.
# desire: the learner sees their own walk become geometry — the body writes in space, and the writing remembers the tempo of the writing. Not a puck on a track: the point that moves is you.
# critical_parameter: trail_max_points — how much of the past is remembered and drawn; the horizon of the biography. (velocity_color scales the reading: speed → hue, motion → mark.)
# triggers: any player movement past min_segment_distance — the LINE_STRIP grows with every step, and each new segment is tinted by how fast that step was taken.
# emerges: the realization that motion is a continuous set of points — and that the DERIVATIVE of that set (velocity) is legible, biographical, yours; a line that runs hot where you hurried and cool where you lingered.
# needs: an XROrigin3D to shadow [present, auto-found if the path misses]; a start marker for where the writing began [present]; a now marker for the live nib [present]; no external resources — built procedurally in _ready.
# relationships: the FIRST queer artifact of the point family — the body's own motion made into a mark, before any external system acts on it; complement to draw_dot (the still point) and grid_lines (traces replayed); load-bearing for primitives ("the point moves — the trace") and for change ("velocity as biography, the derivative of a body that is YOU").
# truth: every path through space is a function of time, and you are constantly computing it. The trace is the first place the curriculum hands you the pen: your walk is the data, your speed is the ink, and the line is a self-portrait you cannot help but draw.

## Player Trace - Records the player's movement through space
## Embodies "The Trace" - continuous expression of bodily duration.
## The body writes a line; its speed writes the line's colour — velocity as biography.

@export var xr_origin_path: NodePath = NodePath("../../XROrigin3D")
@export var trail_color: Color = Color(0.2, 0.9, 0.6, 1.0)  # Bright green
@export var trail_max_points: int = 1024
@export var min_segment_distance: float = 0.01
@export var show_reference_frame: bool = true
@export var reference_frame_size: float = 1.0
@export var fade_trail_over_time: bool = false
@export var fade_duration: float = 10.0  # Seconds before oldest points fade
@export var trace_height_offset: float = 0.05  # Height above ground (0.05 = 5cm)
## Velocity-as-biography: tint each segment by how fast that step was taken.
## Slow → cool (trail_color), fast → warm (velocity_fast_color). The derivative made visible.
@export var velocity_color: bool = true
@export var velocity_fast_color: Color = Color(1.0, 0.55, 0.15, 1.0)  # Warm amber for fast motion
@export var velocity_full_speed: float = 2.0  # m/s that reads as fully "fast"
## Show where the writing began (start) and where the live nib is now (now).
@export var show_endpoints: bool = true

var _xr_origin: Node3D
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _trail_points: Array[Vector3] = []
var _trail_times: Array[float] = []  # Track when each point was added
var _trail_speeds: Array[float] = []  # Speed (m/s) at which each point was reached
var _last_global_position: Vector3 = Vector3.ZERO
var _reference_frame: MeshInstance3D
var _time_elapsed: float = 0.0
var _start_marker: MeshInstance3D
var _now_marker: MeshInstance3D

func _ready() -> void:
	# Find XR Origin
	_xr_origin = get_node_or_null(xr_origin_path)
	if not _xr_origin:
		push_warning("PlayerTrace: XROrigin3D not found at path: %s" % xr_origin_path)
		# Try to find it automatically
		_xr_origin = _find_xr_origin()
		if not _xr_origin:
			push_error("PlayerTrace: Could not find XROrigin3D. Trail will not work.")
			set_process(false)
			return

	_setup_trail()
	if show_reference_frame:
		_setup_reference_frame()
	if show_endpoints:
		_setup_endpoints()

	_last_global_position = _xr_origin.global_position
	set_process(true)

	print("PlayerTrace: Tracking player at %s" % _xr_origin.get_path())

func _find_xr_origin() -> Node3D:
	"""Try to find XROrigin3D in the scene tree"""
	var root = get_tree().root
	if root:
		for child in root.get_children():
			var found = _search_for_xr_origin(child)
			if found:
				return found
	return null

func _search_for_xr_origin(node: Node) -> Node3D:
	"""Recursively search for XROrigin3D"""
	if node.name == "XROrigin3D" or node.is_class("XROrigin3D"):
		return node as Node3D
	for child in node.get_children():
		var found = _search_for_xr_origin(child)
		if found:
			return found
	return null

func _setup_trail() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.name = "PlayerTrail"
	_trail_instance.mesh = _trail_mesh

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = trail_color
	material.emission_enabled = true
	material.emission = trail_color
	material.emission_energy_multiplier = 1.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_instance.material_override = material

	add_child(_trail_instance)

func _setup_reference_frame() -> void:
	"""Creates a reference frame showing the traced area"""
	var frame_mesh := ImmediateMesh.new()
	_reference_frame = MeshInstance3D.new()
	_reference_frame.name = "ReferenceFrame"
	_reference_frame.mesh = frame_mesh
	_reference_frame.position = Vector3(0, 0, 0)

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.5, 0.5, 0.6, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_reference_frame.material_override = material

	var half_size := reference_frame_size / 2.0

	frame_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Ground plane grid (showing the reference space)
	var grid_step = reference_frame_size / 4.0
	for i in range(-2, 3):
		var offset = i * grid_step
		# Lines along X
		frame_mesh.surface_add_vertex(Vector3(-half_size, 0, offset))
		frame_mesh.surface_add_vertex(Vector3(half_size, 0, offset))
		# Lines along Z
		frame_mesh.surface_add_vertex(Vector3(offset, 0, -half_size))
		frame_mesh.surface_add_vertex(Vector3(offset, 0, half_size))

	frame_mesh.surface_end()

	add_child(_reference_frame)

func _make_marker(marker_color: Color, radius: float) -> MeshInstance3D:
	"""Builds a small emissive sphere marker (start / now)."""
	var marker := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	marker.mesh = sphere

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = marker_color
	material.emission_enabled = true
	material.emission = marker_color
	material.emission_energy_multiplier = 2.0
	marker.material_override = material
	marker.visible = false  # Hidden until the trace has a first point
	return marker

func _setup_endpoints() -> void:
	"""Start marker = where the writing began; now marker = the live nib."""
	_start_marker = _make_marker(trail_color, 0.045)
	_start_marker.name = "TraceStart"
	add_child(_start_marker)

	_now_marker = _make_marker(velocity_fast_color, 0.06)
	_now_marker.name = "TraceNow"
	add_child(_now_marker)

func _process(delta: float) -> void:
	if not _xr_origin:
		return

	_time_elapsed += delta

	var current_global = _xr_origin.global_position

	# Check if we've moved enough to record a new point
	var step_distance = current_global.distance_to(_last_global_position)
	if step_distance < min_segment_distance:
		return

	# Speed of this step: distance / time — the derivative of the body's path.
	var step_speed = 0.0 if delta <= 0.0 else step_distance / delta

	_last_global_position = current_global
	# Convert to local space and add height offset
	var local_point = to_local(current_global)
	local_point.y += trace_height_offset  # Offset trail above ground
	_trail_points.append(local_point)
	_trail_times.append(_time_elapsed)
	_trail_speeds.append(step_speed)

	# Enforce max points limit
	if _trail_points.size() > trail_max_points:
		_trail_points.pop_front()
		_trail_times.pop_front()
		_trail_speeds.pop_front()

	# Fade old points if enabled
	if fade_trail_over_time:
		_fade_old_points()

	_rebuild_trail()
	_update_endpoints()

func _velocity_to_color(speed: float) -> Color:
	"""Slow → cool (trail_color), fast → warm (velocity_fast_color). Speed is the ink."""
	var t = clamp(speed / max(velocity_full_speed, 0.001), 0.0, 1.0)
	return trail_color.lerp(velocity_fast_color, t)

func _update_endpoints() -> void:
	"""Place the start marker at the first point and the now marker at the last."""
	if not show_endpoints or _trail_points.is_empty():
		return
	if _start_marker:
		_start_marker.position = _trail_points[0]
		_start_marker.visible = true
	if _now_marker:
		_now_marker.position = _trail_points[_trail_points.size() - 1]
		_now_marker.visible = true

func _fade_old_points() -> void:
	"""Remove points older than fade_duration"""
	var cutoff_time = _time_elapsed - fade_duration
	var remove_count = 0

	for i in range(_trail_times.size()):
		if _trail_times[i] < cutoff_time:
			remove_count += 1
		else:
			break

	if remove_count > 0:
		for i in range(remove_count):
			_trail_points.pop_front()
			_trail_times.pop_front()
			if not _trail_speeds.is_empty():
				_trail_speeds.pop_front()

func _rebuild_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return

	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	var speeds_valid = _trail_speeds.size() == _trail_points.size()
	var fading = fade_trail_over_time and _trail_times.size() == _trail_points.size()

	if fading or (velocity_color and speeds_valid):
		# Per-vertex colour: hue from velocity (the derivative), alpha from age (the fade).
		for i in range(_trail_points.size()):
			var base_col = trail_color
			if velocity_color and speeds_valid:
				base_col = _velocity_to_color(_trail_speeds[i])

			var alpha = base_col.a
			if fading:
				var age = _time_elapsed - _trail_times[i]
				alpha = 1.0 - clamp(age / fade_duration, 0.0, 1.0)

			_trail_mesh.surface_set_color(Color(base_col.r, base_col.g, base_col.b, alpha))
			_trail_mesh.surface_add_vertex(_trail_points[i])
	else:
		# Simple trail without fading or velocity colour
		for point in _trail_points:
			_trail_mesh.surface_add_vertex(point)

	_trail_mesh.surface_end()

func clear_trail() -> void:
	"""Clears all recorded trail points"""
	_trail_points.clear()
	_trail_times.clear()
	_trail_speeds.clear()
	if _trail_mesh:
		_trail_mesh.clear_surfaces()
	if _start_marker:
		_start_marker.visible = false
	if _now_marker:
		_now_marker.visible = false
	if _xr_origin:
		_last_global_position = _xr_origin.global_position

func get_trail_length() -> float:
	"""Returns the total length of the trail in meters"""
	var length = 0.0
	for i in range(1, _trail_points.size()):
		length += _trail_points[i].distance_to(_trail_points[i - 1])
	return length

func get_point_count() -> int:
	"""Returns the number of points in the trail"""
	return _trail_points.size()
