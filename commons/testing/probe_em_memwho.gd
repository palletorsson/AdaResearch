extends SceneTree
## WHO EATS THE MEMORY — attribution by arithmetic, not squint.
## Measures static-memory deltas for: parsing em_plan.json, parsing
## trunk_branches.json, and instantiating ONE of each heavy first-room token.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_em_memwho.gd

const TOKENS := ["matrix_4x4_viewer", "invariants_demo", "transform_composition_workbench",
	"stepped_transform", "y_translation_cube", "homogeneous_coordinates", "dark_sphere"]

func _initialize() -> void:
	call_deferred("_run")


func _mb() -> float:
	return float(OS.get_static_memory_usage()) / 1048576.0


func _run() -> void:
	var report: Dictionary = {}
	var m0 := _mb()
	var plan_txt := FileAccess.get_file_as_string("res://ada_run/em_plan.json")
	var m1 := _mb()
	var plan_v: Variant = JSON.parse_string(plan_txt)
	var m2 := _mb()
	report["plan_text_mb"] = snappedf(m1 - m0, 0.1)
	report["plan_parsed_mb"] = snappedf(m2 - m1, 0.1)
	var trunk_txt := FileAccess.get_file_as_string("res://commons/data/trunk_branches.json")
	var m3 := _mb()
	var trunk_v: Variant = JSON.parse_string(trunk_txt)
	var m4 := _mb()
	report["trunk_parsed_mb"] = snappedf(m4 - m3, 0.1)
	# registry: what does the scene path lookup cost to find?
	var reg: Dictionary = {}
	var dir := DirAccess.open("res://commons/artifacts/registry")
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var v: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/registry/" + f))
		if v is Dictionary:
			var arts: Variant = (v as Dictionary).get("artifacts", v)
			if arts is Dictionary:
				for tok in (arts as Dictionary):
					var e: Variant = (arts as Dictionary)[tok]
					if e is Dictionary:
						var sp := String((e as Dictionary).get("scene_path", (e as Dictionary).get("scene", "")))
						if sp != "" and not reg.has(tok):
							reg[tok] = sp
	var m5 := _mb()
	report["registry_parsed_mb"] = snappedf(m5 - m4, 0.1)
	var rows: Array = []
	for tok in TOKENS:
		var path: String = reg.get(tok, "")
		if path == "" or not ResourceLoader.exists(path):
			rows.append({"token": tok, "why": "no scene"})
			continue
		var a := _mb()
		var t0 := Time.get_ticks_msec()
		var ps: PackedScene = load(path)
		var b := _mb()
		var inst: Node3D = ps.instantiate() as Node3D
		get_root().add_child(inst)
		await process_frame
		await process_frame
		var c := _mb()
		rows.append({"token": tok, "load_mb": snappedf(b - a, 0.1),
			"ready_mb": snappedf(c - b, 0.1), "ms": Time.get_ticks_msec() - t0,
			"nodes": _count(inst)})
		inst.queue_free()
		await process_frame
	report["tokens"] = rows
	# keep the parses alive so the deltas are honest
	report["_holds"] = [typeof(plan_v), typeof(trunk_v)]
	var f2 := FileAccess.open("res://ada_run/em_memwho.json", FileAccess.WRITE)
	f2.store_string(JSON.stringify(report, " "))
	f2.close()
	print(JSON.stringify(report, " "))
	quit(0)


func _count(n: Node) -> int:
	var c := 1
	for ch in n.get_children():
		c += _count(ch)
	return c
