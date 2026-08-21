extends SceneTree
## THE DOLL HOUSE, photographed: boots into iso over the point hall, lets the
## wake ramp fill the field, stands the doll mid-hall, and saves the frame.
##   (windowed — a screenshot needs a renderer)

const CTL := "res://ada_run/_doll_trial_control.json"   # the trial's own voice — never the live session's file

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var f := FileAccess.open(CTL, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "primitives", "first_map": "", "dollhouse": 1}, " "))
	f.close()
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	inst.set("EM_CONTROL", CTL)
	get_root().add_child(inst)
	await create_timer(2.0).timeout
	var pl: CharacterBody3D = inst.get("_player")
	if pl != null:
		pl.position = Vector3(7.0, 0.0, 13.0)   # mid point-hall, bodies all around
	inst.set("_doll_zoom", 19.0)
	await create_timer(5.0).timeout   # wake ramp, drain, recut, butter settle
	inst.call("_doll_menu_toggle")    # the add menu must be IN the picture
	# …and so must the inspector: select the first floor body with a live node
	var records: Array = inst.get("_edit_records")
	for i in range(records.size()):
		var r: Dictionary = records[i]
		var kd := String(r.get("kind", ""))
		if kd != "" and kd != "artifact":
			continue
		var nd: Node3D = r.get("node")
		if nd != null and is_instance_valid(nd) and nd.global_position.z > 6.0:
			inst.call("_doll_select", i)
			break
	await create_timer(1.0).timeout
	var img := get_root().get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://ada_run/doll_shot.png"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CTL))
	print("SHOT saved")
	quit(0)
