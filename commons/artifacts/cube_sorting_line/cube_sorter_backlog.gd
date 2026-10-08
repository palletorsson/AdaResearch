extends Node3D
## Retain exactly where and how each missed delivery settles. Batching must
## never arrange or sort the pile.
const PROXY_INTERVAL := 0.3
const PROXY_REACH := 1.7
const MAX_PROXIES := 12

var bounds := Rect2()
var pitch := 0.4
var height_limit := 3.0
var cube_size := 0.32
var max_layers := 0
var capacity := 0
var _game: Node3D
var _entries: Dictionary = {}
var _pending_wake: Dictionary = {}
var _next_id := 0
var _batches: Array[MultiMeshInstance3D] = []
var _collision_body: StaticBody3D
var _box_shape: BoxShape3D
var _proxy_clock := 0.0
var _generation := 0
var _rebuild_pending := false
var _configured := false
var _player_body: Node3D
var _exclusions: Array[Rect2] = []
var _blocked_columns := 0
var _footprint_cells := 0


func configure(game: Node3D, floor_bounds: Rect2, column_pitch: float = 0.4, ceiling: float = 3.0) -> void:
	clear()
	_game = game
	bounds = floor_bounds.abs()
	cube_size = maxf(0.05, float(game.get("cube_size")))
	pitch = maxf(column_pitch, cube_size)
	height_limit = maxf(cube_size, ceiling)
	max_layers = maxi(1, int(floor(height_limit / cube_size)))
	var exclusions: Variant = game.get("backlog_exclusions")
	if exclusions is Array:
		for rectangle in exclusions:
			if rectangle is Rect2: _exclusions.append(rectangle.abs())
	# Sample empty floor volume ONLY to bound capacity. These cells are never
	# destinations: the real physics result determines every stored transform.
	var column_shape := BoxShape3D.new()
	column_shape.size = Vector3(cube_size, maxf(0.02, height_limit - 0.12), cube_size)
	var width := maxi(0, int(floor((bounds.size.x - cube_size) / pitch)) + 1)
	var depth := maxi(0, int(floor((bounds.size.y - cube_size) / pitch)) + 1)
	if bounds.size.x < cube_size: width = 0
	if bounds.size.y < cube_size: depth = 0
	for z in depth:
		for x in width:
			var at := Vector3(bounds.position.x + cube_size * 0.5 + x * pitch, 0.0,
				bounds.position.y + cube_size * 0.5 + z * pitch)
			if _column_blocked(at, column_shape): _blocked_columns += 1
			else: _footprint_cells += 1
	capacity = _footprint_cells * max_layers
	_collision_body = StaticBody3D.new()
	_collision_body.name = "SettledPileCollision"
	_collision_body.collision_layer = 1
	_collision_body.collision_mask = 0
	add_child(_collision_body)
	_box_shape = BoxShape3D.new()
	_box_shape.size = Vector3.ONE * cube_size
	var meshes: Variant = game.get("pile_meshes")
	var materials: Variant = game.get("kind_materials")
	for kind in 2:
		var mesh: Mesh
		if meshes is Array and meshes.size() > kind and meshes[kind] is Mesh:
			mesh = meshes[kind]
		else:
			var box := BoxMesh.new()
			box.size = Vector3.ONE
			if materials is Array and materials.size() > kind and materials[kind] is Material:
				box.material = materials[kind]
			mesh = box
		var batch := MultiMeshInstance3D.new()
		batch.name = "RetainedKind%d" % kind
		batch.multimesh = MultiMesh.new()
		batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		batch.multimesh.mesh = mesh
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(batch)
		_batches.append(batch)
	_configured = true
	_queue_rebuild()


func _column_blocked(at: Vector3, shape: BoxShape3D) -> bool:
	for rectangle in _exclusions:
		if rectangle.has_point(Vector2(at.x, at.z)): return true
	if not is_inside_tree() or get_world_3d() == null: return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	query.collide_with_areas = false
	query.transform = global_transform * Transform3D(Basis.IDENTITY, at + Vector3.UP * height_limit * 0.5)
	return not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


## pose is the settled cube's transform in game coordinates; we stay at identity.
func offer(kind: int, pose: Transform3D) -> bool:
	if not _configured or is_full(): return false
	if not bounds.has_point(Vector2(pose.origin.x, pose.origin.z)): return false
	for rectangle in _exclusions:
		if rectangle.has_point(Vector2(pose.origin.x, pose.origin.z)): return false
	var owner_id := _collision_body.create_shape_owner(self)
	_collision_body.shape_owner_add_shape(owner_id, _box_shape)
	_collision_body.shape_owner_set_transform(owner_id, pose)
	_entries[_next_id] = {"kind": clampi(kind, 0, 1), "pose": pose,
		"proxy": null, "owner": owner_id}
	_next_id += 1
	_queue_rebuild()
	return true


func count() -> int:
	return _entries.size()


func is_full() -> bool:
	return _configured and count() >= capacity


func get_state() -> Dictionary:
	var proxies := 0
	var highest := 0.0
	for entry: Dictionary in _entries.values():
		if is_instance_valid(entry.proxy): proxies += 1
		var pose: Transform3D = entry.pose
		var half_y := (absf(pose.basis.x.y) + absf(pose.basis.y.y) + absf(pose.basis.z.y)) * cube_size * 0.5
		highest = maxf(highest, pose.origin.y + half_y)
	return {"count": count(), "capacity": capacity, "footprint_cells": _footprint_cells,
		"proxies": proxies, "pitch": pitch, "cube_size": cube_size,
		"height_limit": height_limit, "max_layers": max_layers, "bounds": bounds,
		"blocked_columns": _blocked_columns, "max_stack_height": highest, "full": is_full()}


func clear() -> void:
	_configured = false
	_generation += 1
	_rebuild_pending = false
	for entry: Dictionary in _entries.values():
		if is_instance_valid(entry.proxy):
			remove_child(entry.proxy)
			entry.proxy.queue_free()
	_entries.clear()
	_pending_wake.clear()
	if is_instance_valid(_collision_body):
		remove_child(_collision_body)
		_collision_body.queue_free()
	_collision_body = null
	for batch in _batches:
		if is_instance_valid(batch):
			remove_child(batch)
			batch.queue_free()
	_batches.clear()
	capacity = 0
	_proxy_clock = 0.0
	_player_body = null
	_exclusions.clear()
	_blocked_columns = 0
	_footprint_cells = 0


func _physics_process(delta: float) -> void:
	if not _configured: return
	_proxy_clock += delta
	if _proxy_clock < PROXY_INTERVAL: return
	_proxy_clock = 0.0
	_drain_wake()
	_update_proxies()


func _operator_position() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if is_instance_valid(camera): return to_local(camera.global_position)
	if not is_instance_valid(_player_body):
		for node in get_tree().root.find_children("*", "CharacterBody3D", true, false):
			if node.has_method("is_xr_class") and bool(node.call("is_xr_class", "XRToolsPlayerBody")):
				_player_body = node
				break
	if is_instance_valid(_player_body):
		return to_local(_player_body.global_position + Vector3.UP * 1.3)
	return Vector3(1.8, 1.6, 2.1)


func _update_proxies() -> void:
	var operator := _operator_position()
	var candidates: Array[Dictionary] = []
	for id: int in _entries.keys():
		if not _entries.has(id): continue
		var entry: Dictionary = _entries[id]
		if _proxy_held(entry.proxy):
			_on_proxy_grabbed(id, entry.proxy, _generation)
			continue
		var pose: Transform3D = entry.pose
		var distance := pose.origin.distance_squared_to(operator)
		if distance <= PROXY_REACH * PROXY_REACH:
			candidates.append({"id": id, "distance": distance})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distance < b.distance)
	var wanted: Dictionary = {}
	for candidate in candidates:
		if wanted.size() >= MAX_PROXIES: break
		var id := int(candidate.id)
		if _accessible(id, operator): wanted[id] = true
	for id: int in _entries.keys():
		if _entries.has(id) and is_instance_valid(_entries[id].proxy) and not wanted.has(id): _unexpose(id)
	for id: int in wanted:
		if _entries.has(id) and not is_instance_valid(_entries[id].proxy): _expose(id)


func _accessible(id: int, operator: Vector3) -> bool:
	if not _entries.has(id): return false
	var entry: Dictionary = _entries[id]
	var pose: Transform3D = entry.pose
	var query := PhysicsRayQueryParameters3D.create(to_global(operator), to_global(pose.origin), 7)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return false
	if hit.collider == entry.proxy: return true
	return hit.collider == _collision_body and _collision_body.shape_find_owner(int(hit.shape)) == int(entry.owner)


func _expose(id: int) -> void:
	var entry: Dictionary = _entries[id]
	var proxy: RigidBody3D = _game.call("make_cube", int(entry.kind))
	if not is_instance_valid(proxy): return
	proxy.name = "BacklogTop_%d" % id
	proxy.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	proxy.freeze = true
	proxy.set("release_mode", 0) # XRToolsPickable.ReleaseMode.UNFROZEN
	entry.proxy = proxy
	_collision_body.shape_owner_set_disabled(int(entry.owner), true)
	add_child(proxy)
	proxy.transform = entry.pose
	for signal_name in ["picked_up", "grabbed_by_player"]:
		if not proxy.has_signal(signal_name): continue
		var argument_count := 0
		for definition in proxy.get_signal_list():
			if str(definition.name) == signal_name:
				argument_count = definition.args.size()
				break
		var callback := _on_proxy_grabbed.bind(id, proxy, _generation)
		if argument_count > 0: callback = callback.unbind(argument_count)
		proxy.connect(signal_name, callback)
	_queue_rebuild()


func _unexpose(id: int) -> void:
	var entry: Dictionary = _entries[id]
	var proxy: Variant = entry.proxy
	if _proxy_held(proxy):
		_on_proxy_grabbed(id, proxy, _generation)
		return
	entry.proxy = null
	_collision_body.shape_owner_set_disabled(int(entry.owner), false)
	if is_instance_valid(proxy):
		remove_child(proxy)
		proxy.queue_free()
	_queue_rebuild()


func _proxy_held(proxy: Variant) -> bool:
	if not is_instance_valid(proxy): return false
	if proxy.has_method("is_held") and bool(proxy.call("is_held")): return true
	if proxy.has_method("is_picked_up") and bool(proxy.call("is_picked_up")): return true
	return proxy.collision_layer == 0 and proxy.collision_mask == 0


func _on_proxy_grabbed(id: int, proxy: RigidBody3D, generation: int) -> void:
	if not _configured or generation != _generation or not _entries.has(id): return
	if not is_instance_valid(proxy) or _entries[id].proxy != proxy: return
	var removed: Transform3D = _entries[id].pose
	_reclaim(id, proxy)
	# Taking a support should let nearby boxes above it fall again. Remember
	# all affected boxes even if the moving-body budget is currently full.
	for other_id: int in _entries.keys():
		var pose: Transform3D = _entries[other_id].pose
		var offset := pose.origin - removed.origin
		if offset.y < cube_size * 0.4 or Vector2(offset.x, offset.z).length() > cube_size * 1.45: continue
		_pending_wake[other_id] = true
	_drain_wake()


func _drain_wake() -> void:
	for other_id: int in _pending_wake.keys():
		if not _entries.has(other_id):
			_pending_wake.erase(other_id)
			continue
		if _game.get("active").size() >= int(_game.get("active_limit")): break
		var pose: Transform3D = _entries[other_id].pose
		var other: RigidBody3D = _entries[other_id].proxy
		if not is_instance_valid(other):
			other = _game.call("make_cube", int(_entries[other_id].kind))
			add_child(other)
			other.transform = pose
		_reclaim(other_id, other)
		other.freeze = false
		other.sleeping = false


func _reclaim(id: int, proxy: RigidBody3D) -> void:
	_collision_body.remove_shape_owner(int(_entries[id].owner))
	_entries.erase(id)
	_pending_wake.erase(id)
	proxy.reparent(_game, true)
	_game.call("accept_reclaimed", proxy)
	_queue_rebuild()


func _queue_rebuild() -> void:
	if _rebuild_pending: return
	_rebuild_pending = true
	_rebuild.call_deferred(_generation)


func _rebuild(generation: int) -> void:
	if generation != _generation or not _configured: return
	_rebuild_pending = false
	var transforms: Array[Array] = [[], []]
	var mesh_scale := Transform3D(Basis.from_scale(Vector3.ONE * cube_size), Vector3.ZERO)
	for entry: Dictionary in _entries.values():
		if is_instance_valid(entry.proxy): continue
		transforms[int(entry.kind)].append(entry.pose * mesh_scale)
	for kind in 2:
		var multimesh := _batches[kind].multimesh
		multimesh.instance_count = transforms[kind].size()
		for index in transforms[kind].size():
			multimesh.set_instance_transform(index, transforms[kind][index])

