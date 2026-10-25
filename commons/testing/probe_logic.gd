extends SceneTree
## The logic machines check their own truth tables. Every term in terms.json that carries a
## `logic` block declares its frame, the movers the physics frees, its named inputs (what
## drops where), its named outputs (regions) and its cases. For each case this probe builds
##   step(frame + always-parts + the case's inputs, physics)
## runs the physics for `ticks`, and reads each output as "some freed body ended inside the
## region". A case passes when every output matches its expectation. A change to the geometry
## changes the truth conditions of the machine — that is the lesson, and this is its check.
## Report: ada_run/logic_truth_<hz>hz.json. Run at --hz=60 and --hz=90 (the headset's rate).
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_logic.gd [-- --only=or_gate] [--hz=90]

var _only := ""
var _hz := 60
var _terms_path := "res://commons/modular/terms.json"

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			_only = a.trim_prefix("--only=")
		elif a.begins_with("--hz="):
			_hz = int(a.trim_prefix("--hz="))
		elif a.begins_with("--terms="):
			_terms_path = a.trim_prefix("--terms=")   # a mutant copy, to see the check bite
	# the headset steps physics at 90 Hz, the desktop at 60: a machine must hold at both
	Engine.physics_ticks_per_second = _hz
	call_deferred("_run")


func _bodies(root: Node) -> Array:
	var out: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_front()
		if n is RigidBody3D:
			out.append(n)
		for c in n.get_children():
			stack.append(c)
	return out


func _inside(p: Vector3, region: Dictionary) -> bool:
	var lo: Array = region["min"]
	var hi: Array = region["max"]
	return p.x >= float(lo[0]) and p.x <= float(hi[0]) and p.y >= float(lo[1]) and p.y <= float(hi[1]) and p.z >= float(lo[2]) and p.z <= float(hi[2])


var _terms: Dictionary = {}

func _case(logic: Dictionary, case: Dictionary) -> Dictionary:
	# the frame is built from the terms file THIS probe loaded, not by name: a {"t": frame}
	# reference is resolved by the composite from res://commons/modular/terms.json, so a
	# mutant frame would never reach the physics (it did not, 2026-10-25: a walled AND cup
	# "passed" because the real lip was built)
	var parts: Array = [_terms[logic["frame"]]["build"]]
	parts.append_array(logic.get("always", []))
	var inputs: Dictionary = logic["inputs"]
	for name in case["in"]:
		var inp: Dictionary = inputs[name]
		parts.append({"op": "transform", "of": {"t": inp["t"]}, "at": inp["at"]})
	var expr := {"op": "engine", "kind": "physics", "free": logic.get("free", ["ball"]), "of": {"op": "compose", "parts": parts}}
	var scene: PackedScene = load("res://commons/modular/composite.tscn")
	var thing: Node = scene.instantiate()
	thing.set("expression", JSON.stringify(expr))
	root.add_child(thing)
	await process_frame
	await process_frame
	# `ticks` are written at 60 Hz; the same seconds of physics at any rate
	for i in range(int(float(logic.get("ticks", 300)) * _hz / 60.0)):
		await physics_frame
	var bodies: Array = _bodies(thing)
	var got := {}
	var finals: Array = []
	for b in bodies:
		var q: Vector3 = (b as Node3D).global_position
		finals.append({"term": str(b.get_meta("term", "")), "at": [snapped(q.x, 0.01), snapped(q.y, 0.01), snapped(q.z, 0.01)]})
	var outputs: Dictionary = logic["outputs"]
	for out_name in outputs:
		var hit := false
		for b in bodies:
			# a domino line counts only dominoes; a ball machine counts the movers
			if _inside((b as Node3D).global_position, outputs[out_name]):
				hit = true
		got[out_name] = hit
	var pass_ := true
	for k in case["expect"]:
		if bool(got.get(k, false)) != bool(case["expect"][k]):
			pass_ = false
	thing.queue_free()
	await process_frame
	return {"in": case["in"], "expect": case["expect"], "got": got, "pass": pass_, "bodies": finals}


func _run() -> void:
	var f := FileAccess.open(_terms_path, FileAccess.READ)
	var terms: Dictionary = (JSON.parse_string(f.get_as_text()) as Dictionary)["terms"]
	_terms = terms
	var report := {"probe": "logic", "physics_hz": Engine.physics_ticks_per_second, "machines": {}}
	var all_ok := true
	var n_cases := 0
	var n_pass := 0
	for name in terms:
		var t: Dictionary = terms[name]
		if not t.has("logic") or (_only != "" and name != _only):
			continue
		var rows: Array = []
		for case in t["logic"]["cases"]:
			var r: Dictionary = await _case(t["logic"], case)
			rows.append(r)
			n_cases += 1
			if r["pass"]:
				n_pass += 1
			else:
				all_ok = false
			print("LOGIC %-12s in=%-22s expect=%s got=%s %s" % [name, str(r["in"]), str(r["expect"]), str(r["got"]), "ok" if r["pass"] else "FAIL"])
		report["machines"][name] = rows
	report["ok"] = all_ok
	report["cases"] = n_cases
	report["passed"] = n_pass
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ada_run"))
	# only a full run on the real terms writes the report the pages read; a mutant or a
	# single machine writes beside it (a mutant once overwrote it and the page showed its failure)
	var tag := ""
	if _terms_path != "res://commons/modular/terms.json":
		tag = "_mutant"
	elif _only != "":
		tag = "_" + _only
	var w := FileAccess.open("res://ada_run/logic_truth_%dhz%s.json" % [_hz, tag], FileAccess.WRITE)
	w.store_string(JSON.stringify(report, "  "))
	w.close()
	print("LOGIC_TRUTH hz=%d ok=%s %d/%d cases" % [_hz, all_ok, n_pass, n_cases])
	quit(0 if all_ok else 1)
