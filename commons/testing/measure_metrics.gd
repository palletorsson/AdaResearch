# measure_metrics.gd — THE EM-SQUARE MEASURER: every housed artifact testifies
# about its own body, headless. Font metrics for artifacts (Wang tiles gave
# the space its edge contract; this gives the artifact its base contract):
#   anchor_y   distance from the scene origin DOWN to the visual base
#              (origin-at-base = 0.0; origin-at-centre of a 1m thing = 0.5)
#   size       visual AABB [w, h, d] in the rest pose
#   pose       flat | standing | volume  (from aspect at rest)
#   base       floor | float  (does the visual base sit near y=0?)
# Output: doc/reports/artifact_metrics_measured.json — merged into the
# declarations by `principal_artifacts.py --metrics` (declared beats measured).
#   godot --path . --xr-mode off --no-window --script res://commons/testing/measure_metrics.gd
extends SceneTree

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# subjects: every declared principal's canonical scene + every override
	# artifact + kin members that are housed. Read the declarations.
	var f := FileAccess.open("res://commons/data/principal_artifacts.json", FileAccess.READ)
	var decl: Dictionary = JSON.parse_string(f.get_as_text())
	f.close()
	var subjects := {}          # name -> scene path
	var reg := _load_registry()
	for pname in decl.get("principals", {}):
		var p: Dictionary = decl["principals"][pname]
		subjects[pname] = str(p.get("scene", ""))
	for oname in decl.get("artifact_overrides", {}):
		if oname.begins_with("_"):
			continue
		if reg.has(oname):
			subjects[oname] = str(reg[oname])
	for kname in decl.get("kin", {}):
		var k: Dictionary = decl["kin"][kname]
		# measure_all: true → every member testifies (bench-cluster onboarding);
		# measure_skip lists known headless-hangers (watchdog-killed → skipped).
		var all: bool = bool(k.get("measure_all", false))
		var skip: Array = k.get("measure_skip", [])
		for m in k.get("members", []):
			if skip.has(m):
				continue
			if reg.has(m) and not subjects.has(m):
				subjects[m] = str(reg[m])
				if not all:
					break               # one representative per kin

	var holder := Node3D.new()
	get_root().add_child(holder)
	var results := {}
	var failed := []
	# convergent loop: preload prior measurements (pass --fresh to remeasure
	# everything) and store incrementally, so a watchdog kill loses nothing.
	var fresh := OS.get_cmdline_user_args().has("--fresh")
	if not fresh and FileAccess.file_exists("res://doc/reports/artifact_metrics_measured.json"):
		var pf := FileAccess.open("res://doc/reports/artifact_metrics_measured.json", FileAccess.READ)
		var prior = JSON.parse_string(pf.get_as_text())
		pf.close()
		if prior is Dictionary and prior.get("metrics") is Dictionary:
			results = prior["metrics"]
	for name in subjects:
		if results.has(name):
			continue                        # already testified in a prior run
		var path: String = subjects[name]
		# announce BEFORE instantiating: on a watchdog kill the last
		# "measuring" line names the hanger for measure_skip.
		print("measuring ", name)
		if path == "" or not ResourceLoader.exists(path):
			failed.append(name)
			continue
		var packed = load(path)
		if packed == null:
			failed.append(name)
			continue
		var inst = packed.instantiate()
		if not (inst is Node3D):
			if inst:
				inst.free()
			failed.append(name)
			continue
		holder.add_child(inst)
		await create_timer(0.25).timeout
		var aabb := _combined_aabb(inst)
		if aabb.size.length() < 0.001:
			results[name] = {"unmeasurable": true}
		else:
			var w := aabb.size.x
			var h := aabb.size.y
			var dd := aabb.size.z
			var base_y := aabb.position.y
			var pose := "volume"
			var thin: float = min(w, dd)
			if h < 0.3 and max(w, dd) >= 0.6:
				pose = "flat"
			elif thin <= 0.2 * max(max(w, dd), h) and h >= 0.5:
				pose = "standing"
			results[name] = {
				"anchor_y": snappedf(-base_y, 0.01),
				"size": [snappedf(w, 0.01), snappedf(h, 0.01), snappedf(dd, 0.01)],
				"pose": pose,
				"base": "floor" if absf(base_y) < 0.15 else "float",
			}
		print("measured ", name, " -> ", JSON.stringify(results.get(name, {})))
		_store(results, failed)
		inst.queue_free()
		await create_timer(0.05).timeout

	_store(results, failed)
	print("DONE — %d measured, %d failed" % [results.size(), failed.size()])
	quit(0)


func _store(results: Dictionary, failed: Array) -> void:
	var out := {"_note": "measured em-square metrics (rest pose, headless); declared metrics in principal_artifacts.json win on merge",
		"metrics": results, "failed": failed}
	var of := FileAccess.open("res://doc/reports/artifact_metrics_measured.json", FileAccess.WRITE)
	of.store_string(JSON.stringify(out, " "))
	of.close()


func _load_registry() -> Dictionary:
	var out := {}
	var dir := DirAccess.open("res://commons/artifacts/registry/")
	if dir == null:
		return out
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".json"):
			var file := FileAccess.open("res://commons/artifacts/registry/" + f, FileAccess.READ)
			if file:
				var parsed = JSON.parse_string(file.get_as_text())
				if parsed is Dictionary:
					var arts: Dictionary = parsed.get("artifacts", {})
					for k in arts:
						var e = arts[k]
						if e is Dictionary and e.get("scene"):
							out[e.get("lookup_name", k)] = e["scene"]
		f = dir.get_next()
	return out


func _combined_aabb(node: Node3D) -> AABB:
	var aabb := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var cur = stack.pop_back()
		if cur is VisualInstance3D:
			var a: AABB = cur.global_transform * cur.get_aabb()
			if first:
				aabb = a
				first = false
			else:
				aabb = aabb.merge(a)
		for child in cur.get_children():
			stack.append(child)
	return aabb
