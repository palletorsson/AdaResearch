extends Node3D
## Museum navigation: one resident hall in desktop and VR, with a small loading cell.
## The cell belongs to this coordinator, never to an unloadable segment.
## Packed resources load on workers; scene construction still runs on the main
## thread. In particular, an individual artifact's _ready cannot be time-sliced.

var museum: Node3D
var _initial_loading := false
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
var _landings: Dictionary = {}
var _entry: Dictionary = {}
var _exit: Dictionary = {}
var _recovery_elapsed := 0.0
const ARRIVAL_INSET := 1.15
var _armed := false
var _dwell := 0.0
var _previous_eye := Vector3.ZERO
var _have_previous_eye := false
var _states: Dictionary = {}
var _providers: Array[Dictionary] = []
var _resources: Array[Resource] = []
var _destination: Dictionary = {}
var _return_point := Vector3.ZERO
var _arrival := Vector3.ZERO
var _cell_floor := Vector3(-1000.0, 0.05, 0.0)
const TIMEOUT_MS := 60000

func configure(owner_museum: Node3D, initial_loading := false) -> void:
	add_to_group("museum_portal_navigation")
	museum = owner_museum
	_initial_loading = initial_loading
	name = "PortalLoading"
	_make_cell()
	if initial_loading:
		busy = true
		_set_phase("boot", "Opening the entrance")
	adopt_current.call_deferred()

func staging_rig_ready() -> void:
	# XRTools' usual centering would subtract the tracked offset a second
	# time, after our floor-based arrival has already placed the body.
	if busy:
		_move_player(_cell_floor)
	elif _initial_loading and _source.is_empty():
		_move_player(museum.call("_drop_point") if String(_current.get("map", "")) == "Point_Zero" else _arrival)


func prepare_initial_arrival() -> void:
	# Support exists before a hall does. Keep the actual XR body, as well as
	# its tracking origin, out of the removed lounge while the grid builds.
	_lock_movement()
	await get_tree().physics_frame
	await get_tree().process_frame
	for attempt in range(30):
		if not bool(museum.get("_vr")) or museum.call("_vr_rig") != null:
			_move_player(_cell_floor)
			return
		await get_tree().process_frame

func adopt_current() -> void:
	while not bool(museum.get("_museum_ready")):
		await get_tree().process_frame
	busy = true
	_set_phase("support", "Opening the entrance")
	await get_tree().physics_frame
	await get_tree().process_frame
	var segments: Array = museum.get("_segments")
	if segments.size() != 1:
		_fail("Navigation must start with exactly one hall.")
		return
	_current = segments[0]
	museum.set("_vr_current_node", _current.node)
	if not await _wait_for_grids():
		return
	install_portals()
	# New StaticBody shapes need a physics flush before checking/using them.
	await get_tree().physics_frame
	await get_tree().process_frame
	_arrival = _landings.get(-1, Vector3(0,-1.0e9,0))
	if not _arrival_supported():
		_fail("The entrance has no clear supported landing.")
		return
	if _initial_loading:
		if String(_current.get("map", "")) == "Point_Zero":
			# Keep its authored drop, but move the XR physics body with the rig.
			_move_player(museum.call("_drop_point"))
		else:
			_move_player(_arrival)
			museum.set("_last_ground", _arrival)
		# A saved viewpoint still outranks a fresh entrance (e.g. editor toggle).
		museum.call("_follow_resume")
	_update_spawn_marker()
	_restore_movement()
	busy = false
	_set_phase("idle", "")


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
	var previous := _previous_eye if _have_previous_eye else eye
	_previous_eye = eye
	_have_previous_eye = true
	var near_any := false
	for portal: Dictionary in _portals:
		var p: Vector3 = portal.position
		var inward: Vector3 = portal.get("inward", Vector3(0,0,-int(portal.direction)))
		var across := Vector3(inward.z,0,-inward.x)
		var offset := eye-p
		var near := absf(offset.dot(across)) < 0.85 and absf(offset.dot(inward)) < 0.55 and absf(offset.y-1.4) < 1.3
		near_any = near_any or Vector2(offset.x,offset.z).length() < 1.8
		# Sweep in the doorway's own orientation, including side-wall exits.
		var direction := int(portal.direction)
		var before := (previous-p).dot(inward)
		var after := offset.dot(inward)
		var crossed := false
		if before > 0 and after <= 0:
			var crossing := previous.lerp(eye, before/(before-after))-p
			crossed = absf(crossing.dot(across)) < 0.85 and absf(crossing.y-1.4) < 1.3
		if _armed and (near or crossed):
			_dwell += delta
			if crossed or _dwell >= 0.08:
				request_crossing(direction)
			return
	_dwell = 0.0
	if not near_any:
		_armed = true

func _physics_process(delta: float) -> void:
	# This replaces the grid bounds checker only while a portal museum exists.
	# Use the actual physics body, never the room-scale tracking origin.
	if museum == null or not bool(museum.get("_vr")):
		return
	_recovery_elapsed += delta
	if _recovery_elapsed < 0.2:
		return
	_recovery_elapsed = 0.0
	var rig: Node3D = museum.call("_vr_rig")
	if rig == null: return
	var body := rig.find_child("PlayerBody", true, false) as Node3D
	if body == null: return
	if busy:
		# During construction the visitor belongs on the persistent loading
		# floor. A late staging callback must not leave their body in the void.
		if phase not in ["entering", "arriving", "support"] and body.global_position.distance_to(_cell_floor) > 4.0:
			_move_player(_cell_floor)
		return
	if _current.is_empty() or _arrival.y < -1.0e8: return
	var lowest := _arrival.y
	var heights: Dictionary = museum.get("_walk_h")
	for cell: Vector2i in heights:
		lowest = minf(lowest, float(heights[cell]))
	if body.global_position.y < lowest - 8.0 and _supported(_arrival):
		_move_player(_arrival)
		museum.set("_last_ground", _arrival)
		events.append({"phase":"fall_recovered", "map":_current.get("map", ""), "landing":str(_arrival)})


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
	var eye: Node3D = museum.call("_vr_eye") if bool(museum.get("_vr")) else museum.get("_cam")
	var forward: Vector3 = -eye.global_basis.z if eye != null else Vector3.FORWARD
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
	for key in ["_walk_cells", "_walk_h", "_walk_climb", "_ride_cells"]:
		(museum.get(key) as Dictionary).clear()
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
		if bool(museum.get("_vr")):
			museum.call("_vr_build_forward_shell")
		else:
			museum.call("_build_segment")
	else:
		var freed: Array = museum.get("_freed")
		for i in range(freed.size()-1, -1, -1):
			if absf(float(freed[i].z0)-float(record.z0)) < 0.1:
				freed.remove_at(i)
		if bool(museum.get("_vr")):
			museum.call("_vr_build_shell_from_record", record)
		else:
			museum.call("_stream_rebuild", record)
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
	if bool(museum.get("_vr")):
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
	if not await _wait_for_grids():
		return
	_restore_state(_current.node)
	_set_phase("support", "Opening the doorway")
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	install_portals()
	await get_tree().physics_frame
	await get_tree().process_frame
	_arrival = _return_point if returning else _landings.get(-_direction, Vector3(0,-1.0e9,0))
	if not _arrival_supported():
		_fail("The destination has no clear supported landing.")
		return
	_set_phase("arriving", "The hall is ready")
	_move_player(_arrival)
	museum.set("_last_ground", _arrival)
	_update_spawn_marker()
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
	_set_phase("error", "This hall could not open.\n" + ("Reload to try again." if _source.is_empty() else "Touch RETURN to go back."))
	push_warning("[em-portals] " + message)

func _set_phase(value: String, message: String) -> void:
	phase = value
	_status.text = message
	_back_button.visible = value == "error" and not _source.is_empty()
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
	if not bool(museum.get("_vr")):
		var walker: CharacterBody3D = museum.get("_player")
		if walker != null:
			walker.global_position = target
			walker.velocity = Vector3.ZERO
			museum.set("_vy", 0.0)
		return
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

func _supported(p: Vector3, allow_opening_door := false) -> bool:
	if p.y < -1.0e8:
		return false
	var space := get_world_3d().direct_space_state
	for offset in [Vector3.ZERO, Vector3(0.3,0,0), Vector3(-0.3,0,0), Vector3(0,0,0.3), Vector3(0,0,-0.3)]:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p+offset+Vector3(0,0.15,0), p+offset-Vector3(0,0.2,0)))
		if hit.is_empty() or hit.normal.y < 0.8 or not (hit.collider is StaticBody3D):
			return false
	return _body_clear(p,allow_opening_door)

func _body_clear(p: Vector3, allow_opening_door := false) -> bool:
	var space := get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform.origin = p + Vector3(0,0.95,0)
	var walker: Node = museum.get("_player")
	if walker is CollisionObject3D:
		query.exclude = [walker.get_rid()]
	# Ignore the visitor's own body when checking the original landing.
	var rig: Node3D = museum.call("_vr_rig")
	var own_body: Node = rig.find_child("PlayerBody", true, false) if rig != null else null
	if own_body is CollisionObject3D:
		var excluded := query.exclude
		excluded.append(own_body.get_rid())
		query.exclude = excluded
	for body: Node in get_tree().get_nodes_in_group("player_body"):
		if body is CollisionObject3D:
			var excluded := query.exclude
			excluded.append(body.get_rid())
			query.exclude = excluded
	if allow_opening_door:
		for door: Node in get_tree().get_nodes_in_group("museum_approach_doors"):
			if not door.has_method("museum_passage_bodies"): continue
			for body: CollisionObject3D in door.call("museum_passage_bodies"):
				var excluded := query.exclude
				excluded.append(body.get_rid())
				query.exclude = excluded
	return space.intersect_shape(query, 1).is_empty()

func _arrival_supported() -> bool:
	if not _supported(_arrival): return false
	if _entry.get("cage", false) and _arrival.distance_to(_entry.landing) < 0.1:
		for i in range(12):
			var step := _arrival.lerp((_entry.marker as Vector3)+Vector3(0,0,0.3), i/11.0)
			# An approach door is meant to start closed and open when the
			# visitor arrives. Only its moving leaves are exempt here; the
			# landing, floor, fixed frame and other obstacles still validate.
			if not _supported(step,true): return false
	return true


func _update_spawn_marker() -> void:
	var spawn := museum.get_node_or_null("SpawnPoint") as Node3D
	if spawn != null and _arrival.y > -1.0e8:
		spawn.global_position = _arrival

func _authored_entry() -> Dictionary:
	var map_name := String(_current.get("map", ""))
	# Point Zero has its own authored drop and lobby; do not turn its grid s into a portal.
	if map_name == "Point_Zero": return {}
	var path := "user://maps/%s/map_data.json" % map_name
	if not FileAccess.file_exists(path): path = "res://commons/maps/%s/map_data.json" % map_name
	if not FileAccess.file_exists(path): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary: return {}
	var doc: Dictionary = parsed
	var layers: Dictionary = doc.get("layers", {})
	var utilities: Array = layers.get("utilities", [])
	var chosen := Vector2i(-1,-1)
	var source := ""
	# The museum's sp wins over a legacy grid s when both are present.
	for kind: String in ["sp","s"]:
		for z in range(utilities.size()):
			for x in range(utilities[z].size()):
				var token := str(utilities[z][x]).strip_edges().split("#")[0]
				var parts := token.split(":")
				if parts[0] != kind: continue
				chosen = Vector2i(x,z)
				if parts.size() >= 4 and parts[1].is_valid_float() and parts[3].is_valid_float():
					chosen = Vector2i(int(float(parts[1])),int(float(parts[3])))
				source = kind
				break
			if chosen.x >= 0: break
		if chosen.x >= 0: break
	if chosen.x < 0: return {}
	# Several old grid routes run backwards. Their far-end s is not the
	# beginning of the museum's forward walk. An explicit sp always wins;
	# otherwise those maps retain the entrance-side fallback.
	var structure_rows: Array = layers.get("structure", [])
	if source == "s" and chosen.y > structure_rows.size() / 2:
		return {}
	var seg: Node3D = _current.node
	var pad := float((seg.get_meta("em_simulation_stage", {}) as Dictionary).get("pad", 0.0))
	var marker := seg.to_global(Vector3(chosen.x+0.5+pad,0,chosen.y+0.5+pad+float(museum.get("VESTIBULE_H"))))
	var level: float = museum.call("_arrival_floor_y", marker.x, marker.z)
	var grid := seg.get_node_or_null("SimGrid_" + map_name) as Node3D
	if grid != null:
		var cell_size := float(grid.get("cube_size"))
		marker = grid.to_global(Vector3(chosen.x*cell_size,0,chosen.y*cell_size))
		var structure: Array = layers.get("structure", [])
		var height := 1.0
		if chosen.y < structure.size() and chosen.x < structure[chosen.y].size():
			var token := str(structure[chosen.y][chosen.x])
			if token.is_valid_float(): height = maxf(1.0,float(token))
		level = grid.global_position.y + (height-0.5)*cell_size
	var floor_point := _nearest_floor(Vector3(marker.x,level+0.4,marker.z))
	var config: Dictionary = doc.get("map_info", {}).get("museum", {}).get("portal_entry", {})
	var cage := bool(config.get("cage", chosen.y == 0 and pad == 0.0))
	# A malformed/blocked authored entry is reported, not silently moved past
	# its opening exhibits. The visitor stays on the supported loading floor.
	if not _supported(floor_point):
		return {"invalid":true,"source":source,"cell":chosen}
	var door := floor_point - Vector3(0,0,3.0 if cage else ARRIVAL_INSET)
	if not _portal_clear(door): return {"invalid":true,"source":source,"cell":chosen}
	return {"source":source,"cell":chosen,"marker":floor_point,"cage":cage,
		"door":door,"landing":door+Vector3(0,0,ARRIVAL_INSET)}


func _authored_exit() -> Dictionary:
	var map_name := String(_current.get("map", ""))
	var path := "user://maps/%s/map_data.json" % map_name
	if not FileAccess.file_exists(path): path = "res://commons/maps/%s/map_data.json" % map_name
	if not FileAccess.file_exists(path): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary: return {}
	var layers: Dictionary = parsed.get("layers", {})
	var utilities: Array = layers.get("utilities", [])
	# A doorway beside a ramp or pit needs its landing outside the authored
	# exit cell. Keep the cell as the connection to the hall; shift only the
	# frame, by no more than the length of its supported approach.
	var config: Dictionary = parsed.get("map_info", {}).get("museum", {}).get("portal_exit", {})
	var outset := clampf(float(config.get("outset", 0.0)), 0.0, 2.3)
	var approaches: Array[Vector3] = [Vector3.FORWARD,Vector3.LEFT,Vector3.RIGHT,Vector3.BACK]
	var facing: String = str(config.get("approach", ""))
	if facing == "from_hall": approaches = [Vector3.FORWARD]
	var candidates: Array[Vector2i] = []
	var next_map: String = museum.call("_peek_next_authored_map")
	for z in range(utilities.size()):
		for x in range(utilities[z].size()):
			var token := str(utilities[z][x]).strip_edges().split("#")[0]
			# Restart/side-trip teleporters are not the next-hall crossing.
			if token == "t" or token == "t:"+next_map:
				candidates.append(Vector2i(x,z))
	if candidates.is_empty(): return {}
	# Repeated t cells often form one wide exit. Prefer the farthest row,
	# then its centre, while trying the other authored cells if obstructed.
	var centre := 0.0
	for cell in candidates: centre += cell.x
	centre /= candidates.size()
	candidates.sort_custom(func(a: Vector2i,b: Vector2i): return a.y > b.y if a.y != b.y else absf(a.x-centre) < absf(b.x-centre))
	var seg: Node3D = _current.node
	var pad := float((seg.get_meta("em_simulation_stage", {}) as Dictionary).get("pad", 0.0))
	var grid := seg.get_node_or_null("SimGrid_"+map_name) as Node3D
	var rejected: Array[Dictionary] = []
	for cell in candidates:
		var marker := seg.to_global(Vector3(cell.x+0.5+pad,0,cell.y+0.5+pad+float(museum.get("VESTIBULE_H"))))
		var level: float = museum.call("_arrival_floor_y", marker.x,marker.z)
		if grid != null:
			var size := float(grid.get("cube_size"))
			marker = grid.to_global(Vector3(cell.x*size,0,cell.y*size))
			var structure: Array = layers.get("structure", [])
			var height := 1.0
			if cell.y < structure.size() and cell.x < structure[cell.y].size():
				var value := str(structure[cell.y][cell.x])
				if value.is_valid_float(): height = maxf(1.0,float(value))
			level = grid.global_position.y+(height-0.5)*size
		# Old grid teleport holes receive a flush solid threshold. Never use
		# the bottom of a pit as the doorway's floor height.
		var anchor := Vector3(marker.x,level+0.05,marker.z)
		for inward: Vector3 in approaches:
			var p := anchor - inward * outset
			var yaw := atan2(inward.x,inward.z)
			if not _portal_clear(p,yaw):
				rejected.append({"door":p,"inward":inward,"reason":"frame blocked"})
				continue
			if not _supported(p+inward*2.3):
				rejected.append({"door":p,"inward":inward,"reason":"approach unsupported","join":p+inward*2.3})
				continue
			var clear := true
			for distance: float in [0.0,0.4,0.8,ARRIVAL_INSET,1.6,2.0,2.3]:
				if not _body_clear(p+inward*distance):
					rejected.append({"door":p,"inward":inward,"reason":"approach blocked","distance":distance})
					clear = false
					break
			if clear:
				return {"source":"t","cell":cell,"marker":anchor,"door":p,"inward":inward,"yaw":yaw,"outset":outset}
	return {"invalid":true,"source":"t","cells":candidates,"rejected":rejected}


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
	for option in options.slice(0, 300):
		# Start just above the map's declared deck, below ceiling exhibits.
		var floor_y: float = museum.call("_arrival_floor_y", option.x, option.z)
		var p := _nearest_floor(option+Vector3(0,floor_y+1.0,0))
		if not _supported(p) or not _portal_clear(p):
			continue
		var inward := Vector3(0,0,-1 if at_far_end else 1)
		var connected := true
		# Check a walking lane all the way through the arrival pad and past
		# its inner edge. A slab at a pit lip is not a usable entrance.
		for distance: float in [0.55, ARRIVAL_INSET, 1.75, 2.3]:
			if not _supported(p + inward * distance):
				connected = false
				break
		if connected:
			return p
	return Vector3(0,-1.0e9,0)

func _portal_clear(p: Vector3, yaw := 0.0) -> bool:
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.18,2.76,0.44)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(Vector3.UP,yaw),p+Vector3(0,1.41,0))
	var walker: Node = museum.get("_player")
	if walker is CollisionObject3D:
		query.exclude = [walker.get_rid()]
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
	_landings.clear()
	_entry = _authored_entry()
	_exit = _authored_exit()
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
			title = "ENTRANCE"
		else:
			var next_map: String = museum.call("_peek_next_authored_map")
			if next_map != "": title = next_map
		var p := Vector3.ZERO
		var inward := Vector3(0,0,-direction)
		if direction < 0 and not _entry.is_empty():
			if bool(_entry.get("invalid", false)):
				push_warning("[em-portals] blocked authored entry: " + str(_entry))
				continue
			p = _entry.door
		elif direction > 0 and not _exit.is_empty() and not _exit.get("invalid",false):
			p = _exit.door
			inward = _exit.inward
		else:
			# Preserve navigation for old maps without a usable t; make an
			# obstructed authored exit visible in the log instead of hiding it.
			if direction > 0 and _exit.get("invalid",false):
				push_warning("[em-portals] blocked t exit; safe fallback in " + str(_current.get("map","")) + ": " + str(_exit))
			p = _find_landing(direction > 0)
		if p.y < -1.0e8:
			continue
		var frame := Node3D.new()
		root.add_child(frame)
		frame.name = "NextHall" if direction > 0 else "PreviousHall"
		frame.global_position = p
		var builder := load("res://commons/scenes/em/em_portal_frame.gd")
		if direction < 0 and available < 0:
			frame.name = "EntranceLanding"
			builder.build_landing(frame, Color(0.54,0.20,1.0), museum.call("_sm","deck"))
		else:
			builder.build(frame,title,direction,seg.get_meta("em_wall_mat",museum.call("_sm","wall_white")),museum.call("_sm","deck"))
			frame.rotation.y = atan2(inward.x,inward.z)
			_portals.append({"direction":direction, "position":p, "inward":inward})
			if direction > 0: frame.set_meta("authored_exit",_exit)
		if direction < 0 and bool(_entry.get("cage", false)):
			builder.build_entry_room(frame,String(_current.get("map","")),seg.get_meta("em_wall_mat",museum.call("_sm","wall_white")),museum.call("_sm","deck"))
		var landing := p + inward * ARRIVAL_INSET
		_landings[direction] = landing
	if not _portals.any(func(p: Dictionary): return int(p.direction) == 1):
		push_error("[em-portals] no supported exit doorway in " + str(_current.get("map", "")))
	# A visitor who walks past a portal still meets support and an end wall.
	for z in [float(_current.z0)+0.1, float(_current.z1)-0.1]:
		var wall := _box(root, Vector3(float(_current.w)+4,8,0.2), Vector3.ZERO, Color(0.12,0.16,0.2))
		wall.global_position = Vector3(float(_current.w)*0.5,3,z)

func _save_state(root: Node3D) -> void:
	var saved: Dictionary = {}
	for node: Node in root.find_children("*", "", true, false):
		if node.has_method("capture_museum_state"):
			saved[_state_key(root, node)] = node.call("capture_museum_state")
	_states[String(root.get_meta("em_map", ""))] = saved

func _restore_state(root: Node3D) -> void:
	var saved: Dictionary = _states.get(String(root.get_meta("em_map", "")), {})
	for node: Node in root.find_children("*", "", true, false):
		# Restoring an artifact may rebuild its children during this traversal.
		# Only surviving receivers need an address; retired display nodes do not.
		if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion():
			continue
		if not node.has_method("restore_museum_state"):
			continue
		var key := _state_key(root, node)
		if saved.has(key):
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
	_box(_cell,Vector3(5.8,0.03,0.03),Vector3(0,0.08,-2.85),Color(1.0,0.025,0.34),false)
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


func _wait_for_grids() -> bool:
	# Grid exhibits have their own frame-budgeted build. Empty museum queues
	# do not mean their physics floor or artifacts are ready yet.
	var started := Time.get_ticks_msec()
	while true:
		var pending := false
		for child in _current.node.get_children():
			if str(child.name).begins_with("SimGrid_") and not bool(child.get_meta("stage_grid_ready", false)):
				pending = true
		if not pending:
			return true
		if Time.get_ticks_msec() - started > TIMEOUT_MS:
			_fail("The room's simulation is still preparing.")
			return false
		await get_tree().process_frame
	return false
