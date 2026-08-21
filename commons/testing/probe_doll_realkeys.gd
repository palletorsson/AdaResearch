extends SceneTree
## REAL KEYS, real propagation: Input.parse_input_event() walks the same
## pipeline as hardware — every child's _input runs before the museum's, and a
## thief calling set_input_as_handled() kills the key before the museum sees
## it. inst.call("_input", ev) — the older probes' habit — skips all of that,
## which is how a working menu and a dead key could BOTH be true. This probe
## holds the doll house to the real pipeline: N opens the menu, ESC closes it,
## X removes a selection (grab_cube_scalable claims X in the walk), and a
## pearl-keyed add refuses to replay in a hall with another pearl's name.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_doll_realkeys.gd

const OUT := "res://ada_run/doll_realkeys_probe.txt"
const CTL := "res://ada_run/_doll_trial_control.json"   # the trial's own voice — never the live session's file

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
	await create_timer(2.5).timeout   # past the first recut, so late arrivals settled

	# N through the real pipeline
	_key(KEY_N)
	await process_frame
	await process_frame
	if inst.get("_doll_menu") == null:
		fails.append("real N never opened the menu — stolen in propagation")
	# ESC closes (the filter holds focus, so N must NOT — it would eat typed n's)
	_key(KEY_ESCAPE)
	await process_frame
	await process_frame
	if inst.get("_doll_menu") != null:
		fails.append("real ESC did not close the menu")

	# X through the real pipeline removes the selected body
	var records: Array = inst.get("_edit_records")
	var target := -1
	for i in range(records.size()):
		var r: Dictionary = records[i]
		var kd := String(r.get("kind", ""))
		if kd != "" and kd != "artifact":
			continue
		var nd: Node3D = r.get("node")
		if nd != null and is_instance_valid(nd) and nd.global_position.z > 6.0:
			target = i
			break
	if target < 0:
		fails.append("no body to select for the X test")
	else:
		inst.call("_doll_select", target)
		_key(KEY_X)
		await process_frame
		await process_frame
		if int(inst.get("_edit_sel")) >= 0:
			fails.append("real X did not remove the selection — stolen in propagation")

	# the pearl key: an add ruled in another pearl's hall must not replay here
	var seg2 := Node3D.new()
	seg2.set_meta("em_chapter", "primitives")
	seg2.set_meta("em_pearl", "some_other_pearl")
	get_root().add_child(seg2)
	var ovs: Array = inst.get("_edit_overrides")
	var foreign := {"add": true, "chapter": "primitives", "pearl": "the_pearl_it_was_ruled_in",
		"token": "origin", "from": [3, 3], "to": [3, 3], "rotation": 0.0,
		"remove": false, "provenance": "hand"}
	ovs.append(foreign)
	var rc_before: int = (inst.get("_edit_records") as Array).size()
	inst.call("_apply_hand_adds", seg2, 0, "primitives")
	if (inst.get("_edit_records") as Array).size() != rc_before:
		fails.append("a pearl-keyed add replayed in a hall with another pearl's name")
	if foreign.has("_matched"):
		fails.append("the foreign add was marked matched")
	ovs.erase(foreign)
	seg2.queue_free()

	DirAccess.remove_absolute(ProjectSettings.globalize_path(CTL))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://ada_run/_doll_trial_overrides.json"))
	var f3 := FileAccess.open(OUT, FileAccess.WRITE)
	f3.store_string("PASS" if fails.is_empty() else "FAIL: " + "; ".join(fails))
	f3.close()
	print("DOLL REALKEYS: " + ("PASS" if fails.is_empty() else "FAIL " + "; ".join(fails)))
	quit(0 if fails.is_empty() else 1)
