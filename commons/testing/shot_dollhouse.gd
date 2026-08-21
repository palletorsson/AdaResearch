extends SceneTree
## THE DOLL HOUSE, photographed: boots into iso over the point hall, lets the
## wake ramp fill the field, stands the doll mid-hall, and saves the frame.
##   (windowed — a screenshot needs a renderer)

const CTL := "res://ada_run/em_control.json"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var ctl_before := FileAccess.get_file_as_string(CTL)
	var f := FileAccess.open(CTL, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "primitives", "first_map": "", "dollhouse": 1}, " "))
	f.close()
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(inst)
	await create_timer(2.0).timeout
	var pl: CharacterBody3D = inst.get("_player")
	if pl != null:
		pl.position = Vector3(7.0, 0.0, 13.0)   # mid point-hall, bodies all around
	inst.set("_doll_zoom", 19.0)
	await create_timer(6.0).timeout   # wake ramp, drain, recut, butter settle
	var img := get_root().get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://ada_run/doll_shot.png"))
	var f2 := FileAccess.open(CTL, FileAccess.WRITE)
	f2.store_string(ctl_before)
	f2.close()
	print("SHOT saved")
	quit(0)
