extends Node3D

# @identity
# essence: snap(position) = round(position / grid_size) * grid_size — discretise continuous space
# desire: learner feels the tension between analog hand movement and digital quantized grid
# critical_parameter: grid_size — the quantization step that snaps position to nearest lattice point
# triggers: moving the grabbed sphere — each snap is a click, a discrete decision
# emerges: the grid as a constraint that makes space countable; infinite positions become finite choices
# needs: [has Label3D [has], grabbable sphere [has], missing grid_size VR slider]
# relationships: sibling to draw_dot (continuous vs discrete); foundation for voxel/pixel thinking
# truth: quantization is a choice about what differences are worth keeping

## Grab sphere point that snaps to grid and leaves a trail

@export var grab_point_path: NodePath = NodePath("GrabPoint")
@export var draw_sphere_path: NodePath = NodePath("GrabPoint/DrawSphere")

# Grid snapping
@export var snap_to_grid: bool = true
@export var grid_size: float = 1.0
@export var snap_on_drop: bool = true

# Trail settings
@export var trail_color: Color = Color(0.2, 1.0, 0.6, 1.0)
@export var trail_max_points: int = 4096
@export var min_segment_distance: float = 0.005
@export var record_only_when_grabbed: bool = true
@export var auto_clear_on_drop: bool = false

# Reference frame
@export var reference_frame_position: Vector3 = Vector3(0, 0, 0.2)
@export var reference_frame_size: float = 0.5
@export var show_reference_frame: bool = false

# Data Table Display
@export_group("Data Table")
@export var show_data_table: bool = true
@export var data_table_height_offset: float = -0.35
@export var data_table_color: Color = Color(0.9, 0.95, 1.0, 1.0)
@export var data_table_font_size: int = 20
@export var data_table_update_interval: float = 0.15  # Seconds between updates

var _data_table_label: Label3D
var _data_table_timer: float = 0.0
var _total_trail_length: float = 0.0

var _grab_point: Node3D
var _draw_sphere: Node3D
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _trail_points: Array[Vector3] = []
var _last_global_position: Vector3 = Vector3.ZERO
var _reference_frame: MeshInstance3D

func _ready() -> void:
	# Prevent gravity gun from affecting drag points
	add_to_group("no_gravity_gun")

	_grab_point = get_node_or_null(grab_point_path)
	_draw_sphere = get_node_or_null(draw_sphere_path)

	if not _grab_point:
		push_warning("GrabSpherePointSnap: Missing grab point in scene.")
		set_process(false)
		return

	# Use grab point position if no draw sphere
	if not _draw_sphere:
		_draw_sphere = _grab_point

	_setup_trail()
	if show_reference_frame:
		_setup_reference_frame()
	_setup_data_table()
	_last_global_position = _draw_sphere.global_position
	set_process(true)

	# Connect to grab point signals
	if _grab_point.has_signal("dropped"):
		_grab_point.dropped.connect(_on_grab_point_dropped)
	if _grab_point.has_signal("picked_up"):
		_grab_point.picked_up.connect(_on_grab_point_picked_up)

func _setup_trail() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.name = "SnapTrail"
	_trail_instance.mesh = _trail_mesh

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = trail_color
	material.emission_enabled = true
	material.emission = trail_color
	material.emission_energy_multiplier = 1.5
	_trail_instance.material_override = material

	# Trail in global space
	_trail_instance.set_as_top_level(true)
	add_child(_trail_instance)

func _setup_reference_frame() -> void:
	var frame_mesh := ImmediateMesh.new()
	_reference_frame = MeshInstance3D.new()
	_reference_frame.name = "ReferenceFrame"
	_reference_frame.mesh = frame_mesh
	_reference_frame.position = reference_frame_position

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.7, 0.7, 0.7, 0.8)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_reference_frame.material_override = material

	var half_size := reference_frame_size / 2.0

	frame_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	# Square frame
	frame_mesh.surface_add_vertex(Vector3(-half_size, half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(half_size, half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(-half_size, -half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(half_size, -half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(-half_size, -half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(-half_size, half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(half_size, -half_size, 0))
	frame_mesh.surface_add_vertex(Vector3(half_size, half_size, 0))
	frame_mesh.surface_end()

	add_child(_reference_frame)

func _process(delta: float) -> void:
	if not _draw_sphere:
		return

	var current_global = _draw_sphere.global_position

	# Only record when grabbed
	if record_only_when_grabbed and _grab_point and _grab_point.has_method("is_picked_up"):
		if not _grab_point.is_picked_up():
			_last_global_position = current_global
			# Hide data table when not grabbed
			if _data_table_label:
				_data_table_label.visible = false
			return

	# Snap current position to grid for tracing
	var snapped_global = snap_position_to_grid(current_global)

	# Minimum distance check (using snapped positions to ensure distinct grid points)
	if snapped_global.distance_to(_last_global_position) < min_segment_distance:
		return
	
	# If strict grid tracing is desired, we ensure we only add points that are exactly on grid nodes
	# But maybe they want lines between grid nodes?
	# Let's assume connecting grid points is what "trace the grid means"
	
	# Track trail length
	_total_trail_length += snapped_global.distance_to(_last_global_position)

	_last_global_position = snapped_global
	_trail_points.append(snapped_global)

	if _trail_points.size() > trail_max_points:
		_trail_points.pop_front()

	_rebuild_trail()

	# Update data table (throttled)
	_data_table_timer += delta
	if _data_table_timer >= data_table_update_interval:
		_data_table_timer = 0.0
		_update_data_table()

	# Optional: visually snap the draw sphere if we want the object to look like it's on grid?
	# _draw_sphere.global_position = snapped_global # This might jitter against hand smoothness
	# Better to let the trail be the grid trace.

func _rebuild_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return

	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for point in _trail_points:
		_trail_mesh.surface_add_vertex(point)
	_trail_mesh.surface_end()

func snap_position_to_grid(pos: Vector3) -> Vector3:
	if not snap_to_grid:
		return pos
	return Vector3(
		round(pos.x / grid_size) * grid_size,
		round(pos.y / grid_size) * grid_size,
		round(pos.z / grid_size) * grid_size
	)

func _on_grab_point_dropped(_pickable) -> void:
	if auto_clear_on_drop:
		clear_trail()

	# Snap to grid on drop
	if snap_on_drop and _grab_point:
		var snapped_pos = snap_position_to_grid(_grab_point.global_position)
		_grab_point.global_position = snapped_pos
		print("GrabSpherePointSnap: Snapped to grid at %s" % snapped_pos)

		# Add snapped position to trail
		_trail_points.append(snapped_pos)
		_rebuild_trail()

func _on_grab_point_picked_up(_pickable) -> void:
	# Record starting position when picked up
	if _grab_point:
		_last_global_position = _grab_point.global_position

func clear_trail() -> void:
	_trail_points.clear()
	_total_trail_length = 0.0
	if _trail_mesh:
		_trail_mesh.clear_surfaces()
	if _draw_sphere:
		_last_global_position = _draw_sphere.global_position
	if _data_table_label:
		_data_table_label.visible = false

func get_trail_points() -> Array[Vector3]:
	return _trail_points.duplicate()

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
	var snapped_pos = snap_position_to_grid(current_pos)
	var point_count = _trail_points.size()

	# Build table text with two columns: Point (raw) | Snap (grid)
	var table_text = "GRID TRACE DATA\n"
	table_text += "Points: %d  Length: %.2f m\n" % [point_count, _total_trail_length]
	table_text += "─────────────────────────────────\n"
	table_text += "  POINT (raw)      │  SNAP (grid)\n"
	table_text += "─────────────────────────────────\n"

	# Show last 10 points with both raw and snapped values
	var start_idx = max(0, _trail_points.size() - 10)
	for i in range(start_idx, _trail_points.size()):
		var pt = _trail_points[i]
		var snapped = snap_position_to_grid(pt)
		var grid = snapped / grid_size
		table_text += "(%.1f,%.1f,%.1f) │ (%d,%d,%d)\n" % [pt.x, pt.y, pt.z, int(grid.x), int(grid.y), int(grid.z)]

	_data_table_label.text = table_text
	_data_table_label.visible = true

	# Position near trail start, offset to the side and forward
	var start_pos = _trail_points[0]
	_data_table_label.global_position = start_pos + Vector3(0.15, data_table_height_offset - 0.1, 0.2)
