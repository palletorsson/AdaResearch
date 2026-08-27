extends SceneTree
## The VR floor body, proven both ways in one boot.
##
## The desktop walker CLAMPS y, so museum floors were meshes with no collider —
## invisible until the staging pass put the XR rig's gravity-simulating
## PlayerBody on that deck. The fix stamps floor colliders GATED ON _vr.
## This test asserts the gate bites in both directions:
##   VR build      → floor-level CollisionShape3D count is large (the deck is a body)
##   desktop build → the SAME CURRENT-HALL count. VR now keeps lightweight
##                   neighbour shells for spatial safety, so counting the whole
##                   scene would intentionally count two or three decks.
## Floor-level means shape position y < 0.0: floor slabs sit at -0.1 and the
## balcony catch slab at -4.1, while every pre-existing collider (walls 1.5,
## podiums 0.1, plinths 0.3, parapets 0.55) sits at or above 0.1.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_vr_floor.gd

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array[String] = []

	var n_vr: int = await _floor_cols(true)
	var n_desk: int = await _floor_cols(false)

	if n_vr < 50:
		fails.append("VR build stamped only %d floor colliders — the deck is still not a body" % n_vr)
	if n_desk != n_vr:
		fails.append("desktop build stamped %d floor colliders, VR %d — one museum in both modes means the same deck" % [n_desk, n_vr])

	if fails.is_empty():
		print("VR FLOOR: PASS — vr=%d floor colliders, desktop=%d (the same deck)" % [n_vr, n_desk])
	else:
		print("VR FLOOR: FAIL %d" % fails.size())
		for f in fails:
			print("  - " + f)
	quit(0 if fails.is_empty() else 1)


func _floor_cols(vr: bool) -> int:
	# The VR path waits for a headset rig before streaming (by design), so the
	# VR half of this test stands up a bare XROrigin3D + XRCamera3D — enough
	# for _vr_eye() to find, no XR interface needed headless.
	var rig: XROrigin3D = null
	if vr:
		rig = XROrigin3D.new()
		var eye := XRCamera3D.new()
		rig.add_child(eye)
		rig.position = Vector3(7.5, 0.0, 0.5)
		eye.position = Vector3(0, 1.7, 0)
		get_root().add_child(rig)
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("_force_vr", vr)
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(inst)
	for i in range(5):
		await create_timer(0.2).timeout
	# Compare one hall to one hall. The VR scene deliberately carries neighbour
	# architecture shells now; their extra floors are the feature this regression
	# must not mistake for a desktop/VR parity failure.
	var count_root: Node = inst
	if vr:
		var current_v: Variant = inst.get("_vr_current_node")
		if current_v != null and is_instance_valid(current_v):
			count_root = current_v as Node
		else:
			var vr_segs: Array = inst.get("_segments")
			if not vr_segs.is_empty():
				count_root = (vr_segs[0] as Dictionary).get("node") as Node
	else:
		var desk_segs: Array = inst.get("_segments")
		if not desk_segs.is_empty():
			count_root = (desk_segs[0] as Dictionary).get("node") as Node
	var n: int = _count(count_root)
	get_root().remove_child(inst)
	inst.queue_free()
	if rig != null:
		get_root().remove_child(rig)
		rig.queue_free()
	await create_timer(0.2).timeout
	return n


func _count(n: Node) -> int:
	# Only shapes on the SEGMENT'S own "Collision" StaticBody count. Stamped
	# artifact scenes carry their own internal colliders at whatever local y
	# they like (the first run of this test found five below zero on the
	# desktop build and read them as a gate leak) — those are the artifacts'
	# business, not the floor's.
	var total: int = 0
	if n is CollisionShape3D and (n as Node3D).position.y < 0.0 \
			and n.get_parent() is StaticBody3D \
			and n.get_parent().name == "Collision":
		total += 1
	for c in n.get_children():
		total += _count(c)
	return total
