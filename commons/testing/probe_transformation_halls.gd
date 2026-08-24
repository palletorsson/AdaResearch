extends SceneTree
## THE TRANSFORMATION HALLS, TESTED (2026-08-24, Palle: "test the other
## translations maps") — boots the real endless_museum with TRIAL control
## (probe isolation), forces all seven transformation segments to build, and
## measures the BUILT WORLD with raycasts — batching hides boxes from node
## scans, but physics cannot lie about where the floor is:
##   translation        pool floor at -1 under the field, p:3 pier at +3,
##                      wedges seated on the pool floor, deck margin at 0
##   axisdecomposition  pool at -1, entry deck at 0
##   rotation           pool at -1, rotate_grid_cubes sunken, a wedge in
##   rotationspectacle  OPEN ROOF (sky ray reaches the floor), tunnel placed
##   scale              still ROOFED (the control for the sky ray)
##   pit                hazard patches with Area3D, the living blocks placed
##   every hall         the exit chicane adds 3 rows past the map
## godot --headless --path . --xr-mode off --script res://commons/testing/probe_transformation_halls.gd

const OUT := "res://ada_run/transformation_probe.txt"
const V := 4.0   # VESTIBULE_H


func _initialize() -> void:
	call_deferred("_run")


func _roof_meshes(seg: Node3D) -> int:
	## em_detail emits the coffered ceiling as nodes NAMED Ceiling /
	## ArrisCeiling (an AABB-height scan missed them: the ribs hang at 4.46,
	## below the wall head). Count their instances.
	if seg == null or not is_instance_valid(seg):
		return -1
	var n_roof: int = 0
	for nm in ["Ceiling", "ArrisCeiling"]:
		var cn: Node = seg.find_child(nm, true, false)
		if cn == null:
			continue
		if cn is MultiMeshInstance3D and (cn as MultiMeshInstance3D).multimesh != null:
			n_roof += (cn as MultiMeshInstance3D).multimesh.instance_count
		else:
			n_roof += 1
	return n_roof


func _ray_y(w3d: World3D, x: float, z: float, from_y: float = 12.0) -> float:
	## y of the first hit casting straight down at (x, z); -999 = nothing
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, from_y, z), Vector3(x, -30.0, z))
	var hit: Dictionary = w3d.direct_space_state.intersect_ray(q)
	return float(hit["position"].y) if not hit.is_empty() else -999.0


func _run() -> void:
	var fails: Array = []
	var notes: Array = []
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_tf_control.json")
	inst.set("_overrides_path", "res://ada_run/_trial_tf_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_tf_hand.json")
	var ctl := FileAccess.open("res://ada_run/_trial_tf_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "transformation", "dollhouse": 0, "grid_pack": 1}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(1.0).timeout
	# the probe wants ALL SEVEN standing at once — the one-hall stream must
	# not free anything mid-measure
	inst.set("MIN_SEGMENTS", 99)
	inst.set("KEEP_AHEAD_M", 99999.0)
	inst.set("KEEP_BEHIND_M", 99999.0)
	for i in range(7):
		if (inst.get("_segments") as Array).size() >= 7:
			break
		inst.call("_build_segment")
		await create_timer(0.3).timeout
	inst.call("flush_stamps")
	await create_timer(1.5).timeout   # settle: deferred configs, late seats, physics

	var segs: Array = inst.get("_segments")
	if segs.size() < 7:
		fails.append("only %d segment(s) built, wanted 7" % segs.size())
	# plan h per pearl (pre-chicane) for the passage check
	var plan_h: Dictionary = {}
	var plan_v: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://ada_run/em_plan.json"))
	if plan_v is Dictionary:
		for r_v in ((plan_v as Dictionary).get("plans", []) as Array):
			var r: Dictionary = r_v
			if str(r.get("sequence", "")) == "transformation":
				plan_h[str(r.get("pearl", ""))] = int(r.get("h", 0))
	var w3d: World3D = inst.get_world_3d()
	var by_pearl: Dictionary = {}
	for s_v in segs:
		var s: Dictionary = s_v
		var sn: Node3D = s.get("node")
		if sn != null and is_instance_valid(sn):
			by_pearl[str(s.get("pearl", ""))] = s

	# ── every hall: the chicane adds exactly 3 rows ─────────────────────────
	for pearl in plan_h.keys():
		if not by_pearl.has(pearl):
			fails.append("%s: never built" % pearl)
			continue
		var rec: Dictionary = by_pearl[pearl]
		var span: int = int(round(float(rec["z1"]) - float(rec["z0"]) - V))
		var want: int = int(plan_h[pearl]) + 3
		if span != want:
			fails.append("%s: z-span %d rows, wanted map %d + chicane 3 = %d" % [pearl, span, int(plan_h[pearl]), want])
		else:
			notes.append("%s: chicane present (h %d -> %d)" % [pearl, int(plan_h[pearl]), want])

	# helper: map cell -> world (authored halls are origin-pinned, offx 0)
	var cellw := func(rec: Dictionary, mx: float, mz: float) -> Vector2:
		return Vector2(mx + 0.5, float(rec["z0"]) + V + mz + 0.5)

	# ── trans translation ───────────────────────────────────────────────────
	if by_pearl.has("trans translation"):
		var rc: Dictionary = by_pearl["trans translation"]
		var p: Vector2 = cellw.call(rc, 3.0, 12.0)
		var y_pool: float = _ray_y(w3d, p.x, p.y)
		if absf(y_pool + 1.0) > 0.25:
			fails.append("translation: field floor at %.2f, wanted -1.0 (the pool)" % y_pool)
		var pp: Vector2 = cellw.call(rc, 2.0, 12.0)
		var y_pier: float = _ray_y(w3d, pp.x, pp.y)
		if absf(y_pier - 3.0) > 0.3:
			fails.append("translation: p:3 pier top at %.2f, wanted 3.0" % y_pier)
		var dm: Vector2 = cellw.call(rc, 3.0, 20.0)
		var y_deck: float = _ray_y(w3d, dm.x, dm.y)
		if absf(y_deck) > 0.2:
			fails.append("translation: south margin at %.2f, wanted 0 (deck)" % y_deck)
		var sunk_wedges: int = 0
		var sn2: Node3D = rc.get("node")
		for n in sn2.find_children("*", "Node3D", true, false):
			if str(n.name).to_lower().contains("walkableprism") or str((n as Node3D).scene_file_path).contains("walkableprism"):
				if (n as Node3D).position.y < 0.0:
					sunk_wedges += 1
		if sunk_wedges < 2:
			fails.append("translation: %d wedge(s) seated in the pool, wanted >=2" % sunk_wedges)
		else:
			notes.append("translation: pool -1 / pier +3 / deck 0 / %d sunken wedge(s)" % sunk_wedges)
		# the courtyard walk-around (2026-08-24): west margin and east
		# ambulatory at deck 0, and the two-flight stair's p:1 step at +1
		var mw: Vector2 = cellw.call(rc, 0.0, 10.0)
		var ymw: float = _ray_y(w3d, mw.x, mw.y)
		var me: Vector2 = cellw.call(rc, 7.0, 8.0)
		var yme: float = _ray_y(w3d, me.x, me.y)
		var stp: Vector2 = cellw.call(rc, 7.0, 12.0)
		var ystp: float = _ray_y(w3d, stp.x, stp.y)
		if absf(ymw) > 0.2 or absf(yme) > 0.2:
			fails.append("translation: margins west %.2f / east %.2f, wanted 0 (the walk-around)" % [ymw, yme])
		if absf(ystp - 1.0) > 0.25:
			fails.append("translation: stair step at %.2f, wanted 1.0 (the p:1 flight)" % ystp)
		if absf(ymw) <= 0.2 and absf(yme) <= 0.2 and absf(ystp - 1.0) <= 0.25:
			notes.append("translation: walk-around margins 0 / stair step +1")

	# ── trans axisdecomposition ─────────────────────────────────────────────
	if by_pearl.has("trans axisdecomposition"):
		var ra: Dictionary = by_pearl["trans axisdecomposition"]
		# (4,13) is an EMPTY pool cell — probing (5,14) hit the
		# z_translation_cube standing there at 0.2 (measure the floor, not
		# the exhibit)
		var pa: Vector2 = cellw.call(ra, 4.0, 13.0)
		var ya: float = _ray_y(w3d, pa.x, pa.y)
		if absf(ya + 1.0) > 0.25:
			fails.append("axisdecomposition: field floor at %.2f, wanted -1.0" % ya)
		# the SIMULATION declaration sinks the WHOLE map (2026-08-24): the
		# west strip is pool floor now, and the margins outside the tile walk
		# at deck 0 with wedges connecting them
		var da: Vector2 = cellw.call(ra, 1.0, 1.0)
		var yd: float = _ray_y(w3d, da.x, da.y)
		if absf(yd + 1.0) > 0.25:
			fails.append("axisdecomposition: west strip at %.2f, wanted -1.0 (the whole map is the simulation)" % yd)
		var ma: Vector2 = cellw.call(ra, -1.0, 8.0)
		var yma: float = _ray_y(w3d, ma.x, ma.y)
		if absf(yma) > 0.2:
			fails.append("axisdecomposition: margin at %.2f, wanted 0 (the walk-around)" % yma)
		var auto_wedges: int = 0
		var an2: Node3D = ra.get("node")
		for n in an2.find_children("*", "Node3D", true, false):
			if str(n.name).begins_with("Wedge_") and (n as Node3D).position.y < 0.2:
				auto_wedges += 1
		if auto_wedges < 3:
			fails.append("axisdecomposition: %d auto wedge(s), wanted >=3 (entry/exit/sides)" % auto_wedges)
		if absf(yd + 1.0) <= 0.25 and absf(yma) <= 0.2 and auto_wedges >= 3:
			notes.append("axisdecomposition: whole map sunk / margin 0 / %d connecting wedges" % auto_wedges)

	# ── trans rotation ──────────────────────────────────────────────────────
	if by_pearl.has("trans rotation"):
		var rr: Dictionary = by_pearl["trans rotation"]
		var pr: Vector2 = cellw.call(rr, 3.0, 4.0)
		var yr: float = _ray_y(w3d, pr.x, pr.y)
		if absf(yr + 1.0) > 0.25:
			fails.append("rotation: simulation floor at %.2f, wanted -1.0" % yr)
		var sunken := false
		var rn: Node3D = rr.get("node")
		for n in rn.find_children("*", "Node3D", true, false):
			if n.has_meta("artifact_lookup_name") and str(n.get_meta("artifact_lookup_name")) == "rotate_grid_cubes":
				if (n as Node3D).position.y < -0.4:
					sunken = true
		if not sunken:
			fails.append("rotation: rotate_grid_cubes not sunken into the pool")
		else:
			notes.append("rotation: pool -1, the grid-changer stands in it")

	# ── trans rotationspectacle: OPEN ROOF ──────────────────────────────────
	# ceilings are VISUAL-ONLY (no colliders) — a raycast cannot see them
	# (the first run "proved" scale unroofed by ray; the instrument was
	# blind). Count meshes whose AABB bottom sits above the wall head.
	if by_pearl.has("trans rotationspectacle"):
		var rs: Dictionary = by_pearl["trans rotationspectacle"]
		var roofn: int = _roof_meshes(rs.get("node"))
		if roofn > 0:
			fails.append("rotationspectacle: %d ceiling mesh(es) — the courtyard has a ROOF" % roofn)
		else:
			notes.append("rotationspectacle: open roof (0 ceiling meshes)")
		var tunnel := false
		var tn: Node3D = rs.get("node")
		for n in tn.find_children("*", "Node3D", true, false):
			if n.has_meta("artifact_lookup_name") and str(n.get_meta("artifact_lookup_name")) == "boolean_tunnel":
				tunnel = true
		if not tunnel:
			fails.append("rotationspectacle: boolean_tunnel missing")

	# ── trans scale: the ROOFED control ─────────────────────────────────────
	if by_pearl.has("trans scale"):
		var rsc: Dictionary = by_pearl["trans scale"]
		var roofc: int = _roof_meshes(rsc.get("node"))
		if roofc == 0:
			fails.append("scale: 0 ceiling meshes — this hall should still be roofed")
		else:
			notes.append("scale: roofed (%d ceiling meshes)" % roofc)

	# ── trans pit: the museum-safe danger ───────────────────────────────────
	if by_pearl.has("trans pit"):
		var rp: Dictionary = by_pearl["trans pit"]
		var pn: Node3D = rp.get("node")
		var patches: int = 0
		var with_area: int = 0
		var blocks: int = 0
		for n in pn.find_children("*", "Node3D", true, false):
			if str(n.name).begins_with("Hazard_"):
				patches += 1
				for c in n.get_children():
					if c is Area3D:
						with_area += 1
						break
			if n.has_meta("artifact_lookup_name") and str(n.get_meta("artifact_lookup_name")) in ["pusher_block", "grower_block"]:
				blocks += 1
		if patches < 20:
			fails.append("pit: %d hazard patch(es), wanted >=20 (the map carries 32 h: cells)" % patches)
		if with_area < patches:
			fails.append("pit: %d/%d patches carry an Area3D" % [with_area, patches])
		if blocks < 4:
			fails.append("pit: %d living block(s), wanted >=4" % blocks)
		if patches >= 20 and blocks >= 4:
			notes.append("pit: %d hazard patches (all armed), %d living blocks" % [patches, blocks])

	var report := "TRANSFORMATION HALLS PROBE\n"
	for nt in notes:
		report += "  ok   %s\n" % nt
	for fl in fails:
		report += "  FAIL %s\n" % fl
	report += "%d fail(s)\n" % fails.size()
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(report)
	f.close()
	print(report)
	quit(1 if not fails.is_empty() else 0)
