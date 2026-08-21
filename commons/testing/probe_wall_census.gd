extends SceneTree
## WHO ARE THE WALLS? Everything tall in segment 0, by class, name, parent.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var f0 := FileAccess.open("res://ada_run/em_control.json", FileAccess.WRITE)
	f0.store_string(JSON.stringify({"first_chapter": "primitives", "first_map": "", "dollhouse": 1}, " "))
	f0.close()
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(inst)
	await create_timer(1.0).timeout
	var seg: Node3D = ((inst.get("_segments") as Array)[0] as Dictionary).get("node")
	var talls: Array = []
	_walk(seg, talls)
	talls.sort_custom(func(a, b): return float(a["top"]) > float(b["top"]))
	var lines: Array = []
	for t in talls.slice(0, 20):
		lines.append("%.1f m top · %s '%s' under '%s' · artifact=%s" % [t["top"], t["cls"], t["name"], t["parent"], t.get("artifact", "")])
	var fr := FileAccess.open("res://ada_run/em_control.json", FileAccess.WRITE)
	fr.store_string(JSON.stringify({"first_chapter": "primitives", "first_map": "", "dollhouse": 0}, " "))
	fr.close()
	var f := FileAccess.open("res://ada_run/wall_census.txt", FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	quit(0)
func _walk(n: Node, out_list: Array) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null and (n as MeshInstance3D).is_visible_in_tree():
		var aabb: AABB = (n as MeshInstance3D).get_aabb()
		var top: float = ((n as Node3D).global_transform * aabb).get_support(Vector3.UP).y
		if top > 1.5:
			var anc := ""
			var w: Node = n
			while w != null:
				if w.has_meta("artifact_lookup_name"):
					anc = String(w.get_meta("artifact_lookup_name"))
					break
				w = w.get_parent()
			out_list.append({"top": top, "cls": "MeshInstance3D", "name": n.name, "parent": n.get_parent().name, "artifact": anc})
	elif n is MultiMeshInstance3D:
		var mm := (n as MultiMeshInstance3D).multimesh
		var hi: float = -1e9
		if mm != null:
			for i in range(mm.instance_count):
				var t := mm.get_instance_transform(i)
				hi = maxf(hi, ((n as Node3D).global_transform * t).origin.y + t.basis.y.length() * 0.5)
		if hi > 1.5:
			out_list.append({"top": hi, "cls": "MultiMesh(" + str(mm.instance_count) + ")", "name": n.name, "parent": n.get_parent().name})
	for c in n.get_children():
		_walk(c, out_list)
