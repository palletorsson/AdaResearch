## probe_forces_casting.gd — two questions the critic raised, answered without a camera.
##
## 1. drag_corridor's swimmer axis read as a TWIN (dart == extinguisher, focus 3.75%).
##    A twin can be a small change OR an unreached value — Object.set() on a typed
##    property refuses in silence, and the sweep sets values pre-add. So: instantiate
##    both ways, count meshes. Three extinguishers are ~30 meshes; three dart spheres
##    are 3. The counts cannot lie.
## 2. prop_mobile measured subject 0.56% of frame — an AABB hog. Rank its meshes by
##    world diagonal (probe_aabb_hogs' method, 0.5 s settle) and print the union.
##
## Writes user://forces_casting_probe.json.
extends SceneTree

func _initialize() -> void:
	_run()

func _run() -> void:
	var report := {}

	# --- 1: does the swimmer value take? -----------------------------------------
	for value in ["dart", "extinguisher"]:
		var packed: PackedScene = load("res://commons/artifacts/drag_corridor/drag_corridor.tscn")
		var inst: Node = packed.instantiate()
		inst.set("swimmer", value)          # pre-add, exactly as the sweep does
		root.add_child(inst)
		for i in range(30):
			await process_frame
		report["corridor_" + value] = {
			"swimmer_readback": str(inst.get("swimmer")),
			"meshes": _count_meshes(inst),
		}
		inst.queue_free()
		await process_frame
		await process_frame

	# --- 2: what inflates prop_mobile's box? -------------------------------------
	var packed2: PackedScene = load("res://commons/artifacts/prop_mobile/prop_mobile.tscn")
	var mob: Node = packed2.instantiate()
	root.add_child(mob)
	for i in range(30):
		await process_frame
	var rows: Array = []
	var union := AABB()
	var first := true
	var stack: Array = [mob]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var box: AABB = mi.global_transform * mi.get_aabb()
			union = box if first else union.merge(box)
			first = false
			rows.append({"path": str(mi.get_path()).right(60), "diag": snappedf(box.size.length(), 0.01),
				"pos": [snappedf(box.position.x, 0.1), snappedf(box.position.y, 0.1), snappedf(box.position.z, 0.1)]})
		for c in n.get_children():
			stack.append(c)
	rows.sort_custom(func(a, b): return a["diag"] > b["diag"])
	report["mobile_union"] = [snappedf(union.size.x, 0.01), snappedf(union.size.y, 0.01), snappedf(union.size.z, 0.01)]
	report["mobile_union_pos"] = [snappedf(union.position.x, 0.1), snappedf(union.position.y, 0.1), snappedf(union.position.z, 0.1)]
	report["mobile_top_meshes"] = rows.slice(0, 6)
	mob.queue_free()

	var f := FileAccess.open("user://forces_casting_probe.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	quit(0)

func _count_meshes(node: Node) -> int:
	var n := 0
	var stack: Array = [node]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		if x is MeshInstance3D:
			n += 1
		for c in x.get_children():
			stack.append(c)
	return n
