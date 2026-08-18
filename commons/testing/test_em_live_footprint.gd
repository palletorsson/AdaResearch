extends SceneTree
## The live footprint ledger + walk-inside, museum side.
## GATE: a body within its footprint seals as before and writes NO ledger.
## BITE: a 12 m body with NO collider seals ZERO cells (walk-inside) and is
##       ledgered walk_inside=true; a 12 m body WITH a collider seals cells and
##       is ledgered has_collider=true. The live ledger file is backed up and
##       restored, so the run leaves no trace.
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_live_footprint.gd
const LEDGER := "res://ada_run/em_live_footprints.json"

func _initialize() -> void:
	call_deferred("_run")

func _body(name: String, size_m: float, with_collider: bool, at: Vector3, parent: Node) -> Node3D:
	var n := Node3D.new(); n.name = name; n.set_meta("artifact_lookup_name", name)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(size_m, 1.0, size_m); mi.mesh = bm
	n.add_child(mi)
	if with_collider:
		var sb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = Vector3(size_m, 1.0, size_m); cs.shape = bs
		sb.add_child(cs); n.add_child(sb)
	parent.add_child(n)
	n.global_position = at
	return n

func _run() -> void:
	var fails: Array[String] = []
	var had := FileAccess.file_exists(LEDGER)
	var backup := FileAccess.get_file_as_string(LEDGER) if had else ""
	if had:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LEDGER))
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var m: Node3D = ps.instantiate() as Node3D
	m.set("_plan_path", "")
	get_root().add_child(m)
	await create_timer(0.6).timeout
	var walk: Dictionary = m.get("_walk_cells")
	# a walkable spot inside segment 0
	var cx := 7; var cz := 12
	if not walk.has(Vector2i(cx, cz)):
		for k in walk.keys():
			cx = (k as Vector2i).x; cz = (k as Vector2i).y; break
	var at := Vector3(cx + 0.5, 0.5, cz + 0.5)
	# GATE: 1 m body
	var small := _body("test_small_body", 1.0, true, at, m)
	await process_frame; await process_frame
	var c0: Array = m.call("_occupied_cells", small, {"x": cx, "y": cz, "rank": 2}, 0)
	if c0.is_empty(): fails.append("GATE: a 1 m body sealed no cells")
	# (the museum's own deal may already have ledgered a real overgrown body —
	# noisesphere lives 31 m wide with no collider — so the gate is that the
	# SMALL body is absent from the ledger, checked below, not that no file exists)
	small.queue_free()
	# BITE 1: 12 m, no collider -> walk inside
	var field := _body("test_field_no_collider", 12.0, false, at, m)
	await process_frame; await process_frame
	var c1: Array = m.call("_occupied_cells", field, {"x": cx, "y": cz, "rank": 2}, 0)
	if not c1.is_empty(): fails.append("BITE: a 12 m collider-less body sealed %d cells (walk-inside should seal 0)" % c1.size())
	if not (m.get("_walk_inside") as Dictionary).has("test_field_no_collider"): fails.append("BITE: not marked walk_inside")
	field.queue_free()
	# BITE 2: 12 m with collider -> sealed + ledgered
	var big := _body("test_big_collider", 12.0, true, at, m)
	await process_frame; await process_frame
	var c2: Array = m.call("_occupied_cells", big, {"x": cx, "y": cz, "rank": 2}, 0)
	if c2.is_empty(): fails.append("BITE: a 12 m collider body sealed nothing")
	big.queue_free()
	await process_frame
	if not FileAccess.file_exists(LEDGER):
		fails.append("BITE: no ledger written")
	else:
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LEDGER))
		var bodies: Dictionary = d.get("bodies", {})
		var f: Dictionary = bodies.get("test_field_no_collider", {})
		var b: Dictionary = bodies.get("test_big_collider", {})
		if f.is_empty() or not bool(f.get("walk_inside", false)): fails.append("BITE: field not ledgered walk_inside=true (%s)" % str(f))
		if b.is_empty() or not bool(b.get("has_collider", false)): fails.append("BITE: big body not ledgered has_collider=true (%s)" % str(b))
		if not b.is_empty() and float((b.get("live_aabb", [0,0,0]) as Array)[0]) < 11.5: fails.append("BITE: ledger live_aabb %s < 12 m" % str(b.get("live_aabb")))
		if bodies.has("test_small_body"): fails.append("GATE: the 1 m body is in the ledger")
	# restore
	if had:
		var w := FileAccess.open(LEDGER, FileAccess.WRITE); w.store_string(backup); w.close()
	elif FileAccess.file_exists(LEDGER):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LEDGER))
	get_root().remove_child(m); m.queue_free()
	if fails.is_empty():
		print("LIVE FOOTPRINT (museum): PASS — 1 m sealed %d, 12 m no-collider sealed 0 (walk-inside), 12 m collider sealed %d, both ledgered" % [c0.size(), c2.size()])
	else:
		print("LIVE FOOTPRINT (museum): FAIL %d" % fails.size()); for x in fails: print("  - " + x)
	quit(0 if fails.is_empty() else 1)
