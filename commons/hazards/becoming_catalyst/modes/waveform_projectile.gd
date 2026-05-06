# WaveformProjectile.gd
# Continuous double helix — two glowing trails spiral around the forward axis.
# Wave-particle duality as identity — always oscillating, never fixed.
extends CatalystProjectile

var _wave_freq: float = 5.0
var _wave_amp: float = 0.12
var _local_right: Vector3 = Vector3.RIGHT
var _local_up: Vector3 = Vector3.UP

# Helix trail rendering
var _trail_a_im: ImmediateMesh
var _trail_b_im: ImmediateMesh
var _trail_a_mesh: MeshInstance3D
var _trail_b_mesh: MeshInstance3D
var _trail_a_points: PackedVector3Array = PackedVector3Array()
var _trail_b_points: PackedVector3Array = PackedVector3Array()
var _strand_b_node: MeshInstance3D
const MAX_TRAIL_POINTS := 200

func _build_visual() -> void:
	# Strand A core
	_mesh_instance = MeshInstance3D.new()
	var sphere_a := SphereMesh.new()
	sphere_a.radius = 0.03 * projectile_scale
	sphere_a.height = 0.06 * projectile_scale
	sphere_a.radial_segments = 8
	_mesh_instance.mesh = sphere_a
	_mesh_instance.material_override = _make_material(color_primary, emission_energy)
	add_child(_mesh_instance)

	# Strand B core
	_strand_b_node = MeshInstance3D.new()
	_strand_b_node.name = "StrandB"
	var sphere_b := SphereMesh.new()
	sphere_b.radius = 0.03 * projectile_scale
	sphere_b.height = 0.06 * projectile_scale
	sphere_b.radial_segments = 8
	_strand_b_node.mesh = sphere_b
	_strand_b_node.material_override = _make_material(color_secondary, emission_energy * 0.8)
	add_child(_strand_b_node)

	# Trail meshes (added to scene root so they persist)
	_trail_a_im = ImmediateMesh.new()
	_trail_a_mesh = MeshInstance3D.new()
	_trail_a_mesh.mesh = _trail_a_im
	var mat_a := StandardMaterial3D.new()
	mat_a.albedo_color = color_primary
	mat_a.emission_enabled = true
	mat_a.emission = color_primary
	mat_a.emission_energy_multiplier = emission_energy * 0.6
	mat_a.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_a_mesh.material_override = mat_a

	_trail_b_im = ImmediateMesh.new()
	_trail_b_mesh = MeshInstance3D.new()
	_trail_b_mesh.mesh = _trail_b_im
	var mat_b := StandardMaterial3D.new()
	mat_b.albedo_color = color_secondary
	mat_b.emission_enabled = true
	mat_b.emission = color_secondary
	mat_b.emission_energy_multiplier = emission_energy * 0.5
	mat_b.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_b_mesh.material_override = mat_b

	call_deferred("_add_trails_to_scene")

func _add_trails_to_scene() -> void:
	if not is_inside_tree():
		return
	var scene := get_tree().current_scene
	for trail in [_trail_a_mesh, _trail_b_mesh]:
		if trail:
			scene.add_child(trail)
			var timer := Timer.new()
			timer.wait_time = lifetime + 3.0
			timer.one_shot = true
			timer.timeout.connect(trail.queue_free)
			trail.add_child(timer)
			timer.start()

func _apply_initial_velocity() -> void:
	var forward := direction.normalized()
	if abs(forward.dot(Vector3.UP)) < 0.99:
		_local_right = forward.cross(Vector3.UP).normalized()
	else:
		_local_right = forward.cross(Vector3.RIGHT).normalized()
	_local_up = _local_right.cross(forward).normalized()
	linear_velocity = forward * speed

func _update_trajectory(_delta: float) -> void:
	if has_hit:
		return

	var t := time_alive * _wave_freq
	var offset_a := _local_right * sin(t) * _wave_amp + _local_up * cos(t) * _wave_amp
	var offset_b := _local_right * sin(t + PI) * _wave_amp + _local_up * cos(t + PI) * _wave_amp

	if _mesh_instance:
		_mesh_instance.position = offset_a
	if _strand_b_node:
		_strand_b_node.position = offset_b

	# Record world-space trail points
	var center := global_position
	_trail_a_points.append(center + offset_a)
	_trail_b_points.append(center + offset_b)
	if _trail_a_points.size() > MAX_TRAIL_POINTS:
		_trail_a_points = _trail_a_points.slice(_trail_a_points.size() - MAX_TRAIL_POINTS)
	if _trail_b_points.size() > MAX_TRAIL_POINTS:
		_trail_b_points = _trail_b_points.slice(_trail_b_points.size() - MAX_TRAIL_POINTS)

	# Rebuild trail lines
	if _trail_a_im and _trail_a_points.size() >= 2:
		_trail_a_im.clear_surfaces()
		_trail_a_im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for pt in _trail_a_points:
			_trail_a_im.surface_add_vertex(pt)
		_trail_a_im.surface_end()
	if _trail_b_im and _trail_b_points.size() >= 2:
		_trail_b_im.clear_surfaces()
		_trail_b_im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for pt in _trail_b_points:
			_trail_b_im.surface_add_vertex(pt)
		_trail_b_im.surface_end()

func _on_hit(body: Node3D) -> void:
	projectile_hit.emit(body, global_position)
	if body.has_method("hit_by_projectile"):
		body.hit_by_projectile(color_primary)
