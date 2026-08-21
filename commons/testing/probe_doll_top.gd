extends SceneTree
## THE PLAN VIEW, proven: a real H press in the doll house climbs to the plan
## (no reload — same doll, same records), the camera stands at noon looking
## straight down, the floor point still resolves under the crosshair, and the
## next H falls through to the exit branch of the ladder.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_doll_top.gd

const OUT := "res://ada_run/doll_top_probe.txt"
const CTL := "res://ada_run/_doll_trial_control.json"

func _key(kc: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = kc as Key
	ev.physical_keycode = kc as Key
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventKey.new()
	up.keycode = kc as Key
	up.physical_keycode = kc as Key
	up.pressed = false
	Input.parse_input_event(up)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array = []
	var f := FileAccess.open(CTL, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "primitives", "first_map": "", "dollhouse": 1}, " "))
	f.close()
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	inst.set("EM_CONTROL", CTL)
	inst.set("_overrides_path", "res://ada_run/_doll_trial_overrides.json")
	get_root().add_child(inst)
	await create_timer(1.2).timeout
	for i in range(200):
		if (inst.get("_stamp_queue") as Array).is_empty():
			break
		await process_frame

	# H (real pipeline): iso → plan, no reload
	_key(KEY_H)
	await process_frame
	await process_frame
	if not bool(inst.get("_doll_top")):
		fails.append("H did not climb to the plan view")
	if not is_instance_valid(inst) or not bool(inst.get("_dollhouse")):
		fails.append("the climb reloaded or left the doll house")
	await create_timer(1.6).timeout   # the butter carries the camera up

	var cam: Camera3D = inst.get("_cam")
	var pl: CharacterBody3D = inst.get("_player")
	if cam == null or pl == null:
		fails.append("no camera or player after the climb")
	else:
		var flat := Vector2(cam.global_position.x - pl.position.x, cam.global_position.z - pl.position.z)
		if flat.length() > 3.0:
			fails.append("plan camera is not overhead (offset %.1f m)" % flat.length())
		if cam.global_position.y < 40.0:
			fails.append("plan camera too low (%.1f m)" % cam.global_position.y)
		var fwd: Vector3 = -cam.global_basis.z
		if fwd.dot(Vector3.DOWN) < 0.95:
			fails.append("plan camera not looking down (dot %.2f)" % fwd.dot(Vector3.DOWN))
		# the crosshair still finds the floor under the doll
		var centre: Vector2 = get_root().get_visible_rect().size * 0.5
		var pt: Vector3 = inst.call("_doll_floor_point", centre)
		if Vector2(pt.x - pl.position.x, pt.z - pl.position.z).length() > 3.0:
			fails.append("floor point under the crosshair missed the doll (%.1f m off)" % Vector2(pt.x - pl.position.x, pt.z - pl.position.z).length())

	# the next H falls through to the exit branch (in a probe the reload is a
	# guarded no-op, so the observable is: the plan does NOT flip back to iso)
	_key(KEY_H)
	await process_frame
	await process_frame
	if not bool(inst.get("_doll_top")):
		fails.append("H from the plan re-entered iso instead of the exit branch")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(CTL))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://ada_run/_doll_trial_overrides.json"))
	var f3 := FileAccess.open(OUT, FileAccess.WRITE)
	f3.store_string("PASS" if fails.is_empty() else "FAIL: " + "; ".join(fails))
	f3.close()
	print("DOLL TOP: " + ("PASS" if fails.is_empty() else "FAIL " + "; ".join(fails)))
	quit(0 if fails.is_empty() else 1)
