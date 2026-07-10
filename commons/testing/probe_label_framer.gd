# probe_label_framer.gd — headless proof that hanging labels get bodies.
# 1 compile: LabelFramer + GridInteractablesComponent scripts resolve
# 2 unit: single_cube (billboarded labels) -> framed, billboard off, plates on
# 3 negative: framed_labels:false opt-out leaves labels untouched
# 4 negative: a non-billboard Label3D is never framed
# 5 live: Tutorial_Single loads through GridSystem and its spawned artifacts
#         carry label_framed markers (the component hook fires)
#   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_label_framer.gd
extends SceneTree

const LabelFramer := preload("res://commons/grid/LabelFramer.gd")

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


func _count_framed(root: Node) -> Array:
	var framed := 0
	var labels := 0
	var stack: Array = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if cur is Label3D:
			labels += 1
			if cur.has_meta("label_framed"):
				framed += 1
		for c in cur.get_children():
			stack.append(c)
	return [labels, framed]


func _run() -> void:
	# 1 compile
	var gic = load("res://commons/grid/GridInteractablesComponent.gd")
	_check("compile: GridInteractablesComponent", gic != null)
	_check("compile: LabelFramer", LabelFramer != null)

	# 2 unit — single_cube has billboarded labels
	var packed = load("res://algorithms/arrays/single_cube.tscn")
	if packed == null:
		packed = load("res://algorithms/arrays/single_cube.gd")
	var inst: Node3D = null
	if packed is PackedScene:
		inst = packed.instantiate()
	else:
		inst = Node3D.new()
		inst.set_script(packed)
	get_root().add_child(inst)
	await create_timer(0.3).timeout
	var n := LabelFramer.frame_labels(inst)
	var counts := _count_framed(inst)
	_check("unit: framed >= 1 on single_cube", n >= 1,
			"framed=%d labels=%d" % [n, counts[0]])
	var all_off := true
	var plates_ok := true
	var stack: Array = [inst]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if cur is Label3D and cur.has_meta("label_framed"):
			if cur.billboard != BaseMaterial3D.BILLBOARD_DISABLED:
				all_off = false
			var mi := 0
			for c in cur.get_children():
				if c is MeshInstance3D:
					mi += 1
			if mi < 2:
				plates_ok = false
		for c in cur.get_children():
			stack.append(c)
	_check("unit: billboard disabled on framed", all_off)
	_check("unit: bezel+panel plates added", plates_ok)
	var again := LabelFramer.frame_labels(inst)
	_check("unit: idempotent (second pass frames 0)", again == 0, str(again))
	inst.queue_free()

	# 3 negative — opt-out
	var inst2: Node3D = null
	if packed is PackedScene:
		inst2 = packed.instantiate()
	else:
		inst2 = Node3D.new()
		inst2.set_script(packed)
	inst2.set_meta("config_framed_labels", "false")
	get_root().add_child(inst2)
	await create_timer(0.3).timeout
	var n2 := LabelFramer.frame_labels(inst2)
	_check("negative: opt-out frames 0", n2 == 0, str(n2))
	inst2.queue_free()

	# 4 negative — non-billboard label untouched
	var holder := Node3D.new()
	var flat := Label3D.new()
	flat.text = "engraved"
	flat.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	holder.add_child(flat)
	get_root().add_child(holder)
	var n3 := LabelFramer.frame_labels(holder)
	_check("negative: surface label untouched", n3 == 0 and not flat.has_meta("label_framed"))
	holder.queue_free()

	# 5 live — the real map path (catalog pattern, per probe_yah_in_map)
	change_scene_to_file("res://commons/maps/catalog/MapCatalogDesktop3D.tscn")
	await process_frame
	await process_frame
	var catalog: Node = current_scene
	if catalog == null or not catalog.has_method("load_map_fresh"):
		_check("live: map catalog available", false)
	else:
		catalog.call("load_map_fresh", "Tutorial_Single")
		for i in range(180):
			await process_frame
		var live := _count_framed(catalog)
		_check("live: Tutorial_Single spawns framed labels", live[1] >= 1,
				"labels=%d framed=%d" % [live[0], live[1]])
	print("DONE probe_label_framer — %d failures" % _fail)
	var of := FileAccess.open("res://doc/reports/probe_label_framer.json", FileAccess.WRITE)
	of.store_string(JSON.stringify({"failures": _fail, "log": _log}, " "))
	of.close()
	quit(_fail)
