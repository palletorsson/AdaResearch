extends SceneTree
## THE DOLL'S HANDS, proven headless: a synthesized LMB press on a body
## selects it (ring up), a drag of one cell previews, release commits — and
## the override ruling holds the same to-cell the first-person arrows would
## have written. ESC lets go.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_doll_hands.gd

const OUT := "res://ada_run/doll_hands_probe.txt"
const CTL := "res://ada_run/_doll_trial_control.json"   # the trial's own voice — never the live session's file

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
	inst.set("_overrides_path", "res://ada_run/_doll_trial_overrides.json")   # the trial's file, never the curator's
	get_root().add_child(inst)
	await create_timer(1.2).timeout
	for i in range(200):
		if (inst.get("_stamp_queue") as Array).is_empty():
			break
		await process_frame

	var cam: Camera3D = inst.get("_cam")
	var records: Array = inst.get("_edit_records")
	# a floor artifact with a live node
	var target := -1
	for i in range(records.size()):
		var r: Dictionary = records[i]
		if String(r.get("kind", "")) != "" and String(r.get("kind", "")) != "artifact":
			continue
		var n: Node3D = r.get("node")
		if n != null and is_instance_valid(n) and n.global_position.z > 6.0:
			target = i
			break
	if target < 0:
		fails.append("no floor artifact to grab")
	else:
		var node: Node3D = (records[target] as Dictionary).get("node")
		var start_pos: Vector3 = node.position
		var start_cell: Array = ((records[target] as Dictionary).get("tile_cell") as Array).duplicate()
		# (re-bound after the press to whatever was actually selected)
		# aim the doll eye at the body so the unprojection is honest
		var pl: CharacterBody3D = inst.get("_player")
		pl.position = Vector3(node.global_position.x, 0, node.global_position.z)
		await process_frame
		await process_frame
		var screen: Vector2 = cam.unproject_position(node.global_position)
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.position = screen
		inst.call("_input", press)
		if int(inst.get("_edit_sel")) < 0:
			fails.append("LMB press selected nothing")
		else:
			# the press picks the NEAREST pickable — in a packed hall that may
			# be a neighbour of the aimed body. The claim under test is that
			# THE SELECTED body moves one cell; assert on it, not on the aim.
			target = int(inst.get("_edit_sel"))
			node = (records[target] as Dictionary).get("node")
			start_pos = node.position
			start_cell = ((records[target] as Dictionary).get("tile_cell") as Array).duplicate()
		var ring: MeshInstance3D = inst.get("_doll_ring")
		if ring == null or not ring.visible:
			fails.append("no selection ring")
		# drag one cell +x: release over the neighbouring cell's centre
		var drop_world: Vector3 = node.global_position + Vector3(1.0, 0, 0)
		var rel := InputEventMouseButton.new()
		rel.button_index = MOUSE_BUTTON_LEFT
		rel.pressed = false
		rel.position = cam.unproject_position(drop_world)
		inst.call("_input", rel)
		var moved: Vector3 = node.position - start_pos
		if absf(moved.x - 1.0) > 0.01 or absf(moved.z) > 0.01:
			fails.append("body did not land one cell +x (moved %s)" % str(moved))
		var cell_now: Array = (records[target] as Dictionary).get("tile_cell")
		if int(cell_now[0]) != int(start_cell[0]) + 1:
			fails.append("tile_cell did not follow the drag")
		var ovs: Array = inst.get("_edit_overrides")
		var found := false
		for ov in ovs:
			var to_v: Variant = (ov as Dictionary).get("to")
			if to_v is Array and int((to_v as Array)[0]) == int(start_cell[0]) + 1:
				found = true
		if not found:
			fails.append("no override ruling carries the drag's to-cell")
		if not bool(inst.get("_edit_dirty")):
			fails.append("the drag did not mark the rulings dirty (autosave will not fire)")
		# ESC lets go
		var esc := InputEventKey.new()
		esc.keycode = KEY_ESCAPE
		esc.pressed = true
		inst.call("_input", esc)
		if int(inst.get("_edit_sel")) >= 0:
			fails.append("ESC did not release the selection")

	# THE ADD MENU: N fills a list from the chapter palette; placing the first
	# entry stands a new body before the doll, selected
	inst.call("_doll_menu_toggle")
	var ml: ItemList = inst.get("_doll_menu_list")
	if ml == null or ml.item_count == 0:
		fails.append("the add menu opened empty")
	else:
		var rc_before: int = (inst.get("_edit_records") as Array).size()
		inst.call("_doll_menu_place", 0)
		if (inst.get("_edit_records") as Array).size() != rc_before + 1:
			# an occupied front cell is honest museum behaviour — do what the
			# UI asks of a human: step, try once more
			var pl2: CharacterBody3D = inst.get("_player")
			pl2.position.z += 2.0
			inst.call("_doll_menu_place", 0)
		if (inst.get("_edit_records") as Array).size() != rc_before + 1:
			fails.append("menu place refused twice: " + String(inst.get("_stamp_refusal")))
		elif int(inst.get("_edit_sel")) != rc_before:
			fails.append("the placed body did not arrive selected")
		else:
			# X removes it again — an add's removal erases the add itself, which
			# may free the node at frame end and reshuffle the records; judge by
			# THE NODE captured at placement, after a frame has passed
			var placed_node: Node3D = ((inst.get("_edit_records") as Array)[rc_before] as Dictionary).get("node")
			var xev := InputEventKey.new()
			xev.keycode = KEY_X
			xev.pressed = true
			inst.call("_input", xev)
			await process_frame
			await process_frame
			var gone: bool = placed_node == null or not is_instance_valid(placed_node) 				or not placed_node.is_inside_tree() or not placed_node.visible
			if not gone:
				fails.append("X did not remove the placed body")
	inst.call("_doll_menu_toggle")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(CTL))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://ada_run/_doll_trial_overrides.json"))
	var f3 := FileAccess.open(OUT, FileAccess.WRITE)
	f3.store_string("PASS" if fails.is_empty() else "FAIL: " + "; ".join(fails))
	f3.close()
	print("DOLL HANDS: " + ("PASS" if fails.is_empty() else "FAIL " + "; ".join(fails)))
	quit(0 if fails.is_empty() else 1)
