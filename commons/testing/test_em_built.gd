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
			for j in range(mini(ba.size(), bb.size())):
				var x: Dictionary = ba[j]; var y: Dictionary = bb[j]
				if x.get("token") != y.get("token") or x.get("inv") != y.get("inv"):
					ok = false; why.append("seg %d body %d: %s/%s vs %s/%s" % [i, j, x.get("token"), x.get("inv"), y.get("token"), y.get("inv")]); break
				var wx: Array = x.get("world", [0,0,0]); var wy: Array = y.get("world", [0,0,0])
				if absf(float(wx[0]) - float(wy[0])) + absf(float(wx[2]) - float(wy[2])) > 0.05 or absf(float(x.get("rot", 0)) - float(y.get("rot", 0))) > 0.5:
					ok = false; why.append("seg %d %s pose differs" % [i, x.get("token")]); break
		if ok:
			var s0: Dictionary = sa[0]
			print("EM BUILT: %d segments · seg0 %s/%s %s · %d bodies · %d cards · desktop == vr" % [sa.size(), s0.get("chapter"), s0.get("pearl"), s0.get("museum"), (s0.get("bodies", []) as Array).size(), (s0.get("cards", []) as Array).size()])
	for w in why: print("EM BUILT: " + String(w))
	print("EM BUILT: %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
func _build(vr: bool) -> Dictionary:
	if FileAccess.file_exists(BUILT): DirAccess.remove_absolute(ProjectSettings.globalize_path(BUILT))
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	m.set("_force_vr", vr)
	get_root().add_child(m)
	await create_timer(4.0).timeout
	m.queue_free()
	await create_timer(0.5).timeout
	if not FileAccess.file_exists(BUILT): return {}
	var txt: String = FileAccess.get_file_as_string(BUILT)
	var f := FileAccess.open("user://em_built_%s.json" % ("vr" if vr else "desktop"), FileAccess.WRITE)
	if f: f.store_string(txt)
	var d: Variant = JSON.parse_string(txt)
	return d if d is Dictionary else {}
