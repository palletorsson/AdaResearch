extends Node3D

# @identity
# essence: path(t) — the sequence of positions your body occupies over time
# desire: learner sees their own movement become geometry — the body writes in space
# critical_parameter: trail_length — how many past positions are remembered and drawn
# triggers: any player movement — the LINE_STRIP grows with every step taken
# emerges: the realization that motion is just a continuous set of points — a set of coordinates
# needs: [missing VR controls — purely passive recorder of XROrigin3D position]
# relationships: used alongside player_trace in grid_lines to replay traces; complement to draw_dot
# truth: every path through space is a function of time, and you are constantly computing it

## Player Trace - Records the player's movement through space
## Embodies "The Trace" - continuous expression of bodily duration

@export var xr_origin_path: NodePath = NodePath("../../XROrigin3D")
@export var trail_color: Color = Color(0.2, 0.9, 0.6, 1.0)  # Bright green
@export var trail_max_points: int = 1024
@export var min_segment_distance: float = 0.01
@export var show_reference_frame: bool = true
@export var reference_frame_size: float = 1.0
@export var fade_trail_over_time: bool = false
@export var fade_duration: float = 10.0  # Seconds before oldest points fade
@export var trace_height_offset: float = 0.05  # Height above ground (0.05 = 5cm)

var _xr_origin: Node3D
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _trail_points: Array[Vector3] = []
var _trail_times: Array[float] = []  # Track when each point was added
var _last_global_position: Vector3 = Vector3.ZERO
var _reference_frame: MeshInstance3D
var _time_elapsed: float = 0.0

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

func _process(delta: float) -> void:
	if not _xr_origin:
		return

	_time_elapsed += delta

	var current_global = _xr_origin.global_position

	# Check if we've moved enough to record a new point
	if current_global.distance_to(_last_global_position) < min_segment_distance:
		return

	_last_global_position = current_global
	# Convert to local space and add height offset
	var local_point = to_local(current_global)
	local_point.y += trace_height_offset  # Offset trail above ground
	_trail_points.append(local_point)
	_trail_times.append(_time_elapsed)

	# Enforce max points limit
	if _trail_points.size() > trail_max_points:
		_trail_points.pop_front()
		_trail_times.pop_front()

	# Fade old points if enabled
	if fade_trail_over_time:
		_fade_old_points()

	_rebuild_trail()

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

func _rebuild_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return

	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	# Draw with optional fading based on age
	if fade_trail_over_time and _trail_times.size() == _trail_points.size():
		var cutoff_time = _time_elapsed - fade_duration
		for i in range(_trail_points.size()):
			# Calculate alpha based on age
			var age = _time_elapsed - _trail_times[i]
			var alpha = 1.0 - clamp(age / fade_duration, 0.0, 1.0)

			_trail_mesh.surface_set_color(Color(trail_color.r, trail_color.g, trail_color.b, alpha))
			_trail_mesh.surface_add_vertex(_trail_points[i])
	else:
		# Simple trail without fading
		for point in _trail_points:
			_trail_mesh.surface_add_vertex(point)

	_trail_mesh.surface_end()

func clear_trail() -> void:
	"""Clears all recorded trail points"""
	_trail_points.clear()
	_trail_times.clear()
	if _trail_mesh:
		_trail_mesh.clear_surfaces()
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
