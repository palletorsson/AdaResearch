extends SceneTree
## WHAT IS UNDER THE LINE DEMO? Palle: "there is a plinth under the line demo
## but I want it removed so it optional." The token carries no #plinth, the
## structure cell is plain floor, and the grid only builds one on request — so
## whatever it is, the artifact is making it itself. This lists every visible
## mesh with its height, lowest first.

func _init() -> void:
	var D := load("res://commons/primitives/snappoint/demos/line_demo.tscn")
	var d = D.instantiate()
	get_root().add_child(d)
	await process_frame
	await process_frame
	var rows: Array = []
	_walk(d, rows)
	rows.sort_custom(func(a, b): return a["y"] < b["y"])
	print("VISIBLE MESHES, lowest first:")
	for r in rows:
		print("  y=%+6.2f  %-34s %-18s size~%s  visible_in_tree=%s"
			% [r["y"], r["path"], r["cls"], r["size"], r["vis"]])
	quit(0)

func _walk(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is VisualInstance3D:
			var sz := "-"
			if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
				sz = str((c as MeshInstance3D).mesh.get_aabb().size.snapped(Vector3(0.01, 0.01, 0.01)))
			out.append({"y": (c as Node3D).global_position.y,
				"path": str(n.name) + "/" + str(c.name),
				"cls": c.get_class(), "size": sz,
				"vis": (c as VisualInstance3D).is_visible_in_tree()})
		_walk(c, out)
