extends Node3D
## Opt-in Quest experiment: one resident hall, with a persistent loading cell.
## The cell belongs to this coordinator, never to an unloadable segment.
## Packed resources load on workers; scene construction still runs on the main
## thread. In particular, an individual artifact's _ready cannot be time-sliced.

var museum: Node3D
var busy := false
var phase := "idle"
var failure := ""
var events: Array[Dictionary] = []
var _cell: Node3D
var _status: Label3D
var _back_button: Node3D
var _current: Dictionary = {}
var _source: Dictionary = {}
var _direction := 1
var _portals: Array[Dictionary] = []
var _armed := false
var _dwell := 0.0
var _states: Dictionary = {}
var _providers: Array[Dictionary] = []
var _resources: Array[Resource] = []
var _destination: Dictionary = {}
var _return_point := Vector3.ZERO
var _arrival := Vector3.ZERO
var _cell_floor := Vector3(-1000.0, 0.05, 0.0)
const TIMEOUT_MS := 60000

func configure(owner_museum: Node3D) -> void:
	museum = owner_museum
	name = "PortalLoading"
	_make_cell()
	adopt_current.call_deferred()

func adopt_current() -> void:
	await get_tree().physics_frame
	await get_tree().process_frame
	var segments: Array = museum.get("_segments")
	if segments.size() != 1:
		push_error("[em-portals] pilot must start with exactly one hall")
		return
	_current = segments[0]
	museum.set("_vr_current_node", _current.node)
	install_portals()

func _process(delta: float) -> void:
	if museum == null or not is_instance_valid(museum):
		return
	if busy:
		if phase == "error":
			for hand: Node in get_tree().get_nodes_in_group("xr_controllers"):
				if hand is Node3D and hand.global_position.distance_to(_back_button.global_position) < 0.22:
					return_to_source()
		return
	if _portals.is_empty():
		return
	var eye: Vector3 = museum.call("_eye_pos")
	var near_any := false
	for portal: Dictionary in _portals:
		var p: Vector3 = portal.position
		var near := absf(eye.x - p.x) < 0.85 and absf(eye.z - p.z) < 0.55 and absf(eye.y - p.y - 1.4) < 1.3
		near_any = near_any or Vector2(eye.x-p.x, eye.z-p.z).length() < 1.8
		if near and _armed:
			_dwell += delta
			if _dwell >= 0.3:
				request_crossing(int(portal.direction))
			return
	_dwell = 0.0
	if not near_any:
		_armed = true

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B and phase == "error":
		return_to_source()

func request_crossing(direction: int) -> bool:
	if busy or _current.is_empty() or direction not in [-1, 1]:
		return false
	var boundary: float = _current.z1 if direction > 0 else _current.z0
	var freed_i: int = museum.call("_freed_index_for_boundary", boundary, direction)
	if direction < 0 and freed_i < 0:
		return false
	_source = _current.duplicate(true)
	_source.erase("node")
	_destination = {}
	if freed_i >= 0:
		_destination = (museum.get("_freed") as Array)[freed_i].duplicate(true)
	_direction = direction
	_return_point = _nearest_floor(museum.call("_eye_pos"))
	if _return_point.y < -1.0e8:
		return false
	_save_state(_current.node)
	busy = true
	_armed = false
	failure = ""
	_set_phase("entering", "A moment between halls")
	_cross.call_deferred()
	return true

func _cross() -> void:
	_lock_movement()
	var eye: Node3D = museum.call("_vr_eye")
	var forward: Vector3 = -eye.global_basis.z
	forward.y = 0
	if forward.length_squared() > 0.01:
		_cell.look_at(_cell.global_position + forward, Vector3.UP)
	# Give the cell its own registered physics support BEFORE moving the rig.
	await get_tree().physics_frame
	await get_tree().process_frame
	if not _supported(_cell_floor):
		busy = false
		_restore_movement()
		_set_phase("idle", "")
		push_error("[em-portals] loading floor unavailable; old hall retained")
		return
	_move_player(_cell_floor)
	await get_tree().process_frame
	await get_tree().process_frame
	await _unload()
	await _build_destination(_destination)

func _unload() -> void:
	_set_phase("unloading", "Leaving this hall")
	_portals.clear()
	museum.set("_vr_current_node", null)
	museum.set("_gate", {})
	museum.set("_gate_t", -1.0)
	(museum.get("_stamp_queue") as Array).clear()
	(museum.get("_cartridge_pending_nodes") as Array).clear()
	(museum.get("_repair_owed") as Array).clear()
	var segments: Array = museum.get("_segments")
	var old_nodes: Array[Node] = []
	for rec: Dictionary in segments:
		old_nodes.append(rec.node)
	while not segments.is_empty():
		museum.call("_stream_free", 0, "through portal")
	# These cells describe the previous geometry; stale support is not a floor.
	(museum.get("_walk_cells") as Dictionary).clear()
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	for old: Variant in old_nodes:
		if is_instance_valid(old):
			_fail("The previous hall could not be released.")
			return
	_set_phase("empty", "Preparing the next hall")

func _build_destination(record: Dictionary, returning := false) -> void:
	if phase == "error":
		return
	_set_phase("architecture", "Preparing the floor")
	await get_tree().process_frame
	var started := Time.get_ticks_msec()
	if record.is_empty():
		museum.call("_vr_build_forward_shell")
	else:
		var freed: Array = museum.get("_freed")
		for i in range(freed.size()-1, -1, -1):
			if absf(float(freed[i].z0)-float(record.z0)) < 0.1:
				freed.remove_at(i)
		museum.call("_vr_build_shell_from_record", record)
	var segments: Array = museum.get("_segments")
	if segments.size() != 1:
		_fail("The destination did not produce a single hall.")
		return
	_current = segments[0]
	_destination = _current.duplicate(true)
	_destination.erase("node")
	museum.set("_vr_current_node", _current.node)
	events.append({"phase":"architecture_ms", "ms":Time.get_ticks_msec()-started})
	_set_phase("resources", "Bringing in the exhibits")
	var paths: Array[String] = []
	for recipe: Dictionary in _current.node.get_meta("em_vr_content_blueprints", []):
		var path := String(recipe.get("scene_path", ""))
		if path != "" and not paths.has(path):
			paths.append(path)
	_resources.clear()
	for path in paths:
		if ResourceLoader.load_threaded_request(path, "PackedScene") != OK:
			_fail("An exhibit could not be requested: " + path.get_file())
			return
	started = Time.get_ticks_msec()
	while not paths.is_empty():
		if phase == "error":
			return
		for i in range(paths.size()-1, -1, -1):
			var state := ResourceLoader.load_threaded_get_status(paths[i])
			if state == ResourceLoader.THREAD_LOAD_LOADED:
				_resources.append(ResourceLoader.load_threaded_get(paths[i]))
				paths.remove_at(i)
			elif state == ResourceLoader.THREAD_LOAD_FAILED or state == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_fail("An exhibit could not be loaded: " + paths[i].get_file())
				return
		if Time.get_ticks_msec()-started > TIMEOUT_MS:
			_fail("Loading took too long.")
			return
		await get_tree().process_frame
	museum.call("_vr_promote_segment", _current)
	_set_phase("artifacts", "Arranging the exhibits")
	started = Time.get_ticks_msec()
	while not (museum.get("_stamp_queue") as Array).is_empty() or not (museum.get("_cartridge_pending_nodes") as Array).is_empty() or not (museum.get("_repair_owed") as Array).is_empty():
		if phase == "error":
			return
		if Time.get_ticks_msec()-started > TIMEOUT_MS:
			_fail("The exhibits are not ready yet.")
			return
		await get_tree().process_frame
	if phase == "error":
		return
	_restore_state(_current.node)
	_set_phase("support", "Checking your way in")
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	install_portals()
	_arrival = _return_point if returning else _find_landing(_direction < 0)
	if not _supported(_arrival):
		_fail("The destination has no clear supported landing.")
		return
	_set_phase("arriving", "The hall is ready")
	_move_player(_arrival)
	museum.set("_last_ground", _arrival)
	await get_tree().physics_frame
	await get_tree().process_frame
	_restore_movement()
	_resources.clear()
	busy = false
	_set_phase("idle", "")
	print("[em-portals] arrived in ", _current.node.get_meta("em_map", ""))

func return_to_source() -> void:
	if phase != "error" or _source.is_empty():
		return
	_set_phase("returning", "Returning to the previous hall")
	_recover.call_deferred()

func _recover() -> void:
	await _unload()
	await _build_destination(_source, true)

func loading_focus() -> Vector3:
	if _current.is_empty():
		return Vector3.ZERO
	return Vector3(float(_current.w)*0.5, 1.6, (float(_current.z0)+float(_current.z1))*0.5)

func _fail(message: String) -> void:
	failure = message
	_set_phase("error", "This hall could not open.\nTouch RETURN to go back.")
	push_warning("[em-portals] " + message)

func _set_phase(value: String, message: String) -> void:
	phase = value
	_status.text = message
	_back_button.visible = value == "error"
	events.append({"phase":value, "halls":(museum.get("_segments") as Array).size(), "ms":Time.get_ticks_msec()})

func _lock_movement() -> void:
	_providers.clear()
	var rig: Node3D = museum.call("_vr_rig")
	for provider: Node in get_tree().get_nodes_in_group("movement_providers"):
		if rig != null and rig.is_ancestor_of(provider):
			_providers.append({"node":provider, "enabled":provider.get("enabled")})
			provider.set("enabled", false)
			# XRTools also invokes active providers even when disabled. Cancel an
			# ongoing glide/climb so it cannot carry the body out of the cell.
			provider.set("is_active", false)

func _restore_movement() -> void:
	for saved: Dictionary in _providers:
		if is_instance_valid(saved.node):
			saved.node.set("enabled", saved.enabled)
	_providers.clear()

func _exit_tree() -> void:
	_restore_movement()

func _move_player(target: Vector3) -> void:
	var rig: Node3D = museum.call("_vr_rig")
	if rig == null:
		return
	var new_origin: Vector3 = museum.call("_vr_drop", rig.global_position, museum.call("_eye_pos"), target)
	var body := rig.find_child("PlayerBody", true, false)
	if body is Node3D and body.has_method("teleport"):
		var pose: Transform3D = body.global_transform
		pose.origin = target
		body.call("teleport", pose)
		# Startup/falling can leave a vertical body-to-origin offset. A landing
		# must put BOTH feet and tracking origin at the supported floor height.
		# Preserve the tracked head offset and orientation, not that stale gap.
		rig.global_position = new_origin
		body.set("velocity", Vector3.ZERO)
		body.set("ground_control_velocity", Vector2.ZERO)
	else:
		rig.global_position = new_origin
	museum.call("_vr_veil", Color.BLACK, 1.0, 0.35)

func _nearest_floor(eye: Vector3) -> Vector3:
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye, eye-Vector3(0,5,0)))
	return hit.position + Vector3(0,0.05,0) if not hit.is_empty() else Vector3(0,-1.0e9,0)

func _supported(p: Vector3) -> bool:
	if p.y < -1.0e8:
		return false
	var space := get_world_3d().direct_space_state
	for offset in [Vector3.ZERO, Vector3(0.3,0,0), Vector3(-0.3,0,0), Vector3(0,0,0.3), Vector3(0,0,-0.3)]:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p+offset+Vector3(0,0.15,0), p+offset-Vector3(0,0.2,0)))
		if hit.is_empty() or hit.normal.y < 0.8 or not (hit.collider is StaticBody3D):
			return false
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform.origin = p + Vector3(0,0.95,0)
	# Ignore the visitor's own body when checking the original landing.
	var rig: Node3D = museum.call("_vr_rig")
	var own_body: Node = rig.find_child("PlayerBody", true, false) if rig != null else null
	if own_body is CollisionObject3D:
		query.exclude = [own_body.get_rid()]
	for body: Node in get_tree().get_nodes_in_group("player_body"):
		if body is CollisionObject3D:
			var excluded := query.exclude
			excluded.append(body.get_rid())
			query.exclude = excluded
	return space.intersect_shape(query, 1).is_empty()

func _find_landing(at_far_end: bool) -> Vector3:
	var cells: Dictionary = museum.get("_walk_cells")
	var node: Node3D = _current.node
	var rows: Array = node.get_meta("em_tile", [])
	var start: float = float(_current.z0) + float(museum.get("VESTIBULE_H"))
	var end := minf(float(_current.z1)-2.0, start+rows.size()-1.0)
	var wanted := Vector3(float(_current.w)*0.5, 0, end-1.0 if at_far_end else start+1.5)
	var options: Array[Vector3] = []
	for cell: Vector2i in cells:
		if cell.y >= start and cell.y < end:
			options.append(Vector3(cell.x+0.5, 0, cell.y+0.5))
	options.sort_custom(func(a: Vector3,b: Vector3): return a.distance_squared_to(wanted)<b.distance_squared_to(wanted))
	for option in options.slice(0, 100):
		# Pilot maps have ground-level decks. Do not mistake a ceiling or an
		# artifact's top for an arrival floor; raised arenas need authored anchors.
		var p := _nearest_floor(option+Vector3(0,1,0))
		if _supported(p) and _portal_clear(p):
			return p
	return Vector3(0,-1.0e9,0)

func _portal_clear(p: Vector3) -> bool:
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.18,2.76,0.44)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = p+Vector3(0,1.41,0)
	var portal_root: Node = _current.node.get_node_or_null("HallPortals")
	if portal_root != null:
		for part: Node in portal_root.find_children("*", "StaticBody3D", true, false):
			var excluded := query.exclude
			excluded.append((part as CollisionObject3D).get_rid())
			query.exclude = excluded
	for body: Node in get_tree().get_nodes_in_group("player_body"):
		if body is CollisionObject3D:
			var excluded := query.exclude
			excluded.append(body.get_rid())
			query.exclude = excluded
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func install_portals() -> void:
	_portals.clear()
	var seg: Node3D = _current.node
	if seg.has_node("HallPortals"):
		seg.get_node("HallPortals").queue_free()
	var root := Node3D.new()
	root.name = "HallPortals"
	seg.add_child(root)
	for direction in [-1, 1]:
		var boundary: float = _current.z0 if direction < 0 else _current.z1
		var available: int = museum.call("_freed_index_for_boundary", boundary, direction)
		var title := "NEXT HALL"
		if available >= 0:
			title = String((museum.get("_freed") as Array)[available].get("map", "PREVIOUS HALL" if direction < 0 else "NEXT HALL"))
		elif direction < 0:
			continue
		else:
			var next_map: String = museum.call("_peek_next_authored_map")
			if next_map != "": title = next_map
		var p := _find_landing(direction > 0)
		if p.y < -1.0e8:
			continue
		var frame := Node3D.new()
		root.add_child(frame)
		frame.global_position = p
		load("res://commons/scenes/em/em_portal_frame.gd").build(frame,title,direction)
		_portals.append({"direction":direction, "position":p})
	# A visitor who walks past a portal still meets support and an end wall.
	for z in [float(_current.z0)+0.1, float(_current.z1)-0.1]:
		var wall := _box(root, Vector3(float(_current.w)+2,5,0.2), Vector3.ZERO, Color(0.12,0.16,0.2))
		wall.global_position = Vector3(float(_current.w)*0.5,2,z)

func _save_state(root: Node3D) -> void:
	var saved: Dictionary = {}
	for node: Node in root.find_children("*", "", true, false):
		if node.has_method("capture_museum_state"):
			saved[_state_key(root, node)] = node.call("capture_museum_state")
	_states[String(root.get_meta("em_map", ""))] = saved

func _restore_state(root: Node3D) -> void:
	var saved: Dictionary = _states.get(String(root.get_meta("em_map", "")), {})
	for node: Node in root.find_children("*", "", true, false):
		var key := _state_key(root, node)
		if saved.has(key) and node.has_method("restore_museum_state"):
			node.call("restore_museum_state", saved[key])

func _state_key(root: Node3D, node: Node) -> String:
	if node is Node3D:
		return String(node.get_meta("artifact_lookup_name", node.name))+"@"+str(root.to_local(node.global_position).snapped(Vector3.ONE*0.01))
	return String(root.get_path_to(node))

func _make_cell() -> void:
	_cell = Node3D.new()
	_cell.name = "SupportedLoadingCell"
	add_child(_cell)
	_cell.position = _cell_floor-Vector3(0,0.05,0)
	_box(_cell, Vector3(6,0.3,6), Vector3(0,-0.15,0), Color(0.12,0.16,0.2))
	_box(_cell, Vector3(6,0.2,6), Vector3(0,3,0), Color(0.06,0.08,0.12))
	for x in [-3,3]:
		_box(_cell,Vector3(0.2,3,6),Vector3(x,1.5,0),Color(0.06,0.09,0.14))
	for z in [-3,3]:
		_box(_cell,Vector3(6,3,0.2),Vector3(0,1.5,z),Color(0.06,0.09,0.14))
	_box(_cell,Vector3(5.8,0.03,0.03),Vector3(0,0.08,-2.85),Color(0.15,0.85,0.72),false)
	_status = _label(_cell, "", Vector3(0,1.75,-1.8),0.003)
	_back_button = _box(_cell,Vector3(0.6,0.2,0.15),Vector3(0,1.4,-0.75),Color(0.6,0.45,0.95),false)
	_label(_back_button,"RETURN",Vector3(0,0,0.09),0.002)
	_back_button.visible = false

func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, solid := true) -> Node3D:
	var body := StaticBody3D.new()
	body.position = pos
	parent.add_child(body)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
	return body

func _label(parent: Node3D, text: String, pos: Vector3, pixel: float) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.pixel_size = pixel
	label.font_size = 36
	label.no_depth_test = false
	label.double_sided = true
	parent.add_child(label)
	return label
