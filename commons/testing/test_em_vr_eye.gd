extends SceneTree
## THE VR EYE, with TWO rigs in the tree — as the shipped loop has them: the
## staging's own XROrigin3D (parked at the menu, not current) and the loaded
## scene's (current, driven by the visitor). The museum must follow the CURRENT
## one; following the parked one is exactly "VR loads one map and fewer
## artifacts" (nothing streams, everything far from a dead eye is culled).
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_vr_eye.gd
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var fails: Array[String] = []
	# the parked staging rig, first in the tree
	var parked := XROrigin3D.new(); parked.name = "StagingOrigin"; parked.current = false
	var pcam := XRCamera3D.new(); parked.add_child(pcam)
	get_root().add_child(parked)
	parked.global_position = Vector3(100, 0, -50)          # the menu, far away
	# the loaded scene's rig, current, at the museum spawn
	var live := XROrigin3D.new(); live.name = "SceneOrigin"; live.current = true
	var body := Node3D.new(); body.name = "PlayerBody"      # the camera nested one deeper, as base.tscn nests it
	var lcam := XRCamera3D.new(); body.add_child(lcam); live.add_child(body)
	get_root().add_child(live)
	live.global_position = Vector3(7.5, 0, 1.5)
	lcam.position = Vector3(0, 1.7, 0)
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_force_vr", true)
	get_root().add_child(m)
	await create_timer(3.0).timeout
	var eye: Camera3D = m.call("_vr_eye")
	if eye != lcam:
		fails.append("the museum's eye is %s, not the CURRENT rig's camera" % (str(eye.get_path()) if eye else "null"))
	# now WALK the live rig 400 m and count segments, exactly the desktop stream test
	var seg0: int = int(m.get("_seg_index"))
	for i in range(34):
		live.global_position.z += 12.0
		await process_frame; await process_frame
		if i % 8 == 0:
			print("[probe] rig z=%.0f body z=%.0f cam z=%.0f (cam local %s) museum eye=%s next_z=%.0f segs=%d" % [live.global_position.z, body.global_position.z, lcam.global_position.z, str(lcam.position), str(m.call("_eye_pos")), float(m.get("_next_z")), int(m.get("_seg_index"))])
	var built: int = int(m.get("_seg_index"))
	print("[test] eye=%s · segments %d -> %d after walking the CURRENT rig 400 m" % [str(eye.get_path()) if eye else "null", seg0, built])
	if built - seg0 < 4:
		fails.append("VR did not stream: %d -> %d segments" % [seg0, built])
	# and the culling follows the live eye, not the parked one: bodies near the rig must be running.
	# THE CULL RUNS ON A 0.3 s TIMER, and this walk is 68 process frames — headless they
	# pass in far less than the ten seconds of ticks the walk would take in the world, so
	# reading straight after the last step measured the timer, not the eye (14 bodies
	# beside the rig, 2 running, twice in a row). Give it one real tick, then ask.
	await create_timer(0.4).timeout
	m.call("_cull_artifacts")
	var near_running := 0; var near_total := 0
	for r in (m.get("_vis_records") as Array):
		var nv: Variant = (r as Dictionary).get("node")
		if nv == null or not is_instance_valid(nv): continue     # freed with its segment: valid FIRST, cast after
		var n: Node3D = nv as Node3D
		if Vector2(n.global_position.x - live.global_position.x, n.global_position.z - live.global_position.z).length() < 25.0:
			near_total += 1
			if n.visible and n.process_mode != Node.PROCESS_MODE_DISABLED: near_running += 1
	print("[test] bodies within 25 m of the live rig: %d, running %d" % [near_total, near_running])
	if near_total > 0 and near_running < near_total / 2:
		fails.append("bodies beside the visitor are culled — the cull follows the wrong eye")
	get_root().remove_child(m); m.queue_free()
	if fails.is_empty(): print("EM VR EYE: PASS — follows the current rig; streamed %d segments; bodies beside the visitor run" % (built - seg0))
	else:
		print("EM VR EYE: FAIL %d" % fails.size()); for x in fails: print("  - " + x)
	quit(0 if fails.is_empty() else 1)
