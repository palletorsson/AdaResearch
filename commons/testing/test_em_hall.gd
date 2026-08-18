extends SceneTree
## The turbine hall, proven in the museum. A trial plan gives the opening
## chapter one hall row (venue hall, court_access ring, court [58,58]).
## BITE: the joint builds a hall: sunken floor collider at -HALL_DEPTH, the
## west/north/south galleries at y=0 walkable, the hall floor cells NOT in the
## walk map, two ramps, the body stamped. GATE: without the row, no hall.
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_hall.gd
const PLAN := "res://ada_run/em_plan.json"
const TRIAL := "res://ada_run/_trial_em_plan_hall.json"
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var fails: Array[String] = []
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PLAN))
	var plans: Array = doc.get("plans", [])
	# opening chapter/pearl per em_control
	var ctl: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://ada_run/em_control.json"))
	var want := String(ctl.get("first_chapter", "primitives")); var wmap := String(ctl.get("first_map", ""))
	var row: Dictionary = {}
	for pl in plans:
		if String((pl as Dictionary).get("sequence", "")) == want and (wmap == "" or String((pl as Dictionary).get("map", "")) == wmap):
			row = pl; break
	if row.is_empty(): row = plans[0]
	# add a hall resident: FlowFieldMain (50 m) as a hall row
	var arts: Array = row.get("artifacts", [])
	arts.push_front({"token": "lab_room", "cell": [0, 0], "tile_cell": [0, 0], "rotation": 0, "mode": "freestanding",
		"venue": "hall", "support_height_m": 0.0, "slot": "hall", "wall": null, "court": [58, 58], "court_access": "ring",
		"relation": {"walk_kind": "extends", "walk_why": "TRIAL hall row"}})
	row["artifacts"] = arts
	var f := FileAccess.open(TRIAL, FileAccess.WRITE); f.store_string(JSON.stringify(doc)); f.close()
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var m: Node3D = ps.instantiate() as Node3D
	m.set("_plan_path", TRIAL); m.set("_overrides_path", "res://ada_run/_trial_em_overrides_hall.json")
	get_root().add_child(m)
	await create_timer(1.0).timeout
	for i in range(3):
		m.call("_build_segment"); await create_timer(0.3).timeout
	var stats: Dictionary = m.get("_deal_stats")
	if int(stats.get("halls", 0)) < 1:
		fails.append("BITE: no hall built (halls=%d)" % int(stats.get("halls", 0)))
	# find the hall floor collider at -HALL_DEPTH and count ramps (rotated box colliders)
	var depth: float = float(m.get("HALL_DEPTH"))
	var floor_found := false; var ramps := 0
	var stack: Array = [m]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children(): stack.append(c)
		if n is CollisionShape3D:
			var cs := n as CollisionShape3D
			if cs.shape is BoxShape3D:
				var sz: Vector3 = (cs.shape as BoxShape3D).size
				if absf(cs.position.y - (-depth - 0.1)) < 0.05 and sz.x >= 40.0 and sz.z >= 40.0: floor_found = true
				if absf(cs.rotation.x) > 0.2 and sz.x == 3.0: ramps += 1
	if not floor_found: fails.append("BITE: no hall floor collider at %.1f m down" % -depth)
	if ramps != 2: fails.append("BITE: %d ramps, expected 2" % ramps)
	# walk map: gallery cells present, hall floor cells absent (probe the segment that holds the hall)
	var wc: Dictionary = m.get("_walk_cells")
	var g: int = int(m.get("HALL_GALLERY_W"))
	var seg_ok := false
	for s0 in (m.get("_segments") as Array):
		var zb: int = int((s0 as Dictionary).get("z0", 0))
		# scan for a row where x=1..3 walkable and x=g+10 not, followed by an all-walkable gallery row
		for z in range(zb, zb + 400):
			if wc.has(Vector2i(1, z)) and wc.has(Vector2i(g - 1, z)) and not wc.has(Vector2i(g + 10, z)) and wc.has(Vector2i(g + 10, z - 2)):
				seg_ok = true; break
		if seg_ok: break
	if not seg_ok: fails.append("BITE: walk map does not show gallery-open / hall-floor-closed")
	get_root().remove_child(m); m.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TRIAL))
	if FileAccess.file_exists("res://ada_run/_trial_em_overrides_hall.json"): DirAccess.remove_absolute(ProjectSettings.globalize_path("res://ada_run/_trial_em_overrides_hall.json"))
	if fails.is_empty(): print("EM HALL: PASS — hall built: floor %.1f m down, 2 ramps, galleries walkable, floor not advertised" % -depth)
	else:
		print("EM HALL: FAIL %d" % fails.size()); for x in fails: print("  - " + x)
	quit(0 if fails.is_empty() else 1)
