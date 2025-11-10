extends Node3D

@export var grab_point_path: NodePath = NodePath("GrabPoint")
@export var draw_sphere_path: NodePath = NodePath("GrabPoint/DrawSphere")
@export var trail_color: Color = Color(1.0, 0.4, 0.9, 1.0)
@export var trail_max_points: int = 1024
@export var min_segment_distance: float = 0.01
@export var record_only_when_grabbed: bool = true
@export var auto_clear_on_drop: bool = false
@export var reference_frame_position: Vector3 = Vector3(0, 0, 1.0)
@export var reference_frame_size: float = 0.5
@export var show_reference_frame: bool = true

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

	if not _grab_point or not _draw_sphere:
		push_warning("DrawDot: Missing grab point or draw sphere in scene.")
		set_process(false)
		return

	_setup_trail()
	if show_reference_frame:
		_setup_reference_frame()
	_last_global_position = _draw_sphere.global_position
	set_process(true)

	if auto_clear_on_drop and _grab_point.has_signal("dropped"):
		_grab_point.dropped.connect(_on_grab_point_dropped)

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

func _process(_delta: float) -> void:
	if not _draw_sphere:
		return

	var current_global = _draw_sphere.global_position

	if record_only_when_grabbed and _grab_point and _grab_point.has_method("is_picked_up"):
		if not _grab_point.is_picked_up():
			_last_global_position = current_global
			return

	if current_global.distance_to(_last_global_position) < min_segment_distance:
		return

	_last_global_position = current_global
	var local_point = to_local(current_global)
	_trail_points.append(local_point)

	if _trail_points.size() > trail_max_points:
		_trail_points.pop_front()

	_rebuild_trail()

func _rebuild_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return

	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for point in _trail_points:
		_trail_mesh.surface_add_vertex(point)
	_trail_mesh.surface_end()

func clear_trail() -> void:
	_trail_points.clear()
	if _trail_mesh:
		_trail_mesh.clear_surfaces()
	if _draw_sphere:
		_last_global_position = _draw_sphere.global_position

func _on_grab_point_dropped(_pickable) -> void:
	clear_trail()
