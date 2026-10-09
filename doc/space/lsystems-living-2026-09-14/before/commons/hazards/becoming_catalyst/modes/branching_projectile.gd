# BranchingProjectile.gd
# verb: grow
# L-system seed that branches repeatedly as it flies forward.
# Each segment branches into 2-3 children at narrow angles — a growing tree.
# At terminal depth or on hit, grows a real DNA-based tree via TreeMorphology.
extends CatalystProjectile

const MAX_DEPTH := 4
const BRANCH_INTERVAL := 0.3
const BRANCH_ANGLE := 0.26  # ~15 degrees — tighter, more forward
const MIN_CHILDREN := 2
const MAX_CHILDREN := 3
const TREE_GROW_CHANCE := 0.6  # probability a terminal branch spawns a tree

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
	call_deferred("_add_trail_to_scene")

func _add_trail_to_scene() -> void:
	if _trail_mesh and is_inside_tree():
		get_tree().current_scene.add_child(_trail_mesh)
		_prev_pos = global_position
		var timer := Timer.new()
		timer.wait_time = lifetime + 2.0
		timer.one_shot = true
		timer.timeout.connect(_trail_mesh.queue_free)
		_trail_mesh.add_child(timer)
		timer.start()

func _update_trajectory(delta: float) -> void:
	if has_hit:
		return

	# Draw trail
	if _trail_im and _prev_pos != Vector3.ZERO:
		var current := global_position
		if current.distance_to(_prev_pos) > 0.02:
			_trail_points.append(_prev_pos)
			_trail_points.append(current)
			_prev_pos = current
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
	if body.has_method("hit_by_projectile"):
		body.hit_by_projectile(color_primary)
	if not _has_branched:
		_branch()
	# Grow a tree at impact point
	_try_grow_tree()

func _branch() -> void:
	_has_branched = true
	var depth: int = get_meta("branch_depth", 0)
	if depth >= MAX_DEPTH:
		return

	var forward := linear_velocity.normalized()
	if forward.length_squared() < 0.01:
		forward = direction.normalized()

	# Two perpendicular axes for 3D branching
	var perp: Vector3
	if abs(forward.dot(Vector3.UP)) < 0.99:
		perp = forward.cross(Vector3.UP).normalized()
	else:
		perp = forward.cross(Vector3.RIGHT).normalized()
	var perp2 := forward.cross(perp).normalized()

	var child_script: GDScript = load("res://commons/hazards/becoming_catalyst/modes/branching_projectile.gd")
	var scene_root := get_tree().current_scene
	var child_count := randi_range(MIN_CHILDREN, MAX_CHILDREN)

	for i in child_count:
		# Distribute children around the forward axis
		var spread_angle := TAU / child_count * i + randf_range(-0.2, 0.2)
		var branch_axis := (perp * cos(spread_angle) + perp2 * sin(spread_angle)).normalized()
		var child_dir := forward.rotated(branch_axis, BRANCH_ANGLE * randf_range(0.7, 1.3)).normalized()

		var child_depth := depth + 1
		var scale_factor := pow(0.75, child_depth)

		var child := CatalystProjectile.new()
		child.speed = speed * 0.9
		child.lifetime = lifetime - time_alive
		child.projectile_scale = scale_factor
		child.color_primary = color_primary.lerp(Color(0.2, 0.9, 0.3), child_depth * 0.15)
		child.color_secondary = color_secondary
		child.emission_energy = emission_energy
		child.direction = child_dir
		child.set_meta("branch_depth", child_depth)
		child.set_script(child_script)

		scene_root.add_child(child)
		child.global_position = global_position

# ── Tree growth at terminal branches / impact ─────────────────────

func _try_grow_tree() -> void:
	var depth: int = get_meta("branch_depth", 0)
	# Only terminal-depth branches or direct hits grow trees
	if depth < MAX_DEPTH - 1 and not has_hit:
		return
	if randf() > TREE_GROW_CHANCE:
		return

	# Use sculptor DNA if available, otherwise random tree
	var dna: CritterDNA
	if Engine.has_meta("sculptor_tree_dna"):
		dna = (Engine.get_meta("sculptor_tree_dna") as CritterDNA).duplicate()
		# Mutate slightly per depth — each planted tree is a variant
		CritterDNA.mutate(dna, 0.15, 0.2)
	else:
		dna = CritterDNA.random_kingdom(0, randi())
		dna.segments = clampf(dna.segments, 3.0, 6.0)
		dna.scale = 0.4 + randf() * 0.3

	# Scale down so the planted tree fits the projectile context
	dna.scale *= projectile_scale * 1.5

	var mapper := CritterTraitMapper.new()
	var tree_root := Node3D.new()
	tree_root.name = "CatalystTree"
	get_tree().current_scene.add_child(tree_root)
	tree_root.global_position = global_position

	TreeMorphology.build(dna, tree_root, mapper, 1)  # LOD 1 for performance

	# Animate: scale up from zero
	tree_root.scale = Vector3.ZERO
	var tween := tree_root.create_tween()
	tween.tween_property(tree_root, "scale", Vector3.ONE, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Auto-remove after 30 seconds to prevent clutter
	var cleanup_timer := Timer.new()
	cleanup_timer.wait_time = 30.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func():
		var fade := tree_root.create_tween()
		fade.tween_property(tree_root, "scale", Vector3.ZERO, 0.5)
		fade.tween_callback(tree_root.queue_free)
	)
	tree_root.add_child(cleanup_timer)
	cleanup_timer.start()
