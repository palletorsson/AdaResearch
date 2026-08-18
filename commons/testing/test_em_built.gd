extends SceneTree
## GATE: the AS-BUILT plan. The assembler writes ada_run/em_built.json as each
## segment finishes — every cell's role, every body's final pose and number,
## every card. Build the first two segments on the desktop and in VR and the
## two files must describe the same rooms; the diff is what parity MEANS now.
## Copies land in user://em_built_desktop.json / user://em_built_vr.json for
## `python tools/em_built.py --diff`.
const BUILT := "res://ada_run/em_built.json"
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var a: Dictionary = await _build(false)
	var b: Dictionary = await _build(true)
	var ok: bool = true
	var why: Array = []
	if a.is_empty() or b.is_empty():
		ok = false; why.append("no em_built written (desktop %s, vr %s)" % [not a.is_empty(), not b.is_empty()])
	else:
		var sa: Array = a.get("segments", []); var sb: Array = b.get("segments", [])
		if sa.size() < 1: ok = false; why.append("desktop wrote 0 segments")
		if sa.size() != sb.size(): ok = false; why.append("segments %d vs %d" % [sa.size(), sb.size()])
		for i in range(mini(sa.size(), sb.size())):
			var A: Dictionary = sa[i]; var B: Dictionary = sb[i]
			if A.get("cells") != B.get("cells"): ok = false; why.append("seg %d cells differ" % i)
			var ba: Array = A.get("bodies", []); var bb: Array = B.get("bodies", [])
			if ba.size() != bb.size(): ok = false; why.append("seg %d bodies %d vs %d" % [i, ba.size(), bb.size()])
			var ca: Array = A.get("cards", []); var cb: Array = B.get("cards", [])
			if ca.size() != cb.size(): ok = false; why.append("seg %d cards %d vs %d" % [i, ca.size(), cb.size()])
			if i == 0 and ca.size() == 0: ok = false; why.append("seg 0 has no cards")
			if i == 0 and ba.size() == 0: ok = false; why.append("seg 0 has no bodies")
			# with a bake on disk every stamp must come from it: nothing measured, nothing unbaked
			if FileAccess.file_exists("res://ada_run/em_bake.json"):
				if not bool(A.get("replay", false)): ok = false; why.append("seg %d desktop did not replay the bake" % i)
				if not bool(B.get("replay", false)): ok = false; why.append("seg %d vr did not replay the bake" % i)
				if int(A.get("unbaked", 0)) + int(B.get("unbaked", 0)) > 0: ok = false; why.append("seg %d: %d/%d bodies placed the live way — the bake is stale for this plan (python tools/em_bake.py)" % [i, int(A.get("unbaked", 0)), int(B.get("unbaked", 0))])
			for j in range(mini(ba.size(), bb.size())):
				var x: Dictionary = ba[j]; var y: Dictionary = bb[j]
				if x.get("token") != y.get("token") or x.get("inv") != y.get("inv"):
					ok = false; why.append("seg %d body %d: %s/%s vs %s/%s" % [i, j, x.get("token"), x.get("inv"), y.get("token"), y.get("inv")]); break
				var wx: Array = x.get("world", [0,0,0]); var wy: Array = y.get("world", [0,0,0])
				if absf(float(wx[0]) - float(wy[0])) + absf(float(wx[2]) - float(wy[2])) > 0.05 or absf(float(x.get("rot", 0)) - float(y.get("rot", 0))) > 0.5:
					ok = false; why.append("seg %d %s pose differs" % [i, x.get("token")]); break
		if ok:
			var s0: Dictionary = sa[0]
			print("EM BUILT: %d segments · seg0 %s/%s %s · %d bodies · %d cards · desktop == vr · replay %s" % [sa.size(), s0.get("chapter"), s0.get("pearl"), s0.get("museum"), (s0.get("bodies", []) as Array).size(), (s0.get("cards", []) as Array).size(), s0.get("replay", false)])
	for w in why: print("EM BUILT: " + String(w))
	print("EM BUILT: %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
func _build(vr: bool) -> Dictionary:
	if FileAccess.file_exists(BUILT): DirAccess.remove_absolute(ProjectSettings.globalize_path(BUILT))
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	m.set("_force_vr", vr)
	get_root().add_child(m)
	# wait for two segments (the museum opens the second on its own at boot),
	# up to 12 s — a fixed 4 s wait once caught VR at one segment and desktop at two
	var waited: float = 0.0
	while waited < 30.0:
		await create_timer(0.5).timeout
		waited += 0.5
		if (m.get("_built") as Array).size() >= 2:
			break
	await create_timer(0.5).timeout
	var txt: String = FileAccess.get_file_as_string(BUILT) if FileAccess.file_exists(BUILT) else ""
	print("EM BUILT: %s run — waited %.1f s, _built %d, file %d bytes" % ["vr" if vr else "desktop", waited, (m.get("_built") as Array).size(), txt.length()])
	m.queue_free()
	await create_timer(0.5).timeout
	if txt == "": return {}
	var f := FileAccess.open("user://em_built_%s.json" % ("vr" if vr else "desktop"), FileAccess.WRITE)
	if f: f.store_string(txt)
	var d: Variant = JSON.parse_string(txt)
	return d if d is Dictionary else {}
