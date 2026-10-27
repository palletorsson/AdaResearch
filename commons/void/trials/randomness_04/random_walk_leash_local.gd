extends "res://algorithms/randomness/random_walk_leash/random_walk_leash.gd"
## Void placement adapter: keep the source's walk, history and controls, while
## resolving the orb and tether in the artifact's editor transform.

func _enforce_leash() -> void:
	var offset := to_local(_orb_body.global_position) - _orb_spawn_pos
	var distance := offset.length()
	if distance > leash_length:
		var toward := (to_global(_orb_spawn_pos) - _orb_body.global_position).normalized()
		_orb_body.apply_force(toward * (distance - leash_length) * 2.0)

func _update_leash_visual() -> void:
	if not _orb_body or not _leash_line: return
	var end := to_local(_orb_body.global_position)
	if end.distance_to(_orb_spawn_pos) < .001: return
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(_orb_spawn_pos)
	mesh.surface_add_vertex(end)
	mesh.surface_end()
	_leash_line.mesh = mesh
	_leash_line.material_override = _leash_material

func _update_trail() -> void:
	if not _orb_body or not _trail_mesh: return
	_trail_points.append(to_local(_orb_body.global_position))
	while _trail_points.size() > _trail_cap(): _trail_points.pop_front()
	if _trail_points.size() < 2: return
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for point in _trail_points: mesh.surface_add_vertex(point)
	mesh.surface_end()
	_trail_mesh.mesh = mesh
	_trail_mesh.material_override = _trail_material

func _reset() -> void:
	var mode: int = _orb_body.freeze_mode if is_instance_valid(_orb_body) else 0
	if is_instance_valid(_orb_body): _orb_body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	super._reset()
	if is_instance_valid(_orb_body):
		_orb_body.global_position = to_global(_orb_spawn_pos)
		_orb_body.set_deferred("freeze_mode", mode)
