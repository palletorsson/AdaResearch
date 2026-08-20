extends SceneTree
## PROBE: the jump list holds every hall; em_control + reload opens AT the target
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	# 1. write the control as the jump would, for Trans_Translation (a PAGE)
	var f := FileAccess.open("res://ada_run/em_control.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "transformation", "first_map": "Trans_Translation"}, " "))
	f.close()
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(m)
	await create_timer(5.0).timeout
	# 2. the jump list
	m.call("_jump_toggle")
	var lst: ItemList = m.get("_jump_list")
	print("JUMP list: %d hall(s); first: %s" % [lst.item_count, lst.get_item_text(0)])
	var found := ""
	for i in range(lst.item_count):
		if lst.get_item_text(i).contains("trans introduction"):
			found = lst.get_item_text(i)
	print("JUMP row for the pool hall: %s" % found)
	# 3. did the control open the museum at the right hall?
	var cur: Dictionary = m.get("_pearl_cursor")
	print("JUMP opened at chapter=%s cursor=%s (want transformation, the intro hall that holds Trans_Translation)" % [m.get("_first_chapter"), str(cur)])
	quit(0)
