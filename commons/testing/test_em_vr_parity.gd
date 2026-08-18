extends SceneTree
## VR and desktop must build the SAME museum from the same plan: every body at
## the same cell and rotation, the same inventory numbers, the same rulings.
## Built twice in one boot — once with _vr false, once true — and diffed.
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_vr_parity.gd
func _snapshot(m: Node3D) -> Dictionary:
	var out: Dictionary = {}
	for r in (m.get("_edit_records") as Array):
		var rd: Dictionary = r
		if String(rd.get("kind", "artifact")) not in ["artifact", ""]: continue
		var n: Node3D = rd.get("node") as Node3D
		if n == null or not is_instance_valid(n): continue
		out[String(rd.get("token", "")) + "@" + str(rd.get("tile_cell", []))] = {
			"pos": n.global_position, "rot": n.rotation_degrees.y, "inv": rd.get("inv", "")}
	return out
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var fails: Array[String] = []
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var a: Node3D = ps.instantiate() as Node3D
	get_root().add_child(a)
	await create_timer(3.0).timeout
	var desk := _snapshot(a)
	var inv_a: int = (a.get("_inventory") as Array).size()
	get_root().remove_child(a); a.queue_free()
	await create_timer(0.5).timeout
	var b: Node3D = ps.instantiate() as Node3D
	b.set("_vr", true)              # the VR build path, without a headset
	get_root().add_child(b)
	await create_timer(3.0).timeout
	var vr := _snapshot(b)
	var inv_b: int = (b.get("_inventory") as Array).size()
	print("[test] desktop bodies %d · VR bodies %d · inventory %d vs %d" % [desk.size(), vr.size(), inv_a, inv_b])
	if vr.is_empty(): fails.append("VR build recorded no bodies")
	if desk.size() != vr.size(): fails.append("body count differs: desktop %d, VR %d" % [desk.size(), vr.size()])
	if inv_a != inv_b: fails.append("inventory differs: desktop %d, VR %d" % [inv_a, inv_b])
	var moved := 0; var renumbered := 0
	for k in desk:
		if not vr.has(k): fails.append("only on desktop: %s" % k); continue
		var da: Dictionary = desk[k]; var db: Dictionary = vr[k]
		# a RigidBody3D settles by a few mm between two builds; that is physics,
		# not placement — 5 cm and 0.5 degrees is the honest tolerance
		if (da["pos"] as Vector3).distance_to(db["pos"]) > 0.05 or absf(float(da["rot"]) - float(db["rot"])) > 0.5:
			moved += 1
			print("[test] differs: %s  desktop %s rot %.0f  vr %s rot %.0f" % [k, str(da["pos"]), float(da["rot"]), str(db["pos"]), float(db["rot"])])
		if String(da["inv"]) != String(db["inv"]): renumbered += 1
	if moved > 0: fails.append("%d bodies stand differently in VR" % moved)
	if renumbered > 0: fails.append("%d bodies carry a different inventory number in VR" % renumbered)
	get_root().remove_child(b); b.queue_free()
	if fails.is_empty(): print("EM VR PARITY: PASS — %d bodies, same cells, same rotations, same numbers in both modes" % desk.size())
	else:
		print("EM VR PARITY: FAIL %d" % fails.size()); for x in fails.slice(0, 6): print("  - " + x)
	quit(0 if fails.is_empty() else 1)
