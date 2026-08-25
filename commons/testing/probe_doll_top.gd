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


func _wheel(target: Node, button: MouseButton) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = true
	ev.factor = 1.0
	ev.position = get_root().get_visible_rect().size * 0.5
	# Call the museum's input lane directly. The project autoloads also consume
	# synthetic mouse events in headless runs, making parse_input_event timing
	# nondeterministic even though the museum handler itself is synchronous.
	target.call("_input", ev)


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
	var toolbar: HBoxContainer = inst.get("_plan_toolbar")
	if toolbar == null or not is_instance_valid(toolbar) or toolbar.get_child_count() != 9:
		fails.append("the plan toolbar is missing its nine editor tools")
	var paint_canvas: Control = inst.get("_paint2d_canvas")
	if paint_canvas == null or not is_instance_valid(paint_canvas):
		fails.append("the plan overlay/selection canvas was not created")
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
		var screen_up: Vector3 = cam.global_basis.y
		if screen_up.dot(Vector3.FORWARD) < 0.95:
			fails.append("plan is not north-up (screen-up dot north %.2f)" % screen_up.dot(Vector3.FORWARD))
		# the crosshair still finds the floor under the doll
		var centre: Vector2 = get_root().get_visible_rect().size * 0.5
		var pt: Vector3 = inst.call("_doll_floor_point", centre)
		if Vector2(pt.x - pl.position.x, pt.z - pl.position.z).length() > 3.0:
			fails.append("floor point under the crosshair missed the doll (%.1f m off)" % Vector2(pt.x - pl.position.x, pt.z - pl.position.z).length())
		# In plan view the wheel scrolls continuously along the museum axis; it
		# must move the view and never mutate isometric zoom.
		var iso_zoom: float = float(inst.get("_doll_zoom"))
		var before_scroll_z: float = pl.position.z
		_wheel(inst, MOUSE_BUTTON_WHEEL_DOWN)
		await process_frame
		await process_frame
		if absf(float(inst.get("_doll_zoom")) - iso_zoom) > 0.001:
			fails.append("plan wheel changed zoom instead of scrolling maps")
		if pl.position.z <= before_scroll_z + 0.1:
			fails.append("plan wheel did not scroll down the map axis (%.2f -> %.2f)" % [
				before_scroll_z, pl.position.z])

	# The real top-down artifact footprint is backed by the LMB picker.
	var records: Array = inst.get("_edit_records")
	for i in range(records.size()):
		var record: Dictionary = records[i]
		if String(record.get("kind", "")) in ["variant", "plinth"]:
			continue
		var node_v: Variant = record.get("node")
		if node_v is Node3D and is_instance_valid(node_v):
			var node := node_v as Node3D
			var picked: int = int(inst.call("_doll_pick", Vector3(node.global_position.x, 0.0, node.global_position.z)))
			if picked < 0:
				fails.append("visible artifact has no selectable plan-space record")
			break

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
