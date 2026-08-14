extends SceneTree
## The VR floor body, proven both ways in one boot.
##
## The desktop walker CLAMPS y, so museum floors were meshes with no collider —
## invisible until the staging pass put the XR rig's gravity-simulating
## PlayerBody on that deck. The fix stamps floor colliders GATED ON _vr.
## This test asserts the gate bites in both directions:
##   VR build      → floor-level CollisionShape3D count is large (the deck is a body)
##   desktop build → floor-level CollisionShape3D count is ZERO (byte-identical v1)
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
	if n_desk != 0:
		fails.append("desktop build stamped %d floor colliders — the _vr gate leaks" % n_desk)

	if fails.is_empty():
		print("VR FLOOR: PASS — vr=%d floor colliders, desktop=0" % n_vr)
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
	var n: int = _count(inst)
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
