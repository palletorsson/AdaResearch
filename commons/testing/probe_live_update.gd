# probe_live_update.gd — the live-update adapter on a bench, no socket.
#
# 2026-10-22: commons/bridge/live_update.gd applies a revision envelope to the
# loaded grid map. This probe loads a REAL map through the real GridSystem,
# then calls VRLink._command() with no socket (every handler returns its reply,
# as probe_vr_link_agent.gd relies on) and reads the acks:
#
#   1. move an artifact from its cell to an empty floor cell  -> applied, in_place,
#      the node stands at the new cell and nothing at the old
#   2. the same revision again                                 -> rejected (duplicate)
#   3. an older seq                                            -> rejected (obsolete)
#   4. a wrong base_revision, map_data carried                -> conflict, resolved_by_reload
#   5. a structure edit                                        -> applied via reload
#   6. a map that is not loaded                                -> rejected (not_loaded)
#   7. a malformed op                                          -> rejected (invalid)
#
#   godot --headless --path . --xr-mode off --script res://commons/testing/probe_live_update.gd -- --map=Point_One
#
# Exit 0 iff every check holds.
extends SceneTree

var _fails := 0
var _map := "Point_One"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--map="):
			_map = String(a).substr(6)
	_run.call_deferred()


func _ok(cond: bool, what: String) -> void:
	print("%s %s" % ["  ok  " if cond else "  FAIL", what])
	if not cond:
		_fails += 1


func _env(rid: String, seq: int, ops: Array, base: String = "", rev: String = "", carry: bool = false) -> Dictionary:
	var e: Dictionary = {"cmd": "update", "revision_id": rid, "project_id": "ada", "map_id": _map,
		"seq": seq, "base_revision": base, "revision": rev, "timestamp": 0.0,
		"source": "probe", "operations": ops}
	if carry:
		e["map_text"] = FileAccess.get_file_as_string("res://commons/maps/%s/map_data.json" % _map)
	return e


func _at_cell(gs: Node, at: Vector2i) -> Array:
	var found: Array = []
	for n in get_nodes_in_group("vr_editable_artifact"):
		if n is Node3D and is_instance_valid(n) and gs.is_ancestor_of(n) and n.has_meta("grid_cell") and n.get_meta("grid_cell") == at:
			found.append(n)
	return found


func _run() -> void:
	var link: Node = load("res://commons/bridge/vr_link.gd").new()
	link.name = "VRLinkProbe"
	root.add_child(link)   # not armed: _ready disables processing; _command is called by hand

	var gs: Node = (load("res://commons/grid/grid_system.tscn") as PackedScene).instantiate()
	gs.set("map_name", _map)
	gs.set("auto_load_map_on_ready", true)
	root.add_child(gs)
	var t0: int = Time.get_ticks_msec()
	while bool(gs.get("generation_in_progress")) or Time.get_ticks_msec() - t0 < 1500:
		await process_frame
		if Time.get_ticks_msec() - t0 > 60000:
			break
	await create_timer(0.5).timeout
	var arts: Array = get_nodes_in_group("vr_editable_artifact")
	print("probe: %s loaded, %d placed artifact(s)" % [_map, arts.size()])
	_ok(arts.size() > 0, "the map placed at least one artifact")
	if arts.is_empty():
		quit(1)
		return

	# a map cell with an artifact, and an empty floor cell to move it to
	var map_d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/%s/map_data.json" % _map))
	var layers: Dictionary = map_d.get("layers", {})
	var inter: Array = layers.get("interactables", [])
	var struct: Array = layers.get("structure", [])
	var from := Vector2i(-1, -1)
	var token := ""
	for z in inter.size():
		var row: Array = inter[z] if inter[z] is Array else String(inter[z]).split(",")
		for x in row.size():
			var tk: String = String(row[x]).strip_edges()
			if tk != "" and not tk.begins_with("#") and tk.find(":") == -1 and not _at_cell(gs, Vector2i(x, z)).is_empty():
				from = Vector2i(x, z)
				token = tk
				break
		if from.x >= 0:
			break
	if from.x < 0:   # fall back to the first placed node
		var n0: Node = arts[0]
		from = n0.get_meta("grid_cell")
		token = String(n0.get_meta("artifact_lookup_name"))
	var to := Vector2i(-1, -1)
	for z in struct.size():
		var row: Array = struct[z] if struct[z] is Array else String(struct[z]).split(",")
		for x in row.size():
			var h: String = String(row[x]).strip_edges()
			var irow: Array = inter[z] if (z < inter.size() and inter[z] is Array) else []
			var occupied: bool = z < inter.size() and x < irow.size() and String(irow[x]).strip_edges() != ""
			if h == "1" and not occupied and Vector2i(x, z) != from and _at_cell(gs, Vector2i(x, z)).is_empty():
				to = Vector2i(x, z)
				break
		if to.x >= 0:
			break
	_ok(to.x >= 0, "found an empty floor cell to move to")
	print("probe: move %s %s -> %s" % [token, from, to])

	# 1. move, in place
	var live: RefCounted = link.call("_live_for")
	live.note_loaded(_map)
	var rev0: String = FileAccess.get_sha256("res://commons/maps/%s/map_data.json" % _map)
	var mv: Array = [{"op": "move", "layer": "interactables", "from": [from.x, from.y], "to": [to.x, to.y], "token": token}]
	var a1: Dictionary = link.call("_command", _env("rev-1", 1, mv, rev0, "sha-new-1"))
	print("  ack1: %s" % JSON.stringify(a1))
	_ok(a1.get("status") == "applied" and a1.get("mode") == "in_place", "1. move -> applied in place")
	await process_frame
	_ok(_at_cell(gs, from).is_empty(), "1. nothing stands at the old cell")
	var moved: Array = _at_cell(gs, to)
	_ok(moved.size() == 1 and String(moved[0].get_meta("artifact_lookup_name")) == token, "1. the artifact stands at the new cell")
	if moved.size() == 1:
		var total: float = float(gs.get("cube_size")) + float(gs.get("gutter"))
		var p: Vector3 = (moved[0] as Node3D).position
		_ok(absf(p.x - to.x * total) < 0.01 and absf(p.z - to.y * total) < 0.01, "1. its position is the cell's world position")

	# 2. duplicate
	var a2: Dictionary = link.call("_command", _env("rev-1", 1, mv, rev0, "sha-new-1"))
	_ok(a2.get("status") == "rejected" and a2.get("reason") == "duplicate", "2. same revision again -> rejected (duplicate)")

	# 3. obsolete seq
	var a3: Dictionary = link.call("_command", _env("rev-0", 0, mv, "sha-new-1", "sha-new-0").merged({"seq": 1}, true))
	_ok(a3.get("status") == "rejected" and a3.get("reason") == "obsolete", "3. older seq -> rejected (obsolete)")

	# 6. not loaded
	var a6: Dictionary = link.call("_command", _env("rev-x", 9, mv).merged({"map_id": "No_Such_Map"}, true))
	_ok(a6.get("status") == "rejected" and a6.get("reason") == "not_loaded", "6. unknown map -> rejected (not_loaded)")

	# 7. malformed
	var a7: Dictionary = link.call("_command", _env("rev-bad", 2, [{"op": "teleport", "layer": "interactables"}]))
	_ok(a7.get("status") == "rejected" and a7.get("reason") == "invalid", "7. unknown op -> rejected (invalid)")

	# 4. conflict with map_data carried -> reload
	var a4: Dictionary = link.call("_command", _env("rev-2", 2, mv, "sha-somebody-else", "sha-new-2", true))
	_ok(a4.get("status") == "conflict" and a4.get("reason") == "resolved_by_reload", "4. wrong base -> conflict, resolved by reload")
	t0 = Time.get_ticks_msec()
	await process_frame
	await process_frame
	while bool(gs.get("generation_in_progress")) and Time.get_ticks_msec() - t0 < 60000:
		await process_frame
	await create_timer(0.5).timeout
	var after_n: int = get_nodes_in_group("vr_editable_artifact").size()
	_ok(after_n == arts.size(), "4. after the reload the map stands as the file says (%d artifacts, found %d)" % [arts.size(), after_n])

	# 5. structure edit -> reload
	# after a reload the scene holds the FILE's revision (rev0: nothing wrote the file), so that is the base now
	var a5: Dictionary = link.call("_command", _env("rev-3", 3, [{"op": "set_cell", "layer": "structure", "at": [0, 0], "before": "1", "after": "2"}], rev0, "sha-new-3", true))
	_ok(a5.get("status") == "applied" and a5.get("mode") == "reload", "5. structure edit -> applied via reload")

	print("probe_live_update: %d failure(s)" % _fails)
	quit(1 if _fails > 0 else 0)
