extends SceneTree
## THE DOLL HOUSE, proven headless: with em_control {"dollhouse":1} the
## desktop camera is ORTHOGRAPHIC and the architecture is cut to knee walls;
## without it, the walk is exactly the walk (perspective, walls whole).
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_dollhouse.gd

const OUT := "res://ada_run/dollhouse_probe.txt"
const CTL := "res://ada_run/em_control.json"

func _initialize() -> void:
	call_deferred("_run")


func _boot(doll: bool) -> Dictionary:
	var f := FileAccess.open(CTL, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "primitives", "first_map": "", "dollhouse": 1 if doll else 0}, " "))
	f.close()
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(inst)
	var r := {}
	return {"inst": inst}


func _tall_visible(seg: Node3D) -> int:
	var tall := 0
	var stack: Array = [seg]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n != seg and n is Node3D and n.has_meta("artifact_lookup_name"):
			continue
		for c in n.get_children():
			stack.append(c)
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null and (n as MeshInstance3D).visible:
			var wb: AABB = (n as MeshInstance3D).global_transform * (n as MeshInstance3D).get_aabb()
			if wb.position.y + wb.size.y > 2.9 and String(n.name) != "DetailExtentAnchor":
				tall += 1
	return tall


func _run() -> void:
	var fails: Array = []
	var ctl_before := FileAccess.get_file_as_string(CTL)

	var a: Node3D = _boot(true)["inst"]
	await create_timer(1.0).timeout
	if not bool(a.get("_dollhouse")):
		fails.append("_dollhouse flag never rose from em_control")
	var cam_a: Camera3D = a.get("_cam")
	if cam_a == null or cam_a.projection != Camera3D.PROJECTION_ORTHOGONAL:
		fails.append("doll house camera is not orthographic")
	var tall_a := 0
	for seg in (a.get("_segments") as Array):
		var sn: Node3D = (seg as Dictionary).get("node")
		if sn != null:
			tall_a += _tall_visible(sn)
	if tall_a > 0:
		fails.append(str(tall_a) + " tall architecture piece(s) still visible in the doll house")
	var cut := 0
	# the pan: carry the doll 30 m along z and wait past the bounds check's
	# 1 s interval — a sleeping check leaves it there; the old bug snapped it home
	var pl: CharacterBody3D = a.get("_player")
	var z0: float = pl.position.z
	pl.position.z += 30.0
	await create_timer(1.6).timeout
	if absf(pl.position.z - (z0 + 30.0)) > 2.0:
		fails.append("the doll was yanked home after a 30 m pan (bounds check awake?) — z %.1f" % pl.position.z)
	a.queue_free()
	await process_frame

	var b: Node3D = _boot(false)["inst"]
	await create_timer(1.0).timeout
	var cam_b: Camera3D = b.get("_cam")
	if cam_b == null or cam_b.projection != Camera3D.PROJECTION_PERSPECTIVE:
		fails.append("the plain walk lost its perspective camera")
	var tall_b := 0
	for seg in (b.get("_segments") as Array):
		var sn: Node3D = (seg as Dictionary).get("node")
		if sn != null:
			tall_b += _tall_visible(sn)
	if tall_b == 0:
		fails.append("the plain walk has NO tall walls — the cut leaked into it")
	b.queue_free()

	var f2 := FileAccess.open(CTL, FileAccess.WRITE)
	f2.store_string(ctl_before)
	f2.close()
	var f3 := FileAccess.open(OUT, FileAccess.WRITE)
	f3.store_string("PASS" if fails.is_empty() else "FAIL: " + "; ".join(fails))
	f3.close()
	print("DOLL HOUSE: " + ("PASS — the house opens, the walk untouched" if fails.is_empty() else "FAIL " + "; ".join(fails)))
	quit(0 if fails.is_empty() else 1)
