extends Node3D

@export var target_path: NodePath = NodePath("PickUpCube")
@export var trail_color: Color = Color(0.95, 0.7, 0.2, 1.0)
@export var trail_max_points: int = 1000
@export var sample_interval: float = 0.05
@export var time_axis_speed: float = 0.6
@export var fade_trail_over_time: bool = false
@export var fade_duration: float = 10.0

var _target: Node3D
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _trail_points: Array[Vector3] = []
var _trail_times: Array[float] = []
var _time_elapsed: float = 0.0
var _sample_timer: float = 0.0
var _origin_z: float = 0.0
var _origin_set: bool = false

func _ready() -> void:
	_target = get_node_or_null(target_path)
	if not _target:
		push_warning("MarioCubeTimeTrace: Target not found at %s" % target_path)
		set_process(false)
		return

	_setup_trail()
	_origin_z = _target.global_position.z
	_origin_set = true
	set_process(true)

func _setup_trail() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.name = "MarioCubeTimeTrace"
	_trail_instance.mesh = _trail_mesh

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = trail_color
	material.emission_enabled = true
	material.emission = trail_color
	material.emission_energy_multiplier = 1.5
	_trail_instance.material_override = material
	_trail_instance.set_as_top_level(true)

	add_child(_trail_instance)

func _process(delta: float) -> void:
	if not _target:
		return

	_time_elapsed += delta

	# Advance existing points along +Z (time axis)
	if _trail_points.size() > 0:
		var z_offset = time_axis_speed * delta
		for i in range(_trail_points.size()):
			_trail_points[i].z += z_offset

	_sample_timer += delta
	if _sample_timer >= sample_interval:
		_sample_timer = 0.0
		var current_global = _target.global_position
		if not _origin_set:
			_origin_z = current_global.z
			_origin_set = true

		var trace_point = Vector3(current_global.x, current_global.y, _origin_z)
		_trail_points.append(trace_point)
		if fade_trail_over_time:
			_trail_times.append(_time_elapsed)

		if _trail_points.size() > trail_max_points:
			_trail_points.pop_front()
			if fade_trail_over_time and _trail_times.size() > 0:
				_trail_times.pop_front()

		if fade_trail_over_time:
			_cleanup_old_points()

	_rebuild_trail()

func _cleanup_old_points() -> void:
	if _trail_times.is_empty():
		return

	var cutoff_time = _time_elapsed - fade_duration
	while _trail_times.size() > 0 and _trail_times[0] < cutoff_time:
		_trail_times.pop_front()
		_trail_points.pop_front()

func _rebuild_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return

	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	if fade_trail_over_time and _trail_times.size() == _trail_points.size():
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
