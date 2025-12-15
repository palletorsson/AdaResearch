extends Node3D
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

var _grab_point: Node3D
var _draw_sphere: Node3D
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _trail_points: Array[Vector3] = []
var _last_global_position: Vector3 = Vector3.ZERO
var _reference_frame: MeshInstance3D

func _ready() -> void:
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

func _process(_delta: float) -> void:
	if not _draw_sphere:
		return

	var current_global = _draw_sphere.global_position

	# Only record when grabbed
	if record_only_when_grabbed and _grab_point and _grab_point.has_method("is_picked_up"):
		if not _grab_point.is_picked_up():
			_last_global_position = current_global
			return

	# Snap current position to grid for tracing
	var snapped_global = snap_position_to_grid(current_global)

	# Minimum distance check (using snapped positions to ensure distinct grid points)
	if snapped_global.distance_to(_last_global_position) < min_segment_distance:
		return
	
	# If strict grid tracing is desired, we ensure we only add points that are exactly on grid nodes
	# But maybe they want lines between grid nodes?
	# Let's assume connecting grid points is what "trace the grid means"
	
	_last_global_position = snapped_global
	_trail_points.append(snapped_global)

	if _trail_points.size() > trail_max_points:
		_trail_points.pop_front()

	_rebuild_trail()

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
	if _trail_mesh:
		_trail_mesh.clear_surfaces()
	if _draw_sphere:
		_last_global_position = _draw_sphere.global_position

func get_trail_points() -> Array[Vector3]:
	return _trail_points.duplicate()
