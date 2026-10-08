extends "res://commons/artifacts/cube_sorting_line/cube_sorter_stage.gd"
## Fold -> drop -> print -> sort. Unsorted stock is conserved, including when
## settled physics becomes a collidable, reclaimable pile for headset budgets.
const CUBE = preload("res://commons/artifacts/cube_sorting_line/sorting_cube.gd")
const SKINS = preload("res://commons/artifacts/cube_sorting_line/carton_skins.gd")
const BACKLOG = preload("res://commons/artifacts/cube_sorting_line/cube_sorter_backlog.gd")

@export var auto_start := true
@export_range(1.0, 20.0) var spawn_interval := 4.8
@export var belt_speed := 0.55
@export var active_limit := 64
@export var backlog_bounds := Rect2(-6.5, -1.5, 12.0, 17.0)
@export var backlog_height := 3.0
var cube_size := 0.32
var backlog_exclusions: Array[Rect2] = [
	Rect2(-3.15, -0.65, 5.85, 1.35), # moving line
	Rect2(0.0, -1.24, 2.10, 0.95), # baskets behind the belt
	Rect2(0.0, 0.65, 3.35, 1.30), # clear operator side and console
	Rect2(-5.5, 7.5, 1.0, 1.0), Rect2(4.5, 7.5, 1.0, 1.0), # hall pillars
]
var kind_materials: Array[Material] = []
var pile_meshes: Array[Mesh] = []
var raw_material: Material
var active: Array[RigidBody3D] = []
var sorting_bodies: Array[RigidBody3D] = []
var sorted_counts: Array[int] = [0, 0]
var mini_transforms: Array[Array] = [[], []]
var sorted_displays: Array[MultiMeshInstance3D] = []
var backlog: Node3D
var produced := 0
var running := false
var room_full := false
var _clock := 0.0
var _released := false
var _scan_clock := 0.0
var _notice := ""
var _notice_time := 0.0
var _quiet: Dictionary = {}
var _tweens: Array[Tween] = []
var _generation := 0
var _configured := false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	for kind in 2:
		kind_materials.append(SKINS.make_material(kind))
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE
		mesh.material = kind_materials[kind]
		pile_meshes.append(mesh)
	raw_material = stage_material(Color("ddcbb0"))
	build_stage()
	for kind in 2:
		var display := MultiMeshInstance3D.new()
		display.name = "Sorted" + str(kind)
		display.multimesh = MultiMesh.new()
		display.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		display.multimesh.mesh = pile_meshes[kind]
		add_child(display)
		sorted_displays.append(display)
	backlog = BACKLOG.new()
	backlog.name = "UnsortedStock"
	add_child(backlog)
	running = auto_start
	_update_readout()
	_configure_backlog.call_deferred(_generation)

func _configure_backlog(generation: int) -> void:
	# Museum placement happens after add_child; also allow retired reset
	# colliders to leave physics before testing which floor columns are free.
	await get_tree().physics_frame
	await get_tree().physics_frame
	if generation != _generation: return
	backlog.configure(self, backlog_bounds, 0.4, backlog_height)
	_configured = true

func make_cube(kind: int = -1) -> RigidBody3D:
	var body := CUBE.new()
	body.name = "SortingCube"
	body.kind = kind
	body.printed = kind >= 0
	body.collision_layer = 6
	body.collision_mask = 7
	body.release_mode = 0 # always dynamic after a hand releases a pile cube
	body.ranged_grab_method = 2
	body.mass = 0.4
	body.continuous_cd = true
	body.linear_damp = 0.15
	body.angular_damp = 0.7
	var friction := PhysicsMaterial.new()
	friction.friction = 0.8
	friction.bounce = 0.03
	body.physics_material_override = friction
	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	visual.mesh = mesh
	visual.material_override = kind_materials[kind] if kind >= 0 else raw_material
	body.add_child(visual)
	body.visual = visual
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = BoxShape3D.new()
	body.add_child(collision)
	body.shape_node = collision
	body.resize_to(cube_size)
	return body

func spawn_cube() -> RigidBody3D:
	if not _configured or room_full or active.size() >= active_limit: return null
	var body := make_cube(-1)
	add_child(body)
	body.position = net.position - Vector3.UP * 0.42 * 0.5
	active.append(body)
	produced += 1
	return body

func stamp_cube(body: RigidBody3D, kind: int = -1) -> void:
	if not is_instance_valid(body) or body.printed or body.is_held(): return
	var edition := _rng.randi_range(0, 1) if kind < 0 else clampi(kind, 0, 1)
	body.kind = edition
	body.printed = true
	body.visual.material_override = kind_materials[edition]
	stamp_visual.material_override = kind_materials[edition]
	stamp_visual.position.y = 1.48

func _physics_process(delta: float) -> void:
	if not is_instance_valid(belt) or not _configured: return
	room_full = backlog.is_full()
	if room_full: running = false
	belt.constant_linear_velocity = global_basis.x.normalized() * belt_speed if running else Vector3.ZERO
	if running:
		_update_feeder(delta)
		for tread in belt_marks:
			tread.position.x = wrapf(tread.position.x + belt_speed * delta, -2.6, 2.6)
	stamp_visual.position.y = move_toward(stamp_visual.position.y, 1.59, delta * 0.6)
	_notice_time = maxf(0.0, _notice_time - delta)
	_scan_clock += delta
	if _scan_clock < 0.1: return
	var elapsed := _scan_clock
	_scan_clock = 0.0
	for body in active.duplicate():
		if not is_instance_valid(body): continue
		var local := to_local(body.global_position)
		if body.is_held():
			_quiet.erase(body.get_instance_id())
			continue
		if not body.printed and absf(local.z) < 0.48 and local.x > -1.15 and local.x < -0.45 and local.y > 0.95 and local.y < 1.48:
			stamp_cube(body)
		var consumed := false
		for index in baskets.size():
			# Center containment stops grazing the outside of a basket counting.
			var p := baskets[index].to_local(body.global_position)
			if absf(p.x) < 0.35 and absf(p.z) < 0.35 and absf(p.y) < 0.20:
				consumed = try_sort(body, index)
				if consumed: break
		if consumed: continue
		var id: int = body.get_instance_id()
		var on_floor_stock := backlog_bounds.has_point(Vector2(local.x, local.z)) and local.y < backlog_height + cube_size * 2.0
		for exclusion in backlog_exclusions:
			if exclusion.has_point(Vector2(local.x, local.z)): on_floor_stock = false
		if body.printed and on_floor_stock and body.linear_velocity.length_squared() < 0.04 and body.angular_velocity.length_squared() < 0.1:
			_quiet[id] = float(_quiet.get(id, 0.0)) + elapsed
			if float(_quiet[id]) > 2.0: archive_cube(body)
		else:
			_quiet.erase(id)
		# A dropped delivery outside the hall is returned to the inlet, never
		# deleted from the ledger. A held object is never moved by this rule.
		if is_instance_valid(body) and active.has(body) and local.y < -4.0:
			body.global_position = to_global(Vector3(net.position.x, 1.6, 0))
			body.linear_velocity = Vector3.ZERO
			body.angular_velocity = Vector3.ZERO
	_update_readout()

func _update_feeder(delta: float) -> void:
	var interval := maxf(1.0, spawn_interval)
	_clock += delta
	var phase := _clock / interval
	net.set("fold_progress", clampf((phase - 0.10) / 0.33, 0.0, 1.0))
	var net_root: Node3D = net.get("_cube_root")
	if is_instance_valid(net_root):
		var shrink := lerpf(1.0, cube_size / 0.42, clampf((phase - 0.43) / 0.10, 0.0, 1.0))
		net_root.scale = Vector3.ONE * shrink
		net_root.position.y = -0.42 * 0.5 * (1.0 - shrink)
	if phase >= 0.55 and not _released:
		if active.size() >= active_limit:
			_clock = interval * 0.55
			return
		spawn_cube()
		_released = true
	net.visible = not _released
	if phase >= 1.0:
		_clock = 0.0
		_released = false
		net.visible = true

func try_sort(body: RigidBody3D, basket_index: int) -> bool:
	if basket_index < 0 or basket_index >= 2 or not is_instance_valid(body): return false
	if not active.has(body) or body.sorting or body.is_held(): return false
	if not body.printed:
		_notice = "PRINT IT ON THE BELT FIRST"
		_notice_time = 1.0
		return false
	if body.kind != basket_index:
		_notice = "TRY THE OTHER BASKET"
		_notice_time = 1.0
		return false
	active.erase(body)
	_quiet.erase(body.get_instance_id())
	sorting_bodies.append(body)
	body.sorting = true
	body.enabled = false
	body.freeze = true
	body.collision_layer = 0
	body.collision_mask = 0
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO
	var pending := 0
	for other in sorting_bodies:
		if other != body and other.kind == basket_index: pending += 1
	var destination := _mini_position(basket_index, sorted_counts[basket_index] + pending)
	var initial := body.global_position
	var orientation := body.quaternion
	var generation := _generation
	var tween := create_tween()
	_tweens.append(tween)
	tween.tween_method(func(t: float) -> void:
		if not is_instance_valid(body): return
		body.global_position = initial.lerp(to_global(destination), t)
		body.quaternion = orientation.slerp(Quaternion.IDENTITY, t)
		body.resize_to(lerpf(cube_size, 0.065, t))
	, 0.0, 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		_tweens.erase(tween)
		if generation != _generation or not is_instance_valid(body): return
		sorting_bodies.erase(body)
		mini_transforms[basket_index].append(Transform3D(Basis.from_scale(Vector3.ONE * 0.065), destination))
		sorted_counts[basket_index] += 1
		_rebuild_minis(basket_index)
		body.queue_free()
		_update_readout()
	)
	return true

func _mini_position(kind: int, index: int) -> Vector3:
	return baskets[kind].position + Vector3(-0.28 + (index % 9) * 0.07,
		-0.235 + floori(index / 81.0) * 0.07, -0.28 + (floori(index / 9.0) % 9) * 0.07)

func _rebuild_minis(kind: int) -> void:
	var batch := sorted_displays[kind].multimesh
	batch.instance_count = mini_transforms[kind].size()
	for i in mini_transforms[kind].size(): batch.set_instance_transform(i, mini_transforms[kind][i])

func archive_cube(body: RigidBody3D) -> bool:
	if not is_instance_valid(body) or not active.has(body) or body.is_held() or body.sorting or not body.printed: return false
	var settled_pose := global_transform.affine_inverse() * body.global_transform
	if not backlog.offer(body.kind, settled_pose): return false
	active.erase(body)
	_quiet.erase(body.get_instance_id())
	body.queue_free()
	return true

func accept_reclaimed(body: RigidBody3D) -> void:
	if not active.has(body): active.append(body)
	_quiet.erase(body.get_instance_id())

func act(id: String) -> void:
	if id == "RESET": reset_game()
	elif id == "PAUSE" and not room_full:
		running = not running
	_update_readout()

func reset_game() -> void:
	var resume_after_reset := running or (room_full and auto_start)
	_generation += 1
	for tween in _tweens:
		if tween.is_valid(): tween.kill()
	_tweens.clear()
	for body in active + sorting_bodies:
		if not is_instance_valid(body): continue
		body.release_for_reset()
		body.queue_free()
	active.clear()
	sorting_bodies.clear()
	_quiet.clear()
	_configured = false
	backlog.clear()
	_configure_backlog.call_deferred(_generation)
	produced = 0
	sorted_counts = [0, 0]
	mini_transforms = [[], []]
	for kind in 2: _rebuild_minis(kind)
	room_full = false
	running = resume_after_reset
	_clock = 0.0
	_released = false
	_notice_time = 0.0
	net.visible = true
	net.set("fold_progress", 0.0)
	var net_root: Node3D = net.get("_cube_root")
	if is_instance_valid(net_root):
		net_root.scale = Vector3.ONE
		net_root.position = Vector3.ZERO
	_update_readout()

func get_state() -> Dictionary:
	return {"produced": produced, "active": active.size(), "stored": backlog.count(),
		"sorting": sorting_bodies.size(), "sorted": sorted_counts[0] + sorted_counts[1],
		"room_full": room_full, "running": running}

func _update_readout() -> void:
	if not is_instance_valid(readout): return
	var heading := "ROOM FULL / RESET TO REOPEN" if room_full else ("FOLD / PRINT / SORT" if running else "PAUSED / PRESS TO RESUME")
	if _notice_time > 0.0: heading = _notice
	readout.text = "%s\nAGAIN %d    YET %d\nUNSORTED %d\nGrab. Match. Let go." % [heading, sorted_counts[0], sorted_counts[1], active.size() + backlog.count()]
