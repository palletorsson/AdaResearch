extends SceneTree
## SURVEY, not a gate: where every body in the 10 PRINT hall actually stands, in the hall
## grid's own cells, so a new placement goes where there is room rather than where the
## token grid looks empty. Boots the real endless museum at the hall and reads the grid
## the museum embeds for it.
##
## Prints one line per placed artifact: token, the cell its origin lands in, and the
## x/z extent of its merged mesh AABB in grid-local metres. Then a character map.

var em: Node3D
var gs: Node3D


func _initialize() -> void:
	run.call_deferred()


func _extent(n: Node3D) -> AABB:
	var box := AABB()
	var got := false
	var inv := gs.global_transform.affine_inverse()
	for m in n.find_children("*", "VisualInstance3D", true, false):
		if not (m is MeshInstance3D or m is MultiMeshInstance3D):
			continue
		if not m.is_visible_in_tree():
			continue
		var aabb: AABB = m.get_aabb()
		if aabb.size == Vector3.ZERO:
			continue
		var b: AABB = (inv * m.global_transform) * aabb
		box = b if not got else box.merge(b)
		got = true
	return box if got else AABB(gs.to_local(n.global_position), Vector3.ZERO)


func run() -> void:
	var out := "user://ten_print_survey/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var ctl := out + "control.json"
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "randomness", "dollhouse": 0, "grid_pack": 1}))
	f.close()
	em = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL", ctl)
	em.set("_overrides_path", ctl + ".unused")
	em.set("_hand_path", ctl + ".unused-hand")
	em.set("start_chapter", "randomness")
	em.set("start_map", "Randomness_10_PRINT_Algorithm")
	root.add_child(em)
	current_scene = em
	await create_timer(1.0).timeout
	em.set_process(false)
	em.set_physics_process(false)
	em.call("flush_stamps")
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map", "") == "Randomness_10_PRINT_Algorithm":
			gs = rec.node
	if gs == null:
		for rec: Dictionary in em.get("_segments"):
			var kids: Array = []
			for c in rec.node.get_children():
				kids.append("%s(%s)" % [c.name, c.get_class()])
			print("[survey] segment %s em_map=%s kids=%s" % [rec.node.name, rec.node.get_meta("em_map", "?"), str(kids.slice(0, 14))])
		print("[survey] no embedded grid for the hall")
		quit(1)
		return
	pass
	for frame in 30:
		await physics_frame
	print("[survey] segment ", gs.name, " at ", gs.global_position)
	var rows: Array = []
	for n in gs.find_children("*", "Node3D", true, false):
		if n.get_parent() != gs:
			continue
		var tok := ""
		for k in ["em_token", "artifact_lookup_name", "token", "em_artifact"]:
			if n.has_meta(k):
				tok = str(n.get_meta(k))
				break
		if tok == "":
			if str(n.name).begins_with("Lobby") or str(n.name) in ["ScaleFigure", "Collision"] or n is Light3D:
				continue
			tok = "?" + str(n.name) + " meta=" + str(n.get_meta_list())
		var p: Vector3 = gs.to_local(n.global_position)
		var e: AABB = _extent(n)
		var shapes: int = n.find_children("*", "CollisionShape3D", true, false).size()
		rows.append([tok, p, e, shapes])
		print("[survey] %-26s origin x %6.2f z %6.2f | extent x %6.2f..%6.2f  z %6.2f..%6.2f  y %5.2f..%5.2f | colliders %d" % [
			tok, p.x, p.z, e.position.x, e.end.x, e.position.z, e.end.z, e.position.y, e.end.y, shapes])
	# A character map of footprints, one char per cell, clipped to the hall.
	var W := 13
	var D := 14
	var grid: Array = []
	for z in D:
		var line: Array = []
		for x in W:
			line.append(".")
		grid.append(line)
	var letters := "abcdefghijklmnopqrstuvwxyz"
	var legend := ""
	for i in rows.size():
		var e: AABB = rows[i][2]
		var ch: String = letters[i % letters.length()]
		legend += "  %s = %s\n" % [ch, rows[i][0]]
		for z in range(maxi(0, int(floor(e.position.z))), mini(D, int(ceil(e.end.z)))):
			for x in range(maxi(0, int(floor(e.position.x))), mini(W, int(ceil(e.end.x)))):
				grid[z][x] = ch if grid[z][x] == "." else "*"
	print("[survey] footprint map, x across, z down ('*' = overlap):")
	for z in D:
		print("[survey] %2d  %s" % [z, "".join(grid[z])])
	print(legend)
	quit(0)
