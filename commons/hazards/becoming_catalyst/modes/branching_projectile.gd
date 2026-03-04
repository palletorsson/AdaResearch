# BranchingProjectile.gd
# L-system seed that branches at intervals.
# Spawns 2 children at ±25° with ImmediateMesh trail connections.
extends CatalystProjectile

const MAX_DEPTH := 3
const BRANCH_INTERVAL := 0.4
const BRANCH_ANGLE := 0.44  # ~25 degrees
const CHILD_COUNT := 2

var _branch_timer: float = 0.0
var _has_branched: bool = false
var _trail_mesh: MeshInstance3D = null
var _trail_im: ImmediateMesh = null
var _prev_pos: Vector3 = Vector3.ZERO
var _trail_points: PackedVector3Array = PackedVector3Array()

func _build_visual() -> void:
	_mesh_instance = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.05 * projectile_scale
	sphere.height = 0.1 * projectile_scale
	_mesh_instance.mesh = sphere
	_mesh_instance.material_override = _make_material(color_primary, emission_energy)
	add_child(_mesh_instance)

	# Trail renderer
	_trail_im = ImmediateMesh.new()
	_trail_mesh = MeshInstance3D.new()
	_trail_mesh.mesh = _trail_im
	var trail_mat := StandardMaterial3D.new()
	trail_mat.albedo_color = color_secondary
	trail_mat.emission_enabled = true
	trail_mat.emission = color_primary
	trail_mat.emission_energy_multiplier = 0.8
	trail_mat.vertex_color_use_as_albedo = true
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_mesh.material_override = trail_mat
	# Add trail to scene root so it persists after projectile dies
	call_deferred("_add_trail_to_scene")

func _add_trail_to_scene() -> void:
	if _trail_mesh and is_inside_tree():
		get_tree().current_scene.add_child(_trail_mesh)
		_prev_pos = global_position
		# Trail auto-cleanup
		var timer := Timer.new()
		timer.wait_time = lifetime + 2.0
		timer.one_shot = true
		timer.timeout.connect(_trail_mesh.queue_free)
		_trail_mesh.add_child(timer)
		timer.start()

func _update_trajectory(delta: float) -> void:
	if has_hit:
		return

	# Draw trail — rebuild single surface from accumulated points
	if _trail_im and _prev_pos != Vector3.ZERO:
		var current := global_position
		if current.distance_to(_prev_pos) > 0.02:
			_trail_points.append(_prev_pos)
			_trail_points.append(current)
			_prev_pos = current
			# Rebuild single surface with all segments
			_trail_im.clear_surfaces()
			if _trail_points.size() >= 2:
				_trail_im.surface_begin(Mesh.PRIMITIVE_LINES)
				_trail_im.surface_set_color(color_primary)
				for pt in _trail_points:
					_trail_im.surface_add_vertex(pt)
				_trail_im.surface_end()

	# Branch timer
	_branch_timer += delta
	if _branch_timer >= BRANCH_INTERVAL and not _has_branched:
		_branch()

func _on_hit(body: Node3D) -> void:
	projectile_hit.emit(body, global_position)
	if not _has_branched:
		_branch()

func _branch() -> void:
	_has_branched = true
	var depth: int = get_meta("branch_depth", 0)
	if depth >= MAX_DEPTH:
		return

	var forward := linear_velocity.normalized()
	if forward.length_squared() < 0.01:
		forward = direction.normalized()

	var perp: Vector3
	if abs(forward.dot(Vector3.UP)) < 0.99:
		perp = forward.cross(Vector3.UP).normalized()
	else:
		perp = forward.cross(Vector3.RIGHT).normalized()

	# Inline child creation to avoid circular preload
	var child_script: GDScript = load("res://commons/hazards/becoming_catalyst/modes/branching_projectile.gd")
	var scene_root := get_tree().current_scene
	for i in CHILD_COUNT:
		var angle_sign := 1.0 if i == 0 else -1.0
		var child_dir := forward.rotated(perp, BRANCH_ANGLE * angle_sign).normalized()

		var child_depth := depth + 1
		var scale_factor := pow(0.7, child_depth)

		var child := CatalystProjectile.new()
		child.speed = 10.0
		child.lifetime = 3.5
		child.projectile_scale = scale_factor
		child.color_primary = Color(0.4, 0.75, 0.3)
		child.color_secondary = Color(0.25, 0.5, 0.15)
		child.emission_energy = 1.2
		child.direction = child_dir
		child.set_meta("branch_depth", child_depth)
		child.set_script(child_script)

		scene_root.add_child(child)
		child.global_position = global_position
