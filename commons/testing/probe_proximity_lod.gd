# probe_proximity_lod.gd — the computation budget, proven headless.
# 1 compile: GridSystem / GridInteractablesComponent / ProximityLOD resolve
# 2 unit: artifact beyond radius freezes (PROCESS_MODE_DISABLED); near wakes
# 3 negative: config proximity_lod:false is never frozen
# 4 negative: no camera -> nothing freezes (captures unaffected)
# 5 live-gate negative: a map WITHOUT settings.proximity_lod gets NO manager
#   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_proximity_lod.gd
extends SceneTree

const PLOD := preload("res://commons/grid/ProximityLOD.gd")

var _fail := 0
var _log: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _check(name: String, ok: bool, detail: String = "") -> void:
	var line := ("PASS  " if ok else "FAIL  ") + name + ("  " + detail if detail != "" else "")
	print(line)
	_log.append(line)
	if not ok:
		_fail += 1


func _run() -> void:
	var gs = load("res://commons/grid/GridSystem.gd")
	var gic = load("res://commons/grid/GridInteractablesComponent.gd")
	_check("compile: GridSystem", gs != null)
	_check("compile: GridInteractablesComponent", gic != null)
	_check("compile: ProximityLOD", PLOD != null)

	# rig: camera + manager (tight radius, tiny grace) + two artifacts
	var world := Node3D.new()
	get_root().add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.current = true
	cam.global_position = Vector3(0, 1, 0)
	var mgr = PLOD.new()
	mgr.configure({"radius": 5.0, "hysteresis": 1.0, "grace_s": 0.3})
	world.add_child(mgr)

	var far := Node3D.new()
	world.add_child(far)
	far.global_position = Vector3(30, 0, 0)
	far.add_to_group("vr_editable_artifact")
	var optout := Node3D.new()
	world.add_child(optout)
	optout.global_position = Vector3(40, 0, 0)
	optout.set_meta("config_proximity_lod", "false")
	optout.add_to_group("vr_editable_artifact")

	await create_timer(1.5).timeout      # grace + a few ticks
	_check("unit: far artifact frozen",
			far.process_mode == Node.PROCESS_MODE_DISABLED, str(far.process_mode))
	_check("negative: opt-out stays awake",
			optout.process_mode != Node.PROCESS_MODE_DISABLED)

	cam.global_position = Vector3(29, 1, 0)   # within radius of `far`
	await create_timer(1.0).timeout
	_check("unit: near artifact wakes",
			far.process_mode != Node.PROCESS_MODE_DISABLED, str(far.process_mode))

	# no camera -> nothing freezes
	cam.current = false
	cam.queue_free()
	var far2 := Node3D.new()
	world.add_child(far2)
	far2.global_position = Vector3(90, 0, 0)
	far2.add_to_group("vr_editable_artifact")
	await create_timer(1.2).timeout
	_check("negative: no camera, never frozen",
			far2.process_mode != Node.PROCESS_MODE_DISABLED)
	world.queue_free()

	# live gate negative: an unflagged map spawns NO ProximityLOD manager
	change_scene_to_file("res://commons/maps/catalog/MapCatalogDesktop3D.tscn")
	await process_frame
	await process_frame
	var catalog: Node = current_scene
	if catalog == null or not catalog.has_method("load_map_fresh"):
		_check("live: map catalog available", false)
	else:
		catalog.call("load_map_fresh", "Tutorial_Single")
		for i in range(150):
			await process_frame
		var found := false
		var stack: Array = [catalog]
		while not stack.is_empty():
			var cur: Node = stack.pop_back()
			if cur.name == "ProximityLOD":
				found = true
			for c in cur.get_children():
				stack.append(c)
		_check("live-gate: unflagged map has NO ProximityLOD", not found)

	print("DONE probe_proximity_lod — %d failures" % _fail)
	var of := FileAccess.open("res://doc/reports/probe_proximity_lod.json", FileAccess.WRITE)
	of.store_string(JSON.stringify({"failures": _fail, "log": _log}, " "))
	of.close()
	quit(_fail)
